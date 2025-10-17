# 🎨 JSON Rendering System Specification
## Sistema di Rendering Grafico Basato su JSON con Page Editor

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Executive Summary

Sistema che permette di definire **tutta l'interfaccia grafica tramite JSON**, renderizzabile dinamicamente e **editabile con il Page Editor**. Include:

- ✅ **JSON-based UI** - Tutta la grafica definita in JSON
- ✅ **Dynamic Rendering** - Rendering real-time da configurazione
- ✅ **Visual Editor** - Modifica WYSIWYG con drag & drop
- ✅ **Custom Endpoints** - Endpoint API personalizzabili per tenant
- ✅ **Component Library** - Libreria di componenti riutilizzabili
- ✅ **Theming System** - Temi e branding personalizzati
- ✅ **Responsive** - Layout responsive automatico

---

## 🏗️ Architettura Generale

```
┌──────────────────────────────────────────────────────────┐
│              app-page-builder (Visual Editor)             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Drag & Drop Interface                              │ │
│  │  ├── Component Palette                              │ │
│  │  ├── Canvas                                          │ │
│  │  ├── Properties Panel                                │ │
│  │  └── Preview Mode                                    │ │
│  └──────────────────────┬──────────────────────────────┘ │
└─────────────────────────┼────────────────────────────────┘
                          │ Save/Load JSON
                          ▼
┌──────────────────────────────────────────────────────────┐
│               svc-page-builder (Backend)                  │
│  ┌────────────────┐  ┌────────────────┐                  │
│  │ Pages Storage  │  │ Components Lib │                  │
│  │   (Database)   │  │   (Registry)   │                  │
│  └────────────────┘  └────────────────┘                  │
│  ┌────────────────┐  ┌────────────────┐                  │
│  │ Custom         │  │ Theming        │                  │
│  │ Endpoints      │  │ System         │                  │
│  └────────────────┘  └────────────────┘                  │
└──────────────────────────┬───────────────────────────────┘
                           │ JSON Config
                           ▼
┌──────────────────────────────────────────────────────────┐
│           app-shell-frontend / Any Frontend               │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  JSON Renderer Component                            │ │
│  │  ├── Fetch JSON from API                            │ │
│  │  ├── Parse & Validate Schema                        │ │
│  │  ├── Render Components                              │ │
│  │  └── Handle Events & Data Binding                   │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 📊 Database Schema

### Pages & Layouts

```sql
-- Pages definition
CREATE TABLE pages (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
  page_key VARCHAR(255) NOT NULL, -- 'dashboard', 'settings', 'custom-page-1'
  title VARCHAR(500) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  description TEXT,

  -- JSON configuration
  layout_config JSONB NOT NULL, -- Page layout structure
  theme_config JSONB, -- Theme overrides
  meta_data JSONB, -- SEO, analytics, etc.

  -- Access control
  is_public BOOLEAN DEFAULT false,
  required_roles TEXT[], -- ['USER', 'TENANT_ADMIN']

  -- Status
  status VARCHAR(50) DEFAULT 'draft', -- draft, published, archived
  published_at TIMESTAMPTZ,

  -- Versioning
  version INTEGER DEFAULT 1,
  parent_version_id INTEGER REFERENCES pages(id),

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id),
  updated_by INTEGER REFERENCES users(id),

  UNIQUE(tenant_id, page_key, version)
);

-- Component definitions (reusable)
CREATE TABLE components (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
  component_key VARCHAR(255) NOT NULL,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  category VARCHAR(100), -- 'layout', 'form', 'data-display', 'navigation'

  -- Component configuration
  config_schema JSONB NOT NULL, -- JSON schema for props validation
  default_props JSONB NOT NULL,

  -- UI metadata
  icon VARCHAR(100),
  preview_image VARCHAR(500),

  -- Availability
  is_global BOOLEAN DEFAULT false, -- Available to all tenants
  is_custom BOOLEAN DEFAULT false, -- Custom tenant component

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id),

  UNIQUE(tenant_id, component_key)
);

-- Custom endpoints (tenant-specific)
CREATE TABLE custom_endpoints (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
  endpoint_key VARCHAR(255) NOT NULL,
  name VARCHAR(500) NOT NULL,
  description TEXT,

  -- Endpoint configuration
  method VARCHAR(10) NOT NULL, -- GET, POST, PUT, DELETE
  path VARCHAR(500) NOT NULL, -- /api/custom/:tenant/my-endpoint

  -- Logic definition (JSON-based)
  logic_config JSONB NOT NULL, -- Workflow definition

  -- Request/Response schemas
  request_schema JSONB,
  response_schema JSONB,

  -- Authentication & Authorization
  requires_auth BOOLEAN DEFAULT true,
  allowed_roles TEXT[],
  rate_limit INTEGER DEFAULT 100, -- requests per hour

  -- Status
  is_enabled BOOLEAN DEFAULT true,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id),

  UNIQUE(tenant_id, endpoint_key)
);

-- Themes (branding)
CREATE TABLE themes (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
  theme_key VARCHAR(255) NOT NULL,
  name VARCHAR(500) NOT NULL,

  -- Theme configuration
  colors JSONB NOT NULL, -- Primary, secondary, backgrounds, etc.
  typography JSONB NOT NULL, -- Fonts, sizes, weights
  spacing JSONB, -- Margins, padding scale
  borders JSONB, -- Border radius, width
  shadows JSONB, -- Box shadows

  -- Assets
  logo_url VARCHAR(500),
  favicon_url VARCHAR(500),
  background_image VARCHAR(500),

  -- Status
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, theme_key)
);

-- Page analytics
CREATE TABLE page_analytics (
  id SERIAL PRIMARY KEY,
  page_id INTEGER REFERENCES pages(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

  -- Event data
  event_type VARCHAR(50) NOT NULL, -- 'view', 'edit', 'interaction'
  event_data JSONB,

  -- Session info
  session_id VARCHAR(255),
  ip_address INET,
  user_agent TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_pages_tenant ON pages(tenant_id);
CREATE INDEX idx_pages_key ON pages(page_key);
CREATE INDEX idx_pages_status ON pages(status);
CREATE INDEX idx_components_tenant ON components(tenant_id);
CREATE INDEX idx_components_category ON components(category);
CREATE INDEX idx_custom_endpoints_tenant ON custom_endpoints(tenant_id);
CREATE INDEX idx_custom_endpoints_path ON custom_endpoints(path);
CREATE INDEX idx_themes_tenant ON themes(tenant_id);
CREATE INDEX idx_page_analytics_page ON page_analytics(page_id);
CREATE INDEX idx_page_analytics_created ON page_analytics(created_at);
```

---

## 📝 JSON Schema Definitions

### Page Layout Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "layout"],
  "properties": {
    "version": {
      "type": "string",
      "enum": ["1.0"]
    },
    "layout": {
      "type": "object",
      "required": ["type", "children"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["container", "grid", "flex", "stack"]
        },
        "props": {
          "type": "object"
        },
        "children": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/component"
          }
        }
      }
    },
    "bindings": {
      "type": "object",
      "description": "Data bindings for dynamic content"
    },
    "actions": {
      "type": "object",
      "description": "Event handlers and actions"
    }
  },
  "definitions": {
    "component": {
      "type": "object",
      "required": ["type"],
      "properties": {
        "type": {
          "type": "string"
        },
        "id": {
          "type": "string"
        },
        "props": {
          "type": "object"
        },
        "children": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/component"
          }
        },
        "bindings": {
          "type": "object"
        },
        "conditions": {
          "type": "object",
          "description": "Conditional rendering rules"
        }
      }
    }
  }
}
```

### Example Page Configuration

```json
{
  "version": "1.0",
  "layout": {
    "type": "container",
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
          "text": "Dashboard",
          "className": "mb-6"
        }
      },
      {
        "type": "grid",
        "id": "stats-grid",
        "props": {
          "columns": 4,
          "gap": 4
        },
        "children": [
          {
            "type": "stat-card",
            "id": "stat-users",
            "props": {
              "title": "Total Users",
              "icon": "Users",
              "color": "blue"
            },
            "bindings": {
              "value": "{{api.stats.users}}",
              "change": "{{api.stats.usersChange}}"
            }
          },
          {
            "type": "stat-card",
            "id": "stat-revenue",
            "props": {
              "title": "Revenue",
              "icon": "DollarSign",
              "color": "green",
              "format": "currency"
            },
            "bindings": {
              "value": "{{api.stats.revenue}}",
              "change": "{{api.stats.revenueChange}}"
            }
          }
        ]
      },
      {
        "type": "chart",
        "id": "revenue-chart",
        "props": {
          "title": "Revenue Over Time",
          "chartType": "line",
          "height": 400
        },
        "bindings": {
          "data": "{{api.analytics.revenue}}",
          "labels": "{{api.analytics.dates}}"
        }
      },
      {
        "type": "data-table",
        "id": "recent-orders",
        "props": {
          "title": "Recent Orders",
          "columns": [
            {
              "key": "id",
              "label": "Order ID",
              "sortable": true
            },
            {
              "key": "customer",
              "label": "Customer"
            },
            {
              "key": "amount",
              "label": "Amount",
              "format": "currency"
            },
            {
              "key": "status",
              "label": "Status",
              "render": "status-badge"
            }
          ],
          "pageSize": 10
        },
        "bindings": {
          "data": "{{api.orders.recent}}",
          "loading": "{{api.orders.loading}}",
          "error": "{{api.orders.error}}"
        },
        "actions": {
          "onRowClick": {
            "type": "navigate",
            "url": "/orders/{{row.id}}"
          }
        }
      }
    ]
  },
  "bindings": {
    "api": {
      "stats": {
        "endpoint": "/api/admin/tenant/analytics/stats",
        "method": "GET",
        "refresh": 30000
      },
      "analytics": {
        "endpoint": "/api/admin/tenant/analytics/revenue",
        "method": "GET",
        "params": {
          "period": "30d"
        }
      },
      "orders": {
        "endpoint": "/api/orders",
        "method": "GET",
        "params": {
          "limit": 10,
          "sort": "created_at:desc"
        }
      }
    }
  },
  "actions": {
    "refreshData": {
      "type": "refresh-bindings",
      "targets": ["api.stats", "api.orders"]
    }
  }
}
```

### Component Schema

```json
{
  "componentKey": "stat-card",
  "name": "Statistic Card",
  "description": "Display a statistic with optional trend indicator",
  "category": "data-display",
  "schema": {
    "type": "object",
    "required": ["title"],
    "properties": {
      "title": {
        "type": "string",
        "description": "Card title"
      },
      "value": {
        "type": ["string", "number"],
        "description": "Main value to display"
      },
      "icon": {
        "type": "string",
        "description": "Lucide icon name"
      },
      "color": {
        "type": "string",
        "enum": ["blue", "green", "red", "yellow", "purple"],
        "default": "blue"
      },
      "change": {
        "type": "number",
        "description": "Percentage change (e.g., 12.5 for +12.5%)"
      },
      "format": {
        "type": "string",
        "enum": ["number", "currency", "percentage"],
        "default": "number"
      }
    }
  },
  "defaultProps": {
    "title": "Statistic",
    "value": 0,
    "color": "blue",
    "format": "number"
  }
}
```

### Custom Endpoint Schema

```json
{
  "endpointKey": "get-customer-insights",
  "name": "Get Customer Insights",
  "description": "Retrieve customer analytics and insights",
  "method": "GET",
  "path": "/api/custom/:tenant/customer-insights",
  "logicConfig": {
    "steps": [
      {
        "id": "fetch-customers",
        "type": "database-query",
        "config": {
          "table": "customers",
          "where": {
            "tenant_id": "{{auth.tenantId}}",
            "created_at": {
              "gte": "{{params.startDate}}",
              "lte": "{{params.endDate}}"
            }
          },
          "select": ["id", "name", "email", "total_spent", "order_count"]
        },
        "output": "customers"
      },
      {
        "id": "calculate-metrics",
        "type": "transform",
        "config": {
          "script": `
            const totalRevenue = customers.reduce((sum, c) => sum + c.total_spent, 0);
            const avgOrderValue = totalRevenue / customers.reduce((sum, c) => sum + c.order_count, 0);
            const topCustomers = customers.sort((a, b) => b.total_spent - a.total_spent).slice(0, 10);

            return {
              totalCustomers: customers.length,
              totalRevenue,
              avgOrderValue,
              topCustomers
            };
          `
        },
        "output": "metrics"
      },
      {
        "id": "return-response",
        "type": "response",
        "config": {
          "body": {
            "success": true,
            "data": "{{metrics}}"
          }
        }
      }
    ],
    "errorHandling": {
      "onError": {
        "type": "response",
        "config": {
          "status": 500,
          "body": {
            "success": false,
            "error": "{{error.message}}"
          }
        }
      }
    }
  },
  "requestSchema": {
    "type": "object",
    "properties": {
      "startDate": {
        "type": "string",
        "format": "date"
      },
      "endDate": {
        "type": "string",
        "format": "date"
      }
    }
  },
  "responseSchema": {
    "type": "object",
    "properties": {
      "success": {
        "type": "boolean"
      },
      "data": {
        "type": "object",
        "properties": {
          "totalCustomers": {
            "type": "number"
          },
          "totalRevenue": {
            "type": "number"
          },
          "avgOrderValue": {
            "type": "number"
          },
          "topCustomers": {
            "type": "array"
          }
        }
      }
    }
  },
  "requiresAuth": true,
  "allowedRoles": ["TENANT_ADMIN", "USER"],
  "rateLimit": 100
}
```

---

## 🔌 API Endpoints

### Page Management

```http
# Get all pages for tenant
GET /api/page-builder/pages
Authorization: Bearer {token}

# Get specific page
GET /api/page-builder/pages/:pageKey
Authorization: Bearer {token}

# Create page
POST /api/page-builder/pages
Authorization: Bearer {token}
Content-Type: application/json

{
  "pageKey": "dashboard",
  "title": "My Dashboard",
  "slug": "/dashboard",
  "layoutConfig": { /* JSON layout */ },
  "requiredRoles": ["USER"]
}

# Update page
PUT /api/page-builder/pages/:pageKey
Authorization: Bearer {token}
Content-Type: application/json

{
  "layoutConfig": { /* updated JSON layout */ }
}

# Publish page
POST /api/page-builder/pages/:pageKey/publish
Authorization: Bearer {token}

# Delete page
DELETE /api/page-builder/pages/:pageKey
Authorization: Bearer {token}

# Get page versions
GET /api/page-builder/pages/:pageKey/versions
Authorization: Bearer {token}

# Revert to version
POST /api/page-builder/pages/:pageKey/revert/:versionId
Authorization: Bearer {token}
```

### Component Library

```http
# Get all components
GET /api/page-builder/components
Authorization: Bearer {token}

# Get component by key
GET /api/page-builder/components/:componentKey
Authorization: Bearer {token}

# Create custom component
POST /api/page-builder/components
Authorization: Bearer {token}
Content-Type: application/json

{
  "componentKey": "my-custom-widget",
  "name": "My Custom Widget",
  "category": "custom",
  "configSchema": { /* JSON schema */ },
  "defaultProps": { /* default props */ }
}

# Update component
PUT /api/page-builder/components/:componentKey
Authorization: Bearer {token}

# Delete component
DELETE /api/page-builder/components/:componentKey
Authorization: Bearer {token}
```

### Custom Endpoints

```http
# Get all custom endpoints
GET /api/page-builder/endpoints
Authorization: Bearer {token}

# Get endpoint by key
GET /api/page-builder/endpoints/:endpointKey
Authorization: Bearer {token}

# Create custom endpoint
POST /api/page-builder/endpoints
Authorization: Bearer {token}
Content-Type: application/json

{
  "endpointKey": "my-endpoint",
  "name": "My Custom Endpoint",
  "method": "GET",
  "path": "/api/custom/:tenant/my-endpoint",
  "logicConfig": { /* workflow definition */ },
  "requiresAuth": true,
  "allowedRoles": ["USER"]
}

# Update endpoint
PUT /api/page-builder/endpoints/:endpointKey
Authorization: Bearer {token}

# Delete endpoint
DELETE /api/page-builder/endpoints/:endpointKey
Authorization: Bearer {token}

# Test endpoint
POST /api/page-builder/endpoints/:endpointKey/test
Authorization: Bearer {token}
Content-Type: application/json

{
  "params": { /* test parameters */ }
}

# Enable/disable endpoint
POST /api/page-builder/endpoints/:endpointKey/toggle
Authorization: Bearer {token}
```

### Themes

```http
# Get all themes
GET /api/page-builder/themes
Authorization: Bearer {token}

# Get active theme
GET /api/page-builder/themes/active
Authorization: Bearer {token}

# Create theme
POST /api/page-builder/themes
Authorization: Bearer {token}
Content-Type: application/json

{
  "themeKey": "my-theme",
  "name": "My Brand Theme",
  "colors": {
    "primary": "#3B82F6",
    "secondary": "#8B5CF6",
    "background": "#FFFFFF",
    "text": "#1F2937"
  },
  "typography": {
    "fontFamily": "Inter, sans-serif",
    "headingFontFamily": "Poppins, sans-serif"
  }
}

# Update theme
PUT /api/page-builder/themes/:themeKey
Authorization: Bearer {token}

# Set active theme
POST /api/page-builder/themes/:themeKey/activate
Authorization: Bearer {token}

# Delete theme
DELETE /api/page-builder/themes/:themeKey
Authorization: Bearer {token}
```

---

## 🎨 Built-in Components Library

### Layout Components

```typescript
// Container
{
  type: 'container',
  props: {
    maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '7xl',
    padding?: number,
    className?: string
  }
}

// Grid
{
  type: 'grid',
  props: {
    columns: number | { sm?: number, md?: number, lg?: number },
    gap?: number,
    className?: string
  }
}

// Flex
{
  type: 'flex',
  props: {
    direction?: 'row' | 'column',
    justify?: 'start' | 'end' | 'center' | 'between' | 'around',
    align?: 'start' | 'end' | 'center' | 'stretch',
    gap?: number,
    wrap?: boolean
  }
}

// Stack
{
  type: 'stack',
  props: {
    spacing?: number,
    divider?: boolean
  }
}
```

### Data Display Components

```typescript
// Data Table
{
  type: 'data-table',
  props: {
    title?: string,
    columns: Array<{
      key: string,
      label: string,
      sortable?: boolean,
      format?: 'text' | 'number' | 'currency' | 'date',
      render?: string, // custom render function name
      width?: number
    }>,
    pageSize?: number,
    searchable?: boolean,
    filterable?: boolean
  },
  bindings: {
    data: string, // binding expression
    loading?: string,
    error?: string
  }
}

// Chart
{
  type: 'chart',
  props: {
    chartType: 'line' | 'bar' | 'pie' | 'doughnut' | 'area',
    title?: string,
    height?: number,
    showLegend?: boolean,
    showGrid?: boolean
  },
  bindings: {
    data: string,
    labels: string
  }
}

// Stat Card
{
  type: 'stat-card',
  props: {
    title: string,
    icon?: string, // Lucide icon name
    color?: 'blue' | 'green' | 'red' | 'yellow' | 'purple',
    format?: 'number' | 'currency' | 'percentage'
  },
  bindings: {
    value: string,
    change?: string // percentage change
  }
}

// Card
{
  type: 'card',
  props: {
    title?: string,
    subtitle?: string,
    padding?: number,
    hover?: boolean,
    clickable?: boolean
  }
}
```

### Form Components

```typescript
// Form
{
  type: 'form',
  props: {
    title?: string,
    submitLabel?: string,
    cancelLabel?: string,
    layout?: 'vertical' | 'horizontal',
    validationSchema?: object // JSON schema
  },
  actions: {
    onSubmit: {
      type: 'api-call',
      endpoint: string,
      method: 'POST',
      successMessage?: string,
      errorMessage?: string
    }
  }
}

// Input
{
  type: 'input',
  props: {
    name: string,
    label: string,
    placeholder?: string,
    type?: 'text' | 'email' | 'password' | 'number' | 'tel',
    required?: boolean,
    disabled?: boolean,
    helperText?: string
  }
}

// Select
{
  type: 'select',
  props: {
    name: string,
    label: string,
    placeholder?: string,
    required?: boolean,
    multiple?: boolean
  },
  bindings: {
    options: string // array of {value, label}
  }
}

// Button
{
  type: 'button',
  props: {
    label: string,
    variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger',
    size?: 'sm' | 'md' | 'lg',
    icon?: string,
    iconPosition?: 'left' | 'right',
    fullWidth?: boolean,
    loading?: boolean,
    disabled?: boolean
  },
  actions: {
    onClick: {
      type: 'navigate' | 'api-call' | 'custom-action',
      // action-specific config
    }
  }
}
```

### Typography Components

```typescript
// Heading
{
  type: 'heading',
  props: {
    level: 1 | 2 | 3 | 4 | 5 | 6,
    text: string,
    className?: string
  }
}

// Text
{
  type: 'text',
  props: {
    content: string,
    variant?: 'body' | 'caption' | 'overline',
    weight?: 'normal' | 'medium' | 'semibold' | 'bold',
    color?: string,
    className?: string
  }
}
```

### Navigation Components

```typescript
// Breadcrumbs
{
  type: 'breadcrumbs',
  bindings: {
    items: string // [{label, href}]
  }
}

// Tabs
{
  type: 'tabs',
  props: {
    defaultTab?: string
  },
  children: Array<{
    type: 'tab',
    props: {
      id: string,
      label: string,
      icon?: string
    },
    children: [...] // tab content
  }>
}
```

---

## 🔄 Data Binding System

### Binding Expressions

```javascript
// Simple property binding
"{{api.users.data}}"

// Nested property
"{{api.stats.users.total}}"

// Array access
"{{api.users.data[0].name}}"

// Computed expressions
"{{api.stats.revenue * 1.2}}"

// Conditional
"{{api.stats.change > 0 ? 'Increase' : 'Decrease'}}"

// Template literals
"{{`${api.user.firstName} ${api.user.lastName}`}}"
```

### API Bindings

```json
{
  "bindings": {
    "api": {
      "users": {
        "endpoint": "/api/users",
        "method": "GET",
        "params": {
          "page": 1,
          "limit": 20
        },
        "refresh": 60000, // Auto-refresh every 60s
        "cache": true,
        "onSuccess": {
          "type": "set-variable",
          "variable": "userCount",
          "value": "{{response.data.length}}"
        }
      }
    },
    "variables": {
      "userCount": 0,
      "selectedUser": null
    }
  }
}
```

### State Management

```json
{
  "state": {
    "filters": {
      "status": "active",
      "search": ""
    },
    "selectedItems": [],
    "isLoading": false
  },
  "actions": {
    "updateFilter": {
      "type": "set-state",
      "path": "filters.{{key}}",
      "value": "{{value}}"
    },
    "toggleSelection": {
      "type": "toggle-in-array",
      "path": "selectedItems",
      "value": "{{item.id}}"
    }
  }
}
```

---

## 🎬 Actions System

### Action Types

```typescript
// Navigate
{
  type: 'navigate',
  url: '/orders/{{item.id}}'
}

// API Call
{
  type: 'api-call',
  endpoint: '/api/users/{{userId}}',
  method: 'POST',
  body: {
    name: '{{form.name}}',
    email: '{{form.email}}'
  },
  onSuccess: {
    type: 'show-notification',
    message: 'User updated successfully'
  },
  onError: {
    type: 'show-notification',
    message: 'Failed to update user',
    variant: 'error'
  }
}

// Set State
{
  type: 'set-state',
  path: 'selectedUser',
  value: '{{user}}'
}

// Refresh Bindings
{
  type: 'refresh-bindings',
  targets: ['api.users', 'api.stats']
}

// Show Notification
{
  type: 'show-notification',
  message: 'Operation completed',
  variant: 'success', // success | error | warning | info
  duration: 5000
}

// Open Modal
{
  type: 'open-modal',
  modalId: 'edit-user-modal',
  props: {
    user: '{{selectedUser}}'
  }
}

// Close Modal
{
  type: 'close-modal',
  modalId: 'edit-user-modal'
}

// Custom Action (execute custom endpoint)
{
  type: 'custom-action',
  endpointKey: 'my-custom-endpoint',
  params: {
    userId: '{{user.id}}'
  }
}
```

---

## 🎨 Frontend Renderer Implementation

### React JSON Renderer Component

```typescript
// src/components/JSONRenderer.tsx
import React, { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getPageConfig } from '@/api/page-builder';
import { ComponentRegistry } from '@/lib/component-registry';
import { BindingContext } from '@/lib/binding-context';

interface JSONRendererProps {
  pageKey: string;
  tenantId: number;
}

export const JSONRenderer: React.FC<JSONRendererProps> = ({ pageKey, tenantId }) => {
  // Fetch page configuration
  const { data: pageConfig, isLoading, error } = useQuery({
    queryKey: ['page', pageKey, tenantId],
    queryFn: () => getPageConfig(pageKey),
  });

  // Initialize binding context
  const bindingContext = useMemo(() => {
    if (!pageConfig) return null;
    return new BindingContext(pageConfig.bindings);
  }, [pageConfig]);

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (error || !pageConfig) {
    return <div>Error loading page</div>;
  }

  return (
    <BindingContext.Provider value={bindingContext}>
      <RenderComponent config={pageConfig.layout} />
    </BindingContext.Provider>
  );
};

// Recursive component renderer
const RenderComponent: React.FC<{ config: any }> = ({ config }) => {
  const Component = ComponentRegistry.get(config.type);

  if (!Component) {
    console.warn(`Component type "${config.type}" not found`);
    return null;
  }

  // Resolve bindings for props
  const resolvedProps = useResolveBindings(config.props, config.bindings);

  // Render children recursively
  const children = config.children?.map((child: any, index: number) => (
    <RenderComponent key={child.id || index} config={child} />
  ));

  return <Component {...resolvedProps}>{children}</Component>;
};
```

### Component Registry

```typescript
// src/lib/component-registry.ts
import { Container, Grid, Flex, Stack } from '@/components/layout';
import { DataTable, Chart, StatCard, Card } from '@/components/data-display';
import { Form, Input, Select, Button } from '@/components/forms';
import { Heading, Text } from '@/components/typography';

export const ComponentRegistry = new Map([
  // Layout
  ['container', Container],
  ['grid', Grid],
  ['flex', Flex],
  ['stack', Stack],

  // Data Display
  ['data-table', DataTable],
  ['chart', Chart],
  ['stat-card', StatCard],
  ['card', Card],

  // Forms
  ['form', Form],
  ['input', Input],
  ['select', Select],
  ['button', Button],

  // Typography
  ['heading', Heading],
  ['text', Text],
]);

// Register custom component
ComponentRegistry.set('my-custom-widget', MyCustomWidget);
```

### Binding Resolution

```typescript
// src/hooks/useResolveBindings.ts
import { useContext, useMemo } from 'react';
import { BindingContext } from '@/lib/binding-context';

export const useResolveBindings = (props: any, bindings?: any) => {
  const context = useContext(BindingContext);

  return useMemo(() => {
    if (!bindings || !context) {
      return props;
    }

    const resolved = { ...props };

    Object.entries(bindings).forEach(([key, expression]) => {
      resolved[key] = context.resolve(expression as string);
    });

    return resolved;
  }, [props, bindings, context]);
};
```

---

## 🔐 Security Considerations

1. **Input Validation**: All JSON schemas validated before storage
2. **XSS Prevention**: Sanitize user-generated content
3. **RBAC**: Check permissions before rendering/executing
4. **Rate Limiting**: Limit custom endpoint executions
5. **Sandbox Execution**: Custom logic runs in isolated environment
6. **Audit Trail**: Log all page edits and endpoint executions

---

## 📋 Deployment Checklist

- [ ] Database migrations executed
- [ ] Component registry populated
- [ ] Default theme created
- [ ] Page editor deployed and accessible
- [ ] JSON renderer tested with all component types
- [ ] Custom endpoints execution sandboxed
- [ ] Rate limiting configured
- [ ] Audit logging enabled
- [ ] Documentation published
- [ ] Training materials created

---

**Questo sistema è la base per l'editabilità completa della piattaforma.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team & Frontend Team
