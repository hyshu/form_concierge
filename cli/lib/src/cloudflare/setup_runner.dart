import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli_exception.dart';
import '../monorepo.dart';
import '../tools.dart';
import 'deployment_plan.dart';
import 'jsonc.dart';
import 'deployment_config.dart';
import 'secret_names.dart';
import 'setup_options.dart';

/// Orchestrates Cloudflare D1 / R2 / Worker / Pages provisioning.
class CloudflareSetupRunner {
  CloudflareSetupRunner({
    required this.paths,
    required this.options,
    this.invocationDir,
    this.deploymentName,
    this.allowCreateDeployment = true,
  });

  final MonorepoPaths paths;
  final CloudflareSetupOptions options;
  final String? invocationDir;
  final String? deploymentName;
  final bool allowCreateDeployment;

  List<String> _jasprCmd = const ['jaspr'];
  String? _seedFile;
  String? _secretsStoreId;
  final Set<String> _legacySecretNames = {};
  late CloudflareDeploymentStore _deploymentStore;
  CloudflareDeploymentConfig _deployment = CloudflareDeploymentConfig();

  Future<int> run() async {
    if (options.explain) {
      _printExplain();
      return 0;
    }

    _resolveLocalD1PersistPath();

    if (options.listLocalProjects) {
      await _checkCommands();
      await _ensureWranglerConfigFile();
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

      await _loadDeployment();

      var deploymentPlan = CloudflareDeploymentPlan.resolve(
        installedVersion: _deployment.installedVersion,
        targetVersion: options.targetVersion!,
        initialSetup: allowCreateDeployment,
        force: options.force,
        hasConfigurationOverrides:
            options.hasConfigurationOverrides ||
            _deploymentConfigurationIsIncomplete(),
      );

      await _selectRemoteBindingsForLocalDev();
      await _selectResourceNames();

      options.webAssetBaseUrl ??= 'https://${options.webProject}.pages.dev';
      // Always rewrite worker/wrangler.jsonc ourselves after create.
      // Wrangler --update-config can append a second "DB" binding and break config.
      options.wranglerUpdateConfig = true;

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

      // Secrets Store first: accounts often allow only one store, and create can
      // fail after D1/R2 were already provisioned. Resolve/reuse before those.
      // Worker deploy requires each secrets_store_secrets binding to already exist.
      final secretsStoreCreated = await _ensureSecretsStore();
      final storeSecretsRestored = await _ensureSecretsStoreSecrets();
      final d1Created = await _ensureD1Database();
      final r2Created = await _ensureR2Bucket();
      await _waitForR2Bucket();
      await _saveDeployment();
      final workerSecretRestored = await _ensureCfApiToken();

      final recoveryComponents = <CloudflareDeploymentComponent>{
        if (secretsStoreCreated || storeSecretsRestored || workerSecretRestored)
          CloudflareDeploymentComponent.secrets,
        if (d1Created || storeSecretsRestored)
          CloudflareDeploymentComponent.d1Migrations,
        if (secretsStoreCreated ||
            storeSecretsRestored ||
            d1Created ||
            r2Created)
          CloudflareDeploymentComponent.worker,
      };
      deploymentPlan = deploymentPlan.withAdditionalComponents(
        recoveryComponents,
        'required Cloudflare resource recreated',
      );
      _printDeploymentPlan(deploymentPlan);

      final deployWorker = deploymentPlan.includes(
        CloudflareDeploymentComponent.worker,
      );
      final applyD1Migrations =
          options.seedProjectId != null ||
          deploymentPlan.includes(CloudflareDeploymentComponent.d1Migrations);

      if (deployWorker) {
        stdout.writeln('==> Configure Worker');
        await _updateWrangler();

        stdout.writeln('==> Worker typecheck');
        // Validate source against bindings generated from this deployment's
        // wrangler.jsonc. The checked-in WorkerEnv intentionally excludes
        // temporary legacy migration bindings.
        await runInherit('npm', [
          'run',
          'typecheck:deployment',
        ], workingDirectory: paths.worker);
        await runInherit('npm', [
          'run',
          'test:typecheck',
        ], workingDirectory: paths.worker);
      } else {
        stdout.writeln('==> Worker: unchanged, deploy skipped');
      }

      if (applyD1Migrations) {
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
      } else {
        stdout.writeln('==> D1 migrations: unchanged, skipped');
      }

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

      if (deployWorker) {
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
      }

      final deployAdmin = deploymentPlan.includes(
        CloudflareDeploymentComponent.adminPages,
      );
      if (deployAdmin && options.deployAdminPages == true) {
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
      } else if (options.deployAdminPages != true) {
        stdout.writeln('==> Admin Pages: skipped');
      } else {
        stdout.writeln('==> Admin Pages: unchanged, deploy skipped');
      }

      final deployWeb = deploymentPlan.includes(
        CloudflareDeploymentComponent.webPages,
      );
      if (deployWeb) {
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
      } else {
        stdout.writeln('==> Public assets Pages: unchanged, deploy skipped');
      }

      _deployment.installedVersion = options.targetVersion;
      await _saveDeployment();

      stdout.writeln('==> Done');
      stdout.writeln('API: ${options.apiUrl}');
      if (options.deployAdminPages == true) {
        stdout.writeln('Admin: https://${options.adminProject}.pages.dev');
      }
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

  void _printDeploymentPlan(CloudflareDeploymentPlan plan) {
    stdout.writeln('==> Deployment plan: ${plan.reason}');
    if (plan.components.isEmpty) {
      stdout.writeln('    No version-driven deployments required.');
      return;
    }
    stdout.writeln(
      '    ${plan.components.map((component) => component.label).join(', ')}',
    );
  }

  bool _deploymentConfigurationIsIncomplete() {
    return _deployment.workerName == null ||
        _deployment.workerUrl == null ||
        _deployment.databaseName == null ||
        _deployment.databaseId == null ||
        _deployment.r2BucketName == null ||
        _deployment.webPagesProject == null ||
        (_deployment.deployAdminPages && _deployment.adminPagesProject == null);
  }

  Future<void> _loadDeployment() async {
    _deploymentStore = await CloudflareDeploymentStore.select(
      requestedName: deploymentName,
      allowCreate: allowCreateDeployment,
    );
    stdout.writeln('==> Deployment: ${_deploymentStore.name}');
    _deployment = await _deploymentStore.load() ?? CloudflareDeploymentConfig();
    options.workerName ??= _deployment.workerName;
    options.apiUrl ??= _deployment.workerUrl;
    options.databaseName ??= _deployment.databaseName;
    options.databaseId ??= _deployment.databaseId;
    options.r2BucketName ??= _deployment.r2BucketName;
    options.adminProject ??= _deployment.adminPagesProject;
    options.deployAdminPages ??= _deployment.deployAdminPages;
    options.webProject ??= _deployment.webPagesProject;
    options.webAssetBaseUrl ??= _deployment.publicFormAssetBaseUrl;
    options.remoteBindingsForLocalDev ??= _deployment.remoteBindingsForLocalDev;
    _secretsStoreId = _deployment.secretsStoreId;
  }

  Future<void> _saveDeployment() async {
    _deployment
      ..accountId = await _accountId()
      ..workerName = options.workerName
      ..workerUrl = options.apiUrl
      ..databaseBinding = 'DB'
      ..databaseName = options.databaseName
      ..databaseId = options.databaseId
      ..r2BucketName = options.r2BucketName
      ..secretsStoreName = CloudflareSetupOptions.defaultSecretsStoreName
      ..secretsStoreId = _secretsStoreId
      ..deployAdminPages = options.deployAdminPages ?? true
      ..adminPagesProject = options.deployAdminPages == true
          ? options.adminProject
          : null
      ..adminPagesUrl =
          options.deployAdminPages != true || options.adminProject == null
          ? null
          : 'https://${options.adminProject}.pages.dev'
      ..webPagesProject = options.webProject
      ..webPagesUrl = options.webProject == null
          ? null
          : 'https://${options.webProject}.pages.dev'
      ..publicFormAssetBaseUrl = options.webAssetBaseUrl
      ..remoteBindingsForLocalDev = options.remoteBindingsForLocalDev;
    await _deploymentStore.save(_deployment);
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
    await _ensureWranglerConfigFile();
    await _installWorkerDependencies();
    await _ensureWranglerAuth();
    await _ensureJaspr();
  }

  /// Local `wrangler.jsonc` is gitignored; bootstrap from the committed example.
  Future<void> _ensureWranglerConfigFile() async {
    final config = File(paths.wranglerConfig);
    if (config.existsSync()) {
      return;
    }
    final example = File(paths.wranglerConfigExample);
    if (!example.existsSync()) {
      throw CliException(
        'Missing ${paths.wranglerConfigExample}.\n'
        'This monorepo checkout is incomplete.',
      );
    }
    await example.copy(config.path);
    stdout.writeln(
      '==> Created worker/wrangler.jsonc from wrangler.jsonc.example',
    );
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
    // Plain `whoami` exits 0 even when logged out. Prefer --json and check body.
    final result = await runCapture(
      'npx',
      ['wrangler', 'whoami', '--json'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    final out = (result.stdout as String).trim();
    final err = (result.stderr as String).trim();
    final detail = [
      if (out.isNotEmpty) out,
      if (err.isNotEmpty) err,
    ].join('\n');

    if (_wranglerWhoamiLoggedIn(out)) {
      return;
    }

    final lower = detail.toLowerCase();
    final looksLikeConfig =
        lower.contains('wrangler.toml') ||
        lower.contains('wrangler.json') ||
        lower.contains('configuration file') ||
        lower.contains('multiple') && lower.contains('binding') ||
        (lower.contains('invalid') && lower.contains('config'));
    if (looksLikeConfig) {
      if (detail.isNotEmpty) {
        stderr.writeln(detail);
      }
      throw CliException(
        'Wrangler configuration error in worker/wrangler.jsonc.\n'
        'Fix the config, then re-run setup.',
      );
    }

    throw CliException('''
Wrangler is not logged in to Cloudflare.

  npx wrangler login

Then re-run setup.
''');
  }

  /// True when `wrangler whoami --json` reports an authenticated session.
  bool _wranglerWhoamiLoggedIn(String stdout) {
    final raw = stdout.trim();
    if (raw.isEmpty) return false;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return false;
      if (data['loggedIn'] == false) return false;
      if (data['loggedIn'] == true) return true;
      // Older shapes may omit loggedIn but include accounts when authenticated.
      final accounts = data['accounts'];
      return accounts is List && accounts.isNotEmpty;
    } catch (_) {
      return false;
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
    options.deployAdminPages ??= true;
    if (options.deployAdminPages == true) {
      options.adminProject = await _resolveName(
        options.adminProject,
        'Admin Pages project',
        CloudflareSetupOptions.defaultAdminProject,
      );
    } else {
      options.adminProject = null;
    }
    options.webProject = await _resolveName(
      options.webProject,
      'Public assets Pages project',
      CloudflareSetupOptions.defaultWebProject,
    );

    final missing = [
      options.workerName,
      options.databaseName,
      options.r2BucketName,
      if (options.deployAdminPages == true) options.adminProject,
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
    ${options.deployAdminPages == true ? '--admin-project <pages-project> \\\n    ' : ''}--web-project <pages-project>
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
    if (result.exitCode != 0) {
      throw CliException(
        'Could not list D1 databases. Refusing to create a possible duplicate.',
      );
    }
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

  Future<bool> _ensureD1Database() async {
    var id = await _findD1DatabaseId();
    options.databaseId = id;
    if (id.isEmpty) {
      // Never let wrangler append bindings: an existing DB entry becomes a
      // duplicate "DB" binding and breaks whoami/deploy. _updateWrangler owns config.
      stdout.writeln('==> Create D1 database: ${options.databaseName}');
      await runInherit('npx', [
        'wrangler',
        'd1',
        'create',
        options.databaseName!,
        '--update-config=false',
      ], workingDirectory: paths.worker);
      options.databaseId = await _findD1DatabaseId();
      id = options.databaseId!;
    }
    if (options.databaseId == null || options.databaseId!.isEmpty) {
      throw CliException(
        'Could not resolve D1 database ID for ${options.databaseName}.',
      );
    }
    return id.isNotEmpty && id != _deployment.databaseId;
  }

  Future<String> _findSecretsStoreId() async {
    // wrangler secrets-store store list has no --json (as of wrangler 4.103).
    final result = await runCapture(
      'npx',
      ['wrangler', 'secrets-store', 'store', 'list', '--remote'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    final text = '${result.stdout}\n${result.stderr}';
    final defaultName = CloudflareSetupOptions.defaultSecretsStoreName;

    // Table row: │ name │ 32-char hex id │ ...
    final named = RegExp(
      '│\\s*${RegExp.escape(defaultName)}\\s*│\\s*([a-f0-9]{32})\\s*│',
      caseSensitive: false,
    ).firstMatch(text);
    if (named != null) {
      return named.group(1)!;
    }

    // Prefer any existing remote store (accounts often allow only one).
    // Do not fall back to wrangler.jsonc — that can reuse a deleted store id.
    for (final m in RegExp(
      r'│\s*([A-Za-z0-9_-]+)\s*│\s*([a-f0-9]{32})\s*│',
    ).allMatches(text)) {
      final name = m.group(1)!;
      if (name.toLowerCase() == 'name') continue;
      return m.group(2)!;
    }

    return '';
  }

  Future<bool> _ensureSecretsStore() async {
    _secretsStoreId = await _findSecretsStoreId();
    if (_secretsStoreId != null && _secretsStoreId!.isNotEmpty) {
      stdout.writeln('==> Secrets Store: using existing');
      return _secretsStoreId != _deployment.secretsStoreId;
    }

    final name = CloudflareSetupOptions.defaultSecretsStoreName;
    stdout.writeln('==> Create Secrets Store: $name');
    final create = await runCapture(
      'npx',
      ['wrangler', 'secrets-store', 'store', 'create', name, '--remote'],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    _secretsStoreId = await _findSecretsStoreId();
    if (_secretsStoreId != null && _secretsStoreId!.isNotEmpty) {
      return true;
    }

    final detail = [
      if ((create.stdout as String).trim().isNotEmpty)
        (create.stdout as String).trim(),
      if ((create.stderr as String).trim().isNotEmpty)
        (create.stderr as String).trim(),
    ].join('\n');
    if (detail.isNotEmpty) {
      stderr.writeln(detail);
    }
    throw CliException(
      'Could not create or find a Secrets Store.\n'
      'List with: npx wrangler secrets-store store list --remote',
    );
  }

  /// Deploy fails if secrets_store_secrets bindings point at missing secrets.
  Future<bool> _ensureSecretsStoreSecrets() async {
    final storeId = _secretsStoreId;
    if (storeId == null || storeId.isEmpty) {
      throw CliException('Secrets Store id is missing.');
    }

    final existing = await _listSecretsStoreSecretNames(storeId);
    if (!allowCreateDeployment && _isLegacySecretMigrationVersion()) {
      _legacySecretNames.addAll(
        formConciergeSecretNames.where(existing.contains),
      );
    }
    final names = formConciergeSecretNames
        .map(formConciergeSecretName)
        .toList();
    final missing = names.where((n) => !existing.contains(n)).toList();
    if (missing.isEmpty) {
      stdout.writeln('==> Secrets Store secrets: all present');
      return _legacySecretNames.isNotEmpty;
    }

    stdout.writeln(
      '==> Secrets Store secrets: create ${missing.length} placeholder(s)',
    );
    stdout.writeln(
      '    (AI/SMTP/Turnstile values can be set later in admin; placeholders unlock deploy)',
    );
    for (final name in missing) {
      final result = await runCapture(
        'npx',
        [
          'wrangler',
          'secrets-store',
          'secret',
          'create',
          storeId,
          '--name',
          name,
          '--scopes',
          'workers',
          '--remote',
          '--value',
          'placeholder',
          '--comment',
          'form_concierge setup placeholder',
        ],
        workingDirectory: paths.worker,
        throwOnError: false,
      );
      if (result.exitCode == 0) {
        stdout.writeln('    + $name');
        continue;
      }
      final detail = [
        if ((result.stdout as String).trim().isNotEmpty)
          (result.stdout as String).trim(),
        if ((result.stderr as String).trim().isNotEmpty)
          (result.stderr as String).trim(),
      ].join('\n');
      final lower = detail.toLowerCase();
      if (lower.contains('already') || lower.contains('exist')) {
        stdout.writeln('    = $name (already exists)');
        continue;
      }
      if (detail.isNotEmpty) {
        stderr.writeln(detail);
      }
      throw CliException(
        'Failed to create Secrets Store secret "$name".\n'
        'Create it with:\n'
        '  npx wrangler secrets-store secret create $storeId '
        '--name $name --scopes workers --remote',
      );
    }
    return true;
  }

  Future<Set<String>> _listSecretsStoreSecretNames(String storeId) async {
    final result = await runCapture(
      'npx',
      [
        'wrangler',
        'secrets-store',
        'secret',
        'list',
        storeId,
        '--per-page',
        '100',
        '--remote',
      ],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    final text = '${result.stdout}\n${result.stderr}';
    final found = <String>{};
    final knownNames = {
      ...formConciergeSecretNames,
      ...formConciergeSecretNames.map(formConciergeSecretName),
    };
    for (final name in knownNames) {
      if (RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(text)) {
        found.add(name);
      }
    }
    return found;
  }

  bool _isLegacySecretMigrationVersion() {
    final version = _deployment.installedVersion;
    if (version == null) return true;
    final parts = version.split('.').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) return true;
    final [major, minor, patch] = parts.cast<int>();
    return major == 0 && (minor < 2 || (minor == 2 && patch <= 1));
  }

  Future<bool> _ensureR2Bucket() async {
    final info = await runCapture(
      'npx',
      ['wrangler', 'r2', 'bucket', 'info', options.r2BucketName!],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (info.exitCode == 0) return false;

    stdout.writeln('==> Create R2 bucket: ${options.r2BucketName}');
    // Same as D1: do not append bindings; _updateWrangler rewrites config.
    await runInherit('npx', [
      'wrangler',
      'r2',
      'bucket',
      'create',
      options.r2BucketName!,
      '--update-config=false',
    ], workingDirectory: paths.worker);
    return true;
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
    config['ratelimits'] = [
      {
        'name': 'LOGIN_RATE_LIMITER',
        'namespace_id': '1001',
        'simple': {'limit': 20, 'period': 60},
      },
      {
        'name': 'ANON_CREATE_RATE_LIMITER',
        'namespace_id': '1002',
        'simple': {'limit': 30, 'period': 60},
      },
      {
        'name': 'PUBLIC_WRITE_RATE_LIMITER',
        'namespace_id': '1003',
        'simple': {'limit': 120, 'period': 60},
      },
    ];

    if (secretsStoreId.isNotEmpty) {
      config['secrets_store_secrets'] = [
        for (final name in formConciergeSecretNames)
          {
            'binding': formConciergeSecretBinding(name),
            'store_id': secretsStoreId,
            'secret_name': formConciergeSecretName(name),
          },
        for (final name in _legacySecretNames)
          {
            'binding': formConciergeLegacySecretBinding(name),
            'store_id': secretsStoreId,
            'secret_name': name,
          },
      ];
    }

    config['r2_buckets'] = [
      {
        'binding': 'MEDIA_BUCKET',
        'bucket_name': options.r2BucketName,
        'remote': remote,
      },
    ];
    config['triggers'] = {
      'crons': ['*/15 * * * *'],
    };

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
    const quotaDefaults = {
      'QUOTA_RESPONSES_PER_ACCOUNT_DAY': '100',
      'QUOTA_RESPONSES_PER_IP_DAY': '500',
      'QUOTA_RESPONSES_PER_SURVEY_DAY': '10000',
      'QUOTA_UPLOAD_BYTES_PER_ACCOUNT_DAY': '104857600',
      'QUOTA_STORED_BYTES_PER_ACCOUNT': '262144000',
      'QUOTA_AI_GENERATIONS_PER_ACCOUNT_DAY': '20',
      'QUOTA_AI_GENERATIONS_PER_SURVEY_DAY': '500',
      'QUOTA_EMAILS_PER_SURVEY_DAY': '1000',
    };
    for (final entry in quotaDefaults.entries) {
      vars.putIfAbsent(entry.key, () => entry.value);
    }
    // Turnstile keys live in Secrets Store (admin-managed), not plain vars.
    vars.remove('TURNSTILE_SITE_KEY');
    vars.remove('TURNSTILE_SECRET_KEY');
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

  Future<bool> _ensureCfApiToken() async {
    final list = await runCapture(
      'npx',
      [
        'wrangler',
        'secret',
        'list',
        '--format',
        'json',
        '--name',
        options.workerName!,
      ],
      workingDirectory: paths.worker,
      throwOnError: false,
    );
    if (list.exitCode == 0) {
      try {
        final secrets = jsonDecode((list.stdout as String).trim());
        if (secrets is List &&
            secrets.any((s) => s is Map && s['name'] == 'CF_API_TOKEN')) {
          return false;
        }
      } catch (_) {}
    }
    const apiTokensUrl = 'https://dash.cloudflare.com/profile/api-tokens';
    stdout.writeln(
      '==> Worker secret CF_API_TOKEN (Cloudflare API Token, not the store id)',
    );
    final opened = await openInBrowser(apiTokensUrl);
    if (opened) {
      stdout.writeln('    Opened $apiTokensUrl in your browser.');
    } else {
      stdout.writeln('    Open $apiTokensUrl in your browser.');
    }
    stdout.writeln('    Create Token → custom token with:');
    stdout.writeln('      Account → Secrets Store → Edit');
    stdout.writeln('    Paste that token below (not the Secrets Store id).');
    await runInherit('npx', [
      'wrangler',
      'secret',
      'put',
      'CF_API_TOKEN',
      '--name',
      options.workerName!,
    ], workingDirectory: paths.worker);
    return true;
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

  npx wrangler login

Also install Dart, Flutter, Node.js/npm (and run npm install in worker/).
Jaspr CLI is installed automatically when missing. Setup aborts early if you
are not logged in; log in, then re-run setup.

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
