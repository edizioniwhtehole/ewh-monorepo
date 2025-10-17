-- Box Designer System - Simplified Migration (No Multi-tenant)
-- Version: 1.0.0-simple
-- Date: 2025-10-15

-- Box Projects
CREATE TABLE IF NOT EXISTS box_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  box_config JSONB NOT NULL,
  calculated_metrics JSONB,
  status VARCHAR(50) DEFAULT 'draft',
  tags TEXT[],
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_projects_status ON box_projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON box_projects(created_by);

-- Box Project Versions
CREATE TABLE IF NOT EXISTS box_project_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES box_projects(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  box_config JSONB NOT NULL,
  calculated_metrics JSONB,
  created_by VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  notes TEXT,
  UNIQUE(project_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_versions_project ON box_project_versions(project_id);

-- Box Templates
CREATE TABLE IF NOT EXISTS box_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  fefco_code VARCHAR(50),
  box_config JSONB NOT NULL,
  thumbnail_url TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  usage_count INTEGER DEFAULT 0,
  created_by VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_templates_category ON box_templates(category);
CREATE INDEX IF NOT EXISTS idx_templates_public ON box_templates(is_public);

-- Box Machines
CREATE TABLE IF NOT EXISTS box_machines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  machine_type VARCHAR(100) NOT NULL,
  manufacturer VARCHAR(255),
  model VARCHAR(255),
  max_width INTEGER,
  max_height INTEGER,
  speed_sheets_per_hour INTEGER,
  cost_per_hour DECIMAL(10,2),
  setup_time_minutes INTEGER DEFAULT 30,
  material_types TEXT[],
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Box Quotes
CREATE TABLE IF NOT EXISTS box_quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES box_projects(id),
  customer_id VARCHAR(255),
  quote_number VARCHAR(50) UNIQUE NOT NULL,
  quantity INTEGER NOT NULL,
  machine_id UUID REFERENCES box_machines(id),
  unit_cost DECIMAL(10,2) NOT NULL,
  total_cost DECIMAL(10,2) NOT NULL,
  material_cost DECIMAL(10,2),
  production_cost DECIMAL(10,2),
  setup_cost DECIMAL(10,2),
  markup_percentage DECIMAL(5,2),
  profit_margin DECIMAL(10,2),
  status VARCHAR(50) DEFAULT 'draft',
  valid_until DATE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quotes_project ON box_quotes(project_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON box_quotes(status);

-- Box Orders
CREATE TABLE IF NOT EXISTS box_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE NOT NULL,
  quote_id UUID REFERENCES box_quotes(id),
  project_id UUID NOT NULL REFERENCES box_projects(id),
  customer_id VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending',
  priority VARCHAR(20) DEFAULT 'medium',
  quantity INTEGER NOT NULL,
  due_date DATE,
  assigned_to VARCHAR(255),
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_status ON box_orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON box_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_due_date ON box_orders(due_date);

-- Box Export Jobs
CREATE TABLE IF NOT EXISTS box_export_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES box_projects(id),
  format VARCHAR(20) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  progress INTEGER DEFAULT 0,
  options JSONB,
  file_url TEXT,
  file_size_bytes BIGINT,
  requested_by VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  expires_at TIMESTAMP,
  error_message TEXT,
  error_stack TEXT
);

CREATE INDEX IF NOT EXISTS idx_export_jobs_status ON box_export_jobs(status);
CREATE INDEX IF NOT EXISTS idx_export_jobs_project ON box_export_jobs(project_id);
CREATE INDEX IF NOT EXISTS idx_export_jobs_expires ON box_export_jobs(expires_at);

-- Box Design Metrics
CREATE TABLE IF NOT EXISTS box_design_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB,
  project_id UUID REFERENCES box_projects(id),
  user_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_metrics_event_type ON box_design_metrics(event_type);
CREATE INDEX IF NOT EXISTS idx_metrics_project ON box_design_metrics(project_id);
CREATE INDEX IF NOT EXISTS idx_metrics_created_at ON box_design_metrics(created_at);

-- Seed 8 production machines
INSERT INTO box_machines (name, machine_type, manufacturer, model, max_width, max_height, speed_sheets_per_hour, cost_per_hour, material_types) VALUES
('Heidelberg Speedmaster', 'offset_press', 'Heidelberg', 'SX 102', 1020, 720, 15000, 180.00, ARRAY['corrugated', 'cardboard', 'sbs']),
('BOBST Die Cutter', 'die_cutting', 'BOBST', 'EXPERTFOLD 110', 1100, 800, 8000, 150.00, ARRAY['corrugated', 'cardboard']),
('HP Indigo Digital', 'digital_press', 'HP', 'Indigo 30000', 750, 540, 4000, 95.00, ARRAY['cardboard', 'sbs', 'kraft']),
('Kolbus Auto-Gluer', 'gluing', 'Kolbus', 'DA-270', 800, 600, 12000, 120.00, ARRAY['corrugated', 'cardboard']),
('Zünd Cutter', 'cutting', 'Zünd', 'G3 L-3200', 3200, 1650, 3000, 85.00, ARRAY['all']),
('BHS Corrugator', 'corrugated_machine', 'BHS', 'CCS 2500', 2500, 0, 300, 250.00, ARRAY['corrugated']),
('Mitsubishi Offset', 'offset_press', 'Mitsubishi', '1050LX', 1050, 750, 16000, 200.00, ARRAY['cardboard', 'sbs']),
('EFI Nozomi', 'digital_press', 'EFI', 'Nozomi C18000', 1800, 1200, 5000, 140.00, ARRAY['corrugated', 'cardboard'])
ON CONFLICT DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Box Designer system tables created successfully';
END $$;
