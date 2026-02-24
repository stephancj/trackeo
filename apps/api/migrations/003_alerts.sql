-- Migration 003 — Trackeo API
-- Table alerts : alertes générées par le système (geofence_enter, geofence_exit, etc.).
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/003_alerts.sql

DO $$ BEGIN
  CREATE TYPE alert_type AS ENUM ('geofence_enter', 'geofence_exit');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS alerts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id   INTEGER NOT NULL,
  owner_id    INTEGER NOT NULL,
  type        alert_type NOT NULL,
  message     TEXT,
  status      VARCHAR(50) NOT NULL DEFAULT 'open',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alerts_owner
  ON alerts (owner_id);

CREATE INDEX IF NOT EXISTS idx_alerts_device_type
  ON alerts (device_id, type, created_at DESC);
