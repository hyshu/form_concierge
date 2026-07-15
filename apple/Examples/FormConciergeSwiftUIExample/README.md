# FormConciergeSwiftUIExample

Minimal iOS Form Concierge example, matching the flow of `widget/examples/flutter_mobile_simple`.

The app opens `FormConciergeSurveyView` from a simple home screen. The form route closes from `onDone`, not `onSubmitted`, so adaptive follow-up questions remain available after the main response is saved.

The default configuration targets a local Worker and placeholder slugs:

- API: `http://localhost:8787`
- Project slug: `example-project`
- Survey slug: `example-survey`

Open `FormConciergeSwiftUIExample.xcodeproj`, select a simulator, and run the `FormConciergeSwiftUIExample` scheme.

Override configuration with scheme environment variables:

- `FORM_CONCIERGE_API_URL`
- `FORM_CONCIERGE_PROJECT_SLUG`
- `FORM_CONCIERGE_SURVEY_SLUG`
- `FORM_CONCIERGE_SURVEY_ID`
- `FORM_CONCIERGE_TURNSTILE_BASE_URL`

When the selected survey requires CAPTCHA, set `FORM_CONCIERGE_TURNSTILE_BASE_URL` to a hostname allowed by the configured Turnstile widget. The example intentionally does not persist anonymous sessions or add app localization.
