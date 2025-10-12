-- Migration 014: Register all existing widget components
-- This registers all widget components that already exist in the codebase

-- Dashboard & Overview Widgets
INSERT INTO plugins.widget_definitions (
  widget_id, plugin_id, name, category, component_path, description,
  icon, default_width, default_height, supports_realtime
) VALUES
  ('dashboard-widget', null, 'Dashboard Overview', 'dashboard', 'components/DashboardWidget', 'General dashboard overview with key metrics', 'LayoutDashboard', 12, 6, true),
  ('infrastructure-overview-widget', null, 'Infrastructure Overview', 'monitoring', 'components/InfrastructureOverviewWidget', 'Infrastructure topology and health overview', 'Network', 12, 8, true),
  ('service-health-widget', null, 'Service Health', 'monitoring', 'components/ServiceHealthWidget', 'Service health status and uptime tracking', 'HeartPulse', 6, 4, true)
ON CONFLICT (widget_id) DO UPDATE SET
  name = EXCLUDED.name,
  component_path = EXCLUDED.component_path,
  description = EXCLUDED.description;

-- Metrics & Analytics Widgets
INSERT INTO plugins.widget_definitions (
  widget_id, plugin_id, name, category, component_path, description,
  icon, default_width, default_height, supports_realtime
) VALUES
  ('metrics-timeseries-widget', null, 'Metrics Time Series', 'analytics', 'components/MetricsTimeSeriesWidget', 'Time-series metrics visualization with charts', 'LineChart', 6, 4, true),
  ('aggregated-metrics-widget', null, 'Aggregated Metrics', 'analytics', 'components/AggregatedMetricsWidget', 'Aggregated metrics across multiple services', 'BarChart3', 12, 6, true),
  ('performance-metrics-widget', null, 'Performance Metrics', 'analytics', 'components/PerformanceMetricsWidget', 'Performance metrics and response times', 'Gauge', 6, 4, true),
  ('advanced-analytics-widget', null, 'Advanced Analytics', 'analytics', 'components/AdvancedAnalyticsWidget', 'Advanced analytics and data visualization', 'TrendingUp', 12, 8, true),
  ('capacity-planning-widget', null, 'Capacity Planning', 'analytics', 'components/CapacityPlanningWidget', 'Resource capacity planning and forecasting', 'Scale', 8, 6, false)
ON CONFLICT (widget_id) DO UPDATE SET
  name = EXCLUDED.name,
  component_path = EXCLUDED.component_path,
  description = EXCLUDED.description;

-- Monitoring & Alerts Widgets
INSERT INTO plugins.widget_definitions (
  widget_id, plugin_id, name, category, component_path, description,
  icon, default_width, default_height, supports_realtime
) VALUES
  ('alerts-management-widget', null, 'Alerts Management', 'monitoring', 'components/AlertsManagementWidget', 'Manage and configure system alerts', 'Bell', 8, 6, true),
  ('alert-rules-widget', null, 'Alert Rules', 'monitoring', 'components/AlertRulesWidget', 'Configure alert rules and thresholds', 'AlertTriangle', 8, 6, false),
  ('incident-management-widget', null, 'Incident Management', 'monitoring', 'components/IncidentManagementWidget', 'Incident tracking and management', 'AlertOctagon', 12, 8, true),
  ('log-stream-widget', null, 'Log Stream', 'monitoring', 'components/LogStreamWidget', 'Real-time log streaming and filtering', 'ScrollText', 12, 6, true),
  ('notifications-config-widget', null, 'Notifications Config', 'monitoring', 'components/NotificationsConfigWidget', 'Configure notification channels and rules', 'MessageSquare', 8, 6, false)
ON CONFLICT (widget_id) DO UPDATE SET
  name = EXCLUDED.name,
  component_path = EXCLUDED.component_path,
  description = EXCLUDED.description;

-- SLO & Requests Widgets
INSERT INTO plugins.widget_definitions (
  widget_id, plugin_id, name, category, component_path, description,
  icon, default_width, default_height, supports_realtime
) VALUES
  ('slo-configuration-widget', null, 'SLO Configuration', 'monitoring', 'components/SLOConfigurationWidget', 'Service Level Objectives configuration', 'Target', 8, 6, false),
  ('slo-tracker-widget', null, 'SLO Tracker', 'monitoring', 'components/SLOTrackerWidget', 'Track SLO compliance and metrics', 'CheckCircle', 6, 4, true),
  ('service-requests-widget', null, 'Service Requests', 'monitoring', 'components/ServiceRequestsWidget', 'Monitor service requests and traffic', 'Activity', 6, 4, true)
ON CONFLICT (widget_id) DO UPDATE SET
  name = EXCLUDED.name,
  component_path = EXCLUDED.component_path,
  description = EXCLUDED.description;

-- Utility Widgets (already registered, updating)
INSERT INTO plugins.widget_definitions (
  widget_id, plugin_id, name, category, component_path, description,
  icon, default_width, default_height, supports_realtime
) VALUES
  ('widget-loader', null, 'Widget Loader', 'system', 'components/WidgetLoader', 'Dynamic widget loading utility', 'Loader', 6, 4, false),
  ('widget-picker', null, 'Widget Picker', 'system', 'components/WidgetPicker', 'Widget selection interface', 'Grid3x3', 6, 4, false)
ON CONFLICT (widget_id) DO UPDATE SET
  name = EXCLUDED.name,
  component_path = EXCLUDED.component_path,
  description = EXCLUDED.description;

-- Show all registered widgets
SELECT
  widget_id,
  name,
  category,
  icon,
  default_width || 'x' || default_height as size,
  supports_realtime as rt
FROM plugins.widget_definitions
WHERE plugin_id IS NULL
ORDER BY category, name;
