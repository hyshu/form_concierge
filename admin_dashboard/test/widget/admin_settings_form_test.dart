import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/settings/presentation/widgets/admin_settings_form.dart';
import 'package:hux/hux.dart';

import '../support/localized_test_app.dart';

void main() {
  group('AdminSettingsForm', () {
    late AdminIntegrationSettingsInput? savedInput;

    setUp(() {
      savedInput = null;
    });

    Widget buildSubject(AdminIntegrationSettings settings) {
      return localizedTestApp(
        home: Scaffold(
          body: AdminSettingsForm(
            settings: settings,
            isSaving: false,
            onSave: (input) async {
              savedInput = input;
              return true;
            },
            onClearMessages: () {},
          ),
        ),
      );
    }

    testWidgets('shows only the selected AI provider key field', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(_settings(aiProvider: AiProvider.openai)),
      );

      expect(find.text('OpenAI API Key'), findsOneWidget);
      expect(find.text('Gemini API Key'), findsNothing);
      expect(find.text('Claude API Key'), findsNothing);
      expect(find.text('Cerebras API Key'), findsNothing);
    });

    testWidgets('saves selected AI key without requiring SMTP fields', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(_settings()));
      await _enterText(tester, 'Gemini API Key', 'gemini-key');
      await tester.pump();

      await _tapSave(tester);

      expect(savedInput, isNotNull);
      expect(savedInput!.aiProvider, AiProvider.gemini);
      expect(savedInput!.geminiApiKey, 'gemini-key');
      expect(savedInput!.openaiApiKey, isNull);
      expect(savedInput!.claudeApiKey, isNull);
      expect(savedInput!.cerebrasApiKey, isNull);
      expect(savedInput!.smtpHost, isNull);
      expect(savedInput!.smtpPort, isNull);
    });

    testWidgets('requires SMTP host when another SMTP field is present', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(_settings()));
      await _enterText(tester, 'From Email', 'forms@example.com');
      await tester.pump();

      await _tapSave(tester);

      expect(savedInput, isNull);
      expect(
        find.text('Host is required when SMTP settings are present'),
        findsOneWidget,
      );
    });

    testWidgets('blank secret fields preserve saved secrets', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          _settings(
            aiProvider: AiProvider.openai,
            hasOpenaiKey: true,
            hasSmtpPassword: true,
            smtpHost: 'smtp.example.com',
            smtpPort: 587,
            smtpFromEmail: 'forms@example.com',
          ),
        ),
      );
      await _enterText(tester, 'From Name (optional)', 'Forms');
      await tester.pump();

      await _tapSave(tester);

      expect(savedInput, isNotNull);
      expect(savedInput!.aiProvider, AiProvider.openai);
      expect(savedInput!.geminiApiKey, isNull);
      expect(savedInput!.clearGeminiApiKey, isFalse);
      expect(savedInput!.openaiApiKey, isNull);
      expect(savedInput!.clearOpenaiApiKey, isFalse);
      expect(savedInput!.smtpPassword, isNull);
      expect(savedInput!.clearSmtpPassword, isFalse);
      expect(savedInput!.smtpFromName, 'Forms');
    });
  });
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  final button = find.widgetWithText(HuxButton, 'Save Changes');
  await tester.ensureVisible(button);
  tester.widget<HuxButton>(button).onPressed?.call();
  await tester.pumpAndSettle();
}

Future<void> _enterText(
  WidgetTester tester,
  String label,
  String value,
) async {
  final input = find.ancestor(
    of: find.text(label),
    matching: find.byType(HuxInput),
  );
  final field = find.descendant(of: input, matching: find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

AdminIntegrationSettings _settings({
  AiProvider aiProvider = AiProvider.gemini,
  bool hasGeminiKey = false,
  bool hasOpenaiKey = false,
  bool hasClaudeKey = false,
  bool hasCerebrasKey = false,
  bool hasSmtpPassword = false,
  String? smtpHost,
  int? smtpPort,
  String? smtpFromEmail,
}) {
  return AdminIntegrationSettings(
    ai: AiIntegrationSettings(
      provider: aiProvider,
      gemini: AiProviderKeySettings(
        enabled: aiProvider == AiProvider.gemini && hasGeminiKey,
        hasApiKey: hasGeminiKey,
      ),
      openai: AiProviderKeySettings(
        enabled: aiProvider == AiProvider.openai && hasOpenaiKey,
        hasApiKey: hasOpenaiKey,
      ),
      claude: AiProviderKeySettings(
        enabled: aiProvider == AiProvider.claude && hasClaudeKey,
        hasApiKey: hasClaudeKey,
      ),
      cerebras: AiProviderKeySettings(
        enabled: aiProvider == AiProvider.cerebras && hasCerebrasKey,
        hasApiKey: hasCerebrasKey,
      ),
    ),
    smtp: SmtpIntegrationSettings(
      configured: smtpHost != null && smtpPort != null && smtpFromEmail != null,
      host: smtpHost,
      port: smtpPort,
      hasPassword: hasSmtpPassword,
      fromEmail: smtpFromEmail,
    ),
  );
}
