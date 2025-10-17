-- Add missing fields to box_templates
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS keywords TEXT[];
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS industry VARCHAR(100);
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS suitable_for TEXT[];
ALTER TABLE box_templates ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP;

-- Add missing fields to box_projects
ALTER TABLE box_projects ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE box_projects ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE box_projects ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE box_projects ADD COLUMN IF NOT EXISTS metadata JSONB;
ALTER TABLE box_projects ADD COLUMN IF NOT EXISTS customer_id UUID;

-- Add missing fields to other tables
ALTER TABLE box_quotes ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE box_orders ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE box_export_jobs ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE box_design_metrics ADD COLUMN IF NOT EXISTS tenant_id UUID;

-- Update existing templates to be public by default
UPDATE box_templates SET tenant_id = NULL WHERE tenant_id IS NULL;
