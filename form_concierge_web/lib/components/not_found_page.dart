import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class NotFoundPage extends StatelessComponent {
  const NotFoundPage({super.key});

  @override
  Component build(BuildContext context) {
    return div(
        classes:
            'max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 text-center py-16 px-6',
        [
          h1(classes: 'text-7xl font-light text-slate-300', [
            Component.text('404'),
          ]),
          p(classes: 'mt-4 text-lg font-medium text-slate-700', [
            Component.text('Page not found'),
          ]),
          p(classes: 'mt-2 text-sm text-slate-500', [
            Component.text('The page you are looking for does not exist.'),
          ]),
        ]);
  }
}
