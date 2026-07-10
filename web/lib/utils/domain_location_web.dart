import 'package:web/web.dart' as web;

String currentHostname() => web.window.location.hostname;

String currentPathname() => web.window.location.pathname;

void replaceLocation(String path) => web.window.location.replace(path);
