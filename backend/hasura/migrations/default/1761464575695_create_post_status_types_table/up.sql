-- Create post_status_types lookup table (instead of ENUM)
CREATE TABLE post_status_types (
  value TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  sort_order INT NOT NULL
);

-- Insert initial values
INSERT INTO post_status_types (value, label, sort_order) VALUES
  ('draft', 'øM', 1),
  ('published', 'l‹', 2),
  ('archived', '¢ü«¤Ö', 3);

-- Add comment
COMMENT ON TABLE post_status_types IS 'Lookup table for post statuses (replaces PostgreSQL ENUM for flexibility)';
