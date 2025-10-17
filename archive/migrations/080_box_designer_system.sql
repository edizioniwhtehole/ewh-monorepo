-- =====================================================
-- Box Designer / Packaging CAD System
-- Migration: 080_box_designer_system.sql
-- Description: Complete enterprise packaging design system
-- =====================================================

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Projects: Box design projects
CREATE TABLE box_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Project status workflow
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN (
        'draft',        -- In lavorazione
        'review',       -- In revisione
        'approved',     -- Approvato
        'production',   -- In produzione
        'completed',    -- Completato
        'archived'      -- Archiviato
    )),

    -- Box configuration (complete state)
    box_config JSONB NOT NULL,
    -- Structure: {
    --   shape: 'rectangular' | 'pyramid_trunk' | 'cylinder',
    --   dimensions: { length, width, height, unit },
    --   material: { type, thickness, weight },
    --   closure: { top, bottom },
    --   options: { glueFlap, bleed, windows, handles },
    --   fefcoCode?: string
    -- }

    -- Cached calculations (for performance)
    calculated_metrics JSONB,
    -- Structure: {
    --   volume: { internal, external },
    --   area: { material, dieline },
    --   weight: number,
    --   dielineDimensions: { width, height }
    -- }

    -- Thumbnail for quick preview
    thumbnail_url TEXT,

    -- Links to other entities
    customer_id UUID REFERENCES crm_contacts(id),
    parent_project_id UUID REFERENCES box_projects(id), -- For duplicates

    -- Metadata
    metadata JSONB DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_dimensions CHECK (
        (box_config->'dimensions'->>'length')::numeric > 0 AND
        (box_config->'dimensions'->>'width')::numeric > 0 AND
        (box_config->'dimensions'->>'height')::numeric > 0
    )
);

-- Project versions (full history)
CREATE TABLE box_project_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES box_projects(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,

    -- Snapshot of configuration at this version
    box_config JSONB NOT NULL,
    calculated_metrics JSONB,

    -- Change tracking
    changes_description TEXT,
    changed_fields TEXT[],

    -- Who and when
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),

    -- Unique version per project
    UNIQUE(project_id, version_number)
);

-- Templates library
CREATE TABLE box_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Ownership
    tenant_id UUID REFERENCES tenants(id), -- NULL = global public template
    created_by UUID REFERENCES users(id),

    -- Template info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- 'fefco_0201', 'tuck_end', 'custom', 'specialized'
    fefco_code VARCHAR(20),

    -- Visual
    thumbnail_url TEXT,
    preview_images TEXT[],

    -- Configuration template
    box_config JSONB NOT NULL,

    -- Discovery & SEO
    tags TEXT[] DEFAULT '{}',
    keywords TEXT[],

    -- Visibility
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,

    -- Usage stats
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP,

    -- Metadata
    industry VARCHAR(100), -- 'food', 'retail', 'shipping', 'cosmetics', etc.
    suitable_for TEXT[], -- ['gift_boxes', 'shipping', 'retail_display']

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

-- =====================================================
-- MACHINES & PRODUCTION
-- =====================================================

-- Production machines (moved from TypeScript to database)
CREATE TABLE box_machines (
    id VARCHAR(100) PRIMARY KEY,

    -- Ownership (NULL = global machines available to all)
    tenant_id UUID REFERENCES tenants(id),

    -- Machine info
    name VARCHAR(255) NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'offset_press',
        'digital_press',
        'die_cutter',
        'combined',
        'cnc_cutter'
    )),

    -- Physical specifications
    max_sheet_width INTEGER NOT NULL,  -- mm
    max_sheet_height INTEGER NOT NULL, -- mm
    min_sheet_width INTEGER,
    min_sheet_height INTEGER,

    -- Gripper zones (non-printable/non-cuttable areas)
    gripper_margins JSONB NOT NULL,
    -- Structure: { front: 15, back: 8, left: 8, right: 8 }

    -- Performance
    speed_sheets_per_hour INTEGER,

    -- Costing
    cost_per_sheet DECIMAL(10,4),
    cost_per_hour DECIMAL(10,2),
    setup_time_minutes INTEGER DEFAULT 30,

    -- Material support
    supported_materials JSONB,
    -- Structure: [
    --   { type: 'cardboard_300g', minThickness: 0.3, maxThickness: 0.3 },
    --   { type: 'corrugated_e', minThickness: 1.5, maxThickness: 1.5 }
    -- ]

    -- Grain preference
    grain_preference VARCHAR(20) CHECK (grain_preference IN ('horizontal', 'vertical', 'any')),

    -- Capabilities
    capabilities JSONB,
    -- Structure: {
    --   creasing: true,
    --   perforation: true,
    --   dieCutting: true,
    --   embossing: false
    -- }

    -- Status
    is_active BOOLEAN DEFAULT true,
    maintenance_schedule TEXT,
    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- QUOTES & ORDERS
-- =====================================================

-- Quotes (preventivi)
CREATE TABLE box_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Quote identification
    quote_number VARCHAR(50) UNIQUE NOT NULL,

    -- Relations
    project_id UUID REFERENCES box_projects(id),
    customer_id UUID REFERENCES crm_contacts(id),

    -- Production specs
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    machine_id VARCHAR(100) REFERENCES box_machines(id),
    sheet_size VARCHAR(50), -- e.g., "1060x760"
    material VARCHAR(100),

    -- Nesting results
    nesting_data JSONB,
    -- Structure: {
    --   itemsPerSheet: 12,
    --   efficiency: 78.5,
    --   sheetsNeeded: 84,
    --   layout: [...]
    -- }

    -- Pricing breakdown
    unit_cost DECIMAL(10,4),
    setup_cost DECIMAL(10,2),
    material_cost DECIMAL(10,2),
    production_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2) NOT NULL,

    -- Markup and margins
    markup_multiplier DECIMAL(4,2) DEFAULT 1.3,
    profit_margin DECIMAL(10,2),

    -- Time estimates
    production_time_hours DECIMAL(6,2),
    estimated_delivery_date DATE,

    -- Status
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN (
        'draft',
        'sent',
        'viewed',
        'accepted',
        'rejected',
        'expired',
        'converted' -- Converted to order
    )),

    valid_until DATE,

    -- Communication
    sent_at TIMESTAMP,
    viewed_at TIMESTAMP,
    responded_at TIMESTAMP,
    notes TEXT,
    customer_notes TEXT,

    -- Files
    pdf_url TEXT,

    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Orders (ordini di produzione)
CREATE TABLE box_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Order identification
    order_number VARCHAR(50) UNIQUE NOT NULL,

    -- Relations
    quote_id UUID REFERENCES box_quotes(id),
    project_id UUID NOT NULL REFERENCES box_projects(id),
    customer_id UUID REFERENCES crm_contacts(id),

    -- Production details
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    machine_id VARCHAR(100) REFERENCES box_machines(id),

    -- Status workflow
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending',       -- In attesa
        'confirmed',     -- Confermato
        'in_production', -- In produzione
        'quality_check', -- Controllo qualità
        'completed',     -- Completato
        'shipped',       -- Spedito
        'delivered',     -- Consegnato
        'cancelled'      -- Cancellato
    )),

    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),

    -- Scheduling
    due_date DATE,
    scheduled_start_date DATE,
    scheduled_end_date DATE,

    -- Actual times
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,

    -- Assignment
    assigned_to UUID REFERENCES users(id),
    production_team TEXT[],

    -- Notes
    production_notes TEXT,
    quality_notes TEXT,
    shipping_notes TEXT,

    -- Files
    production_files TEXT[], -- URLs to dielines, artwork, etc.

    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- EXPORT JOBS (Async processing)
-- =====================================================

CREATE TABLE box_export_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- What to export
    project_id UUID NOT NULL REFERENCES box_projects(id),
    format VARCHAR(20) NOT NULL CHECK (format IN ('svg', 'pdf', 'dxf', 'ai', 'plt', 'json')),

    -- Export options
    options JSONB DEFAULT '{}',
    -- Structure: {
    --   includeGuides: true,
    --   includeDimensions: true,
    --   scale: 1.0,
    --   colorMode: 'cmyk'
    -- }

    -- Job status
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending',
        'processing',
        'completed',
        'failed'
    )),

    -- Progress tracking
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),

    -- Result
    file_url TEXT,
    file_size_bytes BIGINT,
    error_message TEXT,
    error_stack TEXT,

    -- Timing
    requested_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    expires_at TIMESTAMP, -- Auto-delete temp files after expiry

    -- Retry handling
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3
);

-- =====================================================
-- ANALYTICS & METRICS
-- =====================================================

CREATE TABLE box_design_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Event tracking
    event_type VARCHAR(100) NOT NULL,
    -- Examples: 'project_created', 'quote_generated', 'export_completed',
    --          'template_used', 'nesting_calculated', 'order_completed'

    event_data JSONB,

    -- Relations (optional, depends on event)
    project_id UUID REFERENCES box_projects(id),
    user_id UUID REFERENCES users(id),

    -- Metadata
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- SETTINGS (Platform Waterfall Integration)
-- =====================================================

INSERT INTO platform_settings (category, key, value_type, default_value, description, scope, is_visible)
VALUES
-- Global settings
('box_designer', 'enabled', 'boolean', 'true', 'Enable box designer module', 'global', true),
('box_designer', 'default_units', 'string', 'mm', 'Default measurement units (mm/cm/in)', 'global', true),
('box_designer', 'public_templates_enabled', 'boolean', 'true', 'Enable public template library', 'global', true),
('box_designer', 'max_dimension_mm', 'integer', '3000', 'Maximum allowed dimension in mm', 'global', true),

-- Tenant settings
('box_designer', 'max_projects', 'integer', '100', 'Maximum projects per tenant', 'tenant', true),
('box_designer', 'max_active_projects', 'integer', '50', 'Maximum active (non-archived) projects', 'tenant', true),
('box_designer', 'custom_machines_enabled', 'boolean', 'true', 'Allow custom machine configurations', 'tenant', true),
('box_designer', 'export_formats', 'json', '["svg","pdf","dxf","ai","plt"]', 'Allowed export formats', 'tenant', true),
('box_designer', 'pricing_markup', 'number', '1.3', 'Default pricing markup multiplier', 'tenant', true),
('box_designer', 'enable_quotes', 'boolean', 'true', 'Enable quote generation', 'tenant', true),
('box_designer', 'enable_orders', 'boolean', 'true', 'Enable order management', 'tenant', true),
('box_designer', 'auto_archive_days', 'integer', '90', 'Auto-archive completed projects after N days', 'tenant', true),

-- User settings
('box_designer', 'auto_save_interval', 'integer', '30', 'Auto-save interval in seconds', 'user', true),
('box_designer', 'default_grain_direction', 'string', 'horizontal', 'Default grain direction (horizontal/vertical/any)', 'user', true),
('box_designer', 'default_machine_id', 'string', null, 'Default machine ID for nesting', 'user', true),
('box_designer', 'default_material', 'string', 'corrugated_e', 'Default material type', 'user', true),
('box_designer', 'show_dimensions_on_dieline', 'boolean', 'true', 'Show dimensions on dieline by default', 'user', true),
('box_designer', 'default_bleed_mm', 'number', '3', 'Default bleed/trim in mm', 'user', true);

-- =====================================================
-- PERMISSIONS
-- =====================================================

INSERT INTO permissions (name, description, category) VALUES
-- Projects
('box.projects.view', 'View box design projects', 'box_designer'),
('box.projects.view_all', 'View all projects in tenant', 'box_designer'),
('box.projects.create', 'Create box design projects', 'box_designer'),
('box.projects.edit', 'Edit box design projects', 'box_designer'),
('box.projects.edit_all', 'Edit all projects in tenant', 'box_designer'),
('box.projects.delete', 'Delete box design projects', 'box_designer'),
('box.projects.approve', 'Approve projects for production', 'box_designer'),

-- Templates
('box.templates.view', 'View box templates', 'box_designer'),
('box.templates.create', 'Create box templates', 'box_designer'),
('box.templates.edit', 'Edit box templates', 'box_designer'),
('box.templates.delete', 'Delete box templates', 'box_designer'),
('box.templates.publish', 'Publish public templates', 'box_designer'),

-- Quotes
('box.quotes.view', 'View quotes', 'box_designer'),
('box.quotes.view_all', 'View all quotes in tenant', 'box_designer'),
('box.quotes.create', 'Create quotes', 'box_designer'),
('box.quotes.edit', 'Edit quotes', 'box_designer'),
('box.quotes.send', 'Send quotes to clients', 'box_designer'),
('box.quotes.approve', 'Approve quotes', 'box_designer'),

-- Orders
('box.orders.view', 'View orders', 'box_designer'),
('box.orders.view_all', 'View all orders in tenant', 'box_designer'),
('box.orders.create', 'Create production orders', 'box_designer'),
('box.orders.edit', 'Edit production orders', 'box_designer'),
('box.orders.manage', 'Manage production workflow', 'box_designer'),
('box.orders.cancel', 'Cancel orders', 'box_designer'),

-- Machines
('box.machines.view', 'View production machines', 'box_designer'),
('box.machines.create', 'Add custom machines', 'box_designer'),
('box.machines.edit', 'Edit machine configurations', 'box_designer'),
('box.machines.delete', 'Delete custom machines', 'box_designer'),

-- Analytics
('box.analytics.view', 'View box designer analytics', 'box_designer'),
('box.analytics.export', 'Export analytics data', 'box_designer'),

-- Admin
('box.settings.manage', 'Manage box designer settings', 'box_designer');

-- =====================================================
-- DEFAULT ROLE PERMISSIONS
-- =====================================================

-- Admin: Full access
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'admin' AND p.category = 'box_designer';

-- Designer: Project management + quotes
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'designer' AND p.name IN (
    'box.projects.view',
    'box.projects.create',
    'box.projects.edit',
    'box.templates.view',
    'box.templates.create',
    'box.quotes.view',
    'box.quotes.create',
    'box.machines.view',
    'box.analytics.view'
);

-- Sales: Quotes and orders
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'sales' AND p.name IN (
    'box.projects.view_all',
    'box.templates.view',
    'box.quotes.view_all',
    'box.quotes.create',
    'box.quotes.send',
    'box.orders.view_all',
    'box.orders.create',
    'box.machines.view'
);

-- Production: Order management
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'production' AND p.name IN (
    'box.projects.view_all',
    'box.orders.view_all',
    'box.orders.edit',
    'box.orders.manage',
    'box.machines.view'
);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Projects
CREATE INDEX idx_box_projects_tenant ON box_projects(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_projects_status ON box_projects(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_projects_created_by ON box_projects(created_by) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_projects_customer ON box_projects(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_projects_created_at ON box_projects(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_projects_tags ON box_projects USING GIN(tags);

-- Project versions
CREATE INDEX idx_box_project_versions_project ON box_project_versions(project_id, version_number DESC);

-- Templates
CREATE INDEX idx_box_templates_tenant ON box_templates(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_templates_category ON box_templates(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_templates_public ON box_templates(is_public) WHERE is_public = true AND deleted_at IS NULL;
CREATE INDEX idx_box_templates_featured ON box_templates(is_featured) WHERE is_featured = true AND deleted_at IS NULL;
CREATE INDEX idx_box_templates_tags ON box_templates USING GIN(tags);
CREATE INDEX idx_box_templates_usage ON box_templates(usage_count DESC) WHERE deleted_at IS NULL;

-- Machines
CREATE INDEX idx_box_machines_tenant ON box_machines(tenant_id);
CREATE INDEX idx_box_machines_type ON box_machines(type) WHERE is_active = true;
CREATE INDEX idx_box_machines_active ON box_machines(is_active);

-- Quotes
CREATE INDEX idx_box_quotes_tenant ON box_quotes(tenant_id);
CREATE INDEX idx_box_quotes_project ON box_quotes(project_id);
CREATE INDEX idx_box_quotes_customer ON box_quotes(customer_id);
CREATE INDEX idx_box_quotes_status ON box_quotes(status);
CREATE INDEX idx_box_quotes_created_at ON box_quotes(created_at DESC);
CREATE INDEX idx_box_quotes_number ON box_quotes(quote_number);

-- Orders
CREATE INDEX idx_box_orders_tenant ON box_orders(tenant_id);
CREATE INDEX idx_box_orders_project ON box_orders(project_id);
CREATE INDEX idx_box_orders_customer ON box_orders(customer_id);
CREATE INDEX idx_box_orders_status ON box_orders(status);
CREATE INDEX idx_box_orders_priority ON box_orders(priority, due_date);
CREATE INDEX idx_box_orders_assigned ON box_orders(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_box_orders_due_date ON box_orders(due_date) WHERE status NOT IN ('completed', 'cancelled');
CREATE INDEX idx_box_orders_number ON box_orders(order_number);

-- Export jobs
CREATE INDEX idx_box_export_jobs_tenant ON box_export_jobs(tenant_id);
CREATE INDEX idx_box_export_jobs_project ON box_export_jobs(project_id);
CREATE INDEX idx_box_export_jobs_status ON box_export_jobs(status);
CREATE INDEX idx_box_export_jobs_created_at ON box_export_jobs(created_at DESC);

-- Metrics
CREATE INDEX idx_box_metrics_tenant ON box_design_metrics(tenant_id);
CREATE INDEX idx_box_metrics_event_type ON box_design_metrics(event_type, created_at DESC);
CREATE INDEX idx_box_metrics_project ON box_design_metrics(project_id) WHERE project_id IS NOT NULL;
CREATE INDEX idx_box_metrics_user ON box_design_metrics(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_box_metrics_created_at ON box_design_metrics(created_at DESC);

-- =====================================================
-- SEED DATA: Global Machines
-- =====================================================

INSERT INTO box_machines (id, name, manufacturer, model, type, max_sheet_width, max_sheet_height, min_sheet_width, min_sheet_height, gripper_margins, speed_sheets_per_hour, cost_per_sheet, cost_per_hour, setup_time_minutes, supported_materials, grain_preference, capabilities) VALUES
-- Offset Presses
('heidelberg-xl-106', 'Heidelberg Speedmaster XL 106', 'Heidelberg', 'Speedmaster XL 106', 'offset_press', 1060, 760, 520, 360, '{"front": 15, "back": 8, "left": 8, "right": 8}', 18000, 0.35, 180, 45, '[{"type": "cardboard_300g", "minThickness": 0.3, "maxThickness": 0.3}, {"type": "corrugated_e", "minThickness": 1.5, "maxThickness": 1.8}]', 'horizontal', '{"creasing": true, "perforation": true, "dieCutting": false, "embossing": false}'),

('komori-g40', 'Komori Lithrone G40', 'Komori', 'Lithrone G40', 'offset_press', 1020, 720, 480, 330, '{"front": 12, "back": 7, "left": 7, "right": 7}', 16000, 0.32, 160, 40, '[{"type": "cardboard_300g", "minThickness": 0.3, "maxThickness": 0.4}, {"type": "cardboard_400g", "minThickness": 0.4, "maxThickness": 0.5}]', 'horizontal', '{"creasing": true, "perforation": true, "dieCutting": false, "embossing": false}'),

-- Digital Presses
('hp-indigo-12000', 'HP Indigo 12000 Digital Press', 'HP', 'Indigo 12000', 'digital_press', 750, 530, 210, 148, '{"front": 10, "back": 5, "left": 5, "right": 5}', 4600, 0.55, 120, 15, '[{"type": "cardboard_300g", "minThickness": 0.3, "maxThickness": 0.4}, {"type": "cardboard_400g", "minThickness": 0.4, "maxThickness": 0.5}]', 'any', '{"creasing": false, "perforation": false, "dieCutting": false, "embossing": false}'),

-- Die Cutters
('bobst-novacut-106', 'BOBST Novacut 106', 'BOBST', 'Novacut 106', 'die_cutter', 1060, 760, 420, 300, '{"front": 15, "back": 10, "left": 10, "right": 10}', 8000, 0.45, 150, 60, '[{"type": "cardboard_300g", "minThickness": 0.3, "maxThickness": 0.5}, {"type": "corrugated_e", "minThickness": 1.5, "maxThickness": 2.0}, {"type": "corrugated_b", "minThickness": 3.0, "maxThickness": 3.5}]', 'horizontal', '{"creasing": true, "perforation": true, "dieCutting": true, "embossing": true}'),

('masterwork-mx-1060', 'Masterwork MX 1060', 'Masterwork', 'MX 1060', 'die_cutter', 1060, 760, 400, 300, '{"front": 18, "back": 12, "left": 12, "right": 12}', 7000, 0.40, 130, 50, '[{"type": "corrugated_e", "minThickness": 1.5, "maxThickness": 2.0}, {"type": "corrugated_b", "minThickness": 3.0, "maxThickness": 4.0}]', 'horizontal', '{"creasing": true, "perforation": true, "dieCutting": true, "embossing": false}'),

('sanwa-750', 'Sanwa Kiko Die Cutter 750', 'Sanwa Kiko', '750', 'die_cutter', 750, 520, 300, 200, '{"front": 15, "back": 10, "left": 10, "right": 10}', 6000, 0.35, 110, 45, '[{"type": "cardboard_300g", "minThickness": 0.3, "maxThickness": 0.4}, {"type": "corrugated_e", "minThickness": 1.5, "maxThickness": 2.0}]', 'any', '{"creasing": true, "perforation": true, "dieCutting": true, "embossing": false}'),

-- Combined (Print + Die Cut)
('bobst-mastercut-106', 'BOBST Mastercut 106 PER', 'BOBST', 'Mastercut 106 PER', 'combined', 1060, 760, 450, 320, '{"front": 15, "back": 8, "left": 8, "right": 8}', 10000, 0.65, 200, 50, '[{"type": "corrugated_e", "minThickness": 1.5, "maxThickness": 2.0}, {"type": "corrugated_b", "minThickness": 3.0, "maxThickness": 3.5}]', 'horizontal', '{"creasing": true, "perforation": true, "dieCutting": true, "embossing": true}'),

-- CNC Digital Cutters
('zund-g3-l2500', 'Zünd G3 L-2500', 'Zünd', 'G3 L-2500', 'cnc_cutter', 2500, 3200, 100, 100, '{"front": 5, "back": 5, "left": 5, "right": 5}', 120, 1.20, 80, 10, '[{"type": "cardboard_300g", "minThickness": 0.3, "maxThickness": 0.5}, {"type": "corrugated_e", "minThickness": 1.5, "maxThickness": 2.0}, {"type": "microflauto", "minThickness": 1.2, "maxThickness": 1.5}]', 'any', '{"creasing": true, "perforation": true, "dieCutting": true, "embossing": false}');

-- =====================================================
-- TRIGGERS for Updated Timestamps
-- =====================================================

CREATE OR REPLACE FUNCTION update_box_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER box_projects_updated_at BEFORE UPDATE ON box_projects
    FOR EACH ROW EXECUTE FUNCTION update_box_updated_at();

CREATE TRIGGER box_templates_updated_at BEFORE UPDATE ON box_templates
    FOR EACH ROW EXECUTE FUNCTION update_box_updated_at();

CREATE TRIGGER box_quotes_updated_at BEFORE UPDATE ON box_quotes
    FOR EACH ROW EXECUTE FUNCTION update_box_updated_at();

CREATE TRIGGER box_orders_updated_at BEFORE UPDATE ON box_orders
    FOR EACH ROW EXECUTE FUNCTION update_box_updated_at();

CREATE TRIGGER box_machines_updated_at BEFORE UPDATE ON box_machines
    FOR EACH ROW EXECUTE FUNCTION update_box_updated_at();

-- =====================================================
-- FUNCTIONS: Auto-increment version numbers
-- =====================================================

CREATE OR REPLACE FUNCTION box_project_version_autoincrement()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.version_number IS NULL THEN
        SELECT COALESCE(MAX(version_number), 0) + 1
        INTO NEW.version_number
        FROM box_project_versions
        WHERE project_id = NEW.project_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER box_project_versions_autoincrement BEFORE INSERT ON box_project_versions
    FOR EACH ROW EXECUTE FUNCTION box_project_version_autoincrement();

-- =====================================================
-- VIEWS: Useful aggregations
-- =====================================================

-- Active projects summary
CREATE VIEW box_projects_active AS
SELECT
    p.*,
    u.name as creator_name,
    c.name as customer_name,
    (SELECT COUNT(*) FROM box_project_versions WHERE project_id = p.id) as version_count
FROM box_projects p
LEFT JOIN users u ON p.created_by = u.id
LEFT JOIN crm_contacts c ON p.customer_id = c.id
WHERE p.deleted_at IS NULL AND p.status NOT IN ('archived');

-- Quote statistics
CREATE VIEW box_quote_stats AS
SELECT
    tenant_id,
    COUNT(*) as total_quotes,
    COUNT(*) FILTER (WHERE status = 'accepted') as accepted_quotes,
    COUNT(*) FILTER (WHERE status = 'sent') as pending_quotes,
    SUM(total_cost) as total_quoted_value,
    SUM(total_cost) FILTER (WHERE status = 'accepted') as accepted_value,
    AVG(total_cost) as avg_quote_value,
    AVG(nesting_data->>'efficiency') as avg_nesting_efficiency
FROM box_quotes
GROUP BY tenant_id;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE box_projects IS 'Box design projects with complete configuration and versioning';
COMMENT ON TABLE box_templates IS 'Reusable box templates (FEFCO standards and custom designs)';
COMMENT ON TABLE box_machines IS 'Production machines for nesting and cost calculation';
COMMENT ON TABLE box_quotes IS 'Customer quotes with pricing and production estimates';
COMMENT ON TABLE box_orders IS 'Production orders with workflow tracking';
COMMENT ON TABLE box_export_jobs IS 'Async export jobs for various file formats';
COMMENT ON TABLE box_design_metrics IS 'Analytics and usage metrics for box designer module';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- Log migration
INSERT INTO schema_migrations (version, description, executed_at) VALUES
('080', 'Box Designer / Packaging CAD System - Complete enterprise implementation', NOW());
