PRAGMA foreign_keys = ON;

CREATE TABLE admins (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  scope_names TEXT NOT NULL DEFAULT '["admin"]',
  blocked INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE admin_sessions (
  token_hash TEXT PRIMARY KEY,
  admin_id TEXT NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX admin_sessions_admin_id ON admin_sessions(admin_id);
CREATE INDEX admin_sessions_expires_at ON admin_sessions(expires_at);

CREATE TABLE anonymous_accounts (
  id TEXT PRIMARY KEY,
  token_hash TEXT NOT NULL UNIQUE,
  display_name TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  last_seen_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE surveys (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  auth_requirement TEXT NOT NULL DEFAULT 'anonymous',
  created_by_admin_id TEXT REFERENCES admins(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  starts_at TEXT,
  ends_at TEXT
);

CREATE INDEX surveys_status ON surveys(status);
CREATE INDEX surveys_created_by_admin_id ON surveys(created_by_admin_id);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_id INTEGER NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  type TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  is_required INTEGER NOT NULL DEFAULT 1,
  placeholder TEXT,
  min_length INTEGER,
  max_length INTEGER,
  min_selected INTEGER,
  max_selected INTEGER,
  visibility_condition_mode TEXT NOT NULL DEFAULT 'all',
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX questions_survey_order ON questions(survey_id, order_index);

CREATE TABLE choices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  value TEXT
);

CREATE INDEX choices_question_order ON choices(question_id, order_index);

CREATE TABLE survey_responses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_id INTEGER NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  anonymous_account_id TEXT NOT NULL REFERENCES anonymous_accounts(id) ON DELETE CASCADE,
  anonymous_id TEXT,
  submitted_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  ip_address TEXT,
  user_agent TEXT,
  device_id TEXT,
  device_label TEXT,
  device_platform TEXT,
  device_os TEXT,
  device_os_version TEXT,
  device_browser TEXT,
  device_browser_version TEXT,
  device_locale TEXT,
  device_timezone TEXT,
  screen_width INTEGER,
  screen_height INTEGER,
  device_pixel_ratio REAL,
  device_info TEXT,
  metadata TEXT
);

CREATE INDEX survey_responses_survey_submitted ON survey_responses(survey_id, submitted_at);
CREATE INDEX survey_responses_anonymous_account ON survey_responses(anonymous_account_id, submitted_at);

CREATE TABLE answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_response_id INTEGER NOT NULL REFERENCES survey_responses(id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  text_value TEXT,
  selected_choice_ids TEXT,
  UNIQUE (survey_response_id, question_id)
);

CREATE INDEX answers_question_id ON answers(question_id);

CREATE TABLE question_visibility_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_id INTEGER NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  target_question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  source_question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  operator TEXT NOT NULL,
  value_json TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  CHECK (operator IN ('equals', 'notEquals', 'contains', 'notContains', 'isAnswered', 'isNotAnswered')),
  CHECK (target_question_id != source_question_id)
);

CREATE INDEX question_visibility_rules_survey ON question_visibility_rules(survey_id);
CREATE INDEX question_visibility_rules_target ON question_visibility_rules(target_question_id);
CREATE INDEX question_visibility_rules_source ON question_visibility_rules(source_question_id);

CREATE TABLE admin_replies (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_response_id INTEGER NOT NULL REFERENCES survey_responses(id) ON DELETE CASCADE,
  anonymous_account_id TEXT NOT NULL REFERENCES anonymous_accounts(id) ON DELETE CASCADE,
  admin_id TEXT REFERENCES admins(id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  read_at TEXT
);

CREATE INDEX admin_replies_response_id ON admin_replies(survey_response_id, created_at);
CREATE INDEX admin_replies_anonymous_account_id ON admin_replies(anonymous_account_id, created_at);

CREATE TABLE notification_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  survey_id INTEGER NOT NULL UNIQUE REFERENCES surveys(id) ON DELETE CASCADE,
  enabled INTEGER NOT NULL DEFAULT 0,
  recipient_email TEXT NOT NULL,
  send_hour INTEGER NOT NULL DEFAULT 9,
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  last_sent_at TEXT
);
