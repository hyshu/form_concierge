import FormConciergeSwiftUI
import SwiftUI

struct ContentView: View {
  let client: FormConciergeClient

  @State private var isShowingForm = false
  @State private var showSubmittedConfirmation = false

  var body: some View {
    NavigationStack {
      VStack {
        Button("Open form") {
          isShowingForm = true
        }
        .buttonStyle(.borderedProminent)
      }
      .navigationTitle("SwiftUI Mobile Simple")
      .navigationDestination(isPresented: $isShowingForm) {
        SurveyScreen(client: client) {
          isShowingForm = false
          showSubmittedConfirmation = true
        }
      }
    }
    .overlay(alignment: .bottom) {
      if showSubmittedConfirmation {
        Text("Form submitted")
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(.regularMaterial, in: Capsule())
          .padding(.bottom, 24)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.default, value: showSubmittedConfirmation)
    .task(id: showSubmittedConfirmation) {
      guard showSubmittedConfirmation else { return }
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      showSubmittedConfirmation = false
    }
  }
}

#Preview {
  ContentView(client: FormConciergeClient(baseURL: ExampleConfiguration.apiURL))
}
