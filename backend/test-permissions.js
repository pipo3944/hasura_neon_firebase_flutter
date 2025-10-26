#!/usr/bin/env node
/**
 * Test Hasura permissions with different user roles using JWT
 */

const jwt = require('jsonwebtoken');

const JWT_SECRET = 'local-development-secret-key-please-change-in-production-this-is-only-for-testing';
const HASURA_ENDPOINT = process.env.HASURA_ENDPOINT || 'http://localhost:8080/v1/graphql';

// Generate JWT token
function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { algorithm: 'HS256', expiresIn: '1h' });
}

// Execute GraphQL query
async function executeQuery(token, query) {
  const response = await fetch(HASURA_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({ query })
  });
  return response.json();
}

// Test users
const testUsers = {
  'user-bob': {
    sub: 'aaaaaaaa-0002-0002-0002-000000000002',
    'https://hasura.io/jwt/claims': {
      'x-hasura-allowed-roles': ['user'],
      'x-hasura-default-role': 'user',
      'x-hasura-user-id': 'aaaaaaaa-0002-0002-0002-000000000002',
      'x-hasura-tenant-id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    }
  },
  'tenant-admin-alice': {
    sub: 'aaaaaaaa-0001-0001-0001-000000000001',
    'https://hasura.io/jwt/claims': {
      'x-hasura-allowed-roles': ['tenant_admin', 'user'],
      'x-hasura-default-role': 'tenant_admin',
      'x-hasura-user-id': 'aaaaaaaa-0001-0001-0001-000000000001',
      'x-hasura-tenant-id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    }
  },
  'user-diana': {
    sub: 'bbbbbbbb-0002-0002-0002-000000000002',
    'https://hasura.io/jwt/claims': {
      'x-hasura-allowed-roles': ['user'],
      'x-hasura-default-role': 'user',
      'x-hasura-user-id': 'bbbbbbbb-0002-0002-0002-000000000002',
      'x-hasura-tenant-id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    }
  },
  'admin': {
    sub: '00000000-0000-0000-0000-000000000000',
    'https://hasura.io/jwt/claims': {
      'x-hasura-allowed-roles': ['admin', 'tenant_admin', 'user'],
      'x-hasura-default-role': 'admin',
      'x-hasura-user-id': '00000000-0000-0000-0000-000000000000',
      'x-hasura-tenant-id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    }
  }
};

async function runTests() {
  console.log('==================================================');
  console.log('Hasura Permission Tests');
  console.log('==================================================\n');

  // Test 1: User role (Bob)
  console.log('==================================================');
  console.log('Test 1: User Role (Bob - Acme Corp)');
  console.log('Expected: Only Bob\'s posts (5 posts, excluding soft-deleted)');
  console.log('==================================================');

  const bobToken = generateToken(testUsers['user-bob']);
  const bobResult = await executeQuery(bobToken, `
    { posts(where: {deleted_at: {_is_null: true}}) { id title user { name } } }
  `);

  if (bobResult.data && bobResult.data.posts) {
    console.log(`✅ Bob can see ${bobResult.data.posts.length} posts:`);
    bobResult.data.posts.forEach(post => {
      const userName = post.user ? post.user.name : 'N/A';
      console.log(`  - ${post.title} by ${userName}`);
    });
  } else {
    console.log('❌ Error:', bobResult.errors);
  }
  console.log('');

  // Test 2: Tenant admin role (Alice)
  console.log('==================================================');
  console.log('Test 2: Tenant Admin Role (Alice - Acme Corp)');
  console.log('Expected: All Acme Corp posts including soft-deleted (7 total)');
  console.log('==================================================');

  const aliceToken = generateToken(testUsers['tenant-admin-alice']);
  const aliceResult = await executeQuery(aliceToken, `
    { posts { id title deleted_at user { name } } }
  `);

  if (aliceResult.data && aliceResult.data.posts) {
    console.log(`✅ Alice (tenant_admin) can see ${aliceResult.data.posts.length} posts:`);
    aliceResult.data.posts.forEach(post => {
      const deleted = post.deleted_at ? ' (DELETED)' : '';
      const userName = post.user ? post.user.name : 'N/A';
      console.log(`  - ${post.title} by ${userName}${deleted}`);
    });
  } else {
    console.log('❌ Error:', aliceResult.errors);
  }
  console.log('');

  // Test 3: Cross-tenant check (Diana)
  console.log('==================================================');
  console.log('Test 3: User Role - Cross-Tenant Check (Diana - Beta Inc)');
  console.log('Expected: Only Diana\'s posts (3 posts), NO Acme Corp data');
  console.log('==================================================');

  const dianaToken = generateToken(testUsers['user-diana']);
  const dianaResult = await executeQuery(dianaToken, `
    { posts(where: {deleted_at: {_is_null: true}}) { id title organization { name } user { name } } }
  `);

  if (dianaResult.data && dianaResult.data.posts) {
    console.log(`✅ Diana can see ${dianaResult.data.posts.length} posts:`);
    dianaResult.data.posts.forEach(post => {
      const userName = post.user ? post.user.name : 'N/A';
      const orgName = post.organization ? post.organization.name : 'N/A';
      console.log(`  - ${post.title} by ${userName} (${orgName})`);
    });
  } else {
    console.log('❌ Error:', dianaResult.errors);
  }
  console.log('');

  // Test 4: Admin role
  console.log('==================================================');
  console.log('Test 4: Admin Role (System Admin)');
  console.log('Expected: All posts from all tenants (13 total including soft-deleted)');
  console.log('==================================================');

  const adminToken = generateToken(testUsers['admin']);
  const adminResult = await executeQuery(adminToken, `
    { posts { id title organization { name } deleted_at } }
  `);

  if (adminResult.data && adminResult.data.posts) {
    console.log(`✅ Admin can see ${adminResult.data.posts.length} posts across all tenants:`);
    adminResult.data.posts.forEach(post => {
      const deleted = post.deleted_at ? ' (DELETED)' : '';
      const orgName = post.organization ? post.organization.name : 'N/A';
      console.log(`  - ${post.title} (${orgName})${deleted}`);
    });
  } else {
    console.log('❌ Error:', adminResult.errors);
  }
  console.log('');

  // Test 5: User isolation check
  console.log('==================================================');
  console.log('Test 5: User trying to access another user\'s data');
  console.log('Expected: Bob should NOT see Alice\'s posts');
  console.log('==================================================');

  const bobIsolationResult = await executeQuery(bobToken, `
    { posts(where: {user_id: {_eq: "aaaaaaaa-0001-0001-0001-000000000001"}, deleted_at: {_is_null: true}}) { id title user { name } } }
  `);

  if (bobIsolationResult.data && bobIsolationResult.data.posts) {
    if (bobIsolationResult.data.posts.length === 0) {
      console.log('✅ Bob correctly CANNOT see Alice\'s posts (isolation working)');
    } else {
      console.log('❌ PERMISSION ERROR: Bob can see Alice\'s posts!');
      bobIsolationResult.data.posts.forEach(post => {
        const userName = post.user ? post.user.name : 'N/A';
        console.log(`  - ${post.title} by ${userName}`);
      });
    }
  } else {
    console.log('❌ Error:', bobIsolationResult.errors);
  }
  console.log('');

  console.log('==================================================');
  console.log('All Permission Tests Complete!');
  console.log('==================================================');
}

runTests().catch(console.error);
