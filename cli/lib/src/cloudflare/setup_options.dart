/// Options for `setup cloudflare`.
class CloudflareSetupOptions {
  /// Creates CloudflareSetupOptions with the supplied values.
  CloudflareSetupOptions({
    this.preflightOnly = false,
    this.explain = false,
    this.listLocalProjects = false,
    this.seedProjectId,
    this.databaseId,
    this.databaseName,
    this.workerName,
    this.r2BucketName,
    this.apiUrl,
    this.adminProject,
    this.deployAdminPages,
    this.webProject,
    this.webAssetBaseUrl,
    this.localD1PersistTo,
    this.remoteBindingsForLocalDev,
    this.wranglerUpdateConfig,
    this.targetVersion,
    this.force = false,
    this.hasConfigurationOverrides = false,
  });

  /// Whether to check prerequisites without deploying resources.
  final bool preflightOnly;

  /// Whether to describe the deployment plan without applying it.
  final bool explain;

  /// Whether to list locally available projects for seeding.
  final bool listLocalProjects;

  /// The local project identifier to copy into the deployed database, if supplied.
  String? seedProjectId;

  /// The identifier of the Cloudflare D1 database.
  String? databaseId;

  /// The name of the Cloudflare D1 database.
  String? databaseName;

  /// The name of the API Worker.
  String? workerName;

  /// The name of the R2 bucket used for uploaded media.
  String? r2BucketName;

  /// The public base URL of the deployed API.
  String? apiUrl;

  /// The Cloudflare Pages project name for the administrator application.
  String? adminProject;

  /// `null` = use saved setting / default true.
  bool? deployAdminPages;

  /// The Cloudflare Pages project name for the public web application.
  String? webProject;

  /// The base URL from which public form assets are served.
  String? webAssetBaseUrl;

  /// The local directory holding D1 state used for project export.
  String? localD1PersistTo;

  /// Whether local development uses remote bindings. Null prompts or uses the default.
  bool? remoteBindingsForLocalDev;

  /// Whether Wrangler may update configuration. Null prompts or defaults to allowing updates.
  bool? wranglerUpdateConfig;

  /// The release version to install, when explicitly selected.
  String? targetVersion;

  /// Whether to redeploy components even when their versions are unchanged.
  final bool force;

  /// Whether the invocation explicitly overrides deployment settings.
  final bool hasConfigurationOverrides;

  /// The default worker name used for a new deployment.
  static const defaultWorkerName = 'form-concierge-api';

  /// The default D1 database name used for a new deployment.
  static const defaultD1DatabaseName = 'form_concierge';

  /// The default admin project used for a new deployment.
  static const defaultAdminProject = 'form-concierge-admin';

  /// The default web project used for a new deployment.
  static const defaultWebProject = 'form-concierge-web';

  /// The default R2 bucket name used for a new deployment.
  static const defaultR2BucketName = 'form-concierge-media';

  /// Prefer a product-specific name so setup does not hijack an unrelated store.
  static const defaultSecretsStoreName = 'form-concierge';
}
