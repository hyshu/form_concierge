import 'package:web/web.dart' as web;

String? getTurnstileResponse() {
  final input = web.document.querySelector(
    '.cf-turnstile input[name="cf-turnstile-response"]',
  );
  if (input == null) return null;
  final value = (input as web.HTMLInputElement).value;
  return value.isEmpty ? null : value;
}
