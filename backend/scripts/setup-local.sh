#!/bin/bash
set -e

echo "🚀 Setting up local development environment..."

# Check if .env exists
if [ ! -f "../.env" ]; then
  echo "📝 Creating .env from .env.example..."
  cp ../.env.example ../.env
  echo "⚠️  Please edit backend/.env and fill in the actual values"
  exit 1
fi

# Check if config.yaml exists
if [ ! -f "../hasura/config.yaml" ]; then
  echo "📝 Creating hasura/config.yaml from config.yaml.example..."
  cp ../hasura/config.yaml.example ../hasura/config.yaml
  echo "⚠️  Please edit backend/hasura/config.yaml and fill in the actual values"
  exit 1
fi

echo "🐳 Starting Docker containers..."
cd ..
docker compose up -d

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

echo "⏳ Waiting for Hasura to be ready..."
until curl -s http://localhost:8080/healthz > /dev/null 2>&1; do
  echo "   Still waiting for Hasura..."
  sleep 2
done

echo "✅ Hasura is ready!"

# Check if migrations exist
if [ -d "hasura/migrations" ] && [ "$(ls -A hasura/migrations)" ]; then
  echo "📦 Applying migrations..."
  cd hasura
  hasura migrate apply
  echo "✅ Migrations applied"
else
  echo "ℹ️  No migrations found. You can create them using 'hasura migrate create'"
fi

# Check if metadata exists
if [ -d "hasura/metadata" ] && [ "$(ls -A hasura/metadata)" ]; then
  echo "📦 Applying metadata..."
  cd hasura
  hasura metadata apply
  echo "✅ Metadata applied"
else
  echo "ℹ️  No metadata found. You can export it using 'hasura metadata export'"
fi

echo ""
echo "🎉 Local environment is ready!"
echo ""
echo "📍 Services:"
echo "   - Hasura Console: http://localhost:9695 (run 'hasura console' in backend/hasura/)"
echo "   - GraphQL Endpoint: http://localhost:8080/v1/graphql"
echo "   - PostgreSQL: localhost:5432"
echo "   - pgAdmin: http://localhost:5050"
echo ""
echo "📖 Next steps:"
echo "   1. cd backend/hasura"
echo "   2. hasura console"
echo "   3. Start developing!"
echo ""
