-- Optional admin-authored instructions included in the adaptive follow-up
-- (GenUI) generation prompt when Flutter follow-up is enabled.
ALTER TABLE surveys ADD COLUMN follow_up_prompt TEXT;
