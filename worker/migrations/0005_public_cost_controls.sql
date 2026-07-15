CREATE TABLE usage_quotas (
  subject TEXT NOT NULL,
  resource TEXT NOT NULL,
  period TEXT NOT NULL,
  used INTEGER NOT NULL DEFAULT 0 CHECK (used >= 0),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (subject, resource, period)
);

CREATE INDEX usage_quotas_period ON usage_quotas(period);

CREATE TABLE follow_up_jobs (
  response_id INTEGER PRIMARY KEY REFERENCES survey_responses(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'failed')),
  lease_token TEXT NOT NULL,
  lease_expires_at TEXT NOT NULL,
  last_error TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX follow_up_jobs_lease ON follow_up_jobs(status, lease_expires_at);

CREATE TABLE media_objects (
  key TEXT PRIMARY KEY,
  anonymous_account_id TEXT NOT NULL REFERENCES anonymous_accounts(id) ON DELETE CASCADE,
  response_id INTEGER REFERENCES survey_responses(id) ON DELETE CASCADE,
  size_bytes INTEGER NOT NULL CHECK (size_bytes > 0),
  status TEXT NOT NULL DEFAULT 'temporary' CHECK (status IN ('temporary', 'attached')),
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  attached_at TEXT
);

CREATE INDEX media_objects_expiry ON media_objects(status, expires_at);
CREATE INDEX media_objects_response ON media_objects(response_id);
CREATE INDEX media_objects_account ON media_objects(anonymous_account_id, created_at);

CREATE TRIGGER media_objects_refund_stored_bytes
AFTER DELETE ON media_objects
BEGIN
  UPDATE usage_quotas
  SET used = MAX(0, used - OLD.size_bytes),
      updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE subject = 'account:' || OLD.anonymous_account_id
    AND resource = 'stored_media_bytes'
    AND period = 'all';
END;

DROP INDEX survey_responses_idempotency_key;
CREATE UNIQUE INDEX survey_responses_account_idempotency_key
  ON survey_responses (anonymous_account_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
