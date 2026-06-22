import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';

class HuxAdminShell extends StatelessWidget {
  const HuxAdminShell({
    super.key,
    required this.title,
    required this.child,
    this.selectedItemId,
    this.actions = const [],
    this.onBack,
    this.showUsers = false,
  });

  final String title;
  final Widget child;
  final String? selectedItemId;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showUsers;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              _Sidebar(selectedItemId: selectedItemId, showUsers: showUsers),
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedItemId, required this.showUsers});

  final String? selectedItemId;
  final bool showUsers;

  @override
  Widget build(BuildContext context) {
    return HuxSidebar(
      width: 260,
      selectedItemId: selectedItemId,
      onItemSelected: (itemId) => _go(context, itemId),
      header: Row(
        children: [
          const Icon(LucideIcons.clipboardList, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('Form Concierge'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      items: [
        HuxSidebarItemData(
          id: 'surveys',
          icon: LucideIcons.layoutDashboard,
          label: context.tr('Surveys'),
        ),
        if (showUsers)
          HuxSidebarItemData(
            id: 'users',
            icon: LucideIcons.users,
            label: context.tr('User Management'),
          ),
      ],
    );
  }

  void _go(BuildContext context, String itemId) {
    switch (itemId) {
      case 'surveys':
        context.go('/admin');
      case 'users':
        context.go('/admin/users');
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.actions,
    required this.showMenu,
    required this.selectedItemId,
    required this.showUsers,
    this.onBack,
  });

  final String title;
  final List<Widget> actions;
  final bool showMenu;
  final String? selectedItemId;
  final bool showUsers;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
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
              HuxButton(
                onPressed: onBack,
                variant: HuxButtonVariant.ghost,
                size: HuxButtonSize.small,
                icon: LucideIcons.arrowLeft,
                child: const SizedBox(width: 0),
              ),
              const SizedBox(width: 8),
            ] else if (showMenu) ...[
              SizedBox(
                width: 180,
                child: HuxDropdown<String>(
                  value: selectedItemId ?? 'surveys',
                  useItemWidgetAsValue: true,
                  items: [
                    HuxDropdownItem(
                      value: 'surveys',
                      child: Text(context.tr('Surveys')),
                    ),
                    if (showUsers)
                      HuxDropdownItem(
                        value: 'users',
                        child: Text(context.tr('User Management')),
                      ),
                  ],
                  onChanged: (itemId) {
                    switch (itemId) {
                      case 'surveys':
                        context.go('/admin');
                      case 'users':
                        context.go('/admin/users');
                    }
                  },
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
