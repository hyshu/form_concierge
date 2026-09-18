import { isTurnstileConfigured } from './admin_settings';
import type { Env, SurveyRow } from './types';

/**
 * Combines the survey's CAPTCHA preference with Turnstile availability.
 */
export function captchaRequiredForSurvey(survey: SurveyRow, turnstileConfigured: boolean): boolean {
  return survey.captcha_enabled === 1 && turnstileConfigured;
}

/**
 * Checks whether the survey requires a token using the current Turnstile configuration.
 */
export async function isCaptchaRequiredForSurvey(env: Env, survey: SurveyRow): Promise<boolean> {
  return captchaRequiredForSurvey(survey, await isTurnstileConfigured(env));
}
