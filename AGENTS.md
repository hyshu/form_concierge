# Repository Instructions

## Task Completion

After modifying source code, run the appropriate formatter for every changed
source file before completing the task.

# CLI Commands

## Cloudflare Workers

Install dependencies:

```bash
cd worker
npm install
```

Run locally:

```bash
npm run d1:migrate:local
npm run dev
```

Deploy:

```bash
npm run d1:migrate:remote
npm run deploy
```

Create D1 database:

```bash
npx wrangler d1 create form_concierge
```

Typecheck:

```bash
npm run typecheck
```

## Jaspr CLI

Install:

```bash
dart pub global activate jaspr_cli
```

Serve with hot-reload:

```bash
FORM_CONCIERGE_API_URL=http://localhost:8787 jaspr serve
```

Build:

```bash
jaspr build
```

## Form Concierge packages

| Dir | Package |
|-----|---------|
| `client/` | `form_concierge_client` |
| `widget/` | `form_concierge` |
| `cli/` | `form_concierge_cli` |

```bash
cd cli && dart pub get
dart run form_concierge_cli doctor
dart run form_concierge_cli setup cloudflare --preflight-only
dart run form_concierge_cli setup cloudflare
```

## Flutter

Admin dashboard:

```bash
cd admin_dashboard
flutter run -d chrome
```

Example app:

```bash
cd widget/examples/flutter_mobile_simple
flutter run
```

## Apple Swift Package

Build:

```bash
cd apple
swift build
```
