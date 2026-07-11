# form_concierge

Flutter package for embedding Form Concierge surveys.

Not published to pub.dev yet (`publish_to: none`).

## Setup

```dart
import 'package:form_concierge/form_concierge.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

final client = Client('https://your-worker.example.com');
```

## Usage

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
  onSubmitted: () {
    Navigator.pop(context);
  },
)
```

Pass `locale` to render survey content and widget messages in that language. Locale tags are normalized, so `ja`, `ja_JP`, and `ja-JP` render Japanese. Region tags such as `en_US`, `ko_KR`, `de_DE`, `es_ES`, `fr_FR`, `it_IT`, `th_TH`, `tr_TR`, `zh_CN`, and `zh_TW` are also normalized to the supported survey locales (`en`, `ja`, `zh-Hans`, `zh-Hant`, `ko`, `de`, `es`, `fr`, `it`, `th`, `tr`).

Pass `deviceInfo` from your app when you need stable device IDs, app versions, OS versions, model names, or any values collected outside this package. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags. The widget also adds basic screen, locale, timezone, and Flutter platform values when available.

The widget creates an anonymous account automatically before submission. Store `session.token` and pass it back as `anonymousToken` to receive admin replies across app launches.

Submitted answers are retained on the server for admins, but anonymous users cannot fetch their answer history from the API. Store any respondent-facing submission receipt locally if needed.

Admin replies can be read through the shared client:

```dart
client.anonymous.useToken(savedAnonymousToken);
final replies = await client.anonymous.getReplies(responseId: responseId);
```

To check whether new admin replies exist without downloading the full reply list, use the reply checker. The server returns only the latest reply timestamp; **the host app owns last-seen persistence** (this package does not depend on SharedPreferences).

```dart
final prefs = await SharedPreferences.getInstance(); // or your own store
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
  // Show your in-app badge or notification.
}

await checker.markLatestSeen();
```

## Supported Question Types

- Single choice
- Multiple choice
- Single line text
- Multi-line text
