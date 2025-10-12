-- Migration: Plugin Management System
-- Description: Sistema per gestire plugin del page builder a livello piattaforma e tenant
-- Author: AI Assistant
-- Date: 2025-10-11

BEGIN;

-- ============================================================================
-- PLATFORM PLUGIN SETTINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS cms.platform_plugin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_key VARCHAR(100) UNIQUE NOT NULL,
  plugin_name VARCHAR(255) NOT NULL,
  plugin_description TEXT,
  plugin_category VARCHAR(50), -- 'blocks', 'components', 'forms', 'sections', 'interactive', 'content', 'templates', 'preset'
  block_count INTEGER DEFAULT 0, -- numero di blocchi forniti dal plugin
  is_enabled_globally BOOLEAN DEFAULT true,
  is_core_plugin BOOLEAN DEFAULT false, -- plugin core non possono essere disabilitati
  config JSONB DEFAULT '{}'::jsonb, -- configurazione globale del plugin
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indici
CREATE INDEX IF NOT EXISTS idx_platform_plugin_category ON cms.platform_plugin_settings(plugin_category);
CREATE INDEX IF NOT EXISTS idx_platform_plugin_enabled ON cms.platform_plugin_settings(is_enabled_globally);

-- ============================================================================
-- TENANT PLUGIN SETTINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS cms.tenant_plugin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  plugin_key VARCHAR(100) NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  config JSONB DEFAULT '{}'::jsonb, -- override configurazione per questo tenant
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, plugin_key)
);

-- Foreign key verrà aggiunta dopo aver verificato che platform_plugin_settings esiste
-- ALTER TABLE cms.tenant_plugin_settings
--   ADD CONSTRAINT fk_tenant_plugin_key
--   FOREIGN KEY (plugin_key) REFERENCES cms.platform_plugin_settings(plugin_key) ON DELETE CASCADE;

-- Indici
CREATE INDEX IF NOT EXISTS idx_tenant_plugin_tenant ON cms.tenant_plugin_settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_plugin_enabled ON cms.tenant_plugin_settings(tenant_id, is_enabled);
CREATE INDEX IF NOT EXISTS idx_tenant_plugin_key ON cms.tenant_plugin_settings(plugin_key);

-- ============================================================================
-- TRIGGER: Updated At
-- ============================================================================

CREATE OR REPLACE FUNCTION cms.update_plugin_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER platform_plugin_settings_updated_at
  BEFORE UPDATE ON cms.platform_plugin_settings
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_plugin_settings_timestamp();

CREATE TRIGGER tenant_plugin_settings_updated_at
  BEFORE UPDATE ON cms.tenant_plugin_settings
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_plugin_settings_timestamp();

-- ============================================================================
-- INITIAL DATA: Platform Plugins
-- ============================================================================

INSERT INTO cms.platform_plugin_settings
  (plugin_key, plugin_name, plugin_description, plugin_category, block_count, is_core_plugin, is_enabled_globally)
VALUES
  -- Core plugin (always enabled)
  ('grapesjs-blocks-basic', 'Basic Blocks', 'Blocchi fondamentali: colonne, testo, link, immagini, video, mappe', 'blocks', 11, true, true),

  -- GrapesJS Preset & Extensions
  ('grapesjs-preset-webpage', 'Webpage Preset', 'Preset completo con forms, navbar, countdown, tabs e custom code', 'preset', 45, false, true),

  -- Custom Shadcn Blocks
  ('shadcn-blocks', 'Shadcn Blocks', 'Componenti UI moderni: container, section, grid, card, button, badge, input, textarea', 'components', 15, false, true),
  ('shadcn-blocks-extended', 'Shadcn Extended', 'Sezioni avanzate: hero, features, pricing, testimonials, FAQ, accordion, tabs, stats, team', 'sections', 11, false, true),

  -- Interactive & Content
  ('interactive-blocks', 'Interactive Blocks', 'Elementi interattivi: tabs, accordion, modal, carousel, toast, dropdown', 'interactive', 6, false, true),
  ('content-blocks', 'Content Blocks', 'Blocchi ricchi: WYSIWYG editor con AI, gestione immagini DAM, link avanzati', 'content', 3, false, true),

  -- Templates
  ('templates', 'Page Templates', 'Template predefiniti: landing page, blog post, product page, contact form', 'templates', 4, false, true)

ON CONFLICT (plugin_key) DO UPDATE SET
  plugin_name = EXCLUDED.plugin_name,
  plugin_description = EXCLUDED.plugin_description,
  plugin_category = EXCLUDED.plugin_category,
  block_count = EXCLUDED.block_count,
  updated_at = NOW();

-- ============================================================================
-- FUNCTION: Get Enabled Plugins for Tenant
-- ============================================================================

CREATE OR REPLACE FUNCTION cms.get_enabled_plugins_for_tenant(
  p_tenant_id UUID
)
RETURNS TABLE (
  plugin_key VARCHAR(100),
  plugin_name VARCHAR(255),
  plugin_description TEXT,
  plugin_category VARCHAR(50),
  block_count INTEGER,
  is_core_plugin BOOLEAN,
  tenant_config JSONB,
  platform_config JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pps.plugin_key,
    pps.plugin_name,
    pps.plugin_description,
    pps.plugin_category,
    pps.block_count,
    pps.is_core_plugin,
    COALESCE(tps.config, '{}'::jsonb) as tenant_config,
    pps.config as platform_config
  FROM cms.platform_plugin_settings pps
  LEFT JOIN cms.tenant_plugin_settings tps
    ON tps.plugin_key = pps.plugin_key
    AND tps.tenant_id = p_tenant_id
  WHERE
    pps.is_enabled_globally = true
    AND (
      pps.is_core_plugin = true -- core plugins sempre abilitati
      OR tps.is_enabled IS NULL -- se non specificato dal tenant, usa default (abilitato)
      OR tps.is_enabled = true   -- o esplicitamente abilitato dal tenant
    )
  ORDER BY
    pps.is_core_plugin DESC, -- core prima
    pps.plugin_category,
    pps.plugin_name;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCTION: Get Plugin Statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION cms.get_plugin_statistics()
RETURNS TABLE (
  total_plugins INTEGER,
  enabled_plugins INTEGER,
  core_plugins INTEGER,
  total_blocks INTEGER,
  total_tenants_with_custom_settings INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::INTEGER as total_plugins,
    COUNT(*) FILTER (WHERE is_enabled_globally = true)::INTEGER as enabled_plugins,
    COUNT(*) FILTER (WHERE is_core_plugin = true)::INTEGER as core_plugins,
    SUM(block_count)::INTEGER as total_blocks,
    (SELECT COUNT(DISTINCT tenant_id)::INTEGER FROM cms.tenant_plugin_settings) as total_tenants_with_custom_settings
  FROM cms.platform_plugin_settings;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE cms.platform_plugin_settings IS 'Plugin disponibili a livello piattaforma per il page builder';
COMMENT ON TABLE cms.tenant_plugin_settings IS 'Configurazione plugin specifica per ogni tenant';
COMMENT ON FUNCTION cms.get_enabled_plugins_for_tenant IS 'Restituisce i plugin abilitati per un tenant specifico';
COMMENT ON FUNCTION cms.get_plugin_statistics IS 'Statistiche sui plugin della piattaforma';

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verifica plugin installati
-- SELECT * FROM cms.platform_plugin_settings ORDER BY plugin_category, plugin_name;

-- Verifica statistiche
-- SELECT * FROM cms.get_plugin_statistics();

-- Test: Ottieni plugin per un tenant
-- SELECT * FROM cms.get_enabled_plugins_for_tenant('00000000-0000-0000-0000-000000000000');
