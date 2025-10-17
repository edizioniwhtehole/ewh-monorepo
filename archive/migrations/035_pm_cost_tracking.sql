-- Migration: Complete Cost Tracking & Billing System

-- Cost categories
CREATE TABLE IF NOT EXISTS pm.cost_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  category_name VARCHAR(100) NOT NULL,
  category_code VARCHAR(50) NOT NULL,
  description TEXT,
  default_rate DECIMAL(10,2), -- Default hourly/unit rate
  billing_type VARCHAR(20) DEFAULT 'hourly', -- 'hourly', 'fixed', 'unit'
  is_billable BOOLEAN DEFAULT TRUE,
  color VARCHAR(7), -- Hex color for charts
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT fk_cost_cat_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE,
  UNIQUE(tenant_id, category_code)
);

-- Project budget & costs
ALTER TABLE pm.projects ADD COLUMN IF NOT EXISTS budget DECIMAL(12,2);
ALTER TABLE pm.projects ADD COLUMN IF NOT EXISTS spent DECIMAL(12,2) DEFAULT 0;
ALTER TABLE pm.projects ADD COLUMN IF NOT EXISTS budget_type VARCHAR(20) DEFAULT 'fixed'; -- 'fixed', 'time_and_materials'
ALTER TABLE pm.projects ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2);
ALTER TABLE pm.projects ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'EUR';

-- Task estimates & costs
ALTER TABLE pm.tasks ADD COLUMN IF NOT EXISTS cost_estimate DECIMAL(10,2);
ALTER TABLE pm.tasks ADD COLUMN IF NOT EXISTS actual_cost DECIMAL(10,2) DEFAULT 0;

-- Expenses (materiali, servizi esterni, etc)
CREATE TABLE IF NOT EXISTS pm.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  project_id UUID NOT NULL,
  task_id UUID,

  expense_date DATE NOT NULL,
  category_id UUID,
  description TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'EUR',

  -- Receipt tracking
  receipt_url TEXT,
  receipt_number VARCHAR(100),
  vendor_name VARCHAR(255),

  -- Billing
  is_billable BOOLEAN DEFAULT TRUE,
  billed BOOLEAN DEFAULT FALSE,
  invoice_id UUID,

  -- Who submitted
  submitted_by UUID NOT NULL,
  submitted_by_name VARCHAR(255),
  approved_by UUID,
  approval_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'

  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_expense_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_expense_project FOREIGN KEY (project_id) REFERENCES pm.projects(id) ON DELETE CASCADE,
  CONSTRAINT fk_expense_task FOREIGN KEY (task_id) REFERENCES pm.tasks(id) ON DELETE SET NULL,
  CONSTRAINT fk_expense_category FOREIGN KEY (category_id) REFERENCES pm.cost_categories(id) ON DELETE SET NULL
);

-- Time logs with rates (già esiste pm.time_logs, aggiungiamo colonne)
ALTER TABLE pm.time_logs ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2);
ALTER TABLE pm.time_logs ADD COLUMN IF NOT EXISTS cost DECIMAL(10,2);
ALTER TABLE pm.time_logs ADD COLUMN IF NOT EXISTS billable BOOLEAN DEFAULT TRUE;
ALTER TABLE pm.time_logs ADD COLUMN IF NOT EXISTS billed BOOLEAN DEFAULT FALSE;
ALTER TABLE pm.time_logs ADD COLUMN IF NOT EXISTS invoice_id UUID;

-- Invoices
CREATE TABLE IF NOT EXISTS pm.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  project_id UUID NOT NULL,

  invoice_number VARCHAR(50) NOT NULL,
  invoice_date DATE NOT NULL,
  due_date DATE,

  subtotal DECIMAL(12,2) NOT NULL,
  tax_rate DECIMAL(5,2) DEFAULT 0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  total DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'EUR',

  -- Client info
  client_name VARCHAR(255),
  client_email VARCHAR(255),
  client_address TEXT,

  status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  paid_date DATE,

  notes TEXT,
  terms TEXT,

  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_invoice_project FOREIGN KEY (project_id) REFERENCES pm.projects(id) ON DELETE CASCADE,
  UNIQUE(tenant_id, invoice_number)
);

-- Budget alerts
CREATE TABLE IF NOT EXISTS pm.budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  project_id UUID NOT NULL,

  alert_type VARCHAR(50) NOT NULL, -- 'threshold_reached', 'budget_exceeded', 'projected_overrun'
  threshold_percentage INTEGER, -- Alert at 80%, 100%, etc
  current_percentage DECIMAL(5,2),
  amount_over DECIMAL(12,2),

  triggered_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged BOOLEAN DEFAULT FALSE,
  acknowledged_by UUID,
  acknowledged_at TIMESTAMPTZ,

  CONSTRAINT fk_alert_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_alert_project FOREIGN KEY (project_id) REFERENCES pm.projects(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_expenses_project ON pm.expenses(project_id);
CREATE INDEX idx_expenses_date ON pm.expenses(expense_date);
CREATE INDEX idx_expenses_billable ON pm.expenses(is_billable, billed);
CREATE INDEX idx_invoices_project ON pm.invoices(project_id);
CREATE INDEX idx_invoices_status ON pm.invoices(status);
CREATE INDEX idx_budget_alerts_project ON pm.budget_alerts(project_id);

-- Insert default cost categories
INSERT INTO pm.cost_categories (tenant_id, category_name, category_code, default_rate, billing_type, color) VALUES
('00000000-0000-0000-0000-000000000001', 'Design Work', 'DESIGN', 75.00, 'hourly', '#3B82F6'),
('00000000-0000-0000-0000-000000000001', 'Development', 'DEV', 100.00, 'hourly', '#10B981'),
('00000000-0000-0000-0000-000000000001', 'Content Writing', 'WRITING', 50.00, 'hourly', '#F59E0B'),
('00000000-0000-0000-0000-000000000001', 'Project Management', 'PM', 80.00, 'hourly', '#8B5CF6'),
('00000000-0000-0000-0000-000000000001', 'Printing', 'PRINT', 0, 'unit', '#EF4444'),
('00000000-0000-0000-0000-000000000001', 'Photography', 'PHOTO', 150.00, 'unit', '#EC4899'),
('00000000-0000-0000-0000-000000000001', 'Travel & Expenses', 'TRAVEL', 0, 'fixed', '#6B7280'),
('00000000-0000-0000-0000-000000000001', 'External Services', 'EXTERNAL', 0, 'fixed', '#14B8A6');

-- Function to update project costs
CREATE OR REPLACE FUNCTION pm.update_project_costs()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate total spent from time logs and expenses
  UPDATE pm.projects p
  SET spent = COALESCE((
    SELECT SUM(COALESCE(cost, 0))
    FROM pm.time_logs
    WHERE task_id IN (SELECT id FROM pm.tasks WHERE project_id = p.id)
      AND deleted_at IS NULL
  ), 0) + COALESCE((
    SELECT SUM(amount)
    FROM pm.expenses
    WHERE project_id = p.id
      AND approval_status = 'approved'
  ), 0),
  updated_at = NOW()
  WHERE id = NEW.project_id OR id = (SELECT project_id FROM pm.tasks WHERE id = NEW.task_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update costs
CREATE TRIGGER trigger_update_costs_on_timelog
  AFTER INSERT OR UPDATE ON pm.time_logs
  FOR EACH ROW
  EXECUTE FUNCTION pm.update_project_costs();

CREATE TRIGGER trigger_update_costs_on_expense
  AFTER INSERT OR UPDATE ON pm.expenses
  FOR EACH ROW
  EXECUTE FUNCTION pm.update_project_costs();

-- Function to check budget alerts
CREATE OR REPLACE FUNCTION pm.check_budget_alerts()
RETURNS TRIGGER AS $$
DECLARE
  v_budget DECIMAL(12,2);
  v_spent DECIMAL(12,2);
  v_percentage DECIMAL(5,2);
BEGIN
  SELECT budget, spent INTO v_budget, v_spent
  FROM pm.projects
  WHERE id = NEW.project_id;

  IF v_budget IS NOT NULL AND v_budget > 0 THEN
    v_percentage := (v_spent / v_budget) * 100;

    -- Alert at 80%, 100%
    IF v_percentage >= 80 AND NOT EXISTS (
      SELECT 1 FROM pm.budget_alerts
      WHERE project_id = NEW.project_id
        AND threshold_percentage = 80
        AND triggered_at > NOW() - INTERVAL '7 days'
    ) THEN
      INSERT INTO pm.budget_alerts (tenant_id, project_id, alert_type, threshold_percentage, current_percentage)
      VALUES (NEW.tenant_id, NEW.project_id, 'threshold_reached', 80, v_percentage);
    END IF;

    IF v_percentage >= 100 AND NOT EXISTS (
      SELECT 1 FROM pm.budget_alerts
      WHERE project_id = NEW.project_id
        AND threshold_percentage = 100
        AND triggered_at > NOW() - INTERVAL '7 days'
    ) THEN
      INSERT INTO pm.budget_alerts (tenant_id, project_id, alert_type, threshold_percentage, current_percentage, amount_over)
      VALUES (NEW.tenant_id, NEW.project_id, 'budget_exceeded', 100, v_percentage, v_spent - v_budget);
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_budget_alerts
  AFTER INSERT OR UPDATE ON pm.expenses
  FOR EACH ROW
  EXECUTE FUNCTION pm.check_budget_alerts();

COMMENT ON TABLE pm.cost_categories IS 'Categories for expenses and time tracking rates';
COMMENT ON TABLE pm.expenses IS 'Project expenses (materials, external services, travel)';
COMMENT ON TABLE pm.invoices IS 'Client invoices for billable work';
COMMENT ON TABLE pm.budget_alerts IS 'Automated alerts when budget thresholds are reached';
