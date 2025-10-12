-- Advanced Custom Fields (ACF) System
-- WordPress-style flexible custom field system

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Field Groups: Collections of custom fields
CREATE TABLE IF NOT EXISTS cms.acf_field_groups (
  field_group_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  key VARCHAR(255) UNIQUE NOT NULL, -- Unique identifier like 'group_homepage'
  description TEXT,
  location JSONB NOT NULL DEFAULT '[]'::jsonb, -- Rules for where this group appears
  menu_order INTEGER DEFAULT 0,
  position VARCHAR(50) DEFAULT 'normal', -- 'normal', 'side', 'acf_after_title'
  style VARCHAR(50) DEFAULT 'default', -- 'default', 'seamless'
  label_placement VARCHAR(50) DEFAULT 'top', -- 'top', 'left'
  instruction_placement VARCHAR(50) DEFAULT 'label', -- 'label', 'field'
  hide_on_screen JSONB DEFAULT '[]'::jsonb, -- Array of elements to hide
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Fields: Individual custom fields
CREATE TABLE IF NOT EXISTS cms.acf_fields (
  field_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_group_id UUID REFERENCES cms.acf_field_groups(field_group_id) ON DELETE CASCADE,
  parent_field_id UUID REFERENCES cms.acf_fields(field_id) ON DELETE CASCADE, -- For nested fields
  label VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL, -- Field name/key like 'hero_title'
  type VARCHAR(50) NOT NULL, -- text, textarea, number, email, url, password, image, file, wysiwyg, select, checkbox, radio, true_false, date_picker, color_picker, etc.
  instructions TEXT,
  required BOOLEAN DEFAULT false,
  conditional_logic JSONB DEFAULT '[]'::jsonb,
  wrapper JSONB DEFAULT '{}'::jsonb, -- width, class, id
  default_value TEXT,
  placeholder TEXT,
  prepend TEXT,
  append TEXT,
  formatting VARCHAR(50), -- For wysiwyg: 'html' or 'text'
  maxlength INTEGER,
  readonly BOOLEAN DEFAULT false,
  disabled BOOLEAN DEFAULT false,
  choices JSONB DEFAULT '{}'::jsonb, -- For select/checkbox/radio
  allow_null BOOLEAN DEFAULT true,
  multiple BOOLEAN DEFAULT false,
  ui BOOLEAN DEFAULT false,
  ajax BOOLEAN DEFAULT false,
  return_format VARCHAR(50), -- For various field types
  layout VARCHAR(50), -- For repeater/flexible_content
  min INTEGER,
  max INTEGER,
  button_label VARCHAR(255),
  collapsed VARCHAR(255),
  menu_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Field Values: Actual data stored for each field
CREATE TABLE IF NOT EXISTS cms.acf_field_values (
  value_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_id UUID REFERENCES cms.acf_fields(field_id) ON DELETE CASCADE,
  post_id UUID REFERENCES cms.posts(post_id) ON DELETE CASCADE, -- Can also reference pages, etc.
  value TEXT, -- JSON for complex fields
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(field_id, post_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_acf_field_groups_key ON cms.acf_field_groups(key);
CREATE INDEX IF NOT EXISTS idx_acf_field_groups_active ON cms.acf_field_groups(active);
CREATE INDEX IF NOT EXISTS idx_acf_fields_group_id ON cms.acf_fields(field_group_id);
CREATE INDEX IF NOT EXISTS idx_acf_fields_name ON cms.acf_fields(name);
CREATE INDEX IF NOT EXISTS idx_acf_fields_parent ON cms.acf_fields(parent_field_id);
CREATE INDEX IF NOT EXISTS idx_acf_field_values_field_id ON cms.acf_field_values(field_id);
CREATE INDEX IF NOT EXISTS idx_acf_field_values_post_id ON cms.acf_field_values(post_id);

-- Update triggers
CREATE OR REPLACE FUNCTION cms.update_acf_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_acf_field_groups_modtime
  BEFORE UPDATE ON cms.acf_field_groups
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_acf_updated_at_column();

CREATE TRIGGER update_acf_fields_modtime
  BEFORE UPDATE ON cms.acf_fields
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_acf_updated_at_column();

CREATE TRIGGER update_acf_field_values_modtime
  BEFORE UPDATE ON cms.acf_field_values
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_acf_updated_at_column();

-- Comments
COMMENT ON TABLE cms.acf_field_groups IS 'ACF field groups - collections of custom fields';
COMMENT ON TABLE cms.acf_fields IS 'ACF field definitions';
COMMENT ON TABLE cms.acf_field_values IS 'ACF field values stored per post/page';
COMMENT ON COLUMN cms.acf_field_groups.location IS 'JSON array of location rules defining where this group appears';
COMMENT ON COLUMN cms.acf_fields.type IS 'Field type: text, textarea, number, email, url, password, image, file, wysiwyg, select, checkbox, radio, true_false, date_picker, color_picker, repeater, flexible_content, etc.';
COMMENT ON COLUMN cms.acf_fields.conditional_logic IS 'JSON array of conditional display rules';
