import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class SurveyLoading extends StatelessComponent {
  const SurveyLoading({super.key});

  @override
  Component build(BuildContext context) {
    return div(
        classes:
            'max-w-xl mx-auto flex flex-col items-center justify-center min-h-[320px] bg-white rounded-xl shadow-md border border-slate-200',
        [
          div(
              classes:
                  'w-10 h-10 border-3 border-slate-200 border-t-indigo-600 rounded-full animate-spin',
              []),
          p(classes: 'mt-4 text-slate-500 text-sm', [
            Component.text('Loading survey...'),
          ]),
        ]);
  }
}
