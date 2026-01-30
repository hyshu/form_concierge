import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../services/gemini_service.dart';
import '../utils/exceptions.dart';

/// Endpoint for AI-powered survey generation.
/// Requires authentication.
class AiAdminEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Generates survey questions from a natural language prompt.
  ///
  /// Returns a list of [QuestionWithChoices] that can be used to create
  /// a new survey.
  ///
  /// Throws [ValidationException] if Gemini is not configured.
  Future<List<QuestionWithChoices>> generateSurveyQuestions(
    Session session,
    String prompt,
  ) async {
    if (!GeminiService.isConfigured) {
      throw const ValidationException('AI generation is not available');
    }

    return GeminiService.instance.generateSurveyQuestions(
      session: session,
      prompt: prompt,
    );
  }
}
