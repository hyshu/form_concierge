import 'package:form_concierge_server/src/domain/survey_rules.dart';
import 'package:form_concierge_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/given_when_then.dart';

void main() {
  group('SurveyRules.isAcceptingResponses', () {
    late SurveyStatus status;
    late DateTime? startsAt;
    late DateTime? endsAt;
    late DateTime now;
    late bool result;

    scenario(
      'published survey without date restrictions accepts responses',
      given: () {
        status = SurveyStatus.published;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isTrue);
      },
    );

    scenario(
      'published survey before start date rejects responses',
      given: () {
        status = SurveyStatus.published;
        startsAt = DateTime(2024, 6, 20);
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );

    scenario(
      'published survey after end date rejects responses',
      given: () {
        status = SurveyStatus.published;
        startsAt = null;
        endsAt = DateTime(2024, 6, 10);
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );

    scenario(
      'published survey within date range accepts responses',
      given: () {
        status = SurveyStatus.published;
        startsAt = DateTime(2024, 6, 1);
        endsAt = DateTime(2024, 6, 30);
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isTrue);
      },
    );

    scenario(
      'draft survey rejects responses',
      given: () {
        status = SurveyStatus.draft;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );

    scenario(
      'closed survey rejects responses',
      given: () {
        status = SurveyStatus.closed;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );

    scenario(
      'archived survey rejects responses',
      given: () {
        status = SurveyStatus.archived;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.isAcceptingResponses(
          status: status,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );
  });

  group('SurveyRules.canTransition', () {
    late SurveyStatus from;
    late SurveyStatus to;
    late bool result;

    group('from draft status', () {
      scenario(
        'draft to published is allowed',
        given: () {
          from = SurveyStatus.draft;
          to = SurveyStatus.published;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isTrue);
        },
      );

      scenario(
        'draft to closed is not allowed',
        given: () {
          from = SurveyStatus.draft;
          to = SurveyStatus.closed;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isFalse);
        },
      );

      scenario(
        'draft to archived is allowed',
        given: () {
          from = SurveyStatus.draft;
          to = SurveyStatus.archived;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isTrue);
        },
      );
    });

    group('from published status', () {
      scenario(
        'published to closed is allowed',
        given: () {
          from = SurveyStatus.published;
          to = SurveyStatus.closed;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isTrue);
        },
      );

      scenario(
        'published to draft is not allowed',
        given: () {
          from = SurveyStatus.published;
          to = SurveyStatus.draft;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isFalse);
        },
      );

      scenario(
        'published to archived is allowed',
        given: () {
          from = SurveyStatus.published;
          to = SurveyStatus.archived;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isTrue);
        },
      );
    });

    group('from closed status', () {
      scenario(
        'closed to published (reopen) is allowed',
        given: () {
          from = SurveyStatus.closed;
          to = SurveyStatus.published;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isTrue);
        },
      );

      scenario(
        'closed to draft is not allowed',
        given: () {
          from = SurveyStatus.closed;
          to = SurveyStatus.draft;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isFalse);
        },
      );

      scenario(
        'closed to archived is allowed',
        given: () {
          from = SurveyStatus.closed;
          to = SurveyStatus.archived;
        },
        when: () {
          result = SurveyRules.canTransition(from, to);
        },
        then: () {
          expect(result, isTrue);
        },
      );
    });

    group('from archived status', () {
      for (final targetStatus in [
        SurveyStatus.draft,
        SurveyStatus.published,
        SurveyStatus.closed,
      ]) {
        scenario(
          'archived to ${targetStatus.name} is not allowed',
          given: () {
            from = SurveyStatus.archived;
            to = targetStatus;
          },
          when: () {
            result = SurveyRules.canTransition(from, to);
          },
          then: () {
            expect(result, isFalse);
          },
        );
      }
    });
  });

  group('SurveyRules.canPublish', () {
    late SurveyStatus status;
    late int questionCount;
    late bool result;

    scenario(
      'draft survey with questions can be published',
      given: () {
        status = SurveyStatus.draft;
        questionCount = 3;
      },
      when: () {
        result = SurveyRules.canPublish(
          status: status,
          questionCount: questionCount,
        );
      },
      then: () {
        expect(result, isTrue);
      },
    );

    scenario(
      'draft survey without questions cannot be published',
      given: () {
        status = SurveyStatus.draft;
        questionCount = 0;
      },
      when: () {
        result = SurveyRules.canPublish(
          status: status,
          questionCount: questionCount,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );

    scenario(
      'published survey cannot be published again',
      given: () {
        status = SurveyStatus.published;
        questionCount = 5;
      },
      when: () {
        result = SurveyRules.canPublish(
          status: status,
          questionCount: questionCount,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );

    scenario(
      'closed survey cannot be published directly',
      given: () {
        status = SurveyStatus.closed;
        questionCount = 5;
      },
      when: () {
        result = SurveyRules.canPublish(
          status: status,
          questionCount: questionCount,
        );
      },
      then: () {
        expect(result, isFalse);
      },
    );
  });

  group('SurveyRules.validateResponseSubmission', () {
    late SurveyStatus status;
    late AuthRequirement authRequirement;
    late bool isAuthenticated;
    late DateTime? startsAt;
    late DateTime? endsAt;
    late DateTime now;
    late ResponseValidation result;

    scenario(
      'anonymous survey accepts unauthenticated response',
      given: () {
        status = SurveyStatus.published;
        authRequirement = AuthRequirement.anonymous;
        isAuthenticated = false;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      },
    );

    scenario(
      'anonymous survey accepts authenticated response',
      given: () {
        status = SurveyStatus.published;
        authRequirement = AuthRequirement.anonymous;
        isAuthenticated = true;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isTrue);
      },
    );

    scenario(
      'authenticated survey rejects unauthenticated response',
      given: () {
        status = SurveyStatus.published;
        authRequirement = AuthRequirement.authenticated;
        isAuthenticated = false;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Authentication required'));
      },
    );

    scenario(
      'authenticated survey accepts authenticated response',
      given: () {
        status = SurveyStatus.published;
        authRequirement = AuthRequirement.authenticated;
        isAuthenticated = true;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isTrue);
      },
    );

    scenario(
      'draft survey rejects response with appropriate message',
      given: () {
        status = SurveyStatus.draft;
        authRequirement = AuthRequirement.anonymous;
        isAuthenticated = false;
        startsAt = null;
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('not accepting responses'));
      },
    );

    scenario(
      'survey before start date rejects with appropriate message',
      given: () {
        status = SurveyStatus.published;
        authRequirement = AuthRequirement.anonymous;
        isAuthenticated = false;
        startsAt = DateTime(2024, 6, 20);
        endsAt = null;
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('not started'));
      },
    );

    scenario(
      'survey after end date rejects with appropriate message',
      given: () {
        status = SurveyStatus.published;
        authRequirement = AuthRequirement.anonymous;
        isAuthenticated = false;
        startsAt = null;
        endsAt = DateTime(2024, 6, 10);
        now = DateTime(2024, 6, 15);
      },
      when: () {
        result = SurveyRules.validateResponseSubmission(
          status: status,
          authRequirement: authRequirement,
          isAuthenticated: isAuthenticated,
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
        );
      },
      then: () {
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('ended'));
      },
    );
  });
}
