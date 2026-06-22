import 'package:web/web.dart' as web;

String currentHostname() => web.window.location.hostname;

void replaceLocation(String path) {
  web.window.location.replace(path);
}
