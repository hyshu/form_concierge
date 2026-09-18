/// Immutable authentication state.
class AuthState {
  /// Whether a token is set locally, without checking its server validity.
  final bool isAuthenticated;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Whether the initial attempt to restore administrator authentication has finished.
  final bool hasCheckedAuth;

  /// Returns whether the server is waiting for its first administrator account.
  final bool? isFirstUser;

  /// Whether the server's first-administrator status has been checked.
  final bool hasCheckedFirstUser;

  /// Whether the first-administrator status request is in progress.
  final bool isCheckingFirstUser;

  /// Whether the authentication interface requires a CAPTCHA challenge.
  final bool captchaRequired;

  /// Creates AuthState with the supplied values.
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.hasCheckedAuth = false,
    this.isFirstUser,
    this.hasCheckedFirstUser = false,
    this.isCheckingFirstUser = false,
    this.captchaRequired = false,
  });

  /// Creates the initial state before any data has been loaded.
  factory AuthState.initial() => const AuthState();

  /// Returns a copy with the supplied state changes.
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? hasCheckedAuth,
    bool? isFirstUser,
    bool? hasCheckedFirstUser,
    bool? isCheckingFirstUser,
    bool? captchaRequired,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    hasCheckedAuth: hasCheckedAuth ?? this.hasCheckedAuth,
    isFirstUser: isFirstUser ?? this.isFirstUser,
    hasCheckedFirstUser: hasCheckedFirstUser ?? this.hasCheckedFirstUser,
    isCheckingFirstUser: isCheckingFirstUser ?? this.isCheckingFirstUser,
    captchaRequired: captchaRequired ?? this.captchaRequired,
  );
}
