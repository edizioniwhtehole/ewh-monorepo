-- ============================================================================
-- Migration 027: Widget Templates System
-- Sistema di template widget prefatti con configurazioni predefinite
-- ============================================================================

-- Template Categories (categorie per organizzare i template)
CREATE TABLE IF NOT EXISTS cms.widget_template_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_slug TEXT UNIQUE NOT NULL,
    category_name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    parent_category_id UUID REFERENCES cms.widget_template_categories(category_id) ON DELETE SET NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_template_categories_slug ON cms.widget_template_categories(category_slug);
CREATE INDEX idx_template_categories_active ON cms.widget_template_categories(is_active) WHERE is_active = true;
CREATE INDEX idx_template_categories_parent ON cms.widget_template_categories(parent_category_id);

-- Widget Templates (template prefatti per i widget)
CREATE TABLE IF NOT EXISTS cms.widget_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_slug TEXT UNIQUE NOT NULL,
    template_name TEXT NOT NULL,
    description TEXT,
    widget_slug TEXT NOT NULL REFERENCES cms.widget_registry(widget_slug) ON DELETE CASCADE,
    category_id UUID REFERENCES cms.widget_template_categories(category_id) ON DELETE SET NULL,

    -- Configurazione del template
    template_config JSONB DEFAULT '{}'::jsonb,  -- Configurazione predefinita
    preview_html TEXT,                          -- HTML preview del template
    preview_image TEXT,                         -- URL immagine preview
    preview_data JSONB DEFAULT '{}'::jsonb,     -- Dati di esempio per preview

    -- Metadata
    tags TEXT[],                                -- Tag per ricerca/filtraggio
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    use_cases TEXT[],                           -- Casi d'uso suggeriti

    -- Ownership & Availability
    author_type TEXT DEFAULT 'system' CHECK (author_type IN ('system', 'owner', 'tenant', 'user')),
    author_id UUID,                             -- ID dell'autore (owner/tenant/user)
    is_public BOOLEAN DEFAULT false,            -- Visibile a tutti
    is_premium BOOLEAN DEFAULT false,           -- Richiede licenza premium
    is_featured BOOLEAN DEFAULT false,          -- In evidenza

    -- Statistics
    usage_count INTEGER DEFAULT 0,
    rating_average NUMERIC(3,2) DEFAULT 0.00,
    rating_count INTEGER DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT true,
    version TEXT DEFAULT '1.0.0',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_widget_templates_slug ON cms.widget_templates(template_slug);
CREATE INDEX idx_widget_templates_widget ON cms.widget_templates(widget_slug);
CREATE INDEX idx_widget_templates_category ON cms.widget_templates(category_id);
CREATE INDEX idx_widget_templates_author ON cms.widget_templates(author_type, author_id);
CREATE INDEX idx_widget_templates_public ON cms.widget_templates(is_public) WHERE is_public = true;
CREATE INDEX idx_widget_templates_featured ON cms.widget_templates(is_featured) WHERE is_featured = true;
CREATE INDEX idx_widget_templates_active ON cms.widget_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_widget_templates_tags ON cms.widget_templates USING gin(tags);

-- Template Permissions (chi può usare quali template)
CREATE TABLE IF NOT EXISTS cms.widget_template_permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES cms.widget_templates(template_id) ON DELETE CASCADE,

    -- Target
    target_type TEXT NOT NULL CHECK (target_type IN ('owner', 'tenant', 'role', 'user')),
    target_id UUID,  -- tenant_id, role_id, user_id (NULL per owner)

    -- Permissions
    can_view BOOLEAN DEFAULT true,
    can_use BOOLEAN DEFAULT true,
    can_customize BOOLEAN DEFAULT true,
    can_duplicate BOOLEAN DEFAULT false,
    can_edit BOOLEAN DEFAULT false,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

    UNIQUE(template_id, target_type, target_id)
);

CREATE INDEX idx_template_perms_template ON cms.widget_template_permissions(template_id);
CREATE INDEX idx_template_perms_target ON cms.widget_template_permissions(target_type, target_id);

-- Template Usage Log (tracciamento utilizzo template)
CREATE TABLE IF NOT EXISTS cms.widget_template_usage (
    usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES cms.widget_templates(template_id) ON DELETE CASCADE,
    widget_instance_id UUID,  -- Riferimento a widget_instances se applicabile

    -- User context
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    page_id UUID,

    -- Customization tracking
    config_customized BOOLEAN DEFAULT false,
    customization_data JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_template_usage_template ON cms.widget_template_usage(template_id);
CREATE INDEX idx_template_usage_tenant ON cms.widget_template_usage(tenant_id);
CREATE INDEX idx_template_usage_user ON cms.widget_template_usage(user_id);
CREATE INDEX idx_template_usage_created ON cms.widget_template_usage(created_at DESC);

-- ============================================================================
-- Miglioramenti alle tabelle esistenti
-- ============================================================================

-- Aggiungi colonne per i template ai widget instances
ALTER TABLE cms.widget_instances
ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES cms.widget_templates(template_id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS is_from_template BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS template_customizations JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_widget_instances_template ON cms.widget_instances(template_id);

-- Aggiungi colonne avanzate ai permessi owner
ALTER TABLE cms.owner_widget_permissions
ADD COLUMN IF NOT EXISTS default_template_id UUID REFERENCES cms.widget_templates(template_id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS allowed_template_categories UUID[],
ADD COLUMN IF NOT EXISTS custom_config_schema JSONB,
ADD COLUMN IF NOT EXISTS allow_template_creation BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS require_approval_for_custom BOOLEAN DEFAULT false;

-- Aggiungi colonne avanzate ai permessi tenant
ALTER TABLE cms.tenant_widget_permissions
ADD COLUMN IF NOT EXISTS default_template_id UUID REFERENCES cms.widget_templates(template_id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS allowed_template_ids UUID[],
ADD COLUMN IF NOT EXISTS custom_templates_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS max_custom_templates INTEGER DEFAULT 50;

-- ============================================================================
-- Triggers
-- ============================================================================

-- Trigger per aggiornare updated_at
CREATE TRIGGER trg_template_categories_updated_at
    BEFORE UPDATE ON cms.widget_template_categories
    FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at();

CREATE TRIGGER trg_widget_templates_updated_at
    BEFORE UPDATE ON cms.widget_templates
    FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at();

CREATE TRIGGER trg_template_permissions_updated_at
    BEFORE UPDATE ON cms.widget_template_permissions
    FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at();

-- Trigger per incrementare usage_count quando viene usato un template
CREATE OR REPLACE FUNCTION cms.increment_template_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE cms.widget_templates
    SET usage_count = usage_count + 1
    WHERE template_id = NEW.template_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_template_usage_increment
    AFTER INSERT ON cms.widget_template_usage
    FOR EACH ROW EXECUTE FUNCTION cms.increment_template_usage();

-- ============================================================================
-- Functions
-- ============================================================================

-- Funzione per ottenere i template disponibili per un utente
CREATE OR REPLACE FUNCTION cms.get_available_templates(
    p_tenant_id UUID,
    p_user_id UUID,
    p_user_role TEXT,
    p_widget_slug TEXT DEFAULT NULL
)
RETURNS TABLE (
    template_id UUID,
    template_slug TEXT,
    template_name TEXT,
    description TEXT,
    widget_slug TEXT,
    category_name TEXT,
    template_config JSONB,
    preview_image TEXT,
    tags TEXT[],
    difficulty_level TEXT,
    is_premium BOOLEAN,
    is_featured BOOLEAN,
    usage_count INTEGER,
    rating_average NUMERIC,
    can_customize BOOLEAN,
    can_duplicate BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        t.template_id,
        t.template_slug,
        t.template_name,
        t.description,
        t.widget_slug,
        tc.category_name,
        t.template_config,
        t.preview_image,
        t.tags,
        t.difficulty_level,
        t.is_premium,
        t.is_featured,
        t.usage_count,
        t.rating_average,
        COALESCE(tp.can_customize, true) as can_customize,
        COALESCE(tp.can_duplicate, false) as can_duplicate
    FROM cms.widget_templates t
    LEFT JOIN cms.widget_template_categories tc ON t.category_id = tc.category_id
    LEFT JOIN cms.widget_template_permissions tp ON t.template_id = tp.template_id
        AND (
            (tp.target_type = 'tenant' AND tp.target_id = p_tenant_id) OR
            (tp.target_type = 'user' AND tp.target_id = p_user_id) OR
            (tp.target_type = 'role')
        )
    WHERE t.is_active = true
        AND (
            t.is_public = true
            OR t.author_id = p_tenant_id
            OR tp.can_view = true
        )
        AND (p_widget_slug IS NULL OR t.widget_slug = p_widget_slug)
    ORDER BY t.is_featured DESC, t.usage_count DESC, t.rating_average DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Seed Data - Categorie di Template
-- ============================================================================

INSERT INTO cms.widget_template_categories (category_slug, category_name, description, icon, display_order) VALUES
('ecommerce-product', 'E-commerce Product', 'Template per prodotti e-commerce', '🛍️', 1),
('ecommerce-cart', 'Shopping Cart', 'Template per carrelli e checkout', '🛒', 2),
('marketing-cta', 'Call to Action', 'Template per CTA e conversione', '📣', 3),
('marketing-promo', 'Promotions', 'Template per promozioni e offerte', '🎁', 4),
('content-hero', 'Hero Sections', 'Template per sezioni hero', '🎭', 5),
('content-features', 'Features', 'Template per showcase features', '⚡', 6),
('forms-contact', 'Contact Forms', 'Template per form contatto', '📧', 7),
('forms-registration', 'Registration', 'Template per registrazione', '📝', 8),
('analytics-dashboard', 'Dashboards', 'Template per dashboard analytics', '📊', 9),
('analytics-charts', 'Charts & Graphs', 'Template per grafici', '📈', 10),
('social-feed', 'Social Feeds', 'Template per feed social', '📱', 11),
('social-sharing', 'Social Sharing', 'Template per condivisione social', '🔗', 12)
ON CONFLICT (category_slug) DO NOTHING;

-- ============================================================================
-- Seed Data - Template Esempi
-- ============================================================================

-- Template: Product Card Standard
INSERT INTO cms.widget_templates (
    template_slug,
    template_name,
    description,
    widget_slug,
    category_id,
    template_config,
    tags,
    difficulty_level,
    is_public,
    is_featured,
    author_type
) VALUES (
    'product-card-standard',
    'Standard Product Card',
    'Scheda prodotto standard con immagine, titolo, prezzo e pulsante',
    'product-card',
    (SELECT category_id FROM cms.widget_template_categories WHERE category_slug = 'ecommerce-product'),
    '{"layout": "vertical", "showImage": true, "showPrice": true, "showAddToCart": true, "imageRatio": "1:1"}'::jsonb,
    ARRAY['ecommerce', 'product', 'shop', 'basic'],
    'beginner',
    true,
    true,
    'system'
) ON CONFLICT (template_slug) DO NOTHING;

-- Template: Product Card Premium
INSERT INTO cms.widget_templates (
    template_slug,
    template_name,
    description,
    widget_slug,
    category_id,
    template_config,
    tags,
    difficulty_level,
    is_public,
    is_featured,
    is_premium,
    author_type
) VALUES (
    'product-card-premium',
    'Premium Product Card',
    'Scheda prodotto premium con hover effects, wishlist e quick view',
    'product-card',
    (SELECT category_id FROM cms.widget_template_categories WHERE category_slug = 'ecommerce-product'),
    '{"layout": "vertical", "showImage": true, "showPrice": true, "showAddToCart": true, "showWishlist": true, "showQuickView": true, "hoverEffect": "zoom", "imageRatio": "4:5"}'::jsonb,
    ARRAY['ecommerce', 'product', 'shop', 'premium'],
    'intermediate',
    true,
    true,
    true,
    'system'
) ON CONFLICT (template_slug) DO NOTHING;

-- Template: Mini Cart
INSERT INTO cms.widget_templates (
    template_slug,
    template_name,
    description,
    widget_slug,
    category_id,
    template_config,
    tags,
    difficulty_level,
    is_public,
    is_featured,
    author_type
) VALUES (
    'mini-cart-dropdown',
    'Dropdown Mini Cart',
    'Mini carrello dropdown con preview prodotti',
    'mini-cart',
    (SELECT category_id FROM cms.widget_template_categories WHERE category_slug = 'ecommerce-cart'),
    '{"position": "right", "showThumbnails": true, "showQuantity": true, "showTotal": true, "maxItems": 5}'::jsonb,
    ARRAY['ecommerce', 'cart', 'checkout'],
    'beginner',
    true,
    true,
    'system'
) ON CONFLICT (template_slug) DO NOTHING;

-- Template: CTA Button Large
INSERT INTO cms.widget_templates (
    template_slug,
    template_name,
    description,
    widget_slug,
    category_id,
    template_config,
    tags,
    difficulty_level,
    is_public,
    is_featured,
    author_type
) VALUES (
    'cta-button-large',
    'Large CTA Button',
    'Pulsante CTA grande con icona e sottotitolo',
    'button',
    (SELECT category_id FROM cms.widget_template_categories WHERE category_slug = 'marketing-cta'),
    '{"size": "large", "style": "primary", "showIcon": true, "showSubtext": true, "fullWidth": true}'::jsonb,
    ARRAY['marketing', 'cta', 'conversion'],
    'beginner',
    true,
    true,
    'system'
) ON CONFLICT (template_slug) DO NOTHING;

-- Template: Dashboard KPI Card
INSERT INTO cms.widget_templates (
    template_slug,
    template_name,
    description,
    widget_slug,
    category_id,
    template_config,
    tags,
    difficulty_level,
    is_public,
    is_featured,
    author_type
) VALUES (
    'dashboard-kpi-card',
    'KPI Dashboard Card',
    'Card KPI con valore, trend e sparkline',
    'kpi-card',
    (SELECT category_id FROM cms.widget_template_categories WHERE category_slug = 'analytics-dashboard'),
    '{"showTrend": true, "showSparkline": true, "showPercentage": true, "colorScheme": "auto"}'::jsonb,
    ARRAY['analytics', 'dashboard', 'kpi', 'metrics'],
    'intermediate',
    true,
    true,
    'system'
) ON CONFLICT (template_slug) DO NOTHING;

COMMENT ON TABLE cms.widget_template_categories IS 'Categorie per organizzare i template widget';
COMMENT ON TABLE cms.widget_templates IS 'Template prefatti per widget con configurazioni predefinite';
COMMENT ON TABLE cms.widget_template_permissions IS 'Permessi per controllare chi può usare quali template';
COMMENT ON TABLE cms.widget_template_usage IS 'Log di utilizzo dei template per analytics';
