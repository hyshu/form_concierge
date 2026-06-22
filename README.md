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

1. Create a D1 database:

   ```bash
   cd worker
   npx wrangler d1 create form_concierge
   ```

2. Put the returned `database_id` into `worker/wrangler.jsonc`.

3. Apply migrations and deploy:

   ```bash
   npm run d1:migrate:remote
   npm run deploy
   ```

4. Point `admin_dashboard/assets/config.json` and `FORM_CONCIERGE_API_URL` at the deployed Worker URL.

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
