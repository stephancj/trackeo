ALTER TABLE security_incidents ADD COLUMN IF NOT EXISTS source_event_id BIGINT;
CREATE UNIQUE INDEX IF NOT EXISTS uq_security_incidents_source_event ON security_incidents(source_event_id) WHERE source_event_id IS NOT NULL;
