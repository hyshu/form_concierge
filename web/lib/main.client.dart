import 'package:jaspr/client.dart';

import 'app.dart';

const _serverUrl = 'http://localhost:8787';

void main() {
  runApp(
    const App(serverUrl: _serverUrl),
  );
}
