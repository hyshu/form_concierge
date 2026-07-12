# form_concierge_client

Dart REST client for the Form Concierge Workers API.

## Installation

```bash
dart pub add form_concierge_client
```

The package exposes survey, admin, anonymous-account, response, reply, and configuration endpoints for the Workers API.

## Usage

```dart
import 'package:form_concierge_client/form_concierge_client.dart';

Future<void> main() async {
  final client = Client('https://your-worker.example.com');
  try {
    final project = await client.survey.getProjectBySlug('demo-project');
    print(project?.project.name);
  } finally {
    client.close();
  }
}
```

Survey submissions accept optional `DeviceInfo` and `metadata`. Collect and store stable IDs or detailed device fields in the host app, then pass them to `submitResponse(deviceInfo: ..., metadata: ...)`. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags.
