import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_flutter/src/features/dashboard/presentation/capsules/survey_list_capsule.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/capsules/aggregated_results_capsule.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/capsules/notification_settings_capsule.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/capsules/response_list_capsule.dart';
import 'package:form_concierge_flutter/src/features/settings/presentation/capsules/admin_settings_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/question_list_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_state.dart';
import 'package:form_concierge_flutter/src/features/users/presentation/capsules/user_list_capsule.dart';

void main() {
  group('admin initial loading state', () {
    test('remote-loaded admin screens start in loading state', () {
      expect(SurveyListState.initial().isLoading, isTrue);
      expect(UserListState.initial().isLoading, isTrue);
      expect(const AdminSettingsState().isLoading, isTrue);
      expect(ResponseListState.initial().isLoading, isTrue);
      expect(AggregatedResultsState.initial().isLoading, isTrue);
      expect(NotificationSettingsState.initial().isLoading, isTrue);
      expect(QuestionListState.initial().isLoading, isTrue);
    });

    test('new survey form does not start in loading state', () {
      expect(SurveyFormState.initial().isLoading, isFalse);
    });
  });
}
