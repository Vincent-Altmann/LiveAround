import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';

import { DatabaseService } from '../database/database.service';
import { ConcertModel } from './concert.model';
import { FindConcertsDto } from './dto/find-concerts.dto';

// Purge periodique des concerts passes : garde la base fraiche (enjeu du
// cadrage) sans job externe. Un concert reste 2 jours apres sa date pour
// laisser les favoris recents consultables.
const PURGE_INTERVAL_MS = 6 * 60 * 60 * 1000;
const PURGE_RETENTION = '2 days';

export interface StoredConcertRow {
  external_id: string;
  artist: string;
  title: string;
  genre: string;
  starts_at: Date | string;
  price_from: string | number | null;
  ticket_url: string | null;
  description: string | null;
  image_url: string | null;
  venue_name: string;
  venue_city: string;
  venue_address: string | null;
  latitude: number | string;
  longitude: number | string;
  distance_km?: number | string | null;
}

/**
 * Cache persistant des concerts normalises (tables venues/concerts + PostGIS).
 * Alimente en ecriture directe par les recherches Ticketmaster, il sert :
 * - de source de secours quand Ticketmaster est indisponible ;
 * - de base aux alertes personnalisees (detection des nouveaux concerts).
 */
@Injectable()
export class ConcertStore implements OnModuleDestroy {
  private readonly logger = new Logger(ConcertStore.name);
  private purgeTimer?: NodeJS.Timeout;
  private warnedDisabled = false;

  constructor(private readonly database: DatabaseService) {
    this.purgeTimer = setInterval(() => {
      void this.purgeExpired();
    }, PURGE_INTERVAL_MS);
    this.purgeTimer.unref();
  }

  onModuleDestroy() {
    if (this.purgeTimer) clearInterval(this.purgeTimer);
  }

  get isEnabled() {
    return this.database.geoEnabled;
  }

  /**
   * Upsert des salles et concerts issus d'une recherche Ticketmaster.
   * Appele en tache de fond : ne doit jamais faire echouer une recherche.
   */
  async ingest(concerts: ConcertModel[]) {
    if (!this.isEnabled || concerts.length === 0) return;

    let stored = 0;
    for (const concert of concerts) {
      try {
        const venue = await this.database.query<{ id: string }>(
          `
            INSERT INTO venues (name, city, address, location, source)
            VALUES ($1, $2, $3, ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography, $6)
            ON CONFLICT (name, city) DO UPDATE SET
              address = EXCLUDED.address,
              location = EXCLUDED.location,
              updated_at = now()
            RETURNING id
          `,
          [
            concert.venue.name,
            concert.venue.city,
            concert.venue.address ?? '',
            concert.venue.longitude,
            concert.venue.latitude,
            concert.source ?? 'ticketmaster',
          ],
        );

        await this.database.query(
          `
            INSERT INTO concerts (
              external_id, artist, title, genre, starts_at, venue_id,
              price_from, ticket_url, description, source, image_url,
              source_updated_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, now())
            ON CONFLICT (external_id) DO UPDATE SET
              artist = EXCLUDED.artist,
              title = EXCLUDED.title,
              genre = EXCLUDED.genre,
              starts_at = EXCLUDED.starts_at,
              venue_id = EXCLUDED.venue_id,
              price_from = EXCLUDED.price_from,
              ticket_url = EXCLUDED.ticket_url,
              description = EXCLUDED.description,
              image_url = EXCLUDED.image_url,
              source_updated_at = now(),
              updated_at = now()
          `,
          [
            concert.id,
            concert.artist,
            concert.title,
            concert.genre,
            concert.startsAt,
            venue.rows[0].id,
            concert.priceFrom > 0 ? concert.priceFrom : null,
            concert.ticketUrl || null,
            concert.description || null,
            concert.source ?? 'ticketmaster',
            concert.imageUrl ?? null,
          ],
        );
        stored += 1;
      } catch (error) {
        this.warnOnce(`Ingestion impossible: ${errorMessage(error)}`);
      }
    }

    if (stored > 0) {
      this.logger.log(`${stored} concerts ingeres dans le cache PostGIS`);
    }
  }

  /**
   * Recherche geospatiale dans le cache persistant : tri par distance via
   * PostGIS, memes filtres que l'API publique.
   */
  async searchNearby(query: FindConcertsDto): Promise<ConcertModel[]> {
    if (!this.isEnabled) return [];

    const values: unknown[] = [
      query.longitude,
      query.latitude,
      query.radiusKm * 1000,
    ];
    const conditions = [
      `ST_DWithin(v.location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3)`,
      `c.starts_at >= now()`,
    ];

    if (query.genres.length > 0) {
      values.push(query.genres);
      conditions.push(`c.genre = ANY($${values.length})`);
    }
    if (query.from) {
      values.push(query.from);
      conditions.push(`c.starts_at >= $${values.length}`);
    }
    if (query.to) {
      values.push(query.to);
      conditions.push(`c.starts_at <= $${values.length}`);
    }
    if (query.query?.trim()) {
      values.push(`%${query.query.trim()}%`);
      conditions.push(
        `(c.artist ILIKE $${values.length} OR c.title ILIKE $${values.length} OR v.city ILIKE $${values.length})`,
      );
    }

    const result = await this.database.query<StoredConcertRow>(
      `
        SELECT
          c.external_id,
          c.artist,
          c.title,
          c.genre,
          c.starts_at,
          c.price_from,
          c.ticket_url,
          c.description,
          c.image_url,
          v.name AS venue_name,
          v.city AS venue_city,
          v.address AS venue_address,
          ST_Y(v.location::geometry) AS latitude,
          ST_X(v.location::geometry) AS longitude,
          ST_Distance(v.location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) / 1000 AS distance_km
        FROM concerts c
        JOIN venues v ON v.id = c.venue_id
        WHERE ${conditions.join(' AND ')}
        ORDER BY distance_km ASC
        LIMIT 50
        OFFSET ${(query.page ?? 0) * 50}
      `,
      values,
    );

    return result.rows.map(storedRowToConcert);
  }

  async purgeExpired() {
    if (!this.isEnabled) return;

    try {
      const result = await this.database.query(
        `DELETE FROM concerts WHERE starts_at < now() - interval '${PURGE_RETENTION}'`,
      );
      if ((result.rowCount ?? 0) > 0) {
        this.logger.log(`${result.rowCount} concerts passes purges`);
      }
    } catch (error) {
      this.warnOnce(`Purge impossible: ${errorMessage(error)}`);
    }
  }

  private warnOnce(message: string) {
    if (this.warnedDisabled) return;
    this.warnedDisabled = true;
    this.logger.warn(message);
  }
}

export function storedRowToConcert(row: StoredConcertRow): ConcertModel {
  return {
    id: row.external_id,
    artist: row.artist,
    title: row.title,
    genre: row.genre,
    startsAt: toIso(row.starts_at),
    venue: {
      name: row.venue_name,
      city: row.venue_city,
      address: row.venue_address ?? '',
      latitude: Number(row.latitude),
      longitude: Number(row.longitude),
    },
    distanceKm:
      row.distance_km == null
        ? undefined
        : Number(Number(row.distance_km).toFixed(1)),
    priceFrom: row.price_from == null ? 0 : Number(row.price_from),
    ticketUrl: row.ticket_url ?? '',
    description: row.description ?? '',
    source: 'cache',
    imageUrl: row.image_url ?? undefined,
  };
}

function toIso(value: Date | string) {
  return value instanceof Date
    ? value.toISOString()
    : new Date(value).toISOString();
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
