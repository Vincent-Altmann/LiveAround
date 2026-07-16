import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';

import { DatabaseService } from '../database/database.service';
import { UsersService } from '../users/users.service';
import { PushSender } from './push-sender';

// Balayage : premier passage peu apres le demarrage (les concerts ingeres
// pendant l'arret sont rattrapes via la fenetre de 24 h), puis toutes les
// 15 minutes.
const SWEEP_INITIAL_DELAY_MS = 15 * 1000;
const SWEEP_INTERVAL_MS = 15 * 60 * 1000;
const CATCH_UP_WINDOW = '24 hours';

// Regle anti-spam du cadrage : au plus 3 alertes par utilisateur par 24 h,
// et jamais deux fois le meme concert (contrainte UNIQUE en base).
const MAX_NOTIFICATIONS_PER_DAY = 3;

interface AlertCandidateRow {
  user_id: string;
  concert_external_id: string;
  artist: string;
  genre: string;
  starts_at: Date | string;
  venue_name: string;
  venue_city: string;
  distance_km: string | number;
  sent_last_24h: string | number;
}

export interface UserNotificationModel {
  id: string;
  concertId: string;
  title: string;
  body: string;
  createdAt: string;
  clickedAt: string | null;
}

interface UserNotificationRow {
  id: string;
  concert_external_id: string;
  title: string;
  body: string;
  created_at: Date | string;
  clicked_at: Date | string | null;
}

/**
 * Alertes personnalisees (flux notification de l'architecture) :
 * 1. les imports ajoutent des concerts (ConcertStore.ingest) ;
 * 2. ce service croise les nouveaux concerts avec les preferences des
 *    utilisateurs opt-in (genres, rayon, derniere position) ;
 * 3. une regle anti-spam borne la frequence ;
 * 4. l'alerte est persistee (in-app) et transmise au PushSender (FCM a
 *    brancher) ;
 * 5. les clics sont historises pour mesurer la pertinence.
 */
@Injectable()
export class NotificationsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotificationsService.name);
  private sweepTimer?: NodeJS.Timeout;
  private initialTimer?: NodeJS.Timeout;
  private sweeping = false;

  constructor(
    private readonly database: DatabaseService,
    private readonly usersService: UsersService,
    private readonly pushSender: PushSender,
  ) {}

  onModuleInit() {
    this.initialTimer = setTimeout(() => {
      void this.sweep();
    }, SWEEP_INITIAL_DELAY_MS);
    this.initialTimer.unref();

    this.sweepTimer = setInterval(() => {
      void this.sweep();
    }, SWEEP_INTERVAL_MS);
    this.sweepTimer.unref();
  }

  onModuleDestroy() {
    if (this.initialTimer) clearTimeout(this.initialTimer);
    if (this.sweepTimer) clearInterval(this.sweepTimer);
  }

  /**
   * Croise les concerts recemment ingeres avec les utilisateurs opt-in.
   * Idempotent : la contrainte UNIQUE (user, concert) et la fenetre de
   * rattrapage permettent de relancer sans doublon.
   */
  async sweep() {
    if (this.sweeping || !this.database.geoEnabled) return;
    this.sweeping = true;

    try {
      const candidates = await this.database.query<AlertCandidateRow>(
        `
          SELECT
            u.id AS user_id,
            c.external_id AS concert_external_id,
            c.artist,
            c.genre,
            c.starts_at,
            v.name AS venue_name,
            v.city AS venue_city,
            ST_Distance(v.location, u.last_location) / 1000 AS distance_km,
            (
              SELECT COUNT(*)
              FROM user_notifications n
              WHERE n.user_id = u.id
                AND n.created_at > now() - interval '24 hours'
            ) AS sent_last_24h
          FROM concerts c
          JOIN venues v ON v.id = c.venue_id
          CROSS JOIN users u
          WHERE c.created_at > now() - interval '${CATCH_UP_WINDOW}'
            AND c.starts_at > now()
            AND u.notification_opt_in = true
            AND u.last_location IS NOT NULL
            AND ST_DWithin(v.location, u.last_location, u.preferred_radius_km * 1000)
            AND (
              cardinality(u.preferred_genres) = 0
              OR c.genre = ANY(u.preferred_genres)
            )
            AND NOT EXISTS (
              SELECT 1
              FROM user_notifications n
              WHERE n.user_id = u.id
                AND n.concert_external_id = c.external_id
            )
          ORDER BY u.id, c.starts_at ASC
          LIMIT 500
        `,
      );

      let created = 0;
      const sentPerUser = new Map<string, number>();

      for (const row of candidates.rows) {
        const alreadySent =
          Number(row.sent_last_24h) + (sentPerUser.get(row.user_id) ?? 0);
        if (alreadySent >= MAX_NOTIFICATIONS_PER_DAY) continue;

        const content = buildAlertContent(row);
        const inserted = await this.database.query(
          `
            INSERT INTO user_notifications (user_id, concert_external_id, title, body)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (user_id, concert_external_id) DO NOTHING
          `,
          [row.user_id, row.concert_external_id, content.title, content.body],
        );

        if ((inserted.rowCount ?? 0) === 0) continue;
        created += 1;
        sentPerUser.set(row.user_id, (sentPerUser.get(row.user_id) ?? 0) + 1);

        await this.pushSender.send({
          userId: row.user_id,
          concertId: row.concert_external_id,
          title: content.title,
          body: content.body,
        });
      }

      if (created > 0) {
        this.logger.log(`${created} alertes personnalisees creees`);
      }
    } catch (error) {
      this.logger.warn(`Balayage des alertes impossible: ${errorMessage(error)}`);
    } finally {
      this.sweeping = false;
    }
  }

  async findForDevice(deviceId: string): Promise<UserNotificationModel[]> {
    const user = await this.usersService.getOrCreateCurrentUser(deviceId);
    const result = await this.database.query<UserNotificationRow>(
      `
        SELECT id, concert_external_id, title, body, created_at, clicked_at
        FROM user_notifications
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 50
      `,
      [user.id],
    );

    return result.rows.map((row) => ({
      id: row.id,
      concertId: row.concert_external_id,
      title: row.title,
      body: row.body,
      createdAt: toIso(row.created_at),
      clickedAt: row.clicked_at ? toIso(row.clicked_at) : null,
    }));
  }

  /** Historise le clic (mesure de pertinence prevue par l'architecture). */
  async markClicked(deviceId: string, notificationId: string) {
    const user = await this.usersService.getOrCreateCurrentUser(deviceId);
    await this.database.query(
      `
        UPDATE user_notifications
        SET clicked_at = COALESCE(clicked_at, now())
        WHERE id = $1 AND user_id = $2
      `,
      [notificationId, user.id],
    );
    return { id: notificationId, clicked: true };
  }
}

export function buildAlertContent(row: {
  artist: string;
  genre: string;
  starts_at: Date | string;
  venue_name: string;
  venue_city: string;
  distance_km: string | number;
}) {
  const date = new Date(row.starts_at);
  const dateLabel = date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
  });
  const distance = Number(row.distance_km);
  const distanceLabel = Number.isFinite(distance)
    ? ` a ${distance < 1 ? 'moins de 1' : Math.round(distance)} km`
    : '';

  return {
    title: `Nouveau concert ${row.genre}${distanceLabel}`,
    body: `${row.artist} — ${row.venue_name}, ${row.venue_city}, le ${dateLabel}`,
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
