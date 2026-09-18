import Foundation

#if canImport(UIKit)
  import UIKit
#endif
#if canImport(AppKit)
  import AppKit
#endif

/// Optional device and application details attached to a survey response.
public struct DeviceInfo: Codable, Sendable {
  /// An application-provided identifier for the device.
  public let deviceId: String?
  /// A human-readable label.
  public let label: String?
  /// The platform on which the respondent is running the form.
  public let platform: String?
  /// The name of the operating system.
  public let os: String?
  /// The version of the operating system.
  public let osVersion: String?
  /// The browser name, when available.
  public let browser: String?
  /// The browser version, when available.
  public let browserVersion: String?
  /// The application's public version string.
  public let appVersion: String?
  /// The application's build identifier.
  public let appBuild: String?
  /// The hardware model reported by the device.
  public let model: String?
  /// The hardware manufacturer reported by the device.
  public let manufacturer: String?
  /// The locale reported by the respondent's device.
  public let locale: String?
  /// The device's time zone identifier.
  public let timezone: String?
  /// The screen width reported by the host platform.
  public let screenWidth: Int?
  /// The screen height reported by the host platform.
  public let screenHeight: Int?
  /// The number of physical pixels per logical screen pixel.
  public let devicePixelRatio: Double?
  /// The user agent reported by the client, when available.
  public let userAgent: String?

  /// Creates DeviceInfo with the supplied configuration.
  public init(
    deviceId: String? = nil,
    label: String? = nil,
    platform: String? = nil,
    os: String? = nil,
    osVersion: String? = nil,
    browser: String? = nil,
    browserVersion: String? = nil,
    appVersion: String? = nil,
    appBuild: String? = nil,
    model: String? = nil,
    manufacturer: String? = nil,
    locale: String? = nil,
    timezone: String? = nil,
    screenWidth: Int? = nil,
    screenHeight: Int? = nil,
    devicePixelRatio: Double? = nil,
    userAgent: String? = nil
  ) {
    self.deviceId = deviceId
    self.label = label
    self.platform = platform
    self.os = os
    self.osVersion = osVersion
    self.browser = browser
    self.browserVersion = browserVersion
    self.appVersion = appVersion
    self.appBuild = appBuild
    self.model = model
    self.manufacturer = manufacturer
    self.locale = locale
    self.timezone = timezone
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.devicePixelRatio = devicePixelRatio
    self.userAgent = userAgent
  }

  /// Collects available device, locale, and screen details from the current platform.
  public static var current: DeviceInfo {
    var label: String?
    var platform = "swiftui"
    var os: String?
    var osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    var screenWidth: Int?
    var screenHeight: Int?
    var scale: Double?

    #if canImport(UIKit)
      let device = UIDevice.current
      label = device.model
      platform = "ios"
      os = device.systemName
      osVersion = device.systemVersion
      let size = UIScreen.main.bounds.size
      screenWidth = Int(size.width.rounded())
      screenHeight = Int(size.height.rounded())
      scale = UIScreen.main.scale
    #elseif canImport(AppKit)
      label = Host.current().localizedName
      platform = "macos"
      os = "macOS"
      if let frame = NSScreen.main?.frame {
        screenWidth = Int(frame.width.rounded())
        screenHeight = Int(frame.height.rounded())
      }
      scale = NSScreen.main.map { Double($0.backingScaleFactor) }
    #endif

    return DeviceInfo(
      label: label,
      platform: platform,
      os: os,
      osVersion: osVersion,
      locale: Locale.current.identifier,
      timezone: TimeZone.current.identifier,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      devicePixelRatio: scale
    )
  }
}
