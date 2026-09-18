/// The legacy secret names managed by the deployment tooling.
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

/// Converts a legacy secret name to its product-prefixed store name.
String formConciergeSecretName(String legacyName) =>
    'form_concierge_$legacyName';

/// Returns the Worker binding name for a product-prefixed secret.
String formConciergeSecretBinding(String legacyName) =>
    legacyName.toUpperCase();

/// Returns the compatibility binding name for a legacy secret.
String formConciergeLegacySecretBinding(String legacyName) =>
    'LEGACY_${legacyName.toUpperCase()}';
