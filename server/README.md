# form_concierge_server

Serverpod backend server for Form Concierge.

## Prerequisites

- Dart SDK ^3.6.0
- Docker
- Serverpod CLI: `dart pub global activate serverpod_cli`

## Setup

1. Install dependencies:

   ```bash
   dart pub get
   ```

2. Start PostgreSQL and Redis:

   ```bash
   docker compose up -d
   ```

3. Generate Serverpod code (run after model changes):

   ```bash
   serverpod generate
   ```

4. Start the server with migrations:

   ```bash
   dart run bin/main.dart --apply-migrations
   ```

## Stop Services

```bash
docker compose down
```

To also remove database volumes:

```bash
docker compose down -v
```

## Email Testing (MailHog)

1. Add the following to `config/passwords.yaml`:

   ```yaml
   development:
     smtpHost: 'localhost'
     smtpPort: '1025'
     smtpUsername: ''
     smtpPassword: ''
     smtpFromEmail: 'noreply@localhost'
     smtpFromName: 'Form Concierge'
   ```

2. Start MailHog:

   ```bash
   docker run -p 1025:1025 -p 8025:8025 mailhog/mailhog
   ```

3. View sent emails at http://localhost:8025

## Gemini API (Optional)

Adding a Gemini API key enables AI features:

- AI-generated survey question suggestions
- AI summary of survey responses

Add to `config/passwords.yaml`:

```yaml
development:
  geminiApiKey: 'your-api-key'
```
