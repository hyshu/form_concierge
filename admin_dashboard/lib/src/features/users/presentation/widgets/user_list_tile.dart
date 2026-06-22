import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    required this.onToggleBlocked,
    required this.onRoleChanged,
    required this.onDelete,
    this.isCurrentUser = false,
  });

  final AuthUserInfo user;
  final VoidCallback onToggleBlocked;
  final ValueChanged<AdminRole> onRoleChanged;
  final VoidCallback onDelete;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.blocked
            ? colorScheme.errorContainer
            : colorScheme.primary,
        child: Icon(
          user.blocked ? Icons.block : Icons.person,
          color: user.blocked
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimary,
        ),
      ),
      title: Row(
        children: [
          Text(user.email ?? 'No email'),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Chip(
              label: const Text('You'),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              backgroundColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        _roleLabel(user.role),
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.blocked)
            Chip(
              label: const Text('Blocked'),
              backgroundColor: colorScheme.errorContainer,
              labelStyle: TextStyle(color: colorScheme.onErrorContainer),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'role_admin':
                  onRoleChanged(AdminRole.admin);
                case 'role_editor':
                  onRoleChanged(AdminRole.editor);
                case 'role_viewer':
                  onRoleChanged(AdminRole.viewer);
                case 'toggle_block':
                  onToggleBlocked();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'role_admin',
                child: ListTile(
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text('Make admin'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'role_editor',
                child: ListTile(
                  leading: Icon(Icons.edit_note_outlined),
                  title: Text('Make editor'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'role_viewer',
                child: ListTile(
                  leading: Icon(Icons.visibility_outlined),
                  title: Text('Make viewer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_block',
                child: ListTile(
                  leading: Icon(
                    user.blocked ? Icons.check_circle : Icons.block,
                    color: user.blocked
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                  title: Text(user.blocked ? 'Unblock' : 'Block'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: const Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _roleLabel(AdminRole role) {
  return switch (role) {
    AdminRole.admin => 'Admin',
    AdminRole.editor => 'Editor',
    AdminRole.viewer => 'Viewer',
  };
}
