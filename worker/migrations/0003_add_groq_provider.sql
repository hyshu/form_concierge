PRAGMA foreign_keys = OFF;

CREATE TABLE integration_settings_new (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  ai_provider TEXT NOT NULL DEFAULT 'gemini',
  smtp_host TEXT,
  smtp_port INTEGER,
  smtp_username TEXT,
  smtp_from_email TEXT,
  smtp_from_name TEXT,
  smtp_secure_mode TEXT NOT NULL DEFAULT 'starttls',
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  CHECK (ai_provider IN ('gemini', 'openai', 'claude', 'groq', 'cerebras')),
  CHECK (smtp_secure_mode IN ('none', 'starttls', 'tls')),
  CHECK (smtp_port IS NULL OR (smtp_port BETWEEN 1 AND 65535))
);

INSERT INTO integration_settings_new SELECT * FROM integration_settings;
DROP TABLE integration_settings;
ALTER TABLE integration_settings_new RENAME TO integration_settings;

PRAGMA foreign_keys = ON;
