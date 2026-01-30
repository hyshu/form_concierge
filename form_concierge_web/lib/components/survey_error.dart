import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class SurveyError extends StatelessComponent {
  const SurveyError({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final void Function()? onRetry;

  @override
  Component build(BuildContext context) {
    return div(
        classes:
            'max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 text-center py-12 px-6',
        [
          div(
              classes:
                  'w-14 h-14 bg-red-100 rounded-full flex items-center justify-center mx-auto',
              [
                span(classes: 'text-red-500 text-2xl', [
                  Component.text('\u26A0'),
                ]),
              ]),
          h2(classes: 'mt-5 text-xl font-semibold text-slate-900', [
            Component.text('Something went wrong'),
          ]),
          p(classes: 'mt-2 text-slate-600', [
            Component.text(message),
          ]),
          if (onRetry != null)
            div(classes: 'mt-6', [
              button(
                [Component.text('Try Again')],
                classes:
                    'px-6 py-2.5 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 shadow-sm',
                onClick: onRetry,
              ),
            ]),
        ]);
  }
}
