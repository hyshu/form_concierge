import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

const authInputClasses =
    'w-full px-4 py-3 border border-slate-200 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 focus:outline-none text-sm disabled:bg-slate-50 disabled:cursor-not-allowed placeholder:text-slate-400';

const authPrimaryButtonClasses =
    'w-full py-3 px-4 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm';

class AuthErrorMessage extends StatelessComponent {
  const AuthErrorMessage(this.message, {super.key});

  final String message;

  @override
  Component build(BuildContext context) {
    return div(
        classes:
            'flex items-start gap-3 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm',
        [
          span(classes: 'text-red-500 flex-shrink-0', [
            Component.text('\u26A0'),
          ]),
          span([Component.text(message)]),
        ]);
  }
}
