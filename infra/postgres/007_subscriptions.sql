-- Migration 007: Subscriptions table
-- Run: docker exec -i trackeo-postgres-1 psql -U trackeo -d traccar_db < infra/postgres/007_subscriptions.sql

CREATE TABLE IF NOT EXISTS subscriptions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  plan          VARCHAR(50) NOT NULL DEFAULT 'free',
  status        VARCHAR(50) NOT NULL DEFAULT 'trial',
  vehicle_limit INTEGER NOT NULL DEFAULT 1,
  next_billing_date TIMESTAMPTZ,
  trial_ends_at     TIMESTAMPTZ,
  notes             TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed: create a default "free / trial" subscription for every existing user
INSERT INTO subscriptions (user_id, plan, status, vehicle_limit, trial_ends_at)
SELECT
  id,
  'free',
  'trial',
  1,
  NOW() + INTERVAL '30 days'
FROM users
ON CONFLICT (user_id) DO NOTHING;
