import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/email_validation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import 'admin_settings_form_widgets.dart';

class AdminSettingsSmtpSection extends StatelessWidget {
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

  final SmtpIntegrationSettings settings;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController fromEmailController;
  final TextEditingController fromNameController;
  final SmtpSecureMode secureMode;
  final bool clearPassword;
  final ValueChanged<SmtpSecureMode> onSecureModeChanged;
  final ValueChanged<bool> onClearPasswordChanged;

  @override
  Widget build(BuildContext context) {
    return HuxCard(
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
                hint: 'smtp.example.com',
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
                hint: '587',
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
        ],
      ),
    );
  }

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
