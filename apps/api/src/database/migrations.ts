/**
 * Migrations versionnees du schema : source de verite unique, appliquees une
 * seule fois chacune et historisees dans la table schema_migrations.
 *
 * Regles :
 * - ne jamais modifier une migration deja fusionnee : en ajouter une nouvelle ;
 * - les identifiants sont croissants et uniques ;
 * - `requiresGeo` reserve la migration aux bases disposant de PostGIS
 *   (elle sera appliquee plus tard si l'extension devient disponible).
 */
export interface Migration {
  id: number;
  name: string;
  requiresGeo?: boolean;
  up: string;
}

export const MIGRATIONS: Migration[] = [
  {
    id: 1,
    name: 'baseline-comptes-favoris-signalements-notifications',
    up: `
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
    `,
  },
  {
    id: 2,
    name: 'geo-venues-concerts-derniere-position',
    requiresGeo: true,
    up: `
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
    `,
  },
  {
    id: 3,
    name: 'sessions-refresh-et-reinitialisation-mot-de-passe',
    up: `
      CREATE TABLE IF NOT EXISTS user_refresh_tokens (
        token_hash TEXT PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE INDEX IF NOT EXISTS user_refresh_tokens_user_idx
        ON user_refresh_tokens (user_id);

      CREATE TABLE IF NOT EXISTS password_reset_codes (
        user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        code_hash TEXT NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `,
  },
];
