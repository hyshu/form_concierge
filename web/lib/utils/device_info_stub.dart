import 'package:form_concierge_client/form_concierge_client.dart';

DeviceInfo buildDeviceInfo() => DeviceInfo(
      label: 'Web',
      platform: 'web',
      timezone: DateTime.now().timeZoneName,
    );
