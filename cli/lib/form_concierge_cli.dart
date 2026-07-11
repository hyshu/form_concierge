import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Entry point for the Form Concierge CLI.
Future<int> runFormConciergeCli(List<String> args) async {
  final runner = CommandRunner<int>(
    'form_concierge',
    'Form Concierge tooling (setup, doctor).',
  )
    ..addCommand(DoctorCommand())
    ..addCommand(SetupCommand());

  try {
    final result = await runner.run(args);
    return result ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    return 64;
  } on CliException catch (error) {
    stderr.writeln(error.message);
    return error.exitCode;
  }
}

class CliException implements Exception {
  CliException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}

class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check local tools required for Form Concierge.';

  @override
  Future<int> run() async {
    final missing = <String>[];
    for (final cmd in const ['dart', 'flutter', 'node', 'npm', 'npx']) {
      if (!await _commandExists(cmd)) {
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
        'Monorepo root not found (looked for worker/ and tool/cloudflare/setup.sh).',
      );
    } else {
      stdout.writeln('Monorepo root: $root');
      final setup = p.join(root, 'tool', 'cloudflare', 'setup.sh');
      stdout.writeln(
        File(setup).existsSync()
            ? 'Cloudflare setup script: $setup'
            : 'Cloudflare setup script missing: $setup',
      );
    }

    final wranglerOk = await _commandExists('wrangler') ||
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
        defaultsTo: null,
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
      'Create/configure D1, R2, Worker, and Pages via the monorepo setup script.';

  @override
  Future<int> run() async {
    final root = findMonorepoRoot();
    if (root == null) {
      throw CliException(
        'Could not find Form Concierge monorepo root.\n'
        'Run this command from a checkout that contains worker/ and '
        'tool/cloudflare/setup.sh.\n'
        '(Published template download is not implemented yet.)',
      );
    }

    final setupScript = p.join(root, 'tool', 'cloudflare', 'setup.sh');
    if (!File(setupScript).existsSync()) {
      throw CliException('Setup script not found: $setupScript');
    }

    final forwarded = _forwardedArgs(argResults!);
    final process = await Process.start(
      setupScript,
      forwarded,
      mode: ProcessStartMode.inheritStdio,
      workingDirectory: root,
    );
    return process.exitCode;
  }

  List<String> _forwardedArgs(ArgResults results) {
    final args = <String>[];

    void addFlag(String name) {
      if (results[name] == true) {
        args.add('--$name');
      }
    }

    void addOption(String name) {
      final value = results[name] as String?;
      if (value != null && value.isNotEmpty) {
        args
          ..add('--$name')
          ..add(value);
      }
    }

    addFlag('preflight-only');
    addFlag('explain');
    addFlag('list-local-projects');
    addFlag('remote-bindings-for-local-dev');
    addFlag('local-bindings-for-local-dev');
    addFlag('no-wrangler-update-config');
    if (results['wrangler-update-config'] == true) {
      args.add('--wrangler-update-config');
    }

    addOption('seed-project-id');
    addOption('project-id');
    addOption('database-id');
    addOption('database-name');
    addOption('worker-name');
    addOption('r2-bucket-name');
    addOption('r2-binding');
    addOption('api-url');
    addOption('admin-project');
    addOption('web-project');
    addOption('web-asset-base-url');
    addOption('local-d1-persist-to');

    return args;
  }
}

/// Walks up from [start] (default: cwd) looking for monorepo markers.
String? findMonorepoRoot({String? start}) {
  var dir = Directory(start ?? Directory.current.path).absolute;
  while (true) {
    final worker = Directory(p.join(dir.path, 'worker'));
    final setup = File(p.join(dir.path, 'tool', 'cloudflare', 'setup.sh'));
    if (worker.existsSync() && setup.existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
}

Future<bool> _commandExists(String command) async {
  try {
    final result = Platform.isWindows
        ? await Process.run('where', [command], runInShell: true)
        : await Process.run(
            'sh',
            ['-c', r'command -v -- "$1"', '_', command],
          );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
