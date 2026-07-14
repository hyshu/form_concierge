import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'cli_exception.dart';
import 'cloudflare/deployment_config.dart';
import 'cloudflare/secret_names.dart';
import 'monorepo.dart';
import 'template_resolver.dart';
import 'tools.dart';

class DestroyCommand extends Command<int> {
  DestroyCommand() {
    addSubcommand(DestroyCloudflareCommand());
  }

  @override
  String get name => 'destroy';

  @override
  String get description => 'Destroy a deployed Form Concierge backend.';
}

class DestroyCloudflareCommand extends Command<int> {
  DestroyCloudflareCommand() {
    argParser
      ..addFlag(
        'dry-run',
        help: 'Print resources without deleting them.',
        negatable: false,
      )
      ..addOption(
        'deployment',
        help: 'Saved deployment name (for example production or staging).',
      )
      ..addFlag(
        'include-data',
        help: 'Also delete D1 and an empty R2 bucket.',
        negatable: false,
      )
      ..addFlag(
        'empty-r2',
        help: 'Request deletion of R2 content (not yet automated).',
        negatable: false,
      )
      ..addFlag(
        'delete-secrets-store',
        help: 'Also delete only Form Concierge-owned secret values.',
        negatable: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skip interactive confirmation.',
        negatable: false,
      )
      ..addOption(
        'template-version',
        defaultsTo: formConciergeCliVersion,
        help: 'Cached template version providing Wrangler.',
      );
  }

  @override
  String get name => 'cloudflare';

  @override
  String get description => 'Destroy resources recorded in a saved deployment.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final store = await CloudflareDeploymentStore.select(
      requestedName: results['deployment'] as String?,
      allowCreate: false,
    );
    final deployment = await store.load();
    if (deployment == null) {
      throw CliException('Missing ${store.path}. Nothing to destroy.');
    }

    final includeData = results['include-data'] == true;
    final emptyR2 = results['empty-r2'] == true;
    final deleteSecretsStore = results['delete-secrets-store'] == true;
    if (emptyR2 && !includeData) {
      throw CliException('--empty-r2 requires --include-data.');
    }
    if (emptyR2) {
      throw CliException(
        'Automatic R2 content deletion is not available. Empty bucket '
        '"${deployment.r2BucketName}" in the Cloudflare dashboard, then run '
        'destroy again with --include-data.',
      );
    }

    _printPlan(deployment, includeData, deleteSecretsStore);
    if (results['dry-run'] == true) return 0;

    if (results['yes'] != true) {
      final expected = deployment.workerName ?? 'destroy';
      final answer = await promptOptional(
        'Type "$expected" to permanently destroy these resources: ',
      );
      if (answer != expected) {
        stdout.writeln('Destroy cancelled.');
        return 0;
      }
    }

    final root =
        findMonorepoRoot() ??
        await TemplateResolver().resolve(
          version: results['template-version'] as String,
          offline: true,
        );
    final workerDirectory = MonorepoPaths(root).worker;
    await _verifyAccount(deployment, workerDirectory);

    await _deleteWorker(deployment, store, workerDirectory);
    await _deletePages(deployment, store, workerDirectory, admin: true);
    await _deletePages(deployment, store, workerDirectory, admin: false);
    if (includeData) {
      await _deleteD1(deployment, store, workerDirectory);
      await _deleteR2(deployment, store, workerDirectory);
    }
    if (deleteSecretsStore) {
      await _deleteFormConciergeSecrets(deployment, store, workerDirectory);
    }

    if (deployment.hasResources) {
      await store.save(deployment);
      stdout.writeln('==> Destroy incomplete; remaining resources saved.');
    } else {
      await store.delete();
      stdout.writeln('==> Deployment destroyed.');
    }
    return 0;
  }

  void _printPlan(
    CloudflareDeploymentConfig deployment,
    bool includeData,
    bool deleteSecretsStore,
  ) {
    stdout.writeln('Cloudflare resources selected for permanent deletion:');
    if (deployment.accountId != null) {
      stdout.writeln('  Account: ${deployment.accountId}');
    }
    if (deployment.workerName != null) {
      stdout.writeln('  Worker: ${deployment.workerName}');
    }
    if (deployment.adminPagesProject != null) {
      stdout.writeln('  Admin Pages: ${deployment.adminPagesProject}');
    }
    if (deployment.webPagesProject != null) {
      stdout.writeln('  Web Pages: ${deployment.webPagesProject}');
    }
    if (deployment.databaseName != null) {
      stdout.writeln(
        includeData
            ? '  D1: ${deployment.databaseName} (all data)'
            : '  D1: ${deployment.databaseName} (kept; use --include-data)',
      );
    }
    if (deployment.r2BucketName != null) {
      stdout.writeln(
        includeData
            ? '  R2: ${deployment.r2BucketName} (deleted only when empty)'
            : '  R2: ${deployment.r2BucketName} (kept; use --include-data)',
      );
    }
    if (deployment.secretsStoreId != null) {
      stdout.writeln(
        deleteSecretsStore
            ? '  Secrets: Form Concierge-owned values only'
            : '  Secrets Store: kept (use --delete-secrets-store)',
      );
    }
  }

  Future<void> _verifyAccount(
    CloudflareDeploymentConfig deployment,
    String workerDirectory,
  ) async {
    final expected = deployment.accountId;
    if (expected == null || expected.isEmpty) return;
    final result = await runCapture(
      'npx',
      ['wrangler', 'whoami', '--json'],
      workingDirectory: workerDirectory,
      throwOnError: false,
    );
    if (result.exitCode != 0) {
      throw CliException('Could not verify Cloudflare account.');
    }
    final data = jsonDecode((result.stdout as String).trim());
    final accounts = data is Map ? data['accounts'] : null;
    final ids = accounts is List
        ? accounts.whereType<Map>().map((account) => '${account['id']}').toSet()
        : <String>{};
    if (!ids.contains(expected)) {
      throw CliException(
        'Cloudflare account mismatch. Expected $expected; authenticated: '
        '${ids.isEmpty ? 'none' : ids.join(', ')}.',
      );
    }
  }

  Future<void> _deleteWorker(
    CloudflareDeploymentConfig deployment,
    CloudflareDeploymentStore store,
    String cwd,
  ) async {
    final name = deployment.workerName;
    if (name == null) return;
    await _runDelete(
      ['wrangler', 'delete', name, '--force'],
      cwd,
      'Worker $name',
    );
    deployment
      ..workerName = null
      ..workerUrl = null;
    await store.save(deployment);
  }

  Future<void> _deletePages(
    CloudflareDeploymentConfig deployment,
    CloudflareDeploymentStore store,
    String cwd, {
    required bool admin,
  }) async {
    final name = admin
        ? deployment.adminPagesProject
        : deployment.webPagesProject;
    if (name == null) return;
    await _runDelete(
      ['wrangler', 'pages', 'project', 'delete', name, '--yes'],
      cwd,
      'Pages $name',
    );
    if (admin) {
      deployment
        ..adminPagesProject = null
        ..adminPagesUrl = null;
    } else {
      deployment
        ..webPagesProject = null
        ..webPagesUrl = null
        ..publicFormAssetBaseUrl = null;
    }
    await store.save(deployment);
  }

  Future<void> _deleteD1(
    CloudflareDeploymentConfig deployment,
    CloudflareDeploymentStore store,
    String cwd,
  ) async {
    final name = deployment.databaseName;
    if (name == null) return;
    await _runDelete(
      ['wrangler', 'd1', 'delete', name, '--skip-confirmation'],
      cwd,
      'D1 $name',
    );
    deployment
      ..databaseName = null
      ..databaseId = null;
    await store.save(deployment);
  }

  Future<void> _deleteR2(
    CloudflareDeploymentConfig deployment,
    CloudflareDeploymentStore store,
    String cwd,
  ) async {
    final name = deployment.r2BucketName;
    if (name == null) return;
    final result = await runCapture(
      'npx',
      ['wrangler', 'r2', 'bucket', 'delete', name],
      workingDirectory: cwd,
      throwOnError: false,
    );
    if (result.exitCode != 0) {
      stderr.writeln('[kept] R2 $name');
      stderr.writeln(
        'Bucket may contain objects. Empty it in Cloudflare dashboard, then '
        'run destroy again with --include-data.',
      );
      return;
    }
    stdout.writeln('[deleted] R2 $name');
    deployment.r2BucketName = null;
    await store.save(deployment);
  }

  Future<void> _deleteFormConciergeSecrets(
    CloudflareDeploymentConfig deployment,
    CloudflareDeploymentStore store,
    String cwd,
  ) async {
    final id = deployment.secretsStoreId;
    if (id == null) return;
    final listResult = await runCapture(
      'npx',
      [
        'wrangler',
        'secrets-store',
        'secret',
        'list',
        id,
        '--per-page',
        '100',
        '--remote',
      ],
      workingDirectory: cwd,
      throwOnError: false,
    );
    if (listResult.exitCode != 0) {
      final detail = '${listResult.stdout}\n${listResult.stderr}';
      if (!detail.toLowerCase().contains('no secrets')) {
        throw CliException('Failed to list Secrets Store secrets.');
      }
    }
    final output = '${listResult.stdout}\n${listResult.stderr}';
    final ownedNames = formConciergeSecretNames
        .map(formConciergeSecretName)
        .toSet();
    final ownedSecrets = <String, String>{};
    for (final line in output.split('\n')) {
      final cells = line
          .split('│')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
      if (cells.length >= 2 && ownedNames.contains(cells[0])) {
        ownedSecrets[cells[0]] = cells[1];
      }
    }
    for (final entry in ownedSecrets.entries) {
      final result = await runCapture(
        'npx',
        [
          'wrangler',
          'secrets-store',
          'secret',
          'delete',
          id,
          '--secret-id',
          entry.value,
          '--remote',
        ],
        workingDirectory: cwd,
        throwOnError: false,
      );
      if (result.exitCode == 0) {
        stdout.writeln('[deleted] Secret ${entry.key}');
        continue;
      }
      throw CliException('Failed to delete Secret ${entry.key}.');
    }
    deployment
      ..secretsStoreName = null
      ..secretsStoreId = null;
    await store.save(deployment);
  }

  Future<void> _runDelete(
    List<String> arguments,
    String cwd,
    String label,
  ) async {
    final result = await runCapture(
      'npx',
      arguments,
      workingDirectory: cwd,
      throwOnError: false,
    );
    if (result.exitCode != 0) {
      final detail = '${result.stdout}\n${result.stderr}'.trim();
      if (detail.isNotEmpty) stderr.writeln(detail);
      throw CliException('Failed to delete $label.');
    }
    stdout.writeln('[deleted] $label');
  }
}
