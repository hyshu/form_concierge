import 'package:jaspr/client.dart';

import 'app.dart';
import 'utils/ssr_payload.dart';

const _serverUrl = 'http://localhost:8787';

/// Initializes the application and starts its root interface.
void main() {
  final serverUrl = readConfiguredApiUrl() ?? _serverUrl;
  removeSsrRoot();

  runApp(App(serverUrl: serverUrl));
}
