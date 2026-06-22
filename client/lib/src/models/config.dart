part of form_concierge_client;

class PublicConfig {
  final bool passwordResetEnabled;
  final bool requireEmailVerification;
  final bool geminiEnabled;

  const PublicConfig({
    required this.passwordResetEnabled,
    required this.requireEmailVerification,
    required this.geminiEnabled,
  });

  factory PublicConfig.fromJson(Map<String, dynamic> json) => PublicConfig(
    passwordResetEnabled: _bool(json['passwordResetEnabled']),
    requireEmailVerification: _bool(json['requireEmailVerification']),
    geminiEnabled: _bool(json['geminiEnabled']),
  );

  Map<String, dynamic> toJson() => {
    'passwordResetEnabled': passwordResetEnabled,
    'requireEmailVerification': requireEmailVerification,
    'geminiEnabled': geminiEnabled,
  };
}
