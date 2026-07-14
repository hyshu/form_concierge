# form_concierge

<p align="center">
  <img src="https://raw.githubusercontent.com/hyshu/form_concierge/main/widget/logo.svg" alt="Form Concierge logo" width="360">
</p>

Form Concierge is a self-hosted survey platform for Flutter, backed by Cloudflare Workers and D1. Embed surveys in your app, collect anonymous responses, and optionally run AI-powered adaptive follow-up interviews. You can also send replies directly to respondents.

The package exports both the Flutter widget and the Dart client API.

## Features

- Native Flutter survey UI
- Web survey forms powered by [Jaspr](https://pub.dev/packages/jaspr)
- Anonymous responses without email or login
- Single-choice, multiple-choice, text, and image-upload questions
- Multilingual survey content
- Administrator replies for anonymous respondents
- Optional AI-powered adaptive follow-up interviews
- Self-hosted Cloudflare backend and admin dashboard

## Quick Start

### Deploy the Backend

Install [the setup CLI](https://pub.dev/packages/form_concierge_cli) and authenticate with Cloudflare:

```bash
dart pub global activate form_concierge_cli
npx wrangler login
```

Check the local environment, then deploy the Worker, D1 database, R2 storage, and admin dashboard:

```bash
form_concierge doctor
form_concierge setup cloudflare
```

During setup, the CLI asks for a Cloudflare API token used by the deployed Worker to manage Secrets Store values. Create a custom token from [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens) with this permission:

- `Account` → `Secrets Store` → `Edit`

Paste the API token when prompted. The CLI stores it as the Worker secret `CF_API_TOKEN`; do not paste a Secrets Store ID.

### Create a Survey

Create a project and survey in the deployed admin dashboard, then pass their slugs to the widget:

```dart
FormConciergeSurvey(
  projectSlug: 'demo-project',
  surveySlug: 'customer-feedback',
  // ...
)
```

Provider credentials and other deployment settings are also managed from the admin dashboard.

### Add the Flutter Package

```bash
flutter pub add form_concierge
```

Create a client for the deployed Worker:

```dart
import 'package:form_concierge/form_concierge.dart';

final client = Client('https://your-worker.example.com');
```

Code that only needs the Dart client can use:

```dart
import 'package:form_concierge/client.dart';
```

### Embed the Survey

```dart
FormConciergeSurvey(
  client: client,
  projectSlug: 'demo-project',
  surveySlug: 'customer-feedback',
  anonymousToken: savedAnonymousToken,
  locale: 'ja_JP',
  onAnonymousSession: (session) async {
    // Write the token persistence process here.
    await secureStorage.write(key, session.token);
  },
  onDone: () {
    Navigator.pop(context);
  },
)
```

Surveys with adaptive follow-up enabled generate and render additional questions after the initial response.

## Widget Configuration

### Anonymous Sessions

The widget creates an anonymous account before the first submission. Persist the token and pass it back on later app launches:

```dart
FormConciergeSurvey(
  anonymousToken: savedAnonymousToken,
  onAnonymousSession: (session) async {
    // Write the token persistence process here.
    await secureStorage.write(key, session.token);
  },
  // ...
)
```

Reusing the token lets a respondent receive administrator replies without a conventional account.

### Submission Callbacks

| Callback | Called when | Typical use |
|---|---|---|
| `onAnonymousSession` | A session is created or restored | Persist the anonymous token |
| `onResponseSubmitted` | The main response is saved | Store the response and submitted answers |
| `onFollowUpSubmitted` | Follow-up answers are saved | Update the stored receipt |
| `onDone` | The respondent taps Done | Close the survey route |
| `onSubmitError` | Submission fails | Log or display error details |

Do not close the route from `onResponseSubmitted` when adaptive follow-up is enabled. Additional questions may appear after it runs.

For security, anonymous respondents cannot retrieve their submitted answers through the API. To show a response history, persist the response and answers received by `onResponseSubmitted` in the host application.

### Administrator Replies

Use the stored anonymous token to retrieve replies for a response:

```dart
client.anonymous.useToken(savedAnonymousToken);

final replies = await client.anonymous.getReplies(
  responseId: responseId,
);
```

Store a local submission receipt if the app needs respondent-facing submission history.

To check for unread replies without downloading the full list, use `FormConciergeReplyChecker`. The host app provides storage for the last-seen timestamp:

```dart
final checker = FormConciergeReplyChecker(
  client: client,
  anonymousToken: savedAnonymousToken,
  responseId: responseId,
  store: FormConciergeReplySeenStore(
    read: prefs.getString,
    write: (key, value) async => prefs.setString(key, value),
    remove: (key) async => prefs.remove(key),
  ),
);

final result = await checker.check();
if (result.hasNewReplies) {
  // Show an unread indicator.
}
await checker.markLatestSeen();
```

### Device Information and Metadata

Use `deviceInfo` for structured device and app information, and `metadata` for application-specific context:

```dart
FormConciergeSurvey(
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
    'tenant': currentTenant.id,
    'plan': currentUser.plan,
  },
  // ...
)
```

The widget also attaches basic environment information when available, including screen details, locale, time zone, and Flutter platform. Avoid sensitive personal data unless required and disclosed to the respondent.

### Image Processing

Image questions open the image picker and upload the selected image. Use `processImage` to resize, compress, redact, remove metadata, or convert it first:

```dart
processImage: (image) async {
  // Write the image conversion process here.
  return image;
},
```

### Localization

Pass `locale` to control survey content and widget messages. Locale tags such as `ja`, `ja_JP`, and `ja-JP` are normalized automatically.

Supported locales:

| Language | Locale |
|---|---|
| English | `en` |
| Japanese | `ja` |
| Simplified Chinese | `zh-Hans` |
| Traditional Chinese | `zh-Hant` |
| Korean | `ko` |
| German | `de` |
| Spanish | `es` |
| French | `fr` |
| Italian | `it` |
| Thai | `th` |
| Turkish | `tr` |

Allow respondents to change language inside the widget with:

```dart
showLocalePicker: true,
```

## Question Types

- Single choice
- Multiple choice
- Single-line text
- Multi-line text
- Image upload

Question definitions and localized content are managed in the admin dashboard.

## Adaptive Follow-Up Interviews

Adaptive follow-up interviews are optional and configured per survey in the admin dashboard.

When enabled, the respondent submits the main survey, the backend generates relevant follow-up questions with the configured AI provider, and the widget renders and submits them. A custom prompt controls the interview's purpose, tone, and focus.

When email notifications are enabled, the main response and follow-up response each send a notification, resulting in two emails. This is because some respondents may close the survey without providing a follow-up response.

Configure the AI provider and its credentials in the admin dashboard before enabling this feature.

## CAPTCHA with Turnstile

Turnstile runs JavaScript in a browser environment, so it cannot be implemented using only the Flutter UI. Supporting it directly would require an additional browser integration, such as a WebView package or native platform code. To avoid imposing that dependency and implementation choice on every application, this package does not include CAPTCHA UI.

When CAPTCHA is enabled, the widget instead requests a verification token from the host application through `captchaTokenProvider`.

```dart
FormConciergeSurvey(
  client: client,
  projectSlug: 'my-project',
  surveySlug: 'contact',
  captchaTokenProvider: () => resolveCaptchaToken(context),
);

Future<String?> resolveCaptchaToken(BuildContext context) async {
  final config = await client.config.getPublicConfig();
  final siteKey = config.turnstileSiteKey;
  if (siteKey == null || siteKey.isEmpty || !context.mounted) return null;

  final completer = Completer<String?>();
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => CloudflareTurnstile(
      siteKey: siteKey,
      baseUrl: 'https://your-form-domain.example.com',
      onTokenReceived: (token) {
        completer.complete(token);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
  if (!completer.isCompleted) completer.complete(null);
  return completer.future;
}
```

This example uses [`cloudflare_turnstile`](https://pub.dev/packages/cloudflare_turnstile) and `dart:async`. The provider runs only when CAPTCHA is required; return `null` to cancel submission. Turnstile tokens are single-use, and `baseUrl` must use a hostname allowed by the Turnstile widget configuration.

See [`examples/flutter_mobile_full`](examples/flutter_mobile_full) for complete error and timeout handling.

## Privacy and Data Ownership

- Respondents need no email address or password.
- Survey answers remain server-side and are visible to administrators.
- Anonymous respondents can retrieve administrator replies, but not their answer history.
- The host app may store a local receipt when respondent-facing history is needed.
- The application owner controls the Cloudflare account, Worker, database, storage, and deployment configuration.

Application owners remain responsible for privacy notices, consent, retention rules, and uploaded-image handling.
