import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks up from [start] (default: cwd) looking for monorepo markers.
///
/// Markers: `worker/wrangler.jsonc.example` (or local `wrangler.jsonc`) and
/// `admin_dashboard/pubspec.yaml`. The real config is gitignored; the example
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
  MonorepoPaths(this.root);

  final String root;

  String get worker => p.join(root, 'worker');
  String get admin => p.join(root, 'admin_dashboard');
  String get web => p.join(root, 'web');
  String get wranglerConfig => p.join(worker, 'wrangler.jsonc');
  String get wranglerConfigExample => p.join(worker, 'wrangler.jsonc.example');
  String get wranglerBin => p.join(worker, 'node_modules', '.bin', 'wrangler');
  String get listLocalProjectsScript =>
      p.join(root, 'tool', 'cloudflare', 'list_local_projects.mjs');
  String get exportProjectSeedScript =>
      p.join(root, 'tool', 'cloudflare', 'export_project_seed.mjs');
}
