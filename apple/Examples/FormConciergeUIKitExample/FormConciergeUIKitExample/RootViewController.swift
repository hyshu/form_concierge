import FormConciergeUIKit
import UIKit

@MainActor
final class RootViewController: UIViewController {
  private let client: FormConciergeClient
  private let openButton = UIButton(configuration: .filled())
  private let confirmationLabel = UILabel()

  init(client: FormConciergeClient) {
    self.client = client
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIKit Mobile Simple"
    view.backgroundColor = .systemBackground

    openButton.configuration?.title = "Open form"
    openButton.addAction(
      UIAction { [weak self] _ in
        Task { await self?.openForm() }
      },
      for: .primaryActionTriggered
    )
    openButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(openButton)

    confirmationLabel.text = "Form submitted"
    confirmationLabel.font = .preferredFont(forTextStyle: .callout)
    confirmationLabel.textAlignment = .center
    confirmationLabel.backgroundColor = .secondarySystemBackground
    confirmationLabel.layer.cornerRadius = 18
    confirmationLabel.clipsToBounds = true
    confirmationLabel.alpha = 0
    confirmationLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(confirmationLabel)

    NSLayoutConstraint.activate([
      openButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      openButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      confirmationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      confirmationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      confirmationLabel.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
      confirmationLabel.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  private func openForm() async {
    openButton.isEnabled = false
    defer { openButton.isEnabled = true }

    let siteKey = try? await client.publicConfig().turnstileSiteKey
    let turnstile = TurnstileCoordinator()
    let survey = FormConciergeSurveyViewController(
      client: client,
      projectSlug: ExampleConfiguration.projectSlug,
      surveySlug: ExampleConfiguration.surveySlug.isEmpty
        ? nil : ExampleConfiguration.surveySlug,
      surveyId: ExampleConfiguration.surveyId,
      onDone: { [weak self] in
        self?.navigationController?.popViewController(animated: true)
        self?.showSubmittedConfirmation()
      },
      captchaTokenProvider: { [weak self] in
        guard let self, let siteKey else { return nil }
        return await turnstile.requestToken(
          presentingViewController: self.navigationController?.topViewController ?? self,
          siteKey: siteKey,
          baseURL: ExampleConfiguration.turnstileBaseURL
        )
      }
    )
    survey.title = "Form"
    navigationController?.pushViewController(survey, animated: true)
  }

  private func showSubmittedConfirmation() {
    confirmationLabel.layer.removeAllAnimations()
    confirmationLabel.alpha = 1
    UIView.animate(
      withDuration: 0.2,
      delay: 2,
      options: [.curveEaseOut, .beginFromCurrentState],
      animations: { [weak self] in self?.confirmationLabel.alpha = 0 }
    )
  }
}
