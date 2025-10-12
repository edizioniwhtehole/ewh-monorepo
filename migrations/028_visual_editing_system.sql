-- Visual Editing System with Multi-Level Overrides
-- Supports: Installation > Tenant > Tenant Group > Global > Hardcoded

-- =====================================================
-- 1. Permissions System
-- =====================================================

CREATE TABLE IF NOT EXISTS cms.visual_editing_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES auth.organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Scope of editing permission
  scope TEXT CHECK (scope IN ('tenant', 'tenant_group', 'global', 'installation')) DEFAULT 'tenant',

  -- Granular permissions
  can_edit_components BOOLEAN DEFAULT false,
  can_edit_layouts BOOLEAN DEFAULT false,
  can_edit_themes BOOLEAN DEFAULT false,
  can_edit_branding BOOLEAN DEFAULT false,

  -- Filtering by tenant groups (if scope = 'tenant_group')
  allowed_tenant_groups UUID[] DEFAULT ARRAY[]::UUID[],

  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, tenant_id)
);

CREATE INDEX idx_visual_editing_permissions_user ON cms.visual_editing_permissions(user_id);
CREATE INDEX idx_visual_editing_permissions_tenant ON cms.visual_editing_permissions(tenant_id);

-- =====================================================
-- 2. Component Overrides with Multi-Level Support
-- =====================================================

CREATE TABLE IF NOT EXISTS cms.component_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Component identifier (e.g., 'ShellLayout', 'Button', 'TopBar')
  component_key TEXT NOT NULL,

  -- Override scope (determines precedence)
  override_scope TEXT CHECK (override_scope IN ('installation', 'tenant', 'tenant_group', 'global')) NOT NULL,

  -- Scope identifiers
  installation_id TEXT, -- For on-premise installations
  tenant_id UUID REFERENCES auth.organizations(id) ON DELETE CASCADE,
  tenant_group_id UUID REFERENCES auth.tenant_groups(id) ON DELETE CASCADE,

  -- The actual override data (JSON)
  override_data JSONB NOT NULL,

  -- Metadata
  version INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure only one override per component + scope + identifier
  UNIQUE(component_key, override_scope, installation_id, tenant_id, tenant_group_id),

  -- Constraints: only one scope identifier should be set
  CHECK (
    (override_scope = 'installation' AND installation_id IS NOT NULL AND tenant_id IS NULL AND tenant_group_id IS NULL) OR
    (override_scope = 'tenant' AND tenant_id IS NOT NULL AND installation_id IS NULL AND tenant_group_id IS NULL) OR
    (override_scope = 'tenant_group' AND tenant_group_id IS NOT NULL AND installation_id IS NULL AND tenant_id IS NULL) OR
    (override_scope = 'global' AND installation_id IS NULL AND tenant_id IS NULL AND tenant_group_id IS NULL)
  )
);

-- Indexes for fast lookup with precedence
CREATE INDEX idx_component_overrides_lookup ON cms.component_overrides(component_key, override_scope, is_active);
CREATE INDEX idx_component_overrides_installation ON cms.component_overrides(installation_id) WHERE installation_id IS NOT NULL;
CREATE INDEX idx_component_overrides_tenant ON cms.component_overrides(tenant_id) WHERE tenant_id IS NOT NULL;
CREATE INDEX idx_component_overrides_tenant_group ON cms.component_overrides(tenant_group_id) WHERE tenant_group_id IS NOT NULL;

-- =====================================================
-- 3. Audit Log for Override Changes
-- =====================================================

CREATE TABLE IF NOT EXISTS cms.component_override_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  override_id UUID REFERENCES cms.component_overrides(id) ON DELETE CASCADE,
  component_key TEXT NOT NULL,
  override_scope TEXT NOT NULL,

  -- Snapshot of data before change
  old_data JSONB,
  new_data JSONB,

  -- Who made the change
  changed_by UUID REFERENCES auth.users(id),
  change_reason TEXT,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_component_override_history_override ON cms.component_override_history(override_id);
CREATE INDEX idx_component_override_history_component ON cms.component_override_history(component_key);

-- =====================================================
-- 4. Helper Function: Get Component Props with Cascade
-- =====================================================

CREATE OR REPLACE FUNCTION cms.get_component_props(
  p_component_key TEXT,
  p_installation_id TEXT DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB := '{}'::JSONB;
  v_tenant_groups UUID[];
BEGIN
  -- Get tenant groups for this tenant
  IF p_tenant_id IS NOT NULL THEN
    SELECT ARRAY_AGG(tg.id)
    INTO v_tenant_groups
    FROM auth.tenant_groups tg
    JOIN auth.tenant_group_members tgm ON tg.id = tgm.group_id
    WHERE tgm.tenant_id = p_tenant_id;
  END IF;

  -- Build result by cascading (reverse order - most general to most specific)
  -- Each level overrides the previous one

  -- 1. Global overrides (base level)
  SELECT COALESCE(v_result, '{}'::JSONB) || override_data
  INTO v_result
  FROM cms.component_overrides
  WHERE component_key = p_component_key
    AND override_scope = 'global'
    AND is_active = true
  LIMIT 1;

  -- 2. Tenant Group overrides (if tenant belongs to groups)
  IF v_tenant_groups IS NOT NULL THEN
    SELECT COALESCE(v_result, '{}'::JSONB) || override_data
    INTO v_result
    FROM cms.component_overrides
    WHERE component_key = p_component_key
      AND override_scope = 'tenant_group'
      AND tenant_group_id = ANY(v_tenant_groups)
      AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;
  END IF;

  -- 3. Tenant-specific overrides
  IF p_tenant_id IS NOT NULL THEN
    SELECT COALESCE(v_result, '{}'::JSONB) || override_data
    INTO v_result
    FROM cms.component_overrides
    WHERE component_key = p_component_key
      AND override_scope = 'tenant'
      AND tenant_id = p_tenant_id
      AND is_active = true
    LIMIT 1;
  END IF;

  -- 4. Installation-specific overrides (highest priority)
  IF p_installation_id IS NOT NULL THEN
    SELECT COALESCE(v_result, '{}'::JSONB) || override_data
    INTO v_result
    FROM cms.component_overrides
    WHERE component_key = p_component_key
      AND override_scope = 'installation'
      AND installation_id = p_installation_id
      AND is_active = true
    LIMIT 1;
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. Sample Data for Testing
-- =====================================================

-- Grant tenant admin the ability to edit components for their tenant
DO $$
DECLARE
  v_tenant_id UUID;
  v_user_id UUID;
BEGIN
  -- Get first tenant and user for demo
  SELECT id INTO v_tenant_id FROM auth.organizations LIMIT 1;
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;

  IF v_tenant_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    INSERT INTO cms.visual_editing_permissions (
      tenant_id, user_id, scope,
      can_edit_components, can_edit_layouts, can_edit_themes
    ) VALUES (
      v_tenant_id, v_user_id, 'tenant',
      true, true, true
    ) ON CONFLICT (user_id, tenant_id) DO NOTHING;

    RAISE NOTICE 'Visual editing permissions granted to user % for tenant %', v_user_id, v_tenant_id;
  END IF;
END $$;

COMMENT ON TABLE cms.visual_editing_permissions IS 'Controls who can edit visual components and at what scope level';
COMMENT ON TABLE cms.component_overrides IS 'Stores component customizations with multi-level cascade support';
COMMENT ON TABLE cms.component_override_history IS 'Audit trail of all component override changes';
COMMENT ON FUNCTION cms.get_component_props IS 'Retrieves final component props by applying cascade: Installation > Tenant > Tenant Group > Global';
