-- Migration: CAD Drawings System
-- Creates tables for CAD drawings management
-- Date: 2025-10-16

-- CAD Drawings table
CREATE TABLE IF NOT EXISTS cad_drawings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  -- Drawing info
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Drawing data (JSONB for flexibility)
  data JSONB NOT NULL,

  -- Metadata (cached calculations)
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Thumbnail
  thumbnail_url TEXT,

  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP,

  -- Constraints
  CONSTRAINT fk_cad_drawings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_cad_drawings_tenant ON cad_drawings(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_cad_drawings_user ON cad_drawings(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_cad_drawings_created ON cad_drawings(created_at DESC);
CREATE INDEX idx_cad_drawings_updated ON cad_drawings(updated_at DESC);
CREATE INDEX idx_cad_drawings_name ON cad_drawings(name) WHERE deleted_at IS NULL;

-- Full-text search index on name and description
CREATE INDEX idx_cad_drawings_search ON cad_drawings USING GIN (
  to_tsvector('english', COALESCE(name, '') || ' ' || COALESCE(description, ''))
);

-- GIN index on data JSONB for fast queries
CREATE INDEX idx_cad_drawings_data ON cad_drawings USING GIN (data);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_cad_drawings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cad_drawings_updated_at
  BEFORE UPDATE ON cad_drawings
  FOR EACH ROW
  EXECUTE FUNCTION update_cad_drawings_updated_at();

-- Comments
COMMENT ON TABLE cad_drawings IS 'CAD drawings storage with JSONB data format';
COMMENT ON COLUMN cad_drawings.data IS 'Full drawing data: {version, objects[], layers[], settings}';
COMMENT ON COLUMN cad_drawings.metadata IS 'Cached metadata: {object_count, layer_count, etc.}';

-- Sample data format documentation
COMMENT ON COLUMN cad_drawings.data IS 'Format: {
  "version": "2.0",
  "objects": [
    {
      "id": "uuid",
      "type": "line|circle|arc|rectangle|polygon|ellipse|spline|text",
      "layer_id": "uuid",
      "properties": {...},
      "style": {
        "stroke_color": "#000000",
        "stroke_width": 1,
        "fill_color": "#ffffff",
        "line_type": "solid"
      }
    }
  ],
  "layers": [
    {
      "id": "uuid",
      "name": "Layer 1",
      "color": "#000000",
      "line_type": "cut|crease|perforation|bleed|dimension|custom",
      "line_width": 1,
      "visible": true,
      "locked": false,
      "printable": true
    }
  ],
  "settings": {
    "units": "mm",
    "grid_size": 10,
    "snap_enabled": true
  }
}';
