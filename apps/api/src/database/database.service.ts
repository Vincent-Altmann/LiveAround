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
    `);
  }
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
