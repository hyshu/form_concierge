import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';

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
                  _AiSection(
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

class _AiSection extends StatelessWidget {
  const _AiSection({
    required this.settings,
    required this.provider,
    required this.geminiKeyController,
    required this.openaiKeyController,
    required this.claudeKeyController,
    required this.cerebrasKeyController,
    required this.clearGeminiKey,
    required this.clearOpenaiKey,
    required this.clearClaudeKey,
    required this.clearCerebrasKey,
    required this.onProviderChanged,
    required this.onClearGeminiChanged,
    required this.onClearOpenaiChanged,
    required this.onClearClaudeChanged,
    required this.onClearCerebrasChanged,
  });

  final AiIntegrationSettings settings;
  final AiProvider provider;
  final TextEditingController geminiKeyController;
  final TextEditingController openaiKeyController;
  final TextEditingController claudeKeyController;
  final TextEditingController cerebrasKeyController;
  final bool clearGeminiKey;
  final bool clearOpenaiKey;
  final bool clearClaudeKey;
  final bool clearCerebrasKey;
  final ValueChanged<AiProvider> onProviderChanged;
  final ValueChanged<bool> onClearGeminiChanged;
  final ValueChanged<bool> onClearOpenaiChanged;
  final ValueChanged<bool> onClearClaudeChanged;
  final ValueChanged<bool> onClearCerebrasChanged;

  @override
  Widget build(BuildContext context) {
    return HuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: LucideIcons.sparkles,
            title: context.tr('AI Generation'),
            configured:
                _selectedProviderSettings.hasApiKey &&
                !_selectedProviderClearFlag,
          ),
          const SizedBox(height: 16),
          _LabeledControl(
            label: context.tr('AI Provider'),
            child: HuxDropdown<AiProvider>(
              value: provider,
              useItemWidgetAsValue: true,
              items: [
                for (final value in AiProvider.values)
                  HuxDropdownItem(
                    value: value,
                    child: Text(context.tr(_aiProviderLabel(value))),
                  ),
              ],
              onChanged: onProviderChanged,
            ),
          ),
          const SizedBox(height: 16),
          _selectedProviderKeyField(context),
        ],
      ),
    );
  }

  Widget _selectedProviderKeyField(BuildContext context) {
    return switch (provider) {
      AiProvider.gemini => _AiProviderKeyField(
        label: context.tr('Gemini API Key'),
        hint: 'AIza...',
        controller: geminiKeyController,
        hasApiKey: settings.gemini.hasApiKey,
        clearApiKey: clearGeminiKey,
        clearLabel: context.tr('Clear saved Gemini API key'),
        onClearChanged: onClearGeminiChanged,
      ),
      AiProvider.openai => _AiProviderKeyField(
        label: context.tr('OpenAI API Key'),
        hint: 'sk-...',
        controller: openaiKeyController,
        hasApiKey: settings.openai.hasApiKey,
        clearApiKey: clearOpenaiKey,
        clearLabel: context.tr('Clear saved OpenAI API key'),
        onClearChanged: onClearOpenaiChanged,
      ),
      AiProvider.claude => _AiProviderKeyField(
        label: context.tr('Claude API Key'),
        hint: 'sk-ant-...',
        controller: claudeKeyController,
        hasApiKey: settings.claude.hasApiKey,
        clearApiKey: clearClaudeKey,
        clearLabel: context.tr('Clear saved Claude API key'),
        onClearChanged: onClearClaudeChanged,
      ),
      AiProvider.cerebras => _AiProviderKeyField(
        label: context.tr('Cerebras API Key'),
        hint: 'csk-...',
        controller: cerebrasKeyController,
        hasApiKey: settings.cerebras.hasApiKey,
        clearApiKey: clearCerebrasKey,
        clearLabel: context.tr('Clear saved Cerebras API key'),
        onClearChanged: onClearCerebrasChanged,
      ),
    };
  }

  AiProviderKeySettings get _selectedProviderSettings {
    return switch (provider) {
      AiProvider.gemini => settings.gemini,
      AiProvider.openai => settings.openai,
      AiProvider.claude => settings.claude,
      AiProvider.cerebras => settings.cerebras,
    };
  }

  bool get _selectedProviderClearFlag {
    return switch (provider) {
      AiProvider.gemini => clearGeminiKey,
      AiProvider.openai => clearOpenaiKey,
      AiProvider.claude => clearClaudeKey,
      AiProvider.cerebras => clearCerebrasKey,
    };
  }
}

class _AiProviderKeyField extends StatelessWidget {
  const _AiProviderKeyField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.hasApiKey,
    required this.clearApiKey,
    required this.clearLabel,
    required this.onClearChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool hasApiKey;
  final bool clearApiKey;
  final String clearLabel;
  final ValueChanged<bool> onClearChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HuxInput(
          controller: controller,
          label: label,
          hint: hasApiKey
              ? context.tr('Leave blank to keep the saved key')
              : hint,
          prefixIcon: const Icon(LucideIcons.keyRound),
          obscureText: true,
          enabled: !clearApiKey,
        ),
        if (hasApiKey) ...[
          const SizedBox(height: 12),
          _SwitchRow(
            label: clearLabel,
            value: clearApiKey,
            onChanged: onClearChanged,
          ),
        ],
      ],
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
          _SectionHeader(
            icon: LucideIcons.mail,
            title: context.tr('SMTP Server'),
            configured: settings.configured,
          ),
          const SizedBox(height: 16),
          _ResponsiveFields(
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
          _ResponsiveFields(
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
            _SwitchRow(
              label: context.tr('Clear saved SMTP password'),
              value: clearPassword,
              onChanged: onClearPasswordChanged,
            ),
          ],
          const SizedBox(height: 16),
          _ResponsiveFields(
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
          _LabeledControl(
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.configured,
  });

  final IconData icon;
  final String title;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HuxTokens.primary(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        HuxBadge(
          label: context.tr(configured ? 'Configured' : 'Not configured'),
          variant: configured
              ? HuxBadgeVariant.success
              : HuxBadgeVariant.secondary,
          size: HuxBadgeSize.small,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        HuxSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
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

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _aiProviderLabel(AiProvider provider) {
  return switch (provider) {
    AiProvider.gemini => 'Gemini',
    AiProvider.openai => 'OpenAI',
    AiProvider.claude => 'Claude',
    AiProvider.cerebras => 'Cerebras',
  };
}
