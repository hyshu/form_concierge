import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'monorepo.dart';
import 'tools.dart';

class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check local tools required for Form Concierge.';

  @override
  Future<int> run() async {
    final missing = <String>[];
    for (final cmd in const ['dart', 'flutter', 'node', 'npm', 'npx']) {
      if (!await commandExists(cmd)) {
        missing.add(cmd);
      }
    }

    if (missing.isEmpty) {
      stdout.writeln('All required commands found: dart flutter node npm npx');
    } else {
      stdout.writeln('Missing required command(s): ${missing.join(' ')}');
    }

    final root = findMonorepoRoot();
    if (root == null) {
      stdout.writeln(
        'Monorepo root not found (looked for worker/wrangler.jsonc '
        'and admin_dashboard/pubspec.yaml).',
      );
    } else {
      stdout.writeln('Monorepo root: $root');
      final paths = MonorepoPaths(root);
      stdout.writeln(
        File(paths.wranglerConfig).existsSync()
            ? 'Worker config: ${paths.wranglerConfig}'
            : 'Worker config missing: ${paths.wranglerConfig}',
      );
      final helpersOk =
          File(paths.listLocalProjectsScript).existsSync() &&
          File(paths.exportProjectSeedScript).existsSync();
      stdout.writeln(
        helpersOk
            ? 'Cloudflare helper scripts: present under tool/cloudflare/'
            : 'Cloudflare helper scripts: missing under tool/cloudflare/',
      );
    }

    final wranglerOk =
        await commandExists('wrangler') ||
        (root != null &&
            File(
              p.join(root, 'worker', 'node_modules', '.bin', 'wrangler'),
            ).existsSync());
    stdout.writeln(
      wranglerOk
          ? 'Wrangler: available (global or worker/node_modules)'
          : 'Wrangler: not found (run npm install in worker/)',
    );

    return missing.isEmpty ? 0 : 1;
  }
}
