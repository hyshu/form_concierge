import 'package:form_concierge_cli/src/cloudflare/deployment_plan.dart';
import 'package:form_concierge_cli/src/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('current CLI version has a deployment manifest entry', () {
    expect(
      cloudflareReleaseChanges.map((change) => change.version),
      contains(formConciergeCliVersion),
    );
  });

  test('historical release deployment entries match tagged source changes', () {
    final changes = {
      for (final change in cloudflareReleaseChanges)
        change.version: change.components,
    };

    expect(changes['0.1.0'], allCloudflareDeploymentComponents);
    expect(changes['0.1.1'], {
      CloudflareDeploymentComponent.d1Migrations,
      CloudflareDeploymentComponent.worker,
      CloudflareDeploymentComponent.adminPages,
    });
    expect(changes['0.2.0'], allCloudflareDeploymentComponents);
    expect(changes['0.2.1'], {
      CloudflareDeploymentComponent.d1Migrations,
      CloudflareDeploymentComponent.worker,
      CloudflareDeploymentComponent.adminPages,
    });
  });

  test('initial setup deploys every component', () {
    final plan = CloudflareDeploymentPlan.resolve(
      installedVersion: null,
      targetVersion: formConciergeCliVersion,
      initialSetup: true,
    );

    expect(plan.components, allCloudflareDeploymentComponents);
  });

  test('same version skips component deployment', () {
    final plan = CloudflareDeploymentPlan.resolve(
      installedVersion: formConciergeCliVersion,
      targetVersion: formConciergeCliVersion,
    );

    expect(plan.components, isEmpty);
  });

  test('resource recovery adds required deployment components', () {
    final plan =
        CloudflareDeploymentPlan.resolve(
          installedVersion: formConciergeCliVersion,
          targetVersion: formConciergeCliVersion,
        ).withAdditionalComponents(const {
          CloudflareDeploymentComponent.d1Migrations,
          CloudflareDeploymentComponent.worker,
        }, 'required Cloudflare resource recreated');

    expect(plan.components, {
      CloudflareDeploymentComponent.d1Migrations,
      CloudflareDeploymentComponent.worker,
    });
    expect(plan.reason, contains('resource recreated'));
  });

  test('upgrade unions release component entries', () {
    final plan = CloudflareDeploymentPlan.resolve(
      installedVersion: '1.0.0',
      targetVersion: '1.2.0',
      releaseChanges: const [
        CloudflareReleaseChange('1.0.0', {}),
        CloudflareReleaseChange('1.1.0', {
          CloudflareDeploymentComponent.worker,
        }),
        CloudflareReleaseChange('1.2.0', {
          CloudflareDeploymentComponent.d1Migrations,
          CloudflareDeploymentComponent.webPages,
        }),
      ],
    );

    expect(plan.components, {
      CloudflareDeploymentComponent.worker,
      CloudflareDeploymentComponent.d1Migrations,
      CloudflareDeploymentComponent.webPages,
    });
  });

  test('force, overrides, downgrade, and unknown target deploy everything', () {
    final plans = [
      CloudflareDeploymentPlan.resolve(
        installedVersion: formConciergeCliVersion,
        targetVersion: formConciergeCliVersion,
        force: true,
      ),
      CloudflareDeploymentPlan.resolve(
        installedVersion: formConciergeCliVersion,
        targetVersion: formConciergeCliVersion,
        hasConfigurationOverrides: true,
      ),
      CloudflareDeploymentPlan.resolve(
        installedVersion: '9.0.0',
        targetVersion: formConciergeCliVersion,
      ),
      CloudflareDeploymentPlan.resolve(
        installedVersion: formConciergeCliVersion,
        targetVersion: '9.0.0',
      ),
    ];

    for (final plan in plans) {
      expect(plan.components, allCloudflareDeploymentComponents);
    }
  });
}
