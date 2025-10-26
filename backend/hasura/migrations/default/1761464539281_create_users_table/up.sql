-- Create users table (synced with Firebase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY,  -- Firebase UID (will be UUID format)
  tenant_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'user',  -- 'user' | 'admin'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  deleted_at TIMESTAMPTZ
);

-- Create indexes
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_role ON users(role);

-- Create trigger for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE users IS 'Users synced from Firebase Auth with app-specific profile data';
COMMENT ON COLUMN users.id IS 'Firebase Auth UID';
COMMENT ON COLUMN users.tenant_id IS 'Organization the user belongs to';
COMMENT ON COLUMN users.role IS 'User role: user or admin';
