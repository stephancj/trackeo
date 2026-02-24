-- Migration 001 — Trackeo API
-- Table device_assignments : lie un device Traccar à un owner Trackeo.
-- À exécuter UNE SEULE FOIS après le premier démarrage de Traccar.
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/001_device_assignments.sql

CREATE TABLE IF NOT EXISTS device_assignments (
  id          SERIAL PRIMARY KEY,
  device_id   INTEGER NOT NULL,
  user_id     INTEGER NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Un device ne peut être lié qu'à un seul owner
  CONSTRAINT uq_device_assignments_device UNIQUE (device_id)
);

CREATE INDEX IF NOT EXISTS idx_device_assignments_user
  ON device_assignments (user_id);
