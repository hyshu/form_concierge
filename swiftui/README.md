# FormConciergeSwiftUI

Swift Package for embedding Form Concierge surveys in SwiftUI apps.

```swift
let client = FormConciergeClient(baseURL: URL(string: "https://your-worker.example.com")!)

FormConciergeSurveyView(
    client: client,
    surveySlug: "customer-feedback",
    anonymousToken: savedAnonymousToken,
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

Pass `deviceInfo` from your app when you need stable device IDs, app versions, OS versions, model names, or values collected outside this package. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags. If omitted, the SwiftUI package sends basic current device, locale, timezone, and screen values.

Use the saved anonymous token to receive admin replies. Submitted answers are retained on the server for admins, but anonymous users cannot fetch their answer history from the API.

```swift
await client.setAnonymousToken(savedAnonymousToken)
let replies = try await client.replies(responseId: responseId)
```
