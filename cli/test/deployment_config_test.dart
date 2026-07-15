import 'dart:io';

import 'package:form_concierge_cli/src/cli_exception.dart';
import 'package:form_concierge_cli/src/cloudflare/deployment_config.dart';
import 'package:test/test.dart';

void main() {
  test('deployment config round-trips', () {
    final original = CloudflareDeploymentConfig(
      installedVersion: '1.2.3',
      accountId: 'account',
      workerName: 'worker',
      databaseName: 'database',
      databaseId: 'database-id',
      r2BucketName: 'bucket',
      adminPagesProject: 'admin',
      webPagesProject: 'web',
      remoteBindingsForLocalDev: true,
      deployAdminPages: false,
    );

    final decoded = CloudflareDeploymentConfig.fromJson(original.toJson());

    expect(decoded.installedVersion, '1.2.3');
    expect(decoded.workerName, 'worker');
    expect(decoded.databaseId, 'database-id');
    expect(decoded.webPagesProject, 'web');
    expect(decoded.remoteBindingsForLocalDev, isTrue);
    expect(decoded.deployAdminPages, isFalse);
    expect(
      decoded.toJson()['configuration'],
      containsPair('deployAdminPages', false),
    );
  });

  test('legacy deployment config defaults to deploying admin Pages', () {
    final decoded = CloudflareDeploymentConfig.fromJson({
      'schemaVersion': 1,
      'provider': 'cloudflare',
    });

    expect(decoded.deployAdminPages, isTrue);
  });

  test('legacy custom R2 binding is normalized to MEDIA_BUCKET', () {
    final decoded = CloudflareDeploymentConfig.fromJson({
      'schemaVersion': 1,
      'provider': 'cloudflare',
      'cloudflare': {
        'r2': {'binding': 'CUSTOM_BUCKET', 'bucketName': 'uploads'},
      },
    });

    expect((decoded.toJson()['cloudflare'] as Map)['r2'], {
      'binding': 'MEDIA_BUCKET',
      'bucketName': 'uploads',
    });
  });

  test('store writes and loads deployment config', () async {
    final root = await Directory.systemTemp.createTemp('deployment-store-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CloudflareDeploymentStore.select(
      requestedName: 'test',
      allowCreate: true,
      homeDirectory: root.path,
    );

    await store.save(CloudflareDeploymentConfig(workerName: 'worker'));
    final loaded = await store.load();

    expect(loaded?.workerName, 'worker');
    expect(File(store.path).existsSync(), isTrue);
  });

  test('store deletes deployment file and empty directory', () async {
    final root = await Directory.systemTemp.createTemp('deployment-delete-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final store = await CloudflareDeploymentStore.select(
      requestedName: 'test',
      allowCreate: true,
      homeDirectory: root.path,
    );
    await store.save(CloudflareDeploymentConfig(workerName: 'worker'));

    await store.delete();

    expect(File(store.path).existsSync(), isFalse);
    expect(File(store.path).parent.existsSync(), isFalse);
  });

  test('store auto-selects the only deployment', () async {
    final root = await Directory.systemTemp.createTemp('deployment-select-');
    addTearDown(() => root.delete(recursive: true));
    final original = await CloudflareDeploymentStore.select(
      requestedName: 'production',
      allowCreate: true,
      homeDirectory: root.path,
    );
    await original.save(CloudflareDeploymentConfig(workerName: 'worker'));

    final selected = await CloudflareDeploymentStore.select(
      allowCreate: false,
      homeDirectory: root.path,
    );

    expect(selected.name, 'production');
  });

  test('store creates default deployment when none exist', () async {
    final root = await Directory.systemTemp.createTemp('deployment-default-');
    addTearDown(() => root.delete(recursive: true));

    final selected = await CloudflareDeploymentStore.select(
      allowCreate: true,
      homeDirectory: root.path,
    );

    expect(selected.name, 'default');
    expect(selected.path, endsWith('.form_concierge/deployments/default.json'));
  });

  test(
    'store requires a name for multiple non-interactive deployments',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'deployment-multiple-',
      );
      addTearDown(() => root.delete(recursive: true));
      for (final name in ['production', 'staging']) {
        final store = await CloudflareDeploymentStore.select(
          requestedName: name,
          allowCreate: true,
          homeDirectory: root.path,
        );
        await store.save(CloudflareDeploymentConfig(workerName: name));
      }

      expect(
        () => CloudflareDeploymentStore.select(
          allowCreate: false,
          homeDirectory: root.path,
        ),
        throwsA(
          isA<CliException>().having(
            (error) => error.message,
            'message',
            contains('--deployment <name>'),
          ),
        ),
      );
    },
  );

  test('store rejects invalid deployment names', () async {
    expect(
      () => CloudflareDeploymentStore.select(
        requestedName: '../production',
        allowCreate: true,
      ),
      throwsA(isA<CliException>()),
    );
  });
}
