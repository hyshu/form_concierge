part of form_concierge_client;

class DeviceInfo {
  final String? deviceId;
  final String? label;
  final String? platform;
  final String? os;
  final String? osVersion;
  final String? browser;
  final String? browserVersion;
  final String? appVersion;
  final String? appBuild;
  final String? model;
  final String? manufacturer;
  final String? locale;
  final String? timezone;
  final int? screenWidth;
  final int? screenHeight;
  final double? devicePixelRatio;
  final String? userAgent;

  const DeviceInfo({
    this.deviceId,
    this.label,
    this.platform,
    this.os,
    this.osVersion,
    this.browser,
    this.browserVersion,
    this.appVersion,
    this.appBuild,
    this.model,
    this.manufacturer,
    this.locale,
    this.timezone,
    this.screenWidth,
    this.screenHeight,
    this.devicePixelRatio,
    this.userAgent,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    deviceId: _optionalString(json['deviceId']),
    label: _optionalString(json['label']),
    platform: _optionalString(json['platform']),
    os: _optionalString(json['os']),
    osVersion: _optionalString(json['osVersion']),
    browser: _optionalString(json['browser']),
    browserVersion: _optionalString(json['browserVersion']),
    appVersion: _optionalString(json['appVersion']),
    appBuild: _optionalString(json['appBuild']),
    model: _optionalString(json['model']),
    manufacturer: _optionalString(json['manufacturer']),
    locale: _optionalString(json['locale']),
    timezone: _optionalString(json['timezone']),
    screenWidth: json['screenWidth'] == null ? null : _int(json['screenWidth']),
    screenHeight: json['screenHeight'] == null
        ? null
        : _int(json['screenHeight']),
    devicePixelRatio: json['devicePixelRatio'] == null
        ? null
        : _double(json['devicePixelRatio']),
    userAgent: _optionalString(json['userAgent']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'deviceId': deviceId,
    'label': label,
    'platform': platform,
    'os': os,
    'osVersion': osVersion,
    'browser': browser,
    'browserVersion': browserVersion,
    'appVersion': appVersion,
    'appBuild': appBuild,
    'model': model,
    'manufacturer': manufacturer,
    'locale': locale,
    'timezone': timezone,
    'screenWidth': screenWidth,
    'screenHeight': screenHeight,
    'devicePixelRatio': devicePixelRatio,
    'userAgent': userAgent,
  });

  DeviceInfo merge(DeviceInfo? override) {
    if (override == null) return this;
    return DeviceInfo(
      deviceId: override.deviceId ?? deviceId,
      label: override.label ?? label,
      platform: override.platform ?? platform,
      os: override.os ?? os,
      osVersion: override.osVersion ?? osVersion,
      browser: override.browser ?? browser,
      browserVersion: override.browserVersion ?? browserVersion,
      appVersion: override.appVersion ?? appVersion,
      appBuild: override.appBuild ?? appBuild,
      model: override.model ?? model,
      manufacturer: override.manufacturer ?? manufacturer,
      locale: override.locale ?? locale,
      timezone: override.timezone ?? timezone,
      screenWidth: override.screenWidth ?? screenWidth,
      screenHeight: override.screenHeight ?? screenHeight,
      devicePixelRatio: override.devicePixelRatio ?? devicePixelRatio,
      userAgent: override.userAgent ?? userAgent,
    );
  }

  String? get summary {
    final name = label ?? model;
    final system = [
      os,
      osVersion,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    final agent = [
      browser,
      browserVersion,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    final parts = [
      name,
      system.isEmpty ? platform : system,
      agent.isEmpty ? null : agent,
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' / ');
  }

  String? get detailSummary {
    final screen = screenWidth != null && screenHeight != null
        ? '${screenWidth}x$screenHeight'
        : null;
    final parts = [
      locale,
      timezone,
      screen,
      devicePixelRatio == null ? null : '${devicePixelRatio}x',
      appVersion == null ? null : 'app $appVersion',
      appBuild == null ? null : 'build $appBuild',
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' / ');
  }
}
