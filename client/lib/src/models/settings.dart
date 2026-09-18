part of form_concierge_client;

/// The service used to generate and translate survey content.
enum AiProvider {
  /// Google Gemini.
  gemini,

  /// OpenAI.
  openai,

  /// Anthropic Claude.
  claude,

  /// Groq.
  groq,

  /// Cerebras.
  cerebras,
}

/// The transport security used when connecting to an SMTP server.
enum SmtpSecureMode {
  /// Connects without transport encryption.
  none,

  /// Upgrades the SMTP connection to TLS using STARTTLS.
  starttls,

  /// Establishes TLS before exchanging SMTP commands.
  tls,
}

/// Saved AI, email, and CAPTCHA settings with secret availability flags.
class AdminIntegrationSettings {
  /// AI provider settings and saved credential availability.
  final AiIntegrationSettings ai;

  /// SMTP connection settings and saved credential availability.
  final SmtpIntegrationSettings smtp;

  /// Turnstile configuration and saved credential availability.
  final TurnstileIntegrationSettings turnstile;

  /// When this record was last updated.
  final DateTime? updatedAt;

  /// Creates AdminIntegrationSettings with the supplied values.
  const AdminIntegrationSettings({
    required this.ai,
    required this.smtp,
    required this.turnstile,
    this.updatedAt,
  });

  /// Decodes AdminIntegrationSettings from its JSON representation.
  factory AdminIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      AdminIntegrationSettings(
        ai: _object(json['ai'], AiIntegrationSettings.fromJson),
        smtp: _object(json['smtp'], SmtpIntegrationSettings.fromJson),
        turnstile: _object(
          json['turnstile'],
          TurnstileIntegrationSettings.fromJson,
        ),
        updatedAt: _optionalDate(json['updatedAt']),
      );
}

/// The selected AI provider and each provider's availability.
class AiIntegrationSettings {
  /// The AI provider selected for generation and translation.
  final AiProvider provider;

  /// Saved credential availability for Gemini.
  final AiProviderKeySettings gemini;

  /// Saved credential availability for OpenAI.
  final AiProviderKeySettings openai;

  /// Saved credential availability for Claude.
  final AiProviderKeySettings claude;

  /// Saved credential availability for Groq.
  final AiProviderKeySettings groq;

  /// Saved credential availability for Cerebras.
  final AiProviderKeySettings cerebras;

  /// Creates AiIntegrationSettings with the supplied values.
  const AiIntegrationSettings({
    required this.provider,
    required this.gemini,
    required this.openai,
    required this.claude,
    required this.groq,
    required this.cerebras,
  });

  /// Decodes AiIntegrationSettings from its JSON representation.
  factory AiIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      AiIntegrationSettings(
        provider: _enum(AiProvider.values, json['provider']),
        gemini: _object(json['gemini'], AiProviderKeySettings.fromJson),
        openai: _object(json['openai'], AiProviderKeySettings.fromJson),
        claude: _object(json['claude'], AiProviderKeySettings.fromJson),
        groq: _object(json['groq'], AiProviderKeySettings.fromJson),
        cerebras: _object(json['cerebras'], AiProviderKeySettings.fromJson),
      );
}

/// Whether an AI provider is enabled and has a saved API key.
class AiProviderKeySettings {
  /// Whether this provider is enabled for use.
  final bool enabled;

  /// Whether an API key is stored for this provider.
  final bool hasApiKey;

  /// Creates AiProviderKeySettings with the supplied values.
  const AiProviderKeySettings({
    required this.enabled,
    required this.hasApiKey,
  });

  /// Decodes AiProviderKeySettings from its JSON representation.
  factory AiProviderKeySettings.fromJson(Map<String, dynamic> json) =>
      AiProviderKeySettings(
        enabled: _bool(json['enabled']),
        hasApiKey: _bool(json['hasApiKey']),
      );
}

/// SMTP connection settings and saved password availability.
class SmtpIntegrationSettings {
  /// Whether the integration has the settings required for use.
  final bool configured;

  /// The host name of the SMTP server.
  final String? host;

  /// The TCP port used to connect to the SMTP server.
  final int? port;

  /// The username used for SMTP authentication, if required.
  final String? username;

  /// Whether an SMTP password is stored.
  final bool hasPassword;

  /// The email address used as the message sender.
  final String? fromEmail;

  /// The display name used for the message sender.
  final String? fromName;

  /// The transport security used for the SMTP connection.
  final SmtpSecureMode secureMode;

  /// Creates SmtpIntegrationSettings with the supplied values.
  const SmtpIntegrationSettings({
    required this.configured,
    this.host,
    this.port,
    this.username,
    required this.hasPassword,
    this.fromEmail,
    this.fromName,
    this.secureMode = SmtpSecureMode.starttls,
  });

  /// Decodes SmtpIntegrationSettings from its JSON representation.
  factory SmtpIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      SmtpIntegrationSettings(
        configured: _bool(json['configured']),
        host: _optionalString(json['host']),
        port: json['port'] == null ? null : _int(json['port']),
        username: _optionalString(json['username']),
        hasPassword: _bool(json['hasPassword']),
        fromEmail: _optionalString(json['fromEmail']),
        fromName: _optionalString(json['fromName']),
        secureMode: _enum(SmtpSecureMode.values, json['secureMode']),
      );
}

/// Whether Turnstile is configured and its keys are stored.
class TurnstileIntegrationSettings {
  /// Whether the integration has the settings required for use.
  final bool configured;

  /// Whether a public Turnstile site key is stored.
  final bool hasSiteKey;

  /// Whether a Turnstile secret key is stored.
  final bool hasSecretKey;

  /// Creates TurnstileIntegrationSettings with the supplied values.
  const TurnstileIntegrationSettings({
    required this.configured,
    required this.hasSiteKey,
    required this.hasSecretKey,
  });

  /// Decodes TurnstileIntegrationSettings from its JSON representation.
  factory TurnstileIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      TurnstileIntegrationSettings(
        configured: _bool(json['configured']),
        hasSiteKey: _bool(json['hasSiteKey']),
        hasSecretKey: _bool(json['hasSecretKey']),
      );
}

/// Values and explicit secret removal flags for an integration update.
class AdminIntegrationSettingsInput {
  /// The AI provider to select after saving the settings.
  final AiProvider aiProvider;

  /// A replacement Gemini API key, or null to preserve the stored key.
  final String? geminiApiKey;

  /// Whether to remove the stored Gemini API key.
  final bool clearGeminiApiKey;

  /// A replacement OpenAI API key, or null to preserve the stored key.
  final String? openaiApiKey;

  /// Whether to remove the stored OpenAI API key.
  final bool clearOpenaiApiKey;

  /// A replacement Claude API key, or null to preserve the stored key.
  final String? claudeApiKey;

  /// Whether to remove the stored Claude API key.
  final bool clearClaudeApiKey;

  /// A replacement Groq API key, or null to preserve the stored key.
  final String? groqApiKey;

  /// Whether to remove the stored Groq API key.
  final bool clearGroqApiKey;

  /// A replacement Cerebras API key, or null to preserve the stored key.
  final String? cerebrasApiKey;

  /// Whether to remove the stored Cerebras API key.
  final bool clearCerebrasApiKey;

  /// The host name of the SMTP server.
  final String? smtpHost;

  /// The TCP port used to connect to the SMTP server.
  final int? smtpPort;

  /// The username used for SMTP authentication, if required.
  final String? smtpUsername;

  /// A replacement SMTP password, or null to preserve the stored password.
  final String? smtpPassword;

  /// Whether to remove the stored SMTP password.
  final bool clearSmtpPassword;

  /// The email address used as the message sender.
  final String? smtpFromEmail;

  /// The display name used for the message sender.
  final String? smtpFromName;

  /// The transport security used for the SMTP connection.
  final SmtpSecureMode smtpSecureMode;

  /// The public Turnstile site key used by the CAPTCHA widget.
  final String? turnstileSiteKey;

  /// Whether to remove the stored Turnstile site key.
  final bool clearTurnstileSiteKey;

  /// A replacement Turnstile secret key, or null to preserve the stored key.
  final String? turnstileSecretKey;

  /// Whether to remove the stored Turnstile secret key.
  final bool clearTurnstileSecretKey;

  /// The timestamp of the settings snapshot used to build the form. The
  /// server rejects the save with 409 if someone else saved in between.
  final DateTime? expectedUpdatedAt;

  /// Creates AdminIntegrationSettingsInput with the supplied values.
  const AdminIntegrationSettingsInput({
    this.aiProvider = AiProvider.gemini,
    this.geminiApiKey,
    this.clearGeminiApiKey = false,
    this.openaiApiKey,
    this.clearOpenaiApiKey = false,
    this.claudeApiKey,
    this.clearClaudeApiKey = false,
    this.groqApiKey,
    this.clearGroqApiKey = false,
    this.cerebrasApiKey,
    this.clearCerebrasApiKey = false,
    this.smtpHost,
    this.smtpPort,
    this.smtpUsername,
    this.smtpPassword,
    this.clearSmtpPassword = false,
    this.smtpFromEmail,
    this.smtpFromName,
    this.smtpSecureMode = SmtpSecureMode.starttls,
    this.turnstileSiteKey,
    this.clearTurnstileSiteKey = false,
    this.turnstileSecretKey,
    this.clearTurnstileSecretKey = false,
    this.expectedUpdatedAt,
  });

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => {
    if (expectedUpdatedAt != null)
      'expectedUpdatedAt': expectedUpdatedAt!.toIso8601String(),
    'ai': {
      'provider': _enumName(aiProvider),
      'geminiApiKey': geminiApiKey,
      'clearGeminiApiKey': clearGeminiApiKey,
      'openaiApiKey': openaiApiKey,
      'clearOpenaiApiKey': clearOpenaiApiKey,
      'claudeApiKey': claudeApiKey,
      'clearClaudeApiKey': clearClaudeApiKey,
      'groqApiKey': groqApiKey,
      'clearGroqApiKey': clearGroqApiKey,
      'cerebrasApiKey': cerebrasApiKey,
      'clearCerebrasApiKey': clearCerebrasApiKey,
    },
    'smtp': {
      'host': smtpHost,
      'port': smtpPort,
      'username': smtpUsername,
      'password': smtpPassword,
      'clearPassword': clearSmtpPassword,
      'fromEmail': smtpFromEmail,
      'fromName': smtpFromName,
      'secureMode': _enumName(smtpSecureMode),
    },
    'turnstile': {
      'siteKey': turnstileSiteKey,
      'clearSiteKey': clearTurnstileSiteKey,
      'secretKey': turnstileSecretKey,
      'clearSecretKey': clearTurnstileSecretKey,
    },
  };
}
