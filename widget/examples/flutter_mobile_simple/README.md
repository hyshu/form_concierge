# flutter_mobile_simple

Minimal iOS/Android Form Concierge example.

This sample embeds `FormConciergeSurvey` without local persistence, secure
storage, or app localization.

The route closes from `onDone`, not `onSubmitted`, so adaptive follow-up
questions remain available after the main response is saved.

Run:

```bash
flutter run \
  --dart-define=FORM_CONCIERGE_API_URL=http://localhost:8787 \
  --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project
```

Optional:

- `FORM_CONCIERGE_SURVEY_SLUG`: open a specific survey in the project.
- `FORM_CONCIERGE_SURVEY_ID`: legacy fallback for older survey URLs.
