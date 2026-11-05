import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/core/capsules/client_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/models/draft_question.dart';
import 'package:rearch/rearch.dart';

void main() {
  test(
    'draft conditions retain stable references and reject destructive source edits',
    () {
      final client = Client('https://api.example.com');
      addTearDown(client.close);
      final container = MockableContainer()
        ..mock(clientCapsule).apply((_) => client);
      addTearDown(container.dispose);
      final manager = container.read(surveyFormManagerCapsule);

      void add(String title, {List<DraftVisibilityRule> rules = const []}) =>
          manager.addDraftQuestion(
            textTranslations: LocalizedText({'en': title}),
            type: QuestionType.singleChoice,
            isRequired: false,
            placeholderTranslations: const LocalizedText({'en': ''}),
            visibilityConditionMode: VisibilityConditionMode.any,
            visibilityRules: rules,
            firstChoiceTranslations: const LocalizedText({'en': 'One'}),
            secondChoiceTranslations: const LocalizedText({'en': 'Two'}),
          );

      add('Source');
      final source = manager.getState(null).draftQuestions.first;
      add(
        'Target',
        rules: [
          DraftVisibilityRule(
            sourceQuestionTempId: source.tempId,
            operator: VisibilityOperator.equals,
            value: source.choices[1].tempId,
          ),
        ],
      );
      manager.deleteDraftQuestion(source.tempId);
      expect(manager.getState(null).draftQuestions, hasLength(2));
      expect(manager.getState(null).error, isNotNull);
      manager.deleteDraftChoice(source.tempId, source.choices[1].tempId);
      expect(manager.getState(null).draftQuestions.first.choices, hasLength(2));
      manager.reorderDraftQuestions(0, 1);
      expect(manager.getState(null).draftQuestions.first.tempId, source.tempId);
      manager.updateDraftQuestion(
        tempId: source.tempId,
        textTranslations: source.textTranslations,
        type: QuestionType.textSingle,
        isRequired: false,
        placeholderTranslations: source.placeholderTranslations,
        visibilityConditionMode: VisibilityConditionMode.all,
      );
      expect(
        manager.getState(null).draftQuestions.first.type,
        QuestionType.singleChoice,
      );

      manager.updateDraftChoice(
        source.tempId,
        source.choices[1].tempId,
        const LocalizedText({'en': 'Renamed'}),
      );
      add('Independent');
      manager.reorderDraftQuestions(2, 0);
      final drafts = manager.getState(null).draftQuestions;
      final context = DraftVisibilityContext(drafts, 2);
      final rules = context.toCreationRules(drafts[2].visibilityRules);
      expect(rules.single.sourceQuestionIndex, 1);
      expect(rules.single.targetQuestionIndex, 2);
      expect(rules.single.choiceIndex, 1);
      final roundTrip = context.fromEditorRules(
        context.toEditorRules(drafts[2].visibilityRules),
      );
      expect(roundTrip.single.sourceQuestionTempId, source.tempId);
      expect(roundTrip.single.value, source.choices[1].tempId);
    },
  );
}
