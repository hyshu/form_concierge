import 'package:jaspr/jaspr.dart';

import 'components/survey_client.dart';
import 'utils/domain_location.dart';

class App extends StatelessComponent {
  const App({required this.serverUrl, super.key});

  final String serverUrl;

  @override
  Component build(BuildContext context) {
    final parts = _pathParts(currentPathname());
    final isApiHost = Uri.parse(serverUrl).host == currentHostname();
    final projectSlug = isApiHost && parts.isNotEmpty ? parts.first : null;
    final surveyKey = isApiHost
        ? (parts.length >= 2 ? parts[1] : null)
        : (parts.isNotEmpty ? parts.first : null);
    final surveyId = surveyKey != null && RegExp(r'^\d+$').hasMatch(surveyKey)
        ? int.tryParse(surveyKey)
        : null;
    final surveySlug = surveyKey != null && surveyId == null ? surveyKey : null;
    return SurveyClient(
      serverUrl: serverUrl,
      projectSlug: projectSlug,
      surveySlug: surveySlug,
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
