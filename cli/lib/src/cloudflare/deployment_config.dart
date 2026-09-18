import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli_exception.dart';

/// Persisted resource identifiers and settings for a Cloudflare deployment.
class CloudflareDeploymentConfig {
  /// Creates CloudflareDeploymentConfig with the supplied values.
  CloudflareDeploymentConfig({
    this.schemaVersion = 1,
    this.provider = 'cloudflare',
    this.installedVersion,
    this.accountId,
    this.workerName,
    this.workerUrl,
    this.databaseBinding = 'DB',
    this.databaseName,
    this.databaseId,
    this.r2BucketName,
    this.secretsStoreName,
    this.secretsStoreId,
    this.adminPagesProject,
    this.adminPagesUrl,
    this.webPagesProject,
    this.webPagesUrl,
    this.publicFormAssetBaseUrl,
    this.remoteBindingsForLocalDev,
    this.deployAdminPages = true,
  });

  /// The version of the saved deployment configuration format.
  final int schemaVersion;

  /// The hosting provider associated with this deployment.
  final String provider;

  /// The Form Concierge release last installed in this deployment.
  String? installedVersion;

  /// The Cloudflare account that owns the deployment resources.
  String? accountId;

  /// The name of the API Worker.
  String? workerName;

  /// The public URL of the API Worker.
  String? workerUrl;

  /// The Worker binding name used for the D1 database.
  String databaseBinding;

  /// The name of the Cloudflare D1 database.
  String? databaseName;

  /// The identifier of the Cloudflare D1 database.
  String? databaseId;

  /// The name of the R2 bucket used for uploaded media.
  String? r2BucketName;

  /// The name of the Cloudflare Secrets Store used by the deployment.
  String? secretsStoreName;

  /// The identifier of the Cloudflare Secrets Store used by the deployment.
  String? secretsStoreId;

  /// The Cloudflare Pages project serving the administrator application.
  String? adminPagesProject;

  /// The public URL of the administrator Pages deployment.
  String? adminPagesUrl;

  /// The Cloudflare Pages project serving public form assets.
  String? webPagesProject;

  /// The public URL of the web Pages deployment.
  String? webPagesUrl;

  /// The base URL used to load public form assets.
  String? publicFormAssetBaseUrl;

  /// Whether local development should use remote bindings, if configured.
  bool? remoteBindingsForLocalDev;

  /// Whether deployment includes the administrator Pages application.
  bool deployAdminPages;

  /// Whether any deployable Cloudflare resources are recorded in this configuration.
  bool get hasResources =>
      workerName != null ||
      databaseName != null ||
      r2BucketName != null ||
      secretsStoreId != null ||
      adminPagesProject != null ||
      webPagesProject != null;

  /// Decodes CloudflareDeploymentConfig from its JSON representation.
  static CloudflareDeploymentConfig fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 1) {
      throw CliException(
        'Unsupported deployment.json schemaVersion: $schemaVersion',
      );
    }
    if (json['provider'] != 'cloudflare') {
      throw CliException('deployment.json provider must be "cloudflare".');
    }

    final cloudflare = _map(json['cloudflare']);
    final worker = _map(cloudflare['worker']);
    final d1 = _map(cloudflare['d1']);
    final r2 = _map(cloudflare['r2']);
    final secretsStore = _map(cloudflare['secretsStore']);
    final pages = _map(cloudflare['pages']);
    final admin = _map(pages['admin']);
    final web = _map(pages['web']);
    final configuration = _map(json['configuration']);

    return CloudflareDeploymentConfig(
      installedVersion: _string(json['installedVersion']),
      accountId: _string(cloudflare['accountId']),
      workerName: _string(worker['name']),
      workerUrl: _string(worker['url']),
      databaseBinding: _string(d1['binding']) ?? 'DB',
      databaseName: _string(d1['databaseName']),
      databaseId: _string(d1['databaseId']),
      r2BucketName: _string(r2['bucketName']),
      secretsStoreName: _string(secretsStore['name']),
      secretsStoreId: _string(secretsStore['storeId']),
      adminPagesProject: _string(admin['projectName']),
      adminPagesUrl: _string(admin['url']),
      webPagesProject: _string(web['projectName']),
      webPagesUrl: _string(web['url']),
      publicFormAssetBaseUrl: _string(configuration['publicFormAssetBaseUrl']),
      remoteBindingsForLocalDev:
          configuration['remoteBindingsForLocalDev'] as bool?,
      deployAdminPages: configuration['deployAdminPages'] as bool? ?? true,
    );
  }

  /// Returns the JSON representation used for local persistence.
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'provider': provider,
    if (installedVersion != null) 'installedVersion': installedVersion,
    'cloudflare': {
      if (accountId != null) 'accountId': accountId,
      'worker': {
        if (workerName != null) 'name': workerName,
        if (workerUrl != null) 'url': workerUrl,
      },
      'd1': {
        'binding': databaseBinding,
        if (databaseName != null) 'databaseName': databaseName,
        if (databaseId != null) 'databaseId': databaseId,
      },
      'r2': {
        'binding': 'MEDIA_BUCKET',
        if (r2BucketName != null) 'bucketName': r2BucketName,
      },
      'secretsStore': {
        if (secretsStoreName != null) 'name': secretsStoreName,
        if (secretsStoreId != null) 'storeId': secretsStoreId,
      },
      'pages': {
        'admin': {
          if (adminPagesProject != null) 'projectName': adminPagesProject,
          if (adminPagesUrl != null) 'url': adminPagesUrl,
        },
        'web': {
          if (webPagesProject != null) 'projectName': webPagesProject,
          if (webPagesUrl != null) 'url': webPagesUrl,
        },
      },
    },
    'configuration': {
      if (publicFormAssetBaseUrl != null)
        'publicFormAssetBaseUrl': publicFormAssetBaseUrl,
      if (remoteBindingsForLocalDev != null)
        'remoteBindingsForLocalDev': remoteBindingsForLocalDev,
      'deployAdminPages': deployAdminPages,
    },
  };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}

/// Loads and saves a named deployment's local configuration file.
class CloudflareDeploymentStore {
  CloudflareDeploymentStore._(this.name, this.path);

  /// The name identifying this saved deployment.
  final String name;

  /// The path to this deployment's configuration file.
  final String path;

  /// Selects a saved deployment or prepares a new one according to the supplied options.
  static Future<CloudflareDeploymentStore> select({
    String? requestedName,
    required bool allowCreate,
    String? homeDirectory,
  }) async {
    final root = p.join(
      homeDirectory ??
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          Directory.current.path,
      '.form_concierge',
      'deployments',
    );
    if (requestedName != null) {
      _validateName(requestedName);
      final store = CloudflareDeploymentStore._(
        requestedName,
        p.join(root, '$requestedName.json'),
      );
      if (!allowCreate && !await File(store.path).exists()) {
        throw CliException(
          'Deployment "$requestedName" not found at ${store.path}.',
        );
      }
      return store;
    }

    final directory = Directory(root);
    final names = await directory.exists()
        ? await directory
              .list()
              .where(
                (entry) => entry is File && p.extension(entry.path) == '.json',
              )
              .map((entry) => p.basenameWithoutExtension(entry.path))
              .toList()
        : <String>[];
    names.sort();

    if (names.isEmpty) {
      if (!allowCreate) {
        throw CliException(
          'No deployments found in $root. Run setup first or pass '
          '--deployment <name>.',
        );
      }
      return CloudflareDeploymentStore._(
        'default',
        p.join(root, 'default.json'),
      );
    }
    if (names.length == 1) {
      return CloudflareDeploymentStore._(
        names.single,
        p.join(root, '${names.single}.json'),
      );
    }
    if (!stdin.hasTerminal) {
      throw CliException(
        'Multiple deployments found: ${names.join(', ')}. Pass '
        '--deployment <name>.',
      );
    }

    stderr.writeln('Select deployment:');
    for (var index = 0; index < names.length; index++) {
      stderr.writeln('  ${index + 1}. ${names[index]}');
    }
    while (true) {
      stderr.write('> ');
      final input = stdin.readLineSync();
      if (input == null) {
        throw CliException('No deployment selected. Pass --deployment <name>.');
      }
      final selection = int.tryParse(input.trim());
      if (selection != null && selection >= 1 && selection <= names.length) {
        final name = names[selection - 1];
        return CloudflareDeploymentStore._(name, p.join(root, '$name.json'));
      }
      stderr.writeln('Enter a number from 1 to ${names.length}.');
    }
  }

  static void _validateName(String name) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(name)) {
      throw CliException(
        'Invalid deployment name "$name". Use letters, numbers, hyphens, '
        'and underscores.',
      );
    }
  }

  /// Reads the saved deployment configuration, or returns null when no file exists.
  Future<CloudflareDeploymentConfig?> load() async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final value = jsonDecode(await file.readAsString());
      if (value is! Map) throw const FormatException('root must be an object');
      return CloudflareDeploymentConfig.fromJson(
        Map<String, dynamic>.from(value),
      );
    } on CliException {
      rethrow;
    } catch (error) {
      throw CliException('Invalid $path: $error');
    }
  }

  /// Writes the deployment configuration to this store's file.
  Future<void> save(CloudflareDeploymentConfig config) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final temporary = File('$path.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await temporary.writeAsString('${encoder.convert(config.toJson())}\n');
    await temporary.rename(path);
  }

  /// Removes this store's configuration file when it exists.
  Future<void> delete() async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    var directory = file.parent;
    while (await directory.exists() && await directory.list().isEmpty) {
      await directory.delete();
      if (p.basename(directory.path) == '.form_concierge') break;
      directory = directory.parent;
    }
  }
}
