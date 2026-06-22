import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/admin_settings_capsule.dart';
import '../widgets/admin_settings_form.dart';

class AdminSettingsPage extends RearchConsumer {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final manager = use(adminSettingsManagerCapsule);
    final client = use(clientCapsule);
    final isAdmin = client.auth.signedInUser?.role == AdminRole.admin;

    if (use.isFirstBuild() && isAdmin) {
      manager.loadSettings();
    }

    return HuxAdminShell(
      title: context.tr('Settings'),
      selectedItemId: 'settings',
      showUsers: isAdmin,
      showSettings: isAdmin,
      actions: [
        HuxButton(
          onPressed: isAdmin ? manager.loadSettings : null,
          variant: HuxButtonVariant.secondary,
          icon: LucideIcons.refreshCw,
          child: Text(context.tr('Refresh')),
        ),
      ],
      child: SafeArea(
        child: _buildBody(context, manager, isAdmin),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminSettingsManager manager,
    bool isAdmin,
  ) {
    if (!isAdmin) {
      return HuxPageBody(
        child: HuxErrorState(
          message: context.tr('Insufficient permissions'),
        ),
      );
    }

    if (manager.state.isLoading && manager.state.settings == null) {
      return const Center(child: HuxLoading(size: HuxLoadingSize.large));
    }

    if (manager.state.error != null && manager.state.settings == null) {
      return HuxPageBody(
        child: HuxErrorState(
          message: context.trMessage(manager.state.error!),
          onRetry: manager.loadSettings,
        ),
      );
    }

    final settings = manager.state.settings;
    if (settings == null) {
      return HuxPageBody(
        child: HuxEmptyState(
          icon: LucideIcons.settings,
          title: context.tr('Settings'),
          message: '',
          action: HuxButton(
            onPressed: manager.loadSettings,
            icon: LucideIcons.refreshCw,
            child: Text(context.tr('Refresh')),
          ),
        ),
      );
    }

    return AdminSettingsForm(
      settings: settings,
      isSaving: manager.state.isSaving,
      error: manager.state.error,
      successMessage: manager.state.successMessage,
      onSave: manager.saveSettings,
      onClearMessages: manager.clearMessages,
    );
  }
}
