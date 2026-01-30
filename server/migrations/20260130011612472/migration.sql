BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "notification_settings" (
    "id" bigserial PRIMARY KEY,
    "surveyId" bigint NOT NULL,
    "enabled" boolean NOT NULL DEFAULT false,
    "recipientEmail" text NOT NULL,
    "sendHour" bigint NOT NULL DEFAULT 9,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSentAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "survey_id_unique" ON "notification_settings" USING btree ("surveyId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "notification_settings"
    ADD CONSTRAINT "notification_settings_fk_0"
    FOREIGN KEY("surveyId")
    REFERENCES "survey"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR form_concierge
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('form_concierge', '20260130011612472', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260130011612472', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
