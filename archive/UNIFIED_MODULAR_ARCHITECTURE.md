# 🏗️ Unified Modular Architecture - Sistema Completo

## Visione Generale

Sistema **completamente modulare** dove:
- ✅ **Dashboard** usa widget riutilizzabili
- ✅ **Page Builder** usa gli stessi widget (drag & drop)
- ✅ **CMS** gestisce pagine composte da widget
- ✅ **Renderer** renderizza le pagine pubbliche
- ✅ Tutto configurabile, tutto riutilizzabile

---

## 🎯 Obiettivi

### 1. Dashboard Modulare
Trasformare tutte le pagine admin in composizioni di widget:
- `/admin/dashboard` → Composizione di MetricsCards + ServiceStatus + RecentActivity
- `/admin/monitoring` → Composizione di ServiceHealth + AlertsManagement + LogStream
- `/admin/tenants` → Composizione di TenantsList + TenantMetrics + RecentSignups
- Ecc...

### 2. Page Builder Integrato
Permettere editing visuale di:
- Pagine admin (dashboard personalizzabili)
- Landing pages pubbliche
- Pagine di contenuto
- Email templates

### 3. CMS per Gestione Pagine
Sistema di gestione completo:
- CRUD pagine
- Versionamento
- Publishing workflow (draft → review → published)
- Template system
- Widget marketplace

### 4. Sistema Modulare
- Widget = building blocks atomici
- Modules = composizioni di widget (pagine)
- Templates = layout predefiniti
- Themes = styling system

---

## 📐 Architettura Completa

```
┌─────────────────────────────────────────────────────────────┐
│                    UNIFIED PLATFORM                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           CONTENT MANAGEMENT SYSTEM (CMS)            │  │
│  │                                                       │  │
│  │  • Page CRUD                                         │  │
│  │  • Widget Management                                 │  │
│  │  • Template Library                                  │  │
│  │  • Publishing Workflow                               │  │
│  │  • Version Control                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↓                                 │
│  ┌─────────────────┬──────────────────┬──────────────────┐ │
│  │  PAGE BUILDER   │   ADMIN DASH     │   PUBLIC PAGES   │ │
│  │                 │                  │                  │ │
│  │  Visual Editor  │  Composed Pages  │  SSR Renderer    │ │
│  │  Drag & Drop    │  Live Widgets    │  Static Export   │ │
│  └─────────────────┴──────────────────┴──────────────────┘ │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              WIDGET REGISTRY (Central)                │  │
│  │                                                       │  │
│  │  31 Admin Widgets  +  Custom Widgets  +  Plugins     │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                 SHARED INFRASTRUCTURE                 │  │
│  │                                                       │  │
│  │  • Widget Types & Registry                           │  │
│  │  • Data Fetching (useWidgetData)                     │  │
│  │  • API Client (Gateway)                              │  │
│  │  • Configuration System                              │  │
│  │  • Theme System                                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    DATABASE LAYER                     │  │
│  │                                                       │  │
│  │  pages, page_versions, widgets, widget_configs       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema

### Tabelle Principali

```sql
-- Pages table
CREATE TABLE cms.pages (
  page_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  page_type TEXT NOT NULL CHECK (page_type IN ('admin', 'public', 'landing', 'email')),
  template_id UUID REFERENCES cms.templates(template_id),
  layout JSONB NOT NULL, -- Widget composition
  meta_data JSONB,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived')),
  published_at TIMESTAMPTZ,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Page versions (for versioning)
CREATE TABLE cms.page_versions (
  version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES cms.pages(page_id) ON DELETE CASCADE,
  version_number INT NOT NULL,
  layout JSONB NOT NULL,
  changes_summary TEXT,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(page_id, version_number)
);

-- Templates (predefined layouts)
CREATE TABLE cms.templates (
  template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  preview_image TEXT,
  layout JSONB NOT NULL, -- Default widget composition
  category TEXT,
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Widget configurations (per page instance)
CREATE TABLE cms.page_widget_configs (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES cms.pages(page_id) ON DELETE CASCADE,
  widget_id TEXT NOT NULL, -- Reference to widget in registry
  instance_id TEXT NOT NULL, -- Unique instance on page
  position JSONB NOT NULL, -- {row, col, width, height}
  config JSONB NOT NULL, -- Widget-specific config
  UNIQUE(page_id, instance_id)
);

-- Existing: widgets.widget_definitions (già creata)
-- Per i widget disponibili nel registry
```

---

## 📦 Package Structure

```
/Users/andromeda/dev/ewh/

├── shared/
│   ├── widgets/                    # ✅ Already created
│   │   ├── src/
│   │   │   ├── widgets/            # 31 widgets
│   │   │   ├── modules/            # NEW: Composite widgets (full pages)
│   │   │   ├── templates/          # NEW: Template system
│   │   │   └── themes/             # NEW: Theme system
│   │   └── package.json
│   │
│   └── cms-core/                   # NEW: CMS shared logic
│       ├── src/
│       │   ├── types/
│       │   ├── page-composer/      # Page composition logic
│       │   ├── template-engine/    # Template rendering
│       │   └── versioning/         # Version control
│       └── package.json
│
├── svc-cms/                        # NEW: CMS Backend Service
│   ├── src/
│   │   ├── routes/
│   │   │   ├── pages.ts            # CRUD pages
│   │   │   ├── templates.ts        # Template management
│   │   │   ├── widgets.ts          # Widget management
│   │   │   └── publishing.ts       # Publishing workflow
│   │   ├── services/
│   │   │   ├── page-service.ts
│   │   │   ├── version-service.ts
│   │   │   └── render-service.ts
│   │   └── index.ts
│   └── package.json
│
├── app-cms-frontend/               # NEW: CMS Admin UI
│   ├── pages/
│   │   ├── cms/
│   │   │   ├── pages/              # Page management
│   │   │   ├── templates/          # Template library
│   │   │   ├── widgets/            # Widget marketplace
│   │   │   └── settings/           # CMS settings
│   │   └── ...
│   └── package.json
│
├── app-page-builder/               # ✅ Already exists, to enhance
│   ├── src/
│   │   ├── adapters/               # NEW: Adapters for different contexts
│   │   │   ├── grapesjs.adapter.ts
│   │   │   ├── dashboard.adapter.ts
│   │   │   └── public.adapter.ts
│   │   └── ...
│   └── package.json
│
├── app-admin-frontend/             # To refactor as modular
│   ├── pages/
│   │   └── admin/
│   │       ├── dashboard/
│   │       │   └── index.tsx       # Rewritten as widget composition
│   │       ├── monitoring/
│   │       │   └── index.tsx       # Rewritten as widget composition
│   │       └── ...
│   └── package.json
│
└── svc-page-renderer/              # NEW: Public page renderer
    ├── src/
    │   ├── ssr/                    # Server-side rendering
    │   ├── cache/                  # Page caching
    │   └── index.ts
    └── package.json
```

---

## 🔄 Data Flow

### 1. Admin Dashboard (Live Mode)
```
User visits /admin/dashboard
  ↓
Next.js loads page composition from DB
  ↓
Renders widgets in "live" mode
  ↓
Each widget fetches real data via useWidgetData
  ↓
Auto-refresh per widget config
```

### 2. Page Builder (Preview Mode)
```
User opens Page Builder
  ↓
Loads available widgets from registry
  ↓
User drags widget to canvas
  ↓
Widget renders in "preview" mode (mock data)
  ↓
User configures widget via UI
  ↓
Saves page composition to DB
```

### 3. Public Page (SSR Mode)
```
User visits /landing/promo
  ↓
SSR renderer fetches page from DB
  ↓
Pre-renders all widgets server-side
  ↓
Sends static HTML + hydration data
  ↓
Client hydrates interactive widgets
```

### 4. CMS Workflow
```
Editor creates new page
  ↓
Selects template (or blank)
  ↓
Adds widgets via Page Builder
  ↓
Configures each widget
  ↓
Saves as draft
  ↓
Submits for review
  ↓
Approver reviews & publishes
  ↓
Page becomes live
```

---

## 🎨 Layout System

### Page Layout Structure
```typescript
interface PageLayout {
  version: string;
  grid: GridConfig;
  widgets: WidgetInstance[];
  styles?: PageStyles;
}

interface GridConfig {
  type: 'flex' | 'grid' | 'masonry';
  columns: number;
  gap: number;
  responsive?: ResponsiveBreakpoints;
}

interface WidgetInstance {
  instanceId: string;          // Unique on page
  widgetId: string;             // From registry
  position: {
    row: number;
    col: number;
    width: number;              // Grid units
    height: number;             // Grid units or 'auto'
  };
  config: Record<string, any>;  // Widget-specific config
  conditions?: DisplayConditions; // When to show/hide
}

interface DisplayConditions {
  userRole?: string[];
  deviceType?: ('mobile' | 'tablet' | 'desktop')[];
  dateRange?: { from: Date; to: Date };
}
```

### Esempio: Dashboard Page
```json
{
  "version": "1.0",
  "grid": {
    "type": "grid",
    "columns": 12,
    "gap": 24,
    "responsive": {
      "mobile": { "columns": 1 },
      "tablet": { "columns": 6 },
      "desktop": { "columns": 12 }
    }
  },
  "widgets": [
    {
      "instanceId": "metrics-1",
      "widgetId": "metrics-cards",
      "position": { "row": 0, "col": 0, "width": 12, "height": 1 },
      "config": {
        "dataEndpoint": "/api/admin/stats",
        "refreshInterval": 60000
      }
    },
    {
      "instanceId": "services-1",
      "widgetId": "service-status",
      "position": { "row": 1, "col": 0, "width": 6, "height": 2 },
      "config": {
        "dataEndpoint": "/api/admin/services",
        "refreshInterval": 30000,
        "maxServices": 5
      }
    },
    {
      "instanceId": "activity-1",
      "widgetId": "recent-activity",
      "position": { "row": 1, "col": 6, "width": 6, "height": 2 },
      "config": {
        "dataEndpoint": "/api/admin/activity",
        "refreshInterval": 60000,
        "maxItems": 5
      }
    }
  ]
}
```

---

## 🚀 Implementation Roadmap

### **Phase 2: CMS Foundation** (5-7 giorni)

#### 2.1 Database Setup
- [ ] Creare schema `cms` con tabelle (pages, page_versions, templates, page_widget_configs)
- [ ] Migration script
- [ ] Seed data con template base

#### 2.2 Backend Service (svc-cms)
- [ ] Setup Express + TypeScript
- [ ] CRUD endpoints per pages
- [ ] Template management API
- [ ] Version control API
- [ ] Publishing workflow API

#### 2.3 Page Composer
- [ ] Shared package `cms-core`
- [ ] Page layout engine
- [ ] Widget positioning system
- [ ] Configuration validator

### **Phase 3: Page Builder Enhancement** (3-4 giorni)

#### 3.1 GrapesJS Adapter
- [ ] Integrare shared widgets nel Page Builder
- [ ] Custom blocks per ogni widget
- [ ] Configuration panel per widget
- [ ] Preview mode con mock data

#### 3.2 Saving & Loading
- [ ] Save page layout to DB
- [ ] Load page layout from DB
- [ ] Template application

### **Phase 4: Admin Dashboard Refactor** (5-7 giorni)

#### 4.1 Page Renderer Component
```typescript
<PageRenderer
  pageId="admin-dashboard"
  mode="live"
  context={{ tenantId, userId, userRole }}
/>
```

#### 4.2 Migrate Pages
- [ ] `/admin/dashboard` → Widget composition
- [ ] `/admin/monitoring` → Widget composition
- [ ] `/admin/tenants` → Widget composition
- [ ] `/admin/billing` → Widget composition
- [ ] Altre pagine...

### **Phase 5: CMS Admin UI** (4-5 giorni)

#### 5.1 Page Management
- [ ] Pages list con filtering
- [ ] Create/Edit/Delete pages
- [ ] Preview page
- [ ] Duplicate page

#### 5.2 Template Library
- [ ] Template browser
- [ ] Template preview
- [ ] Apply template to page
- [ ] Create custom template

#### 5.3 Widget Marketplace
- [ ] Widget browser
- [ ] Widget search
- [ ] Widget preview
- [ ] Install custom widgets

### **Phase 6: Public Renderer** (3-4 giorni)

#### 6.1 SSR Service
- [ ] Server-side rendering engine
- [ ] Page caching layer
- [ ] CDN integration ready

#### 6.2 Hydration
- [ ] Client-side hydration
- [ ] Interactive widget activation

---

## 📝 Migration Strategy per Admin Dashboard

### Current State
```typescript
// app-admin-frontend/pages/admin/dashboard.tsx
export default function AdminDashboard() {
  // Hardcoded components
  return (
    <div>
      <MetricsCards />
      <ServiceStatus />
      <RecentActivity />
    </div>
  );
}
```

### Target State
```typescript
// app-admin-frontend/pages/admin/dashboard.tsx
import { PageRenderer } from '@ewh/cms-core';

export default function AdminDashboard() {
  return (
    <PageRenderer
      pageSlug="admin-dashboard"
      mode="live"
      context={{
        tenantId: user.tenantId,
        userId: user.id,
        userRole: user.role
      }}
    />
  );
}
```

Page composition stored in DB:
```sql
SELECT * FROM cms.pages WHERE slug = 'admin-dashboard';

-- Returns layout JSON with 3 widgets:
-- - metrics-cards (row 0, col 0-12)
-- - service-status (row 1, col 0-6)
-- - recent-activity (row 1, col 6-12)
```

---

## 🎯 Key Features da Implementare

### 1. **Drag & Drop Widget Placement**
- Visual grid system
- Snap to grid
- Resize handles
- Collision detection

### 2. **Widget Configuration UI**
- Dynamic form generation da JSON Schema
- Real-time preview
- Reset to defaults
- Import/Export config

### 3. **Template System**
- Pre-built templates per:
  - Admin dashboards
  - Landing pages
  - Content pages
  - Email layouts
- One-click apply
- Template marketplace

### 4. **Version Control**
- Auto-save drafts
- Version history
- Diff viewer
- Rollback to previous version

### 5. **Publishing Workflow**
- Draft → Review → Published
- Approval system
- Schedule publishing
- Unpublish/Archive

### 6. **Permissions**
- Page-level permissions
- Widget-level permissions
- Template access control
- Publishing permissions

### 7. **Multi-tenancy**
- Tenant-specific pages
- Tenant-specific widgets
- Tenant theme overrides

### 8. **Analytics Integration**
- Page views
- Widget interactions
- A/B testing support
- Heatmaps

---

## 🔧 Development Tools

### CLI Commands
```bash
# Generate new widget
npm run widget:create --name MyWidget --category monitoring

# Generate new template
npm run template:create --name DashboardTemplate

# Migrate page to widget composition
npm run page:migrate --page /admin/dashboard

# Export page as template
npm run template:export --page /admin/dashboard --name AdminDash

# Import widgets from npm package
npm run widget:import --package @my-company/custom-widgets
```

---

## 📚 Documentation Structure

```
docs/
├── architecture/
│   ├── overview.md
│   ├── database-schema.md
│   ├── widget-system.md
│   └── cms-workflow.md
│
├── guides/
│   ├── creating-widgets.md
│   ├── creating-pages.md
│   ├── creating-templates.md
│   └── publishing-pages.md
│
├── api/
│   ├── widgets-api.md
│   ├── pages-api.md
│   ├── templates-api.md
│   └── cms-api.md
│
└── examples/
    ├── admin-dashboard.md
    ├── landing-page.md
    └── custom-widget.md
```

---

## 🎉 End Goal

### Admin Experience
1. Apre CMS admin UI
2. Crea nuova pagina o modifica esistente
3. Drag & drop widgets dalla sidebar
4. Configura ogni widget visivamente
5. Preview real-time
6. Salva come draft o pubblica
7. Pagina immediatamente disponibile

### Developer Experience
1. Crea nuovo widget seguendo template
2. Registra nel registry
3. Widget automaticamente disponibile in:
   - Page Builder
   - CMS
   - Dashboard
4. Mock data per preview integrato
5. TypeScript types auto-generated
6. Hot reload in dev mode

### End User Experience
1. Visita dashboard personalizzata
2. Vede solo widget rilevanti per il suo ruolo
3. Dati real-time con auto-refresh
4. Responsive su tutti i device
5. Performance ottimizzate con caching

---

## 🤔 Prossimo Step

**Cosa facciamo per primo?**

**A)** Creare database schema CMS + migrations

**B)** Implementare svc-cms backend service

**C)** Creare PageRenderer component (per renderizzare composizioni)

**D)** Migrare prima pagina admin (es. dashboard) a widget composition

**E)** Altro?

Dimmi da dove vuoi partire! 🚀
