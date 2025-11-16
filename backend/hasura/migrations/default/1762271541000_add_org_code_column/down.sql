-- Rollback: Remove organization code column

DROP INDEX IF EXISTS idx_organizations_code;

ALTER TABLE organizations
DROP COLUMN IF EXISTS code;
