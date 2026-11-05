## 0.4.0

- Configure administrator email notifications while creating a survey. Reuse the
  latest recipient from the same project, then fall back to the latest recipient
  across projects; enable notifications when an address is available.
- Hide the recipient field while notifications are disabled and retain its value
  when notifications are enabled again.
- Configure question visibility rules before saving a new survey. The first
  question is always visible; later questions can depend on earlier questions.
- Preserve the selected all/any visibility match mode through draft editing
  and saving.
- Describe AI follow-up support across Flutter, SwiftUI, UIKit, and Android
  Compose as an in-app feature.
- Update navigation, UI, and other dependencies and refresh platform build settings.

## 0.3.0

- Preserve the saved CAPTCHA setting when surveys are loaded, edited, and
  updated independently of the deployment's runtime CAPTCHA availability.

## 0.2.1

- Show reply counts and existing reply history alongside survey responses.
- Translate individual text answers while preserving their detected source
  locales across response refreshes.
- Add a manual refresh action to the responses page.
- Rename GenUI follow-up wording to AI follow-ups in every supported locale.

## 0.2.0

- Add an account page and allow the signed-in administrator to change their
  password.
- Add Groq AI provider configuration.
- Improve project and survey action layouts and clear stale form values when
  creating a new survey.
- Add account-related translations for every supported locale.

## 0.1.1

- Add a Turnstile challenge to administrator login after repeated failures.
- Improve survey question editing, scrolling, and published-state restrictions.

## 0.1.0

- First public release.
- Add localized administration for projects, surveys, questions, responses,
  replies, user accounts, and integration settings.
- Add AI-assisted survey generation, adaptive follow-up configuration, image
  answers, email notifications, custom domains, and Turnstile settings.
