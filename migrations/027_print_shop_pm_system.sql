-- Migration 027: Print Shop Project Management System
-- Specialized PM for typography/print operations

-- Print job types and specifications
CREATE TABLE IF NOT EXISTS pm.print_job_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Job type
    type_name VARCHAR(100) NOT NULL, -- 'business_cards', 'flyers', 'posters', 'brochures', 'books'
    type_key VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'commercial', 'editorial', 'packaging', 'large_format'

    -- Default specifications
    default_paper_weight INTEGER, -- grams (90, 120, 170, 250, 300)
    default_paper_type VARCHAR(50), -- 'coated', 'uncoated', 'recycled', 'synthetic'
    default_colors VARCHAR(20), -- '4/4', '4/0', '1/1', '2/2'
    default_finishing TEXT[], -- ['lamination', 'uv_coating', 'embossing', 'die_cutting']

    -- Typical dimensions (mm)
    typical_widths INTEGER[],
    typical_heights INTEGER[],

    -- Production info
    min_quantity INTEGER DEFAULT 1,
    typical_quantities INTEGER[], -- [100, 250, 500, 1000, 5000]
    avg_production_time_hours DECIMAL(6,2),

    -- Pricing
    base_price_per_unit DECIMAL(10,2),
    setup_cost DECIMAL(10,2),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, type_key)
);

-- Print jobs (projects)
CREATE TABLE IF NOT EXISTS pm.print_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Client info
    client_id UUID REFERENCES crm.contacts(id),
    client_name VARCHAR(200) NOT NULL,
    client_email VARCHAR(200),
    client_phone VARCHAR(50),

    -- Job identification
    job_number VARCHAR(50) NOT NULL, -- 'PO-2025-001'
    job_name VARCHAR(200) NOT NULL,
    job_type_id UUID REFERENCES pm.print_job_types(id),

    -- Specifications
    quantity INTEGER NOT NULL,
    width_mm INTEGER,
    height_mm INTEGER,
    pages INTEGER DEFAULT 1,
    paper_weight INTEGER,
    paper_type VARCHAR(50),
    colors_front VARCHAR(20), -- '4/0', '4/4', '1/1'
    colors_back VARCHAR(20),
    finishing TEXT[], -- ['lamination', 'folding', 'binding']

    -- Files
    artwork_files JSONB, -- [{url: '', filename: '', uploaded_at: ''}]
    proof_files JSONB,
    final_files JSONB,

    -- Timeline
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    proof_deadline DATE,
    production_deadline DATE NOT NULL,
    delivery_date DATE NOT NULL,

    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'quote', -- 'quote', 'approved', 'prepress', 'printing', 'finishing', 'quality_check', 'shipped', 'delivered', 'cancelled'
    priority VARCHAR(20) DEFAULT 'normal', -- 'urgent', 'high', 'normal', 'low'

    -- Pricing
    quoted_price DECIMAL(10,2),
    final_price DECIMAL(10,2),
    cost DECIMAL(10,2),
    profit_margin DECIMAL(5,2),

    -- Production
    assigned_prepress_user UUID REFERENCES users(id),
    assigned_print_operator UUID REFERENCES users(id),
    assigned_finishing_user UUID REFERENCES users(id),

    -- Notes
    client_notes TEXT,
    production_notes TEXT,
    internal_notes TEXT,

    -- Tracking
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, job_number)
);

CREATE INDEX idx_print_jobs_tenant ON pm.print_jobs(tenant_id);
CREATE INDEX idx_print_jobs_status ON pm.print_jobs(status);
CREATE INDEX idx_print_jobs_client ON pm.print_jobs(client_id);
CREATE INDEX idx_print_jobs_delivery ON pm.print_jobs(delivery_date);

-- Production tasks (linked to print jobs)
CREATE TABLE IF NOT EXISTS pm.production_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    print_job_id UUID NOT NULL REFERENCES pm.print_jobs(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,

    -- Task info
    task_name VARCHAR(200) NOT NULL,
    task_type VARCHAR(50) NOT NULL, -- 'prepress', 'proofing', 'plate_making', 'printing', 'cutting', 'folding', 'binding', 'quality_check', 'packing', 'shipping'
    task_order INTEGER NOT NULL, -- Sequence in workflow

    -- Assignment
    assigned_to UUID REFERENCES users(id),
    assigned_at TIMESTAMPTZ,

    -- Timing
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    scheduled_start TIMESTAMPTZ,
    scheduled_end TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'blocked', 'cancelled'
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),

    -- Quality
    quality_check_passed BOOLEAN,
    quality_issues TEXT,

    -- Machine/Resource
    machine_id UUID REFERENCES pm.machines(id),
    machine_name VARCHAR(100),

    -- Notes
    notes TEXT,

    -- Workflow learning integration
    workflow_recording_id UUID REFERENCES pm.workflow_recordings(id),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_production_tasks_job ON pm.production_tasks(print_job_id);
CREATE INDEX idx_production_tasks_assigned ON pm.production_tasks(assigned_to);
CREATE INDEX idx_production_tasks_status ON pm.production_tasks(status);
CREATE INDEX idx_production_tasks_scheduled ON pm.production_tasks(scheduled_start, scheduled_end);

-- Machines/Equipment
CREATE TABLE IF NOT EXISTS pm.machines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Machine info
    machine_name VARCHAR(100) NOT NULL,
    machine_type VARCHAR(50) NOT NULL, -- 'offset_press', 'digital_press', 'plotter', 'cutting_machine', 'folding_machine', 'binding_machine'
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),

    -- Capabilities
    max_width_mm INTEGER,
    max_height_mm INTEGER,
    max_colors INTEGER,
    max_paper_weight INTEGER,
    capabilities TEXT[], -- ['uv_coating', 'spot_color', 'variable_data']

    -- Status
    status VARCHAR(50) DEFAULT 'available', -- 'available', 'in_use', 'maintenance', 'broken'
    current_job_id UUID REFERENCES pm.print_jobs(id),

    -- Maintenance
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    maintenance_hours INTEGER DEFAULT 0,

    -- Usage tracking
    total_impressions BIGINT DEFAULT 0,
    total_hours DECIMAL(10,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, machine_name)
);

CREATE INDEX idx_machines_tenant ON pm.machines(tenant_id);
CREATE INDEX idx_machines_type ON pm.machines(machine_type);
CREATE INDEX idx_machines_status ON pm.machines(status);

-- Material inventory
CREATE TABLE IF NOT EXISTS pm.print_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Material info
    material_type VARCHAR(50) NOT NULL, -- 'paper', 'ink', 'plate', 'coating', 'adhesive'
    material_name VARCHAR(200) NOT NULL,
    sku VARCHAR(100),

    -- Paper specific
    paper_weight INTEGER,
    paper_type VARCHAR(50),
    paper_finish VARCHAR(50), -- 'glossy', 'matte', 'satin'

    -- Ink specific
    ink_type VARCHAR(50), -- 'cmyk', 'pantone', 'specialty'
    ink_color VARCHAR(100),

    -- Dimensions
    width_mm INTEGER,
    height_mm INTEGER,
    thickness_mm DECIMAL(6,2),

    -- Inventory
    unit_of_measure VARCHAR(20) DEFAULT 'sheets', -- 'sheets', 'rolls', 'kg', 'liters'
    quantity_in_stock DECIMAL(10,2) DEFAULT 0,
    min_stock_level DECIMAL(10,2),
    reorder_quantity DECIMAL(10,2),

    -- Pricing
    cost_per_unit DECIMAL(10,2),
    supplier_id UUID REFERENCES crm.contacts(id),

    -- Location
    storage_location VARCHAR(100),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, sku)
);

CREATE INDEX idx_print_materials_tenant ON pm.print_materials(tenant_id);
CREATE INDEX idx_print_materials_type ON pm.print_materials(material_type);
CREATE INDEX idx_print_materials_stock ON pm.print_materials(quantity_in_stock);

-- Material usage (track what's used in each job)
CREATE TABLE IF NOT EXISTS pm.material_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    print_job_id UUID NOT NULL REFERENCES pm.print_jobs(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES pm.print_materials(id),

    quantity_used DECIMAL(10,2) NOT NULL,
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),

    used_at TIMESTAMPTZ DEFAULT NOW(),
    recorded_by UUID REFERENCES users(id)
);

CREATE INDEX idx_material_usage_job ON pm.material_usage(print_job_id);
CREATE INDEX idx_material_usage_material ON pm.material_usage(material_id);

-- Print job status history (audit trail)
CREATE TABLE IF NOT EXISTS pm.print_job_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    print_job_id UUID NOT NULL REFERENCES pm.print_jobs(id) ON DELETE CASCADE,

    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,

    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMPTZ DEFAULT NOW(),

    notes TEXT
);

CREATE INDEX idx_job_status_history ON pm.print_job_status_history(print_job_id, changed_at DESC);

-- Function: Calculate job profitability
CREATE OR REPLACE FUNCTION pm.calculate_job_profitability(job_id UUID)
RETURNS TABLE (
    revenue DECIMAL(10,2),
    material_cost DECIMAL(10,2),
    labor_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    profit DECIMAL(10,2),
    margin_percentage DECIMAL(5,2)
) AS $$
DECLARE
    job_revenue DECIMAL(10,2);
    materials_cost DECIMAL(10,2);
    labor_cost DECIMAL(10,2);
    total_cost DECIMAL(10,2);
BEGIN
    -- Get revenue
    SELECT COALESCE(final_price, quoted_price, 0)
    INTO job_revenue
    FROM pm.print_jobs
    WHERE id = job_id;

    -- Calculate material costs
    SELECT COALESCE(SUM(total_cost), 0)
    INTO materials_cost
    FROM pm.material_usage
    WHERE print_job_id = job_id;

    -- Calculate labor costs (assume $50/hour average)
    SELECT COALESCE(SUM(actual_hours * 50), 0)
    INTO labor_cost
    FROM pm.production_tasks
    WHERE print_job_id = job_id;

    total_cost := materials_cost + labor_cost;

    RETURN QUERY SELECT
        job_revenue as revenue,
        materials_cost as material_cost,
        labor_cost as labor_cost,
        total_cost as total_cost,
        (job_revenue - total_cost) as profit,
        CASE WHEN job_revenue > 0
            THEN ((job_revenue - total_cost) / job_revenue * 100)
            ELSE 0
        END as margin_percentage;
END;
$$ LANGUAGE plpgsql;

-- Function: Get production schedule
CREATE OR REPLACE FUNCTION pm.get_production_schedule(
    start_date DATE,
    end_date DATE,
    machine_id_filter UUID DEFAULT NULL
)
RETURNS TABLE (
    task_id UUID,
    job_number VARCHAR,
    job_name VARCHAR,
    task_name VARCHAR,
    machine_name VARCHAR,
    assigned_to_name VARCHAR,
    scheduled_start TIMESTAMPTZ,
    scheduled_end TIMESTAMPTZ,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pt.id as task_id,
        pj.job_number,
        pj.job_name,
        pt.task_name,
        pt.machine_name,
        u.name as assigned_to_name,
        pt.scheduled_start,
        pt.scheduled_end,
        pt.status
    FROM pm.production_tasks pt
    JOIN pm.print_jobs pj ON pt.print_job_id = pj.id
    LEFT JOIN users u ON pt.assigned_to = u.id
    WHERE pt.scheduled_start::DATE BETWEEN start_date AND end_date
      AND (machine_id_filter IS NULL OR pt.machine_id = machine_id_filter)
    ORDER BY pt.scheduled_start ASC;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update job status when all tasks complete
CREATE OR REPLACE FUNCTION pm.update_job_status_on_task_completion()
RETURNS TRIGGER AS $$
DECLARE
    all_tasks_complete BOOLEAN;
    job_status VARCHAR;
BEGIN
    IF NEW.status = 'completed' THEN
        -- Check if all tasks for this job are completed
        SELECT NOT EXISTS (
            SELECT 1 FROM pm.production_tasks
            WHERE print_job_id = NEW.print_job_id
              AND status != 'completed'
        ) INTO all_tasks_complete;

        IF all_tasks_complete THEN
            -- Update job status to quality_check
            UPDATE pm.print_jobs
            SET status = 'quality_check',
                updated_at = NOW()
            WHERE id = NEW.print_job_id;

            -- Record status change
            INSERT INTO pm.print_job_status_history (print_job_id, from_status, to_status, notes)
            SELECT NEW.print_job_id, status, 'quality_check', 'All production tasks completed'
            FROM pm.print_jobs
            WHERE id = NEW.print_job_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_job_on_task_complete
    AFTER UPDATE OF status ON pm.production_tasks
    FOR EACH ROW
    EXECUTE FUNCTION pm.update_job_status_on_task_completion();

-- Trigger: Track material usage inventory
CREATE OR REPLACE FUNCTION pm.update_material_inventory()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pm.print_materials
    SET quantity_in_stock = quantity_in_stock - NEW.quantity_used,
        updated_at = NOW()
    WHERE id = NEW.material_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_inventory_on_usage
    AFTER INSERT ON pm.material_usage
    FOR EACH ROW
    EXECUTE FUNCTION pm.update_material_inventory();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.print_job_types TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.print_jobs TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.production_tasks TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.machines TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.print_materials TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.material_usage TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.print_job_status_history TO ewh;

-- Sample job types for print shop
INSERT INTO pm.print_job_types (tenant_id, type_name, type_key, category, default_paper_weight, default_paper_type, default_colors, typical_widths, typical_heights, typical_quantities, avg_production_time_hours, base_price_per_unit, setup_cost)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Biglietti da Visita', 'business_cards', 'commercial', 300, 'coated', '4/4', ARRAY[85, 90], ARRAY[55], ARRAY[100, 250, 500, 1000], 2, 0.15, 25),
    ('00000000-0000-0000-0000-000000000001', 'Volantini A5', 'flyers_a5', 'commercial', 170, 'coated', '4/4', ARRAY[148], ARRAY[210], ARRAY[500, 1000, 2000, 5000], 4, 0.08, 35),
    ('00000000-0000-0000-0000-000000000001', 'Manifesti 70x100', 'posters_70x100', 'large_format', 150, 'coated', '4/0', ARRAY[700], ARRAY[1000], ARRAY[10, 25, 50, 100], 3, 2.50, 50),
    ('00000000-0000-0000-0000-000000000001', 'Brochure A4', 'brochure_a4', 'commercial', 170, 'coated', '4/4', ARRAY[210], ARRAY[297], ARRAY[100, 250, 500], 6, 0.45, 60),
    ('00000000-0000-0000-0000-000000000001', 'Cataloghi', 'catalogs', 'editorial', 150, 'coated', '4/4', ARRAY[210], ARRAY[297], ARRAY[50, 100, 250], 24, 3.50, 150);

COMMENT ON TABLE pm.print_jobs IS 'Core table for print shop project management';
COMMENT ON TABLE pm.production_tasks IS 'Individual tasks in print production workflow';
COMMENT ON TABLE pm.machines IS 'Print shop equipment and machinery';
COMMENT ON TABLE pm.print_materials IS 'Inventory of papers, inks, and consumables';
COMMENT ON FUNCTION pm.calculate_job_profitability IS 'Calculate revenue, costs, and profit margin for print jobs';
