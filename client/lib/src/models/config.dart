part of form_concierge_client;

class PublicConfig {
  final bool passwordResetEnabled;
  final bool requireEmailVerification;
  final bool aiGenerationEnabled;

  /// Cloudflare Turnstile site key (public). Null when CAPTCHA is not configured.
  final String? turnstileSiteKey;

  const PublicConfig({
    required this.passwordResetEnabled,
    required this.requireEmailVerification,
    required this.aiGenerationEnabled,
    this.turnstileSiteKey,
  });

  factory PublicConfig.fromJson(Map<String, dynamic> json) => PublicConfig(
    passwordResetEnabled: _bool(json['passwordResetEnabled']),
    requireEmailVerification: _bool(json['requireEmailVerification']),
    aiGenerationEnabled: _bool(json['aiGenerationEnabled']),
    turnstileSiteKey: _optionalString(json['turnstileSiteKey']),
  );

  Map<String, dynamic> toJson() => {
    'passwordResetEnabled': passwordResetEnabled,
    'requireEmailVerification': requireEmailVerification,
    'aiGenerationEnabled': aiGenerationEnabled,
    'turnstileSiteKey': turnstileSiteKey,
  };
}
