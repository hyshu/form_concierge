import 'package:form_concierge_cli/src/cloudflare/jsonc.dart';
import 'package:test/test.dart';

void main() {
  test('parseJsonc strips comments and trailing commas', () {
    const raw = '''
{
  // worker name
  "name": "demo",
  "vars": {
    "PUBLIC_BASE_URL": "https://example.com",
  },
}
''';
    final parsed = parseJsonc(raw) as Map<String, dynamic>;
    expect(parsed['name'], 'demo');
    expect((parsed['vars'] as Map)['PUBLIC_BASE_URL'], 'https://example.com');
  });

  test('encodePrettyJson ends with newline', () {
    final out = encodePrettyJson({'a': 1});
    expect(out.endsWith('\n'), isTrue);
    expect(out, contains('"a": 1'));
  });
}
