import FormConciergeSwiftUI
import SwiftUI

@main
struct FormConciergeSwiftUIExampleApp: App {
  private let client = FormConciergeClient(baseURL: ExampleConfiguration.apiURL)

  var body: some Scene {
    WindowGroup {
      ContentView(client: client)
    }
  }
}
