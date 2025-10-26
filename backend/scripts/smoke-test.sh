#!/bin/bash
set -e

ENDPOINT="${HASURA_GRAPHQL_ENDPOINT:-http://localhost:8080}"
ADMIN_SECRET="${HASURA_GRAPHQL_ADMIN_SECRET}"

echo "🧪 Running smoke tests against: $ENDPOINT"
echo ""

# 1. Health Check
echo "1️⃣  Health Check..."
if curl -f "${ENDPOINT}/healthz" > /dev/null 2>&1; then
  echo "   ✅ Health check passed"
else
  echo "   ❌ Health check failed"
  exit 1
fi

# 2. GraphQL Introspection
echo "2️⃣  GraphQL Introspection..."
QUERY='{"query": "{ __schema { queryType { name } } }"}'
RESPONSE=$(curl -s -X POST "$ENDPOINT/v1/graphql" \
  -H "Content-Type: application/json" \
  -H "x-hasura-admin-secret: $ADMIN_SECRET" \
  -d "$QUERY")

if echo "$RESPONSE" | grep -q "query_root"; then
  echo "   ✅ GraphQL introspection passed"
else
  echo "   ❌ GraphQL introspection failed"
  echo "   Response: $RESPONSE"
  exit 1
fi

# 3. Anonymous Role Query (should fail or return limited data)
echo "3️⃣  Anonymous role test..."
QUERY='{"query": "{ __typename }"}'
RESPONSE=$(curl -s -X POST "$ENDPOINT/v1/graphql" \
  -H "Content-Type: application/json" \
  -d "$QUERY")

if echo "$RESPONSE" | grep -q "query_root"; then
  echo "   ✅ Anonymous role can query __typename"
else
  echo "   ⚠️  Anonymous role might be restricted"
fi

# 4. Admin Role Query
echo "4️⃣  Admin role test..."
QUERY='{"query": "{ __typename }"}'
RESPONSE=$(curl -s -X POST "$ENDPOINT/v1/graphql" \
  -H "Content-Type: application/json" \
  -H "x-hasura-admin-secret: $ADMIN_SECRET" \
  -d "$QUERY")

if echo "$RESPONSE" | grep -q "query_root"; then
  echo "   ✅ Admin role query passed"
else
  echo "   ❌ Admin role query failed"
  echo "   Response: $RESPONSE"
  exit 1
fi

echo ""
echo "🎉 All smoke tests passed!"
echo ""
