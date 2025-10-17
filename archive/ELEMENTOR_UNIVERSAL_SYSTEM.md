# Sistema Elementor Universale
## Editor Cross-App + Templates + Landing Pages + Site Generator Multi-Tenant

**Created:** 2025-10-09
**Status:** 🚀 Architecture Complete
**Vision:** Un solo editor Elementor per tutto (admin, web, public, tenant sites)

---

## 🎯 Obiettivo

**UN SOLO EDITOR per:**

1. ✅ **Admin Dashboard** (app-admin-frontend)
2. ✅ **User Dashboard** (app-web-frontend)
3. ✅ **Landing Pages Pubbliche** (accessibili a tutti, no auth)
4. ✅ **Siti Web Tenant** (ogni tenant ha il suo sito/portale)
5. ✅ **CMS Figli** (interfacce custom per tenant)
6. ✅ **Template Library** (Crocoblock-style, riutilizzabili)

---

## 🏗️ Architettura Unificata

```
┌──────────────────────────────────────────────────────────────┐
│           SHARED ELEMENTOR EDITOR COMPONENT                  │
│         (Unico componente, usato ovunque)                    │
│  /shared/components/ElementorBuilder.tsx                     │
└────────────┬─────────────────────────────────────────────────┘
             │
    ┌────────┴────────────────────────────────┐
    │                                         │
┌───▼──────────────┐                  ┌──────▼───────────────┐
│ app-admin-frontend│                  │ app-web-frontend     │
│ God Mode:         │                  │ User Mode:           │
│ - Edit Admin Pages│                  │ - Edit User Dash     │
│ - Create Templates│                  │ - Customize Pages    │
│ - Build Landing   │                  │ - Build Landing      │
└───┬───────────────┘                  └──────┬───────────────┘
    │                                         │
    └────────────┬────────────────────────────┘
                 │
    ┌────────────▼────────────────────────────────────┐
    │        svc-site-builder (Port: 4xxx)            │
    │  - Salva/carica page data                      │
    │  - Gestisce templates                          │
    │  - API per elementi/blocchi                    │
    └────────────┬───────────────────────────────────┘
                 │
    ┌────────────▼────────────────────────────────────┐
    │        svc-site-renderer (Port: 4xxx)           │
    │  - SSR delle pagine                            │
    │  - Cache rendering                             │
    │  - Serve public pages                          │
    └────────────┬───────────────────────────────────┘
                 │
    ┌────────────▼────────────────────────────────────┐
    │        svc-site-publisher (Port: 4xxx)          │
    │  - Deploy to CDN                               │
    │  - Static export                               │
    │  - Multi-tenant isolation                      │
    └─────────────────────────────────────────────────┘
```

---

## 📦 Database Schema Esteso

### 1. Pages con Context Multi-Ambiente

```sql
-- Estensione tabella pages dal COMPLETE_VISUAL_SYSTEM_ARCHITECTURE.md

ALTER TABLE cms.pages ADD COLUMN IF NOT EXISTS
  page_context VARCHAR(50) DEFAULT 'internal';  -- internal|public|tenant

ALTER TABLE cms.pages ADD COLUMN IF NOT EXISTS
  tenant_id UUID;  -- NULL = platform pages

ALTER TABLE cms.pages ADD COLUMN IF NOT EXISTS
  domain VARCHAR(255);  -- Per tenant sites: tenant.example.com

ALTER TABLE cms.pages ADD COLUMN IF NOT EXISTS
  is_landing_page BOOLEAN DEFAULT false;

ALTER TABLE cms.pages ADD COLUMN IF NOT EXISTS
  seo_settings JSONB DEFAULT '{}';

ALTER TABLE cms.pages ADD COLUMN IF NOT EXISTS
  analytics_config JSONB DEFAULT '{}';

-- Index per performance
CREATE INDEX idx_pages_context ON cms.pages(page_context);
CREATE INDEX idx_pages_tenant ON cms.pages(tenant_id) WHERE tenant_id IS NOT NULL;
CREATE INDEX idx_pages_landing ON cms.pages(is_landing_page) WHERE is_landing_page = true;
CREATE INDEX idx_pages_domain ON cms.pages(domain) WHERE domain IS NOT NULL;

-- Check constraint
ALTER TABLE cms.pages ADD CONSTRAINT check_page_context
  CHECK (page_context IN ('internal', 'public', 'tenant'));

COMMENT ON COLUMN cms.pages.page_context IS
  'internal: admin/user dashboards | public: landing pages | tenant: tenant-specific sites';
```

### 2. Template Library (Crocoblock-Style)

```sql
CREATE TABLE builder.template_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  template_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Category
  template_type VARCHAR(50) NOT NULL,          -- page|section|block|widget
  category VARCHAR(100),                        -- landing|dashboard|blog|ecommerce|portfolio

  -- Preview
  thumbnail TEXT,
  preview_url TEXT,
  demo_url TEXT,

  -- Content (JSON structure di sections/columns/elements)
  template_data JSONB NOT NULL,

  -- Metadata
  tags TEXT[] DEFAULT '{}',
  color_palette JSONB,                         -- Preset colori
  font_settings JSONB,                         -- Preset font

  -- Compatibility
  min_elements_version VARCHAR(50),
  required_plugins TEXT[],
  required_widgets TEXT[],

  -- Pricing
  is_free BOOLEAN DEFAULT true,
  is_pro BOOLEAN DEFAULT false,
  price DECIMAL(10,2),

  -- Stats
  downloads_count INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.0,
  reviews_count INTEGER DEFAULT 0,

  -- Ownership
  author_id UUID,
  author_type VARCHAR(50) DEFAULT 'system',    -- system|user|marketplace

  -- Tenant
  tenant_id UUID,                               -- NULL = global templates
  is_tenant_private BOOLEAN DEFAULT false,

  -- Status
  status VARCHAR(50) DEFAULT 'published',       -- draft|published|archived
  published_at TIMESTAMPTZ,

  -- Versioning
  version VARCHAR(50) DEFAULT '1.0.0',
  changelog TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (template_type IN ('page', 'section', 'block', 'widget', 'header', 'footer')),
  CHECK (status IN ('draft', 'published', 'archived'))
);

CREATE INDEX idx_templates_type ON builder.template_library(template_type);
CREATE INDEX idx_templates_category ON builder.template_library(category);
CREATE INDEX idx_templates_tenant ON builder.template_library(tenant_id);
CREATE INDEX idx_templates_free ON builder.template_library(is_free) WHERE is_free = true;

-- Template usage tracking
CREATE TABLE builder.template_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  template_id UUID REFERENCES builder.template_library(id),
  page_id UUID REFERENCES cms.pages(id),

  user_id UUID,
  tenant_id UUID,

  installed_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3. Tenant Sites (CMS Figli)

```sql
CREATE TABLE cms.tenant_sites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Tenant
  tenant_id UUID NOT NULL,

  -- Identity
  site_name VARCHAR(255) NOT NULL,
  site_slug VARCHAR(255) NOT NULL,

  -- Domain
  primary_domain VARCHAR(255) UNIQUE NOT NULL,  -- acme.example.com
  custom_domains TEXT[],                        -- [www.acme.com, acme.com]

  -- Type
  site_type VARCHAR(50) NOT NULL,               -- website|portal|cms|ecommerce|blog

  -- Theme
  theme_id VARCHAR(255),
  color_scheme JSONB DEFAULT '{}',
  font_settings JSONB DEFAULT '{}',
  logo_url TEXT,
  favicon_url TEXT,

  -- Settings
  site_settings JSONB DEFAULT '{}',
  seo_settings JSONB DEFAULT '{}',
  analytics_config JSONB DEFAULT '{}',

  -- Features
  enabled_features TEXT[] DEFAULT '{}',         -- blog|shop|forms|bookings
  disabled_features TEXT[] DEFAULT '{}',

  -- Navigation
  main_menu_id UUID REFERENCES cms.menu_items(id),
  footer_menu_id UUID REFERENCES cms.menu_items(id),

  -- Pages
  home_page_id UUID REFERENCES cms.pages(id),
  error_404_page_id UUID REFERENCES cms.pages(id),
  error_500_page_id UUID REFERENCES cms.pages(id),

  -- Publishing
  status VARCHAR(50) DEFAULT 'draft',           -- draft|published|maintenance|archived
  published_at TIMESTAMPTZ,
  last_published_at TIMESTAMPTZ,

  -- SSL
  ssl_enabled BOOLEAN DEFAULT true,
  ssl_certificate TEXT,
  ssl_expires_at TIMESTAMPTZ,

  -- Performance
  cdn_enabled BOOLEAN DEFAULT true,
  cache_enabled BOOLEAN DEFAULT true,
  cache_ttl INTEGER DEFAULT 3600,

  -- Metadata
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, site_slug),
  CHECK (site_type IN ('website', 'portal', 'cms', 'ecommerce', 'blog', 'landing', 'documentation')),
  CHECK (status IN ('draft', 'published', 'maintenance', 'archived'))
);

CREATE INDEX idx_tenant_sites_tenant ON cms.tenant_sites(tenant_id);
CREATE INDEX idx_tenant_sites_domain ON cms.tenant_sites(primary_domain);
CREATE INDEX idx_tenant_sites_status ON cms.tenant_sites(status);
```

### 4. Landing Pages Pubbliche

```sql
CREATE TABLE cms.landing_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference to base page
  page_id UUID REFERENCES cms.pages(id) ON DELETE CASCADE,

  -- URL
  slug VARCHAR(500) UNIQUE NOT NULL,            -- /promo/black-friday
  full_url TEXT,                                -- https://example.com/promo/black-friday

  -- Campaign
  campaign_name VARCHAR(255),
  campaign_id VARCHAR(255),
  utm_source VARCHAR(255),
  utm_medium VARCHAR(255),
  utm_campaign VARCHAR(255),

  -- A/B Testing
  ab_test_enabled BOOLEAN DEFAULT false,
  ab_variant VARCHAR(10),                       -- A|B|C
  ab_traffic_split JSONB,                       -- {A: 50, B: 50}

  -- Conversion
  conversion_goal VARCHAR(100),                 -- signup|purchase|download|contact
  conversion_tracking_code TEXT,

  -- Forms
  form_ids TEXT[],                              -- IDs dei form sulla pagina
  form_submit_webhook TEXT,

  -- Integrations
  crm_integration JSONB,                        -- Salesforce, HubSpot, etc
  email_provider JSONB,                         -- Mailchimp, SendGrid, etc
  analytics_provider JSONB,                     -- GA, Mixpanel, etc

  -- SEO
  meta_title VARCHAR(255),
  meta_description TEXT,
  meta_keywords TEXT[],
  og_image TEXT,
  twitter_card TEXT,
  schema_markup JSONB,

  -- Performance
  cache_enabled BOOLEAN DEFAULT true,
  cache_ttl INTEGER DEFAULT 3600,
  cdn_enabled BOOLEAN DEFAULT true,

  -- Scheduling
  schedule_start TIMESTAMPTZ,
  schedule_end TIMESTAMPTZ,
  auto_archive_after_end BOOLEAN DEFAULT false,

  -- Stats (cache, refreshed periodically)
  views_count INTEGER DEFAULT 0,
  unique_visitors INTEGER DEFAULT 0,
  conversions_count INTEGER DEFAULT 0,
  conversion_rate DECIMAL(5,2),
  bounce_rate DECIMAL(5,2),
  avg_time_on_page INTEGER,

  -- Status
  status VARCHAR(50) DEFAULT 'draft',
  published_at TIMESTAMPTZ,

  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (status IN ('draft', 'published', 'scheduled', 'archived', 'expired'))
);

CREATE INDEX idx_landing_pages_slug ON cms.landing_pages(slug);
CREATE INDEX idx_landing_pages_campaign ON cms.landing_pages(campaign_id) WHERE campaign_id IS NOT NULL;
CREATE INDEX idx_landing_pages_status ON cms.landing_pages(status);
CREATE INDEX idx_landing_pages_schedule ON cms.landing_pages(schedule_start, schedule_end);
```

---

## 🎨 Shared Elementor Component

```typescript
// shared/components/ElementorBuilder.tsx

import { useState, useEffect } from 'react';
import { Section, Column, Element } from './types';

export interface ElementorBuilderProps {
  // Context
  context: 'internal' | 'public' | 'tenant';

  // Page
  pageId?: string;
  pageData?: any;

  // Tenant (opzionale, per tenant sites)
  tenantId?: string;
  siteId?: string;

  // Permissions
  canEdit: boolean;
  canPublish: boolean;

  // Template library access
  showTemplateLibrary?: boolean;
  allowedTemplateTypes?: string[];

  // Callbacks
  onSave?: (data: any) => Promise<void>;
  onPublish?: (data: any) => Promise<void>;
  onPreview?: (data: any) => void;

  // Settings
  enabledElements?: string[];  // Whitelist elementi disponibili
  customElements?: any[];      // Elementi custom del tenant
}

export function ElementorBuilder({
  context,
  pageId,
  pageData,
  tenantId,
  siteId,
  canEdit,
  canPublish,
  showTemplateLibrary = true,
  allowedTemplateTypes = ['page', 'section', 'block'],
  onSave,
  onPublish,
  onPreview,
  enabledElements,
  customElements = []
}: ElementorBuilderProps) {
  const [sections, setSections] = useState<Section[]>([]);
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [mode, setMode] = useState<'edit' | 'preview'>('edit');

  // Load page data
  useEffect(() => {
    if (pageId) {
      loadPageData(pageId, context, tenantId);
    } else if (pageData) {
      setSections(pageData.sections || []);
    }
  }, [pageId, pageData, context, tenantId]);

  async function loadPageData(id: string, ctx: string, tid?: string) {
    const endpoint = ctx === 'tenant'
      ? `/api/tenant-sites/${tid}/pages/${id}`
      : `/api/pages/${id}`;

    const res = await fetch(endpoint);
    const data = await res.json();
    setSections(data.sections || []);
  }

  async function handleSave() {
    if (!onSave) return;

    const data = {
      sections,
      context,
      tenantId,
      siteId,
      updatedAt: new Date().toISOString()
    };

    await onSave(data);
  }

  async function handlePublish() {
    if (!onPublish) return;

    const data = {
      sections,
      context,
      tenantId,
      siteId,
      publishedAt: new Date().toISOString()
    };

    await onPublish(data);
  }

  return (
    <div className="elementor-builder">
      {/* Toolbar */}
      <div className="toolbar">
        <div className="toolbar-left">
          <button onClick={() => setMode(mode === 'edit' ? 'preview' : 'edit')}>
            {mode === 'edit' ? 'Preview' : 'Edit'}
          </button>
          {showTemplateLibrary && (
            <button onClick={() => openTemplateLibrary()}>
              📚 Templates
            </button>
          )}
        </div>
        <div className="toolbar-right">
          {canEdit && (
            <button onClick={handleSave}>Save Draft</button>
          )}
          {canPublish && (
            <button onClick={handlePublish} className="primary">
              Publish
            </button>
          )}
        </div>
      </div>

      {/* Main Interface */}
      <div className="builder-interface">
        {/* Sidebar: Elements */}
        <div className="sidebar">
          <ElementLibrary
            enabledElements={enabledElements}
            customElements={customElements}
            onDragStart={(element) => handleDragStart(element)}
          />
        </div>

        {/* Canvas */}
        <div className="canvas">
          {mode === 'edit' ? (
            <EditMode
              sections={sections}
              onSectionsChange={setSections}
              selectedItem={selectedItem}
              onSelectItem={setSelectedItem}
            />
          ) : (
            <PreviewMode sections={sections} />
          )}
        </div>

        {/* Properties Panel */}
        {selectedItem && mode === 'edit' && (
          <div className="properties-panel">
            <PropertiesEditor
              item={selectedItem}
              onUpdate={(updated) => updateItem(updated)}
            />
          </div>
        )}
      </div>
    </div>
  );
}
```

---

## 🚀 Use Cases Completi

### 1. Admin Edita Dashboard Interna

```typescript
// app-admin-frontend/pages/god-mode/page-editor.tsx

import { ElementorBuilder } from '@/shared/components/ElementorBuilder';

export default function AdminPageEditor() {
  return (
    <ElementorBuilder
      context="internal"
      pageId="admin-dashboard"
      canEdit={true}
      canPublish={true}
      showTemplateLibrary={true}
      allowedTemplateTypes={['page', 'section', 'widget']}
      onSave={async (data) => {
        await fetch('/api/pages/admin-dashboard', {
          method: 'PUT',
          body: JSON.stringify(data)
        });
      }}
      onPublish={async (data) => {
        await fetch('/api/pages/admin-dashboard/publish', {
          method: 'POST',
          body: JSON.stringify(data)
        });
      }}
    />
  );
}
```

### 2. User Personalizza la Sua Dashboard

```typescript
// app-web-frontend/pages/dashboard/customize.tsx

import { ElementorBuilder } from '@/shared/components/ElementorBuilder';

export default function UserDashboardCustomizer() {
  return (
    <ElementorBuilder
      context="internal"
      pageId={`user-dashboard-${userId}`}
      canEdit={true}
      canPublish={true}
      showTemplateLibrary={true}
      allowedTemplateTypes={['widget', 'block']}  // No full pages
      enabledElements={['heading', 'text', 'widget', 'chart']}  // Limited
      onSave={async (data) => {
        await fetch('/api/user/dashboard', {
          method: 'PUT',
          body: JSON.stringify(data)
        });
      }}
    />
  );
}
```

### 3. Marketing Crea Landing Page Pubblica

```typescript
// app-admin-frontend/pages/landing-pages/new.tsx

import { ElementorBuilder } from '@/shared/components/ElementorBuilder';

export default function LandingPageEditor() {
  return (
    <ElementorBuilder
      context="public"
      pageId="new-landing-page"
      canEdit={true}
      canPublish={true}
      showTemplateLibrary={true}
      allowedTemplateTypes={['page', 'section', 'block']}
      onSave={async (data) => {
        await fetch('/api/landing-pages', {
          method: 'POST',
          body: JSON.stringify({
            ...data,
            slug: '/promo/black-friday',
            campaign: 'black-friday-2025'
          })
        });
      }}
      onPublish={async (data) => {
        // Publish to svc-site-renderer (SSR)
        await fetch('/api/landing-pages/publish', {
          method: 'POST',
          body: JSON.stringify(data)
        });
      }}
    />
  );
}
```

### 4. Tenant Crea il Proprio Sito

```typescript
// app-web-frontend/pages/my-site/builder.tsx

import { ElementorBuilder } from '@/shared/components/ElementorBuilder';
import { useTenantContext } from '@/contexts/TenantContext';

export default function TenantSiteBuilder() {
  const { tenantId, siteId } = useTenantContext();

  return (
    <ElementorBuilder
      context="tenant"
      tenantId={tenantId}
      siteId={siteId}
      pageId="home"
      canEdit={true}
      canPublish={true}
      showTemplateLibrary={true}
      allowedTemplateTypes={['page', 'section', 'block', 'header', 'footer']}
      customElements={tenantCustomElements}  // Elementi custom del tenant
      onSave={async (data) => {
        await fetch(`/api/tenant-sites/${siteId}/pages/home`, {
          method: 'PUT',
          body: JSON.stringify(data)
        });
      }}
      onPublish={async (data) => {
        // Publish to tenant domain
        await fetch(`/api/tenant-sites/${siteId}/publish`, {
          method: 'POST',
          body: JSON.stringify(data)
        });
      }}
    />
  );
}
```

---

## 🎨 Template Library UI (Crocoblock-Style)

```
┌──────────────────────────────────────────────────────────────┐
│  📚 Template Library                         [Upload] [✕]    │
├─────────┬────────────────────────────────────────────────────┤
│         │                                                    │
│ Filters │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐         │
│         │  │[IMG] │  │[IMG] │  │[IMG] │  │[IMG] │         │
│ Type:   │  │Hero  │  │Feat. │  │Testi.│  │CTA   │         │
│  □ Page │  │Sectn │  │Grid  │  │monls │  │Block │         │
│  ☑ Sect │  └──────┘  └──────┘  └──────┘  └──────┘         │
│  □ Block│  ⭐ Free   ⭐ Free   💎 Pro    ⭐ Free          │
│  □ Head │  [Insert]  [Insert]  [Buy]     [Insert]         │
│  □ Foot │                                                   │
│         │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐         │
│ Categry │  │[IMG] │  │[IMG] │  │[IMG] │  │[IMG] │         │
│  □ Land │  │Pricng│  │Team  │  │FAQ   │  │Footr │         │
│  ☑ Dash │  │Table │  │Sectn │  │Block │  │Block │         │
│  □ Blog │  └──────┘  └──────┘  └──────┘  └──────┘         │
│  □ Shop │  ⭐ Free   ⭐ Free   ⭐ Free   ⭐ Free          │
│         │  [Insert]  [Insert]  [Insert]  [Insert]         │
│ Style:  │                                                   │
│  □ Minimalist                                              │
│  □ Corporate                                               │
│  ☑ Modern                                                  │
│         │  [Load More...]                                  │
└─────────┴────────────────────────────────────────────────────┘
```

### Template Insert Flow

```typescript
async function insertTemplate(templateId: string, position: 'append' | 'prepend' | 'replace') {
  // 1. Fetch template data
  const template = await fetch(`/api/templates/${templateId}`).then(r => r.json());

  // 2. Clone template structure
  const newSections = cloneDeep(template.template_data.sections);

  // 3. Generate new IDs for all elements
  const sectionsWithNewIds = generateNewIds(newSections);

  // 4. Insert into current page
  if (position === 'append') {
    setSections([...sections, ...sectionsWithNewIds]);
  } else if (position === 'prepend') {
    setSections([...sectionsWithNewIds, ...sections]);
  } else {
    setSections(sectionsWithNewIds);
  }

  // 5. Track usage
  await fetch('/api/templates/usage', {
    method: 'POST',
    body: JSON.stringify({
      templateId,
      pageId,
      userId,
      tenantId
    })
  });
}
```

---

## 🌐 Rendering & Publishing Flow

### Landing Page Pubblica

```
User visits: https://example.com/promo/black-friday

1. Nginx/Traefik → svc-site-renderer
2. svc-site-renderer checks cache
3. If not cached:
   a. Fetch page data from DB
   b. Render sections → HTML
   c. Inject SEO meta tags
   d. Inject analytics scripts
   e. Cache result (TTL 1h)
4. Return HTML
5. Browser renders + hydrates
```

### Tenant Site

```
User visits: https://acme.example.com

1. Nginx checks domain → route to svc-site-renderer
2. svc-site-renderer:
   a. Lookup tenant by domain
   b. Fetch tenant site config
   c. Fetch home page data
   d. Render with tenant theme
   e. Cache per tenant
3. Return HTML
4. Browser renders
```

### Static Export (Optional)

```typescript
// For ultra-performance, export to static HTML + CDN

async function exportToStatic(pageId: string) {
  // 1. Render all pages
  const pages = await renderAllPages(pageId);

  // 2. Generate static HTML files
  const staticFiles = pages.map(page => ({
    path: page.slug + '.html',
    content: renderToStaticMarkup(page.sections)
  }));

  // 3. Upload to S3/CDN
  await uploadToCDN(staticFiles);

  // 4. Invalidate CDN cache
  await invalidateCDN(pageId);
}
```

---

## 📊 API Endpoints

### Template Library
```typescript
GET    /api/templates                    // List all templates
GET    /api/templates/:id                // Get template
POST   /api/templates                    // Create template (admin)
PUT    /api/templates/:id                // Update template
DELETE /api/templates/:id                // Delete template
POST   /api/templates/:id/install        // Install template
GET    /api/templates/categories         // Get categories
GET    /api/templates/search?q=...       // Search templates
```

### Landing Pages
```typescript
GET    /api/landing-pages                // List landing pages
POST   /api/landing-pages                // Create
PUT    /api/landing-pages/:id            // Update
DELETE /api/landing-pages/:id            // Delete
POST   /api/landing-pages/:id/publish    // Publish
GET    /api/landing-pages/:id/stats      // Analytics
POST   /api/landing-pages/:id/duplicate  // Duplicate
```

### Tenant Sites
```typescript
GET    /api/tenant-sites                 // List sites for tenant
POST   /api/tenant-sites                 // Create new site
PUT    /api/tenant-sites/:id             // Update site config
DELETE /api/tenant-sites/:id             // Delete site
POST   /api/tenant-sites/:id/publish     // Publish site
GET    /api/tenant-sites/:id/pages       // List pages
POST   /api/tenant-sites/:id/pages       // Create page
PUT    /api/tenant-sites/:id/pages/:pid  // Update page
GET    /api/tenant-sites/:id/domains     // Manage domains
POST   /api/tenant-sites/:id/domains     // Add custom domain
```

---

## 🎯 Roadmap Implementazione

### Phase 1: Elementor Core (Week 1-2)
- ✅ Shared component base
- ✅ Section/Column/Element structure
- ✅ Drag & drop
- ✅ Properties panel
- ✅ Save/Load

### Phase 2: Template Library (Week 3)
- ✅ Template schema
- ✅ Template browser UI
- ✅ Insert/Clone logic
- ✅ 10+ starter templates

### Phase 3: Landing Pages (Week 4)
- ✅ Landing pages schema
- ✅ Public routing
- ✅ SEO meta tags
- ✅ Analytics integration

### Phase 4: Tenant Sites (Week 5-6)
- ✅ Tenant sites schema
- ✅ Domain management
- ✅ Theme system
- ✅ Multi-tenant isolation

### Phase 5: Rendering & Publishing (Week 7)
- ✅ SSR engine (svc-site-renderer)
- ✅ CDN integration (svc-site-publisher)
- ✅ Caching strategy
- ✅ Static export

### Phase 6: Polish & Optimize (Week 8)
- ✅ Performance optimization
- ✅ Mobile responsiveness
- ✅ A/B testing
- ✅ Analytics dashboard

---

## 🎁 Deliverable Finale

**Un sistema dove:**

1. ✅ **Admin** edita dashboard admin con Elementor
2. ✅ **Users** personalizzano dashboard utente con Elementor
3. ✅ **Marketing** crea landing pubbliche con Elementor
4. ✅ **Tenants** buildano siti completi con Elementor
5. ✅ **Tutti** usano template library condivisa
6. ✅ **Tutto** è database-driven e real-time

**UN SOLO EDITOR per TUTTO!** 🚀

---

**Risposta alla tua domanda:**
- ✅ **Sì**, editor richiamabile anche da web-frontend
- ✅ **Sì**, puoi creare blocchi/templates Crocoblock-style
- ✅ **Sì**, landing pages pubbliche visibili a tutti
- ✅ **Sì**, generare siti/portali/CMS per ogni tenant
- ✅ **Sì**, multi-domain support per tenant sites

**Tutto con lo stesso component condiviso!** 🎉
