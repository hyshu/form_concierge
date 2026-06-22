import Foundation

#if canImport(UIKit)
  import UIKit
#endif
#if canImport(AppKit)
  import AppKit
#endif

public struct DeviceInfo: Codable, Sendable {
  public let deviceId: String?
  public let label: String?
  public let platform: String?
  public let os: String?
  public let osVersion: String?
  public let browser: String?
  public let browserVersion: String?
  public let appVersion: String?
  public let appBuild: String?
  public let model: String?
  public let manufacturer: String?
  public let locale: String?
  public let timezone: String?
  public let screenWidth: Int?
  public let screenHeight: Int?
  public let devicePixelRatio: Double?
  public let userAgent: String?

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
