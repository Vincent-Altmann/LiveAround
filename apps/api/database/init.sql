CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT UNIQUE,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  display_name TEXT,
  home_city TEXT,
  home_location GEOGRAPHY(POINT, 4326),
  preferred_genres TEXT[] NOT NULL DEFAULT '{}'::text[],
  preferred_radius_km INTEGER NOT NULL DEFAULT 25,
  notification_opt_in BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS venues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NOT NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE INDEX IF NOT EXISTS concerts_starts_at_idx
  ON concerts (starts_at);

CREATE INDEX IF NOT EXISTS concerts_genre_idx
  ON concerts (genre);

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
