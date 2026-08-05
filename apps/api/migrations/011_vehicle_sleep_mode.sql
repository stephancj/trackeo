-- Mode veille antivol, table propre à l'API (aucune modification tc_*).
CREATE TABLE IF NOT EXISTS vehicle_sleep_modes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id INTEGER NOT NULL UNIQUE,
  owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  armed_lat DOUBLE PRECISION NOT NULL,
  armed_lon DOUBLE PRECISION NOT NULL,
  movement_threshold_m INTEGER NOT NULL DEFAULT 100,
  triggered_at TIMESTAMPTZ,
  last_distance_m DOUBLE PRECISION NOT NULL DEFAULT 0,
  armed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vehicle_sleep_modes_active
  ON vehicle_sleep_modes (active) WHERE active = TRUE;

-- Le nom dépend de l'origine du schéma : migration SQL historique
-- (`alert_type`) ou migration TypeORM (`alerts_type_enum`).
DO $$
BEGIN
  IF to_regtype('public.alert_type') IS NOT NULL THEN
    ALTER TYPE alert_type ADD VALUE IF NOT EXISTS 'sleep_movement';
  ELSIF to_regtype('public.alerts_type_enum') IS NOT NULL THEN
    ALTER TYPE alerts_type_enum ADD VALUE IF NOT EXISTS 'sleep_movement';
  ELSE
    RAISE EXCEPTION 'Type enum de alerts.type introuvable';
  END IF;
END
$$;
