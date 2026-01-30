import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

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

  void _onHourChanged(int? value) {
    if (value != null) {
      setState(() {
        _selectedHour = value;
        _hasChanges = true;
      });
    }
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.isLoading && widget.settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email not configured warning
          if (!widget.isEmailConfigured) ...[
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email service is not configured. Contact your administrator to enable SMTP settings.',
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Error message
          if (widget.error != null) ...[
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClearMessages,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Success message
          if (widget.successMessage != null) ...[
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.successMessage!,
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClearMessages,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Main settings card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Email Notifications',
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Receive a daily summary of new survey responses via email.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 32),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Email',
                        hintText: 'email@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: widget.isEmailConfigured,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Time selector
                    DropdownButtonFormField<int>(
                      initialValue: _selectedHour,
                      decoration: const InputDecoration(
                        labelText: 'Send Time (UTC)',
                        prefixIcon: Icon(Icons.schedule),
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(24, (hour) {
                        final label =
                            '${hour.toString().padLeft(2, '0')}:00 UTC';
                        return DropdownMenuItem(
                          value: hour,
                          child: Text(label),
                        );
                      }),
                      onChanged: widget.isEmailConfigured
                          ? _onHourChanged
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            widget.isEmailConfigured &&
                                !widget.isSaving &&
                                (_hasChanges || widget.settings == null)
                            ? _onSave
                            : null,
                        icon: widget.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
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
          ),

          // Enable/Disable and Test section (only if settings exist)
          if (widget.settings != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  // Enable/Disable toggle
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: Text(
                      widget.settings!.enabled
                          ? 'Daily notifications are active'
                          : 'Daily notifications are paused',
                    ),
                    value: widget.settings!.enabled,
                    onChanged: widget.isEmailConfigured && !widget.isSaving
                        ? (_) => widget.onToggleEnabled()
                        : null,
                    secondary: Icon(
                      widget.settings!.enabled
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: widget.settings!.enabled
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                  ),
                  const Divider(height: 1),

                  // Last sent info
                  if (widget.settings!.lastSentAt != null)
                    ListTile(
                      leading: Icon(
                        Icons.history,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Last Sent'),
                      subtitle: Text(
                        _formatDateTime(widget.settings!.lastSentAt!),
                      ),
                    ),

                  // Test notification button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.isEmailConfigured &&
                                !widget.isSendingTest &&
                                !widget.isSaving
                            ? widget.onSendTest
                            : null,
                        icon: widget.isSendingTest
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Send Test Notification'),
                      ),
                    ),
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
