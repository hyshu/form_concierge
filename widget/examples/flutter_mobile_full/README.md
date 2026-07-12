# flutter_mobile_full

Full iOS/Android Form Concierge example.

It demonstrates:

- `FormConciergeSurvey`
- `FormConciergeReplyChecker`
- adaptive GenUI follow-up interviews without closing after the main response
- image upload questions and the host-side `processImage` hook
- anonymous token persistence with `flutter_secure_storage`
- project, survey, locale, and response state persistence with `shared_preferences`
- localized app UI with `flutter_localizations`
- built-in locale picker control with `showLocalePicker`
- actual admin reply loading in addition to new-reply checks
- `locale`, `anonymousToken`, `anonymousId`, `deviceInfo`, `metadata`, `footer`, `onAnonymousSession`, `onResponseSubmitted`, `onFollowUpSubmitted`, and `onDone`

`onResponseSubmitted` records the main response but deliberately keeps the
survey route open. If follow-up is enabled, the widget continues into that
interview. The route closes only from `onDone` after the completion screen.

The sample `processImage` implementation returns the original image. Replace it
with app-specific resizing, compression, redaction, or metadata removal.

Reply handling follows a typical inquiry flow:

- `FormConciergeReplyChecker.check()` requests only the latest reply timestamp
  and compares it with the host-owned seen marker. The sample shows the result
  as a badge and also provides an explicit check action.
- `client.anonymous.getReplies(responseId: ...)` loads the reply bodies for the
  selected response on a dedicated screen.
- Opening that screen calls `markLatestSeen()`. The seen marker remains in
  `SharedPreferences`; reply bodies stay on the server.

Run:

```bash
flutter run \
  --dart-define=FORM_CONCIERGE_API_URL=http://localhost:8787 \
  --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project
```

Optional configuration:

- `FORM_CONCIERGE_SURVEY_SLUG`: open a specific survey in the project.
- `FORM_CONCIERGE_SURVEY_ID`: legacy fallback for older survey URLs.
- `FORM_CONCIERGE_LOCALE`: initial form content locale, such as `ja` or `ja_JP`.
