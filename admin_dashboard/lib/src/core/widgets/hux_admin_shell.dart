import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';
import 'hux_icon_action_button.dart';

class HuxAdminShell extends StatelessWidget {
  const HuxAdminShell({
    super.key,
    required this.title,
    required this.child,
    this.selectedItemId,
    this.actions = const [],
    this.onBack,
    this.showUsers = false,
    this.showSettings = false,
  });

  final String title;
  final Widget child;
  final String? selectedItemId;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showUsers;
  final bool showSettings;

  @override
  Widget build(context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              _StaticSidebar(
                selectedItemId: selectedItemId,
                showUsers: showUsers,
                showSettings: showSettings,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: title,
                    actions: actions,
                    onBack: onBack,
                    showMenu: !isWide,
                    selectedItemId: selectedItemId,
                    showUsers: showUsers,
                    showSettings: showSettings,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticSidebar extends StatelessWidget {
  const _StaticSidebar({
    required this.selectedItemId,
    required this.showUsers,
    required this.showSettings,
  });

  final String? selectedItemId;
  final bool showUsers;
  final bool showSettings;

  @override
  Widget build(context) {
    final items = _navigationItems(
      context,
      showUsers: showUsers,
      showSettings: showSettings,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HuxTokens.surfacePrimary(context),
        border: Border(
          right: BorderSide(color: HuxTokens.borderSecondary(context)),
        ),
      ),
      child: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clipboardList,
                    size: 26,
                    color: HuxTokens.iconPrimary(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('Form Concierge'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HuxTokens.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (final item in items) ...[
                _SidebarNavigationItem(
                  item: item,
                  selected: selectedItemId == item.id,
                  onTap: () => _goToNavigationItem(context, item.id),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavigationItem extends StatelessWidget {
  const _SidebarNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(context) {
    final textColor = selected
        ? HuxTokens.primary(context)
        : HuxTokens.textSecondary(context);
    final iconColor = selected
        ? HuxTokens.primary(context)
        : HuxTokens.iconSecondary(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (selected) {
              return Colors.transparent;
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return HuxTokens.surfaceHover(context);
            }
            return Colors.transparent;
          }),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? HuxTokens.surfaceSecondary(context)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final IconData icon;
  final String label;
}

List<_NavigationItem> _navigationItems(
  BuildContext context, {
  required bool showUsers,
  required bool showSettings,
}) => [
  _NavigationItem(
    id: 'surveys',
    icon: LucideIcons.layoutDashboard,
    label: context.tr('Surveys'),
  ),
  if (showUsers)
    _NavigationItem(
      id: 'users',
      icon: LucideIcons.users,
      label: context.tr('User Management'),
    ),
  if (showSettings)
    _NavigationItem(
      id: 'settings',
      icon: LucideIcons.settings,
      label: context.tr('Settings'),
    ),
];

void _goToNavigationItem(BuildContext context, String itemId) {
  switch (itemId) {
    case 'surveys':
      context.go('/admin');
      return;
    case 'users':
      context.go('/admin/users');
      return;
    case 'settings':
      context.go('/admin/settings');
      return;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.actions,
    required this.showMenu,
    required this.selectedItemId,
    required this.showUsers,
    required this.showSettings,
    this.onBack,
  });

  final String title;
  final List<Widget> actions;
  final bool showMenu;
  final String? selectedItemId;
  final bool showUsers;
  final bool showSettings;
  final VoidCallback? onBack;

  @override
  Widget build(context) {
    final items = _navigationItems(
      context,
      showUsers: showUsers,
      showSettings: showSettings,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HuxTokens.surfacePrimary(context),
        border: Border(
          bottom: BorderSide(color: HuxTokens.borderSecondary(context)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            if (onBack != null) ...[
              HuxIconActionButton(
                onPressed: onBack,
                icon: LucideIcons.arrowLeft,
                tooltip: context.tr('Back'),
              ),
              const SizedBox(width: 8),
            ] else if (showMenu) ...[
              SizedBox(
                width: 180,
                child: HuxDropdown<String>(
                  value: selectedItemId ?? 'surveys',
                  useItemWidgetAsValue: true,
                  items: [
                    for (final item in items)
                      HuxDropdownItem(
                        value: item.id,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (itemId) => _goToNavigationItem(context, itemId),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
