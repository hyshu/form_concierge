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

## Form Concierge packages (publish_to: none, v0.1.0)

| Dir | Package |
|-----|---------|
| `client/` | `form_concierge_client` |
| `widget/` | `form_concierge` |
| `cli/` | `form_concierge_cli` |

```bash
cd cli && dart pub get
dart run form_concierge_cli doctor
dart run form_concierge_cli setup cloudflare --preflight-only
dart run form_concierge_cli setup cloudflare   # same as ./setup.sh
```

## Flutter

Admin dashboard:

```bash
cd admin_dashboard
flutter run -d chrome
```

Example app:

```bash
cd examples/flutter_mobile_simple
flutter run
```

## SwiftUI Package

Build:

```bash
cd swiftui
swift build
```
