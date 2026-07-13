/// Options for `setup cloudflare`.
class CloudflareSetupOptions {
  CloudflareSetupOptions({
    this.preflightOnly = false,
    this.explain = false,
    this.listLocalProjects = false,
    this.seedProjectId,
    this.databaseId,
    this.databaseName,
    this.workerName,
    this.r2BucketName,
    this.r2Binding = 'MEDIA_BUCKET',
    this.apiUrl,
    this.adminProject,
    this.deployAdminPages,
    this.webProject,
    this.webAssetBaseUrl,
    this.localD1PersistTo,
    this.remoteBindingsForLocalDev,
    this.wranglerUpdateConfig,
    this.targetVersion,
  });

  final bool preflightOnly;
  final bool explain;
  final bool listLocalProjects;
  String? seedProjectId;
  String? databaseId;
  String? databaseName;
  String? workerName;
  String? r2BucketName;
  String r2Binding;
  String? apiUrl;
  String? adminProject;

  /// `null` = use saved setting / default true.
  bool? deployAdminPages;
  String? webProject;
  String? webAssetBaseUrl;
  String? localD1PersistTo;

  /// `null` = prompt / default; `true` = remote; `false` = local.
  bool? remoteBindingsForLocalDev;

  /// `null` = prompt / default yes; true/false explicit.
  bool? wranglerUpdateConfig;
  String? targetVersion;

  static const defaultWorkerName = 'form-concierge-api';
  static const defaultD1DatabaseName = 'form_concierge';
  static const defaultAdminProject = 'form-concierge-admin';
  static const defaultWebProject = 'form-concierge-web';
  static const defaultR2BucketName = 'form-concierge-media';

  /// Prefer a product-specific name so setup does not hijack an unrelated store.
  static const defaultSecretsStoreName = 'form-concierge';
}
