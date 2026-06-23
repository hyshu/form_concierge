# flutter_mobile_full

Full iOS/Android Form Concierge example.

It demonstrates:

- `FormConciergeSurvey`
- `FormConciergeReplyChecker`
- anonymous token persistence with `flutter_secure_storage`
- project, survey, locale, and response state persistence with `shared_preferences`
- localized app UI with `flutter_localizations`
- `locale`, `anonymousToken`, `anonymousId`, `deviceInfo`, `metadata`, `onAnonymousSession`, and `onResponseSubmitted`

Run:

```bash
flutter run \
  --dart-define=FORM_CONCIERGE_API_URL=http://localhost:8787 \
  --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project
```

Optional configuration:

- `FORM_CONCIERGE_SURVEY_ID`: open a specific survey in the project.
- `FORM_CONCIERGE_LOCALE`: initial form content locale, such as `ja` or `ja_JP`.
