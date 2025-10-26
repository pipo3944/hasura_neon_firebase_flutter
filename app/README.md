# Flutter App

This is the Flutter application for the Hasura + Firebase verification project.

## Setup

### Prerequisites

- Flutter SDK 3.10+
- Firebase CLI
- Hasura GraphQL endpoint (dev or prod)

### Environment Configuration

1. Copy environment files:
   ```bash
   cp .env.dev.example .env.dev
   cp .env.prod.example .env.prod
   ```

2. Fill in the actual values in `.env.dev` and `.env.prod`

### Running the App

**Dev environment**:
```bash
flutter run \
  --dart-define=HASURA_ENDPOINT=https://hasura-dev.example.com/v1/graphql \
  --dart-define=FIREBASE_PROJECT_ID=myproject-dev \
  --dart-define=ENV=dev
```

**Prod environment**:
```bash
flutter run \
  --dart-define=HASURA_ENDPOINT=https://hasura.example.com/v1/graphql \
  --dart-define=FIREBASE_PROJECT_ID=myproject-prod \
  --dart-define=ENV=prod
```

### GraphQL Code Generation

1. Create `.graphql` files in `graphql/` directory:
   ```graphql
   # graphql/users.graphql
   query GetUsers {
     users {
       id
       email
       name
     }
   }
   ```

2. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Use the generated code:
   ```dart
   import 'package:app/generated/users.graphql.dart';

   final result = await client.query$GetUsers();
   final users = result.parsedData?.users ?? [];
   ```

## Project Structure

```
app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── config/
│   │   └── environment.dart   # Environment configuration
│   ├── services/
│   │   ├── auth_service.dart  # Firebase Auth
│   │   └── graphql_client.dart # GraphQL client setup
│   └── generated/             # Auto-generated files (gitignored)
├── graphql/                   # GraphQL query definitions
└── pubspec.yaml               # Dependencies
```

## Next Steps

See the main [README](../README.md) for overall project documentation.
