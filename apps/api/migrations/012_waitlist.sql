-- Liste d'attente publique pour le lancement d'iooeh.
-- Table propre à l'API (aucune modification du schéma Traccar tc_*).
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
