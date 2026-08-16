# Form Concierge for Jetpack Compose

Native Android library for Form Concierge surveys and inquiry threads. It supports:

- Published survey loading and localized content
- Single choice, multiple choice, single-line text, multi-line text, and image upload questions
- Visibility rules, validation, anonymous sessions, CAPTCHA callbacks, and AI follow-up questions
- A complete inquiry flow with a new-inquiry form, three-month local history, thread detail, admin replies, and per-thread new-reply checks
- Android Keystore AES-GCM encryption for the anonymous token and locally retained inquiry content

The library requires Android API 24 or later and Jetpack Compose Material 3.

## Local composite dependency

For development beside this repository, include the Android build from the consuming app's `settings.gradle.kts`:

```kotlin
includeBuild("../form_concierge/android")
```

Then add the library dependency:

```kotlin
dependencies {
    implementation("com.github.hyshu.form-concierge:form-concierge-compose:0.4.0-SNAPSHOT")
}
```

The module also defines a `release` Maven publication for local or hosted Maven repositories:

```bash
gradle -p android :form-concierge-compose:publishReleasePublicationToMavenLocal
```

## Complete inquiry flow

`FormConciergeInquiryFlow` owns navigation between the initial form, inquiry hub, history, detail, and admin replies. Users with no retained inquiries open directly on the new-inquiry form. Later visits open the hub.

```kotlin
import com.formconcierge.compose.FormConciergeInquiryConfig
import com.formconcierge.compose.FormConciergeInquiryFlow
import com.formconcierge.compose.rememberFormConciergeSessionStore
import kotlinx.serialization.json.JsonPrimitive

@Composable
fun ContactOverlay(onClose: () -> Unit) {
    val store = rememberFormConciergeSessionStore()

    FormConciergeInquiryFlow(
        config = FormConciergeInquiryConfig(
            baseUrl = "https://api.forms.example.com",
            projectSlug = "my-app",
            surveySlug = "inquiries",
            locale = "ja",
            metadata = mapOf("source" to JsonPrimitive("settings")),
            captchaTokenProvider = {
                // Show the host app's Turnstile challenge and return its token.
                resolveTurnstileToken()
            },
        ),
        store = store,
        onClose = onClose,
    )
}
```

The default store uses a namespace derived from the application ID. Pass an explicit namespace to isolate multiple Form Concierge projects:

```kotlin
val store = rememberFormConciergeSessionStore(namespace = "support")
```

The Worker intentionally does not expose anonymous answer history. The flow saves each successful submission locally so it can render the history and original thread content. Entries older than three calendar months are pruned. The anonymous bearer token and history are encrypted with an app-specific Android Keystore AES-GCM key.

## Survey only

Use `FormConciergeSurvey` when the host owns navigation and persistence:

```kotlin
val client = remember { FormConciergeClient("https://api.forms.example.com") }

FormConciergeSurvey(
    client = client,
    config = FormConciergeSurveyConfig(
        projectSlug = "my-app",
        surveySlug = "feedback",
        locale = "ja",
        captchaTokenProvider = ::resolveTurnstileToken,
    ),
    anonymousToken = savedToken,
    onAnonymousSession = { session -> saveToken(session.token) },
    onResponseSubmitted = { submission ->
        // Includes response, answer payload, questions, choices, and locale.
        saveSubmission(submission)
    },
    onFollowUpSubmitted = ::saveFollowUp,
    onDone = ::closeSurvey,
)
```

`processImage` receives image bytes after selection and before upload. Return a resized/compressed payload, or `null` to skip that image.

## CAPTCHA host responsibility

As with the SwiftUI package, the Compose library does not embed a CAPTCHA vendor UI. When `captchaRequired` is true, it invokes `captchaTokenProvider`. The host must present Cloudflare Turnstile (typically in a WebView) with its allowed origin and return a token, or return `null` on cancellation/failure. `FormConciergeClient.publicConfig()` exposes the configured public site key.

## Lower-level APIs

- `FormConciergeClient` / `FormConciergeApi`: public config, projects, questions, choices, visibility rules, anonymous account creation, response submission, image upload, AI follow-up, replies, and latest-reply timestamp.
- `FormConciergeSessionStore`: pluggable token/history/last-seen persistence.
- `FormConciergeReplyChecker`: global or per-response latest-reply comparison.
- `FormConciergeInquiryHub`, `FormConciergeInquiryList`, and `FormConciergeInquiryDetail`: individually embeddable Compose screens.

## Build and test

```bash
ANDROID_HOME="$HOME/Library/Android/sdk" \
  gradle -p android :form-concierge-compose:testDebugUnitTest

ANDROID_HOME="$HOME/Library/Android/sdk" \
  gradle -p android :form-concierge-compose:lintRelease \
  :form-concierge-compose:assembleRelease
```
