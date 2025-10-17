-- Migration: Add Services Registry and Platform Settings Pages
-- Description: Add new admin pages for services registry and platform settings
-- Date: 2025-10-14

BEGIN;

-- Insert Services Registry page
INSERT INTO plugins.page_definitions (
  page_id,
  name,
  slug,
  description,
  icon,
  parent_page_id,
  menu_position,
  layout_type,
  is_active,
  is_system_page
) VALUES (
  'admin-services-registry',
  'Services Registry',
  '/admin/services-registry',
  'View all microservices, their APIs, webhooks, and health status',
  'Server',
  NULL,
  17,
  'custom',
  true,
  true
) ON CONFLICT (page_id) DO UPDATE SET
  name = EXCLUDED.name,
  slug = EXCLUDED.slug,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  menu_position = EXCLUDED.menu_position;

-- Insert Platform Settings page
INSERT INTO plugins.page_definitions (
  page_id,
  name,
  slug,
  description,
  icon,
  parent_page_id,
  menu_position,
  layout_type,
  is_active,
  is_system_page
) VALUES (
  'admin-platform-settings',
  'Platform Settings',
  '/admin/settings/platform',
  'Configure platform-wide settings with 3-tier waterfall inheritance',
  'Settings',
  NULL,
  18,
  'custom',
  true,
  true
) ON CONFLICT (page_id) DO UPDATE SET
  name = EXCLUDED.name,
  slug = EXCLUDED.slug,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  menu_position = EXCLUDED.menu_position;

COMMIT;
