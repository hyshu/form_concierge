/**
 * Product-prefixed secret names used by the deployment and settings APIs.
 */
export const SECRET_NAMES = {
  /**
   * The product-prefixed store name for the gemini secret.
   */
  gemini: 'form_concierge_gemini_api_key',
  /**
   * The product-prefixed store name for the openai secret.
   */
  openai: 'form_concierge_openai_api_key',
  /**
   * The product-prefixed store name for the claude secret.
   */
  claude: 'form_concierge_claude_api_key',
  /**
   * The product-prefixed store name for the groq secret.
   */
  groq: 'form_concierge_groq_api_key',
  /**
   * The product-prefixed store name for the cerebras secret.
   */
  cerebras: 'form_concierge_cerebras_api_key',
  /**
   * The product-prefixed store name for the smtp password secret.
   */
  smtpPassword: 'form_concierge_smtp_password',
  /**
   * The product-prefixed store name for the turnstile site key secret.
   */
  turnstileSiteKey: 'form_concierge_turnstile_site_key',
  /**
   * The product-prefixed store name for the turnstile secret key secret.
   */
  turnstileSecretKey: 'form_concierge_turnstile_secret_key',
} as const;
