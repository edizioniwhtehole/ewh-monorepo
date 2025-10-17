# 🚀 Unified Page Builder + CMS Architecture
## Sistema Unificato con Permessi Multi-Livello

**Created:** 2025-10-10
**Status:** 🏗️ In Design
**Vision:** Un solo sistema CMS + Page Builder con controllo granulare dei permessi

---

## 🎯 Obiettivo

**UNIFICARE** i sistemi esistenti:
- ✅ **CMS** (svc-cms) - Gestione pagine widget-based
- ✅ **Page Builder** (@ewh/page-builder) - Editor Elementor-style
- ✅ **Template System** - Library Crocoblock-style
- ✅ **Widget Registry** - Sistema widget unificato
- 🆕 **Permission System** - Controllo granulare multi-livello

**ELIMINARE duplicazioni:**
- ❌ Multiple tabelle `pages` (cms.pages, workflow.page_definitions, plugins.page_definitions)
- ❌ Multiple tabelle `widgets` (cms.page_widget_configs, widgets.widget_definitions, workflow.widget_definitions)
- ❌ Multiple tabelle `templates` (cms.templates, plugins.page_templates)

---

## 🏗️ Architettura Unificata

```
┌─────────────────────────────────────────────────────────────────┐
│                        APPLICATIONS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────┐              ┌────────────────────┐     │
│  │  Admin Frontend    │              │  Tenant App        │     │
│  │  (Port 3200)       │              │  (Port 3001)       │     │
│  │                    │              │                    │     │
│  │  - Owner Config    │              │  - Tenant Config   │     │
│  │  - Widget Enabler  │              │  - User Permissions│     │
│  │  - God Mode        │              │  - Page Builder    │     │
│  └──────────┬─────────┘              └──────────┬─────────┘     │
│             │                                   │                │
│             └──────────────┬────────────────────┘                │
│                            ↓                                     │
│           ┌────────────────────────────┐                         │
│           │  CMS Frontend + Builder    │                         │
│           │  (Port 5300)               │                         │
│           │  - Page Builder UI         │                         │
│           │  - ElementorBuilder        │                         │
│           │  - Template Library        │                         │
│           │  - Widget Marketplace      │                         │
│           └──────────┬─────────────────┘                         │
│                      ↓                                            │
│           ┌────────────────────────────┐                         │
│           │  svc-cms (Unified)         │                         │
│           │  (Port 5200)               │                         │
│           │  - Pages API               │                         │
│           │  - Templates API           │                         │
│           │  - Widgets API             │                         │
│           │  - Permissions API         │                         │
│           └──────────┬─────────────────┘                         │
│                      ↓                                            │
│           ┌────────────────────────────┐                         │
│           │  PostgreSQL (Unified)      │                         │
│           │  - cms.pages               │                         │
│           │  - cms.templates           │                         │
│           │  - cms.widget_permissions  │                         │
│           │  - cms.element_permissions │                         │
│           └────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Database Schema Unificato

### 1. Pages (Unica Tabella per Tutto)

```sql
-- DROP old tables
-- DROP TABLE IF EXISTS workflow.page_definitions CASCADE;
-- DROP TABLE IF EXISTS plugins.page_definitions CASCADE;
-- Migration will consolidate data into cms.pages

-- UNIFIED Pages Table
CREATE TABLE cms.pages (
  page_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,

  -- Type & Context
  page_type TEXT NOT NULL CHECK (page_type IN ('admin', 'public', 'landing', 'email', 'tenant')),
  context TEXT NOT NULL CHECK (context IN ('internal', 'public', 'tenant')),

  -- Template Reference
  template_id UUID REFERENCES cms.templates(template_id) ON DELETE SET NULL,

  -- Content (Elementor-style structure)
  elements JSONB NOT NULL DEFAULT '[]', -- ElementorBuilder structure: sections/columns/elements

  -- Widget Composition (CMS-style, for backward compat)
  layout JSONB, -- Widget-based layout (legacy support)

  -- Styling & Meta
  page_settings JSONB DEFAULT '{}', -- Layout, maxWidth, customCSS, customJS
  meta_data JSONB DEFAULT '{}', -- SEO, OpenGraph, Twitter Cards
  styles JSONB DEFAULT '{}', -- Custom CSS overrides

  -- Landing Page Specific
  is_landing_page BOOLEAN DEFAULT FALSE,
  landing_config JSONB, -- {campaign, utm_source, conversion_goal, ab_test, etc.}

  -- Publishing
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived')),
  published_version INT,
  published_at TIMESTAMPTZ,
  scheduled_publish_at TIMESTAMPTZ,

  -- Multi-tenancy
  tenant_id UUID, -- NULL = platform page
  site_id UUID, -- For tenant sites
  domain TEXT, -- Custom domain for tenant

  -- Permissions
  required_roles TEXT[], -- Roles required to VIEW page
  required_permissions TEXT[], -- Permissions required
  owner_locked BOOLEAN DEFAULT FALSE, -- Owner locked this page config

  -- Audit
  created_by UUID NOT NULL,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pages_slug ON cms.pages(slug);
CREATE INDEX idx_pages_page_type ON cms.pages(page_type);
CREATE INDEX idx_pages_context ON cms.pages(context);
CREATE INDEX idx_pages_status ON cms.pages(status);
CREATE INDEX idx_pages_tenant_id ON cms.pages(tenant_id);
CREATE INDEX idx_pages_is_landing ON cms.pages(is_landing_page) WHERE is_landing_page = TRUE;

COMMENT ON COLUMN cms.pages.elements IS 'Elementor-style structure: [{type: "section", children: [{type: "column", ...}]}]';
COMMENT ON COLUMN cms.pages.layout IS 'Widget-based layout (legacy CMS compatibility)';
COMMENT ON COLUMN cms.pages.context IS 'internal: dashboards | public: landing pages | tenant: tenant sites';
```

### 2. Templates (Unified Library)

```sql
CREATE TABLE cms.templates (
  template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  template_slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,

  -- Category & Type
  template_type TEXT NOT NULL CHECK (template_type IN ('page', 'section', 'block', 'header', 'footer', 'widget')),
  category TEXT NOT NULL, -- 'admin', 'landing', 'ecommerce', 'blog', 'portfolio', etc.
  tags TEXT[] DEFAULT '{}',

  -- Preview
  thumbnail TEXT,
  preview_url TEXT,
  demo_url TEXT,
  screenshots TEXT[],

  -- Content (Elementor structure)
  elements JSONB NOT NULL, -- Full Elementor structure

  -- Widget layout (for widget-based templates)
  layout JSONB, -- Legacy widget layout

  -- Styling
  default_settings JSONB DEFAULT '{}',
  color_palette JSONB,
  font_settings JSONB,

  -- Compatibility
  min_builder_version TEXT,
  required_widgets TEXT[], -- Widget IDs needed
  required_elements TEXT[], -- Element types needed

  -- Marketplace
  is_system BOOLEAN DEFAULT FALSE, -- System template (cannot be deleted)
  is_free BOOLEAN DEFAULT TRUE,
  is_pro BOOLEAN DEFAULT FALSE,
  price DECIMAL(10,2),

  -- Stats
  downloads_count INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.0,
  reviews_count INTEGER DEFAULT 0,

  -- Ownership
  author_id UUID,
  author_type TEXT DEFAULT 'system' CHECK (author_type IN ('system', 'user', 'marketplace')),

  -- Multi-tenancy
  tenant_id UUID, -- NULL = global template
  is_private BOOLEAN DEFAULT FALSE, -- Private to tenant

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  published_at TIMESTAMPTZ,

  -- Versioning
  version TEXT DEFAULT '1.0.0',
  changelog TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_templates_type ON cms.templates(template_type);
CREATE INDEX idx_templates_category ON cms.templates(category);
CREATE INDEX idx_templates_tenant ON cms.templates(tenant_id);
CREATE INDEX idx_templates_free ON cms.templates(is_free) WHERE is_free = TRUE;
CREATE INDEX idx_templates_is_system ON cms.templates(is_system);
```

### 3. Widget Definitions Registry (Unified)

```sql
-- Consolidate: widgets.widget_definitions + workflow.widget_definitions
CREATE TABLE cms.widget_registry (
  widget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  widget_slug TEXT UNIQUE NOT NULL, -- 'metrics-cards', 'service-status', etc.
  widget_name TEXT NOT NULL,
  description TEXT,

  -- Category
  category TEXT NOT NULL CHECK (category IN (
    'basic', 'layout', 'media', 'form', 'advanced',
    'ecommerce', 'marketing', 'analytics', 'social', 'crm'
  )),

  -- Icon & Preview
  icon TEXT,
  thumbnail TEXT,
  preview_url TEXT,

  -- Component
  component_path TEXT NOT NULL, -- '@ewh/shared-widgets/src/MetricsCardsWidget'
  component_props_schema JSONB, -- JSON Schema for props validation

  -- Configuration
  default_config JSONB DEFAULT '{}',
  config_schema JSONB, -- Schema for widget config UI

  -- Permissions (Default)
  default_enabled BOOLEAN DEFAULT TRUE,
  default_required_roles TEXT[],
  default_required_permissions TEXT[],

  -- Features
  supports_responsive BOOLEAN DEFAULT TRUE,
  supports_realtime BOOLEAN DEFAULT FALSE,
  supports_export BOOLEAN DEFAULT FALSE,
  requires_api BOOLEAN DEFAULT FALSE,
  api_endpoints TEXT[],

  -- Marketplace
  is_system BOOLEAN DEFAULT FALSE,
  is_free BOOLEAN DEFAULT TRUE,
  is_pro BOOLEAN DEFAULT FALSE,
  price DECIMAL(10,2),

  -- Ownership
  author_id UUID,
  author_type TEXT DEFAULT 'system',

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  version TEXT DEFAULT '1.0.0',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_widget_registry_slug ON cms.widget_registry(widget_slug);
CREATE INDEX idx_widget_registry_category ON cms.widget_registry(category);
CREATE INDEX idx_widget_registry_is_system ON cms.widget_registry(is_system);
```

### 4. **🔐 Widget Permissions (Multi-Level)**

```sql
-- LEVEL 1: Owner Configuration (Platform Admin)
CREATE TABLE cms.owner_widget_permissions (
  permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  widget_slug TEXT NOT NULL REFERENCES cms.widget_registry(widget_slug) ON DELETE CASCADE,

  -- Global Enable/Disable
  enabled_globally BOOLEAN DEFAULT TRUE,

  -- Who can enable this widget
  can_be_enabled_by TEXT[] DEFAULT '{}', -- ['PLATFORM_ADMIN', 'TENANT_ADMIN']

  -- Default visibility for new tenants
  enabled_for_new_tenants BOOLEAN DEFAULT TRUE,

  -- Restrictions
  max_instances_per_page INTEGER, -- NULL = unlimited
  allowed_contexts TEXT[], -- ['internal', 'public', 'tenant']
  allowed_page_types TEXT[], -- ['admin', 'landing', 'tenant']

  -- Feature flags
  features_enabled JSONB DEFAULT '{}', -- {realtime: true, export: false, ...}

  -- Notes
  restriction_reason TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(widget_slug)
);

-- LEVEL 2: Tenant Configuration (Tenant Admin)
CREATE TABLE cms.tenant_widget_permissions (
  permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,
  widget_slug TEXT NOT NULL REFERENCES cms.widget_registry(widget_slug) ON DELETE CASCADE,

  -- Tenant-level enable/disable (within owner's permissions)
  enabled_for_tenant BOOLEAN DEFAULT TRUE,

  -- User/Group restrictions
  allowed_roles TEXT[], -- ['ADMIN', 'MANAGER', 'USER']
  allowed_groups UUID[], -- Specific user groups
  allowed_users UUID[], -- Specific users

  -- Page restrictions
  allowed_pages UUID[], -- Specific pages, empty = all
  forbidden_pages UUID[], -- Blacklist pages

  -- Configuration overrides
  config_overrides JSONB DEFAULT '{}', -- Override default config
  config_locked BOOLEAN DEFAULT FALSE, -- Users cannot change config

  -- Limits
  max_instances_per_page INTEGER,
  max_instances_per_user INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, widget_slug)
);

-- LEVEL 3: User Preferences (End User)
CREATE TABLE cms.user_widget_preferences (
  preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,
  widget_slug TEXT NOT NULL REFERENCES cms.widget_registry(widget_slug) ON DELETE CASCADE,

  -- User's personal config (if allowed by tenant)
  custom_config JSONB DEFAULT '{}',

  -- Visibility toggle (for dashboards)
  is_visible BOOLEAN DEFAULT TRUE,

  -- Position (for drag & drop dashboards)
  position JSONB, -- {row, col, width, height}

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, tenant_id, widget_slug)
);
```

### 5. **Element Permissions (Elementor Elements)**

```sql
-- Same 3-level system for Elementor elements (heading, button, image, etc.)
CREATE TABLE cms.owner_element_permissions (
  permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  element_type TEXT NOT NULL, -- 'heading', 'button', 'pricing-table', etc.

  -- Global Enable/Disable
  enabled_globally BOOLEAN DEFAULT TRUE,

  -- Restrictions
  allowed_contexts TEXT[],
  allowed_page_types TEXT[],
  max_per_page INTEGER,

  -- Pro features
  is_pro BOOLEAN DEFAULT FALSE,
  requires_subscription TEXT, -- 'basic', 'pro', 'enterprise'

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(element_type)
);

CREATE TABLE cms.tenant_element_permissions (
  permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  tenant_id UUID NOT NULL,
  element_type TEXT NOT NULL,

  enabled_for_tenant BOOLEAN DEFAULT TRUE,
  allowed_roles TEXT[],

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, element_type)
);
```

### 6. Widget Instances (Page-Specific)

```sql
CREATE TABLE cms.widget_instances (
  instance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  page_id UUID NOT NULL REFERENCES cms.pages(page_id) ON DELETE CASCADE,
  widget_slug TEXT NOT NULL REFERENCES cms.widget_registry(widget_slug),

  -- Position in page
  instance_key TEXT NOT NULL, -- Unique key in page (e.g., 'metrics-1')
  position JSONB NOT NULL, -- {row, col, width, height} or element position

  -- Configuration
  config JSONB NOT NULL DEFAULT '{}',

  -- Conditions
  display_conditions JSONB, -- {roles: [], devices: [], dateRange: {}}
  is_visible BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(page_id, instance_key)
);

CREATE INDEX idx_widget_instances_page ON cms.widget_instances(page_id);
CREATE INDEX idx_widget_instances_widget ON cms.widget_instances(widget_slug);
```

---

## 🎨 Permission Resolution Flow

### Check se Widget è Disponibile

```typescript
async function checkWidgetPermissions(
  widgetSlug: string,
  context: {
    userId: string;
    tenantId: string;
    userRole: string;
    pageType: string;
    pageContext: string;
  }
): Promise<{
  allowed: boolean;
  reason?: string;
  config: any;
  locked: boolean;
}> {
  // LEVEL 1: Owner permissions
  const ownerPerm = await db.query(`
    SELECT * FROM cms.owner_widget_permissions
    WHERE widget_slug = $1
  `, [widgetSlug]);

  if (!ownerPerm || !ownerPerm.enabled_globally) {
    return {
      allowed: false,
      reason: 'Widget disabled by platform owner',
      config: {},
      locked: true
    };
  }

  if (!ownerPerm.allowed_contexts.includes(context.pageContext)) {
    return {
      allowed: false,
      reason: `Widget not allowed in ${context.pageContext} context`,
      config: {},
      locked: true
    };
  }

  // LEVEL 2: Tenant permissions
  const tenantPerm = await db.query(`
    SELECT * FROM cms.tenant_widget_permissions
    WHERE tenant_id = $1 AND widget_slug = $2
  `, [context.tenantId, widgetSlug]);

  if (!tenantPerm || !tenantPerm.enabled_for_tenant) {
    return {
      allowed: false,
      reason: 'Widget disabled by tenant admin',
      config: {},
      locked: true
    };
  }

  if (tenantPerm.allowed_roles?.length > 0 &&
      !tenantPerm.allowed_roles.includes(context.userRole)) {
    return {
      allowed: false,
      reason: `Role ${context.userRole} not allowed`,
      config: {},
      locked: true
    };
  }

  // LEVEL 3: User preferences
  const userPref = await db.query(`
    SELECT * FROM cms.user_widget_preferences
    WHERE user_id = $1 AND tenant_id = $2 AND widget_slug = $3
  `, [context.userId, context.tenantId, widgetSlug]);

  // Merge configs: owner defaults → tenant overrides → user preferences
  const config = {
    ...ownerPerm.default_config,
    ...(tenantPerm.config_overrides || {}),
    ...(userPref?.custom_config || {})
  };

  return {
    allowed: true,
    config,
    locked: tenantPerm.config_locked
  };
}
```

---

## 🎛️ Configuration UI (Admin)

### Owner Configuration Tab

```typescript
// app-admin-frontend/pages/god-mode/widget-permissions.tsx

export default function WidgetPermissionsConfig() {
  const [widgets, setWidgets] = useState<Widget[]>([]);

  return (
    <div className="widget-permissions-config">
      <h1>Widget Permissions (Platform Owner)</h1>

      <table>
        <thead>
          <tr>
            <th>Widget</th>
            <th>Category</th>
            <th>Enabled Globally</th>
            <th>Allowed Contexts</th>
            <th>Max Instances</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {widgets.map(widget => (
            <tr key={widget.slug}>
              <td>
                <div className="widget-info">
                  <img src={widget.thumbnail} alt={widget.name} />
                  <div>
                    <strong>{widget.name}</strong>
                    <span>{widget.slug}</span>
                  </div>
                </div>
              </td>
              <td>{widget.category}</td>
              <td>
                <Toggle
                  checked={widget.permissions.enabled_globally}
                  onChange={(enabled) => updateOwnerPermission(widget.slug, { enabled_globally: enabled })}
                />
              </td>
              <td>
                <MultiSelect
                  options={['internal', 'public', 'tenant']}
                  value={widget.permissions.allowed_contexts}
                  onChange={(contexts) => updateOwnerPermission(widget.slug, { allowed_contexts: contexts })}
                />
              </td>
              <td>
                <Input
                  type="number"
                  value={widget.permissions.max_instances_per_page}
                  onChange={(e) => updateOwnerPermission(widget.slug, { max_instances_per_page: parseInt(e.target.value) })}
                  placeholder="Unlimited"
                />
              </td>
              <td>
                <button onClick={() => openDetailModal(widget)}>
                  Configure
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

### Tenant Configuration Tab

```typescript
// app-web-frontend/pages/admin/widget-permissions.tsx

export default function TenantWidgetPermissions() {
  const { tenantId } = useTenant();
  const [widgets, setWidgets] = useState<Widget[]>([]);

  // Fetch only widgets enabled by owner
  useEffect(() => {
    fetchAvailableWidgets(tenantId);
  }, [tenantId]);

  return (
    <div className="tenant-widget-permissions">
      <h1>Widget Permissions (Tenant: {tenantName})</h1>

      <p className="info">
        Configure which widgets are available to your users.
        Only widgets enabled by platform owner are shown.
      </p>

      <table>
        <thead>
          <tr>
            <th>Widget</th>
            <th>Enabled for Tenant</th>
            <th>Allowed Roles</th>
            <th>Config Locked</th>
            <th>Max Per User</th>
          </tr>
        </thead>
        <tbody>
          {widgets.map(widget => (
            <tr key={widget.slug}>
              <td>{widget.name}</td>
              <td>
                <Toggle
                  checked={widget.tenantPermissions.enabled_for_tenant}
                  onChange={(enabled) => updateTenantPermission(widget.slug, { enabled_for_tenant: enabled })}
                />
              </td>
              <td>
                <MultiSelect
                  options={['ADMIN', 'MANAGER', 'USER', 'GUEST']}
                  value={widget.tenantPermissions.allowed_roles}
                  onChange={(roles) => updateTenantPermission(widget.slug, { allowed_roles: roles })}
                />
              </td>
              <td>
                <Checkbox
                  checked={widget.tenantPermissions.config_locked}
                  onChange={(locked) => updateTenantPermission(widget.slug, { config_locked: locked })}
                />
              </td>
              <td>
                <Input
                  type="number"
                  value={widget.tenantPermissions.max_instances_per_user}
                  placeholder="Unlimited"
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

---

## 🛒 E-Commerce Widgets (50+ Total)

### Product Widgets
```typescript
const ECOMMERCE_WIDGETS = [
  // Products
  { slug: 'product-grid', name: 'Product Grid', category: 'ecommerce' },
  { slug: 'product-list', name: 'Product List', category: 'ecommerce' },
  { slug: 'product-carousel', name: 'Product Carousel', category: 'ecommerce' },
  { slug: 'product-card', name: 'Product Card', category: 'ecommerce' },
  { slug: 'product-quick-view', name: 'Quick View Modal', category: 'ecommerce' },
  { slug: 'product-compare', name: 'Product Comparison', category: 'ecommerce' },
  { slug: 'product-filter', name: 'Product Filter', category: 'ecommerce' },
  { slug: 'product-search', name: 'Product Search', category: 'ecommerce' },
  { slug: 'product-categories', name: 'Category Grid', category: 'ecommerce' },
  { slug: 'product-breadcrumbs', name: 'Breadcrumbs', category: 'ecommerce' },

  // Cart & Checkout
  { slug: 'shopping-cart', name: 'Shopping Cart', category: 'ecommerce' },
  { slug: 'mini-cart', name: 'Mini Cart', category: 'ecommerce' },
  { slug: 'cart-icon', name: 'Cart Icon', category: 'ecommerce' },
  { slug: 'checkout-form', name: 'Checkout Form', category: 'ecommerce' },
  { slug: 'checkout-steps', name: 'Checkout Steps', category: 'ecommerce' },
  { slug: 'payment-methods', name: 'Payment Methods', category: 'ecommerce' },
  { slug: 'shipping-methods', name: 'Shipping Options', category: 'ecommerce' },
  { slug: 'coupon-code', name: 'Coupon Code', category: 'ecommerce' },
  { slug: 'order-summary', name: 'Order Summary', category: 'ecommerce' },

  // Reviews & Ratings
  { slug: 'product-reviews', name: 'Product Reviews', category: 'ecommerce' },
  { slug: 'star-rating', name: 'Star Rating', category: 'ecommerce' },
  { slug: 'review-form', name: 'Review Form', category: 'ecommerce' },
  { slug: 'review-stats', name: 'Review Statistics', category: 'ecommerce' },

  // Wishlist & Favorites
  { slug: 'wishlist', name: 'Wishlist', category: 'ecommerce' },
  { slug: 'wishlist-button', name: 'Add to Wishlist', category: 'ecommerce' },
  { slug: 'recently-viewed', name: 'Recently Viewed', category: 'ecommerce' },

  // Pricing & Offers
  { slug: 'price-display', name: 'Price Display', category: 'ecommerce' },
  { slug: 'price-range', name: 'Price Range Filter', category: 'ecommerce' },
  { slug: 'pricing-table', name: 'Pricing Table', category: 'ecommerce' },
  { slug: 'sale-badge', name: 'Sale Badge', category: 'ecommerce' },
  { slug: 'discount-banner', name: 'Discount Banner', category: 'ecommerce' },
  { slug: 'countdown-timer', name: 'Countdown Timer', category: 'ecommerce' },

  // Stock & Inventory
  { slug: 'stock-status', name: 'Stock Status', category: 'ecommerce' },
  { slug: 'low-stock-alert', name: 'Low Stock Alert', category: 'ecommerce' },
  { slug: 'back-in-stock', name: 'Back in Stock Notification', category: 'ecommerce' },

  // Recommendations
  { slug: 'related-products', name: 'Related Products', category: 'ecommerce' },
  { slug: 'upsell-products', name: 'Upsell Products', category: 'ecommerce' },
  { slug: 'cross-sell', name: 'Cross-Sell', category: 'ecommerce' },
  { slug: 'frequently-bought', name: 'Frequently Bought Together', category: 'ecommerce' },
  { slug: 'bestsellers', name: 'Best Sellers', category: 'ecommerce' },
  { slug: 'new-arrivals', name: 'New Arrivals', category: 'ecommerce' },

  // Account & Orders
  { slug: 'account-dashboard', name: 'Account Dashboard', category: 'ecommerce' },
  { slug: 'order-history', name: 'Order History', category: 'ecommerce' },
  { slug: 'order-tracking', name: 'Order Tracking', category: 'ecommerce' },
  { slug: 'address-book', name: 'Address Book', category: 'ecommerce' },
  { slug: 'saved-cards', name: 'Saved Payment Methods', category: 'ecommerce' },

  // Social & Trust
  { slug: 'social-share', name: 'Social Share Buttons', category: 'ecommerce' },
  { slug: 'trust-badges', name: 'Trust Badges', category: 'ecommerce' },
  { slug: 'secure-checkout-badge', name: 'Secure Checkout Badge', category: 'ecommerce' },
  { slug: 'shipping-info', name: 'Shipping Information', category: 'ecommerce' },
  { slug: 'return-policy', name: 'Return Policy', category: 'ecommerce' },
];
```

---

## 📊 Complete Widget Categories

```typescript
export const ALL_WIDGET_CATEGORIES = {
  // Original
  basic: ['heading', 'text', 'button', 'image', 'video', 'spacer', 'divider'],
  layout: ['section', 'column', 'container', 'inner-section', 'flex-container'],
  media: ['image-gallery', 'video-player', 'audio-player', 'image-carousel'],
  form: ['form', 'input', 'textarea', 'select', 'checkbox', 'submit', 'contact-form'],
  advanced: ['accordion', 'tabs', 'toggle', 'modal', 'pricing-table', 'testimonial-carousel'],

  // E-Commerce (50+)
  ecommerce: [
    // Products (10)
    'product-grid', 'product-list', 'product-carousel', 'product-card',
    'product-quick-view', 'product-compare', 'product-filter', 'product-search',
    'product-categories', 'product-breadcrumbs',

    // Cart & Checkout (9)
    'shopping-cart', 'mini-cart', 'cart-icon', 'checkout-form',
    'checkout-steps', 'payment-methods', 'shipping-methods', 'coupon-code',
    'order-summary',

    // Reviews (4)
    'product-reviews', 'star-rating', 'review-form', 'review-stats',

    // Wishlist (3)
    'wishlist', 'wishlist-button', 'recently-viewed',

    // Pricing (6)
    'price-display', 'price-range', 'pricing-table', 'sale-badge',
    'discount-banner', 'countdown-timer',

    // Stock (3)
    'stock-status', 'low-stock-alert', 'back-in-stock',

    // Recommendations (6)
    'related-products', 'upsell-products', 'cross-sell',
    'frequently-bought', 'bestsellers', 'new-arrivals',

    // Account (5)
    'account-dashboard', 'order-history', 'order-tracking',
    'address-book', 'saved-cards',

    // Trust (5)
    'social-share', 'trust-badges', 'secure-checkout-badge',
    'shipping-info', 'return-policy'
  ],

  // Marketing (15)
  marketing: [
    'lead-form', 'newsletter-signup', 'popup-form', 'exit-intent-popup',
    'countdown-timer', 'progress-bar', 'call-to-action', 'animated-headline',
    'flip-box', 'hotspot', 'coupon-code', 'scratch-card',
    'spin-wheel', 'quiz', 'survey'
  ],

  // Analytics (10)
  analytics: [
    'metrics-cards', 'chart-line', 'chart-bar', 'chart-pie',
    'chart-doughnut', 'data-table', 'kpi-card', 'trend-indicator',
    'real-time-counter', 'dashboard-widget'
  ],

  // Social (8)
  social: [
    'social-feed', 'instagram-feed', 'twitter-feed', 'facebook-feed',
    'social-share-buttons', 'social-icons', 'follow-buttons', 'reviews-widget'
  ],

  // CRM (12)
  crm: [
    'contact-list', 'lead-score', 'pipeline-view', 'activity-timeline',
    'task-list', 'deal-card', 'email-thread', 'meeting-scheduler',
    'notes-widget', 'files-widget', 'tags-widget', 'custom-fields'
  ]
};

// Total: 120+ widgets
```

---

## 🚀 Implementation Phases

### Phase 1: Database Consolidation ✅
- ✅ Create unified schema
- ✅ Migration script to consolidate data
- ✅ Backward compatibility layer

### Phase 2: Permission System 🔨
- 🔨 Implement 3-level permission tables
- 🔨 Permission resolution service
- 🔨 API endpoints for permission CRUD

### Phase 3: Owner UI 🔨
- 🔨 Widget permissions config UI
- 🔨 Element permissions config UI
- 🔨 Bulk enable/disable tools

### Phase 4: Tenant UI 📋
- 📋 Tenant widget manager
- 📋 Role-based restrictions
- 📋 Config override UI

### Phase 5: E-Commerce Widgets 📋
- 📋 50+ e-commerce widget implementations
- 📋 Product catalog integration
- 📋 Cart/checkout flows

### Phase 6: Integration 📋
- 📋 Update ElementorBuilder with permission checks
- 📋 Update CMS frontend with permission checks
- 📋 Template library filtering by permissions

---

## ✅ Deliverables

1. **Unified Database** - One source of truth for pages/templates/widgets
2. **3-Level Permissions** - Owner → Tenant → User control
3. **120+ Widgets** - Comprehensive widget library including e-commerce
4. **Configuration UIs** - Admin panels for both owner and tenant
5. **ElementorBuilder Integration** - Permission-aware page building
6. **Template Library** - Permission-filtered template browsing
7. **API Endpoints** - Full REST API for all operations

---

**Next Steps:**
1. Review and approve architecture
2. Run database migration
3. Implement permission service
4. Build configuration UIs
5. Add e-commerce widgets
6. Integrate with ElementorBuilder

**Ready to proceed?** 🚀
