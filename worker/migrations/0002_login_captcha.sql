CREATE TABLE admin_login_failures (
  key_hash TEXT PRIMARY KEY,
  failed_attempts INTEGER NOT NULL,
  expires_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX admin_login_failures_expires_at
  ON admin_login_failures(expires_at);
