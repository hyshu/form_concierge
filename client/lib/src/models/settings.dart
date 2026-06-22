part of form_concierge_client;

enum SmtpSecureMode { none, starttls, tls }

class AdminIntegrationSettings {
  final GeminiIntegrationSettings gemini;
  final SmtpIntegrationSettings smtp;
  final DateTime? updatedAt;

  const AdminIntegrationSettings({
    required this.gemini,
    required this.smtp,
    this.updatedAt,
  });

  factory AdminIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      AdminIntegrationSettings(
        gemini: _object(json['gemini'], GeminiIntegrationSettings.fromJson),
        smtp: _object(json['smtp'], SmtpIntegrationSettings.fromJson),
        updatedAt: _optionalDate(json['updatedAt']),
      );
}

class GeminiIntegrationSettings {
  final bool enabled;
  final bool hasApiKey;

  const GeminiIntegrationSettings({
    required this.enabled,
    required this.hasApiKey,
  });

  factory GeminiIntegrationSettings.fromJson(Map<String, dynamic> json) =>
      GeminiIntegrationSettings(
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
        host: json['host'] as String?,
        port: json['port'] == null ? null : _int(json['port']),
        username: json['username'] as String?,
        hasPassword: _bool(json['hasPassword']),
        fromEmail: json['fromEmail'] as String?,
        fromName: json['fromName'] as String?,
        secureMode: _enum(
          SmtpSecureMode.values,
          json['secureMode'],
          SmtpSecureMode.starttls,
        ),
      );
}

class AdminIntegrationSettingsInput {
  final String? geminiApiKey;
  final bool clearGeminiApiKey;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpUsername;
  final String? smtpPassword;
  final bool clearSmtpPassword;
  final String? smtpFromEmail;
  final String? smtpFromName;
  final SmtpSecureMode smtpSecureMode;

  const AdminIntegrationSettingsInput({
    this.geminiApiKey,
    this.clearGeminiApiKey = false,
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
    'gemini': {
      'apiKey': geminiApiKey,
      'clearApiKey': clearGeminiApiKey,
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
