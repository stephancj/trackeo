-- Migration 009 — Trackeo API
-- Stocke la position (lat/lon) où une alerte s'est produite, pour pouvoir
-- l'afficher sur la carte (ex. l'endroit exact d'un excès de vitesse).
-- Nullable : les anciennes alertes restent valides (pas de localisation).
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/009_alert_location.sql

ALTER TABLE alerts
  ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS lon DOUBLE PRECISION;
