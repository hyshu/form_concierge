import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import 'admin_settings_form_widgets.dart';

class AdminSettingsAiSection extends StatelessWidget {
  const AdminSettingsAiSection({
    super.key,
    required this.settings,
    required this.provider,
    required this.geminiKeyController,
    required this.openaiKeyController,
    required this.claudeKeyController,
    required this.groqKeyController,
    required this.cerebrasKeyController,
    required this.clearGeminiKey,
    required this.clearOpenaiKey,
    required this.clearClaudeKey,
    required this.clearGroqKey,
    required this.clearCerebrasKey,
    required this.onProviderChanged,
    required this.onClearGeminiChanged,
    required this.onClearOpenaiChanged,
    required this.onClearClaudeChanged,
    required this.onClearGroqChanged,
    required this.onClearCerebrasChanged,
  });

  final AiIntegrationSettings settings;
  final AiProvider provider;
  final TextEditingController geminiKeyController;
  final TextEditingController openaiKeyController;
  final TextEditingController claudeKeyController;
  final TextEditingController groqKeyController;
  final TextEditingController cerebrasKeyController;
  final bool clearGeminiKey;
  final bool clearOpenaiKey;
  final bool clearClaudeKey;
  final bool clearGroqKey;
  final bool clearCerebrasKey;
  final ValueChanged<AiProvider> onProviderChanged;
  final ValueChanged<bool> onClearGeminiChanged;
  final ValueChanged<bool> onClearOpenaiChanged;
  final ValueChanged<bool> onClearClaudeChanged;
  final ValueChanged<bool> onClearGroqChanged;
  final ValueChanged<bool> onClearCerebrasChanged;

  @override
  Widget build(context) {
    final key = _selectedProviderKey;
    return HuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSettingsSectionHeader(
            icon: LucideIcons.sparkles,
            title: context.tr('AI Generation'),
            configured: key.settings.hasApiKey && !key.clearApiKey,
          ),
          const SizedBox(height: 16),
          HuxLabeledControl(
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
          _AiProviderKeyField(
            label: context.tr(key.label),
            hint: key.hint,
            controller: key.controller,
            hasApiKey: key.settings.hasApiKey,
            clearApiKey: key.clearApiKey,
            clearLabel: context.tr(key.clearLabel),
            onClearChanged: key.onClearChanged,
          ),
        ],
      ),
    );
  }

  _SelectedAiProviderKey get _selectedProviderKey {
    return switch (provider) {
      AiProvider.gemini => _SelectedAiProviderKey(
        label: 'Gemini API Key',
        hint: 'AIza...',
        settings: settings.gemini,
        controller: geminiKeyController,
        clearApiKey: clearGeminiKey,
        clearLabel: 'Clear saved Gemini API key',
        onClearChanged: onClearGeminiChanged,
      ),
      AiProvider.openai => _SelectedAiProviderKey(
        label: 'OpenAI API Key',
        hint: 'sk-...',
        settings: settings.openai,
        controller: openaiKeyController,
        clearApiKey: clearOpenaiKey,
        clearLabel: 'Clear saved OpenAI API key',
        onClearChanged: onClearOpenaiChanged,
      ),
      AiProvider.claude => _SelectedAiProviderKey(
        label: 'Claude API Key',
        hint: 'sk-ant-...',
        settings: settings.claude,
        controller: claudeKeyController,
        clearApiKey: clearClaudeKey,
        clearLabel: 'Clear saved Claude API key',
        onClearChanged: onClearClaudeChanged,
      ),
      AiProvider.groq => _SelectedAiProviderKey(
        label: 'Groq API Key',
        hint: 'gsk_...',
        settings: settings.groq,
        controller: groqKeyController,
        clearApiKey: clearGroqKey,
        clearLabel: 'Clear saved Groq API key',
        onClearChanged: onClearGroqChanged,
      ),
      AiProvider.cerebras => _SelectedAiProviderKey(
        label: 'Cerebras API Key',
        hint: 'csk-...',
        settings: settings.cerebras,
        controller: cerebrasKeyController,
        clearApiKey: clearCerebrasKey,
        clearLabel: 'Clear saved Cerebras API key',
        onClearChanged: onClearCerebrasChanged,
      ),
    };
  }
}

class _SelectedAiProviderKey {
  const _SelectedAiProviderKey({
    required this.label,
    required this.hint,
    required this.settings,
    required this.controller,
    required this.clearApiKey,
    required this.clearLabel,
    required this.onClearChanged,
  });

  final String label;
  final String hint;
  final AiProviderKeySettings settings;
  final TextEditingController controller;
  final bool clearApiKey;
  final String clearLabel;
  final ValueChanged<bool> onClearChanged;
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
  Widget build(context) => Column(
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
        AdminSettingsSwitchRow(
          label: clearLabel,
          value: clearApiKey,
          onChanged: onClearChanged,
        ),
      ],
    ],
  );
}

String _aiProviderLabel(AiProvider provider) => switch (provider) {
  AiProvider.gemini => 'Gemini',
  AiProvider.openai => 'OpenAI',
  AiProvider.claude => 'Claude',
  AiProvider.groq => 'Groq',
  AiProvider.cerebras => 'Cerebras',
};
