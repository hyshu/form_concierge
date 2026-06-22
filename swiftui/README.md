# FormConciergeSwiftUI

Swift Package for embedding Form Concierge surveys in SwiftUI apps.

```swift
let client = FormConciergeClient(baseURL: URL(string: "https://your-worker.example.com")!)

FormConciergeSurveyView(
    client: client,
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

Pass `locale` to render survey content and SwiftUI package messages in that language. Locale identifiers are normalized, so `ja`, `ja_JP`, and `ja-JP` render Japanese. Region identifiers such as `en_US`, `ko_KR`, `de_DE`, `zh_CN`, and `zh_TW` are also normalized to the supported survey locales.

Pass `deviceInfo` from your app when you need stable device IDs, app versions, OS versions, model names, or values collected outside this package. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags. If omitted, the SwiftUI package sends basic current device, locale, timezone, and screen values.

Use the saved anonymous token to receive admin replies. Submitted answers are retained on the server for admins, but anonymous users cannot fetch their answer history from the API.

```swift
await client.setAnonymousToken(savedAnonymousToken)
let replies = try await client.replies(responseId: responseId)
```

To check whether new admin replies exist without downloading the full reply list, use the reply checker. The server returns only the latest reply timestamp; the checker stores the last seen timestamp in `UserDefaults`.

```swift
let checker = FormConciergeReplyChecker(
    client: client,
    anonymousToken: savedAnonymousToken,
    responseId: responseId
)

let status = try await checker.check()
if status.hasNewReplies {
    // Show your in-app badge or notification.
}

try await checker.markLatestSeen()
```
