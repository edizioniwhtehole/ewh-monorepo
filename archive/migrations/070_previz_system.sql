-- =====================================================
-- EWH Pre-visualization System Database Schema
-- =====================================================
-- Description: 3D Scene planning, storyboarding, and pre-visualization
-- Version: 1.0.0
-- Date: 2025-01-15
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- SCENES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_scenes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Scene dimensions and units
    dimensions_x DECIMAL(10, 3) NOT NULL DEFAULT 10.0,
    dimensions_y DECIMAL(10, 3) NOT NULL DEFAULT 10.0,
    dimensions_z DECIMAL(10, 3) NOT NULL DEFAULT 10.0,
    units VARCHAR(20) NOT NULL DEFAULT 'metric', -- 'metric' or 'imperial'

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT scenes_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_scenes_tenant ON previz_scenes(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_scenes_project ON previz_scenes(project_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_scenes_created_by ON previz_scenes(created_by);

-- =====================================================
-- CHARACTERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scene_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'human', -- 'human', 'animal', 'robot', 'custom'
    preset VARCHAR(100), -- 'adult-male', 'adult-female', 'child', etc.

    -- Transform
    position_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    position_y DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    position_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_y DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    scale_x DECIMAL(10, 3) NOT NULL DEFAULT 1.0,
    scale_y DECIMAL(10, 3) NOT NULL DEFAULT 1.0,
    scale_z DECIMAL(10, 3) NOT NULL DEFAULT 1.0,

    -- Rig and appearance
    rig JSONB, -- Joint configuration
    appearance JSONB, -- Color, texture, material

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT characters_scene_fk FOREIGN KEY (scene_id) REFERENCES previz_scenes(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_characters_scene ON previz_characters(scene_id) WHERE deleted_at IS NULL;

-- =====================================================
-- PROPS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_props (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scene_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL, -- 'furniture', 'vehicle', 'electronics', etc.
    asset_id UUID, -- Reference to DAM asset

    -- Transform
    position_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    position_y DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    position_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_y DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    scale_x DECIMAL(10, 3) NOT NULL DEFAULT 1.0,
    scale_y DECIMAL(10, 3) NOT NULL DEFAULT 1.0,
    scale_z DECIMAL(10, 3) NOT NULL DEFAULT 1.0,

    -- Geometry
    geometry JSONB, -- Mesh data, vertices, faces, etc.

    -- AI Generation
    is_ai_generated BOOLEAN DEFAULT FALSE,
    generation_prompt TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT props_scene_fk FOREIGN KEY (scene_id) REFERENCES previz_scenes(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_props_scene ON previz_props(scene_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_props_category ON previz_props(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_props_ai ON previz_props(is_ai_generated) WHERE deleted_at IS NULL;

-- =====================================================
-- LIGHTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_lights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scene_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'point', 'spot', 'directional', 'area', 'ambient'

    -- Transform
    position_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    position_y DECIMAL(10, 3) NOT NULL DEFAULT 5.0,
    position_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_y DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,

    -- Light properties
    color VARCHAR(7) NOT NULL DEFAULT '#FFFFFF', -- Hex color
    intensity DECIMAL(5, 2) NOT NULL DEFAULT 1.0,
    range DECIMAL(10, 2), -- For point and spot lights
    angle DECIMAL(5, 2), -- For spot lights (degrees)
    cast_shadows BOOLEAN DEFAULT TRUE,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT lights_scene_fk FOREIGN KEY (scene_id) REFERENCES previz_scenes(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_lights_scene ON previz_lights(scene_id) WHERE deleted_at IS NULL;

-- =====================================================
-- CAMERAS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_cameras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scene_id UUID NOT NULL,
    shot_id UUID, -- Optional link to shot
    name VARCHAR(255) NOT NULL,

    -- Transform
    position_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    position_y DECIMAL(10, 3) NOT NULL DEFAULT 1.6,
    position_z DECIMAL(10, 3) NOT NULL DEFAULT 5.0,
    rotation_x DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_y DECIMAL(10, 3) NOT NULL DEFAULT 0.0,
    rotation_z DECIMAL(10, 3) NOT NULL DEFAULT 0.0,

    -- Lens
    focal_length DECIMAL(6, 2) NOT NULL DEFAULT 50.0, -- mm
    aperture DECIMAL(4, 2) NOT NULL DEFAULT 2.8, -- f-stop
    sensor_width DECIMAL(6, 2) NOT NULL DEFAULT 36.0, -- mm
    sensor_height DECIMAL(6, 2) NOT NULL DEFAULT 24.0, -- mm
    distortion DECIMAL(4, 2) DEFAULT 0.0,

    -- Settings
    iso INTEGER DEFAULT 400,
    shutter_speed DECIMAL(8, 4) DEFAULT 0.0208, -- 1/48 default for 24fps
    white_balance INTEGER DEFAULT 5600, -- Kelvin
    fov DECIMAL(5, 2) DEFAULT 45.0, -- Field of view
    aspect_ratio VARCHAR(10) DEFAULT '16:9',

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT cameras_scene_fk FOREIGN KEY (scene_id) REFERENCES previz_scenes(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_cameras_scene ON previz_cameras(scene_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_cameras_shot ON previz_cameras(shot_id) WHERE deleted_at IS NULL;

-- =====================================================
-- SHOTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_shots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scene_id UUID NOT NULL,
    storyboard_id UUID,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    shot_number VARCHAR(50) NOT NULL, -- e.g., 'S01', 'S02A', etc.
    duration DECIMAL(8, 2) NOT NULL DEFAULT 5.0, -- seconds
    camera_id UUID NOT NULL,

    -- Shot type
    shot_type VARCHAR(50) DEFAULT 'medium', -- 'wide', 'medium', 'close-up', etc.

    -- Camera movement
    movement JSONB, -- Movement type and keyframes

    -- Order in storyboard
    order_index INTEGER DEFAULT 0,

    -- Thumbnail
    thumbnail_url TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT shots_scene_fk FOREIGN KEY (scene_id) REFERENCES previz_scenes(id) ON DELETE CASCADE,
    CONSTRAINT shots_camera_fk FOREIGN KEY (camera_id) REFERENCES previz_cameras(id) ON DELETE RESTRICT
);

CREATE INDEX idx_previz_shots_scene ON previz_shots(scene_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_shots_storyboard ON previz_shots(storyboard_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_shots_order ON previz_shots(storyboard_id, order_index);

-- =====================================================
-- STORYBOARDS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_storyboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT storyboards_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_storyboards_tenant ON previz_storyboards(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_storyboards_project ON previz_storyboards(project_id) WHERE deleted_at IS NULL;

-- Add foreign key from shots to storyboards
ALTER TABLE previz_shots ADD CONSTRAINT shots_storyboard_fk
    FOREIGN KEY (storyboard_id) REFERENCES previz_storyboards(id) ON DELETE SET NULL;

-- =====================================================
-- PROP LIBRARY TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_library_props (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID, -- NULL for global/public library
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    tags TEXT[], -- Array of tags
    asset_id UUID NOT NULL, -- Reference to DAM
    geometry JSONB NOT NULL, -- Mesh data
    thumbnail_url TEXT,
    is_public BOOLEAN DEFAULT FALSE, -- Public library items available to all

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT library_props_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_library_tenant ON previz_library_props(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_library_category ON previz_library_props(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_library_public ON previz_library_props(is_public) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_library_tags ON previz_library_props USING GIN(tags);

-- =====================================================
-- AI GENERATION REQUESTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_ai_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    prompt TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'prop', 'character', 'scene'
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'

    -- Results
    result_id UUID, -- ID of generated asset/scene
    result_url TEXT,
    error TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT ai_requests_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_ai_tenant ON previz_ai_requests(tenant_id);
CREATE INDEX idx_previz_ai_user ON previz_ai_requests(user_id);
CREATE INDEX idx_previz_ai_status ON previz_ai_requests(status);
CREATE INDEX idx_previz_ai_type ON previz_ai_requests(type);

-- =====================================================
-- WEBHOOKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    url TEXT NOT NULL,
    events TEXT[] NOT NULL, -- Array of event names
    secret VARCHAR(255), -- For HMAC signing
    is_active BOOLEAN DEFAULT TRUE,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Audit
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT webhooks_tenant_fk FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_webhooks_tenant ON previz_webhooks(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_previz_webhooks_active ON previz_webhooks(is_active) WHERE deleted_at IS NULL;

-- =====================================================
-- WEBHOOK DELIVERIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS previz_webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID NOT NULL,
    event VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(50) NOT NULL, -- 'success', 'failed', 'retrying'
    response_code INTEGER,
    response_body TEXT,
    attempt INTEGER DEFAULT 1,

    -- Audit
    delivered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT deliveries_webhook_fk FOREIGN KEY (webhook_id) REFERENCES previz_webhooks(id) ON DELETE CASCADE
);

CREATE INDEX idx_previz_deliveries_webhook ON previz_webhook_deliveries(webhook_id);
CREATE INDEX idx_previz_deliveries_status ON previz_webhook_deliveries(status);
CREATE INDEX idx_previz_deliveries_event ON previz_webhook_deliveries(event);

-- =====================================================
-- UPDATED_AT TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_previz_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER previz_scenes_updated_at BEFORE UPDATE ON previz_scenes
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_characters_updated_at BEFORE UPDATE ON previz_characters
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_props_updated_at BEFORE UPDATE ON previz_props
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_lights_updated_at BEFORE UPDATE ON previz_lights
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_cameras_updated_at BEFORE UPDATE ON previz_cameras
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_shots_updated_at BEFORE UPDATE ON previz_shots
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_storyboards_updated_at BEFORE UPDATE ON previz_storyboards
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_library_props_updated_at BEFORE UPDATE ON previz_library_props
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

CREATE TRIGGER previz_webhooks_updated_at BEFORE UPDATE ON previz_webhooks
    FOR EACH ROW EXECUTE FUNCTION update_previz_updated_at();

-- =====================================================
-- SAMPLE DATA (Optional - for development)
-- =====================================================
-- Insert sample lighting presets
COMMENT ON TABLE previz_scenes IS 'Pre-visualization scenes for 3D planning and storyboarding';
COMMENT ON TABLE previz_characters IS 'Characters (humans, animals, etc.) in scenes';
COMMENT ON TABLE previz_props IS 'Props and objects in scenes';
COMMENT ON TABLE previz_lights IS 'Lights in scenes (point, spot, directional, etc.)';
COMMENT ON TABLE previz_cameras IS 'Virtual cameras for shot composition';
COMMENT ON TABLE previz_shots IS 'Individual shots in storyboards';
COMMENT ON TABLE previz_storyboards IS 'Collections of shots forming a storyboard';
COMMENT ON TABLE previz_library_props IS 'Reusable prop library (tenant-specific and public)';
COMMENT ON TABLE previz_ai_requests IS 'AI generation requests for props, characters, and scenes';
COMMENT ON TABLE previz_webhooks IS 'Webhook subscriptions for events';
COMMENT ON TABLE previz_webhook_deliveries IS 'Webhook delivery history';
