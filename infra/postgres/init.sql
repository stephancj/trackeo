-- Script d'initialisation PostgreSQL pour Trackeo
-- Exécuté une seule fois au premier démarrage du conteneur

-- Extension TimescaleDB (pour les hypertables de positions)
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Extension utile pour les UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Note : Traccar crée automatiquement ses tables (tc_devices, tc_positions, etc.)
-- lors du premier démarrage. Ce script prépare uniquement les extensions.

-- Hypertable pour les positions (à activer APRÈS que Traccar ait créé tc_positions)
-- À exécuter manuellement la première fois :
-- SELECT create_hypertable('tc_positions', 'devicetime', if_not_exists => TRUE);
