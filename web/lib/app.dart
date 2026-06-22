import 'package:jaspr/jaspr.dart';

import 'components/survey_client.dart';
import 'utils/domain_location.dart';

class App extends StatelessComponent {
  const App({required this.serverUrl, super.key});

  final String serverUrl;

  @override
  Component build(BuildContext context) {
    final parts = _pathParts(currentPathname());
    final projectSlug = parts.isEmpty ? null : parts.first;
    final surveyId = parts.length >= 2
        ? int.tryParse(parts[1])
        : (parts.length == 1 ? int.tryParse(parts[0]) : null);
    return SurveyClient(
      serverUrl: serverUrl,
      projectSlug: projectSlug,
      surveyId: surveyId,
      domain: currentHostname(),
    );
  }

  List<String> _pathParts(String pathname) {
    final path = pathname.trim();
    if (path.isEmpty || path == '/') return const [];
    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.decodeComponent)
        .toList();
  }
}
