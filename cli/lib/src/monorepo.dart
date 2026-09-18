import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks up from [start], or the current directory, to find the monorepo root.
///
/// Looks for `worker/wrangler.jsonc.example` or the local `wrangler.jsonc`, together with
/// `admin_dashboard/pubspec.yaml`. The real configuration is gitignored. The example
/// is the committed template.
String? findMonorepoRoot({String? start}) {
  var dir = Directory(start ?? Directory.current.path).absolute;
  while (true) {
    final workerDir = p.join(dir.path, 'worker');
    final hasWrangler =
        File(p.join(workerDir, 'wrangler.jsonc.example')).existsSync() ||
        File(p.join(workerDir, 'wrangler.jsonc')).existsSync();
    final admin = File(p.join(dir.path, 'admin_dashboard', 'pubspec.yaml'));
    if (hasWrangler && admin.existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

/// Paths derived from a monorepo root.
class MonorepoPaths {
  /// Creates MonorepoPaths with the supplied values.
  MonorepoPaths(this.root);

  /// The absolute path to the monorepo root directory.
  final String root;

  /// The API Worker source directory.
  String get worker => p.join(root, 'worker');

  /// The administrator application source directory.
  String get admin => p.join(root, 'admin_dashboard');

  /// The public web application source directory.
  String get web => p.join(root, 'web');

  /// The path to the local Wrangler configuration.
  String get wranglerConfig => p.join(worker, 'wrangler.jsonc');

  /// The path to the committed Wrangler configuration template.
  String get wranglerConfigExample => p.join(worker, 'wrangler.jsonc.example');

  /// The path to the locally installed Wrangler executable.
  String get wranglerBin => p.join(worker, 'node_modules', '.bin', 'wrangler');

  /// The path to the script that lists locally stored projects.
  String get listLocalProjectsScript =>
      p.join(root, 'tool', 'cloudflare', 'list_local_projects.mjs');

  /// The path to the script that exports a project's seed data.
  String get exportProjectSeedScript =>
      p.join(root, 'tool', 'cloudflare', 'export_project_seed.mjs');
}
