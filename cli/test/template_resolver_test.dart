import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:form_concierge_cli/form_concierge_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temporary;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('form-concierge-template-');
  });

  tearDown(() {
    temporary.deleteSync(recursive: true);
  });

  test('CLI version matches pubspec and default release asset URL', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: $formConciergeCliVersion'));
    expect(
      defaultTemplateArchiveUri(formConciergeCliVersion).toString(),
      'https://github.com/hyshu/form_concierge/releases/download/'
      'v$formConciergeCliVersion/'
      'form-concierge-template-$formConciergeCliVersion.tar.gz',
    );
  });

  test('downloads, verifies, extracts, and reuses a cached template', () async {
    final archive = _templateArchive();
    final checksum = sha256.convert(archive).toString();
    final requests = <Uri>[];
    final resolver = TemplateResolver(
      cacheRoot: temporary.path,
      downloader: (uri) async {
        requests.add(uri);
        return uri.path.endsWith('.sha256')
            ? utf8.encode('$checksum  template.tar.gz\n')
            : archive;
      },
      log: (_) {},
    );

    final first = await resolver.resolve(version: '1.2.3');
    expect(
      File(p.join(first, 'worker', 'wrangler.jsonc.example')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(first, 'admin_dashboard', 'pubspec.yaml')).existsSync(),
      isTrue,
    );
    expect(requests, hasLength(2));

    final second = await resolver.resolve(version: '1.2.3', offline: true);
    expect(second, first);
    expect(requests, hasLength(2));
  });

  test('rejects a checksum mismatch without populating the cache', () async {
    final resolver = TemplateResolver(
      cacheRoot: temporary.path,
      downloader: (_) async => _templateArchive(),
      log: (_) {},
    );

    await expectLater(
      resolver.resolve(version: '1.0.0', expectedSha256: '0' * 64),
      throwsA(
        isA<CliException>().having(
          (error) => error.message,
          'message',
          contains('checksum mismatch'),
        ),
      ),
    );
    expect(Directory(p.join(temporary.path, '1.0.0')).existsSync(), isFalse);
  });

  test('rejects archive path traversal', () async {
    final archive = _tarGz({'../escaped.txt': 'bad'});
    final resolver = TemplateResolver(
      cacheRoot: temporary.path,
      downloader: (_) async => archive,
      log: (_) {},
    );

    await expectLater(
      resolver.resolve(
        version: '1.0.0',
        expectedSha256: sha256.convert(archive).toString(),
      ),
      throwsA(
        isA<CliException>().having(
          (error) => error.message,
          'message',
          contains('unsafe path'),
        ),
      ),
    );
    expect(
      File(p.join(temporary.parent.path, 'escaped.txt')).existsSync(),
      isFalse,
    );
  });

  test('offline mode reports a missing cached version', () async {
    final resolver = TemplateResolver(
      cacheRoot: temporary.path,
      downloader: (_) async => fail('network must not be used'),
      log: (_) {},
    );

    await expectLater(
      resolver.resolve(version: '9.9.9', offline: true),
      throwsA(
        isA<CliException>().having(
          (error) => error.message,
          'message',
          contains('not available'),
        ),
      ),
    );
  });
}

List<int> _templateArchive() => _tarGz({
  'worker/wrangler.jsonc.example': '{}',
  'admin_dashboard/pubspec.yaml': 'name: admin\n',
  'web/pubspec.yaml': 'name: web\n',
});

List<int> _tarGz(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile.string(entry.key, entry.value));
  }
  final tar = TarEncoder().encodeBytes(archive);
  return const GZipEncoder().encodeBytes(tar);
}
