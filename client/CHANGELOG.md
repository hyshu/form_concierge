## 0.3.0

- Add `Survey.captchaRequired`, which reports whether a submission must include
  a CAPTCHA token based on both the saved survey setting and the deployed
  Turnstile configuration.
- Add `Survey.captchaConfigurationEnabled` for the saved administrator setting.
  Deprecate `Survey.captchaEnabled` for submission decisions; legacy API
  payloads remain supported. The deprecated property is scheduled for removal
  in 1.0.0.

## 0.2.1

- Expose reply counts on survey responses so admin clients can identify
  responses with existing replies.
- Expose each individual answer's response locale for localized response
  translation.

## 0.2.0

- Add support for changing the signed-in administrator's password.
- Add Groq as a configurable AI provider.

## 0.1.1

- Accept an optional `captchaToken` on admin email login so clients can satisfy
  CAPTCHA challenges after repeated login failures.

## 0.1.0

- First public release.
- Add survey, admin, anonymous-account, response, reply, and configuration API
  support for Form Concierge Workers deployments.
