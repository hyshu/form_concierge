import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'cli_exception.dart';
import 'cloudflare/deployment_config.dart';
import 'monorepo.dart';
import 'template_resolver.dart';
import 'tools.dart';

/// Groups commands that build Form Concierge applications.
class BuildCommand extends Command<int> {
  /// Creates the build command and registers its options.
  BuildCommand() {
    addSubcommand(AdminMacosBuildCommand());
  }

  /// The command name accepted on the command line.
  @override
  String get name => 'build';

  /// The description displayed in command help.
  @override
  String get description => 'Build Form Concierge applications.';
}

/// Builds the administrator application for macOS.
class AdminMacosBuildCommand extends Command<int> {
  /// Creates the admin macos build command and registers its options.
  AdminMacosBuildCommand() {
    argParser
      ..addOption('api-url', help: 'Worker API URL embedded in the app.')
      ..addOption(
        'deployment',
        help: 'Saved deployment name (for example production or staging).',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Destination directory; defaults to the current directory.',
      )
      ..addOption(
        'template-version',
        defaultsTo: formConciergeCliVersion,
        help: 'Template version used outside a checkout.',
      )
      ..addOption('template-url', help: 'Override the template archive URL.')
      ..addOption('template-sha256', help: 'Expected archive SHA-256.')
      ..addFlag(
        'offline',
        help: 'Use a checkout or cached template without network access.',
        negatable: false,
      )
      ..addFlag(
        'refresh-template',
        help: 'Redownload and replace the cached release template.',
        negatable: false,
      );
  }

  /// The command name accepted on the command line.
  @override
  String get name => 'admin-macos';

  /// The description displayed in command help.
  @override
  String get description =>
      'Build the macOS admin app and copy it to the current directory.';

  /// Runs the command with the parsed options and returns its process exit code.
  @override
  Future<int> run() async {
    if (!Platform.isMacOS) {
      throw CliException('The macOS admin app can only be built on macOS.');
    }

    final results = argResults!;
    final invocationDir = Directory.current.absolute.path;
    final localRoot = findMonorepoRoot();
    final root =
        localRoot ??
        await TemplateResolver().resolve(
          version: results['template-version'] as String,
          archiveUrl: results['template-url'] as String?,
          expectedSha256: results['template-sha256'] as String?,
          offline: results['offline'] == true,
          refresh: results['refresh-template'] == true,
        );
    final paths = MonorepoPaths(root);
    CloudflareDeploymentConfig? deployment;
    if (results['api-url'] == null) {
      final store = await CloudflareDeploymentStore.select(
        requestedName: results['deployment'] as String?,
        allowCreate: false,
      );
      deployment = await store.load();
    }
    final apiUrl = results['api-url'] as String? ?? deployment?.workerUrl;
    if (apiUrl == null || apiUrl.isEmpty) {
      throw CliException(
        'Worker API URL missing. Pass --api-url or select a saved deployment.',
      );
    }

    stdout.writeln('==> Build macOS admin');
    await runInherit('flutter', ['pub', 'get'], workingDirectory: paths.admin);
    await runInherit('flutter', [
      'build',
      'macos',
      '--release',
      '--dart-define=FORM_CONCIERGE_API_URL=$apiUrl',
    ], workingDirectory: paths.admin);

    final products = Directory(
      p.join(paths.admin, 'build', 'macos', 'Build', 'Products', 'Release'),
    );
    final apps = products.existsSync()
        ? products
              .listSync()
              .whereType<Directory>()
              .where((entry) => p.extension(entry.path) == '.app')
              .toList()
        : <Directory>[];
    if (apps.length != 1) {
      throw CliException(
        'Expected one .app in ${products.path}, found ${apps.length}.',
      );
    }

    final outputArg = results['output'] as String?;
    final output = Directory(
      outputArg == null
          ? invocationDir
          : p.normalize(
              p.isAbsolute(outputArg)
                  ? outputArg
                  : p.join(invocationDir, outputArg),
            ),
    );
    await output.create(recursive: true);
    final destination = Directory(
      p.join(output.path, p.basename(apps.single.path)),
    );
    if (destination.existsSync()) {
      await destination.delete(recursive: true);
    }
    await runInherit('ditto', [apps.single.path, destination.path]);
    stdout.writeln('Admin app: ${destination.path}');
    return 0;
  }
}
