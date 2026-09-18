import 'package:form_concierge_client/form_concierge_client.dart';

/// Collects available platform details for inclusion in a survey submission.
DeviceInfo buildDeviceInfo() => DeviceInfo(
  label: 'Web',
  platform: 'web',
  timezone: DateTime.now().timeZoneName,
);
