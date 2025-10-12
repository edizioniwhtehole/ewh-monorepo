-- Complete Admin Menu Reorganization
-- Comprehensive hierarchical menu for all services and features

-- First, clear existing menu items (except core ones we want to keep)
DELETE FROM plugins.page_definitions WHERE is_system_page = true AND page_id NOT IN ('admin-dashboard');

-- ============================================================================
-- SECTION 1: MAIN DASHBOARD & OVERVIEW
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
('admin-dashboard', 'Dashboard', '/admin/dashboard', 'Main control panel and overview', 'LayoutDashboard', 1, true, NULL),
('admin-overview', 'System Overview', '/admin/overview', 'Platform health and status', 'Activity', 2, true, NULL);

-- ============================================================================
-- SECTION 2: MONITORING & OPERATIONS (Enterprise-Grade)
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Monitoring Section
('monitoring-root', 'Monitoring & Ops', '/admin/monitoring', 'System monitoring and operations', 'Activity', 10, true, NULL),

-- Sub-items
('monitoring-enterprise', 'Enterprise Dashboard', '/admin/enterprise-monitoring', 'Comprehensive observability dashboard', 'BarChart3', 11, true, 'monitoring-root'),
('monitoring-services', 'Services Health', '/admin/monitoring', 'Service health and metrics', 'Cpu', 12, true, 'monitoring-root'),
('monitoring-metrics', 'Custom Metrics', '/god-mode/metrics-config', 'Configure custom application metrics', 'LineChart', 13, true, 'monitoring-root'),
('monitoring-logs', 'Log Aggregation', '/admin/logs', 'Centralized log management', 'FileText', 14, true, 'monitoring-root'),
('monitoring-alerts', 'Alerts & SLOs', '/admin/alerts', 'Alert rules and SLO tracking', 'Bell', 15, true, 'monitoring-root'),
('monitoring-incidents', 'Incidents', '/admin/incidents', 'Incident management and postmortems', 'AlertTriangle', 16, true, 'monitoring-root');

-- ============================================================================
-- SECTION 3: INFRASTRUCTURE & DEPLOYMENT
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Infrastructure Section
('infrastructure-root', 'Infrastructure', '/admin/infrastructure', 'Platform infrastructure management', 'Server', 20, true, NULL),

-- Sub-items
('infrastructure-map', 'Service Topology', '/admin/infrastructure-map', 'Visual service dependency map', 'GitBranch', 21, true, 'infrastructure-root'),
('infrastructure-services', 'Service Registry', '/admin/services', 'All platform services and status', 'Database', 22, true, 'infrastructure-root'),
('infrastructure-deployments', 'Deployments', '/admin/deployments', 'Deployment history and rollbacks', 'Rocket', 23, true, 'infrastructure-root'),
('infrastructure-gateway', 'API Gateway', '/admin/gateway-enterprise', 'Gateway configuration and routing', 'Router', 24, true, 'infrastructure-root'),
('infrastructure-nodes', 'Service Nodes', '/admin/service-nodes', 'N8N workflow nodes registry', 'Box', 25, true, 'infrastructure-root');

-- ============================================================================
-- SECTION 4: MULTI-TENANCY & TENANTS
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Tenancy Section
('tenancy-root', 'Tenants & Billing', '/admin/tenants', 'Tenant and billing management', 'Users', 30, true, NULL),

-- Sub-items
('tenancy-tenants', 'All Tenants', '/admin/tenants', 'Manage all platform tenants', 'Building', 31, true, 'tenancy-root'),
('tenancy-packages', 'Packages & Features', '/admin/packages', 'Feature packages and pricing', 'Package', 32, true, 'tenancy-root'),
('tenancy-billing', 'Billing & Invoices', '/admin/billing', 'Billing, subscriptions, and invoices', 'DollarSign', 33, true, 'tenancy-root'),
('tenancy-migration', 'Tenant Migration', '/admin/tenant-migration', 'Migrate tenants between isolation tiers', 'Move', 34, true, 'tenancy-root'),
('tenancy-verticals', 'Vertical Markets', '/admin/verticals', 'Manage vertical market configurations', 'Layers', 35, true, 'tenancy-root');

-- ============================================================================
-- SECTION 5: CREATIVE SERVICES (Content & Media)
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Creative Section
('creative-root', 'Creative Studio', '/admin/creative', 'Content and media management', 'Palette', 40, true, NULL),

-- Digital Asset Management
('creative-dam', 'Asset Management (DAM)', '/admin/dam', 'Digital Asset Management system', 'FolderOpen', 41, true, 'creative-root'),
('creative-media', 'Media Library', '/admin/media', 'Global media library and uploads', 'Image', 42, true, 'creative-root'),

-- Content Services
('creative-content', 'Content CMS', '/admin/content', 'Headless CMS for content', 'FileText', 43, true, 'creative-root'),
('creative-writer', 'AI Text Lab', '/dashboard/apps/text-lab/ai-text-generator', 'AI-powered text generation', 'Wand2', 44, true, 'creative-root'),
('creative-kb', 'Knowledge Base', '/admin/kb', 'Documentation and help articles', 'BookOpen', 45, true, 'creative-root'),

-- Visual Editors
('creative-image', 'Image Editor', '/dashboard/apps/image-studio/photo-editor', 'Advanced image editing', 'ImageIcon', 46, true, 'creative-root'),
('creative-vector', 'Vector Lab', '/dashboard/apps/vector-lab/vector-editor', 'Vector graphics editor', 'PenTool', 47, true, 'creative-root'),
('creative-layout', 'Layout Studio', '/dashboard/apps/layout-studio/layout-editor', 'Desktop publishing and layout', 'Layout', 48, true, 'creative-root'),
('creative-mockup', 'Mockup Creator', '/dashboard/apps/mockup-studio/mockup-creator', '3D mockup generation', 'Box', 49, true, 'creative-root'),

-- Video Services
('creative-video', 'Video Studio', '/admin/video', 'Video encoding and streaming', 'Video', 50, true, 'creative-root');

-- ============================================================================
-- SECTION 6: PUBLISHING & SITES
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Publishing Section
('publishing-root', 'Publishing & Sites', '/admin/publishing', 'Website and publishing tools', 'Globe', 60, true, NULL),

-- Sub-items
('publishing-sites', 'Site Builder', '/admin/site-builder', 'Build and manage websites', 'Globe', 61, true, 'publishing-root'),
('publishing-pages', 'Landing Pages', '/admin/landing-pages', 'Landing page management', 'FileText', 62, true, 'publishing-root'),
('publishing-renderer', 'Site Renderer', '/admin/site-renderer', 'SSR and rendering engine', 'Monitor', 63, true, 'publishing-root'),
('publishing-publisher', 'Site Publisher', '/admin/site-publisher', 'Deploy and publish sites', 'Upload', 64, true, 'publishing-root'),
('publishing-search', 'Search Engine', '/admin/search', 'Meilisearch configuration', 'Search', 65, true, 'publishing-root');

-- ============================================================================
-- SECTION 7: E-COMMERCE & ERP
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main ERP Section
('erp-root', 'ERP & E-Commerce', '/admin/erp', 'Business management systems', 'ShoppingCart', 70, true, NULL),

-- Products & Catalog
('erp-products', 'Products', '/admin/products', 'Product catalog management', 'Package', 71, true, 'erp-root'),
('erp-inventory', 'Inventory', '/admin/inventory', 'Stock and warehouse management', 'Warehouse', 72, true, 'erp-root'),
('erp-channels', 'Sales Channels', '/admin/channels', 'Multi-channel management', 'Store', 73, true, 'erp-root'),

-- Sales & Orders
('erp-orders', 'Orders', '/admin/orders', 'Order management', 'ShoppingBag', 74, true, 'erp-root'),
('erp-quotation', 'Quotations', '/admin/quotation', 'Quotes and estimates', 'FileSpreadsheet', 75, true, 'erp-root'),
('erp-shipping', 'Shipping', '/admin/shipping', 'Shipping and logistics', 'Truck', 76, true, 'erp-root'),

-- Procurement & Production
('erp-procurement', 'Procurement', '/admin/procurement', 'Purchase orders and suppliers', 'ShoppingBasket', 77, true, 'erp-root'),
('erp-mrp', 'Production (MRP)', '/admin/mrp', 'Material Requirements Planning', 'Factory', 78, true, 'erp-root'),

-- CRM
('erp-crm', 'CRM', '/admin/crm', 'Customer relationship management', 'Users', 79, true, 'erp-root');

-- ============================================================================
-- SECTION 8: COLLABORATION & COMMUNICATION
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Collaboration Section
('collab-root', 'Collaboration', '/admin/collaboration', 'Team collaboration tools', 'Users', 80, true, NULL),

-- Sub-items
('collab-projects', 'Projects', '/admin/projects', 'Project management', 'Folder', 81, true, 'collab-root'),
('collab-pm', 'Project Management', '/admin/pm', 'Advanced project tracking', 'Trello', 82, true, 'collab-root'),
('collab-boards', 'Boards (Kanban)', '/admin/boards', 'Kanban boards and tasks', 'LayoutGrid', 83, true, 'collab-root'),
('collab-chat', 'Team Chat', '/admin/chat', 'Real-time team messaging', 'MessageSquare', 84, true, 'collab-root'),
('collab-collab', 'Real-time Collab', '/admin/collab', 'Live document collaboration', 'Users', 85, true, 'collab-root'),
('collab-forum', 'Forum', '/admin/forum', 'Discussion forums', 'MessageCircle', 86, true, 'collab-root'),
('collab-support', 'Support Tickets', '/admin/support', 'Help desk and ticketing', 'LifeBuoy', 87, true, 'collab-root');

-- ============================================================================
-- SECTION 9: COMMUNICATION & MARKETING
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Communication Section
('comm-root', 'Communication', '/admin/communication', 'Marketing and communication tools', 'Mail', 90, true, NULL),

-- Sub-items
('comm-email', 'Email Client', '/admin/email', 'Integrated email client', 'Mail', 91, true, 'comm-root'),
('comm-campaigns', 'Campaigns', '/admin/campaigns', 'Marketing campaigns', 'Megaphone', 92, true, 'comm-root'),
('comm-forms', 'Forms', '/admin/forms', 'Form builder and submissions', 'FileInput', 93, true, 'comm-root'),
('comm-enrichment', 'Data Enrichment', '/admin/enrichment', 'Contact data enrichment', 'Database', 94, true, 'comm-root');

-- ============================================================================
-- SECTION 10: HR & WORKFORCE
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main HR Section
('hr-root', 'HR & Workforce', '/admin/hr', 'Human resources management', 'Users', 100, true, NULL),

-- Sub-items
('hr-employees', 'Employees', '/dashboard/hr/employees', 'Employee directory', 'User', 101, true, 'hr-root'),
('hr-timesheet', 'Timesheet', '/dashboard/hr/timesheet', 'Time tracking', 'Clock', 102, true, 'hr-root'),
('hr-attendance', 'Attendance', '/dashboard/hr/attendance', 'Attendance tracking', 'Calendar', 103, true, 'hr-root'),
('hr-contracts', 'Contracts', '/dashboard/hr/contracts', 'Employment contracts', 'FileText', 104, true, 'hr-root'),
('hr-payslips', 'Payslips', '/dashboard/hr/payslips', 'Salary and payslips', 'DollarSign', 105, true, 'hr-root'),
('hr-expenses', 'Expenses', '/dashboard/hr/expenses', 'Expense management', 'Receipt', 106, true, 'hr-root'),
('hr-trips', 'Business Trips', '/dashboard/hr/trips', 'Travel management', 'Plane', 107, true, 'hr-root');

-- ============================================================================
-- SECTION 11: ANALYTICS & BI
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Analytics Section
('analytics-root', 'Analytics & BI', '/admin/analytics', 'Business intelligence and analytics', 'BarChart3', 110, true, NULL),

-- Sub-items
('analytics-bi', 'BI Dashboard', '/admin/bi', 'Business intelligence dashboards', 'BarChart', 111, true, 'analytics-root'),
('analytics-reports', 'Reports', '/dashboard/admin/reports', 'Custom reports', 'FileText', 112, true, 'analytics-root'),
('analytics-metrics', 'Metrics Overview', '/admin/metrics', 'Platform-wide metrics', 'TrendingUp', 113, true, 'analytics-root');

-- ============================================================================
-- SECTION 12: AUTOMATION & WORKFLOWS
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Automation Section
('automation-root', 'Automation', '/admin/automation', 'Workflow automation and AI', 'Zap', 120, true, NULL),

-- Sub-items
('automation-workflows', 'Workflow Builder', '/admin/workflow-builder', 'Visual workflow automation', 'GitBranch', 121, true, 'automation-root'),
('automation-assistant', 'AI Assistant', '/admin/assistant', 'AI-powered virtual assistant', 'Bot', 122, true, 'automation-root'),
('automation-integrations', 'API Integrations', '/admin/api-integrations', 'Third-party integrations', 'Plug', 123, true, 'automation-root'),
('automation-connectors', 'Web Connectors', '/admin/connectors', 'Shopify, WordPress, etc.', 'Link', 124, true, 'automation-root');

-- ============================================================================
-- SECTION 13: PLUGINS & EXTENSIONS
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Plugins Section
('plugins-root', 'Plugins & Extensions', '/admin/plugins', 'Plugin system management', 'Puzzle', 130, true, NULL),

-- Sub-items
('plugins-manager', 'Plugin Manager', '/god-mode/plugins', 'Install and manage plugins', 'Package', 131, true, 'plugins-root'),
('plugins-widgets', 'Widget Gallery', '/god-mode/widgets', 'Browse available widgets', 'LayoutGrid', 132, true, 'plugins-root'),
('plugins-marketplace', 'Marketplace', '/admin/plugin-marketplace', 'Plugin marketplace (coming soon)', 'Store', 133, true, 'plugins-root');

-- ============================================================================
-- SECTION 14: GOD MODE (Advanced Admin)
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main God Mode Section
('godmode-root', 'God Mode', '/god-mode', 'Advanced platform configuration', 'Wand2', 140, true, NULL),

-- Page Builder & UI
('godmode-pages', 'Page Builder', '/god-mode/page-builder-unified', 'Build custom admin pages', 'Layout', 141, true, 'godmode-root'),
('godmode-elementor', 'Elementor Builder', '/god-mode/elementor-builder', 'Drag-and-drop page builder', 'Layers', 142, true, 'godmode-root'),
('godmode-templates', 'Page Templates', '/god-mode/page-templates', 'Template management', 'FileText', 143, true, 'godmode-root'),
('godmode-menu', 'Menu Editor', '/god-mode/menu-editor', 'Configure navigation menus', 'Menu', 144, true, 'godmode-root'),

-- Developer Tools
('godmode-terminal', 'Terminal', '/god-mode/terminal', 'Integrated terminal', 'Terminal', 145, true, 'godmode-root'),
('godmode-database', 'Database Query', '/god-mode/database-query', 'Direct database access', 'Database', 146, true, 'godmode-root'),
('godmode-api-test', 'API Tester', '/god-mode/api-test', 'Test API endpoints', 'Code', 147, true, 'godmode-root'),

-- AI & Automation
('godmode-prompts', 'Prompt Library', '/god-mode/prompt-library', 'AI prompt management', 'BookOpen', 148, true, 'godmode-root'),
('godmode-commands', 'Command Matrix', '/god-mode/command-matrix', 'Command palette configuration', 'Grid', 149, true, 'godmode-root');

-- ============================================================================
-- SECTION 15: SYSTEM SETTINGS
-- ============================================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, parent_page_id) VALUES
-- Main Settings Section
('settings-root', 'System Settings', '/admin/settings', 'Platform configuration', 'Settings', 150, true, NULL),

-- Sub-items
('settings-general', 'General Settings', '/admin/settings/general', 'Platform-wide settings', 'Sliders', 151, true, 'settings-root'),
('settings-security', 'Security', '/admin/settings/security', 'Security configuration', 'Shield', 152, true, 'settings-root'),
('settings-auth', 'Authentication', '/admin/settings/auth', 'Auth providers and SSO', 'Key', 153, true, 'settings-root'),
('settings-i18n', 'Internationalization', '/admin/settings/i18n', 'Language and localization', 'Globe', 154, true, 'settings-root'),
('settings-storage', 'Storage', '/admin/settings/storage', 'S3 and storage config', 'HardDrive', 155, true, 'settings-root'),
('settings-email', 'Email Settings', '/admin/settings/email', 'SMTP and email config', 'Mail', 156, true, 'settings-root'),
('settings-backup', 'Backup & Restore', '/admin/settings/backup', 'Database backups', 'Archive', 157, true, 'settings-root');

-- ============================================================================
-- Add parent_id index for hierarchical queries
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_page_definitions_parent ON plugins.page_definitions(parent_page_id);
CREATE INDEX IF NOT EXISTS idx_page_definitions_menu_order ON plugins.page_definitions(menu_position);

-- ============================================================================
-- Create view for hierarchical menu
-- ============================================================================

CREATE OR REPLACE VIEW plugins.menu_hierarchy AS
WITH RECURSIVE menu_tree AS (
  -- Root level items
  SELECT
    page_id,
    name,
    slug,
    description,
    icon,
    menu_position,
    parent_page_id,
    1 as level,
    ARRAY[menu_position] as path,
    name as full_path
  FROM plugins.page_definitions
  WHERE parent_page_id IS NULL AND is_system_page = true

  UNION ALL

  -- Child items
  SELECT
    p.page_id,
    p.name,
    p.slug,
    p.description,
    p.icon,
    p.menu_position,
    p.parent_page_id,
    mt.level + 1,
    mt.path || p.menu_position,
    mt.full_path || ' > ' || p.name
  FROM plugins.page_definitions p
  INNER JOIN menu_tree mt ON p.parent_page_id = mt.page_id
  WHERE p.is_system_page = true
)
SELECT * FROM menu_tree
ORDER BY path;

COMMENT ON VIEW plugins.menu_hierarchy IS 'Hierarchical view of admin menu structure';

-- ============================================================================
-- Summary statistics
-- ============================================================================

DO $$
DECLARE
  total_items INT;
  root_items INT;
  child_items INT;
BEGIN
  SELECT COUNT(*) INTO total_items FROM plugins.page_definitions WHERE is_system_page = true;
  SELECT COUNT(*) INTO root_items FROM plugins.page_definitions WHERE is_system_page = true AND parent_page_id IS NULL;
  SELECT COUNT(*) INTO child_items FROM plugins.page_definitions WHERE is_system_page = true AND parent_page_id IS NOT NULL;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'Admin Menu Reorganization Complete';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total menu items: %', total_items;
  RAISE NOTICE 'Root sections: %', root_items;
  RAISE NOTICE 'Sub-items: %', child_items;
  RAISE NOTICE '========================================';
END $$;
