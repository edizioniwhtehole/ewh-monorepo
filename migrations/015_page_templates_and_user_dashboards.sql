-- Migration 015: Page Templates and User Dashboards
-- This adds support for page templates and user-specific dashboard customization

-- Page Templates
CREATE TABLE IF NOT EXISTS plugins.page_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100), -- e.g., dashboard, monitoring, analytics, development
  icon VARCHAR(100),
  preview_image TEXT,
  is_system_template BOOLEAN DEFAULT true,
  created_by_plugin VARCHAR(255),
  widgets JSONB DEFAULT '[]'::jsonb, -- Pre-configured widget layout
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  FOREIGN KEY (created_by_plugin) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE
);

CREATE INDEX idx_page_templates_category ON plugins.page_templates(category);

-- User Dashboards (personalized layouts)
CREATE TABLE IF NOT EXISTS plugins.user_dashboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(255) NOT NULL,
  page_id VARCHAR(255) NOT NULL,
  dashboard_name VARCHAR(255),
  is_default BOOLEAN DEFAULT false,
  layout_config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  FOREIGN KEY (page_id) REFERENCES plugins.page_definitions(page_id) ON DELETE CASCADE,
  UNIQUE(user_id, page_id, dashboard_name)
);

CREATE INDEX idx_user_dashboards_user ON plugins.user_dashboards(user_id);
CREATE INDEX idx_user_dashboards_page ON plugins.user_dashboards(page_id);

-- Role-based Dashboard Templates
CREATE TABLE IF NOT EXISTS plugins.role_dashboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_name VARCHAR(255) NOT NULL,
  page_id VARCHAR(255) NOT NULL,
  dashboard_config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  FOREIGN KEY (page_id) REFERENCES plugins.page_definitions(page_id) ON DELETE CASCADE,
  UNIQUE(role_name, page_id)
);

CREATE INDEX idx_role_dashboards_role ON plugins.role_dashboards(role_name);

-- Insert default page templates
INSERT INTO plugins.page_templates (template_id, name, description, category, icon, widgets) VALUES
  (
    'template-dashboard-overview',
    'Dashboard Overview',
    'Complete dashboard with metrics, activity, and quick actions',
    'dashboard',
    'LayoutDashboard',
    '[
      {"widget_id": "metrics-cards-widget", "grid_x": 0, "grid_y": 0, "grid_w": 12, "grid_h": 2, "config": {}},
      {"widget_id": "quick-actions-widget", "grid_x": 0, "grid_y": 2, "grid_w": 12, "grid_h": 2, "config": {}},
      {"widget_id": "service-status-widget", "grid_x": 0, "grid_y": 4, "grid_w": 6, "grid_h": 4, "config": {"maxServices": 5}},
      {"widget_id": "recent-activity-widget", "grid_x": 6, "grid_y": 4, "grid_w": 6, "grid_h": 4, "config": {"maxItems": 5}}
    ]'::jsonb
  ),
  (
    'template-monitoring',
    'Monitoring Dashboard',
    'Comprehensive monitoring with metrics, alerts, and logs',
    'monitoring',
    'Activity',
    '[
      {"widget_id": "infrastructure-overview-widget", "grid_x": 0, "grid_y": 0, "grid_w": 12, "grid_h": 6, "config": {}},
      {"widget_id": "service-health-widget", "grid_x": 0, "grid_y": 6, "grid_w": 6, "grid_h": 4, "config": {}},
      {"widget_id": "alerts-management-widget", "grid_x": 6, "grid_y": 6, "grid_w": 6, "grid_h": 4, "config": {}}
    ]'::jsonb
  ),
  (
    'template-analytics',
    'Analytics Dashboard',
    'Data analytics and visualization dashboard',
    'analytics',
    'TrendingUp',
    '[
      {"widget_id": "advanced-analytics-widget", "grid_x": 0, "grid_y": 0, "grid_w": 12, "grid_h": 6, "config": {}},
      {"widget_id": "aggregated-metrics-widget", "grid_x": 0, "grid_y": 6, "grid_w": 12, "grid_h": 4, "config": {}},
      {"widget_id": "capacity-planning-widget", "grid_x": 0, "grid_y": 10, "grid_w": 12, "grid_h": 4, "config": {}}
    ]'::jsonb
  ),
  (
    'template-development',
    'Development Dashboard',
    'Tools for developers: API testing, database queries, logs',
    'development',
    'Code',
    '[
      {"widget_id": "api-test-panel-widget", "grid_x": 0, "grid_y": 0, "grid_w": 8, "grid_h": 6, "config": {}},
      {"widget_id": "database-query-widget", "grid_x": 0, "grid_y": 6, "grid_w": 8, "grid_h": 6, "config": {}},
      {"widget_id": "log-stream-widget", "grid_x": 8, "grid_y": 0, "grid_w": 4, "grid_h": 12, "config": {}}
    ]'::jsonb
  ),
  (
    'template-infrastructure',
    'Infrastructure Dashboard',
    'Network topology and infrastructure monitoring',
    'infrastructure',
    'Network',
    '[
      {"widget_id": "topology-map-widget", "grid_x": 0, "grid_y": 0, "grid_w": 12, "grid_h": 8, "config": {}},
      {"widget_id": "service-status-widget", "grid_x": 0, "grid_y": 8, "grid_w": 6, "grid_h": 4, "config": {}},
      {"widget_id": "performance-metrics-widget", "grid_x": 6, "grid_y": 8, "grid_w": 6, "grid_h": 4, "config": {}}
    ]'::jsonb
  )
ON CONFLICT (template_id) DO NOTHING;

-- Show created templates
SELECT template_id, name, category FROM plugins.page_templates ORDER BY category, name;
