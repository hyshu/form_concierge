enum AuthViewMode { login, register, verifyCode, setPassword }

class SurveyAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final AuthViewMode viewMode;
  final String? registrationRequestId;
  final String? registrationToken;
  final String? registrationEmail;

  const SurveyAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.viewMode = AuthViewMode.register,
    this.registrationRequestId,
    this.registrationToken,
    this.registrationEmail,
  });

  SurveyAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    AuthViewMode? viewMode,
    String? registrationRequestId,
    String? registrationToken,
    String? registrationEmail,
  }) {
    return SurveyAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      viewMode: viewMode ?? this.viewMode,
      registrationRequestId:
          registrationRequestId ?? this.registrationRequestId,
      registrationToken: registrationToken ?? this.registrationToken,
      registrationEmail: registrationEmail ?? this.registrationEmail,
    );
  }
}
