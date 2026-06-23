# Form Concierge

Survey forms backed by Cloudflare Workers and D1. Respondents use generated anonymous accounts for reply access without email login. Submitted answers plus optional per-response device info and metadata stay server-side for admins; anonymous users can fetch admin replies, not answer history.

## Project Structure

| Directory | Description |
|-----------|-------------|
| `worker/` | Cloudflare Workers API and D1 migrations |
| `client/` | Dart REST client shared by Flutter apps and Jaspr |
| `admin_dashboard/` | Flutter admin dashboard |
| `widget/` | Flutter package for embedding surveys |
| `swiftui/` | Swift Package for embedding surveys in SwiftUI apps |
| `web/` | Jaspr web survey form |
| `examples/` | Example apps demonstrating package usage |

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

Run the setup script to create or reuse Cloudflare D1, R2, Workers, and Pages resources:

```bash
./setup.sh
```

The script checks required local tools and Wrangler authentication before creating resources. To run only those checks:

```bash
./setup.sh --preflight-only
```

After deployment, open the admin Pages URL, create the first admin, and create projects in the deployed dashboard.

Seeding an existing local project is optional:

```bash
./setup.sh --list-local-projects
./setup.sh --seed-project-id <project-id>
```

## Verification

Useful checks:

```bash
cd worker && npm run typecheck
cd worker && npm run d1:migrate:local
cd client && dart analyze
cd web && dart analyze && jaspr build
cd widget && flutter analyze
cd admin_dashboard && flutter analyze && flutter test
cd swiftui && swift build
```
