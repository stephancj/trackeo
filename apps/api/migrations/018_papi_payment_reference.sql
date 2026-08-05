ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS papi_payment_reference VARCHAR(100);

CREATE UNIQUE INDEX IF NOT EXISTS uq_payments_papi_payment_reference
  ON payments(papi_payment_reference)
  WHERE papi_payment_reference IS NOT NULL;
