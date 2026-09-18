import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';

import 'not_found_page.dart';
import 'survey_error.dart';
import 'survey_loading.dart';
import '../utils/domain_location.dart';

/// Resolves a custom domain to its project and redirects to an available survey.
class DomainRedirectClient extends StatefulComponent {
  /// Creates DomainRedirectClient with the supplied values.
  const DomainRedirectClient({required this.serverUrl, super.key});

  /// The base URL used to connect to the API server.
  final String serverUrl;

  /// Creates the state that manages this interactive component.
  @override
  State<DomainRedirectClient> createState() => DomainRedirectClientState();
}

/// Loads the domain's project and tracks redirect progress.
class DomainRedirectClientState extends State<DomainRedirectClient> {
  var _state = _DomainRedirectState.loading;

  /// Initializes the component and starts loading its required data.
  @override
  void initState() {
    super.initState();
    _resolveDomain();
  }

  Future<void> _resolveDomain() async {
    setState(() => _state = _DomainRedirectState.loading);
    try {
      final domain = currentHostname().trim().toLowerCase();
      if (domain.isEmpty) {
        setState(() => _state = _DomainRedirectState.notFound);
        return;
      }
      final project = await Client(
        component.serverUrl,
      ).survey.getProjectByDomain(domain);
      if (project == null || project.surveys.length != 1) {
        setState(() => _state = _DomainRedirectState.notFound);
        return;
      }
      replaceLocation('/${project.surveys.first.id}');
    } on Exception catch (_) {
      setState(() => _state = _DomainRedirectState.error);
    }
  }

  /// Builds the HTML components for the current input and state.
  @override
  Component build(context) => switch (_state) {
    _DomainRedirectState.loading => const SurveyLoading(),
    _DomainRedirectState.notFound => const NotFoundPage(),
    _DomainRedirectState.error => SurveyError(
      locale: defaultFormContentLocale,
      message: FormContentMessages.text(
        defaultFormContentLocale,
        'errorOccurred',
      ),
      onRetry: _resolveDomain,
    ),
  };
}

enum _DomainRedirectState { loading, notFound, error }
