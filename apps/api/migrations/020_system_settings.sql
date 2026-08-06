-- Migration: 020_system_settings
-- Description: Create system_settings table and insert default settings

CREATE TABLE IF NOT EXISTS system_settings (
  key VARCHAR(255) PRIMARY KEY,
  value JSONB,
  description TEXT,
  "updatedAt" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO system_settings (key, value, description)
VALUES 
  ('whatsapp_enabled', 'true'::jsonb, 'Activer globalement les alertes WhatsApp'),
  ('push_enabled', 'true'::jsonb, 'Activer globalement les notifications Push OneSignal')
ON CONFLICT (key) DO NOTHING;
