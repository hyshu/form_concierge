import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_states.dart';
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

    return HuxAdminShell(
      title: context.tr('User Management'),
      selectedItemId: 'users',
      showUsers: true,
      showSettings: true,
      actions: [
        HuxButton(
          onPressed: () => _showCreateUserDialog(context, manager),
          icon: LucideIcons.userPlus,
          child: Text(context.tr('Add User')),
        ),
      ],
      child: SafeArea(
        child: _buildBody(context, manager, authManager, currentUserId),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserListManager manager,
    AuthStateManager authManager,
    UuidValue? currentUserId,
  ) {
    if (manager.state.isLoading && manager.state.users.isEmpty) {
      return const Center(child: HuxLoading(size: HuxLoadingSize.large));
    }

    if (manager.state.error != null) {
      return HuxPageBody(
        child: HuxErrorState(
          message: context.trMessage(manager.state.error!),
          onRetry: () {
            manager.clearError();
            manager.loadUsers();
          },
        ),
      );
    }

    if (manager.state.users.isEmpty) {
      return HuxPageBody(
        child: HuxEmptyState(
          icon: LucideIcons.users,
          title: context.tr('No users yet'),
          message: context.tr('Add your first user to get started'),
          action: HuxButton(
            onPressed: () => _showCreateUserDialog(context, manager),
            icon: LucideIcons.userPlus,
            child: Text(context.tr('Add User')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => manager.loadUsers(),
      child: ListView.builder(
        itemCount: manager.state.users.length,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        itemBuilder: (context, index) {
          final user = manager.state.users[index];
          final isCurrentUser =
              currentUserId != null && user.id == currentUserId;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: UserListTile(
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
              ),
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
