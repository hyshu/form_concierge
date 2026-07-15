# Form Concierge

Survey forms backed by Cloudflare Workers and D1. Respondents use generated anonymous accounts for reply access without email login. Submitted answers plus optional per-response device info and metadata stay server-side for admins; anonymous users can fetch admin replies, not answer history.

## Project Structure

| Directory | Package / role | Description |
|-----------|----------------|-------------|
| `worker/` | (deployed API) | Cloudflare Workers API and D1 migrations |
| `client/` | `form_concierge_client` `0.2.1` | Published Dart REST client shared by Flutter apps and Jaspr |
| `widget/` | `form_concierge` `0.2.1` | Published Flutter package for embedding surveys |
| `cli/` | `form_concierge_cli` `0.2.1` | Published setup / doctor CLI (`form_concierge setup cloudflare`) |
| `admin_dashboard/` | app `0.2.1` | Flutter admin dashboard |
| `apple/` | SPM | Swift Package for embedding surveys in SwiftUI and UIKit apps |
| `web/` | app | Jaspr web survey form |
| `widget/examples/` | apps | Full example apps demonstrating widget package usage |

The Dart client, Flutter widget, and setup CLI are pub.dev packages. Apps and
deployment templates remain source distributions.

The Apple package can be added with Swift Package Manager from
`https://github.com/hyshu/form_concierge.git`. The root `Package.swift` exposes
the `FormConciergeSwiftUI` and `FormConciergeUIKit` library products.

## Package Release

Publish the client before the widget because `form_concierge` depends on
`form_concierge_client`. Before publishing the CLI, push the matching version
tag and wait for the release-template workflow to attach the archive and
checksum:

```bash
cd client
dart pub publish --dry-run
dart pub publish

cd ../widget
flutter pub publish --dry-run
flutter pub publish

cd ..
git tag v0.2.1
git push origin v0.2.1

cd cli
dart pub publish --dry-run
dart pub publish
```

Review every file listed by each dry run before confirming an upload. Published
versions cannot be deleted; fixes require a new version.

## Local Development

### Prerequisites

- Dart SDK / Flutter
- Node.js
- Wrangler CLI via `npm install` in `worker/`
- Jaspr CLI: `dart pub global activate jaspr_cli 0.23.1`

### Setup

1. Start the Workers API:

   ```bash
   cd worker
   npm install
   npm run d1:migrate:local
   npm run dev
   ```

2. Create the first admin at `POST http://localhost:8787/api/admin/bootstrap` or open the admin dashboard and use first-user registration.

3. Run the admin dashboard:

   ```bash
   cd admin_dashboard
   flutter run -d chrome
   ```

4. Run the Jaspr survey web app:

   ```bash
   cd web
   FORM_CONCIERGE_API_URL=http://localhost:8787 jaspr serve --port 8000
   ```

## Cloudflare Deployment

Use the Dart CLI to create or reuse Cloudflare D1, R2, Workers, and Pages resources:

```bash
cd cli && dart pub get
dart run form_concierge_cli setup cloudflare
```

The command checks required local tools and Wrangler authentication before creating resources. To run only those checks:

```bash
dart run form_concierge_cli setup cloudflare --preflight-only
```

After deployment, open the admin Pages URL, create the first admin, and create projects in the deployed dashboard.

### Public cost controls

Setup configures daily D1 quotas for responses (account/IP/survey), image upload and retained R2 bytes, AI follow-up generation (account/survey), and notification email (survey). AI generation uses an atomic lease so concurrent requests for one response cannot fan out into multiple provider calls. Unattached uploads expire after 24 hours; the Worker cron removes them every 15 minutes.

The defaults are written to `worker/wrangler.jsonc` as `QUOTA_*` variables and may be lowered before deployment. Quota changes take effect on the next Worker deployment.

Seeding an existing local project is optional:

```bash
dart run form_concierge_cli setup cloudflare --list-local-projects
dart run form_concierge_cli setup cloudflare --seed-project-id <project-id>
```

## Verification

Useful checks:

```bash
cd worker && npm run typecheck
cd worker && npm run d1:migrate:local
cd client && dart analyze
cd widget && flutter analyze
cd cli && dart analyze && dart test
cd web && dart analyze && jaspr build
cd admin_dashboard && flutter analyze && flutter test
cd apple && swift build
xcodebuild -scheme FormConciergeUIKit \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

### CLI (monorepo)

```bash
cd cli && dart pub get
dart run form_concierge_cli doctor
dart run form_concierge_cli setup cloudflare --preflight-only
dart run form_concierge_cli setup cloudflare
```
