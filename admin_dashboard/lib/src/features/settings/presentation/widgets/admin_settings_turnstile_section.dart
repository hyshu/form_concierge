import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'admin_settings_form_widgets.dart';

/// Turnstile site key and secret key controls.
class AdminSettingsTurnstileSection extends StatelessWidget {
  /// Creates AdminSettingsTurnstileSection with the supplied values.
  const AdminSettingsTurnstileSection({
    super.key,
    required this.settings,
    required this.siteKeyController,
    required this.secretKeyController,
    required this.clearSiteKey,
    required this.clearSecretKey,
    required this.onClearSiteKeyChanged,
    required this.onClearSecretKeyChanged,
  });

  /// The settings currently displayed or edited.
  final TurnstileIntegrationSettings settings;

  /// Controls the site key input.
  final TextEditingController siteKeyController;

  /// Controls the secret key input.
  final TextEditingController secretKeyController;

  /// Whether saving the form should remove the stored Turnstile site key.
  final bool clearSiteKey;

  /// Whether saving the form should remove the stored Turnstile secret key.
  final bool clearSecretKey;

  /// Called when removal of the stored Turnstile site key is toggled.
  final ValueChanged<bool> onClearSiteKeyChanged;

  /// Called when removal of the stored Turnstile secret key is toggled.
  final ValueChanged<bool> onClearSecretKeyChanged;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => HuxCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSettingsSectionHeader(
          icon: LucideIcons.shieldCheck,
          title: context.tr('Turnstile CAPTCHA'),
          configured: settings.configured && !clearSiteKey && !clearSecretKey,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'Cloudflare Turnstile keys for bot protection. '
            'Create a widget in the Cloudflare dashboard, then paste both keys here.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        HuxInput(
          controller: siteKeyController,
          label: context.tr('Site Key'),
          hint: settings.hasSiteKey && !clearSiteKey
              ? context.tr('Leave blank to keep the saved site key')
              : null,
          prefixIcon: const Icon(LucideIcons.key),
          enabled: !clearSiteKey,
        ),
        if (settings.hasSiteKey) ...[
          const SizedBox(height: 12),
          AdminSettingsSwitchRow(
            label: context.tr('Clear saved site key'),
            value: clearSiteKey,
            onChanged: onClearSiteKeyChanged,
          ),
        ],
        const SizedBox(height: 16),
        HuxInput(
          controller: secretKeyController,
          label: context.tr('Secret Key'),
          hint: settings.hasSecretKey && !clearSecretKey
              ? context.tr('Leave blank to keep the saved secret key')
              : null,
          prefixIcon: const Icon(LucideIcons.lock),
          obscureText: true,
          enabled: !clearSecretKey,
        ),
        if (settings.hasSecretKey) ...[
          const SizedBox(height: 12),
          AdminSettingsSwitchRow(
            label: context.tr('Clear saved secret key'),
            value: clearSecretKey,
            onChanged: onClearSecretKeyChanged,
          ),
        ],
      ],
    ),
  );
}
