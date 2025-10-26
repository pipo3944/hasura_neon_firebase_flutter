-- Create posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' REFERENCES post_status_types(value),
  slug TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES users(id),
  updated_by UUID NOT NULL REFERENCES users(id),
  deleted_at TIMESTAMPTZ,

  -- Unique constraint: slug must be unique within tenant (excluding deleted)
  CONSTRAINT posts_tenant_slug_unique UNIQUE (tenant_id, slug)
);

-- Create indexes
CREATE INDEX idx_posts_tenant_id ON posts(tenant_id);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- Composite index for common query pattern (tenant + status + created_at)
CREATE INDEX idx_posts_tenant_status_created
  ON posts(tenant_id, status, created_at DESC)
  WHERE deleted_at IS NULL;

-- Create trigger for updated_at
CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE posts IS 'Blog posts or similar content';
COMMENT ON COLUMN posts.slug IS 'URL-friendly identifier (unique within tenant)';
COMMENT ON COLUMN posts.status IS 'Post status: draft, published, or archived';
