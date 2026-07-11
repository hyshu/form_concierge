# flutter_embedded_form

Flutter app used by the E2E suite for embedded `form_concierge`.
Linux remains enabled because CI runs this app on Linux.

The widget now opens a project by slug and selects the first published survey
unless a survey slug or legacy survey ID is provided.

Run against a local Workers API:

```bash
flutter run \
  --dart-define=FORM_CONCIERGE_API_URL=http://localhost:8787 \
  --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project
```

Optional configuration:

- `FORM_CONCIERGE_SURVEY_SLUG`: open a specific survey in the project.
- `FORM_CONCIERGE_SURVEY_ID`: legacy fallback for older survey URLs.
- `FORM_CONCIERGE_LOCALE`: force a form locale such as `ja` or `ja_JP`.
