import FormConciergeUIKit
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    let client = FormConciergeClient(baseURL: ExampleConfiguration.apiURL)
    window.rootViewController = UINavigationController(
      rootViewController: RootViewController(client: client)
    )
    window.makeKeyAndVisible()
    self.window = window
    return true
  }
}
