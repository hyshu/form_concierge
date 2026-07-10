-- Adaptive follow-up interview flag + response blob (post-0001 remote DBs).
ALTER TABLE surveys ADD COLUMN follow_up_enabled INTEGER NOT NULL DEFAULT 0;
ALTER TABLE survey_responses ADD COLUMN follow_up TEXT;
