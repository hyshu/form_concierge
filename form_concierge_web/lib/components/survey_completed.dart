import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class SurveyCompleted extends StatelessComponent {
  const SurveyCompleted({
    required this.survey,
    super.key,
  });

  final Survey survey;

  @override
  Component build(BuildContext context) {
    return div(
        classes:
            'max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 text-center py-12 px-6',
        [
          div(
              classes:
                  'w-16 h-16 bg-emerald-500 rounded-full flex items-center justify-center mx-auto',
              [
                span(classes: 'text-white text-3xl', [
                  Component.text('\u2713'),
                ]),
              ]),
          h2(classes: 'mt-5 text-xl font-semibold text-slate-900', [
            Component.text('Thank you!'),
          ]),
          p(classes: 'mt-2 text-slate-600', [
            Component.text('Your response has been submitted successfully.'),
          ]),
        ]);
  }
}
