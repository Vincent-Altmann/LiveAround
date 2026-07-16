import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, QueryResult } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private readonly pool: Pool;
  private migrated = false;

  /** Vrai quand PostGIS est disponible (cache concerts en base, alertes). */
  geoEnabled = false;

  constructor(config: ConfigService) {
    this.pool = new Pool({
      connectionString:
        config.get<string>('DATABASE_URL') ??
        'postgres://livearound:livearound@localhost:5432/livearound',
      connectionTimeoutMillis: 1500,
      idleTimeoutMillis: 5000,
    });
  }

  async onModuleInit() {
    try {
      await this.migrate();
      this.migrated = true;
      this.logger.log('Database schema ready');
    } catch (error) {
      this.logger.warn(
        `Database unavailable, using volatile fallback state: ${errorMessage(error)}`,
      );
    }
  }

  async onModuleDestroy() {
    await this.pool.end();
  }

  async query<T extends object = Record<string, unknown>>(
    text: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<T>> {
    if (!this.migrated) {
      await this.migrate();
      this.migrated = true;
    }

    return this.pool.query<T>(text, values);
  }

  private async migrate() {
    await this.migrateBase();
    await this.migrateGeo();
  }

  private async migrateBase() {
    await this.pool.query(`
      CREATE EXTENSION IF NOT EXISTS pgcrypto;

      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        display_name TEXT,
        home_city TEXT,
        notification_opt_in BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      ALTER TABLE users ADD COLUMN IF NOT EXISTS device_id TEXT;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_genres TEXT[] NOT NULL DEFAULT '{}'::text[];
      ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_radius_km INTEGER NOT NULL DEFAULT 25;

      CREATE UNIQUE INDEX IF NOT EXISTS users_device_id_idx
        ON users (device_id)
        WHERE device_id IS NOT NULL;

      CREATE TABLE IF NOT EXISTS user_concert_favorites (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        concert_external_id TEXT NOT NULL,
        concert_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (user_id, concert_external_id)
      );

      CREATE TABLE IF NOT EXISTS concert_reports (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        concert_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        resolved_at TIMESTAMPTZ
      );

      CREATE TABLE IF NOT EXISTS user_notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        concert_external_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        channel TEXT NOT NULL DEFAULT 'in_app',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        clicked_at TIMESTAMPTZ,
        UNIQUE (user_id, concert_external_id)
      );
    `);
  }

  // Le bloc geospatial est isole : sur un Postgres sans extension PostGIS,
  // les comptes/favoris/notifications restent fonctionnels et seules les
  // fonctionnalites geo (cache concerts en base, alertes) sont desactivees.
  private async migrateGeo() {
    try {
      await this.pool.query(`
        CREATE EXTENSION IF NOT EXISTS postgis;

        CREATE TABLE IF NOT EXISTS venues (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name TEXT NOT NULL,
          city TEXT NOT NULL,
          address TEXT NOT NULL DEFAULT '',
          location GEOGRAPHY(POINT, 4326) NOT NULL,
          source TEXT,
          created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        CREATE UNIQUE INDEX IF NOT EXISTS venues_name_city_idx
          ON venues (name, city);

        CREATE INDEX IF NOT EXISTS venues_location_idx
          ON venues
          USING GIST (location);

        CREATE TABLE IF NOT EXISTS concerts (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          external_id TEXT UNIQUE,
          artist TEXT NOT NULL,
          title TEXT NOT NULL,
          genre TEXT NOT NULL,
          starts_at TIMESTAMPTZ NOT NULL,
          venue_id UUID NOT NULL REFERENCES venues(id),
          price_from NUMERIC(8, 2),
          ticket_url TEXT,
          description TEXT,
          source TEXT NOT NULL,
          source_updated_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        ALTER TABLE concerts ADD COLUMN IF NOT EXISTS image_url TEXT;

        CREATE INDEX IF NOT EXISTS concerts_starts_at_idx
          ON concerts (starts_at);

        CREATE INDEX IF NOT EXISTS concerts_genre_idx
          ON concerts (genre);

        ALTER TABLE users ADD COLUMN IF NOT EXISTS last_location GEOGRAPHY(POINT, 4326);
        ALTER TABLE users ADD COLUMN IF NOT EXISTS last_location_updated_at TIMESTAMPTZ;
      `);
      this.geoEnabled = true;
    } catch (error) {
      this.logger.warn(
        `PostGIS indisponible, fonctionnalites geo desactivees: ${errorMessage(error)}`,
      );
    }
  }
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
