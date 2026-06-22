import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../capsules/user_list_capsule.dart';
import '../widgets/create_user_dialog.dart';
import '../widgets/user_list_tile.dart';

class UsersPage extends RearchConsumer {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final manager = use(userListCapsule);
    final authManager = use(authStateCapsule);
    final client = use(clientCapsule);

    // Load users on first build
    if (use.isFirstBuild()) {
      manager.loadUsers();
    }

    // Get current user ID
    final currentUserId = client.auth.signedInUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('User Management')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
          tooltip: context.tr('Back'),
        ),
      ),
      body: SafeArea(
        child: _buildBody(context, manager, authManager, currentUserId),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, manager),
        icon: const Icon(Icons.person_add),
        label: Text(context.tr('Add User')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserListManager manager,
    AuthStateManager authManager,
    UuidValue? currentUserId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (manager.state.isLoading && manager.state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (manager.state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              context.trMessage(manager.state.error!),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                manager.clearError();
                manager.loadUsers();
              },
              child: Text(context.tr('Retry')),
            ),
          ],
        ),
      );
    }

    if (manager.state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              context.tr('No users yet'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Add your first user to get started'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => manager.loadUsers(),
      child: ListView.builder(
        itemCount: manager.state.users.length,
        itemBuilder: (context, index) {
          final user = manager.state.users[index];
          final isCurrentUser =
              currentUserId != null && user.id == currentUserId;
          return UserListTile(
            user: user,
            isCurrentUser: isCurrentUser,
            onToggleBlocked: () => manager.toggleUserBlocked(user.id),
            onRoleChanged: (role) => manager.updateUserRole(user.id, role),
            onDelete: () => _confirmDelete(
              context,
              manager,
              authManager,
              user,
              isCurrentUser,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateUserDialog(
    BuildContext context,
    UserListManager manager,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );

    if (result != null) {
      await manager.createUser(
        email: result['email'] as String,
        password: result['password'] as String,
        role: result['role'] as AdminRole,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserListManager manager,
    AuthStateManager authManager,
    AuthUserInfo user,
    bool isCurrentUser,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: context.tr(isCurrentUser ? 'Delete Your Account' : 'Delete User'),
      content: isCurrentUser
          ? context.tr('Delete your account confirmation')
          : context.tr('Delete user confirmation', {'email': user.email}),
    );

    if (confirmed) {
      final (success, wasSelfDeletion) = await manager.deleteUser(user.id);
      if (success && wasSelfDeletion && context.mounted) {
        await authManager.logout();
        if (context.mounted) {
          context.go('/login');
        }
      }
    }
  }
}
