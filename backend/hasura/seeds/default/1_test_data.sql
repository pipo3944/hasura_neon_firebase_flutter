-- =============================================================================
-- Seed Data for Development/Testing
-- =============================================================================
-- This file contains test data for local development and testing.
-- Run with: hasura seed apply --database-name default
--
-- Data includes:
-- - 2 Organizations (Acme Corp, Beta Inc)
-- - 5 Users (1 admin, 2 tenant_admins, 2 users)
-- - 3 Post status types (draft, published, archived)
-- - 13 Posts (various statuses, some soft-deleted)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Post Status Types (Lookup Table)
-- -----------------------------------------------------------------------------
-- Note: These are already created by migration, but we ensure they exist
-- No need to insert here as they're already in the migration file

-- -----------------------------------------------------------------------------
-- 2. Organizations (Tenants)
-- -----------------------------------------------------------------------------
INSERT INTO organizations (id, name, slug, code) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Acme Corp', 'acme-corp', 'ACME2024'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Beta Inc', 'beta-inc', 'BETA2024')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3. Users
-- -----------------------------------------------------------------------------
-- Note: users.id is the Firebase UID (TEXT), tenant_id is required (NOT NULL)
-- For admin users, we'll assign them to a default tenant

-- Acme Corp users
INSERT INTO users (id, tenant_id, email, name, role) VALUES
  ('aaaaaaaa-0001-0001-0001-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin@acme.com', 'Alice (Acme Admin)', 'tenant_admin'),
  ('aaaaaaaa-0002-0002-0002-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bob@acme.com', 'Bob (Acme User)', 'user')
ON CONFLICT (id) DO NOTHING;

-- Beta Inc users
INSERT INTO users (id, tenant_id, email, name, role) VALUES
  ('bbbbbbbb-0001-0001-0001-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'admin@beta.com', 'Charlie (Beta Admin)', 'tenant_admin'),
  ('bbbbbbbb-0002-0002-0002-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'diana@beta.com', 'Diana (Beta User)', 'user')
ON CONFLICT (id) DO NOTHING;

-- System Admin (assigned to Acme for testing purposes)
INSERT INTO users (id, tenant_id, email, name, role) VALUES
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin@example.com', 'System Admin', 'admin')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 4. Posts
-- -----------------------------------------------------------------------------
-- Acme Corp posts (by Bob)
INSERT INTO posts (id, tenant_id, user_id, title, content, status, slug, created_by, updated_by) VALUES
  ('aaaaaaaa-1111-1111-1111-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0002-0002-0002-000000000002', 'Getting Started with Flutter', 'This is a comprehensive guide to Flutter development...', 'published', 'getting-started-with-flutter', 'aaaaaaaa-0002-0002-0002-000000000002', 'aaaaaaaa-0002-0002-0002-000000000002'),
  ('aaaaaaaa-1111-1111-1111-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0002-0002-0002-000000000002', 'GraphQL Best Practices', 'Here are some best practices for GraphQL API design...', 'published', 'graphql-best-practices', 'aaaaaaaa-0002-0002-0002-000000000002', 'aaaaaaaa-0002-0002-0002-000000000002'),
  ('aaaaaaaa-1111-1111-1111-000000000003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0002-0002-0002-000000000002', 'Draft: Future Features', 'Planning document for upcoming features...', 'draft', 'future-features', 'aaaaaaaa-0002-0002-0002-000000000002', 'aaaaaaaa-0002-0002-0002-000000000002'),
  ('aaaaaaaa-1111-1111-1111-000000000004', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0002-0002-0002-000000000002', 'Old Post (Archived)', 'This post is no longer relevant...', 'archived', 'old-post-archived', 'aaaaaaaa-0002-0002-0002-000000000002', 'aaaaaaaa-0002-0002-0002-000000000002'),
  ('aaaaaaaa-1111-1111-1111-000000000005', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0002-0002-0002-000000000002', 'Deleted Post', 'This post has been soft-deleted...', 'published', 'deleted-post', 'aaaaaaaa-0002-0002-0002-000000000002', 'aaaaaaaa-0002-0002-0002-000000000002')
ON CONFLICT (id) DO NOTHING;

-- Acme Corp posts (by Alice - tenant_admin)
INSERT INTO posts (id, tenant_id, user_id, title, content, status, slug, created_by, updated_by) VALUES
  ('aaaaaaaa-2222-2222-2222-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0001-0001-0001-000000000001', 'Company Announcement', 'Important company-wide announcement...', 'published', 'company-announcement', 'aaaaaaaa-0001-0001-0001-000000000001', 'aaaaaaaa-0001-0001-0001-000000000001'),
  ('aaaaaaaa-2222-2222-2222-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-0001-0001-0001-000000000001', 'Draft: Q4 Planning', 'Internal planning document...', 'draft', 'q4-planning', 'aaaaaaaa-0001-0001-0001-000000000001', 'aaaaaaaa-0001-0001-0001-000000000001')
ON CONFLICT (id) DO NOTHING;

-- Beta Inc posts (by Diana)
INSERT INTO posts (id, tenant_id, user_id, title, content, status, slug, created_by, updated_by) VALUES
  ('bbbbbbbb-1111-1111-1111-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-0002-0002-0002-000000000002', 'Introduction to PostgreSQL', 'PostgreSQL is a powerful database system...', 'published', 'introduction-to-postgresql', 'bbbbbbbb-0002-0002-0002-000000000002', 'bbbbbbbb-0002-0002-0002-000000000002'),
  ('bbbbbbbb-1111-1111-1111-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-0002-0002-0002-000000000002', 'Hasura Tips and Tricks', 'Useful tips for working with Hasura...', 'published', 'hasura-tips-and-tricks', 'bbbbbbbb-0002-0002-0002-000000000002', 'bbbbbbbb-0002-0002-0002-000000000002'),
  ('bbbbbbbb-1111-1111-1111-000000000003', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-0002-0002-0002-000000000002', 'Work in Progress', 'Still writing this article...', 'draft', 'work-in-progress', 'bbbbbbbb-0002-0002-0002-000000000002', 'bbbbbbbb-0002-0002-0002-000000000002')
ON CONFLICT (id) DO NOTHING;

-- Beta Inc posts (by Charlie - tenant_admin)
INSERT INTO posts (id, tenant_id, user_id, title, content, status, slug, created_by, updated_by) VALUES
  ('bbbbbbbb-2222-2222-2222-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-0001-0001-0001-000000000001', 'Team Guidelines', 'Guidelines for team collaboration...', 'published', 'team-guidelines', 'bbbbbbbb-0001-0001-0001-000000000001', 'bbbbbbbb-0001-0001-0001-000000000001'),
  ('bbbbbbbb-2222-2222-2222-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-0001-0001-0001-000000000001', 'Archived: Old Guidelines', 'These guidelines are outdated...', 'archived', 'old-guidelines', 'bbbbbbbb-0001-0001-0001-000000000001', 'bbbbbbbb-0001-0001-0001-000000000001'),
  ('bbbbbbbb-2222-2222-2222-000000000003', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bbbbbbbb-0001-0001-0001-000000000001', 'Deleted: Confidential', 'This was deleted for privacy reasons...', 'published', 'confidential', 'bbbbbbbb-0001-0001-0001-000000000001', 'bbbbbbbb-0001-0001-0001-000000000001')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 5. Soft Deletes (for testing deleted_at filtering)
-- -----------------------------------------------------------------------------
UPDATE posts SET deleted_at = NOW() WHERE id = 'aaaaaaaa-1111-1111-1111-000000000005';
UPDATE posts SET deleted_at = NOW() WHERE id = 'bbbbbbbb-2222-2222-2222-000000000003';

-- =============================================================================
-- Summary of Test Data
-- =============================================================================
-- Organizations: 2 (Acme Corp, Beta Inc)
-- Users: 5
--   - 1 admin (no tenant)
--   - 2 tenant_admins (1 per org)
--   - 2 users (1 per org)
-- Posts: 13 total
--   - Acme Corp: 7 posts (5 by Bob, 2 by Alice), 1 soft-deleted
--   - Beta Inc: 6 posts (3 by Diana, 3 by Charlie), 1 soft-deleted
--   - Statuses: draft (4), published (7), archived (2)
--   - Soft-deleted: 2 posts
-- =============================================================================
