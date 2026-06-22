# form_concierge_survey_widget

Flutter widget package for embedding Form Concierge surveys.

## Setup

```dart
import 'package:form_concierge_client/form_concierge_client.dart';

final client = Client('https://your-worker.example.com');
```

## Usage

```dart
FormConciergeSurvey(
  client: client,
  surveySlug: 'customer-feedback',
  anonymousToken: savedAnonymousToken,
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

Pass `deviceInfo` from your app when you need stable device IDs, app versions, OS versions, model names, or any values collected outside this package. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags. The widget also adds basic screen, locale, timezone, and Flutter platform values when available.

The widget creates an anonymous account automatically before submission. Store `session.token` and pass it back as `anonymousToken` to receive admin replies across app launches.

Submitted answers are retained on the server for admins, but anonymous users cannot fetch their answer history from the API. Store any respondent-facing submission receipt locally if needed.

Admin replies can be read through the shared client:

```dart
client.anonymous.useToken(savedAnonymousToken);
final replies = await client.anonymous.getReplies(responseId: responseId);
```

## Supported Question Types

- Single choice
- Multiple choice
- Single line text
- Multi-line text
