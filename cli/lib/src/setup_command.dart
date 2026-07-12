import 'dart:io';

import 'package:args/command_runner.dart';

import 'cli_exception.dart';
import 'cloudflare/setup_options.dart';
import 'cloudflare/setup_runner.dart';
import 'monorepo.dart';

class SetupCommand extends Command<int> {
  SetupCommand() {
    addSubcommand(SetupCloudflareCommand());
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Scaffold and provision Form Concierge backends.';
}

class SetupCloudflareCommand extends Command<int> {
  SetupCloudflareCommand() {
    argParser
      ..addFlag(
        'preflight-only',
        help: 'Check local tools and Cloudflare auth without deploying.',
        negatable: false,
      )
      ..addFlag(
        'explain',
        help: 'Print setup overview without deploying.',
        negatable: false,
      )
      ..addFlag(
        'list-local-projects',
        help: 'Print local project IDs from the local D1 database.',
        negatable: false,
      )
      ..addOption('seed-project-id', help: 'Local project ID to seed remotely.')
      ..addOption('project-id', help: 'Alias for --seed-project-id.')
      ..addOption('database-id', help: 'Cloudflare D1 database UUID.')
      ..addOption('database-name', help: 'D1 database name.')
      ..addOption('worker-name', help: 'Worker name.')
      ..addOption('r2-bucket-name', help: 'R2 bucket for media uploads.')
      ..addOption('r2-binding', help: 'Worker R2 binding name.')
      ..addOption('api-url', help: 'Public Worker API URL.')
      ..addOption('admin-project', help: 'Pages project for admin.')
      ..addOption('web-project', help: 'Pages project for public assets.')
      ..addOption('web-asset-base-url', help: 'Asset base used by SSR HTML.')
      ..addOption(
        'local-d1-persist-to',
        help: 'Local D1 state path used when reading the source project.',
      )
      ..addFlag(
        'remote-bindings-for-local-dev',
        help: 'Use remote D1/R2 bindings during wrangler dev.',
        negatable: false,
      )
      ..addFlag(
        'local-bindings-for-local-dev',
        help: 'Use local D1/R2 bindings during wrangler dev.',
        negatable: false,
      )
      ..addFlag(
        'wrangler-update-config',
        help: 'Let Wrangler update config when creating D1/R2 resources.',
        negatable: false,
      )
      ..addFlag(
        'no-wrangler-update-config',
        help: 'Do not let Wrangler update config when creating resources.',
        negatable: false,
      );
  }

  @override
  String get name => 'cloudflare';

  @override
  String get description =>
      'Create/configure D1, R2, Worker, and Pages (Dart implementation).';

  @override
  Future<int> run() async {
    final root = findMonorepoRoot();
    if (root == null) {
      throw CliException(
        'Could not find Form Concierge monorepo root.\n'
        'Run this command from a checkout that contains '
        'worker/wrangler.jsonc.example and admin_dashboard/pubspec.yaml.\n'
        '(Published template download is not implemented yet.)',
      );
    }

    final results = argResults!;
    bool? remoteBindings;
    if (results['remote-bindings-for-local-dev'] == true) {
      remoteBindings = true;
    } else if (results['local-bindings-for-local-dev'] == true) {
      remoteBindings = false;
    }

    bool? wranglerUpdate;
    if (results['wrangler-update-config'] == true) {
      wranglerUpdate = true;
    } else if (results['no-wrangler-update-config'] == true) {
      wranglerUpdate = false;
    }

    final seed =
        results['seed-project-id'] as String? ??
        results['project-id'] as String?;

    final options = CloudflareSetupOptions(
      preflightOnly: results['preflight-only'] == true,
      explain: results['explain'] == true,
      listLocalProjects: results['list-local-projects'] == true,
      seedProjectId: seed,
      databaseId: results['database-id'] as String?,
      databaseName: results['database-name'] as String?,
      workerName: results['worker-name'] as String?,
      r2BucketName: results['r2-bucket-name'] as String?,
      r2Binding: (results['r2-binding'] as String?) ?? 'MEDIA_BUCKET',
      apiUrl: results['api-url'] as String?,
      adminProject: results['admin-project'] as String?,
      webProject: results['web-project'] as String?,
      webAssetBaseUrl: results['web-asset-base-url'] as String?,
      localD1PersistTo: results['local-d1-persist-to'] as String?,
      remoteBindingsForLocalDev: remoteBindings,
      wranglerUpdateConfig: wranglerUpdate,
    );

    final runner = CloudflareSetupRunner(
      paths: MonorepoPaths(root),
      options: options,
      invocationDir: Directory.current.path,
    );
    return runner.run();
  }
}
