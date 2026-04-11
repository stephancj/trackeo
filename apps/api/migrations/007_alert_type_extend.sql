-- Migration 007 extension — Ajoute les types speed_limit et low_battery à l'enum alert_type
ALTER TYPE alert_type ADD VALUE IF NOT EXISTS 'speed_limit';
ALTER TYPE alert_type ADD VALUE IF NOT EXISTS 'low_battery';
ALTER TYPE alert_type ADD VALUE IF NOT EXISTS 'sos';
