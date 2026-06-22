import 'package:web/web.dart' as web;

Future<String?> readAuthSession(String key) async =>
    web.window.localStorage.getItem(key);

Future<void> writeAuthSession(String key, String value) async {
  web.window.localStorage.setItem(key, value);
}

Future<void> clearAuthSession(String key) async {
  web.window.localStorage.removeItem(key);
}
