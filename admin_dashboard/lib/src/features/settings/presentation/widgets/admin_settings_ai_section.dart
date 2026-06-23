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
          AdminSettingsSectionHeader(
            icon: LucideIcons.sparkles,
            title: context.tr('AI Generation'),
            configured:
                _selectedProviderSettings.hasApiKey &&
                !_selectedProviderClearFlag,
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
          AdminSettingsSwitchRow(
            label: clearLabel,
            value: clearApiKey,
            onChanged: onClearChanged,
          ),
        ],
      ],
    );
  }
}

String _aiProviderLabel(AiProvider provider) {
  return switch (provider) {
    AiProvider.gemini => 'Gemini',
    AiProvider.openai => 'OpenAI',
    AiProvider.claude => 'Claude',
    AiProvider.cerebras => 'Cerebras',
  };
}
