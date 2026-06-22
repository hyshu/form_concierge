# inappform

Flutter desktop/mobile example app for embedding `form_concierge_survey_widget`.

The widget now opens a project by slug and selects the first published survey
unless a survey ID is provided.

Run against a local Workers API:

```bash
flutter run \
  --dart-define=FORM_CONCIERGE_API_URL=http://localhost:8787 \
  --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project
```

Optional configuration:

- `FORM_CONCIERGE_SURVEY_ID`: open a specific survey in the project.
- `FORM_CONCIERGE_LOCALE`: force a form locale such as `ja` or `ja_JP`.
