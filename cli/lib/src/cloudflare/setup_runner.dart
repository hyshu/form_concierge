import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli_exception.dart';
import '../monorepo.dart';
import '../tools.dart';
import 'jsonc.dart';
import 'setup_options.dart';

/// Orchestrates Cloudflare D1 / R2 / Worker / Pages provisioning.
class CloudflareSetupRunner {
  CloudflareSetupRunner({
    required this.paths,
    required this.options,
    this.invocationDir,
  });

  final MonorepoPaths paths;
  final CloudflareSetupOptions options;
  final String? invocationDir;

  List<String> _jasprCmd = const ['jaspr'];
  String? _seedFile;
  String? _secretsStoreId;

  Future<int> run() async {
    if (options.explain) {
      _printExplain();
      return 0;
    }

    _resolveLocalD1PersistPath();

    if (options.listLocalProjects) {
      await _checkCommands();
      await _installWorkerDependencies();
      final dbName =
          options.databaseName ?? CloudflareSetupOptions.defaultD1DatabaseName;
      await _runNodeScript(paths.listLocalProjectsScript, [
        dbName,
      ], localD1Persist: true);
      return 0;
    }

    if (options.seedProjectId != null) {
      final id = options.seedProjectId!;
      if (!RegExp(r'^[1-9][0-9]*$').hasMatch(id)) {
        throw CliException('Project ID must be a positive integer.');
      }
    }

    try {
      await _runPreflight();
      if (options.preflightOnly) {
        stdout.writeln('Preflight OK.');
        return 0;
      }

      await _selectWranglerUpdateConfig();
      await _selectRemoteBindingsForLocalDev();
      await _selectResourceNames();

      options.webAssetBaseUrl ??= 'https://${options.webProject}.pages.dev';

      stdout.writeln(
        options.wranglerUpdateConfig == true
            ? '==> Wrangler config update: yes'
            : '==> Wrangler config update: no',
      );
      stdout.writeln(
        options.remoteBindingsForLocalDev == true
            ? '==> Local dev bindings: remote D1/R2'
            : '==> Local dev bindings: local D1/R2',
      );

      options.apiUrl ??= await _readWranglerValue('public_base_url');
      if (_isPlaceholderApiUrl(options.apiUrl)) {
        options.apiUrl = null;
      }

      if (options.seedProjectId != null) {
        stdout.writeln(
          '==> Export local project seed: ${options.seedProjectId}',
        );
        await _exportLocalProjectSeed();
      } else {
        stdout.writeln('==> Project seed: skipped');
      }

      await _ensureD1Database();
      await _ensureR2Bucket();
      await _waitForR2Bucket();
      await _ensureSecretsStore();
      await _ensureCfApiToken();

      stdout.writeln('==> Configure Worker');
      await _updateWrangler();

      stdout.writeln('==> Worker typecheck');
      await runInherit('npm', [
        'run',
        'typecheck',
      ], workingDirectory: paths.worker);

      stdout.writeln('==> Apply D1 migrations');
      await runInherit(
        'npx',
        [
          'wrangler',
          'd1',
          'migrations',
          'apply',
          options.databaseName!,
          '--remote',
        ],
        workingDirectory: paths.worker,
        environment: {...Platform.environment, 'CI': '1'},
      );

      if (options.seedProjectId != null && _seedFile != null) {
        stdout.writeln('==> Seed remote D1 project: ${options.seedProjectId}');
        await runInherit('npx', [
          'wrangler',
          'd1',
          'execute',
          options.databaseName!,
          '--remote',
          '--file',
          _seedFile!,
          '--yes',
        ], workingDirectory: paths.worker);
      }

      stdout.writeln('==> Deploy Worker');
      final deployedApiUrl = await _deployWorker();
      if (options.apiUrl == null || _isPlaceholderApiUrl(options.apiUrl)) {
        if (deployedApiUrl == null || deployedApiUrl.isEmpty) {
          throw CliException(
            'Could not infer Worker URL. Re-run with --api-url.',
          );
        }
        options.apiUrl = deployedApiUrl;
        stdout.writeln('==> Update Worker public URL: ${options.apiUrl}');
        await _updateWrangler();
        await _deployWorker();
      }

      stdout.writeln('==> Build admin');
      await runInherit('flutter', [
        'pub',
        'get',
      ], workingDirectory: paths.admin);
      await runInherit('flutter', [
        'build',
        'web',
        '--release',
      ], workingDirectory: paths.admin);
      final configPath = p.join(
        paths.admin,
        'build',
        'web',
        'assets',
        'assets',
        'config.json',
      );
      await Directory(p.dirname(configPath)).create(recursive: true);
      await File(
        configPath,
      ).writeAsString(jsonEncode({'apiUrl': options.apiUrl}));

      stdout.writeln('==> Deploy admin Pages: ${options.adminProject}');
      await _ensurePagesProject(options.adminProject!);
      await runInherit(paths.wranglerBin, [
        'pages',
        'deploy',
        p.join(paths.admin, 'build', 'web'),
        '--project-name',
        options.adminProject!,
        '--commit-dirty=true',
      ], workingDirectory: paths.root);

      stdout.writeln('==> Build public form assets');
      await runInherit('dart', ['pub', 'get'], workingDirectory: paths.web);
      await runInherit(_jasprCmd.first, [
        ..._jasprCmd.skip(1),
        'build',
      ], workingDirectory: paths.web);
      await _injectWebIndexApiUrl();

      stdout.writeln(
        '==> Deploy public form assets Pages: ${options.webProject}',
      );
      await _ensurePagesProject(options.webProject!);
      await runInherit(paths.wranglerBin, [
        'pages',
        'deploy',
        p.join(paths.web, 'build', 'jaspr'),
        '--project-name',
        options.webProject!,
        '--commit-dirty=true',
      ], workingDirectory: paths.root);

      stdout.writeln('==> Done');
      stdout.writeln('API: ${options.apiUrl}');
      stdout.writeln('Admin: https://${options.adminProject}.pages.dev');
      stdout.writeln('Public assets: https://${options.webProject}.pages.dev');
      stdout.writeln('R2 bucket: ${options.r2BucketName}');
      return 0;
    } finally {
      if (_seedFile != null) {
        try {
          File(_seedFile!).deleteSync();
        } catch (_) {}
      }
    }
  }

  void _resolveLocalD1PersistPath() {
    final path = options.localD1PersistTo;
    if (path == null || path.isEmpty) return;
    if (p.isAbsolute(path)) return;
    final base = invocationDir ?? Directory.current.path;
    options.localD1PersistTo = p.normalize(p.join(base, path));
  }

  Future<void> _runPreflight() async {
    stdout.writeln('==> Preflight');
    await _checkCommands();
    await _installWorkerDependencies();
    await _ensureWranglerAuth();
    await _ensureJaspr();
  }

  Future<void> _checkCommands() async {
    final missing = <String>[];
    for (final cmd in const ['dart', 'flutter', 'node', 'npm', 'npx']) {
      if (!await commandExists(cmd)) {
        missing.add(cmd);
      }
    }
    if (missing.isNotEmpty) {
      throw CliException(
        'Missing required command(s): ${missing.join(' ')}\n'
        'Install Dart, Flutter, Node.js/npm, then rerun setup.',
      );
    }
  }

  Future<void> _installWorkerDependencies() async {
    stdout.writeln('==> Install Worker dependencies');
    await runInherit('npm', ['install'], workingDirectory: paths.worker);
  }

  Future<void> _ensureWranglerAuth() async {
    stdout.writeln('==> Wrangler auth');
    final result = await runCapture(
      'npx',
      ['wrangler', 'whoami'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (result.exitCode != 0) {
      final out = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();
      if (out.isNotEmpty) stderr.writeln(out);
      if (err.isNotEmpty) stderr.writeln(err);
      throw CliException('''
Wrangler preflight failed.

If this is an authentication failure, run one of:

  cd worker
  npx wrangler login

or set CLOUDFLARE_API_TOKEN with permissions for Workers, D1, R2, and Pages.

If Wrangler reported a configuration error above, fix worker/wrangler.jsonc first.
''');
    }
  }

  Future<void> _ensureJaspr() async {
    if (await commandExists('jaspr')) {
      _jasprCmd = const ['jaspr'];
      return;
    }
    stdout.writeln('==> Install Jaspr CLI');
    await runInherit('dart', [
      'pub',
      'global',
      'activate',
      'jaspr_cli',
      '0.23.1',
    ]);
    _jasprCmd = const ['dart', 'pub', 'global', 'run', 'jaspr_cli:jaspr'];
  }

  Future<void> _selectWranglerUpdateConfig() async {
    if (options.wranglerUpdateConfig != null) return;
    final answer = await promptOptional(
      'Let Wrangler add created D1/R2 resources to worker/wrangler.jsonc? [Y/n] ',
    );
    options.wranglerUpdateConfig = _parseYesDefaultTrue(answer);
  }

  Future<void> _selectRemoteBindingsForLocalDev() async {
    if (options.remoteBindingsForLocalDev != null) return;
    final answer = await promptOptional(
      'Use remote D1/R2 bindings for local wrangler dev? [y/N] ',
    );
    options.remoteBindingsForLocalDev = _parseYesDefaultFalse(answer);
  }

  Future<void> _selectResourceNames() async {
    options.workerName = await _resolveName(
      options.workerName,
      'Worker name',
      CloudflareSetupOptions.defaultWorkerName,
    );
    options.databaseName = await _resolveName(
      options.databaseName,
      'D1 database name',
      CloudflareSetupOptions.defaultD1DatabaseName,
    );
    options.r2BucketName = await _resolveName(
      options.r2BucketName,
      'R2 bucket name',
      CloudflareSetupOptions.defaultR2BucketName,
    );
    options.adminProject = await _resolveName(
      options.adminProject,
      'Admin Pages project',
      CloudflareSetupOptions.defaultAdminProject,
    );
    options.webProject = await _resolveName(
      options.webProject,
      'Public assets Pages project',
      CloudflareSetupOptions.defaultWebProject,
    );

    final missing = [
      options.workerName,
      options.databaseName,
      options.r2BucketName,
      options.adminProject,
      options.webProject,
    ].any((v) => v == null || v.isEmpty);
    if (missing) {
      throw CliException('''
Resource names are required.

Run setup interactively, or pass:

  form_concierge setup cloudflare \\
    --worker-name <worker-name> \\
    --database-name <database-name> \\
    --r2-bucket-name <bucket-name> \\
    --admin-project <pages-project> \\
    --web-project <pages-project>
''');
    }
  }

  /// Returns [current] if set; otherwise prompts (interactive) or empty.
  Future<String?> _resolveName(
    String? current,
    String label,
    String defaultValue,
  ) async {
    if (current != null && current.isNotEmpty) return current;
    final prompted = await promptName(label, defaultValue);
    if (prompted.isEmpty) return null;
    return prompted;
  }

  bool _parseYesDefaultTrue(String? answer) {
    if (answer == null || answer.trim().isEmpty) return true;
    final v = answer.trim().toLowerCase();
    if (const {'0', 'false', 'n', 'no'}.contains(v)) return false;
    return true;
  }

  bool _parseYesDefaultFalse(String? answer) {
    if (answer == null || answer.trim().isEmpty) return false;
    final v = answer.trim().toLowerCase();
    if (const {'1', 'true', 'y', 'yes'}.contains(v)) return true;
    return false;
  }

  bool _isPlaceholderApiUrl(String? url) {
    if (url == null || url.isEmpty) return true;
    if (url.startsWith('replace-')) return true;
    if (url.startsWith('http://localhost:')) return true;
    if (url.startsWith('http://127.0.0.1:')) return true;
    return false;
  }

  Future<String> _readWranglerValue(String key) async {
    final raw = await File(paths.wranglerConfig).readAsString();
    final config = parseJsonc(raw) as Map<String, dynamic>;
    if (key == 'database_id') {
      final d1 = config['d1_databases'];
      if (d1 is List && d1.isNotEmpty) {
        return '${(d1.first as Map)['database_id'] ?? ''}';
      }
      return '';
    }
    if (key == 'public_base_url') {
      final vars = config['vars'];
      if (vars is Map) {
        return '${vars['PUBLIC_BASE_URL'] ?? ''}';
      }
      return '';
    }
    return '';
  }

  Future<String> _findD1DatabaseId() async {
    final result = await runCapture(
      'npx',
      ['wrangler', 'd1', 'list', '--json'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (result.exitCode != 0) return '';
    final raw = (result.stdout as String).trim();
    if (raw.isEmpty) return '';
    final parsed = jsonDecode(raw);
    final List databases;
    if (parsed is List) {
      databases = parsed;
    } else if (parsed is Map) {
      databases = (parsed['result'] ?? parsed['databases'] ?? []) as List;
    } else {
      return '';
    }
    final name = options.databaseName;
    for (final db in databases) {
      if (db is! Map) continue;
      final n = db['name'] ?? db['database_name'];
      if (n == name) {
        return '${db['uuid'] ?? db['id'] ?? db['database_id'] ?? ''}';
      }
    }
    return '';
  }

  Future<void> _ensureD1Database() async {
    var id = options.databaseId;
    if (id == null || id.isEmpty || id.startsWith('replace-')) {
      id = await _findD1DatabaseId();
      options.databaseId = id;
    }
    if (id.isEmpty) {
      final updateConfig = options.wranglerUpdateConfig == true;
      final useRemote = options.remoteBindingsForLocalDev == true;
      stdout.writeln('==> Create D1 database: ${options.databaseName}');
      await runInherit('npx', [
        'wrangler',
        'd1',
        'create',
        options.databaseName!,
        '--update-config=$updateConfig',
        '--binding=DB',
        '--use-remote=$useRemote',
      ], workingDirectory: paths.worker);
      options.databaseId = await _findD1DatabaseId();
    }
    if (options.databaseId == null || options.databaseId!.isEmpty) {
      throw CliException(
        'Could not resolve D1 database ID for ${options.databaseName}.',
      );
    }
  }

  Future<String> _findSecretsStoreId() async {
    final result = await runCapture(
      'npx',
      ['wrangler', 'secrets-store', 'store', 'list', '--remote', '--json'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    final raw = (result.stdout as String).trim();
    if (raw.isEmpty || result.exitCode != 0) return '';
    try {
      final stores = jsonDecode(raw);
      if (stores is! List) return '';
      for (final s in stores) {
        if (s is Map &&
            s['name'] == CloudflareSetupOptions.defaultSecretsStoreName) {
          return '${s['id'] ?? ''}';
        }
      }
    } catch (_) {}
    return '';
  }

  Future<void> _ensureSecretsStore() async {
    _secretsStoreId = await _findSecretsStoreId();
    if (_secretsStoreId == null || _secretsStoreId!.isEmpty) {
      stdout.writeln(
        '==> Create Secrets Store: '
        '${CloudflareSetupOptions.defaultSecretsStoreName}',
      );
      await runInherit('npx', [
        'wrangler',
        'secrets-store',
        'store',
        'create',
        CloudflareSetupOptions.defaultSecretsStoreName,
        '--remote',
      ], workingDirectory: paths.worker);
      _secretsStoreId = await _findSecretsStoreId();
    }
    if (_secretsStoreId == null || _secretsStoreId!.isEmpty) {
      throw CliException(
        'Could not resolve Secrets Store ID for '
        '${CloudflareSetupOptions.defaultSecretsStoreName}.',
      );
    }
  }

  Future<void> _ensureR2Bucket() async {
    final info = await runCapture(
      'npx',
      ['wrangler', 'r2', 'bucket', 'info', options.r2BucketName!],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (info.exitCode == 0) return;

    stdout.writeln('==> Create R2 bucket: ${options.r2BucketName}');
    final updateConfig = options.wranglerUpdateConfig == true;
    final useRemote = options.remoteBindingsForLocalDev == true;
    await runInherit('npx', [
      'wrangler',
      'r2',
      'bucket',
      'create',
      options.r2BucketName!,
      '--update-config=$updateConfig',
      '--binding=${options.r2Binding}',
      '--use-remote=$useRemote',
    ], workingDirectory: paths.worker);
  }

  Future<void> _waitForR2Bucket() async {
    for (var attempt = 1; attempt <= 30; attempt++) {
      final info = await runCapture(
        'npx',
        ['wrangler', 'r2', 'bucket', 'info', options.r2BucketName!],
        workingDirectory: paths.worker,
        throwOnError: false,
      );
      if (info.exitCode == 0) return;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw CliException(
      'R2 bucket is not visible to Wrangler yet: ${options.r2BucketName}',
    );
  }

  Future<void> _exportLocalProjectSeed() async {
    final tmp = File(p.join(Directory.systemTemp.path, 'fc-seed-$pid.sql'));
    _seedFile = tmp.path;
    await _runNodeScript(paths.exportProjectSeedScript, [
      options.databaseName ?? CloudflareSetupOptions.defaultD1DatabaseName,
      options.seedProjectId!,
      _seedFile!,
    ], localD1Persist: true);
  }

  Future<void> _runNodeScript(
    String script,
    List<String> args, {
    bool localD1Persist = false,
  }) async {
    if (!File(script).existsSync()) {
      throw CliException(
        'Helper script not found: $script\n'
        'This monorepo checkout is incomplete.',
      );
    }
    final env = Map<String, String>.from(Platform.environment);
    if (localD1Persist && options.localD1PersistTo != null) {
      env['LOCAL_D1_PERSIST_TO'] = options.localD1PersistTo!;
    }
    await runInherit(
      'node',
      [script, ...args],
      workingDirectory: paths.worker,
      environment: env,
    );
  }

  Future<String?> _accountId() async {
    final result = await runCapture(
      'npx',
      ['wrangler', 'whoami', '--json'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (result.exitCode != 0) return null;
    try {
      final data = jsonDecode((result.stdout as String).trim());
      if (data is Map && data['accounts'] is List) {
        final accounts = data['accounts'] as List;
        if (accounts.isNotEmpty && accounts.first is Map) {
          return '${(accounts.first as Map)['id'] ?? ''}';
        }
      }
      if (data is List && data.isNotEmpty && data.first is Map) {
        return '${(data.first as Map)['id'] ?? ''}';
      }
    } catch (_) {}
    return null;
  }

  Future<void> _updateWrangler() async {
    final raw = await File(paths.wranglerConfig).readAsString();
    final config = Map<String, dynamic>.from(parseJsonc(raw) as Map);
    final remote = options.remoteBindingsForLocalDev == true;
    final accountId = await _accountId();
    final secretsStoreId = _secretsStoreId ?? '';

    config['name'] = options.workerName;
    config['d1_databases'] = [
      {
        'binding': 'DB',
        'database_name': options.databaseName,
        'database_id': options.databaseId,
        'migrations_dir': 'migrations',
        'remote': remote,
      },
    ];

    if (secretsStoreId.isNotEmpty) {
      const secretNames = [
        'gemini_api_key',
        'openai_api_key',
        'claude_api_key',
        'cerebras_api_key',
        'smtp_password',
      ];
      config['secrets_store_secrets'] = [
        for (final name in secretNames)
          {
            'binding': name.toUpperCase(),
            'store_id': secretsStoreId,
            'secret_name': name,
          },
      ];
    }

    config['r2_buckets'] = [
      {
        'binding': options.r2Binding,
        'bucket_name': options.r2BucketName,
        'remote': remote,
      },
    ];

    final vars = Map<String, dynamic>.from(
      (config['vars'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final apiUrl = options.apiUrl;
    if (apiUrl != null && apiUrl.isNotEmpty) {
      vars['PUBLIC_BASE_URL'] = apiUrl.replaceAll(RegExp(r'/+$'), '');
    }
    vars['PUBLIC_FORM_ASSET_BASE_URL'] = (options.webAssetBaseUrl ?? '')
        .replaceAll(RegExp(r'/+$'), '');
    if (accountId != null && accountId.isNotEmpty) {
      vars['CF_ACCOUNT_ID'] = accountId;
    }
    if (secretsStoreId.isNotEmpty) {
      vars['CF_SECRETS_STORE_ID'] = secretsStoreId;
    }
    config['vars'] = vars;

    await File(paths.wranglerConfig).writeAsString(encodePrettyJson(config));
  }

  Future<String?> _deployWorker() async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      final result = await runTee('npx', [
        'wrangler',
        'deploy',
      ], workingDirectory: paths.worker);
      final match = RegExp(
        r'https://[^\s]+workers\.dev',
      ).allMatches(result.output);
      final url = match.isEmpty ? null : match.last.group(0);

      if (result.exitCode == 0) {
        return url;
      }

      if (result.output.contains('R2 bucket') &&
          result.output.contains('not found') &&
          attempt < 3) {
        stderr.writeln(
          'R2 bucket is not visible to Worker deploy yet; retrying...',
        );
        await _waitForR2Bucket();
        await Future<void>.delayed(Duration(seconds: attempt * 5));
        continue;
      }

      throw CliException(
        'Worker deploy failed (exit ${result.exitCode}).',
        exitCode: result.exitCode,
      );
    }
    return null;
  }

  Future<void> _ensurePagesProject(String project) async {
    await runCapture(
      paths.wranglerBin,
      ['pages', 'project', 'create', project, '--production-branch=main'],
      workingDirectory: paths.root,
      throwOnError: false,
    );
  }

  Future<void> _ensureCfApiToken() async {
    final list = await runCapture(
      'npx',
      ['wrangler', 'secret', 'list', '--json'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (list.exitCode == 0) {
      try {
        final secrets = jsonDecode((list.stdout as String).trim());
        if (secrets is List &&
            secrets.any((s) => s is Map && s['name'] == 'CF_API_TOKEN')) {
          return;
        }
      } catch (_) {}
    }
    stdout.writeln(
      '==> CF_API_TOKEN Worker Secret is required for Secrets Store management.',
    );
    stdout.writeln(
      '    Create an API Token at https://dash.cloudflare.com/profile/api-tokens',
    );
    stdout.writeln("    with 'Account > Secrets Store > Edit' permission.");
    await runInherit('npx', [
      'wrangler',
      'secret',
      'put',
      'CF_API_TOKEN',
    ], workingDirectory: paths.worker);
  }

  Future<void> _injectWebIndexApiUrl() async {
    final indexFile = p.join(paths.web, 'build', 'jaspr', 'index.html');
    var html = await File(indexFile).readAsString();
    final apiUrl = options.apiUrl!
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;');
    final meta = '<meta name="form-concierge-api-url" content="$apiUrl">';
    if (html.contains('name="form-concierge-api-url"')) {
      html = html.replaceFirst(
        RegExp(r'<meta name="form-concierge-api-url" content="[^"]*">'),
        meta,
      );
    } else {
      html = html.replaceFirstMapped(
        RegExp(r'(<meta name="viewport"[^>]*>)'),
        (m) => '${m[1]}\n  $meta',
      );
    }
    await File(indexFile).writeAsString(html);
  }

  void _printExplain() {
    stdout.writeln('''
Cloudflare setup creates/configures D1, R2, Worker, and Pages resources.

Required before running setup:

  cd worker
  npm install
  npx wrangler login
  npx wrangler whoami

Also install Dart, Flutter, Node.js/npm. Jaspr CLI is installed automatically
when missing.

Run setup:

  form_concierge setup cloudflare
  # or: dart run form_concierge_cli setup cloudflare

By default, wrangler dev uses local D1/R2 resources. To use remote bindings
for local dev too:

  form_concierge setup cloudflare --remote-bindings-for-local-dev

Resource names are prompted during interactive setup. For non-interactive setup,
pass --worker-name, --database-name, --r2-bucket-name, --admin-project, and
--web-project.

After setup, open the deployed admin Pages URL, create the first admin, and
create projects there.

Optional: seed an existing local project into remote D1:

  form_concierge setup cloudflare --list-local-projects
  form_concierge setup cloudflare --seed-project-id <project-id>
''');
  }
}
