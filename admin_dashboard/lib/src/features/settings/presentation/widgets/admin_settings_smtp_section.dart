import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/email_validation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import 'admin_settings_form_widgets.dart';

/// SMTP connection, sender, and credential controls.
class AdminSettingsSmtpSection extends StatelessWidget {
  /// Creates AdminSettingsSmtpSection with the supplied values.
  const AdminSettingsSmtpSection({
    super.key,
    required this.settings,
    required this.hostController,
    required this.portController,
    required this.usernameController,
    required this.passwordController,
    required this.fromEmailController,
    required this.fromNameController,
    required this.secureMode,
    required this.clearPassword,
    required this.onSecureModeChanged,
    required this.onClearPasswordChanged,
  });

  /// The settings currently displayed or edited.
  final SmtpIntegrationSettings settings;

  /// Controls the host input.
  final TextEditingController hostController;

  /// Controls the port input.
  final TextEditingController portController;

  /// Controls the username input.
  final TextEditingController usernameController;

  /// Controls the password input.
  final TextEditingController passwordController;

  /// Controls the from email input.
  final TextEditingController fromEmailController;

  /// Controls the from name input.
  final TextEditingController fromNameController;

  /// The transport security used for the SMTP connection.
  final SmtpSecureMode secureMode;

  /// Whether saving the form should remove the stored SMTP password.
  final bool clearPassword;

  /// Called when the SMTP transport security selection changes.
  final ValueChanged<SmtpSecureMode> onSecureModeChanged;

  /// Called when removal of the stored SMTP password is toggled.
  final ValueChanged<bool> onClearPasswordChanged;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => HuxCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSettingsSectionHeader(
          icon: LucideIcons.mail,
          title: context.tr('SMTP Server'),
          configured: settings.configured,
        ),
        const SizedBox(height: 16),
        AdminSettingsResponsiveFields(
          children: [
            HuxInput(
              controller: hostController,
              label: context.tr('SMTP Host'),
              hint: 'smtp.resend.com',
              prefixIcon: const Icon(LucideIcons.server),
              validator: (_) => _smtpRequiredError(
                context,
                hostController.text.trim().isEmpty,
                'Host is required when SMTP settings are present',
              ),
            ),
            HuxInput(
              controller: portController,
              label: context.tr('SMTP Port'),
              hint: '465 (TLS) or 587 (STARTTLS)',
              prefixIcon: const Icon(LucideIcons.network),
              keyboardType: TextInputType.number,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return _smtpRequiredError(
                    context,
                    true,
                    'Port is required when SMTP settings are present',
                  );
                }
                final port = int.tryParse(trimmed);
                if (port == null || port < 1 || port > 65535 || port == 25) {
                  return context.tr('Port must be between 1 and 65535');
                }
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminSettingsResponsiveFields(
          children: [
            HuxInput(
              controller: usernameController,
              label: context.tr('Username (optional)'),
              prefixIcon: const Icon(LucideIcons.user),
            ),
            HuxInput(
              controller: passwordController,
              label: context.tr('SMTP Password'),
              hint: settings.hasPassword
                  ? context.tr('Leave blank to keep the saved password')
                  : null,
              prefixIcon: const Icon(LucideIcons.lock),
              obscureText: true,
              enabled: !clearPassword,
            ),
          ],
        ),
        if (settings.hasPassword) ...[
          const SizedBox(height: 12),
          AdminSettingsSwitchRow(
            label: context.tr('Clear saved SMTP password'),
            value: clearPassword,
            onChanged: onClearPasswordChanged,
          ),
        ],
        const SizedBox(height: 16),
        AdminSettingsResponsiveFields(
          children: [
            HuxInput(
              controller: fromEmailController,
              label: context.tr('From Email'),
              hint: 'forms@example.com',
              prefixIcon: const Icon(LucideIcons.mailCheck),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return _smtpRequiredError(
                    context,
                    true,
                    'From email is required when SMTP settings are present',
                  );
                }
                if (!isValidEmailAddress(trimmed)) {
                  return context.tr('Enter a valid email address');
                }
                return null;
              },
            ),
            HuxInput(
              controller: fromNameController,
              label: context.tr('From Name (optional)'),
              hint: 'Form Concierge',
              prefixIcon: const Icon(LucideIcons.signature),
            ),
          ],
        ),
        const SizedBox(height: 16),
        HuxLabeledControl(
          label: context.tr('Security'),
          child: HuxDropdown<SmtpSecureMode>(
            value: secureMode,
            useItemWidgetAsValue: true,
            items: [
              HuxDropdownItem(
                value: SmtpSecureMode.starttls,
                child: Text(context.tr('STARTTLS')),
              ),
              HuxDropdownItem(
                value: SmtpSecureMode.tls,
                child: Text(context.tr('TLS')),
              ),
              HuxDropdownItem(
                value: SmtpSecureMode.none,
                child: Text(context.tr('None')),
              ),
            ],
            onChanged: onSecureModeChanged,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'Port and Security must match: 465/2465 → TLS, 587/2587 → STARTTLS. '
            'Resend: host smtp.resend.com, username resend, password = API key.',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  String? _smtpRequiredError(
    BuildContext context,
    bool currentFieldEmpty,
    String messageKey,
  ) {
    if (!currentFieldEmpty) return null;
    final anySmtpField = [
      hostController.text,
      portController.text,
      usernameController.text,
      passwordController.text,
      fromEmailController.text,
      fromNameController.text,
    ].any((value) => value.trim().isNotEmpty);
    return anySmtpField ? context.tr(messageKey) : null;
  }
}
