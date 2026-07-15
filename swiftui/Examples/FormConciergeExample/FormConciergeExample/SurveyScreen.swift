import FormConciergeSwiftUI
import SwiftUI

struct SurveyScreen: View {
  let client: FormConciergeClient
  let onDone: () -> Void

  @StateObject private var captcha = TurnstileCoordinator()
  @State private var captchaSiteKey: String?

  var body: some View {
    FormConciergeSurveyView(
      client: client,
      projectSlug: ExampleConfiguration.projectSlug,
      surveySlug: ExampleConfiguration.surveySlug.isEmpty
        ? nil : ExampleConfiguration.surveySlug,
      surveyId: ExampleConfiguration.surveyId,
      onDone: onDone,
      captchaTokenProvider: {
        guard let captchaSiteKey else { return nil }
        return await captcha.requestToken(
          siteKey: captchaSiteKey,
          baseURL: ExampleConfiguration.turnstileBaseURL
        )
      }
    )
    .navigationTitle("Form")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      captchaSiteKey = try? await client.publicConfig().turnstileSiteKey
    }
    .sheet(isPresented: $captcha.isPresented, onDismiss: captcha.cancel) {
      if let challenge = captcha.challenge {
        TurnstileChallengeView(challenge: challenge)
          .presentationDetents([.height(260)])
      }
    }
  }
}
