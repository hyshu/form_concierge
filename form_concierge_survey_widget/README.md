# form_concierge_survey_widget

A Flutter widget package for embedding form_concierge surveys into any Flutter application.

## Installation

Add to your pubspec.yaml:

```yaml
dependencies:
  form_concierge_survey_widget:
    path: ../form_concierge_survey_widget
  form_concierge_client:
    path: ../form_concierge_client
  serverpod_auth_core_flutter: ^3.2.3
```

## Setup

Initialize the client with authentication support in your app:

```dart
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';

final client = Client('https://your-server.com')
  ..authSessionManager = FlutterAuthSessionManager();
```

## Usage

Basic usage for anonymous surveys:

```dart
FormConciergeSurvey(
  client: client,
  surveySlug: 'customer-feedback',
  onSubmitted: () {
    Navigator.pop(context);
  },
)
```

For surveys that require authentication, the widget will display a login form automatically. Users can also register a new account from within the widget.

To handle authentication externally instead:

```dart
FormConciergeSurvey(
  client: client,
  surveySlug: 'member-survey',
  onSubmitted: () => Navigator.pop(context),
  onAuthRequired: () {
    // Navigate to your own login screen
    Navigator.pushNamed(context, '/login');
  },
)
```

## Parameters

- client: The form_concierge Client instance (required)
- surveySlug: The unique identifier for the survey (required)
- onSubmitted: Callback when the survey is successfully submitted
- onAuthRequired: Callback when authentication is needed. If not provided, the widget shows a built-in login form.
- anonymousId: Optional identifier for tracking anonymous responses

## Supported Question Types

- Single choice (radio buttons)
- Multiple choice (checkboxes)
- Single line text
- Multi-line text
