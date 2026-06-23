import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';

/// View for configuring response email notifications.
class NotificationSettingsView extends StatefulWidget {
  final int surveyId;
  final NotificationSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final bool isSendingTest;
  final String? error;
  final String? successMessage;
  final bool isEmailConfigured;
  final Future<void> Function() onRefresh;
  final Future<bool> Function(NotificationSettings settings) onSave;
  final Future<bool> Function() onToggleEnabled;
  final Future<bool> Function() onSendTest;
  final VoidCallback onClearMessages;

  const NotificationSettingsView({
    super.key,
    required this.surveyId,
    required this.settings,
    required this.isLoading,
    required this.isSaving,
    required this.isSendingTest,
    this.error,
    this.successMessage,
    required this.isEmailConfigured,
    required this.onRefresh,
    required this.onSave,
    required this.onToggleEnabled,
    required this.onSendTest,
    required this.onClearMessages,
  });

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.settings?.recipientEmail ?? '',
    );
    _emailController.addListener(_onFormChanged);
  }

  @override
  void didUpdateWidget(NotificationSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings && widget.settings != null) {
      _emailController.text = widget.settings!.recipientEmail;
      _hasChanges = false;
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFormChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = NotificationSettings(
      surveyId: widget.surveyId,
      enabled: widget.settings?.enabled ?? false,
      recipientEmail: _emailController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await widget.onSave(settings);
    if (success) {
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.settings == null) {
      return HuxLoadingState(
        message: context.tr('Loading...'),
        padding: const EdgeInsets.only(top: 16, bottom: 16),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isEmailConfigured) ...[
            HuxMessageCard(
              icon: LucideIcons.triangleAlert,
              message: context.tr(
                'Email service is not configured. Contact your administrator to enable SMTP settings.',
              ),
              destructive: true,
            ),
            const SizedBox(height: 16),
          ],
          HuxFeedbackMessages(
            error: widget.error,
            successMessage: widget.successMessage,
            onClose: widget.onClearMessages,
          ),
          HuxCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.bell,
                        color: HuxTokens.primary(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('Email Notifications'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Send an email every time a new response is submitted.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HuxTokens.textSecondary(context),
                    ),
                  ),
                  Divider(
                    height: 32,
                    color: HuxTokens.borderSecondary(context),
                  ),
                  HuxInput(
                    controller: _emailController,
                    label: context.tr('Recipient Email'),
                    hint: 'email@example.com',
                    prefixIcon: const Icon(LucideIcons.mail),
                    keyboardType: TextInputType.emailAddress,
                    enabled: widget.isEmailConfigured,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('Email is required');
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return context.tr('Enter a valid email address');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  HuxButton(
                    onPressed:
                        widget.isEmailConfigured &&
                            !widget.isSaving &&
                            (_hasChanges || widget.settings == null)
                        ? _onSave
                        : null,
                    isLoading: widget.isSaving,
                    width: HuxButtonWidth.expand,
                    icon: LucideIcons.save,
                    child: Text(
                      context.tr(
                        widget.settings == null
                            ? 'Create Settings'
                            : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.settings != null) ...[
            const SizedBox(height: 16),
            HuxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.settings!.enabled
                            ? LucideIcons.bellRing
                            : LucideIcons.bellOff,
                        color: widget.settings!.enabled
                            ? HuxTokens.primary(context)
                            : HuxTokens.iconSecondary(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('Enable Notifications')),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(
                                widget.settings!.enabled
                                    ? 'Response notifications are active'
                                    : 'Response notifications are paused',
                              ),
                              style: TextStyle(
                                color: HuxTokens.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      HuxSwitch(
                        value: widget.settings!.enabled,
                        isDisabled:
                            !widget.isEmailConfigured || widget.isSaving,
                        onChanged: (_) {
                          widget.onToggleEnabled();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HuxButton(
                    onPressed:
                        widget.isEmailConfigured &&
                            !widget.isSendingTest &&
                            !widget.isSaving
                        ? widget.onSendTest
                        : null,
                    isLoading: widget.isSendingTest,
                    width: HuxButtonWidth.expand,
                    variant: HuxButtonVariant.outline,
                    icon: LucideIcons.send,
                    child: Text(context.tr('Send Test Notification')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
