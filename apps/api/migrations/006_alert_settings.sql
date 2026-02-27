-- Migration 006 — Trackeo API
-- Ajoute les colonnes de paramètres d'alerte sur la table users.
-- - alerts_enabled : boolean (défaut true) — activer/désactiver toutes les alertes
-- - alert_sos : boolean (défaut true) — alertes SOS
-- - alert_low_battery : boolean (défaut true) — alertes batterie faible
-- - alert_speed_limit : boolean (défaut false) — alertes vitesse excessive
-- - alert_via_push : boolean (défaut true) — envoi par push
-- - alert_via_whatsapp : boolean (défaut false) — envoi par WhatsApp
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/006_alert_settings.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS alerts_enabled BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS alert_sos BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS alert_low_battery BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS alert_speed_limit BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS alert_via_push BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS alert_via_whatsapp BOOLEAN DEFAULT false;
