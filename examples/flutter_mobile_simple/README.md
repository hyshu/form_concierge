# flutter_mobile_simple

Minimal iOS/Android Form Concierge example.

This sample embeds `FormConciergeSurvey` without local persistence, secure
storage, or app localization.

Run:

```bash
flutter run \
  --dart-define=FORM_CONCIERGE_API_URL=http://localhost:8787 \
  --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project
```

Optional:

- `FORM_CONCIERGE_SURVEY_ID`: open a specific survey in the project.
