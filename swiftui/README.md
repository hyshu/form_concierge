# FormConciergeSwiftUI

Swift Package for embedding Form Concierge surveys in SwiftUI apps.

```swift
let client = FormConciergeClient(baseURL: URL(string: "https://your-worker.example.com")!)

FormConciergeSurveyView(
    client: client,
    projectSlug: "demo-project",
    surveySlug: "customer-feedback",
    anonymousToken: savedAnonymousToken,
    locale: "ja_JP",
    deviceInfo: DeviceInfo(
        deviceId: savedLocalDeviceId,
        label: "iPhone 18",
        platform: "ios",
        os: "iOS",
        osVersion: "26.0",
        appVersion: "1.4.2"
    ),
    metadata: [
        "uid": "\(currentUser.id)",
        "userName": "\(currentUser.displayName)",
        "plan": "\(currentUser.plan)"
    ],
    onAnonymousSession: { session in
        saveAnonymousToken(session.token)
    }
)
```

Pass `locale` to render survey content and SwiftUI package messages in that language. Locale identifiers are normalized, so `ja`, `ja_JP`, and `ja-JP` render Japanese. Region identifiers such as `en_US`, `ko_KR`, `de_DE`, `es_ES`, `fr_FR`, `it_IT`, `th_TH`, `tr_TR`, `zh_CN`, and `zh_TW` are also normalized to the supported survey locales (`en`, `ja`, `zh-Hans`, `zh-Hant`, `ko`, `de`, `es`, `fr`, `it`, `th`, `tr`).

Pass `deviceInfo` from your app when you need stable device IDs, app versions, OS versions, model names, or values collected outside this package. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags. If omitted, the SwiftUI package sends basic current device, locale, timezone, and screen values.

Use the saved anonymous token to receive admin replies. Submitted answers are retained on the server for admins, but anonymous users cannot fetch their answer history from the API.

When the API reports `captchaRequired: true`, the view calls `captchaTokenProvider` before submission. Integrate Turnstile in the host app and return its token from that closure. The older `Survey.captchaEnabled` property is deprecated for submission decisions because it represents the saved survey setting, not whether Turnstile is currently configured.

```swift
FormConciergeSurveyView(
    client: client,
    projectSlug: "demo-project",
    captchaTokenProvider: {
        await turnstileTokenProvider.token()
    }
)
```

```swift
await client.setAnonymousToken(savedAnonymousToken)
let replies = try await client.replies(responseId: responseId)
```

To check whether new admin replies exist without downloading the full reply list, use the reply checker. The server returns only the latest reply timestamp; **the host app owns last-seen persistence** (same as the Flutter widget — this package does not write to `UserDefaults` by default).

```swift
// Host provides storage (UserDefaults is one option among many).
let store = FormConciergeReplySeenStore.userDefaults(.standard)
// Or: FormConciergeReplySeenStore(read:write:remove:)

let checker = FormConciergeReplyChecker(
    client: client,
    anonymousToken: savedAnonymousToken,
    store: store,
    responseId: responseId
)

let status = try await checker.check()
if status.hasNewReplies {
    // Show your in-app badge or notification.
}

try await checker.markLatestSeen()
```
