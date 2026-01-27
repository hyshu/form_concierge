# Serverpod CLI Commands

## Project

Create new project: `serverpod create <project>`
Create Mini version: `serverpod create <project> --mini`
Create module: `serverpod create --template module <name>`
Check version: `serverpod version`

## Code Generation

Generate code: `serverpod generate`
Watch mode: `serverpod generate --watch`
Enable experimental features: `serverpod generate --experimental-features=all`

## Migration

Create migration: `serverpod create-migration`
Force create: `serverpod create-migration --force`
With tag: `serverpod create-migration --tag "v1-0-0"`

## Repair Migration

Create repair migration: `serverpod create-repair-migration`
For production DB: `serverpod create-repair-migration --mode production`
Target specific version: `serverpod create-repair-migration --version <migration-name>`
Force create: `serverpod create-repair-migration --force`
With tag: `serverpod create-repair-migration --tag "name"`

## Server

Start server: `dart run bin/main.dart`
Apply migrations on start: `dart run bin/main.dart --apply-migrations`
Apply repair migration: `dart run bin/main.dart --apply-repair-migration`
Maintenance mode: `dart run bin/main.dart --role maintenance --apply-migrations`

## Custom Scripts

Run script: `serverpod run <script>`
List scripts: `serverpod run --list`

## Docker

Start: `docker compose up`
Start in background: `docker compose up -d`
Stop: `docker compose down`
Remove volumes: `docker compose down -v`

## Serverpod Cloud (scloud)

Deploy: `scloud deploy`
Launch new project: `scloud launch`
Set variable: `scloud variable set <name> <value>`
Set secret: `scloud secret set <name> <value>`
List domains: `scloud domain list`
Add custom domain: `scloud domain add <domain>`
