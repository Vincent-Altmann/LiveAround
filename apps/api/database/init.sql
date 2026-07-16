-- Le schema applicatif est gere par les migrations versionnees de l'API :
-- apps/api/src/database/migrations.ts (table schema_migrations).
-- Ce script d'initialisation Docker ne prepare que les extensions.
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
