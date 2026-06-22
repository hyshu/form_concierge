import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';

/// State for the user list.
class UserListState {
  final List<AuthUserInfo> users;
  final bool isLoading;
  final String? error;

  const UserListState({
    this.users = const [],
    this.isLoading = true,
    this.error,
  });

  factory UserListState.initial() => const UserListState();

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
  final UserListState state;
  final void Function(UserListState) _setState;
  final Client _client;

  UserListManager({
    required this.state,
    required void Function(UserListState) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

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
  }) async {
    return _runAndReload(
      () => _client.userAdmin.createUser(
        email: email,
        password: password,
        role: role,
      ),
      'Failed to create user',
    );
  }

  Future<bool> updateUserRole(UuidValue userId, AdminRole role) async {
    return _runAndReload(
      () => _client.userAdmin.updateRole(userId, role),
      'Failed to update role',
    );
  }

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
      _setState(state.copyWith(error: 'Failed to delete user: $e'));
      return (false, false);
    }
  }

  /// Toggle user blocked status.
  Future<bool> toggleUserBlocked(UuidValue userId) async {
    return _runAndReload(
      () => _client.userAdmin.toggleUserBlocked(userId),
      'Failed to update user',
    );
  }

  Future<bool> _runAndReload(
    Future<void> Function() action,
    String errorMessage,
  ) async {
    try {
      await action();
      await loadUsers();
      return true;
    } on Exception catch (e) {
      _setState(state.copyWith(error: '$errorMessage: $e'));
      return false;
    }
  }

  /// Clear any error message.
  void clearError() {
    _setState(state.copyWith(error: null));
  }
}
