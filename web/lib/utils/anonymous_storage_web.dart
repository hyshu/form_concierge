import 'package:web/web.dart' as web;

String? readAnonymousToken(String key) => web.window.localStorage.getItem(key);

void writeAnonymousToken(String key, String token) {
  web.window.localStorage.setItem(key, token);
}
