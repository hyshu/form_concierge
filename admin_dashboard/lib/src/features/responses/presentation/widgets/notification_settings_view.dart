import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

/// View for configuring daily email notifications.
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
  late int _selectedHour;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.settings?.recipientEmail ?? '',
    );
    _selectedHour = widget.settings?.sendHour ?? 9;
    _emailController.addListener(_onFormChanged);
  }

  @override
  void didUpdateWidget(NotificationSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings && widget.settings != null) {
      _emailController.text = widget.settings!.recipientEmail;
      _selectedHour = widget.settings!.sendHour;
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

  void _onHourChanged(int value) {
    setState(() {
      _selectedHour = value;
      _hasChanges = true;
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = NotificationSettings(
      surveyId: widget.surveyId,
      enabled: widget.settings?.enabled ?? false,
      recipientEmail: _emailController.text.trim(),
      sendHour: _selectedHour,
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
      return const Center(child: HuxLoading(size: HuxLoadingSize.large));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isEmailConfigured) ...[
            _MessageCard(
              icon: LucideIcons.triangleAlert,
              message: context.tr(
                'Email service is not configured. Contact your administrator to enable SMTP settings.',
              ),
              destructive: true,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.error != null) ...[
            _MessageCard(
              icon: LucideIcons.circleAlert,
              message: context.trMessage(widget.error!),
              destructive: true,
              onClose: widget.onClearMessages,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.successMessage != null) ...[
            _MessageCard(
              icon: LucideIcons.circleCheck,
              message: context.trMessage(widget.successMessage!),
              onClose: widget.onClearMessages,
            ),
            const SizedBox(height: 16),
          ],
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
                        context.tr('Daily Email Notifications'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Receive a daily summary of new survey responses via email.',
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
                  const SizedBox(height: 16),
                  _LabeledControl(
                    label: context.tr('Send Time (UTC)'),
                    child: HuxDropdown<int>(
                      value: _selectedHour,
                      enabled: widget.isEmailConfigured,
                      useItemWidgetAsValue: true,
                      items: List.generate(24, (hour) {
                        final label =
                            '${hour.toString().padLeft(2, '0')}:00 UTC';
                        return HuxDropdownItem(
                          value: hour,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock3, size: 18),
                              const SizedBox(width: 8),
                              Text(label),
                            ],
                          ),
                        );
                      }),
                      onChanged: _onHourChanged,
                    ),
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
                                    ? 'Daily notifications are active'
                                    : 'Daily notifications are paused',
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
                  if (widget.settings!.lastSentAt != null) ...[
                    Divider(
                      height: 32,
                      color: HuxTokens.borderSecondary(context),
                    ),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.history,
                          color: HuxTokens.iconSecondary(context),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('Last Sent')),
                            Text(
                              _formatDateTime(widget.settings!.lastSentAt!),
                              style: TextStyle(
                                color: HuxTokens.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
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

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.destructive = false,
    this.onClose,
  });

  final IconData icon;
  final String message;
  final bool destructive;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? HuxTokens.textDestructive(context)
        : HuxTokens.textSuccess(context);
    return HuxCard(
      backgroundColor: destructive
          ? HuxTokens.surfaceDestructive(context)
          : HuxTokens.surfaceSuccess(context),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
          if (onClose != null)
            HuxButton(
              onPressed: onClose,
              variant: HuxButtonVariant.ghost,
              size: HuxButtonSize.small,
              icon: LucideIcons.x,
              textColor: color,
              child: const SizedBox(width: 0),
            ),
        ],
      ),
    );
  }
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: child),
      ],
    );
  }
}
