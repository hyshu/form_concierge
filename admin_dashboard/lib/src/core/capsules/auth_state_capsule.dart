import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';

import '../../features/auth/data/auth_state.dart';
import 'client_capsule.dart';

/// Capsule that manages authentication state.
AuthStateManager authStateCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(AuthState.initial());
  final client = use(clientCapsule);

  return AuthStateManager(
    state: state,
    setState: setState,
    client: client,
  );
}

/// Manager class for authentication operations.
class AuthStateManager {
  final AuthState state;
  final void Function(AuthState) _setState;
  final Client _client;

  AuthStateManager({
    required this.state,
    required void Function(AuthState) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Attempt to login with email and password.
  Future<void> login(String email, String password) async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final authSuccess = await _client.emailIdp.login(
        email: email,
        password: password,
      );

      // Store the auth success for authenticated requests
      await _client.auth.updateSignedInUser(authSuccess);

      _setState(
        state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          hasCheckedAuth: true,
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: _parseAuthError(e),
          hasCheckedAuth: true,
        ),
      );
    }
  }

  /// Check if we have a valid stored session.
  Future<void> checkAuth() async {
    _setState(state.copyWith(isLoading: true));
    try {
      // Load stored auth info
      await _client.auth.restore();
      final isAuthenticated = _client.auth.isAuthenticated;

      _setState(
        state.copyWith(
          isAuthenticated: isAuthenticated,
          isLoading: false,
          hasCheckedAuth: true,
        ),
      );
    } on Exception {
      _setState(
        state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          hasCheckedAuth: true,
        ),
      );
    }
  }

  /// Check if this is the first user (no users exist yet).
  Future<void> checkFirstUser() async {
    try {
      final isFirst = await _client.userAdmin.isFirstUser();
      _setState(
        state.copyWith(
          isFirstUser: isFirst,
          hasCheckedFirstUser: true,
        ),
      );
    } on Exception {
      _setState(
        state.copyWith(
          isFirstUser: false,
          hasCheckedFirstUser: true,
        ),
      );
    }
  }

  /// Register the first admin user.
  Future<void> registerFirstUser(String email, String password) async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final authSuccess = await _client.userAdmin.registerFirstUser(
        email: email,
        password: password,
      );

      // Store the auth success for authenticated requests
      await _client.auth.updateSignedInUser(authSuccess);

      _setState(
        state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          hasCheckedAuth: true,
          isFirstUser: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Registration failed: $e',
          hasCheckedAuth: true,
        ),
      );
    }
  }

  /// Logout and clear stored credentials.
  Future<void> logout() async {
    await _client.auth.signOutDevice();
    _setState(AuthState.initial().copyWith(hasCheckedAuth: true));
  }

  String _parseAuthError(Exception e) {
    final message = e.toString();
    if (message.contains('invalidCredentials')) {
      return 'Invalid email or password';
    }
    if (message.contains('tooManyAttempts')) {
      return 'Too many login attempts. Please try again later.';
    }
    return 'Login failed. Please try again.';
  }
}
