import 'dart:io';

import 'package:form_concierge_cli/form_concierge_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('findMonorepoRoot discovers root from cli package directory', () {
    final cliDir = Directory.current.path;
    // test runs with cwd = cli/
    final root = findMonorepoRoot(start: cliDir);
    expect(root, isNotNull);
    expect(File(p.join(root!, 'tool', 'cloudflare', 'setup.sh')).existsSync(), isTrue);
    expect(Directory(p.join(root, 'worker')).existsSync(), isTrue);
  });

  test('findMonorepoRoot returns null outside monorepo', () {
    final root = findMonorepoRoot(start: Directory.systemTemp.path);
    expect(root, isNull);
  });
}
