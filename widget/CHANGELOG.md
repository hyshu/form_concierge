## 0.3.0

- Request a token from `captchaTokenProvider` only when the API reports that
  CAPTCHA is required, avoiding unnecessary challenges when the saved CAPTCHA
  setting is enabled but Turnstile is not configured.
- Add a pub.dev package screenshot and improve CAPTCHA API documentation.

## 0.2.1

- Deprecate `onSubmitted` in favor of `onResponseSubmitted`, which provides the
  saved response and answers.
- Rename GenUI follow-up wording to AI follow-ups in API documentation and
  examples.

## 0.2.0

- Add `loadingBuilder` to customize survey loading states.
- Move the default loading indicator near the top of the available body area.

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
