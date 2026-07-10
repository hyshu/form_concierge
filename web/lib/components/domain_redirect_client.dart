import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';

import 'not_found_page.dart';
import 'survey_error.dart';
import 'survey_loading.dart';
import '../utils/domain_location.dart';

class DomainRedirectClient extends StatefulComponent {
  const DomainRedirectClient({
    required this.serverUrl,
    super.key,
  });

  final String serverUrl;

  @override
  State<DomainRedirectClient> createState() => DomainRedirectClientState();
}

class DomainRedirectClientState extends State<DomainRedirectClient> {
  var _state = _DomainRedirectState.loading;

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
      final project =
          await Client(component.serverUrl).survey.getProjectByDomain(
                domain,
              );
      if (project == null || project.surveys.length != 1) {
        setState(() => _state = _DomainRedirectState.notFound);
        return;
      }
      replaceLocation('/${project.surveys.first.id}');
    } on Exception catch (_) {
      setState(() => _state = _DomainRedirectState.error);
    }
  }

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

enum _DomainRedirectState {
  loading,
  notFound,
  error,
}
