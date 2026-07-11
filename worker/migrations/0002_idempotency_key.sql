-- Add idempotency key to prevent duplicate submissions on client retry.
ALTER TABLE survey_responses ADD COLUMN idempotency_key TEXT;

CREATE UNIQUE INDEX survey_responses_idempotency_key ON survey_responses (idempotency_key)
  WHERE idempotency_key IS NOT NULL;
