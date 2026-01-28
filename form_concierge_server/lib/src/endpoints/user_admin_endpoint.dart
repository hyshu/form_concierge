import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import '../generated/auth_user_info.dart';
import '../utils/exceptions.dart';

/// Admin endpoint for managing users.
/// Most methods require authentication, except for first user registration.
class UserAdminEndpoint extends Endpoint {
  /// Check if this is the first user (no users exist yet).
  /// This endpoint is public - no authentication required.
  Future<bool> isFirstUser(Session session) async {
    final count = await AuthUser.db.count(session);
    return count == 0;
  }

  /// Register the first admin user.
  /// Only works if no users exist yet.
  Future<AuthSuccess> registerFirstUser(
    Session session, {
    required String email,
    required String password,
  }) async {
    // Check if this is really the first user
    final count = await AuthUser.db.count(session);
    if (count > 0) {
      throw const ValidationException(
        'Registration closed. Please contact an administrator.',
      );
    }

    // Create the first auth user with admin scope
    final authUsers = AuthUsers();
    final newUser = await authUsers.create(
      session,
      scopes: {Scope('admin'), Scope('user')},
    );

    // Link email account
    await AuthServices.instance.emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: newUser.id,
      email: email,
      password: password,
    );

    // Login and return auth success
    return AuthServices.instance.emailIdp.login(
      session,
      email: email,
      password: password,
    );
  }

  /// Get all users. Requires admin scope.
  Future<List<AuthUserInfo>> listUsers(Session session) async {
    await _requireAdminScope(session);

    final users = await AuthUser.db.find(session);
    final result = <AuthUserInfo>[];

    for (final user in users) {
      final emailAccount = await EmailAccount.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(user.id!),
      );

      result.add(
        AuthUserInfo(
          id: user.id!,
          email: emailAccount?.email,
          scopeNames: user.scopeNames.toList(),
          blocked: user.blocked,
          created: user.createdAt,
        ),
      );
    }

    return result;
  }

  /// Create a new user. Requires admin scope.
  Future<AuthUserInfo> createUser(
    Session session, {
    required String email,
    required String password,
    required List<String> scopes,
  }) async {
    await _requireAdminScope(session);

    // Create auth user with specified scopes
    final authUsers = AuthUsers();
    final newUser = await authUsers.create(
      session,
      scopes: scopes.map((s) => Scope(s)).toSet(),
    );

    // Link email account
    await AuthServices.instance.emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: newUser.id,
      email: email,
      password: password,
    );

    return AuthUserInfo(
      id: newUser.id,
      email: email,
      scopeNames: scopes,
      blocked: false,
      created: newUser.createdAt,
    );
  }

  /// Delete a user. Requires admin scope.
  ///
  /// Returns `true` if the deleted user was the current user (self-deletion),
  /// `false` otherwise (including when the user was not found).
  Future<bool> deleteUser(Session session, UuidValue userId) async {
    await _requireAdminScope(session);

    // Check if deleting self
    final currentUserId = session.authenticated?.authUserId;
    final isSelfDeletion = currentUserId == userId;

    // Delete auth user (email account will be deleted by cascade)
    final authUsers = AuthUsers();
    try {
      await authUsers.delete(session, authUserId: userId);
      return isSelfDeletion;
    } on AuthUserNotFoundException {
      return false;
    }
  }

  /// Toggle user blocked status. Requires admin scope.
  Future<bool> toggleUserBlocked(Session session, UuidValue userId) async {
    await _requireAdminScope(session);

    final user = await AuthUser.db.findById(session, userId);
    if (user == null) {
      throw NotFoundException('User', userId);
    }

    final authUsers = AuthUsers();
    final updated = await authUsers.update(
      session,
      authUserId: userId,
      blocked: !user.blocked,
    );

    return updated.blocked;
  }

  Future<void> _requireAdminScope(Session session) async {
    final identity = session.authenticated;
    if (identity == null) {
      throw const UnauthorizedException('Not authenticated.');
    }

    final hasAdmin = identity.scopes.any((s) => s.name == 'admin');
    if (!hasAdmin) {
      throw const UnauthorizedException('Admin scope required.');
    }
  }
}
