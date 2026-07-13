import 'dart:io';

import 'package:args/command_runner.dart';

import 'cloudflare/setup_options.dart';
import 'cloudflare/setup_runner.dart';
import 'monorepo.dart';
import 'template_resolver.dart';

class SetupCommand extends Command<int> {
  SetupCommand() {
    addSubcommand(CloudflareDeploymentCommand(action: 'setup'));
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Scaffold and provision Form Concierge backends.';
}

class UpdateCommand extends Command<int> {
  UpdateCommand() {
    addSubcommand(CloudflareDeploymentCommand(action: 'update'));
  }

  @override
  String get name => 'update';

  @override
  String get description => 'Update deployed Form Concierge backends.';
}

class CloudflareDeploymentCommand extends Command<int> {
  CloudflareDeploymentCommand({required this.action}) {
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
      ..addOption(
        'deployment',
        help: 'Saved deployment name (for example production or staging).',
      )
      ..addOption('database-name', help: 'D1 database name.')
      ..addOption('worker-name', help: 'Worker name.')
      ..addOption('r2-bucket-name', help: 'R2 bucket for media uploads.')
      ..addOption('r2-binding', help: 'Worker R2 binding name.')
      ..addOption('api-url', help: 'Public Worker API URL.')
      ..addOption('admin-project', help: 'Pages project for admin.')
      ..addFlag(
        'admin-pages',
        help: 'Deploy the admin dashboard to Cloudflare Pages.',
        negatable: false,
      )
      ..addFlag(
        'no-admin-pages',
        help: 'Do not build or deploy the admin dashboard to Pages.',
        negatable: false,
      )
      ..addOption('web-project', help: 'Pages project for public assets.')
      ..addOption('web-asset-base-url', help: 'Asset base used by SSR HTML.')
      ..addOption(
        'local-d1-persist-to',
        help: 'Local D1 state path used when reading the source project.',
      )
      ..addOption(
        'template-version',
        defaultsTo: formConciergeCliVersion,
        help: 'GitHub Release template version used outside a checkout.',
      )
      ..addOption(
        'template-url',
        help: 'Override the release template archive URL.',
      )
      ..addOption(
        'template-sha256',
        help: 'Expected archive SHA-256 (otherwise downloads URL.sha256).',
      )
      ..addFlag(
        'offline',
        help: 'Use a checkout or cached template without network access.',
        negatable: false,
      )
      ..addFlag(
        'refresh-template',
        help: 'Redownload and replace the cached release template.',
        negatable: false,
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

  final String action;

  @override
  String get name => 'cloudflare';

  @override
  String get description => action == 'update'
      ? 'Update D1, R2, Worker, and Pages using saved deployment settings.'
      : 'Create/configure D1, R2, Worker, and Pages.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final localRoot = findMonorepoRoot();
    final root =
        localRoot ??
        (results['explain'] == true
            ? Directory.current.path
            : await TemplateResolver().resolve(
                version: results['template-version'] as String,
                archiveUrl: results['template-url'] as String?,
                expectedSha256: results['template-sha256'] as String?,
                offline: results['offline'] == true,
                refresh: results['refresh-template'] == true,
              ));
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

    bool? deployAdminPages;
    if (results['admin-pages'] == true) {
      deployAdminPages = true;
    } else if (results['no-admin-pages'] == true) {
      deployAdminPages = false;
    }

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
      deployAdminPages: deployAdminPages,
      webProject: results['web-project'] as String?,
      webAssetBaseUrl: results['web-asset-base-url'] as String?,
      localD1PersistTo: results['local-d1-persist-to'] as String?,
      remoteBindingsForLocalDev: remoteBindings,
      wranglerUpdateConfig: wranglerUpdate,
      targetVersion: results['template-version'] as String,
    );

    final runner = CloudflareSetupRunner(
      paths: MonorepoPaths(root),
      options: options,
      invocationDir: Directory.current.path,
      deploymentName: results['deployment'] as String?,
      allowCreateDeployment: action == 'setup',
    );
    return runner.run();
  }
}
