/// Immutable authentication state.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool hasCheckedAuth;
  final bool? isFirstUser;
  final bool hasCheckedFirstUser;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.hasCheckedAuth = false,
    this.isFirstUser,
    this.hasCheckedFirstUser = false,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? hasCheckedAuth,
    bool? isFirstUser,
    bool? hasCheckedFirstUser,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    hasCheckedAuth: hasCheckedAuth ?? this.hasCheckedAuth,
    isFirstUser: isFirstUser ?? this.isFirstUser,
    hasCheckedFirstUser: hasCheckedFirstUser ?? this.hasCheckedFirstUser,
  );
}
