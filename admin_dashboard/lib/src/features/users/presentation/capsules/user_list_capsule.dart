import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/manager_operation.dart';

/// State for the user list.
class UserListState {
  /// The administrator accounts loaded for display.
  final List<AuthUserInfo> users;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Creates UserListState with the supplied values.
  const UserListState({
    this.users = const [],
    this.isLoading = true,
    this.error,
  });

  /// Creates the initial state before any data has been loaded.
  factory UserListState.initial() => const UserListState();

  /// Returns a copy with the supplied state changes.
  UserListState copyWith({
    List<AuthUserInfo>? users,
    bool? isLoading,
    String? error,
  }) => UserListState(
    users: users ?? this.users,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Capsule that manages the user list.
UserListManager userListCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(UserListState.initial());
  final client = use(clientCapsule);

  return UserListManager(
    state: state,
    setState: setState,
    client: client,
  );
}

/// Manager class for user list operations.
class UserListManager {
  /// The current state snapshot exposed by this manager.
  final UserListState state;
  final void Function(UserListState) _setState;
  final Client _client;

  /// Creates UserListManager with the supplied values.
  UserListManager({
    required this.state,
    required this._setState,
    required this._client,
  });

  /// Load all users.
  Future<void> loadUsers() async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final users = await _client.userAdmin.listUsers();
      _setState(state.copyWith(users: users, isLoading: false));
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load users: $e',
        ),
      );
    }
  }

  /// Create a new user.
  Future<bool> createUser({
    required String email,
    required String password,
    required AdminRole role,
  }) => runVoidAndReload(
    action: () => _client.userAdmin.createUser(
      email: email,
      password: password,
      role: role,
    ),
    reload: loadUsers,
    setError: _setError,
    errorMessage: 'Failed to create user',
  );

  /// Updates an administrator's role and refreshes the account list on success.
  Future<bool> updateUserRole(UuidValue userId, AdminRole role) =>
      runVoidAndReload(
        action: () => _client.userAdmin.updateRole(userId, role),
        reload: loadUsers,
        setError: _setError,
        errorMessage: 'Failed to update role',
      );

  /// Delete a user by ID.
  /// Returns (success, wasSelfDeletion) tuple.
  Future<(bool success, bool wasSelfDeletion)> deleteUser(
    UuidValue userId,
  ) async {
    try {
      final wasSelfDeletion = await _client.userAdmin.deleteUser(userId);
      if (!wasSelfDeletion) {
        await loadUsers();
      }
      return (true, wasSelfDeletion);
    } on Exception catch (e) {
      _setError('Failed to delete user: $e');
      return (false, false);
    }
  }

  void _setError(String error) => _setState(state.copyWith(error: error));

  /// Clear any error message.
  void clearError() => _setState(state.copyWith(error: null));
}
