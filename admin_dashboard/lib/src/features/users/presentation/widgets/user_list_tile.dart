import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

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
    return HuxCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final details = _UserDetails(
            user: user,
            isCurrentUser: isCurrentUser,
          );
          final controls = _UserControls(
            user: user,
            onToggleBlocked: onToggleBlocked,
            onRoleChanged: onRoleChanged,
            onDelete: onDelete,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserIcon(blocked: user.blocked),
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 16),
                controls,
              ],
            );
          }

          return Row(
            children: [
              _UserIcon(blocked: user.blocked),
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 16),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _UserDetails extends StatelessWidget {
  const _UserDetails({required this.user, required this.isCurrentUser});

  final AuthUserInfo user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              user.email ?? context.tr('No email'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isCurrentUser)
              HuxBadge(
                label: context.tr('You'),
                variant: HuxBadgeVariant.primary,
                size: HuxBadgeSize.small,
              ),
            if (user.blocked)
              HuxBadge(
                label: context.tr('Blocked'),
                variant: HuxBadgeVariant.destructive,
                size: HuxBadgeSize.small,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(_roleLabel(user.role)),
          style: TextStyle(color: HuxTokens.textSecondary(context)),
        ),
      ],
    );
  }
}

class _UserControls extends StatelessWidget {
  const _UserControls({
    required this.user,
    required this.onToggleBlocked,
    required this.onRoleChanged,
    required this.onDelete,
  });

  final AuthUserInfo user;
  final VoidCallback onToggleBlocked;
  final ValueChanged<AdminRole> onRoleChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 180,
          child: HuxDropdown<AdminRole>(
            value: user.role,
            useItemWidgetAsValue: true,
            items: [
              HuxDropdownItem(
                value: AdminRole.admin,
                child: Text(context.tr('Admin')),
              ),
              HuxDropdownItem(
                value: AdminRole.editor,
                child: Text(context.tr('Editor')),
              ),
              HuxDropdownItem(
                value: AdminRole.viewer,
                child: Text(context.tr('Viewer')),
              ),
            ],
            onChanged: onRoleChanged,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HuxSwitch(
              value: !user.blocked,
              onChanged: (_) => onToggleBlocked(),
            ),
            const SizedBox(width: 8),
            Text(context.tr(user.blocked ? 'Unblock' : 'Block')),
          ],
        ),
        Tooltip(
          message: context.tr('Delete'),
          child: HuxButton(
            onPressed: onDelete,
            variant: HuxButtonVariant.ghost,
            size: HuxButtonSize.small,
            icon: LucideIcons.trash2,
            textColor: HuxTokens.textDestructive(context),
            child: const SizedBox(width: 0),
          ),
        ),
      ],
    );
  }
}

class _UserIcon extends StatelessWidget {
  const _UserIcon({required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: blocked
            ? HuxTokens.surfaceDestructive(context)
            : HuxTokens.primary(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HuxTokens.borderPrimary(context)),
      ),
      alignment: Alignment.center,
      child: Icon(
        blocked ? LucideIcons.userX : LucideIcons.user,
        color: blocked
            ? HuxTokens.textDestructive(context)
            : HuxTokens.primary(context),
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
