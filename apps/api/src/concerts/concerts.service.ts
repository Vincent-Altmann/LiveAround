import { Injectable, Logger, NotFoundException } from '@nestjs/common';

import { TtlCache } from '../common/ttl-cache';
import { DatabaseService } from '../database/database.service';
import { UsersService } from '../users/users.service';
import { ConcertStore } from './concert-store.service';
import { ConcertModel, ConcertReportModel } from './concert.model';
import { FindConcertsDto } from './dto/find-concerts.dto';
import { distanceKm } from './geo.util';
import { TicketmasterClient } from './ticketmaster.client';

// Deux minutes suffisent pour absorber les rafales d'une meme zone (retours
// en arriere, changements de filtre annules) sans servir de donnees perimees.
const SEARCH_CACHE_TTL_MS = 2 * 60 * 1000;
const SEARCH_CACHE_MAX_ENTRIES = 200;

// Le detail d'un concert change rarement : TTL plus long, taille bornee pour
// remplacer l'ancienne Map qui grossissait indefiniment.
const DETAIL_CACHE_TTL_MS = 10 * 60 * 1000;
const DETAIL_CACHE_MAX_ENTRIES = 500;

@Injectable()
export class ConcertsService {
  private readonly logger = new Logger(ConcertsService.name);
  private readonly fallbackReports: ConcertReportModel[] = [];
  private readonly searchCache = new TtlCache<ConcertModel[]>(
    SEARCH_CACHE_TTL_MS,
    SEARCH_CACHE_MAX_ENTRIES,
  );
  private readonly detailCache = new TtlCache<ConcertModel>(
    DETAIL_CACHE_TTL_MS,
    DETAIL_CACHE_MAX_ENTRIES,
  );

  constructor(
    private readonly ticketmasterClient: TicketmasterClient,
    private readonly usersService: UsersService,
    private readonly database: DatabaseService,
    private readonly concertStore: ConcertStore,
  ) {}

  async findNearby(query: FindConcertsDto, deviceId?: string) {
    const favorites = await this.usersService.getFavoriteIds(deviceId);
    const effectiveQuery = await this.withUserPreferences(query, deviceId);

    // La derniere position de recherche alimente les alertes personnalisees
    // (concerts proches de l'utilisateur). Fire-and-forget : jamais bloquant.
    if (deviceId) {
      void this.usersService.updateLastLocation(
        deviceId,
        query.latitude,
        query.longitude,
      );
    }

    if (this.ticketmasterClient.isEnabled()) {
      const cacheKey = searchCacheKey(effectiveQuery);
      const cached = this.searchCache.get(cacheKey);
      if (cached) {
        return withFavorites(cached, favorites);
      }

      try {
        const concerts =
          await this.ticketmasterClient.searchEvents(effectiveQuery);
        this.searchCache.set(cacheKey, concerts);
        concerts.forEach((concert) =>
          this.detailCache.set(concert.id, concert),
        );
        // Alimente le cache persistant PostGIS sans ralentir la reponse.
        void this.concertStore.ingest(concerts).catch(() => undefined);
        return withFavorites(concerts, favorites);
      } catch (error) {
        this.logger.warn(
          `Ticketmaster indisponible, bascule sur le cache PostGIS: ${errorMessage(error)}`,
        );
      }
    }

    // Ticketmaster indisponible ou non configure : le cache persistant sert
    // les concerts deja ingeres ; les donnees de demo restent l'ultime repli.
    try {
      const stored = await this.concertStore.searchNearby(effectiveQuery);
      if (stored.length > 0) {
        return withFavorites(stored, favorites);
      }
    } catch (error) {
      this.logger.warn(
        `Cache PostGIS indisponible: ${errorMessage(error)}`,
      );
    }

    return withFavorites(this.findSeedNearby(effectiveQuery), favorites);
  }

  async findOne(id: string, deviceId?: string) {
    const favorites = await this.usersService.getFavoriteIds(deviceId);
    const cached = this.detailCache.get(id);
    if (cached) {
      return {
        ...cached,
        isFavorite: favorites.has(id),
      };
    }

    if (this.ticketmasterClient.isEnabled() && !id.startsWith('la-')) {
      try {
        const concert = await this.ticketmasterClient.getEvent(id);
        if (concert) {
          this.detailCache.set(concert.id, concert);
          return {
            ...concert,
            isFavorite: favorites.has(id),
          };
        }
      } catch (error) {
        this.logger.warn(
          `Detail Ticketmaster indisponible pour ${id}: ${errorMessage(error)}`,
        );
      }
    }

    const concert = seedConcerts.find((item) => item.id === id);
    if (!concert) return null;
    return {
      ...concert,
      isFavorite: favorites.has(id),
    };
  }

  async toggleFavorite(id: string, deviceId?: string) {
    const concert = await this.findOne(id, deviceId);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }

    const isFavorite = await this.usersService.toggleFavorite(
      deviceId,
      concert,
    );

    return {
      ...concert,
      isFavorite,
    };
  }

  async report(
    concertId: string,
    reason: string,
    deviceId?: string,
  ): Promise<ConcertReportModel> {
    const concert = await this.findOne(concertId, deviceId);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }

    try {
      const userId = deviceId
        ? (await this.usersService.getOrCreateCurrentUser(deviceId)).id
        : null;
      const result = await this.database.query<{
        id: string;
        created_at: Date | string;
      }>(
        `
          INSERT INTO concert_reports (user_id, concert_id, reason)
          VALUES ($1, $2, $3)
          RETURNING id, created_at
        `,
        [userId, concertId, reason],
      );

      const row = result.rows[0];
      return {
        id: row.id,
        concertId,
        reason,
        createdAt: toIso(row.created_at),
      };
    } catch (error) {
      this.logger.warn(
        `Signalement conserve en memoire (base indisponible): ${errorMessage(error)}`,
      );
      const report = {
        concertId,
        reason,
        createdAt: new Date().toISOString(),
      };
      this.fallbackReports.push(report);
      return report;
    }
  }

  private async withUserPreferences(query: FindConcertsDto, deviceId?: string) {
    // Sans session, la recherche reste anonyme : pas de preferences a
    // appliquer et surtout pas de compte cree a la volee.
    if (!deviceId || query.genres.length > 0) return query;

    const profile = await this.usersService.getOrCreateCurrentUser(deviceId);
    return {
      ...query,
      genres: profile.preferredGenres,
    };
  }

  private findSeedNearby(query: FindConcertsDto) {
    // Le jeu de demonstration tient sur une page.
    if ((query.page ?? 0) > 0) return [];

    const normalizedQuery = query.query?.trim().toLowerCase();
    const from = query.from ? new Date(query.from) : null;
    const to = query.to ? new Date(query.to) : null;

    return seedConcerts
      .map((concert) => ({
        ...concert,
        distanceKm: distanceKm(
          query.latitude,
          query.longitude,
          concert.venue.latitude,
          concert.venue.longitude,
        ),
      }))
      .filter((concert) => concert.distanceKm <= query.radiusKm)
      .filter((concert) => {
        if (query.genres.length === 0) return true;
        return query.genres.includes(concert.genre);
      })
      .filter((concert) => {
        const startsAt = new Date(concert.startsAt);
        if (from && startsAt < from) return false;
        if (to && startsAt > to) return false;
        return true;
      })
      .filter((concert) => {
        if (!normalizedQuery) return true;
        return (
          concert.artist.toLowerCase().includes(normalizedQuery) ||
          concert.title.toLowerCase().includes(normalizedQuery) ||
          concert.venue.city.toLowerCase().includes(normalizedQuery)
        );
      })
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }
}

// La position est arrondie a ~1 km pour que les petites variations GPS d'un
// meme utilisateur (ou de voisins) partagent la meme entree de cache.
function searchCacheKey(query: FindConcertsDto) {
  return [
    query.latitude.toFixed(2),
    query.longitude.toFixed(2),
    query.radiusKm,
    query.page ?? 0,
    [...query.genres].sort().join('+'),
    query.from ?? '',
    query.to ?? '',
    query.query?.trim().toLowerCase() ?? '',
  ].join('|');
}

function withFavorites(concerts: ConcertModel[], favorites: Set<string>) {
  return concerts.map((concert) => ({
    ...concert,
    isFavorite: favorites.has(concert.id),
  }));
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}

function toIso(value: Date | string) {
  return value instanceof Date
    ? value.toISOString()
    : new Date(value).toISOString();
}

const seedConcerts: ConcertModel[] = [
  {
    id: 'la-001',
    artist: 'The Velvet Echoes',
    title: 'Tournee d ete',
    genre: 'Rock',
    startsAt: '2026-07-24T20:30:00.000Z',
    venue: {
      name: 'Le Transbordeur',
      city: 'Villeurbanne',
      address: '3 boulevard Stalingrad',
      latitude: 45.7832,
      longitude: 4.8605,
    },
    priceFrom: 32,
    ticketUrl: 'https://tickets.example/livearound/la-001',
    description:
      'Un concert rock nerveux dans une salle lyonnaise emblematique.',
  },
  {
    id: 'la-002',
    artist: 'Nora Blue',
    title: 'Fragments acoustiques',
    genre: 'Pop',
    startsAt: '2026-07-27T19:45:00.000Z',
    venue: {
      name: 'Radiant-Bellevue',
      city: 'Caluire-et-Cuire',
      address: '1 rue Jean Moulin',
      latitude: 45.7958,
      longitude: 4.8446,
    },
    priceFrom: 28,
    ticketUrl: 'https://tickets.example/livearound/la-002',
    description: 'Une soiree pop lumineuse avec une scenographie intimiste.',
  },
  {
    id: 'la-003',
    artist: 'Collectif Minuit',
    title: 'Warehouse live session',
    genre: 'Electro',
    startsAt: '2026-08-02T23:00:00.000Z',
    venue: {
      name: 'Ninkasi Gerland',
      city: 'Lyon',
      address: '267 rue Marcel Merieux',
      latitude: 45.7272,
      longitude: 4.8307,
    },
    priceFrom: 24,
    ticketUrl: 'https://tickets.example/livearound/la-003',
    description:
      'Set electro nocturne, pense pour les amateurs de decouverte locale.',
  },
  {
    id: 'la-004',
    artist: 'Maya Quartet',
    title: 'Jazz sur la Saone',
    genre: 'Jazz',
    startsAt: '2026-08-09T21:00:00.000Z',
    venue: {
      name: 'Hot Club de Lyon',
      city: 'Lyon',
      address: '26 rue Lanterne',
      latitude: 45.7669,
      longitude: 4.8277,
    },
    priceFrom: 18,
    ticketUrl: 'https://tickets.example/livearound/la-004',
    description:
      'Quartet jazz moderne, parfait pour une sortie de derniere minute.',
  },
  {
    id: 'la-005',
    artist: 'Kobalt',
    title: 'Nord Sud',
    genre: 'Rap',
    startsAt: '2026-08-14T20:00:00.000Z',
    venue: {
      name: 'Halle Tony Garnier',
      city: 'Lyon',
      address: '20 place Docteurs Merieux',
      latitude: 45.7302,
      longitude: 4.8239,
    },
    priceFrom: 39,
    ticketUrl: 'https://tickets.example/livearound/la-005',
    description:
      'Plateau rap francophone avec premiere partie locale selectionnee.',
  },
  {
    id: 'la-006',
    artist: 'Solstice Strings',
    title: 'Classiques au parc',
    genre: 'Classique',
    startsAt: '2026-08-21T18:30:00.000Z',
    venue: {
      name: 'Auditorium de Lyon',
      city: 'Lyon',
      address: '149 rue Garibaldi',
      latitude: 45.7607,
      longitude: 4.8525,
    },
    priceFrom: 21,
    ticketUrl: 'https://tickets.example/livearound/la-006',
    description:
      'Programme accessible autour de cordes et pieces orchestrales.',
  },
];
