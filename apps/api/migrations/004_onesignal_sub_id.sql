-- Migration 004 — Trackeo API
-- Ajoute la colonne onesignal_sub_id sur la table users.
-- Permet de cibler un push directement via include_subscription_ids
-- sans dépendre du External ID (qui nécessite OneSignal.login() côté SDK).
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/004_onesignal_sub_id.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS onesignal_sub_id VARCHAR(255);
