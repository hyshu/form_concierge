/// Returns an empty host name on platforms without a browser location.
String currentHostname() => '';

/// Returns the root path on platforms without a browser location.
String currentPathname() => '/';

/// Does nothing on platforms without the required browser APIs.
void replaceLocation(String path) {}
