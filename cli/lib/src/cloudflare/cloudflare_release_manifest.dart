enum CloudflareDeploymentComponent {
  secrets('Secrets'),
  d1Migrations('D1 migrations'),
  worker('Worker'),
  adminPages('Admin Pages'),
  webPages('Web Pages');

  const CloudflareDeploymentComponent(this.label);

  final String label;
}

class CloudflareReleaseChange {
  const CloudflareReleaseChange(this.version, this.components);

  final String version;
  final Set<CloudflareDeploymentComponent> components;
}

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
];
