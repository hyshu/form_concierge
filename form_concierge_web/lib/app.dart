import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/survey_page.dart';
import 'components/not_found_page.dart';

class App extends StatelessComponent {
  const App({required this.serverUrl, super.key});

  final String serverUrl;

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(
          path: '/s/:slug',
          builder: (context, state) => SurveyPage(
            slug: state.params['slug']!,
            serverUrl: serverUrl,
          ),
        ),
        Route(
          path: '/:path(.*)',
          builder: (context, state) => const NotFoundPage(),
        ),
      ],
    );
  }
}
