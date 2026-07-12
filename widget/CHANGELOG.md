## 0.1.1

- Add `captchaTokenProvider` so hosts can supply a CAPTCHA token (for example
  Cloudflare Turnstile) when a survey has CAPTCHA enabled.
- Add `onSubmitError` to surface submission failures beyond the inline message.
- Document CAPTCHA integration and update the full mobile example.

## 0.1.0

- First public release.
- Renamed package from `form_concierge_survey_widget` to `form_concierge`.
- Export the complete client API from `form_concierge.dart` and the focused
  `client.dart` entrypoint.
