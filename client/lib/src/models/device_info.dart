part of form_concierge_client;

/// Optional device and application details attached to a survey response.
class DeviceInfo {
  /// An application-provided identifier for the device.
  final String? deviceId;

  /// A human-readable label.
  final String? label;

  /// The platform on which the respondent is running the form.
  final String? platform;

  /// The name of the operating system.
  final String? os;

  /// The version of the operating system.
  final String? osVersion;

  /// The browser name, when available.
  final String? browser;

  /// The browser version, when available.
  final String? browserVersion;

  /// The application's public version string.
  final String? appVersion;

  /// The application's build identifier.
  final String? appBuild;

  /// The hardware model reported by the device.
  final String? model;

  /// The hardware manufacturer reported by the device.
  final String? manufacturer;

  /// The locale reported by the respondent's device.
  final String? locale;

  /// The device's time zone identifier.
  final String? timezone;

  /// The screen width reported by the host platform.
  final int? screenWidth;

  /// The screen height reported by the host platform.
  final int? screenHeight;

  /// The number of physical pixels per logical screen pixel.
  final double? devicePixelRatio;

  /// The user agent reported by the client, when available.
  final String? userAgent;

  /// Creates DeviceInfo with the supplied values.
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

  /// Decodes DeviceInfo from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

  /// Returns device details with non-null values from the override taking precedence.
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

  /// Returns a compact device label, or null when no useful details are available.
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

  /// Returns a longer summary of available device details, or null when empty.
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
