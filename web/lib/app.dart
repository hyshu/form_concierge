import 'package:jaspr/jaspr.dart';

import 'components/survey_client.dart';
import 'utils/domain_location.dart';

/// The root component that selects the public form route.
class App extends StatelessComponent {
  /// Creates App with the supplied values.
  const App({required this.serverUrl, super.key});

  /// The base URL used to connect to the API server.
  final String serverUrl;

  /// Builds the HTML components for the current input and state.
  @override
  Component build(context) {
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
