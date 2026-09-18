/// A resource or application that can be deployed independently.
enum CloudflareDeploymentComponent {
  /// Secrets Store resources and Worker secret bindings.
  secrets('Secrets'),

  /// Schema migrations for the D1 database.
  d1Migrations('D1 migrations'),

  /// The API Worker deployment.
  worker('Worker'),

  /// The administrator application on Cloudflare Pages.
  adminPages('Admin Pages'),

  /// Public form assets on Cloudflare Pages.
  webPages('Web Pages');

  /// Creates CloudflareDeploymentComponent with the supplied values.
  const CloudflareDeploymentComponent(this.label);

  /// A human-readable label.
  final String label;
}

/// The deployment components affected by a particular release.
class CloudflareReleaseChange {
  /// Creates CloudflareReleaseChange with the supplied values.
  const CloudflareReleaseChange(this.version, this.components);

  /// The version associated with this record.
  final String version;

  /// The deployment components included in this change or plan.
  final Set<CloudflareDeploymentComponent> components;
}

/// All independently deployable Cloudflare components.
const allCloudflareDeploymentComponents = {
  CloudflareDeploymentComponent.secrets,
  CloudflareDeploymentComponent.d1Migrations,
  CloudflareDeploymentComponent.worker,
  CloudflareDeploymentComponent.adminPages,
  CloudflareDeploymentComponent.webPages,
};

/// Deployment work introduced by each CLI/template release.
///
/// Every published CLI version must have an entry, including releases with an
/// empty component set. Updating across multiple versions unions all entries in
/// the traversed range.
const cloudflareReleaseChanges = [
  // Initial public template.
  CloudflareReleaseChange('0.1.0', allCloudflareDeploymentComponents),
  // Login CAPTCHA: migration 0002, Worker auth, and Admin login UI. Secret
  // names and bindings are unchanged from 0.1.0.
  CloudflareReleaseChange('0.1.1', {
    CloudflareDeploymentComponent.d1Migrations,
    CloudflareDeploymentComponent.worker,
    CloudflareDeploymentComponent.adminPages,
  }),
  // Groq/account support: groq_api_key, migration 0003, and Worker/Admin/Web.
  CloudflareReleaseChange('0.2.0', allCloudflareDeploymentComponents),
  // Response replies and translation: migration metadata wording, Worker APIs,
  // and Admin response management. Secrets and Web Pages are unchanged.
  CloudflareReleaseChange('0.2.1', {
    CloudflareDeploymentComponent.d1Migrations,
    CloudflareDeploymentComponent.worker,
    CloudflareDeploymentComponent.adminPages,
  }),
  // Namespaced secrets, migrations 0004-0005, public cost controls, deployment
  // configuration, and CAPTCHA state fixes affect every deployed component.
  CloudflareReleaseChange('0.3.0', allCloudflareDeploymentComponents),
];
