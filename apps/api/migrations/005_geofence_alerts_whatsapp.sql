-- Migration 005 — Trackeo API
-- Ajoute les colonnes pour les alertes WhatsApp et conditions d'alerte sur les geofences.
-- - alert_on_entry : boolean (défaut true) — envoyer une alerte à l'entrée
-- - alert_on_exit : boolean (défaut true) — envoyer une alerte à la sortie
-- - alert_via_whatsapp : boolean (défaut false) — envoyer aussi par WhatsApp
-- Ajoute aussi phone sur users pour recevoir les alertes WhatsApp.
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/005_geofence_alerts_whatsapp.sql

-- Colonnes sur geofences
ALTER TABLE geofences
  ADD COLUMN IF NOT EXISTS alert_on_entry BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS alert_on_exit BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS alert_via_whatsapp BOOLEAN DEFAULT false;

-- Colonnes sur users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS phone VARCHAR(50);
