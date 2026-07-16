import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, QueryResult } from 'pg';

import { MIGRATIONS } from './migrations';

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

  /**
   * Applique les migrations versionnees (src/database/migrations.ts) non
   * encore jouees, chacune dans sa transaction, et les historise dans
   * schema_migrations. Les migrations geo sont differees tant que PostGIS
   * n'est pas disponible.
   */
  private async migrate() {
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `);

    this.geoEnabled = await this.tryEnablePostgis();

    const appliedResult = await this.pool.query<{ id: number }>(
      'SELECT id FROM schema_migrations',
    );
    const applied = new Set(appliedResult.rows.map((row) => Number(row.id)));

    for (const migration of MIGRATIONS) {
      if (applied.has(migration.id)) continue;
      if (migration.requiresGeo && !this.geoEnabled) {
        this.logger.warn(
          `Migration ${migration.id} (${migration.name}) differee : PostGIS indisponible`,
        );
        continue;
      }

      const client = await this.pool.connect();
      try {
        await client.query('BEGIN');
        await client.query(migration.up);
        await client.query(
          'INSERT INTO schema_migrations (id, name) VALUES ($1, $2)',
          [migration.id, migration.name],
        );
        await client.query('COMMIT');
        this.logger.log(
          `Migration ${migration.id} appliquee : ${migration.name}`,
        );
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    }
  }

  private async tryEnablePostgis() {
    try {
      await this.pool.query('CREATE EXTENSION IF NOT EXISTS postgis');
      return true;
    } catch {
      return false;
    }
  }
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
