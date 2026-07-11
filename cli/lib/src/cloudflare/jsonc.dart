import 'dart:convert';

/// Strips `//` line comments and trailing commas from JSONC, then parses JSON.
dynamic parseJsonc(String raw) {
  final withoutComments = raw.replaceAllMapped(
    RegExp(r'("(?:[^"\\]|\\.)*")|//[^\n]*'),
    (match) => match.group(1) ?? '',
  );
  final withoutTrailingCommas = withoutComments.replaceAllMapped(
    RegExp(r',\s*([}\]])'),
    (m) => m[1]!,
  );
  return jsonDecode(withoutTrailingCommas);
}

String encodePrettyJson(Object? value) {
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert(value)}\n';
}
