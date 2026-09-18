import 'package:web/web.dart' as web;

/// Returns the host name of the current browser location.
String currentHostname() => web.window.location.hostname;

/// Returns the path of the current browser location.
String currentPathname() => web.window.location.pathname;

/// Navigates to the supplied path while replacing the current history entry.
void replaceLocation(String path) => web.window.location.replace(path);
