-- ============================================================================
-- DAM Versioning System - Complete Asset Management
-- ============================================================================
-- Created: 2025-10-15
-- Purpose: Intelligent asset management with versioning and usage tracking
--
-- Features:
-- - Asset version history (v1, v2, v3, etc.)
-- - Live references (auto-update) vs Snapshot references (frozen)
-- - Cross-application usage tracking
-- - Impact analysis before updates
-- - Automatic synchronization for live references
-- ============================================================================

-- ============================================================================
-- 1. Main Assets Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- File metadata
  original_filename VARCHAR(500) NOT NULL,
  file_type VARCHAR(100) NOT NULL, -- 'image/jpeg', 'image/png', 'video/mp4', etc.
  mime_type VARCHAR(150),
  file_size_bytes BIGINT,

  -- Versioning
  current_version_id UUID, -- References asset_versions(id)
  version_count INTEGER DEFAULT 1,

  -- Organization
  folder_path VARCHAR(1000), -- '/clients/acme/logos'
  tags TEXT[], -- ['logo', 'brand', 'corporate']

  -- Metadata
  title VARCHAR(500),
  description TEXT,
  alt_text VARCHAR(1000), -- For accessibility

  -- Search optimization
  search_vector tsvector,

  -- Status
  is_archived BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,

  -- Audit
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID,
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ -- Soft delete
);

-- Indexes
CREATE INDEX idx_assets_tenant ON assets(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_folder ON assets(folder_path) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_file_type ON assets(file_type);
CREATE INDEX idx_assets_tags ON assets USING GIN(tags);
CREATE INDEX idx_assets_search ON assets USING GIN(search_vector);
CREATE INDEX idx_assets_created ON assets(created_at DESC);

-- ============================================================================
-- 2. Asset Versions Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS asset_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,

  -- Version info
  version_number INTEGER NOT NULL, -- 1, 2, 3, ...
  version_label VARCHAR(100), -- 'v1', 'final', 'approved', etc.
  is_current BOOLEAN DEFAULT false,

  -- Storage
  storage_path VARCHAR(1000) NOT NULL, -- '/assets/{uuid}/v2/image.jpg'
  cdn_url VARCHAR(1000), -- Full CDN URL
  thumbnail_url VARCHAR(1000),

  -- File metadata (can change per version)
  file_size_bytes BIGINT,
  width_px INTEGER,
  height_px INTEGER,
  duration_seconds DECIMAL(10, 2), -- For videos

  -- Processing
  processing_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
  processing_error TEXT,

  -- Change tracking
  change_notes TEXT, -- What changed in this version?
  replaced_version_id UUID REFERENCES asset_versions(id),

  -- Audit
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(asset_id, version_number)
);

-- Indexes
CREATE INDEX idx_versions_asset ON asset_versions(asset_id);
CREATE INDEX idx_versions_current ON asset_versions(asset_id, is_current) WHERE is_current = true;
CREATE INDEX idx_versions_created ON asset_versions(created_at DESC);

-- Add foreign key constraint from assets to asset_versions (now that asset_versions exists)
ALTER TABLE assets
ADD CONSTRAINT fk_current_version FOREIGN KEY (current_version_id)
  REFERENCES asset_versions(id) ON DELETE SET NULL;

-- ============================================================================
-- 3. Asset Usages Table - Track where assets are used
-- ============================================================================
CREATE TABLE IF NOT EXISTS asset_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Asset reference
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  version_id UUID REFERENCES asset_versions(id) ON DELETE SET NULL,
  -- If version_id is NULL → Live reference (uses current version)
  -- If version_id is set → Snapshot reference (fixed version)

  reference_type VARCHAR(50) NOT NULL, -- 'live' | 'snapshot'

  -- Where is it used?
  app_id VARCHAR(100) NOT NULL, -- 'email-client', 'cms', 'page-builder', etc.
  entity_type VARCHAR(100) NOT NULL, -- 'email', 'document', 'page', 'template'
  entity_id UUID NOT NULL, -- ID of the email/document/page
  field_name VARCHAR(100), -- 'body', 'header_image', 'attachment'

  -- Context
  inserted_by UUID NOT NULL,
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Status
  is_active BOOLEAN DEFAULT true, -- false if removed from entity
  removed_at TIMESTAMPTZ,

  -- Sync tracking (for live references)
  last_synced_version_id UUID REFERENCES asset_versions(id),
  last_synced_at TIMESTAMPTZ,
  sync_status VARCHAR(50) -- 'synced', 'pending', 'failed'
);

-- Indexes
CREATE INDEX idx_usages_asset ON asset_usages(asset_id) WHERE is_active = true;
CREATE INDEX idx_usages_entity ON asset_usages(app_id, entity_type, entity_id) WHERE is_active = true;
CREATE INDEX idx_usages_reference_type ON asset_usages(reference_type) WHERE is_active = true;
CREATE INDEX idx_usages_live_pending ON asset_usages(asset_id, sync_status)
  WHERE reference_type = 'live' AND sync_status = 'pending';

-- Unique constraint: one active usage per asset+app+entity+field combination
CREATE UNIQUE INDEX idx_usages_unique_active
  ON asset_usages(asset_id, app_id, entity_type, entity_id, field_name)
  WHERE is_active = true;

-- ============================================================================
-- 4. Asset Update Logs - Audit trail
-- ============================================================================
CREATE TABLE IF NOT EXISTS asset_update_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  old_version_id UUID REFERENCES asset_versions(id),
  new_version_id UUID REFERENCES asset_versions(id),

  -- What happened?
  action VARCHAR(100) NOT NULL, -- 'version_created', 'version_promoted', 'usage_synced'

  -- Impact
  live_usages_count INTEGER DEFAULT 0, -- How many live refs were updated?
  snapshot_usages_count INTEGER DEFAULT 0,
  affected_apps TEXT[], -- ['email-client', 'cms']

  -- Details
  metadata JSONB, -- Additional context

  -- Audit
  performed_by UUID,
  performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_update_logs_asset ON asset_update_logs(asset_id);
CREATE INDEX idx_update_logs_performed ON asset_update_logs(performed_at DESC);

-- ============================================================================
-- 5. Update search vector trigger
-- ============================================================================
CREATE OR REPLACE FUNCTION update_asset_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.original_filename, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_asset_search ON assets;
CREATE TRIGGER trigger_update_asset_search
  BEFORE INSERT OR UPDATE ON assets
  FOR EACH ROW
  EXECUTE FUNCTION update_asset_search_vector();

-- ============================================================================
-- 6. Auto-promote latest version as current
-- ============================================================================
CREATE OR REPLACE FUNCTION promote_latest_version()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark all other versions as not current
  UPDATE asset_versions
  SET is_current = false
  WHERE asset_id = NEW.asset_id AND id != NEW.id;

  -- Mark this version as current
  NEW.is_current := true;

  -- Update asset's current_version_id and version_count
  UPDATE assets
  SET
    current_version_id = NEW.id,
    version_count = (SELECT COUNT(*) FROM asset_versions WHERE asset_id = NEW.asset_id),
    updated_at = NOW()
  WHERE id = NEW.asset_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_promote_latest_version ON asset_versions;
CREATE TRIGGER trigger_promote_latest_version
  BEFORE INSERT ON asset_versions
  FOR EACH ROW
  EXECUTE FUNCTION promote_latest_version();

-- ============================================================================
-- 7. Mark live usages for sync when new version created
-- ============================================================================
CREATE OR REPLACE FUNCTION mark_live_usages_pending()
RETURNS TRIGGER AS $$
BEGIN
  -- Only if this is a new current version
  IF NEW.is_current THEN
    -- Mark all live references as needing sync
    UPDATE asset_usages
    SET
      sync_status = 'pending',
      last_synced_at = NOW()
    WHERE
      asset_id = NEW.asset_id
      AND reference_type = 'live'
      AND is_active = true;

    -- Create update log
    INSERT INTO asset_update_logs (
      asset_id,
      old_version_id,
      new_version_id,
      action,
      live_usages_count,
      snapshot_usages_count,
      affected_apps,
      performed_by
    )
    SELECT
      NEW.asset_id,
      (SELECT id FROM asset_versions WHERE asset_id = NEW.asset_id AND version_number = NEW.version_number - 1),
      NEW.id,
      'version_created',
      COUNT(*) FILTER (WHERE reference_type = 'live'),
      COUNT(*) FILTER (WHERE reference_type = 'snapshot'),
      array_agg(DISTINCT app_id),
      NEW.created_by
    FROM asset_usages
    WHERE asset_id = NEW.asset_id AND is_active = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_mark_live_usages_pending ON asset_versions;
CREATE TRIGGER trigger_mark_live_usages_pending
  AFTER INSERT ON asset_versions
  FOR EACH ROW
  EXECUTE FUNCTION mark_live_usages_pending();

-- ============================================================================
-- 8. Helper Views
-- ============================================================================

-- Assets with current version details
CREATE OR REPLACE VIEW assets_with_current_version AS
SELECT
  a.*,
  av.version_number as current_version_number,
  av.version_label as current_version_label,
  av.cdn_url as current_cdn_url,
  av.thumbnail_url as current_thumbnail_url,
  av.file_size_bytes as current_file_size,
  av.width_px,
  av.height_px,
  (SELECT COUNT(*) FROM asset_usages WHERE asset_id = a.id AND is_active = true) as usage_count,
  (SELECT COUNT(*) FROM asset_usages WHERE asset_id = a.id AND is_active = true AND reference_type = 'live') as live_usage_count,
  (SELECT COUNT(*) FROM asset_usages WHERE asset_id = a.id AND is_active = true AND reference_type = 'snapshot') as snapshot_usage_count
FROM assets a
LEFT JOIN asset_versions av ON a.current_version_id = av.id
WHERE a.deleted_at IS NULL;

-- Asset usage summary by app
CREATE OR REPLACE VIEW asset_usage_by_app AS
SELECT
  asset_id,
  app_id,
  COUNT(*) as total_usages,
  COUNT(*) FILTER (WHERE reference_type = 'live') as live_usages,
  COUNT(*) FILTER (WHERE reference_type = 'snapshot') as snapshot_usages,
  array_agg(DISTINCT entity_type) as entity_types
FROM asset_usages
WHERE is_active = true
GROUP BY asset_id, app_id;

-- ============================================================================
-- 9. Sample Data (for testing)
-- ============================================================================

-- Sample data is commented out - add manually after migration if needed
-- The trigger system will automatically set current_version_id when versions are created

/*
-- Insert test asset (without current_version_id - will be set by trigger)
INSERT INTO assets (
  id,
  tenant_id,
  original_filename,
  file_type,
  mime_type,
  file_size_bytes,
  folder_path,
  tags,
  title,
  description,
  alt_text,
  created_by
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'company-logo.png',
  'image/png',
  'image/png',
  52480,
  '/brand/logos',
  ARRAY['logo', 'brand', 'corporate'],
  'Company Logo',
  'Official company logo for all marketing materials',
  'Company logo with blue gradient',
  '00000000-0000-0000-0000-000000000001'
);

-- Insert version 1 (trigger will mark as current and update assets table)
INSERT INTO asset_versions (
  id,
  asset_id,
  version_number,
  version_label,
  storage_path,
  cdn_url,
  thumbnail_url,
  file_size_bytes,
  width_px,
  height_px,
  processing_status,
  created_by
) VALUES (
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000001',
  1,
  'v1 - Original',
  '/assets/00000000-0000-0000-0000-000000000001/v1/company-logo.png',
  'https://cdn.example.com/assets/00000000-0000-0000-0000-000000000001/v1/company-logo.png',
  'https://cdn.example.com/assets/00000000-0000-0000-0000-000000000001/v1/thumb.jpg',
  52480,
  1200,
  800,
  'completed',
  '00000000-0000-0000-0000-000000000001'
);
*/

-- ============================================================================
-- 10. Permissions (optional - adjust based on your auth system)
-- ============================================================================

-- Grant permissions to authenticated users
-- GRANT SELECT, INSERT, UPDATE ON assets TO authenticated_users;
-- GRANT SELECT, INSERT ON asset_versions TO authenticated_users;
-- GRANT SELECT, INSERT, UPDATE ON asset_usages TO authenticated_users;
-- GRANT SELECT ON asset_update_logs TO authenticated_users;

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMENT ON TABLE assets IS 'Main assets table - stores metadata for all uploaded assets';
COMMENT ON TABLE asset_versions IS 'Version history - each upload creates a new version';
COMMENT ON TABLE asset_usages IS 'Usage tracking - records where each asset is used across apps';
COMMENT ON TABLE asset_update_logs IS 'Audit trail - logs all version updates and sync operations';

COMMENT ON COLUMN asset_usages.reference_type IS 'live = auto-updates to latest version, snapshot = frozen to specific version';
COMMENT ON COLUMN asset_usages.version_id IS 'NULL for live references (uses current), specific version ID for snapshots';
