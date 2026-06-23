import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import 'admin_settings_ai_section.dart';
import 'admin_settings_form_widgets.dart';

class AdminSettingsForm extends StatefulWidget {
  const AdminSettingsForm({
    super.key,
    required this.settings,
    required this.isSaving,
    this.error,
    this.successMessage,
    required this.onSave,
    required this.onClearMessages,
  });

  final AdminIntegrationSettings settings;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final Future<bool> Function(AdminIntegrationSettingsInput input) onSave;
  final VoidCallback onClearMessages;

  @override
  State<AdminSettingsForm> createState() => _AdminSettingsFormState();
}

class _AdminSettingsFormState extends State<AdminSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _geminiKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _claudeKeyController = TextEditingController();
  final _cerebrasKeyController = TextEditingController();
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _smtpFromEmailController = TextEditingController();
  final _smtpFromNameController = TextEditingController();

  late AiProvider _aiProvider;
  late SmtpSecureMode _secureMode;
  bool _clearGeminiKey = false;
  bool _clearOpenaiKey = false;
  bool _clearClaudeKey = false;
  bool _clearCerebrasKey = false;
  bool _clearSmtpPassword = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _populate(widget.settings);
    for (final controller in _controllers) {
      controller.addListener(_markChanged);
    }
  }

  @override
  void didUpdateWidget(AdminSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _populate(widget.settings);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_markChanged);
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
    _geminiKeyController,
    _openaiKeyController,
    _claudeKeyController,
    _cerebrasKeyController,
    _smtpHostController,
    _smtpPortController,
    _smtpUsernameController,
    _smtpPasswordController,
    _smtpFromEmailController,
    _smtpFromNameController,
  ];

  void _populate(AdminIntegrationSettings settings) {
    _geminiKeyController.clear();
    _openaiKeyController.clear();
    _claudeKeyController.clear();
    _cerebrasKeyController.clear();
    _smtpHostController.text = settings.smtp.host ?? '';
    _smtpPortController.text = settings.smtp.port?.toString() ?? '';
    _smtpUsernameController.text = settings.smtp.username ?? '';
    _smtpPasswordController.clear();
    _smtpFromEmailController.text = settings.smtp.fromEmail ?? '';
    _smtpFromNameController.text = settings.smtp.fromName ?? '';
    _aiProvider = settings.ai.provider;
    _secureMode = settings.smtp.secureMode;
    _clearGeminiKey = false;
    _clearOpenaiKey = false;
    _clearClaudeKey = false;
    _clearCerebrasKey = false;
    _clearSmtpPassword = false;
    _hasChanges = false;
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _setClearGeminiKey(bool value) {
    setState(() {
      _clearGeminiKey = value;
      _hasChanges = true;
      if (value) _geminiKeyController.clear();
    });
  }

  void _setClearOpenaiKey(bool value) {
    setState(() {
      _clearOpenaiKey = value;
      _hasChanges = true;
      if (value) _openaiKeyController.clear();
    });
  }

  void _setClearClaudeKey(bool value) {
    setState(() {
      _clearClaudeKey = value;
      _hasChanges = true;
      if (value) _claudeKeyController.clear();
    });
  }

  void _setClearCerebrasKey(bool value) {
    setState(() {
      _clearCerebrasKey = value;
      _hasChanges = true;
      if (value) _cerebrasKeyController.clear();
    });
  }

  void _setClearSmtpPassword(bool value) {
    setState(() {
      _clearSmtpPassword = value;
      _hasChanges = true;
      if (value) _smtpPasswordController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.onSave(
      AdminIntegrationSettingsInput(
        aiProvider: _aiProvider,
        geminiApiKey: _aiProvider == AiProvider.gemini
            ? _nullIfBlank(_geminiKeyController.text)
            : null,
        clearGeminiApiKey: _aiProvider == AiProvider.gemini && _clearGeminiKey,
        openaiApiKey: _aiProvider == AiProvider.openai
            ? _nullIfBlank(_openaiKeyController.text)
            : null,
        clearOpenaiApiKey: _aiProvider == AiProvider.openai && _clearOpenaiKey,
        claudeApiKey: _aiProvider == AiProvider.claude
            ? _nullIfBlank(_claudeKeyController.text)
            : null,
        clearClaudeApiKey: _aiProvider == AiProvider.claude && _clearClaudeKey,
        cerebrasApiKey: _aiProvider == AiProvider.cerebras
            ? _nullIfBlank(_cerebrasKeyController.text)
            : null,
        clearCerebrasApiKey:
            _aiProvider == AiProvider.cerebras && _clearCerebrasKey,
        smtpHost: _nullIfBlank(_smtpHostController.text),
        smtpPort: _smtpPortController.text.trim().isEmpty
            ? null
            : int.parse(_smtpPortController.text.trim()),
        smtpUsername: _nullIfBlank(_smtpUsernameController.text),
        smtpPassword: _nullIfBlank(_smtpPasswordController.text),
        clearSmtpPassword: _clearSmtpPassword,
        smtpFromEmail: _nullIfBlank(_smtpFromEmailController.text),
        smtpFromName: _nullIfBlank(_smtpFromNameController.text),
        smtpSecureMode: _secureMode,
      ),
    );
    if (success && mounted) setState(() => _hasChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.error != null) ...[
                    HuxMessageCard(
                      icon: LucideIcons.circleAlert,
                      message: context.trMessage(widget.error!),
                      destructive: true,
                      onClose: widget.onClearMessages,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.successMessage != null) ...[
                    HuxMessageCard(
                      icon: LucideIcons.circleCheck,
                      message: context.trMessage(widget.successMessage!),
                      onClose: widget.onClearMessages,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AdminSettingsAiSection(
                    settings: settings.ai,
                    provider: _aiProvider,
                    geminiKeyController: _geminiKeyController,
                    openaiKeyController: _openaiKeyController,
                    claudeKeyController: _claudeKeyController,
                    cerebrasKeyController: _cerebrasKeyController,
                    clearGeminiKey: _clearGeminiKey,
                    clearOpenaiKey: _clearOpenaiKey,
                    clearClaudeKey: _clearClaudeKey,
                    clearCerebrasKey: _clearCerebrasKey,
                    onProviderChanged: (provider) {
                      setState(() {
                        _aiProvider = provider;
                        _hasChanges = true;
                      });
                    },
                    onClearGeminiChanged: _setClearGeminiKey,
                    onClearOpenaiChanged: _setClearOpenaiKey,
                    onClearClaudeChanged: _setClearClaudeKey,
                    onClearCerebrasChanged: _setClearCerebrasKey,
                  ),
                  const SizedBox(height: 16),
                  _SmtpSection(
                    settings: settings.smtp,
                    hostController: _smtpHostController,
                    portController: _smtpPortController,
                    usernameController: _smtpUsernameController,
                    passwordController: _smtpPasswordController,
                    fromEmailController: _smtpFromEmailController,
                    fromNameController: _smtpFromNameController,
                    secureMode: _secureMode,
                    clearPassword: _clearSmtpPassword,
                    onSecureModeChanged: (mode) {
                      setState(() {
                        _secureMode = mode;
                        _hasChanges = true;
                      });
                    },
                    onClearPasswordChanged: _setClearSmtpPassword,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: HuxButton(
                      onPressed: widget.isSaving ? null : _save,
                      isLoading: widget.isSaving,
                      icon: LucideIcons.save,
                      child: Text(context.tr('Save Changes')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmtpSection extends StatelessWidget {
  const _SmtpSection({
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
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed)) {
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

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
