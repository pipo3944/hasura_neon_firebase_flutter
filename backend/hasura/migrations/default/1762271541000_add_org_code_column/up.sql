-- Add organization code column to organizations table
-- This code is used for organization signup/join flow

-- Step 1: Add column without UNIQUE constraint first
ALTER TABLE organizations
ADD COLUMN code VARCHAR(50);

-- Step 2: Update existing organizations with unique codes
UPDATE organizations
SET code = CASE
  WHEN id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' THEN 'ACME2024'
  WHEN id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' THEN 'BETA2024'
  ELSE UPPER(SUBSTRING(slug, 1, 4)) || '2024'
END
WHERE code IS NULL;

-- Step 3: Now add NOT NULL and UNIQUE constraints
ALTER TABLE organizations
ALTER COLUMN code SET NOT NULL;

ALTER TABLE organizations
ADD CONSTRAINT organizations_code_key UNIQUE (code);

-- Add comment
COMMENT ON COLUMN organizations.code IS 'Unique code for organization signup/join (e.g., ACME2024)';

-- Create index for faster lookups
CREATE INDEX idx_organizations_code ON organizations(code);
