-- Brevo : double opt-in de la waitlist et canal d'alertes email.

ALTER TABLE waitlist_subscribers
  ADD COLUMN IF NOT EXISTS verification_token_hash CHAR(64),
  ADD COLUMN IF NOT EXISTS verification_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verification_sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Les entrées historiques étaient déjà considérées comme inscrites.
UPDATE waitlist_subscribers
SET verified_at = created_at
WHERE status = 'subscribed' AND verified_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "IDX_waitlist_verification_token"
  ON waitlist_subscribers (verification_token_hash)
  WHERE verification_token_hash IS NOT NULL;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS alert_via_email BOOLEAN NOT NULL DEFAULT FALSE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'email_verified_at'
  ) THEN
    ALTER TABLE users
      ADD COLUMN email_verified_at TIMESTAMPTZ,
      ADD COLUMN email_verification_token_hash CHAR(64),
      ADD COLUMN email_verification_expires_at TIMESTAMPTZ,
      ADD COLUMN email_verification_sent_at TIMESTAMPTZ,
      ADD COLUMN password_reset_token_hash CHAR(64),
      ADD COLUMN password_reset_expires_at TIMESTAMPTZ,
      ADD COLUMN password_reset_sent_at TIMESTAMPTZ,
      ADD COLUMN last_login_at TIMESTAMPTZ;

    -- Seulement lors de la première migration : les comptes historiques sont validés.
    UPDATE users SET email_verified_at = created_at;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_email_verification_token"
  ON users (email_verification_token_hash)
  WHERE email_verification_token_hash IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_password_reset_token"
  ON users (password_reset_token_hash)
  WHERE password_reset_token_hash IS NOT NULL;
