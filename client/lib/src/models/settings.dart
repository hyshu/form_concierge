part of form_concierge_client;

enum AiProvider { gemini, openai, claude, cerebras }

enum SmtpSecureMode { none, starttls, tls }

class AdminIntegrationSettings {
  final AiIntegrationSettings ai;
  final SmtpIntegrationSettings smtp;
  final DateTime? updatedAt;

  const AdminIntegrationSettings({
    required this.ai,
    required this.smtp,
    this.updatedAt,
  });

  factory AdminIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      AdminIntegrationSettings(
        ai: _object(json['ai'], AiIntegrationSettings.fromJson),
        smtp: _object(json['smtp'], SmtpIntegrationSettings.fromJson),
        updatedAt: _optionalDate(json['updatedAt']),
      );
}

class AiIntegrationSettings {
  final AiProvider provider;
  final AiProviderKeySettings gemini;
  final AiProviderKeySettings openai;
  final AiProviderKeySettings claude;
  final AiProviderKeySettings cerebras;

  const AiIntegrationSettings({
    required this.provider,
    required this.gemini,
    required this.openai,
    required this.claude,
    required this.cerebras,
  });

  factory AiIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      AiIntegrationSettings(
        provider: _enum(AiProvider.values, json['provider']),
        gemini: _object(json['gemini'], AiProviderKeySettings.fromJson),
        openai: _object(json['openai'], AiProviderKeySettings.fromJson),
        claude: _object(json['claude'], AiProviderKeySettings.fromJson),
        cerebras: _object(json['cerebras'], AiProviderKeySettings.fromJson),
      );
}

class AiProviderKeySettings {
  final bool enabled;
  final bool hasApiKey;

  const AiProviderKeySettings({
    required this.enabled,
    required this.hasApiKey,
  });

  factory AiProviderKeySettings.fromJson(Map<String, dynamic> json) =>
      AiProviderKeySettings(
        enabled: _bool(json['enabled']),
        hasApiKey: _bool(json['hasApiKey']),
      );
}

class SmtpIntegrationSettings {
  final bool configured;
  final String? host;
  final int? port;
  final String? username;
  final bool hasPassword;
  final String? fromEmail;
  final String? fromName;
  final SmtpSecureMode secureMode;

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

class AdminIntegrationSettingsInput {
  final AiProvider aiProvider;
  final String? geminiApiKey;
  final bool clearGeminiApiKey;
  final String? openaiApiKey;
  final bool clearOpenaiApiKey;
  final String? claudeApiKey;
  final bool clearClaudeApiKey;
  final String? cerebrasApiKey;
  final bool clearCerebrasApiKey;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpUsername;
  final String? smtpPassword;
  final bool clearSmtpPassword;
  final String? smtpFromEmail;
  final String? smtpFromName;
  final SmtpSecureMode smtpSecureMode;

  const AdminIntegrationSettingsInput({
    this.aiProvider = AiProvider.gemini,
    this.geminiApiKey,
    this.clearGeminiApiKey = false,
    this.openaiApiKey,
    this.clearOpenaiApiKey = false,
    this.claudeApiKey,
    this.clearClaudeApiKey = false,
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
  });

  Map<String, dynamic> toJson() => {
    'ai': {
      'provider': _enumName(aiProvider),
      'geminiApiKey': geminiApiKey,
      'clearGeminiApiKey': clearGeminiApiKey,
      'openaiApiKey': openaiApiKey,
      'clearOpenaiApiKey': clearOpenaiApiKey,
      'claudeApiKey': claudeApiKey,
      'clearClaudeApiKey': clearClaudeApiKey,
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
  };
}
