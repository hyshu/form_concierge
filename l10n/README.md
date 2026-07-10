# Localization

ARB files are the source of truth for static application copy.

- `admin_dashboard/l10n/admin`: admin dashboard UI
- `client/l10n/form_content`: public survey UI shared by client, web, and widget

After editing an ARB file, regenerate Dart lookup tables from the repository
root:

```sh
dart run tool/generate_localizations.dart
```

Do not edit `admin_messages.g.dart` or `survey_messages.g.dart` directly.
Survey titles, descriptions, questions, placeholders, and choices remain dynamic
API data represented by `LocalizedText`; they do not belong in ARB files.
