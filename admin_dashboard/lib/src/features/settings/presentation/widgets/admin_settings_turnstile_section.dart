import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'admin_settings_form_widgets.dart';

class AdminSettingsTurnstileSection extends StatelessWidget {
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

  final TurnstileIntegrationSettings settings;
  final TextEditingController siteKeyController;
  final TextEditingController secretKeyController;
  final bool clearSiteKey;
  final bool clearSecretKey;
  final ValueChanged<bool> onClearSiteKeyChanged;
  final ValueChanged<bool> onClearSecretKeyChanged;

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
