import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Configuration for Gemini AI service.
class GeminiConfig {
  /// Whether Gemini is enabled (API key is set).
  final bool enabled;

  /// Gemini API key.
  final String apiKey;

  const GeminiConfig({required this.enabled, required this.apiKey});

  /// Creates a disabled Gemini config.
  const GeminiConfig.disabled() : enabled = false, apiKey = '';

  /// Creates a GeminiConfig from Serverpod passwords.
  ///
  /// Returns a disabled config if API key is missing.
  factory GeminiConfig.fromServerpod(Serverpod pod) {
    final apiKey = pod.getPassword('geminiApiKey');

    if (apiKey == null || apiKey.isEmpty) {
      return const GeminiConfig.disabled();
    }

    return GeminiConfig(enabled: true, apiKey: apiKey);
  }
}

/// Singleton service for Gemini AI operations.
class GeminiService {
  static GeminiService? _instance;

  /// Gets the singleton instance.
  ///
  /// Throws if [initialize] has not been called.
  static GeminiService get instance {
    if (_instance == null) {
      throw StateError('GeminiService has not been initialized');
    }
    return _instance!;
  }

  /// Whether the Gemini service is configured and enabled.
  static bool get isConfigured => _instance?.config.enabled ?? false;

  /// The Gemini configuration.
  final GeminiConfig config;

  /// The Gemini model instance.
  late final GenerativeModel? _model;

  GeminiService._(this.config) {
    if (config.enabled) {
      _model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: config.apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
    } else {
      _model = null;
    }
  }

  /// Initializes the Gemini service with the given configuration.
  static void initialize(GeminiConfig config) {
    _instance = GeminiService._(config);
  }

  /// Generates survey questions from a natural language prompt.
  ///
  /// Throws [Exception] if Gemini is not configured.
  Future<List<QuestionWithChoices>> generateSurveyQuestions({
    required Session session,
    required String prompt,
  }) async {
    if (!config.enabled || _model == null) {
      throw Exception('Gemini service is not configured');
    }

    final systemPrompt = '''
You are a survey question generator. Generate survey questions based on the user's description.

Output format: JSON array of question objects with this structure:
[
  {
    "text": "Question text here",
    "type": "singleChoice" | "multipleChoice" | "textSingle" | "textMultiLine",
    "isRequired": true | false,
    "placeholder": "optional placeholder for text questions",
    "choices": ["Choice 1", "Choice 2", "Choice 3"]  // only for choice questions
  }
]

Rules:
- Generate 3-10 relevant questions based on the description
- Use appropriate question types for each question
- For choice questions, provide 2-5 meaningful choices
- Keep questions clear and concise
- Make most questions required unless they're optional by nature
- Respond with ONLY the JSON array, no explanation

User description: $prompt
''';

    try {
      final response = await _model.generateContent([Content.text(systemPrompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      session.log('Gemini response: $responseText');

      final List<dynamic> questionsJson = jsonDecode(responseText);
      final questions = <QuestionWithChoices>[];

      for (final q in questionsJson) {
        final typeStr = q['type'] as String;
        final type = _parseQuestionType(typeStr);

        final choicesRaw = q['choices'] as List<dynamic>? ?? [];
        final choices = <String>[];
        if (type == QuestionType.singleChoice ||
            type == QuestionType.multipleChoice) {
          for (final c in choicesRaw) {
            choices.add(c.toString());
          }
        }

        questions.add(
          QuestionWithChoices(
            text: q['text'] as String,
            type: type,
            isRequired: q['isRequired'] as bool? ?? true,
            placeholder: q['placeholder'] as String?,
            choices: choices,
          ),
        );
      }

      return questions;
    } on GenerativeAIException catch (e) {
      session.log(
        'Gemini API error: ${e.message}',
        level: LogLevel.error,
      );
      throw Exception('Failed to generate questions: ${e.message}');
    } on FormatException catch (e) {
      session.log(
        'Failed to parse Gemini response: $e',
        level: LogLevel.error,
      );
      throw Exception('Failed to parse AI response');
    }
  }

  QuestionType _parseQuestionType(String type) {
    switch (type) {
      case 'singleChoice':
        return QuestionType.singleChoice;
      case 'multipleChoice':
        return QuestionType.multipleChoice;
      case 'textSingle':
      case 'textSingleLine':
        return QuestionType.textSingle;
      case 'textMultiLine':
        return QuestionType.textMultiLine;
      default:
        return QuestionType.textSingle;
    }
  }
}
