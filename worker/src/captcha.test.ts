import assert from "node:assert/strict";
import test from "node:test";

import { surveyRow } from "../test/fixtures";
import { captchaRequiredForSurvey } from "./captcha";

test("CAPTCHA is required only when survey policy and Turnstile are enabled", () => {
  assert.equal(
    captchaRequiredForSurvey(surveyRow({ captcha_enabled: 1 }), true),
    true,
  );
  assert.equal(
    captchaRequiredForSurvey(surveyRow({ captcha_enabled: 1 }), false),
    false,
  );
  assert.equal(
    captchaRequiredForSurvey(surveyRow({ captcha_enabled: 0 }), true),
    false,
  );
});
