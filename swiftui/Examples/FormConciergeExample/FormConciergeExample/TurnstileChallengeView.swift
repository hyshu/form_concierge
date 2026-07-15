import Combine
import SwiftUI
import WebKit

@MainActor
final class TurnstileCoordinator: ObservableObject {
  struct Challenge: Identifiable {
    let id = UUID()
    let siteKey: String
    let baseURL: URL
    let resolve: (String?) -> Void
  }

  @Published var isPresented = false
  private(set) var challenge: Challenge?
  private var continuation: CheckedContinuation<String?, Never>?

  func requestToken(siteKey: String, baseURL: URL) async -> String? {
    guard continuation == nil else { return nil }
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      challenge = Challenge(siteKey: siteKey, baseURL: baseURL) { [weak self] token in
        self?.finish(token)
      }
      isPresented = true
    }
  }

  func cancel() {
    finish(nil)
  }

  private func finish(_ token: String?) {
    let pending = continuation
    continuation = nil
    challenge = nil
    isPresented = false
    pending?.resume(returning: token)
  }
}

struct TurnstileChallengeView: UIViewRepresentable {
  let challenge: TurnstileCoordinator.Challenge

  func makeCoordinator() -> MessageHandler {
    MessageHandler(resolve: challenge.resolve)
  }

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(context.coordinator, name: "turnstile")
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.loadHTMLString(html, baseURL: challenge.baseURL)
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}

  static func dismantleUIView(_ webView: WKWebView, coordinator: MessageHandler) {
    webView.configuration.userContentController.removeScriptMessageHandler(forName: "turnstile")
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
              sitekey: '\(challenge.siteKey)',
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

  final class MessageHandler: NSObject, WKScriptMessageHandler {
    private let resolve: (String?) -> Void

    init(resolve: @escaping (String?) -> Void) {
      self.resolve = resolve
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      let body = message.body as? [String: Any]
      resolve(body?["token"] as? String)
    }
  }
}
