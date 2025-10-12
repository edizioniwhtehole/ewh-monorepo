-- Authentication & RBAC System
-- Complete user authentication and role-based access control

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (auth.users already exists in svc-auth, we use cms.users for CMS-specific data)
CREATE TABLE IF NOT EXISTS cms.users (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  avatar_url TEXT,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted')),
  email_verified BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMP,
  last_login_at TIMESTAMP,
  login_count INTEGER DEFAULT 0,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Refresh Tokens for JWT
CREATE TABLE IF NOT EXISTS cms.refresh_tokens (
  token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES cms.users(user_id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  revoked BOOLEAN DEFAULT false,
  revoked_at TIMESTAMP
);

-- Roles
CREATE TABLE IF NOT EXISTS cms.roles (
  role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) UNIQUE NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  is_system BOOLEAN DEFAULT false, -- System roles cannot be deleted
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Permissions
CREATE TABLE IF NOT EXISTS cms.permissions (
  permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) UNIQUE NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  resource VARCHAR(100) NOT NULL, -- sites, posts, pages, domains, plugins, etc.
  action VARCHAR(50) NOT NULL, -- create, read, update, delete, publish, manage
  created_at TIMESTAMP DEFAULT NOW()
);

-- Role-Permission mapping (many-to-many)
CREATE TABLE IF NOT EXISTS cms.role_permissions (
  role_id UUID REFERENCES cms.roles(role_id) ON DELETE CASCADE,
  permission_id UUID REFERENCES cms.permissions(permission_id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- User-Role mapping with tenant context (many-to-many)
CREATE TABLE IF NOT EXISTS cms.user_roles (
  user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES cms.users(user_id) ON DELETE CASCADE,
  role_id UUID REFERENCES cms.roles(role_id) ON DELETE CASCADE,
  tenant_id VARCHAR(255), -- NULL for global roles
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, role_id, tenant_id)
);

-- User-Permission overrides (for exceptions)
CREATE TABLE IF NOT EXISTS cms.user_permissions (
  user_permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES cms.users(user_id) ON DELETE CASCADE,
  permission_id UUID REFERENCES cms.permissions(permission_id) ON DELETE CASCADE,
  tenant_id VARCHAR(255), -- NULL for global permissions
  granted BOOLEAN NOT NULL, -- true = grant, false = revoke
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, permission_id, tenant_id)
);

-- Password reset tokens
CREATE TABLE IF NOT EXISTS cms.password_reset_tokens (
  token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES cms.users(user_id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Email verification tokens
CREATE TABLE IF NOT EXISTS cms.email_verification_tokens (
  token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES cms.users(user_id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON cms.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON cms.users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON cms.users(status);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON cms.refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON cms.refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON cms.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant_id ON cms.user_roles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON cms.user_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_permissions_resource ON cms.permissions(resource);

-- Update trigger
CREATE OR REPLACE FUNCTION cms.update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_modtime
  BEFORE UPDATE ON cms.users
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_users_updated_at();

CREATE TRIGGER update_roles_modtime
  BEFORE UPDATE ON cms.roles
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_users_updated_at();

-- Insert default roles
INSERT INTO cms.roles (name, display_name, description, is_system) VALUES
  ('super_admin', 'Super Admin', 'Full access across all tenants', true),
  ('tenant_admin', 'Tenant Admin', 'Full access within tenant', true),
  ('editor', 'Editor', 'Can edit and publish content', true),
  ('author', 'Author', 'Can create and edit own content', true),
  ('contributor', 'Contributor', 'Can create content but not publish', true),
  ('viewer', 'Viewer', 'Read-only access', true)
ON CONFLICT (name) DO NOTHING;

-- Insert default permissions
INSERT INTO cms.permissions (name, display_name, description, resource, action) VALUES
  -- Sites
  ('sites.create', 'Create Sites', 'Can create new sites', 'sites', 'create'),
  ('sites.read', 'View Sites', 'Can view sites', 'sites', 'read'),
  ('sites.update', 'Update Sites', 'Can update sites', 'sites', 'update'),
  ('sites.delete', 'Delete Sites', 'Can delete sites', 'sites', 'delete'),
  ('sites.publish', 'Publish Sites', 'Can publish/unpublish sites', 'sites', 'publish'),
  ('sites.manage', 'Manage Sites', 'Full site management', 'sites', 'manage'),

  -- Posts
  ('posts.create', 'Create Posts', 'Can create new posts', 'posts', 'create'),
  ('posts.read', 'View Posts', 'Can view posts', 'posts', 'read'),
  ('posts.update', 'Update Posts', 'Can update posts', 'posts', 'update'),
  ('posts.delete', 'Delete Posts', 'Can delete posts', 'posts', 'delete'),
  ('posts.publish', 'Publish Posts', 'Can publish posts', 'posts', 'publish'),
  ('posts.manage', 'Manage Posts', 'Full post management', 'posts', 'manage'),

  -- Pages
  ('pages.create', 'Create Pages', 'Can create new pages', 'pages', 'create'),
  ('pages.read', 'View Pages', 'Can view pages', 'pages', 'read'),
  ('pages.update', 'Update Pages', 'Can update pages', 'pages', 'update'),
  ('pages.delete', 'Delete Pages', 'Can delete pages', 'pages', 'delete'),
  ('pages.publish', 'Publish Pages', 'Can publish pages', 'pages', 'publish'),
  ('pages.manage', 'Manage Pages', 'Full page management', 'pages', 'manage'),

  -- Domains
  ('domains.create', 'Add Domains', 'Can add domains', 'domains', 'create'),
  ('domains.read', 'View Domains', 'Can view domains', 'domains', 'read'),
  ('domains.update', 'Update Domains', 'Can update domains', 'domains', 'update'),
  ('domains.delete', 'Remove Domains', 'Can remove domains', 'domains', 'delete'),
  ('domains.manage', 'Manage Domains', 'Full domain management', 'domains', 'manage'),

  -- Plugins
  ('plugins.read', 'View Plugins', 'Can view plugins', 'plugins', 'read'),
  ('plugins.activate', 'Activate Plugins', 'Can activate plugins', 'plugins', 'activate'),
  ('plugins.install', 'Install Plugins', 'Can install plugins', 'plugins', 'install'),
  ('plugins.manage', 'Manage Plugins', 'Full plugin management', 'plugins', 'manage'),

  -- Templates
  ('templates.create', 'Create Templates', 'Can create templates', 'templates', 'create'),
  ('templates.read', 'View Templates', 'Can view templates', 'templates', 'read'),
  ('templates.update', 'Update Templates', 'Can update templates', 'templates', 'update'),
  ('templates.delete', 'Delete Templates', 'Can delete templates', 'templates', 'delete'),
  ('templates.manage', 'Manage Templates', 'Full template management', 'templates', 'manage'),

  -- Media
  ('media.upload', 'Upload Media', 'Can upload media files', 'media', 'create'),
  ('media.read', 'View Media', 'Can view media', 'media', 'read'),
  ('media.update', 'Update Media', 'Can update media', 'media', 'update'),
  ('media.delete', 'Delete Media', 'Can delete media', 'media', 'delete'),
  ('media.manage', 'Manage Media', 'Full media management', 'media', 'manage'),

  -- Users
  ('users.create', 'Create Users', 'Can create users', 'users', 'create'),
  ('users.read', 'View Users', 'Can view users', 'users', 'read'),
  ('users.update', 'Update Users', 'Can update users', 'users', 'update'),
  ('users.delete', 'Delete Users', 'Can delete users', 'users', 'delete'),
  ('users.manage', 'Manage Users', 'Full user management', 'users', 'manage'),

  -- Settings
  ('settings.read', 'View Settings', 'Can view settings', 'settings', 'read'),
  ('settings.update', 'Update Settings', 'Can update settings', 'settings', 'update'),
  ('settings.manage', 'Manage Settings', 'Full settings management', 'settings', 'manage')
ON CONFLICT (name) DO NOTHING;

-- Assign permissions to roles
DO $$
DECLARE
  v_super_admin_id UUID;
  v_tenant_admin_id UUID;
  v_editor_id UUID;
  v_author_id UUID;
  v_contributor_id UUID;
  v_viewer_id UUID;
BEGIN
  -- Get role IDs
  SELECT role_id INTO v_super_admin_id FROM cms.roles WHERE name = 'super_admin';
  SELECT role_id INTO v_tenant_admin_id FROM cms.roles WHERE name = 'tenant_admin';
  SELECT role_id INTO v_editor_id FROM cms.roles WHERE name = 'editor';
  SELECT role_id INTO v_author_id FROM cms.roles WHERE name = 'author';
  SELECT role_id INTO v_contributor_id FROM cms.roles WHERE name = 'contributor';
  SELECT role_id INTO v_viewer_id FROM cms.roles WHERE name = 'viewer';

  -- Super Admin: ALL permissions
  INSERT INTO cms.role_permissions (role_id, permission_id)
  SELECT v_super_admin_id, permission_id FROM cms.permissions
  ON CONFLICT DO NOTHING;

  -- Tenant Admin: ALL permissions except cross-tenant
  INSERT INTO cms.role_permissions (role_id, permission_id)
  SELECT v_tenant_admin_id, permission_id FROM cms.permissions
  ON CONFLICT DO NOTHING;

  -- Editor: manage posts, pages, media
  INSERT INTO cms.role_permissions (role_id, permission_id)
  SELECT v_editor_id, permission_id FROM cms.permissions
  WHERE resource IN ('posts', 'pages', 'media', 'templates') AND action IN ('create', 'read', 'update', 'delete', 'publish')
  ON CONFLICT DO NOTHING;

  -- Author: create and edit own posts/pages
  INSERT INTO cms.role_permissions (role_id, permission_id)
  SELECT v_author_id, permission_id FROM cms.permissions
  WHERE resource IN ('posts', 'pages', 'media') AND action IN ('create', 'read', 'update')
  ON CONFLICT DO NOTHING;

  -- Contributor: create content, view media
  INSERT INTO cms.role_permissions (role_id, permission_id)
  SELECT v_contributor_id, permission_id FROM cms.permissions
  WHERE resource IN ('posts', 'pages') AND action = 'create'
     OR resource = 'media' AND action = 'read'
  ON CONFLICT DO NOTHING;

  -- Viewer: read-only
  INSERT INTO cms.role_permissions (role_id, permission_id)
  SELECT v_viewer_id, permission_id FROM cms.permissions
  WHERE action = 'read'
  ON CONFLICT DO NOTHING;
END $$;

-- Comments
COMMENT ON TABLE cms.users IS 'CMS users with authentication';
COMMENT ON TABLE cms.roles IS 'User roles for RBAC';
COMMENT ON TABLE cms.permissions IS 'Granular permissions for resources';
COMMENT ON TABLE cms.role_permissions IS 'Role-Permission mapping';
COMMENT ON TABLE cms.user_roles IS 'User-Role assignment with tenant context';
COMMENT ON TABLE cms.user_permissions IS 'User-specific permission overrides';
