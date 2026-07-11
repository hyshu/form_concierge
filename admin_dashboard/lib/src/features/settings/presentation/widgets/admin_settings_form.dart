import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import 'admin_settings_ai_section.dart';
import 'admin_settings_smtp_section.dart';

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

  void _setClearGeminiKey(bool value) => _setClearSecret(
    value: value,
    updateFlag: (next) => _clearGeminiKey = next,
    controller: _geminiKeyController,
  );

  void _setClearOpenaiKey(bool value) => _setClearSecret(
    value: value,
    updateFlag: (next) => _clearOpenaiKey = next,
    controller: _openaiKeyController,
  );

  void _setClearClaudeKey(bool value) => _setClearSecret(
    value: value,
    updateFlag: (next) => _clearClaudeKey = next,
    controller: _claudeKeyController,
  );

  void _setClearCerebrasKey(bool value) => _setClearSecret(
    value: value,
    updateFlag: (next) => _clearCerebrasKey = next,
    controller: _cerebrasKeyController,
  );

  void _setClearSmtpPassword(bool value) => _setClearSecret(
    value: value,
    updateFlag: (next) => _clearSmtpPassword = next,
    controller: _smtpPasswordController,
  );

  void _setClearSecret({
    required bool value,
    required ValueChanged<bool> updateFlag,
    required TextEditingController controller,
  }) => setState(() {
    updateFlag(value);
    _hasChanges = true;
    if (value) controller.clear();
  });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.onSave(
      AdminIntegrationSettingsInput(
        aiProvider: _aiProvider,
        geminiApiKey: _nullIfBlank(_geminiKeyController.text),
        clearGeminiApiKey: _clearGeminiKey,
        openaiApiKey: _nullIfBlank(_openaiKeyController.text),
        clearOpenaiApiKey: _clearOpenaiKey,
        claudeApiKey: _nullIfBlank(_claudeKeyController.text),
        clearClaudeApiKey: _clearClaudeKey,
        cerebrasApiKey: _nullIfBlank(_cerebrasKeyController.text),
        clearCerebrasApiKey: _clearCerebrasKey,
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
  Widget build(context) {
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
                  HuxFeedbackMessages(
                    error: widget.error,
                    successMessage: widget.successMessage,
                    onClose: widget.onClearMessages,
                  ),
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
                  AdminSettingsSmtpSection(
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

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
