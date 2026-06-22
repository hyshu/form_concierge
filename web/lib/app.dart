import 'package:jaspr/jaspr.dart';

import 'components/domain_redirect_client.dart';
import 'components/survey_client.dart';
import 'utils/domain_location.dart';

class App extends StatelessComponent {
  const App({required this.serverUrl, super.key});

  final String serverUrl;

  @override
  Component build(BuildContext context) {
    final slug = _slugFromPath(currentPathname());
    if (slug == null) {
      return DomainRedirectClient(serverUrl: serverUrl);
    }
    return SurveyClient(serverUrl: serverUrl, slug: slug);
  }

  String? _slugFromPath(String pathname) {
    final path = pathname.trim();
    if (path.isEmpty || path == '/') return null;
    final firstSegment =
        path.split('/').where((segment) => segment.isNotEmpty).firstOrNull;
    return firstSegment == null ? null : Uri.decodeComponent(firstSegment);
  }
}
