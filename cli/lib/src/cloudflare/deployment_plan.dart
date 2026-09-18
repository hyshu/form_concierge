import 'package:pub_semver/pub_semver.dart';

import 'cloudflare_release_manifest.dart';

export 'cloudflare_release_manifest.dart';

/// The deployment components selected for an install or upgrade.
class CloudflareDeploymentPlan {
  CloudflareDeploymentPlan._(this.components, this.reason);

  /// Selects deployment components from release changes, using all components when a safe
  /// incremental plan cannot be determined.
  factory CloudflareDeploymentPlan.resolve({
    required String? installedVersion,
    required String targetVersion,
    bool initialSetup = false,
    bool force = false,
    bool hasConfigurationOverrides = false,
    List<CloudflareReleaseChange> releaseChanges = cloudflareReleaseChanges,
  }) {
    if (initialSetup) {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'initial setup',
      );
    }
    if (force) {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'forced by --force',
      );
    }
    if (hasConfigurationOverrides) {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'deployment configuration override',
      );
    }
    if (installedVersion == null) {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'installed version is unknown',
      );
    }

    Version installed;
    Version target;
    try {
      installed = Version.parse(installedVersion);
      target = Version.parse(targetVersion);
    } on FormatException {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'version format is unsupported',
      );
    }

    final parsedChanges = <Version, CloudflareReleaseChange>{};
    for (final change in releaseChanges) {
      parsedChanges[Version.parse(change.version)] = change;
    }
    if (!parsedChanges.containsKey(target)) {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'target version has no deployment manifest entry',
      );
    }
    if (target < installed) {
      return CloudflareDeploymentPlan._(
        allCloudflareDeploymentComponents,
        'version downgrade',
      );
    }
    if (target == installed) {
      return CloudflareDeploymentPlan._(const {}, 'already at $targetVersion');
    }

    final components = <CloudflareDeploymentComponent>{};
    for (final MapEntry(key: version, value: change) in parsedChanges.entries) {
      if (version > installed && version <= target) {
        components.addAll(change.components);
      }
    }
    return CloudflareDeploymentPlan._(
      Set.unmodifiable(components),
      'upgrade $installedVersion → $targetVersion',
    );
  }

  /// The deployment components included in this change or plan.
  final Set<CloudflareDeploymentComponent> components;

  /// The explanation for selecting these deployment components.
  final String reason;

  /// Returns whether the deployment plan contains the supplied component.
  bool includes(CloudflareDeploymentComponent component) =>
      components.contains(component);

  /// Returns a plan with added components and an explanation, or this plan when nothing
  /// is added.
  CloudflareDeploymentPlan withAdditionalComponents(
    Iterable<CloudflareDeploymentComponent> additional,
    String additionalReason,
  ) {
    final combined = {...components, ...additional};
    if (combined.length == components.length) return this;
    return CloudflareDeploymentPlan._(
      Set.unmodifiable(combined),
      '$reason; $additionalReason',
    );
  }
}
