# 🎨 Universal Editing System Specification
## Sistema Completo per Editabilità Universale con Template e Librerie Componenti

**Data**: 15 Ottobre 2025
**Versione**: 2.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Vision

**Ogni app della piattaforma deve avere una modalità di editing** che permetta di:
- ✅ Editare qualsiasi elemento visuale
- ✅ Creare e salvare template riutilizzabili
- ✅ Gestire librerie di componenti personalizzati
- ✅ Supportare templating avanzato con data binding
- ✅ Permission-based editing (chi può editare cosa)

---

## 🏗️ Architettura Unificata

```
┌──────────────────────────────────────────────────────────────┐
│                    UNIVERSAL EDITING LAYER                     │
│                                                                │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │ JSON Renderer  │  │ Visual Editor  │  │ Template       │  │
│  │ (Runtime)      │  │ (Design Time)  │  │ System         │  │
│  └────────────────┘  └────────────────┘  └────────────────┘  │
│           │                  │                    │            │
└───────────┼──────────────────┼────────────────────┼───────────┘
            │                  │                    │
            ▼                  ▼                    ▼
┌────────────────────────────────────────────────────────────────┐
│                    UNIFIED DATA LAYER                          │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  pages         templates         components      widgets │ │
│  │  (instances)   (reusable)        (library)      (shared) │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────────────┐
│           svc-page-builder (Unified Backend Service)           │
│  ┌────────┐  ┌─────────┐  ┌────────────┐  ┌────────────────┐ │
│  │ Pages  │  │Templates│  │ Components │  │ Custom         │ │
│  │ API    │  │ API     │  │ Library    │  │ Endpoints API  │ │
│  └────────┘  └─────────┘  └────────────┘  └────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

---

## 📊 Database Schema Unificato

### Core Tables

```sql
-- ============================================================================
-- PAGES - Actual page instances
-- ============================================================================
CREATE TABLE pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Identity
  page_key VARCHAR(255) NOT NULL,
  title VARCHAR(500) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  description TEXT,

  -- Content Storage (JSON-based)
  layout_config JSONB NOT NULL, -- Full page structure
  theme_overrides JSONB, -- Page-specific theme
  data_bindings JSONB, -- {{api.xxx}} bindings

  -- Template relationship
  template_id UUID REFERENCES templates(id),
  template_version INTEGER,

  -- Access Control
  is_public BOOLEAN DEFAULT false,
  required_roles TEXT[],

  -- Publishing
  status VARCHAR(50) DEFAULT 'draft', -- draft|published|archived
  published_at TIMESTAMPTZ,
  published_by UUID REFERENCES users(id),

  -- Versioning
  version INTEGER DEFAULT 1,
  parent_version_id UUID REFERENCES pages(id),

  -- SEO
  meta_title VARCHAR(255),
  meta_description TEXT,
  meta_keywords TEXT[],
  og_image VARCHAR(500),

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),

  UNIQUE(tenant_id, page_key, version)
);

-- ============================================================================
-- TEMPLATES - Reusable page templates (user-created)
-- ============================================================================
CREATE TABLE templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,

  -- Identity
  template_key VARCHAR(255) NOT NULL,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  category VARCHAR(100), -- 'dashboard', 'form', 'listing', etc.

  -- Template Content
  layout_config JSONB NOT NULL,
  default_data_bindings JSONB, -- Default bindings
  required_data_sources TEXT[], -- ['api.users', 'api.stats']

  -- Thumbnail
  thumbnail_url VARCHAR(500),
  preview_image VARCHAR(500),

  -- Sharing
  is_public BOOLEAN DEFAULT false, -- Share across tenants
  is_featured BOOLEAN DEFAULT false, -- Show in gallery
  visibility VARCHAR(50) DEFAULT 'private', -- private|tenant|public

  -- Usage tracking
  usage_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMPTZ,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),

  UNIQUE(tenant_id, template_key)
);

-- ============================================================================
-- COMPONENTS - Component library (reusable building blocks)
-- ============================================================================
CREATE TABLE components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,

  -- Identity
  component_key VARCHAR(255) NOT NULL,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  category VARCHAR(100), -- 'layout', 'form', 'data-display', etc.

  -- Component Definition
  component_type VARCHAR(100) NOT NULL, -- 'react', 'vue', 'html', 'custom'
  component_path VARCHAR(500), -- '@ewh/components/MyComponent'

  -- Configuration
  config_schema JSONB NOT NULL, -- JSON Schema for validation
  default_props JSONB NOT NULL,
  style_config JSONB, -- Default styles

  -- UI Metadata
  icon VARCHAR(100), -- Lucide icon name
  preview_image VARCHAR(500),
  preview_html TEXT,

  -- Versioning
  version VARCHAR(50) DEFAULT '1.0.0',
  is_stable BOOLEAN DEFAULT true,

  -- Sharing
  is_global BOOLEAN DEFAULT false, -- Available to all tenants
  is_custom BOOLEAN DEFAULT false, -- Custom tenant component
  visibility VARCHAR(50) DEFAULT 'tenant',

  -- Dependencies
  dependencies JSONB, -- NPM packages or other components needed

  -- Documentation
  documentation TEXT,
  usage_examples TEXT,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  UNIQUE(tenant_id, component_key, version)
);

-- ============================================================================
-- COMPONENT_INSTANCES - Component usage tracking
-- ============================================================================
CREATE TABLE component_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  component_id UUID REFERENCES components(id) ON DELETE CASCADE,
  page_id UUID REFERENCES pages(id) ON DELETE CASCADE,

  -- Instance config (overrides default_props)
  instance_config JSONB NOT NULL,
  instance_data_bindings JSONB,

  -- Position in page
  parent_element_id VARCHAR(255), -- ID of parent in layout
  sort_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- CUSTOM_BLOCKS - User-created reusable blocks
-- ============================================================================
CREATE TABLE custom_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),

  -- Identity
  block_key VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),

  -- Block Content (can be composition of multiple components)
  block_config JSONB NOT NULL, -- Full component tree

  -- UI
  icon VARCHAR(100),
  preview_image VARCHAR(500),

  -- Sharing
  is_shared BOOLEAN DEFAULT false, -- Share with team
  allowed_users UUID[], -- Specific users

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, block_key)
);

-- ============================================================================
-- WIDGET_REGISTRY - Platform/Tenant/User widgets (existing system)
-- ============================================================================
-- (Already exists from svc-page-builder)
-- Extended with template support:

ALTER TABLE widgets.widget_definitions
  ADD COLUMN template_id UUID REFERENCES templates(id);

ALTER TABLE widgets.widget_definitions
  ADD COLUMN supports_templating BOOLEAN DEFAULT true;

-- ============================================================================
-- TEMPLATE_GALLERY - Categorized template collections
-- ============================================================================
CREATE TABLE template_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Collection info
  name VARCHAR(500) NOT NULL,
  description TEXT,
  slug VARCHAR(255) NOT NULL UNIQUE,

  -- UI
  icon VARCHAR(100),
  cover_image VARCHAR(500),

  -- Templates in collection
  template_ids UUID[],

  -- Ordering
  sort_order INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TEMPLATE_TAGS - Template categorization
-- ============================================================================
CREATE TABLE template_tags (
  template_id UUID REFERENCES templates(id) ON DELETE CASCADE,
  tag VARCHAR(100) NOT NULL,

  PRIMARY KEY (template_id, tag)
);

-- ============================================================================
-- USER_FAVORITES - User's favorited templates/components
-- ============================================================================
CREATE TABLE user_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Favorited item (polymorphic)
  item_type VARCHAR(50) NOT NULL, -- 'template', 'component', 'block'
  item_id UUID NOT NULL,

  -- Metadata
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, item_type, item_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX idx_pages_tenant ON pages(tenant_id);
CREATE INDEX idx_pages_template ON pages(template_id);
CREATE INDEX idx_pages_status ON pages(status);
CREATE INDEX idx_pages_published ON pages(published_at) WHERE status = 'published';

CREATE INDEX idx_templates_tenant ON templates(tenant_id);
CREATE INDEX idx_templates_category ON templates(category);
CREATE INDEX idx_templates_visibility ON templates(visibility);
CREATE INDEX idx_templates_featured ON templates(is_featured) WHERE is_featured = true;

CREATE INDEX idx_components_tenant ON components(tenant_id);
CREATE INDEX idx_components_category ON components(category);
CREATE INDEX idx_components_type ON components(component_type);

CREATE INDEX idx_component_instances_page ON component_instances(page_id);
CREATE INDEX idx_component_instances_component ON component_instances(component_id);

CREATE INDEX idx_custom_blocks_tenant ON custom_blocks(tenant_id);
CREATE INDEX idx_custom_blocks_user ON custom_blocks(user_id);

CREATE INDEX idx_template_tags_tag ON template_tags(tag);

CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_type_id ON user_favorites(item_type, item_id);

-- ============================================================================
-- GIN INDEXES for JSONB search
-- ============================================================================
CREATE INDEX idx_pages_layout_config ON pages USING gin(layout_config);
CREATE INDEX idx_templates_layout_config ON templates USING gin(layout_config);
CREATE INDEX idx_components_config_schema ON components USING gin(config_schema);
```

---

## 🔌 API Endpoints Completo

### Pages Management

```http
# List all pages
GET /api/pages
Query: ?tenant_id=uuid&status=published&template_id=uuid

# Get page by key
GET /api/pages/:pageKey

# Create page
POST /api/pages
Body: {
  "pageKey": "dashboard",
  "title": "My Dashboard",
  "layoutConfig": { /* JSON */ },
  "templateId": "uuid", // Optional
  "requiredRoles": ["USER"]
}

# Update page
PUT /api/pages/:pageKey

# Publish page
POST /api/pages/:pageKey/publish

# Create version
POST /api/pages/:pageKey/versions

# Revert to version
POST /api/pages/:pageKey/revert/:versionId

# Duplicate page
POST /api/pages/:pageKey/duplicate
Body: {
  "newPageKey": "dashboard-copy",
  "newTitle": "Dashboard Copy"
}

# Delete page
DELETE /api/pages/:pageKey
```

### Templates Management

```http
# List templates
GET /api/templates
Query: ?category=dashboard&visibility=public&featured=true

# Get template
GET /api/templates/:templateKey

# Create template
POST /api/templates
Body: {
  "templateKey": "my-template",
  "name": "My Template",
  "layoutConfig": { /* JSON */ },
  "category": "dashboard",
  "visibility": "public"
}

# Update template
PUT /api/templates/:templateKey

# Delete template
DELETE /api/templates/:templateKey

# Create page from template
POST /api/templates/:templateKey/instantiate
Body: {
  "pageKey": "new-page",
  "title": "New Page from Template",
  "dataBindings": { /* Override bindings */ }
}

# Get template usage stats
GET /api/templates/:templateKey/usage

# Favorite template
POST /api/templates/:templateKey/favorite

# Unfavorite template
DELETE /api/templates/:templateKey/favorite

# Get my favorited templates
GET /api/templates/favorites
```

### Components Library

```http
# List components
GET /api/components
Query: ?category=form&type=react&tenant_id=uuid

# Get component
GET /api/components/:componentKey

# Create custom component
POST /api/components
Body: {
  "componentKey": "my-widget",
  "name": "My Widget",
  "componentType": "react",
  "componentPath": "@ewh/custom/MyWidget",
  "configSchema": { /* JSON Schema */ },
  "defaultProps": { /* default values */ },
  "category": "custom"
}

# Update component
PUT /api/components/:componentKey

# Delete component
DELETE /api/components/:componentKey

# Get component usage
GET /api/components/:componentKey/usage

# Test component render
POST /api/components/:componentKey/test
Body: {
  "props": { /* test props */ }
}
```

### Custom Blocks

```http
# List my blocks
GET /api/blocks
Query: ?shared=true

# Create block
POST /api/blocks
Body: {
  "blockKey": "my-hero-section",
  "name": "Hero Section",
  "blockConfig": { /* component tree */ },
  "isShared": true
}

# Update block
PUT /api/blocks/:blockKey

# Delete block
DELETE /api/blocks/:blockKey

# Share block with user
POST /api/blocks/:blockKey/share
Body: {
  "userIds": ["uuid1", "uuid2"]
}

# Unshare block
POST /api/blocks/:blockKey/unshare
```

### Template Collections

```http
# Get featured collections
GET /api/collections/featured

# Get collection
GET /api/collections/:slug

# Get templates in collection
GET /api/collections/:slug/templates
```

---

## 🎨 Standard del JSON Layout

### Page Layout Schema

```typescript
interface PageLayoutConfig {
  version: string; // "2.0"
  metadata: {
    editMode: 'visual' | 'code' | 'hybrid';
    responsive: boolean;
    breakpoints?: string[];
  };
  layout: LayoutNode;
  bindings: DataBindings;
  actions: ActionHandlers;
  theme: ThemeConfig;
}

interface LayoutNode {
  type: string; // 'container', 'component', 'widget', etc.
  id: string; // Unique ID
  props: Record<string, any>;
  style?: CSSProperties;
  children?: LayoutNode[];
  bindings?: Record<string, string>; // Prop bindings
  conditions?: ConditionalRender[]; // When to render
  events?: EventHandlers;
}

interface DataBindings {
  api: Record<string, APIBinding>;
  variables: Record<string, any>;
  computed: Record<string, string>; // Computed values
}

interface APIBinding {
  endpoint: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  params?: Record<string, any>;
  headers?: Record<string, string>;
  transform?: string; // JS expression to transform data
  refresh?: number; // Auto-refresh interval (ms)
  cache?: boolean;
  onSuccess?: Action;
  onError?: Action;
}

interface Action {
  type: 'navigate' | 'api-call' | 'set-state' | 'show-modal' | 'custom';
  params: Record<string, any>;
}

interface ThemeConfig {
  extends?: string; // 'default', 'tenant-theme'
  colors?: Record<string, string>;
  typography?: TypographyConfig;
  spacing?: Record<string, number>;
}
```

### Example: Complete Dashboard Page

```json
{
  "version": "2.0",
  "metadata": {
    "editMode": "visual",
    "responsive": true,
    "breakpoints": ["sm", "md", "lg", "xl"]
  },
  "layout": {
    "type": "container",
    "id": "root",
    "props": {
      "maxWidth": "7xl",
      "padding": 6
    },
    "children": [
      {
        "type": "heading",
        "id": "page-title",
        "props": {
          "level": 1,
          "text": "{{page.title || 'Dashboard'}}"
        },
        "bindings": {
          "text": "page.title"
        }
      },
      {
        "type": "grid",
        "id": "stats-grid",
        "props": {
          "columns": {
            "sm": 1,
            "md": 2,
            "lg": 4
          },
          "gap": 4
        },
        "children": [
          {
            "type": "widget",
            "id": "stat-users",
            "props": {
              "widgetKey": "stat-card",
              "title": "Total Users",
              "icon": "Users",
              "color": "blue",
              "format": "number"
            },
            "bindings": {
              "value": "api.stats.totalUsers",
              "change": "api.stats.usersChange"
            }
          },
          {
            "type": "widget",
            "id": "stat-revenue",
            "props": {
              "widgetKey": "stat-card",
              "title": "Revenue",
              "icon": "DollarSign",
              "color": "green",
              "format": "currency"
            },
            "bindings": {
              "value": "api.stats.revenue",
              "change": "api.stats.revenueChange"
            }
          }
        ]
      },
      {
        "type": "component",
        "id": "revenue-chart",
        "props": {
          "componentKey": "line-chart",
          "title": "Revenue Trend",
          "height": 400
        },
        "bindings": {
          "data": "api.analytics.revenue",
          "labels": "api.analytics.dates"
        }
      },
      {
        "type": "custom-block",
        "id": "recent-orders",
        "props": {
          "blockKey": "orders-table"
        },
        "bindings": {
          "orders": "api.orders.recent"
        }
      }
    ]
  },
  "bindings": {
    "api": {
      "stats": {
        "endpoint": "/api/admin/tenant/analytics/stats",
        "method": "GET",
        "refresh": 30000,
        "cache": true
      },
      "analytics": {
        "endpoint": "/api/admin/tenant/analytics/revenue",
        "method": "GET",
        "params": {
          "period": "{{variables.selectedPeriod}}"
        },
        "transform": "data => ({ revenue: data.values, dates: data.labels })"
      },
      "orders": {
        "endpoint": "/api/orders",
        "method": "GET",
        "params": {
          "limit": 10,
          "status": "recent"
        }
      }
    },
    "variables": {
      "selectedPeriod": "30d",
      "currentPage": 1
    },
    "computed": {
      "totalValue": "api.stats.revenue + api.stats.expenses"
    }
  },
  "actions": {
    "refreshAll": {
      "type": "refresh-bindings",
      "params": {
        "targets": ["api.stats", "api.orders"]
      }
    },
    "changePeriod": {
      "type": "set-variable",
      "params": {
        "key": "selectedPeriod",
        "value": "{{event.value}}"
      }
    }
  },
  "theme": {
    "extends": "tenant-theme",
    "colors": {
      "primary": "#3B82F6"
    }
  }
}
```

---

## ⚙️ EDITING MODES PER APP

### Ogni App DEVE Implementare:

#### 1. View Mode (Default)
- Rendering normale della UI
- Interazione utente standard
- Nessuna funzionalità di editing visibile

#### 2. Edit Mode (Toggle)
```typescript
// Trigger: Click "Edit Page" button, or Ctrl+E

interface EditModeFeatures {
  // Visual editing
  inlineEditing: boolean; // Click to edit text
  dragAndDrop: boolean; // Reorder components
  componentToolbar: boolean; // Hover tools (edit, delete, duplicate)

  // Inspector panel
  showInspector: boolean;
  inspectorTabs: ['properties', 'styles', 'data', 'actions'];

  // Component palette
  showComponentLibrary: boolean;
  libraryCategories: string[];

  // Grid & Guidelines
  showGrid: boolean;
  showBoundingBoxes: boolean;
  snapToGrid: boolean;
}
```

#### 3. Code Mode (Advanced)
```typescript
// For developers/advanced users
interface CodeModeFeatures {
  jsonEditor: boolean; // Edit layout JSON directly
  cssEditor: boolean; // Edit custom CSS
  jsEditor: boolean; // Edit custom actions

  // Live preview
  splitView: boolean; // Code + Visual side-by-side
  hotReload: boolean;
}
```

### Implementation Standard

```typescript
// src/components/EditableApp.tsx
import { useState } from 'react';
import { JSONRenderer } from '@ewh/page-builder';
import { EditModeToolbar } from '@ewh/page-builder/edit-mode';

export function EditableApp({ pageKey }: { pageKey: string }) {
  const [editMode, setEditMode] = useState<'view' | 'edit' | 'code'>('view');
  const [pageConfig, setPageConfig] = useState<PageLayoutConfig | null>(null);

  return (
    <div className="editable-app">
      {/* Edit Mode Toolbar (only visible in edit/code mode) */}
      {editMode !== 'view' && (
        <EditModeToolbar
          mode={editMode}
          onModeChange={setEditMode}
          onSave={() => savePage(pageConfig)}
          onRevert={() => revertChanges()}
        />
      )}

      {/* Main Content */}
      {editMode === 'view' && (
        <JSONRenderer pageKey={pageKey} />
      )}

      {editMode === 'edit' && (
        <VisualEditor
          pageKey={pageKey}
          config={pageConfig}
          onChange={setPageConfig}
        />
      )}

      {editMode === 'code' && (
        <CodeEditor
          config={pageConfig}
          onChange={setPageConfig}
        />
      )}

      {/* Keyboard Shortcuts */}
      <KeyboardShortcuts
        shortcuts={{
          'Ctrl+E': () => toggleEditMode(),
          'Ctrl+S': () => savePage(),
          'Ctrl+Z': () => undo(),
          'Ctrl+Shift+Z': () => redo()
        }}
      />
    </div>
  );
}
```

---

## 📚 TEMPLATE SYSTEM

### Template Types

```typescript
enum TemplateType {
  PAGE = 'page', // Full page template
  SECTION = 'section', // Page section (hero, features, etc.)
  COMPONENT = 'component', // Single component preset
  LAYOUT = 'layout' // Page layout structure
}

interface Template {
  id: string;
  key: string;
  name: string;
  type: TemplateType;
  category: string;

  // Content
  config: PageLayoutConfig;

  // Customization slots
  slots: TemplateSlot[];
  variables: TemplateVariable[];

  // Metadata
  thumbnail: string;
  description: string;
  tags: string[];

  // Usage
  usageCount: number;
  isFeatured: boolean;
}

interface TemplateSlot {
  id: string;
  name: string;
  description: string;
  type: 'component' | 'text' | 'image' | 'list';
  required: boolean;
  defaultValue?: any;
}

interface TemplateVariable {
  key: string;
  label: string;
  type: 'string' | 'number' | 'boolean' | 'color' | 'url';
  defaultValue: any;
  validation?: ValidationRule;
}
```

### Creating a Template

```http
POST /api/templates
Content-Type: application/json

{
  "templateKey": "hero-with-cta",
  "name": "Hero Section with CTA",
  "type": "section",
  "category": "hero",
  "description": "Eye-catching hero section with title, subtitle, and call-to-action buttons",
  "config": {
    "version": "2.0",
    "layout": {
      "type": "section",
      "props": {
        "className": "hero-section",
        "padding": "{{variables.padding}}"
      },
      "children": [
        {
          "type": "heading",
          "props": {
            "level": 1,
            "text": "{{slots.title}}"
          }
        },
        {
          "type": "text",
          "props": {
            "content": "{{slots.subtitle}}"
          }
        },
        {
          "type": "button-group",
          "children": "{{slots.buttons}}"
        }
      ]
    }
  },
  "slots": [
    {
      "id": "title",
      "name": "Hero Title",
      "type": "text",
      "required": true,
      "defaultValue": "Welcome to Our Platform"
    },
    {
      "id": "subtitle",
      "name": "Subtitle",
      "type": "text",
      "required": false,
      "defaultValue": "Build amazing things"
    },
    {
      "id": "buttons",
      "name": "CTA Buttons",
      "type": "list",
      "required": true,
      "defaultValue": [
        { "label": "Get Started", "variant": "primary" },
        { "label": "Learn More", "variant": "secondary" }
      ]
    }
  ],
  "variables": [
    {
      "key": "padding",
      "label": "Section Padding",
      "type": "number",
      "defaultValue": 12
    },
    {
      "key": "backgroundColor",
      "label": "Background Color",
      "type": "color",
      "defaultValue": "#FFFFFF"
    }
  ],
  "tags": ["hero", "cta", "landing"],
  "visibility": "public"
}
```

### Using a Template

```http
POST /api/templates/hero-with-cta/instantiate
Content-Type: application/json

{
  "pageKey": "landing-page",
  "slots": {
    "title": "Transform Your Business",
    "subtitle": "With our cutting-edge platform",
    "buttons": [
      { "label": "Start Free Trial", "variant": "primary", "url": "/signup" },
      { "label": "Watch Demo", "variant": "secondary", "url": "/demo" }
    ]
  },
  "variables": {
    "padding": 16,
    "backgroundColor": "#F3F4F6"
  }
}
```

---

## 🎨 COMPONENT LIBRARY SYSTEM

### Standard Component Definition

```typescript
interface ComponentDefinition {
  // Identity
  key: string;
  name: string;
  description: string;
  category: string;

  // Implementation
  componentType: 'react' | 'vue' | 'html' | 'custom';
  componentPath: string; // Import path

  // Configuration
  props: PropDefinition[];
  slots?: SlotDefinition[];
  events?: EventDefinition[];

  // Styling
  styleOptions: StyleOption[];
  defaultStyles: CSSProperties;

  // Preview
  icon: string;
  thumbnail: string;
  livePreview: boolean;

  // Documentation
  docs: string;
  examples: ComponentExample[];

  // Version
  version: string;
  changelog: string[];
}

interface PropDefinition {
  name: string;
  type: string;
  required: boolean;
  default?: any;
  options?: any[]; // For select/enum props
  validation?: ValidationRule;
  description: string;
}
```

### Creating Custom Component

```typescript
// 1. Define component
// src/components/MyCustomWidget.tsx
import React from 'react';

export interface MyCustomWidgetProps {
  title: string;
  items: Array<{ id: string; label: string }>;
  color?: 'blue' | 'green' | 'red';
  onItemClick?: (id: string) => void;
}

export function MyCustomWidget({ title, items, color = 'blue', onItemClick }: MyCustomWidgetProps) {
  return (
    <div className={`custom-widget widget-${color}`}>
      <h3>{title}</h3>
      <ul>
        {items.map(item => (
          <li key={item.id} onClick={() => onItemClick?.(item.id)}>
            {item.label}
          </li>
        ))}
      </ul>
    </div>
  );
}

// 2. Register component
POST /api/components
{
  "componentKey": "my-custom-widget",
  "name": "My Custom Widget",
  "description": "A customizable list widget",
  "category": "data-display",
  "componentType": "react",
  "componentPath": "@tenant/components/MyCustomWidget",
  "configSchema": {
    "type": "object",
    "required": ["title", "items"],
    "properties": {
      "title": {
        "type": "string",
        "description": "Widget title"
      },
      "items": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "id": { "type": "string" },
            "label": { "type": "string" }
          }
        }
      },
      "color": {
        "type": "string",
        "enum": ["blue", "green", "red"],
        "default": "blue"
      }
    }
  },
  "defaultProps": {
    "title": "My List",
    "items": [],
    "color": "blue"
  },
  "styleOptions": [
    {
      "name": "backgroundColor",
      "type": "color",
      "default": "#FFFFFF"
    }
  ],
  "icon": "List",
  "visibility": "tenant"
}

// 3. Use in page
{
  "type": "component",
  "props": {
    "componentKey": "my-custom-widget",
    "title": "Recent Activities"
  },
  "bindings": {
    "items": "api.activities.recent"
  },
  "events": {
    "onItemClick": {
      "type": "navigate",
      "url": "/activity/{{event.itemId}}"
    }
  }
}
```

---

## 🔧 PERMISSION SYSTEM

### Edit Permissions

```typescript
interface EditPermissions {
  // Who can edit
  canEdit: boolean;

  // What can be edited
  editableAreas: {
    content: boolean; // Text, images
    layout: boolean; // Structure, components
    styles: boolean; // CSS, theme
    data: boolean; // Data bindings
    actions: boolean; // Event handlers
    code: boolean; // Raw JSON/code
  };

  // Template management
  canCreateTemplates: boolean;
  canPublishTemplates: boolean;
  canShareTemplates: boolean;

  // Component library
  canCreateComponents: boolean;
  canModifyComponents: boolean;
  canDeleteComponents: boolean;
}

// Permission check middleware
export function checkEditPermission(
  user: User,
  page: Page,
  action: keyof EditPermissions['editableAreas']
): boolean {
  // OWNER can edit everything
  if (user.role === 'OWNER') return true;

  // PLATFORM_ADMIN can edit everything except code
  if (user.role === 'PLATFORM_ADMIN') {
    return action !== 'code';
  }

  // TENANT_ADMIN can edit tenant pages
  if (user.role === 'TENANT_ADMIN' && page.tenantId === user.tenantId) {
    return ['content', 'layout', 'styles'].includes(action);
  }

  // Regular users cannot edit by default
  return false;
}
```

---

## 📋 DEPLOYMENT CHECKLIST

### For Each App

- [ ] Edit mode implemented (`Ctrl+E` to toggle)
- [ ] Visual editor integrated
- [ ] JSON renderer supports all component types
- [ ] Template system accessible
- [ ] Component library browsable
- [ ] Permissions enforced
- [ ] Save/Publish workflow implemented
- [ ] Version control working
- [ ] Undo/Redo functional
- [ ] Keyboard shortcuts active
- [ ] Documentation updated

### Platform-wide

- [ ] `svc-page-builder` deployed
- [ ] Database migrations executed
- [ ] Component registry populated
- [ ] Default templates created
- [ ] Template gallery accessible
- [ ] Permission system configured
- [ ] Audit logging enabled
- [ ] Backup system active

---

**Questo è il sistema finale che unifica tutto.**
**Ogni app deve implementare questi standard per l'editabilità.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team & Design System Team
