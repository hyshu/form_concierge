import '../generated/protocol.dart';

/// Pure business rules for survey operations.
///
/// These rules are extracted from endpoints to enable unit testing
/// without database dependencies.
class SurveyRules {
  /// Checks if a survey is currently accepting responses.
  ///
  /// A survey accepts responses when:
  /// - Status is [SurveyStatus.published]
  /// - Current time is after [startsAt] (if set)
  /// - Current time is before [endsAt] (if set)
  static bool isAcceptingResponses({
    required SurveyStatus status,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? now,
  }) {
    if (status != SurveyStatus.published) return false;

    final currentTime = now ?? DateTime.now();
    if (startsAt != null && currentTime.isBefore(startsAt)) return false;
    if (endsAt != null && currentTime.isAfter(endsAt)) return false;
    return true;
  }

  /// Checks if a status transition is allowed.
  ///
  /// Valid transitions:
  /// - draft → published (publish)
  /// - published → closed (close)
  /// - closed → published (reopen)
  /// - any → archived (archive)
  static bool canTransition(SurveyStatus from, SurveyStatus to) {
    return switch ((from, to)) {
      (SurveyStatus.draft, SurveyStatus.published) => true,
      (SurveyStatus.published, SurveyStatus.closed) => true,
      (SurveyStatus.closed, SurveyStatus.published) => true,
      (_, SurveyStatus.archived) => true,
      _ => false,
    };
  }

  /// Checks if a survey can be published.
  ///
  /// Requirements:
  /// - Status must be [SurveyStatus.draft]
  /// - Must have at least one question
  static bool canPublish({
    required SurveyStatus status,
    required int questionCount,
  }) {
    return status == SurveyStatus.draft && questionCount > 0;
  }

  /// Checks if a response submission is valid for a survey.
  ///
  /// Validates:
  /// - Survey is published
  /// - Current time is within survey's start/end dates (if set)
  /// - If auth requirement is [AuthRequirement.authenticated], user must be authenticated
  static ResponseValidation validateResponseSubmission({
    required SurveyStatus status,
    required AuthRequirement authRequirement,
    required bool isAuthenticated,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (status != SurveyStatus.published) {
      return ResponseValidation.rejected('Survey is not accepting responses');
    }
    if (startsAt != null && currentTime.isBefore(startsAt)) {
      return ResponseValidation.rejected('Survey has not started yet');
    }
    if (endsAt != null && currentTime.isAfter(endsAt)) {
      return ResponseValidation.rejected('Survey has ended');
    }

    if (authRequirement == AuthRequirement.authenticated && !isAuthenticated) {
      return ResponseValidation.rejected(
        'Authentication required for this survey',
      );
    }

    return ResponseValidation.accepted();
  }
}

/// Result of response submission validation.
class ResponseValidation {
  final bool isValid;
  final String? errorMessage;

  const ResponseValidation._({required this.isValid, this.errorMessage});

  factory ResponseValidation.accepted() =>
      const ResponseValidation._(isValid: true);

  factory ResponseValidation.rejected(String message) =>
      ResponseValidation._(isValid: false, errorMessage: message);
}
