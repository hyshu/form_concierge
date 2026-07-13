import 'dart:io';

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
    );

    final decoded = CloudflareDeploymentConfig.fromJson(original.toJson());

    expect(decoded.installedVersion, '1.2.3');
    expect(decoded.workerName, 'worker');
    expect(decoded.databaseId, 'database-id');
    expect(decoded.webPagesProject, 'web');
    expect(decoded.remoteBindingsForLocalDev, isTrue);
  });

  test('store writes and loads deployment config', () async {
    final root = await Directory.systemTemp.createTemp('deployment-store-');
    addTearDown(() => root.delete(recursive: true));
    final store = CloudflareDeploymentStore(root.path);

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
    final store = CloudflareDeploymentStore(root.path);
    await store.save(CloudflareDeploymentConfig(workerName: 'worker'));

    await store.delete();

    expect(File(store.path).existsSync(), isFalse);
    expect(File(store.path).parent.existsSync(), isFalse);
  });
}
