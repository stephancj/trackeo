-- Migration 002 — Trackeo API
-- Table geofences : zones géographiques définies par l'utilisateur.
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/002_geofences.sql

CREATE TABLE IF NOT EXISTS geofences (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  user_id     INTEGER NOT NULL,
  device_ids  INTEGER[] NOT NULL DEFAULT '{}',
  center_lat  DOUBLE PRECISION NOT NULL,
  center_lon  DOUBLE PRECISION NOT NULL,
  radius_m    INTEGER NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geofences_user
  ON geofences (user_id);
