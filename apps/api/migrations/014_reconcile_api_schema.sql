-- Réconcilie les installations qui ont exécuté les scripts SQL historiques
-- avant leur intégration au pipeline TypeORM. Aucune table tc_* n'est modifiée.

ALTER TABLE geofences
  ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'custom';

ALTER TABLE alerts
  ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS lon DOUBLE PRECISION;

ALTER TYPE alerts_type_enum ADD VALUE IF NOT EXISTS 'sos';
ALTER TYPE alerts_type_enum ADD VALUE IF NOT EXISTS 'low_battery';
ALTER TYPE alerts_type_enum ADD VALUE IF NOT EXISTS 'speed_limit';
ALTER TYPE alerts_type_enum ADD VALUE IF NOT EXISTS 'sleep_movement';

CREATE TABLE IF NOT EXISTS waitlist_subscribers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(320) NOT NULL,
  source VARCHAR(64) NOT NULL DEFAULT 'landing',
  status VARCHAR(24) NOT NULL DEFAULT 'subscribed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unsubscribed_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS "IDX_waitlist_subscribers_email"
  ON waitlist_subscribers (email);

CREATE INDEX IF NOT EXISTS "IDX_waitlist_subscribers_status_created"
  ON waitlist_subscribers (status, created_at DESC);
