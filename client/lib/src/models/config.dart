part of form_concierge_client;

/// Public feature flags and CAPTCHA configuration for clients.
class PublicConfig {
  /// Whether the server advertises password reset support.
  final bool passwordResetEnabled;

  /// Whether administrator email verification is required.
  final bool requireEmailVerification;

  /// Whether AI-assisted content generation is available.
  final bool aiGenerationEnabled;

  /// Cloudflare Turnstile site key (public). Null when CAPTCHA is not configured.
  final String? turnstileSiteKey;

  /// Creates PublicConfig with the supplied values.
  const PublicConfig({
    required this.passwordResetEnabled,
    required this.requireEmailVerification,
    required this.aiGenerationEnabled,
    this.turnstileSiteKey,
  });

  /// Decodes PublicConfig from its JSON representation.
  factory PublicConfig.fromJson(Map<String, dynamic> json) => PublicConfig(
    passwordResetEnabled: _bool(json['passwordResetEnabled']),
    requireEmailVerification: _bool(json['requireEmailVerification']),
    aiGenerationEnabled: _bool(json['aiGenerationEnabled']),
    turnstileSiteKey: _optionalString(json['turnstileSiteKey']),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => {
    'passwordResetEnabled': passwordResetEnabled,
    'requireEmailVerification': requireEmailVerification,
    'aiGenerationEnabled': aiGenerationEnabled,
    'turnstileSiteKey': turnstileSiteKey,
  };
}
