import UIKit
import WebKit

@MainActor
final class TurnstileCoordinator {
  private var continuation: CheckedContinuation<String?, Never>?

  func requestToken(
    presentingViewController: UIViewController,
    siteKey: String,
    baseURL: URL
  ) async -> String? {
    guard continuation == nil else { return nil }
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      let challenge = TurnstileViewController(siteKey: siteKey, baseURL: baseURL)
      let navigation = UINavigationController(rootViewController: challenge)
      navigation.modalPresentationStyle = .pageSheet
      challenge.onCancel = { [weak self, weak navigation] in
        navigation?.dismiss(animated: true)
        self?.finish(nil)
      }
      challenge.onToken = { [weak self, weak navigation] token in
        navigation?.dismiss(animated: true)
        self?.finish(token)
      }
      if let sheet = navigation.sheetPresentationController {
        sheet.detents = [.custom { _ in 260 }]
      }
      presentingViewController.present(navigation, animated: true)
    }
  }

  private func finish(_ token: String?) {
    let pending = continuation
    continuation = nil
    pending?.resume(returning: token)
  }
}

@MainActor
private final class TurnstileViewController: UIViewController, WKScriptMessageHandler {
  private let siteKey: String
  private let baseURL: URL
  private weak var webView: WKWebView?
  var onCancel: (() -> Void)?
  var onToken: ((String?) -> Void)?

  init(siteKey: String, baseURL: URL) {
    self.siteKey = siteKey
    self.baseURL = baseURL
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Verification"
    view.backgroundColor = .systemBackground
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      systemItem: .cancel,
      primaryAction: UIAction { [weak self] _ in self?.onCancel?() }
    )

    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(self, name: "turnstile")
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.translatesAutoresizingMaskIntoConstraints = false
    self.webView = webView
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    webView.loadHTMLString(html, baseURL: baseURL)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isBeingDismissed || navigationController?.isBeingDismissed == true {
      webView?.configuration.userContentController.removeScriptMessageHandler(
        forName: "turnstile")
    }
  }

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    let body = message.body as? [String: Any]
    onToken?(body?["token"] as? String)
    onToken = nil
  }

  private var html: String {
    """
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"></script>
        <style>
          html, body { height: 100%; margin: 0; background: transparent; }
          body { display: flex; align-items: center; justify-content: center; }
        </style>
      </head>
      <body>
        <div id="challenge"></div>
        <script>
          window.onload = function() {
            turnstile.render('#challenge', {
              sitekey: '\(siteKey)',
              callback: function(token) {
                window.webkit.messageHandlers.turnstile.postMessage({ token: token });
              },
              'error-callback': function() {
                window.webkit.messageHandlers.turnstile.postMessage({ token: null });
              },
              'timeout-callback': function() {
                window.webkit.messageHandlers.turnstile.postMessage({ token: null });
              }
            });
          };
        </script>
      </body>
    </html>
    """
  }
}
