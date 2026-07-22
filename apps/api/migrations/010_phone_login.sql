-- Migration 010 — connexion par téléphone
-- Normalise les numéros malgaches existants et empêche les doublons.

UPDATE users
SET phone = regexp_replace(phone, '[^0-9+]', '', 'g')
WHERE phone IS NOT NULL;

UPDATE users
SET phone = '+261' || substring(phone FROM 2)
WHERE phone ~ '^0[0-9]{9}$';

UPDATE users
SET phone = '+' || phone
WHERE phone ~ '^261[0-9]{9}$';

CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_phone_unique"
  ON users (phone)
  WHERE phone IS NOT NULL;
