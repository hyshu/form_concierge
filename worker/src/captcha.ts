import { isTurnstileConfigured } from "./admin_settings";
import type { Env, SurveyRow } from "./types";

export function captchaRequiredForSurvey(
  survey: SurveyRow,
  turnstileConfigured: boolean,
): boolean {
  return survey.captcha_enabled === 1 && turnstileConfigured;
}

export async function isCaptchaRequiredForSurvey(
  env: Env,
  survey: SurveyRow,
): Promise<boolean> {
  return captchaRequiredForSurvey(survey, await isTurnstileConfigured(env));
}
