import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli_exception.dart';

class CloudflareDeploymentConfig {
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
    this.r2Binding = 'MEDIA_BUCKET',
    this.r2BucketName,
    this.secretsStoreName,
    this.secretsStoreId,
    this.adminPagesProject,
    this.adminPagesUrl,
    this.webPagesProject,
    this.webPagesUrl,
    this.publicFormAssetBaseUrl,
    this.remoteBindingsForLocalDev,
  });

  final int schemaVersion;
  final String provider;
  String? installedVersion;
  String? accountId;
  String? workerName;
  String? workerUrl;
  String databaseBinding;
  String? databaseName;
  String? databaseId;
  String r2Binding;
  String? r2BucketName;
  String? secretsStoreName;
  String? secretsStoreId;
  String? adminPagesProject;
  String? adminPagesUrl;
  String? webPagesProject;
  String? webPagesUrl;
  String? publicFormAssetBaseUrl;
  bool? remoteBindingsForLocalDev;

  bool get hasResources =>
      workerName != null ||
      databaseName != null ||
      r2BucketName != null ||
      secretsStoreId != null ||
      adminPagesProject != null ||
      webPagesProject != null;

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
      r2Binding: _string(r2['binding']) ?? 'MEDIA_BUCKET',
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
    );
  }

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
        'binding': r2Binding,
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
    },
  };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}

class CloudflareDeploymentStore {
  CloudflareDeploymentStore(String root)
    : path = p.join(root, '.form_concierge', 'deployment.json');

  final String path;

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

  Future<void> save(CloudflareDeploymentConfig config) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final temporary = File('$path.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await temporary.writeAsString('${encoder.convert(config.toJson())}\n');
    await temporary.rename(path);
  }

  Future<void> delete() async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    final directory = file.parent;
    if (await directory.exists() && await directory.list().isEmpty) {
      await directory.delete();
    }
  }
}
