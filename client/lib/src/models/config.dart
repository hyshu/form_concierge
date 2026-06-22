part of form_concierge_client;

class PublicConfig {
  final bool passwordResetEnabled;
  final bool requireEmailVerification;
  final bool aiGenerationEnabled;

  const PublicConfig({
    required this.passwordResetEnabled,
    required this.requireEmailVerification,
    required this.aiGenerationEnabled,
  });

  factory PublicConfig.fromJson(Map<String, dynamic> json) => PublicConfig(
    passwordResetEnabled: _bool(json['passwordResetEnabled']),
    requireEmailVerification: _bool(json['requireEmailVerification']),
    aiGenerationEnabled: _bool(json['aiGenerationEnabled']),
  );

  Map<String, dynamic> toJson() => {
    'passwordResetEnabled': passwordResetEnabled,
    'requireEmailVerification': requireEmailVerification,
    'aiGenerationEnabled': aiGenerationEnabled,
  };
}
