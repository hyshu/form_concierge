const formConciergeSecretNames = [
  'gemini_api_key',
  'openai_api_key',
  'claude_api_key',
  'groq_api_key',
  'cerebras_api_key',
  'smtp_password',
  'turnstile_site_key',
  'turnstile_secret_key',
];

String formConciergeSecretName(String legacyName) =>
    'form_concierge_$legacyName';

String formConciergeSecretBinding(String legacyName) =>
    legacyName.toUpperCase();

String formConciergeLegacySecretBinding(String legacyName) =>
    'LEGACY_${legacyName.toUpperCase()}';
