import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Ordered browser language preferences (`navigator.languages`, then
/// `navigator.language`).
List<String> browserPreferredLocales() {
  final result = <String>[
    for (final language in web.window.navigator.languages.toDart)
      language.toDart,
  ].where((value) => value.isNotEmpty).toList();
  if (result.isEmpty) {
    final language = web.window.navigator.language;
    if (language.isNotEmpty) {
      result.add(language);
    }
  }
  return result;
}
