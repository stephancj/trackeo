-- Migration 008 — Trackeo API
-- Ajoute une catégorie de zone (type) sur les geofences pour piloter l'icône et
-- la couleur côté client (domicile, bureau, école, famille, magasin, perso…).
-- - type : text (défaut 'custom') — clé de catégorie, libre côté serveur.
--
-- Usage :
--   psql -h localhost -U trackeo -d traccar_db -f migrations/008_geofence_type.sql

ALTER TABLE geofences
  ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'custom';
