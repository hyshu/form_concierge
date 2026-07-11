-- Add per-survey CAPTCHA toggle (default ON for new surveys).
ALTER TABLE surveys ADD COLUMN captcha_enabled INTEGER NOT NULL DEFAULT 1;
