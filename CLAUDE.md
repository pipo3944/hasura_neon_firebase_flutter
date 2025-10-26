# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **verification project** for mobile app development using Hasura GraphQL Engine, Firebase Auth, Neon PostgreSQL, and Flutter. The goal is to establish and validate architecture patterns, not to build a production service.

**Tech Stack**:
- **Auth**: Firebase Auth (JWT issuance)
- **API**: Hasura GraphQL Engine (auto-generated GraphQL API + authorization)
- **DB**: Neon PostgreSQL (serverless, branch-based environment isolation)
- **Client**: Flutter
- **Infrastructure**: Cloud Run (Hasura hosting)
- **CI/CD**: GitHub Actions

## Environment Philosophy

Three distinct environments with clear purposes:
- **local**: Safe experimentation, migration creation, offline development (Docker Postgres + Hasura)
- **dev**: Integration testing, real device testing (Neon dev branch + Cloud Run)
- **prod**: Production (Neon main branch + Cloud Run, manual approval required)

**Firebase Projects**: Separate projects for dev (`myproject-dev`) and prod (`myproject-prod`)

## Core Commands

### Initial Setup
```bash
# Setup local environment (automated script)
cd backend
bash scripts/setup-local.sh

# Manual setup if needed
cp backend/.env.example backend/.env
cp backend/hasura/config.yaml.example backend/hasura/config.yaml
# Edit .env and config.yaml with actual values

docker compose up -d
cd hasura
hasura console  # Opens at http://localhost:9695
```

### Hasura Development Workflow

**🚨 CRITICAL: Two Different Consoles**

Hasura has TWO consoles - do NOT confuse them:

1. **`http://localhost:8080/console`** (Hasura server's built-in console)
   - ❌ Changes here do NOT generate migration files automatically
   - ⚠️ CAN be used if CLI console doesn't work (see below)
   - ✅ OK for: data inspection, GraphQL testing

2. **`http://localhost:9695`** (Hasura CLI console) - **IDEAL**
   - ✅ Changes here automatically generate migration files
   - ✅ Use for ALL schema changes, permissions, relationships
   - Launch with: `hasura console`

**Known Issue - CORS Error**:
In this project, the CLI console (`localhost:9695`) has CORS errors and doesn't work properly. Therefore, we use the following workflow:

**Actual Workflow (CORS Workaround)**:
1. Use `http://localhost:8080/console` for GUI operations (Track, Permissions)
2. Manually create migration files in `migrations/default/<timestamp>_name/`
3. Run `hasura metadata export` to save metadata
4. Commit both migrations and metadata to Git

This approach works just as well as the CLI console. See `docs/development-flow.md` and `docs/troubleshooting.md` for details.

**Ideal workflow (if CLI console works)**:
```bash
cd backend/hasura
hasura console  # Opens at localhost:9695
# Make changes in GUI → migrations/metadata auto-generated
git add migrations/ metadata/
git commit -m "Your changes"
```

**Actual workflow (CORS workaround - used in this project)**:
```bash
# 1. Open server console in browser
# Navigate to http://localhost:8080/console (enter admin_secret)

# 2. Make changes in GUI (Track tables, set permissions, etc.)

# 3. Manually create migration files
cd backend/hasura/migrations/default
mkdir $(date +%s)000_your_migration_name
# Create up.sql and down.sql manually

# 4. Export metadata
cd backend/hasura
hasura metadata export

# 5. Commit to Git
git add migrations/ metadata/
git commit -m "Your changes"
git push

# 6. Apply migrations (when pulling changes)
hasura migrate apply
hasura metadata apply

# 7. Apply seed data (test data)
hasura seed apply

# Rollback migrations
hasura migrate apply --down 1  # Rollback last migration
hasura migrate apply --goto <version>  # Rollback to specific version
```

### Testing

```bash
# Smoke test (used in CI/CD)
cd backend
export HASURA_GRAPHQL_ENDPOINT=http://localhost:8080
export HASURA_GRAPHQL_ADMIN_SECRET=your-admin-secret
bash scripts/smoke-test.sh
```

### Flutter Development

```bash
cd app

# Run with environment variables
flutter run \
  --dart-define=HASURA_ENDPOINT=https://hasura-dev.example.com/v1/graphql \
  --dart-define=FIREBASE_PROJECT_ID=myproject-dev \
  --dart-define=ENV=dev

# GraphQL code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### Docker Operations

```bash
cd backend

# Start services
docker compose up -d

# View logs
docker compose logs -f hasura
docker compose logs -f postgres

# Reset environment (DESTRUCTIVE - deletes all data)
docker compose down -v
docker compose up -d
cd hasura && hasura migrate apply && hasura metadata apply
```

## Architecture Principles

### Database Design

- **Primary Keys**: UUID v7 (time-ordered, initial implementation uses client-side generation via Dart `uuid` package)
- **Timestamps**: Always `TIMESTAMPTZ` in UTC (client handles timezone conversion)
- **Soft Delete**: Use `deleted_at TIMESTAMPTZ` column (never hard delete)
- **Enums**: Lookup tables (e.g., `post_status_types`) instead of PostgreSQL ENUMs (for flexibility)
- **Naming**: DB uses `snake_case`, GraphQL uses `camelCase` (Hasura auto-converts)
- **Audit Columns**: All tables include `created_at`, `updated_at`, `created_by`, `updated_by`
- **Multi-tenancy**: All tables include `tenant_id UUID` from day one (references `organizations` table)

### Authentication & Authorization

**Separation of Concerns**:
- **Firebase Auth**: Authentication only (issues JWT)
- **Hasura Permissions**: Authorization (row-level access control)

**JWT Flow**:
1. Firebase Auth issues JWT with custom claims (`role`, `tenant_id`)
2. Hasura verifies JWT using Firebase's JWK public keys
3. Hasura extracts claims into session variables (`X-Hasura-User-Id`, `X-Hasura-Tenant-Id`, `X-Hasura-Role`)
4. Permissions filter queries using these session variables

**Roles**:
- `anonymous` (unauthenticated)
- `user` (standard user - can only access their own data)
- `tenant_admin` (organization admin - can access all data within their tenant including soft-deleted records)
- `admin` (system admin - full access to all tenants)

**User Sync Strategy**: Client-triggered idempotent upsert on first login using `ON CONFLICT` (server-side sync via Cloud Functions is future enhancement)

### Migration Management

**One migration = One change**. Never combine multiple schema changes in a single migration.

**Always verify `up.sql` and `down.sql`**:
- `up.sql`: Forward migration
- `down.sql`: Rollback migration (must be carefully crafted, use `CASCADE` where needed)

**Separation**:
- **Migrations**: Database schema changes (tables, columns, indexes)
- **Metadata**: Hasura configuration (permissions, relationships, computed fields)

Both must be committed together when making schema changes.

### Multi-tenant Design

**All data tables include `tenant_id`** (except lookup tables and `organizations` itself).

**Hasura Permissions Examples**:

User role (own data only):
```json
{
  "filter": {
    "_and": [
      {"tenant_id": {"_eq": "X-Hasura-Tenant-Id"}},
      {"user_id": {"_eq": "X-Hasura-User-Id"}},
      {"deleted_at": {"_is_null": true}}
    ]
  }
}
```

Tenant admin role (all data in tenant including soft-deleted):
```json
{
  "filter": {
    "tenant_id": {"_eq": "X-Hasura-Tenant-Id"}
  }
}
```

Admin role (all data across all tenants):
```json
{
  "filter": {}
}
```

**Unique Constraints**: Scope to tenant (e.g., `UNIQUE (tenant_id, slug)` not just `UNIQUE (slug)`)

## File Structure Context

```
backend/
├── hasura/
│   ├── migrations/          # Timestamped SQL migrations (auto-generated from Console)
│   ├── metadata/            # Hasura config as YAML (permissions, relationships)
│   ├── seeds/               # Test/sample data
│   └── config.yaml          # Hasura CLI config (gitignored, use .example)
├── scripts/
│   ├── setup-local.sh       # Automated local environment setup
│   └── smoke-test.sh        # CI/CD health checks
└── docker-compose.yml       # Postgres + Hasura + pgAdmin

app/
├── graphql/                 # .graphql query definitions (for code generation)
├── lib/generated/           # Auto-generated Dart code (gitignored)
└── .env.dev.example         # Environment templates

docs/
├── architecture.md          # System diagrams (mermaid), component responsibilities
├── design-principles.md     # All design decisions with rationale
├── database-design.md       # ER diagram, table schemas, indexing strategy
├── authentication.md        # Auth flow diagrams, JWT config, role design
├── development-flow.md      # Local dev → migration → PR → deploy workflow
├── deployment.md            # CI/CD pipeline, GitHub Actions setup
├── troubleshooting.md       # Common errors and solutions (updated in production)
└── future-enhancements.md   # Neon preview branches, Actions, feature flags
```

## Development Workflow

1. **Local Development**: Make changes in Hasura Console (GUI at `localhost:9695`)
2. **Generate Migration**: `hasura migrate create --from-server "descriptive_name"`
3. **Export Metadata**: `hasura metadata export` (includes Track info, permissions, relationships)
4. **Commit**: `git add migrations/ metadata/` → commit → push
5. **CI (dev)**: GitHub Actions auto-applies to dev environment
6. **Test**: Real device testing against dev Cloud Run
7. **Production**: Manual approval → prod deployment

**NEVER skip the Hasura Console CLI step**. Direct database changes or using the web console without CLI will not be tracked in migrations.

### What is "Track"?

**Track** = Tell Hasura to recognize a PostgreSQL table and generate GraphQL API for it.

- PostgreSQL table exists → **Track** → GraphQL API available
- Without Track: table exists in DB but NOT accessible via GraphQL
- Track info is stored in metadata (`metadata/databases/default/tables/`)

**When to Track**:
- ✅ Console (GUI): Automatic when you create tables
- ✅ CLI/migration: Manual - run `hasura metadata export` after creating tables
- ❌ Team members pulling changes: No need - `hasura metadata apply` handles it

**Track all tables at once**:
```bash
hasura metadata reload  # Auto-tracks untracked tables
```

## GraphQL Code Generation (Flutter)

1. Define queries in `app/graphql/*.graphql`:
```graphql
query GetPosts($tenantId: uuid!) {
  posts(where: {tenant_id: {_eq: $tenantId}, deleted_at: {_is_null: true}}) {
    id
    title
    user { id name }
  }
}
```

2. Run: `flutter pub run build_runner build --delete-conflicting-outputs`

3. Generated files appear in `app/lib/generated/` with full type safety

## Deployment

**Dev**: Auto-deploys on push to `main` (if `backend/hasura/migrations/**` or `metadata/**` changed)

**Prod**: Manual GitHub Actions workflow trigger with confirmation step

Both run smoke tests after deployment:
- `/healthz` check
- GraphQL introspection
- Permission tests (anonymous/user/admin roles)

## Common Gotchas

1. **JWT Expiration**: Firebase ID tokens expire after 1 hour. Implement auto-refresh in Flutter using `idTokenChanges()` stream.

2. **Custom Claims Not Updating**: ID tokens are cached for 1 hour. Force refresh: `await user.getIdToken(true)`

3. **Migration Conflicts**: When multiple developers create migrations, timestamps can collide. Always `git pull` before creating new migrations.

4. **Hasura Console Access**: Must use `hasura console` CLI command, not direct browser access to `localhost:8080/console`

5. **Multi-tenant Data Leaks**: Always test permissions with different `tenant_id` values. Use Hasura Console's "Preview Permissions" feature.

6. **Soft Delete Queries**: Remember to add `deleted_at: {_is_null: true}` to all SELECT permissions

## When Making Changes

**Schema Changes**:
1. Use Hasura Console (via `hasura console`)
2. Generate migration immediately after
3. Export metadata
4. Commit both together

**Permission Changes** (metadata only):
1. Adjust in Hasura Console
2. `hasura metadata export`
3. Commit

**Rollback**:
- Migration: `hasura migrate apply --down 1`
- Emergency: Restore Neon snapshot via Neon console

## Documentation Navigation

- **Architecture questions**: See `docs/architecture.md`
- **Design decisions**: See `docs/design-principles.md`
- **DB schema questions**: See `docs/database-design.md`
- **Auth issues**: See `docs/authentication.md`
- **Deployment issues**: See `docs/deployment.md`
- **Errors**: See `docs/troubleshooting.md`

All architecture diagrams use mermaid syntax and are embedded in markdown files.
