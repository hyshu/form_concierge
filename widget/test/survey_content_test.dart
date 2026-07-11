import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge/src/widgets/survey_content.dart';

void main() {
  group('SurveyContent', () {
    testWidgets('renders localized survey text and changes locale', (
      tester,
    ) async {
      var selectedLocale = 'en';

      await tester.pumpWidget(
        _subject(
          locale: selectedLocale,
          showLocalePicker: true,
          onLocaleChanged: (locale) => selectedLocale = locale,
        ),
      );

      expect(find.text('Customer feedback'), findsOneWidget);
      expect(find.text('Tell us what you think'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('日本語').last);
      await tester.pumpAndSettle();

      expect(selectedLocale, 'ja');
    });

    testWidgets('renders validation and submit error messages', (tester) async {
      await tester.pumpWidget(
        _subject(
          validationErrors: const {1: 'Name is required'},
          errorMessage: 'Submit failed',
        ),
      );

      expect(find.text('Submit failed'), findsOneWidget);
      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('text question reports typed value', (tester) async {
      final answers = <int, AnswerValue>{};

      await tester.pumpWidget(
        _subject(
          questions: [_question(id: 1, type: QuestionType.textSingle)],
          onAnswerChanged: (questionId, value) {
            answers[questionId] = value;
          },
        ),
      );

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pump();

      expect(answers, {1: 'Alice'});
    });

    testWidgets('single choice question reports selected choice ID', (
      tester,
    ) async {
      final answers = <int, AnswerValue>{};

      await tester.pumpWidget(
        _subject(
          questions: [_question(id: 2, type: QuestionType.singleChoice)],
          choicesByQuestion: {
            2: [_choice(id: 10, questionId: 2, text: 'Yes')],
          },
          onAnswerChanged: (questionId, value) {
            answers[questionId] = value;
          },
        ),
      );

      await tester.tap(find.text('Yes'));
      await tester.pump();

      expect(answers, {2: 10});
    });

    testWidgets(
      'multiple choice enforces max selection and toggles selected IDs',
      (tester) async {
        final answers = <int, AnswerValue>{};

        await tester.pumpWidget(
          _subject(
            questions: [
              _question(
                id: 3,
                type: QuestionType.multipleChoice,
                maxSelected: 1,
              ),
            ],
            choicesByQuestion: {
              3: [
                _choice(id: 20, questionId: 3, text: 'Red'),
                _choice(id: 21, questionId: 3, text: 'Blue'),
              ],
            },
            answers: const {
              3: [20],
            },
            onAnswerChanged: (questionId, value) {
              answers[questionId] = value;
            },
          ),
        );

        final disabledTile = tester.widget<CheckboxListTile>(
          find.widgetWithText(CheckboxListTile, 'Blue'),
        );
        expect(disabledTile.onChanged, isNull);

        await tester.tap(find.text('Red'));
        await tester.pump();

        expect(answers, {3: <int>[]});
      },
    );

    testWidgets(
      'submit button is disabled and shows progress while submitting',
      (tester) async {
        var submitted = false;

        await tester.pumpWidget(
          _subject(isSubmitting: true, onSubmit: () => submitted = true),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
        expect(submitted, isFalse);
      },
    );
  });
}

Widget _subject({
  String locale = 'en',
  List<Question>? questions,
  Map<int, List<Choice>> choicesByQuestion = const {},
  AnswerValues answers = const {},
  ValidationErrors validationErrors = const {},
  String? errorMessage,
  bool isSubmitting = false,
  bool showLocalePicker = false,
  void Function(int questionId, AnswerValue value)? onAnswerChanged,
  ValueChanged<String>? onLocaleChanged,
  VoidCallback? onSubmit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SurveyContent(
        client: Client('http://localhost:8787'),
        project: _project(),
        survey: _survey(),
        questions:
            questions ?? [_question(id: 1, type: QuestionType.textSingle)],
        choicesByQuestion: choicesByQuestion,
        answers: answers,
        validationErrors: validationErrors,
        errorMessage: errorMessage,
        locale: locale,
        isSubmitting: isSubmitting,
        showLocalePicker: showLocalePicker,
        onAnswerChanged: onAnswerChanged ?? (_, _) {},
        onLocaleChanged: onLocaleChanged ?? (_) {},
        onSubmit: onSubmit ?? () {},
      ),
    ),
  );
}

Survey _survey() {
  final now = DateTime.utc(2026, 6, 22, 10);
  return Survey(
    id: 1,
    projectId: 1,
    slug: 'customer-feedback',
    titleTranslations: const LocalizedText({
      'en': 'Customer feedback',
      'ja': '顧客フィードバック',
    }),
    descriptionTranslations: const LocalizedText({
      'en': 'Tell us what you think',
      'ja': 'ご意見をお聞かせください',
    }),
    status: SurveyStatus.published,
    createdAt: now,
    updatedAt: now,
  );
}

Project _project() {
  final now = DateTime.utc(2026, 6, 22, 10);
  return Project(
    id: 1,
    slug: 'customer-feedback',
    defaultLocale: 'en',
    supportedLocales: const ['en', 'ja'],
    name: 'Customer feedback',
    createdAt: now,
    updatedAt: now,
  );
}

Question _question({
  required int id,
  required QuestionType type,
  int? maxSelected,
}) {
  return Question(
    id: id,
    surveyId: 1,
    textTranslations: LocalizedText({'en': 'Question $id', 'ja': '質問 $id'}),
    type: type,
    orderIndex: id,
    isRequired: true,
    placeholderTranslations: const LocalizedText({
      'en': 'Type here',
      'ja': 'ここに入力',
    }),
    maxSelected: maxSelected,
  );
}

Choice _choice({
  required int id,
  required int questionId,
  required String text,
}) {
  return Choice(
    id: id,
    questionId: questionId,
    textTranslations: LocalizedText({'en': text, 'ja': text}),
    orderIndex: id,
  );
}
