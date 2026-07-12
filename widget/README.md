# form_concierge

Form Concierge is a self-hosted survey platform for Flutter, backed by Cloudflare Workers and D1.

Embed surveys directly in your app, collect anonymous responses, and optionally run AI-powered adaptive follow-up interviews. The `form_concierge` package includes both the Flutter widget and the Dart client, so your app only needs a single dependency.

## Key Features

- Native survey UI for Flutter
- Anonymous responses with no email or login required
- GenUI-powered adaptive follow-up interviews
- Single-choice, multiple-choice, text, and image-upload questions
- Multilingual survey and widget UI
- Admin replies for anonymous respondents
- Device and application metadata attached to responses
- Self-hosted Cloudflare Workers and D1 backend
- One-command backend deployment
- Flutter-based admin dashboard

The platform also includes:

- A Jaspr web survey form
- A SwiftUI package for native iOS apps

## How It Works

Respondents are automatically assigned an anonymous account before submitting a response. The app can persist the generated anonymous token and reuse it across launches, allowing the respondent to receive replies from administrators without creating a conventional account.

Survey answers remain on the server and are available to administrators. Anonymous respondents can retrieve administrator replies, but they cannot retrieve their own answer history through the API.

When adaptive follow-up is enabled, the backend uses an AI model to generate additional questions based on the respondent's initial answers. These questions are rendered directly inside the survey widget.

---

## Backend Setup

The `form_concierge_cli` package creates and deploys the complete Cloudflare backend, including:

- Workers
- D1
- R2
- Pages

### Install the CLI

```bash
dart pub global activate form_concierge_cli
```

### Authenticate with Cloudflare

The CLI uses Wrangler internally. Sign in to Cloudflare before running the deployment command:

```bash
npx wrangler login
```

### Check Your Environment

Verify that the required local tools are installed and that Cloudflare authentication is available:

```bash
form_concierge doctor
form_concierge setup cloudflare --preflight-only
```

### Deploy the Backend

```bash
form_concierge setup cloudflare
```

The command provisions the required Cloudflare resources and deploys the Worker, database, storage, and admin dashboard.

---

## API Keys and Secrets

Adaptive follow-up interviews require an API key for the AI provider configured in your Worker.

Store the corresponding key as a Cloudflare secret. For example, when using Gemini:

```bash
npx wrangler secret put gemini_api_key
```

Supported provider secrets include:

- `gemini_api_key`
- `openai_api_key`
- `claude_api_key`
- `cerebras_api_key`

Set the secret that matches the model configured for your deployment.

Optional features use additional secrets:

- `smtp_password` for email functionality
- `turnstile_secret_key` for Cloudflare Turnstile

---

## Admin Dashboard

The Flutter admin dashboard is used to create accounts, projects, and surveys.

Open the deployed Pages URL, or run the dashboard locally:

```bash
flutter run -d chrome
```

If no administrator account exists, the dashboard automatically opens the initial registration page. After the first account has been created, the normal sign-in page is shown.

After signing in:

1. Create a project.
2. Create one or more surveys inside the project.
3. Configure the survey questions.

Each survey has:

- A project slug
- A survey slug

Pass both values to the Flutter widget when embedding the survey.

---

## Flutter Package

### Installation

```bash
flutter pub add form_concierge
```

### Create a Client

```dart
import 'package:form_concierge/form_concierge.dart';

final client = Client('https://your-worker.example.com');
```

The main entrypoint exports both the Flutter widget and the complete Dart client API.

Code that only needs the client can use the focused entrypoint:

```dart
import 'package:form_concierge/client.dart';
```

---

## Embed a Survey

```dart
FormConciergeSurvey(
  client: client,
  projectSlug: 'demo-project',
  surveySlug: 'customer-feedback',
  anonymousToken: savedAnonymousToken,
  locale: 'ja_JP',
  deviceInfo: DeviceInfo(
    deviceId: savedLocalDeviceId,
    label: 'Pixel 9',
    platform: 'flutter',
    os: 'android',
    osVersion: '16',
    appVersion: '1.4.2',
  ),
  metadata: {
    'uid': currentUser.uid,
    'userName': currentUser.displayName,
    'plan': currentUser.plan,
  },
  onAnonymousSession: (session) async {
    await saveAnonymousToken(session.token);
  },
  onResponseSubmitted: (response, answers) {
    // Save the receipt for the main response.
    //
    // Do not close the route here when adaptive follow-up is enabled.
    // Additional questions may be generated after this callback.
  },
  onFollowUpSubmitted: (response) {
    // Replace the saved receipt with the follow-up-completed response.
  },
  onDone: () {
    Navigator.pop(context);
  },
  showLocalePicker: true,
  processImage: (image) async {
    // Resize, compress, redact, or remove metadata before upload.
    return image;
  },
  footer: const Text('Your privacy notice'),
)
```

Surveys with `followUpEnabled` automatically generate and render adaptive follow-up questions after the initial response has been submitted.

Image questions automatically open the image picker and upload the selected image. Use `processImage` when the host application needs to transform the image before upload.

Possible transformations include:

- Resizing
- Compression
- Metadata removal
- Redaction
- Format conversion

---

## Submission Lifecycle

### `onAnonymousSession`

Called when the widget creates or restores an anonymous session.

Persist `session.token` and pass it back through `anonymousToken` on later app launches.

```dart
onAnonymousSession: (session) async {
  await saveAnonymousToken(session.token);
},
```

### `onSubmitted`

Called immediately after the main survey response is saved.

### `onResponseSubmitted`

Also called immediately after the main survey response is saved. It provides both the saved response and the submitted answers.

Do not close the host route from `onSubmitted` or `onResponseSubmitted` when adaptive follow-up is enabled. The follow-up interview may begin after these callbacks run.

### `onFollowUpSubmitted`

Called after the adaptive follow-up answers have been saved.

### `onDone`

Called when the respondent taps the Done button on the completion screen.

This is generally the appropriate callback for closing the survey route.

### `onSubmitError`

Called when a submission fails, with the underlying error. The widget already shows an inline error message; use this to surface details (log or dialog).

```dart
onSubmitError: (error) => debugPrint('submit failed: $error'),
```

---

## CAPTCHA (Turnstile)

When a survey has CAPTCHA enabled in the admin dashboard, the backend rejects submissions without a valid token. The widget does **not** embed a CAPTCHA implementation — it asks the host for a token through `captchaTokenProvider`, so you can use any provider.

`captchaTokenProvider` is called only when the survey requires CAPTCHA. Return a token, or `null` to abort the submission (the widget then shows a "complete the CAPTCHA" message).

The example below uses [`cloudflare_turnstile`](https://pub.dev/packages/cloudflare_turnstile). The public site key is served by the backend config endpoint (`client.config.getPublicConfig().turnstileSiteKey`).

```dart
FormConciergeSurvey(
  client: client,
  projectSlug: 'my-project',
  surveySlug: 'contact',
  captchaTokenProvider: () => _resolveCaptchaToken(context),
  onSubmitError: (error) => debugPrint('submit failed: $error'),
);

Future<String?> _resolveCaptchaToken(BuildContext context) async {
  final config = await client.config.getPublicConfig();
  final siteKey = config.turnstileSiteKey;
  if (siteKey == null || siteKey.isEmpty || !context.mounted) return null;

  final completer = Completer<String?>();
  void finish(String? token) {
    if (!completer.isCompleted) completer.complete(token);
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CloudflareTurnstile(
          siteKey: siteKey,
          // Must match a hostname allowed by the Turnstile widget config.
          baseUrl: 'https://your-form-domain.example.com',
          onTokenReceived: (token) {
            finish(token);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
          onError: (error) {
            debugPrint('[turnstile] error: $error');
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
          onTimeout: () {
            debugPrint('[turnstile] timeout');
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        ),
      ),
    ),
  );
  finish(null);
  return completer.future;
}
```

`baseUrl` must be a hostname allowed by the Turnstile widget configuration in the Cloudflare dashboard, otherwise the challenge fails with an error callback. Turnstile tokens are single-use.

A complete, runnable version is in [`examples/flutter_mobile_full`](examples/flutter_mobile_full).

---

## Anonymous Sessions

The widget automatically creates an anonymous account before the first response is submitted.

Store the token returned through `onAnonymousSession`:

```dart
onAnonymousSession: (session) async {
  await saveAnonymousToken(session.token);
},
```

Pass the stored token back to the widget:

```dart
FormConciergeSurvey(
  anonymousToken: savedAnonymousToken,
  // ...
)
```

Reusing the token allows the respondent to receive administrator replies across app launches.

No email address, password, or conventional sign-in flow is required.

---

## Administrator Replies

Anonymous respondents can retrieve replies associated with a submitted response.

```dart
client.anonymous.useToken(savedAnonymousToken);

final replies = await client.anonymous.getReplies(
  responseId: responseId,
);
```

The anonymous API exposes administrator replies, but it does not expose the respondent's submitted answer history.

Store any respondent-facing submission receipt locally when the app needs to display previous submissions.

---

## Checking for New Replies

Use `FormConciergeReplyChecker` to determine whether new administrator replies are available without downloading the full reply list.

The server returns only the latest reply timestamp.

The host application is responsible for persisting the last-seen timestamp. The package does not depend on SharedPreferences or another storage implementation.

```dart
final prefs = await SharedPreferences.getInstance();

final store = FormConciergeReplySeenStore(
  read: prefs.getString,
  write: (key, value) async {
    await prefs.setString(key, value);
  },
  remove: (key) async {
    await prefs.remove(key);
  },
);

final checker = FormConciergeReplyChecker(
  client: client,
  anonymousToken: savedAnonymousToken,
  responseId: responseId,
  store: store,
);

final result = await checker.check();

if (result.hasNewReplies) {
  // Show an in-app badge, notification, or unread indicator.
}

await checker.markLatestSeen();
```

You can replace SharedPreferences with any persistent storage implementation by providing compatible `read`, `write`, and `remove` callbacks.

---

## Device Information and Metadata

Use `deviceInfo` for structured device and application information collected by the host app.

```dart
deviceInfo: DeviceInfo(
  deviceId: savedLocalDeviceId,
  label: 'Pixel 9',
  platform: 'flutter',
  os: 'android',
  osVersion: '16',
  appVersion: '1.4.2',
),
```

Typical values include:

- Stable local device ID
- Device model or label
- Operating system
- Operating-system version
- Application version
- Application platform

Use `metadata` for arbitrary application, user, tenant, or session context:

```dart
metadata: {
  'uid': currentUser.uid,
  'userName': currentUser.displayName,
  'tenant': currentTenant.id,
  'plan': currentUser.plan,
  'featureFlags': enabledFeatureFlags,
},
```

The widget also attaches basic environment information when available, including:

- Screen information
- Locale
- Time zone
- Flutter platform

Avoid attaching sensitive personal data unless it is necessary for the survey and appropriately disclosed to the respondent.

---

## Localization

Pass `locale` to control the language used for survey content and widget messages:

```dart
FormConciergeSurvey(
  locale: 'ja_JP',
  // ...
)
```

Locale tags are normalized automatically.

For example, all of the following select Japanese:

- `ja`
- `ja_JP`
- `ja-JP`

Supported survey locales are:

- `en`
- `ja`
- `zh-Hans`
- `zh-Hant`
- `ko`
- `de`
- `es`
- `fr`
- `it`
- `th`
- `tr`

Common regional locale tags are mapped to the corresponding supported locale:

| Input locale | Normalized locale |
|---|---|
| `en_US` | `en` |
| `ja_JP` | `ja` |
| `ko_KR` | `ko` |
| `de_DE` | `de` |
| `es_ES` | `es` |
| `fr_FR` | `fr` |
| `it_IT` | `it` |
| `th_TH` | `th` |
| `tr_TR` | `tr` |
| `zh_CN` | `zh-Hans` |
| `zh_TW` | `zh-Hant` |

Set `showLocalePicker` to `true` when respondents should be able to change the locale inside the widget:

```dart
showLocalePicker: true,
```

---

## Supported Question Types

Form Concierge currently supports:

- Single choice
- Multiple choice
- Single-line text
- Multi-line text
- Image upload

Question definitions and localized content are managed through the admin dashboard.

---

## Adaptive Follow-Up Interviews

Adaptive follow-up interviews are optional and configured per survey.

When enabled:

1. The respondent submits the main survey.
2. The Worker sends the initial answers to the configured AI provider.
3. The AI generates relevant follow-up questions.
4. The widget renders the generated questions.
5. The follow-up answers are submitted and attached to the response.

A custom prompt can be configured in the admin dashboard to control the purpose, tone, or focus of the generated interview.

An AI provider secret must be configured before this feature can be used.

---

## Data Model and Privacy

Form Concierge is designed around anonymous participation.

- Respondents do not need an email address or password.
- An anonymous token identifies the respondent's session.
- Survey answers are stored server-side.
- Administrators can view submitted answers.
- Anonymous respondents can retrieve administrator replies.
- Anonymous respondents cannot retrieve their own answer history through the API.
- The host app may store a local submission receipt when respondent-facing history is required.

Because the platform is self-hosted, the application owner controls the Cloudflare account, Worker, database, storage, and deployment configuration.

The application owner is also responsible for:

- Privacy notices
- Data-retention rules
- Consent requirements
- Uploaded-image handling
- AI-provider data policies
- Access control for administrators
