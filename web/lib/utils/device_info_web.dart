import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:web/web.dart' as web;

DeviceInfo buildDeviceInfo() => DeviceInfo(
  label: 'Web',
  platform: 'web',
  browser: 'browser',
  locale: web.window.navigator.language,
  timezone: DateTime.now().timeZoneName,
  screenWidth: web.window.screen.width,
  screenHeight: web.window.screen.height,
  devicePixelRatio: web.window.devicePixelRatio,
);
