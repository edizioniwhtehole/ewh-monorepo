# 🎛️ Admin Panels API-First Specification
## Architettura Completa per Pannelli di Amministrazione

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Executive Summary

Questo documento definisce l'architettura **API-first** per tutti i pannelli di amministrazione della piattaforma EWH, organizzati in tre livelli gerarchici:

1. **OWNER / PLATFORM_ADMIN** - Configurazione globale della piattaforma
2. **TENANT_ADMIN** - Configurazione organizzazione/tenant
3. **USER** - Impostazioni personali dell'utente

### Principi Architetturali

- ✅ **API First**: Ogni funzionalità è esposta via API REST
- ✅ **Role-Based Access Control**: Permessi a cascata (Owner → Tenant → User)
- ✅ **Settings Waterfall**: Configurazioni si propagano dal livello superiore
- ✅ **Frontend Agnostic**: API utilizzabile da qualsiasi frontend
- ✅ **Audit Trail**: Ogni modifica è tracciata e loggata
- ✅ **Validation Consistent**: Schema validation uniforme

---

## 🏗️ Architettura Generale

### Settings Waterfall Model

```
┌─────────────────────────────────────────┐
│         OWNER / PLATFORM_ADMIN          │
│  ┌───────────────────────────────────┐  │
│  │   Platform Global Configuration   │  │
│  │   - Services enabled/disabled     │  │
│  │   - Global limits & quotas        │  │
│  │   - Security policies             │  │
│  │   - Payment gateways              │  │
│  └───────────────┬───────────────────┘  │
└──────────────────┼──────────────────────┘
                   │ cascades to
                   ▼
┌─────────────────────────────────────────┐
│            TENANT_ADMIN                 │
│  ┌───────────────────────────────────┐  │
│  │   Organization Configuration      │  │
│  │   - Enabled features (subset)     │  │
│  │   - Users & permissions           │  │
│  │   - Branding & customization      │  │
│  │   - Billing & subscription        │  │
│  └───────────────┬───────────────────┘  │
└──────────────────┼──────────────────────┘
                   │ cascades to
                   ▼
┌─────────────────────────────────────────┐
│               USER                      │
│  ┌───────────────────────────────────┐  │
│  │   Personal Preferences            │  │
│  │   - Profile settings              │  │
│  │   - Notifications                 │  │
│  │   - Integrations                  │  │
│  │   - Language & timezone           │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Service Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   app-settings-frontend                  │
│              (React + TanStack Query + Zustand)          │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  svc-settings (Express)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Platform    │  │   Tenant     │  │    User      │  │
│  │  Settings    │  │  Settings    │  │  Settings    │  │
│  │  Controller  │  │  Controller  │  │  Controller  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│         └─────────────────┴─────────────────┘           │
│                         │                                │
│                 ┌───────▼────────┐                       │
│                 │  Authorization │                       │
│                 │   Middleware   │                       │
│                 └───────┬────────┘                       │
└─────────────────────────┼──────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────┐
│              PostgreSQL (ewh_master)                     │
│  ┌──────────────────┐  ┌──────────────────┐            │
│  │ platform_settings│  │ tenant_settings  │            │
│  │ settings_audit   │  │ user_settings    │            │
│  └──────────────────┘  └──────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Database Architecture

### 🔴 MANDATORIO: Separazione Database Core e User-Generated

La piattaforma EWH **DEVE** utilizzare due database separati:

1. **`ewh_master`** - Database Core (gestione piattaforma)
2. **`ewh_tenant`** - Database User-Generated (contenuti creati dagli utenti)

```
┌─────────────────────────────────────────────────────────────┐
│                      ewh_master                              │
│                   (Core Platform DB)                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  • users, tenants, roles                              │  │
│  │  • platform_settings, tenant_settings                 │  │
│  │  • service_registry, tenant_services                  │  │
│  │  • audit_logs, sessions                               │  │
│  │  • billing, subscriptions                             │  │
│  │                                                        │  │
│  │  Accesso: svc-auth, svc-settings, admin services     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      ewh_tenant                              │
│                (User-Generated Content DB)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  • pages, templates, components                       │  │
│  │  • custom_blocks, widgets                             │  │
│  │  • projects, tasks, boards                            │  │
│  │  • products, inventory, orders                        │  │
│  │  • media_assets, files                                │  │
│  │  • custom_tables (user-created via DB editor)         │  │
│  │                                                        │  │
│  │  Accesso: tutti i business services                   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Perché Due Database Separati?

1. **Sicurezza**: Le tabelle core non possono essere modificate da utenti tenant
2. **Backup**: Backup strategy differenziata (core = critico, tenant = frequente)
3. **Scaling**: I database possono scalare indipendentemente
4. **Multi-tenancy**: Isolamento dati tenant in futuro (un DB per tenant)
5. **Migrazione**: Facile spostare contenuti tenant senza toccare il core

---

## 📊 Database Schema - ewh_master (Core)

### Platform Settings

```sql
-- Platform-wide configuration (OWNER/PLATFORM_ADMIN only)
CREATE TABLE platform_settings (
  id SERIAL PRIMARY KEY,
  setting_key VARCHAR(255) NOT NULL UNIQUE,
  setting_value JSONB NOT NULL,
  category VARCHAR(100) NOT NULL, -- 'general', 'security', 'services', 'billing'
  description TEXT,
  schema JSONB, -- JSON schema for validation
  is_public BOOLEAN DEFAULT false, -- If true, visible to all tenants
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id),
  updated_by INTEGER REFERENCES users(id)
);

-- Tenant-specific configuration
CREATE TABLE tenant_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  category VARCHAR(100) NOT NULL,
  inherits_from_platform BOOLEAN DEFAULT true,
  overridden_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id),
  updated_by INTEGER REFERENCES users(id),
  UNIQUE(tenant_id, setting_key)
);

-- User-specific preferences
CREATE TABLE user_settings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  category VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, setting_key)
);

-- Audit trail for all settings changes
CREATE TABLE settings_audit (
  id SERIAL PRIMARY KEY,
  table_name VARCHAR(50) NOT NULL, -- 'platform_settings', 'tenant_settings', 'user_settings'
  record_id INTEGER NOT NULL,
  action VARCHAR(20) NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
  old_value JSONB,
  new_value JSONB,
  changed_by INTEGER REFERENCES users(id),
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT
);

-- Create indexes
CREATE INDEX idx_platform_settings_category ON platform_settings(category);
CREATE INDEX idx_platform_settings_key ON platform_settings(setting_key);
CREATE INDEX idx_tenant_settings_tenant ON tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_key ON tenant_settings(setting_key);
CREATE INDEX idx_user_settings_user ON user_settings(user_id);
CREATE INDEX idx_settings_audit_record ON settings_audit(table_name, record_id);
CREATE INDEX idx_settings_audit_changed_at ON settings_audit(changed_at);
```

### Service Registry

```sql
-- Registry of all available services in the platform
CREATE TABLE service_registry (
  id SERIAL PRIMARY KEY,
  service_id VARCHAR(100) NOT NULL UNIQUE, -- 'svc-pm', 'svc-inventory', etc.
  service_name VARCHAR(255) NOT NULL,
  service_type VARCHAR(50) NOT NULL, -- 'backend', 'frontend'
  category VARCHAR(100), -- 'business', 'communications', etc.
  description TEXT,
  port INTEGER,
  health_check_url VARCHAR(500),
  documentation_url VARCHAR(500),
  is_core BOOLEAN DEFAULT false, -- Core services can't be disabled
  default_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tenant-level service enablement
CREATE TABLE tenant_services (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  service_id INTEGER NOT NULL REFERENCES service_registry(id),
  is_enabled BOOLEAN DEFAULT true,
  configuration JSONB, -- Service-specific config
  enabled_at TIMESTAMPTZ,
  enabled_by INTEGER REFERENCES users(id),
  disabled_at TIMESTAMPTZ,
  disabled_by INTEGER REFERENCES users(id),
  UNIQUE(tenant_id, service_id)
);

-- User-level service preferences
CREATE TABLE user_service_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_id INTEGER NOT NULL REFERENCES service_registry(id),
  is_pinned BOOLEAN DEFAULT false,
  custom_label VARCHAR(255),
  sort_order INTEGER,
  UNIQUE(user_id, service_id)
);
```

### Connection String Configuration

```bash
# .env per servizi CORE (auth, settings, billing)
DATABASE_URL=postgresql://user:password@localhost:5432/ewh_master

# .env per servizi BUSINESS (pm, inventory, cms, etc.)
DATABASE_URL=postgresql://user:password@localhost:5432/ewh_tenant
```

---

## 📊 Database Schema - ewh_tenant (User-Generated)

### Pages & Templates

```sql
-- Pages (actual instances created by users)
CREATE TABLE pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL, -- References ewh_master.tenants(id)
  page_key VARCHAR(255) NOT NULL,
  page_title VARCHAR(500) NOT NULL,
  layout_config JSONB NOT NULL, -- JSON rendering configuration
  template_id UUID REFERENCES templates(id),
  status VARCHAR(50) DEFAULT 'draft', -- draft, published, archived
  version INTEGER DEFAULT 1,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL, -- References ewh_master.users(id)
  updated_by INTEGER,
  UNIQUE(tenant_id, page_key, version)
);

-- Templates (reusable page templates)
CREATE TABLE templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER, -- NULL = system template, NOT NULL = tenant template
  template_key VARCHAR(255) NOT NULL,
  template_name VARCHAR(500) NOT NULL,
  description TEXT,
  layout_config JSONB NOT NULL,
  thumbnail_url VARCHAR(1000),
  category VARCHAR(100),
  visibility VARCHAR(50) DEFAULT 'private', -- private, tenant, public
  is_system BOOLEAN DEFAULT false,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER,
  UNIQUE(tenant_id, template_key)
);

-- Components Library
CREATE TABLE components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER,
  component_key VARCHAR(255) NOT NULL,
  component_name VARCHAR(500) NOT NULL,
  description TEXT,
  config_schema JSONB NOT NULL, -- JSON schema for props
  default_props JSONB NOT NULL,
  render_config JSONB NOT NULL,
  category VARCHAR(100),
  visibility VARCHAR(50) DEFAULT 'tenant',
  version INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER,
  UNIQUE(tenant_id, component_key, version)
);

-- Custom Blocks (GrapesJS components)
CREATE TABLE custom_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  block_key VARCHAR(255) NOT NULL,
  block_label VARCHAR(500) NOT NULL,
  block_content TEXT NOT NULL, -- HTML/JSX
  block_styles TEXT, -- CSS
  block_category VARCHAR(100),
  thumbnail_url VARCHAR(1000),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  UNIQUE(tenant_id, block_key)
);

-- Widgets Registry (tenant-level)
CREATE TABLE widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  widget_key VARCHAR(255) NOT NULL,
  widget_name VARCHAR(500) NOT NULL,
  widget_type VARCHAR(100) NOT NULL,
  config JSONB NOT NULL,
  permissions JSONB, -- Who can use this widget
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  UNIQUE(tenant_id, widget_key)
);
```

### Business Data (Projects, Tasks, Inventory, etc.)

```sql
-- Projects (from svc-pm)
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  project_key VARCHAR(100) NOT NULL,
  project_name VARCHAR(500) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  start_date DATE,
  due_date DATE,
  budget DECIMAL(12,2),
  owner_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, project_key)
);

-- Tasks (from svc-pm)
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  task_name VARCHAR(500) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'todo',
  priority VARCHAR(50) DEFAULT 'medium',
  assigned_to INTEGER,
  due_date DATE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL
);

-- Products (from svc-products)
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  product_sku VARCHAR(100) NOT NULL,
  product_name VARCHAR(500) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  stock_quantity INTEGER DEFAULT 0,
  category VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  UNIQUE(tenant_id, product_sku)
);

-- Media Assets (from svc-media)
CREATE TABLE media_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  file_name VARCHAR(500) NOT NULL,
  file_path VARCHAR(1000) NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  asset_type VARCHAR(50) NOT NULL, -- image, video, document, etc.
  width INTEGER,
  height INTEGER,
  duration INTEGER, -- for videos
  metadata JSONB,
  folder_id UUID REFERENCES media_folders(id),
  uploaded_by INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Custom Tables (User-Created via DB Editor)

```sql
-- Registry of custom tables created by users
CREATE TABLE custom_tables_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  table_name VARCHAR(100) NOT NULL, -- actual PostgreSQL table name
  display_name VARCHAR(500) NOT NULL,
  description TEXT,
  schema_config JSONB NOT NULL, -- Column definitions
  permissions JSONB, -- Who can access
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  UNIQUE(tenant_id, table_name)
);

-- Example: User creates "custom_contacts" table via DB editor
-- The system automatically creates this table structure:
CREATE TABLE custom_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  -- User-defined columns added dynamically
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL
);
```

### Indexes for Performance

```sql
-- ewh_tenant indexes
CREATE INDEX idx_pages_tenant ON pages(tenant_id);
CREATE INDEX idx_pages_status ON pages(status);
CREATE INDEX idx_templates_tenant ON templates(tenant_id);
CREATE INDEX idx_templates_visibility ON templates(visibility);
CREATE INDEX idx_components_tenant ON components(tenant_id);
CREATE INDEX idx_projects_tenant ON projects(tenant_id);
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assigned ON tasks(assigned_to);
CREATE INDEX idx_products_tenant ON products(tenant_id);
CREATE INDEX idx_products_sku ON products(product_sku);
CREATE INDEX idx_media_tenant ON media_assets(tenant_id);
CREATE INDEX idx_media_folder ON media_assets(folder_id);
```

---

## 🔌 API Endpoints Specification

### Base URL Structure

```
/api/settings/*           - Settings Management
/api/admin/platform/*     - Platform Admin (OWNER only)
/api/admin/tenant/*       - Tenant Admin
/api/user/*              - User Settings
```

---

## 🔐 1. PLATFORM ADMIN APIs (OWNER / PLATFORM_ADMIN)

### 1.1 Platform Settings

#### Get All Platform Settings
```http
GET /api/admin/platform/settings
Authorization: Bearer {token}
X-User-Role: OWNER | PLATFORM_ADMIN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "settings": [
      {
        "id": 1,
        "key": "platform.security.mfa_required",
        "value": true,
        "category": "security",
        "description": "Require MFA for all users",
        "isPublic": false,
        "updatedAt": "2025-10-15T10:30:00Z",
        "updatedBy": {
          "id": 1,
          "name": "Admin User"
        }
      }
    ],
    "categories": ["general", "security", "services", "billing"]
  }
}
```

#### Get Setting by Key
```http
GET /api/admin/platform/settings/:key
Authorization: Bearer {token}
```

**Example:** `GET /api/admin/platform/settings/platform.security.mfa_required`

**Response:**
```json
{
  "success": true,
  "data": {
    "key": "platform.security.mfa_required",
    "value": true,
    "category": "security",
    "description": "Require MFA for all users",
    "schema": {
      "type": "boolean"
    },
    "isPublic": false,
    "history": [
      {
        "changedAt": "2025-10-15T10:30:00Z",
        "changedBy": "Admin User",
        "oldValue": false,
        "newValue": true
      }
    ]
  }
}
```

#### Create/Update Platform Setting
```http
PUT /api/admin/platform/settings/:key
Authorization: Bearer {token}
Content-Type: application/json

{
  "value": true,
  "category": "security",
  "description": "Require MFA for all users",
  "isPublic": false
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "key": "platform.security.mfa_required",
    "value": true,
    "updatedAt": "2025-10-15T10:30:00Z"
  }
}
```

#### Delete Platform Setting
```http
DELETE /api/admin/platform/settings/:key
Authorization: Bearer {token}
```

---

### 1.2 Service Registry Management

#### Get All Services
```http
GET /api/admin/platform/services
Authorization: Bearer {token}
```

**Query Params:**
- `type` - Filter by type (backend, frontend)
- `category` - Filter by category
- `enabled` - Filter by default_enabled status

**Response:**
```json
{
  "success": true,
  "data": {
    "services": [
      {
        "id": 1,
        "serviceId": "svc-pm",
        "name": "Project Management",
        "type": "backend",
        "category": "business",
        "description": "Project management and kanban boards",
        "port": 5500,
        "healthCheckUrl": "http://localhost:5500/health",
        "documentationUrl": "/docs/services/pm",
        "isCore": false,
        "defaultEnabled": true,
        "status": "healthy"
      }
    ],
    "stats": {
      "total": 69,
      "backend": 45,
      "frontend": 24,
      "healthy": 62,
      "unhealthy": 7
    }
  }
}
```

#### Register New Service
```http
POST /api/admin/platform/services
Authorization: Bearer {token}
Content-Type: application/json

{
  "serviceId": "svc-new-service",
  "name": "New Service",
  "type": "backend",
  "category": "business",
  "description": "Description of the service",
  "port": 6500,
  "healthCheckUrl": "http://localhost:6500/health",
  "isCore": false,
  "defaultEnabled": true
}
```

#### Update Service
```http
PUT /api/admin/platform/services/:serviceId
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Updated Name",
  "description": "Updated description",
  "defaultEnabled": false
}
```

#### Delete Service
```http
DELETE /api/admin/platform/services/:serviceId
Authorization: Bearer {token}
```

**Note:** Cannot delete core services or services in use by tenants

---

### 1.3 Global Tenants Management

#### Get All Tenants
```http
GET /api/admin/platform/tenants
Authorization: Bearer {token}
```

**Query Params:**
- `status` - active, suspended, deleted
- `plan` - free, starter, professional, enterprise
- `page`, `limit` - Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "tenants": [
      {
        "id": 1,
        "name": "Acme Corp",
        "slug": "acme",
        "status": "active",
        "plan": "enterprise",
        "userCount": 45,
        "servicesEnabled": 32,
        "storageUsed": "45.2 GB",
        "createdAt": "2025-01-15T00:00:00Z",
        "subscription": {
          "status": "active",
          "currentPeriodEnd": "2025-11-15T00:00:00Z",
          "amount": 999,
          "currency": "USD"
        }
      }
    ],
    "pagination": {
      "total": 156,
      "page": 1,
      "limit": 20,
      "pages": 8
    }
  }
}
```

#### Get Tenant Details
```http
GET /api/admin/platform/tenants/:tenantId
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Acme Corp",
    "slug": "acme",
    "status": "active",
    "plan": "enterprise",
    "users": 45,
    "admins": 3,
    "services": {
      "enabled": 32,
      "available": 69
    },
    "storage": {
      "used": 45.2,
      "limit": 1000,
      "unit": "GB"
    },
    "billing": {
      "email": "billing@acme.com",
      "paymentMethod": "card ending in 4242",
      "nextBillingDate": "2025-11-15"
    },
    "settings": {
      "customDomain": "app.acme.com",
      "ssoEnabled": true,
      "mfaRequired": true
    },
    "activity": {
      "lastLoginAt": "2025-10-15T09:45:00Z",
      "activeUsersToday": 32
    }
  }
}
```

#### Create Tenant
```http
POST /api/admin/platform/tenants
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "New Company",
  "slug": "new-company",
  "plan": "professional",
  "adminEmail": "admin@newcompany.com",
  "adminName": "Admin User"
}
```

#### Update Tenant
```http
PUT /api/admin/platform/tenants/:tenantId
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "suspended",
  "plan": "enterprise"
}
```

#### Suspend Tenant
```http
POST /api/admin/platform/tenants/:tenantId/suspend
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Payment failed",
  "notifyUsers": true
}
```

#### Delete Tenant
```http
DELETE /api/admin/platform/tenants/:tenantId
Authorization: Bearer {token}
```

---

### 1.4 Visual Database Editor

**🗄️ NUOVO SERVIZIO**: Editor DB visuale stile Xano/NocoDB

Il Visual Database Editor è integrato nella sezione Owner/Platform Admin e permette di:

- Creare tabelle custom con interfaccia drag-and-drop
- Definire relazioni tra tabelle visivamente
- Gestire dati con interfaccia spreadsheet
- Generare API automaticamente per ogni tabella

**Vedi specifica completa**: [VISUAL_DATABASE_EDITOR_SPECIFICATION.md](./VISUAL_DATABASE_EDITOR_SPECIFICATION.md)

#### List Custom Tables
```http
GET /api/db-editor/tables
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tables": [
      {
        "tableName": "custom_contacts",
        "displayName": "Contacts",
        "description": "Customer contact information",
        "icon": "👤",
        "color": "#3B82F6",
        "columnCount": 5,
        "rowCount": 234,
        "apiEnabled": true,
        "apiPrefix": "/api/custom/contacts",
        "createdAt": "2025-10-01T10:00:00Z",
        "createdBy": "Admin User"
      }
    ]
  }
}
```

#### Create Custom Table
```http
POST /api/db-editor/tables
Authorization: Bearer {token}
Content-Type: application/json

{
  "displayName": "Contacts",
  "description": "Customer contact information",
  "icon": "👤",
  "color": "#3B82F6",
  "columns": [
    {
      "name": "email",
      "displayName": "Email Address",
      "type": "text",
      "nullable": false,
      "unique": true,
      "validation": {
        "pattern": "^[^@]+@[^@]+\\.[^@]+$"
      }
    },
    {
      "name": "name",
      "displayName": "Full Name",
      "type": "text",
      "nullable": false
    },
    {
      "name": "company_id",
      "displayName": "Company",
      "type": "relation",
      "relatedTable": "custom_companies"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tableName": "custom_contacts",
    "displayName": "Contacts",
    "apiEndpoints": {
      "list": "GET /api/custom/contacts",
      "get": "GET /api/custom/contacts/:id",
      "create": "POST /api/custom/contacts",
      "update": "PUT /api/custom/contacts/:id",
      "delete": "DELETE /api/custom/contacts/:id"
    },
    "message": "Table created successfully and API endpoints auto-generated"
  }
}
```

#### Get Table Data
```http
GET /api/db-editor/data/:tableName?page=1&limit=50&sort=created_at&order=DESC
Authorization: Bearer {token}
```

#### Execute Custom Query
```http
POST /api/db-editor/query
Authorization: Bearer {token}
Content-Type: application/json

{
  "table": "custom_contacts",
  "select": ["email", "name", "created_at"],
  "where": [
    { "field": "status", "operator": "=", "value": "active" }
  ],
  "orderBy": [
    { "field": "created_at", "direction": "DESC" }
  ],
  "limit": 100
}
```

---

### 1.5 Platform Analytics

#### Get Platform Stats
```http
GET /api/admin/platform/analytics/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tenants": {
      "total": 156,
      "active": 148,
      "suspended": 6,
      "trial": 23
    },
    "users": {
      "total": 4521,
      "active": 3890,
      "activeLast7Days": 2345
    },
    "services": {
      "total": 69,
      "healthy": 62,
      "degraded": 5,
      "down": 2
    },
    "revenue": {
      "mrr": 125000,
      "arr": 1500000,
      "growth": 12.5
    },
    "storage": {
      "total": "2.4 TB",
      "average": "15.4 GB"
    }
  }
}
```

#### Get Usage Metrics
```http
GET /api/admin/platform/analytics/usage
Authorization: Bearer {token}
```

**Query Params:**
- `period` - day, week, month, year
- `metric` - users, requests, storage, revenue

---

## 👥 2. TENANT ADMIN APIs

### 2.1 Tenant Settings

#### Get Tenant Settings
```http
GET /api/admin/tenant/settings
Authorization: Bearer {token}
X-User-Role: TENANT_ADMIN
X-Tenant-ID: {tenantId}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "settings": [
      {
        "key": "tenant.branding.logo",
        "value": "https://cdn.example.com/logo.png",
        "category": "branding",
        "inheritsFromPlatform": false,
        "overriddenAt": "2025-10-10T14:20:00Z"
      },
      {
        "key": "tenant.security.mfa_required",
        "value": true,
        "category": "security",
        "inheritsFromPlatform": true,
        "platformValue": true
      }
    ]
  }
}
```

#### Update Tenant Setting
```http
PUT /api/admin/tenant/settings/:key
Authorization: Bearer {token}
Content-Type: application/json

{
  "value": "https://cdn.example.com/new-logo.png",
  "overridePlatform": true
}
```

---

### 2.2 Users & Permissions Management

#### Get Tenant Users
```http
GET /api/admin/tenant/users
Authorization: Bearer {token}
```

**Query Params:**
- `role` - Filter by role
- `status` - active, inactive, invited
- `search` - Search by name/email
- `page`, `limit` - Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 123,
        "email": "john@acme.com",
        "name": "John Doe",
        "role": "USER",
        "status": "active",
        "lastLogin": "2025-10-15T09:30:00Z",
        "servicesAccess": 25,
        "createdAt": "2025-05-10T00:00:00Z"
      }
    ],
    "pagination": {
      "total": 45,
      "page": 1,
      "limit": 20
    }
  }
}
```

#### Invite User
```http
POST /api/admin/tenant/users/invite
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": "newuser@acme.com",
  "name": "New User",
  "role": "USER",
  "services": ["svc-pm", "svc-inventory", "app-dam"]
}
```

#### Update User Role
```http
PUT /api/admin/tenant/users/:userId/role
Authorization: Bearer {token}
Content-Type: application/json

{
  "role": "TENANT_ADMIN"
}
```

#### Revoke User Access
```http
DELETE /api/admin/tenant/users/:userId
Authorization: Bearer {token}
```

---

### 2.3 Tenant Services Management

#### Get Enabled Services
```http
GET /api/admin/tenant/services
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "services": [
      {
        "id": 1,
        "serviceId": "svc-pm",
        "name": "Project Management",
        "category": "business",
        "isEnabled": true,
        "enabledAt": "2025-05-15T10:00:00Z",
        "enabledBy": "Admin User",
        "userCount": 32,
        "configuration": {
          "maxProjects": 100,
          "features": ["kanban", "gantt", "calendar"]
        }
      }
    ],
    "available": 69,
    "enabled": 32,
    "disabled": 37
  }
}
```

#### Enable Service
```http
POST /api/admin/tenant/services/:serviceId/enable
Authorization: Bearer {token}
Content-Type: application/json

{
  "configuration": {
    "maxProjects": 100
  }
}
```

#### Disable Service
```http
POST /api/admin/tenant/services/:serviceId/disable
Authorization: Bearer {token}
```

**Note:** Cannot disable services currently in use

#### Update Service Configuration
```http
PUT /api/admin/tenant/services/:serviceId/configuration
Authorization: Bearer {token}
Content-Type: application/json

{
  "maxProjects": 200,
  "features": ["kanban", "gantt", "calendar", "timeline"]
}
```

---

### 2.4 Billing & Subscription

#### Get Subscription Details
```http
GET /api/admin/tenant/billing/subscription
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "plan": {
      "name": "Enterprise",
      "price": 999,
      "currency": "USD",
      "interval": "month"
    },
    "status": "active",
    "currentPeriod": {
      "start": "2025-10-15T00:00:00Z",
      "end": "2025-11-15T00:00:00Z"
    },
    "usage": {
      "users": {
        "current": 45,
        "limit": 100
      },
      "storage": {
        "current": 45.2,
        "limit": 1000,
        "unit": "GB"
      },
      "services": {
        "current": 32,
        "limit": -1
      }
    },
    "nextInvoice": {
      "date": "2025-11-15T00:00:00Z",
      "amount": 999,
      "items": [
        {
          "description": "Enterprise Plan",
          "amount": 999
        }
      ]
    }
  }
}
```

#### Get Invoices
```http
GET /api/admin/tenant/billing/invoices
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "invoices": [
      {
        "id": "inv_123",
        "date": "2025-09-15T00:00:00Z",
        "amount": 999,
        "status": "paid",
        "pdfUrl": "https://cdn.example.com/invoices/inv_123.pdf"
      }
    ]
  }
}
```

#### Update Payment Method
```http
POST /api/admin/tenant/billing/payment-method
Authorization: Bearer {token}
Content-Type: application/json

{
  "token": "tok_visa_4242"
}
```

#### Change Plan
```http
POST /api/admin/tenant/billing/change-plan
Authorization: Bearer {token}
Content-Type: application/json

{
  "plan": "professional",
  "interval": "yearly"
}
```

---

### 2.5 Security & Audit

#### Get Audit Logs
```http
GET /api/admin/tenant/security/audit
Authorization: Bearer {token}
```

**Query Params:**
- `action` - Filter by action type
- `user` - Filter by user ID
- `startDate`, `endDate` - Date range
- `page`, `limit` - Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "logs": [
      {
        "id": 1234,
        "action": "USER_INVITED",
        "user": "Admin User",
        "target": "newuser@acme.com",
        "details": {
          "role": "USER"
        },
        "ipAddress": "192.168.1.100",
        "userAgent": "Mozilla/5.0...",
        "timestamp": "2025-10-15T10:30:00Z"
      }
    ],
    "pagination": {
      "total": 4521,
      "page": 1,
      "limit": 50
    }
  }
}
```

#### Get Active Sessions
```http
GET /api/admin/tenant/security/sessions
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": "sess_abc123",
        "user": "John Doe",
        "ipAddress": "192.168.1.100",
        "userAgent": "Chrome 118.0",
        "lastActivity": "2025-10-15T10:45:00Z",
        "createdAt": "2025-10-15T09:00:00Z"
      }
    ]
  }
}
```

#### Revoke Session
```http
DELETE /api/admin/tenant/security/sessions/:sessionId
Authorization: Bearer {token}
```

---

## 👤 3. USER APIs

### 3.1 User Profile

#### Get User Profile
```http
GET /api/user/profile
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "email": "john@acme.com",
    "name": "John Doe",
    "avatar": "https://cdn.example.com/avatars/123.jpg",
    "role": "USER",
    "tenant": {
      "id": 1,
      "name": "Acme Corp",
      "plan": "enterprise"
    },
    "preferences": {
      "language": "en",
      "timezone": "America/New_York",
      "theme": "dark"
    },
    "createdAt": "2025-05-10T00:00:00Z",
    "lastLogin": "2025-10-15T09:30:00Z"
  }
}
```

#### Update Profile
```http
PUT /api/user/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John M. Doe",
  "avatar": "https://cdn.example.com/avatars/new.jpg"
}
```

#### Change Password
```http
POST /api/user/profile/change-password
Authorization: Bearer {token}
Content-Type: application/json

{
  "currentPassword": "oldpass123",
  "newPassword": "newpass456"
}
```

---

### 3.2 User Settings

#### Get User Settings
```http
GET /api/user/settings
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "settings": [
      {
        "key": "user.notifications.email",
        "value": true,
        "category": "notifications"
      },
      {
        "key": "user.theme",
        "value": "dark",
        "category": "appearance"
      }
    ]
  }
}
```

#### Update User Setting
```http
PUT /api/user/settings/:key
Authorization: Bearer {token}
Content-Type: application/json

{
  "value": "light"
}
```

---

### 3.3 Notifications Preferences

#### Get Notification Settings
```http
GET /api/user/notifications/preferences
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "email": {
      "enabled": true,
      "frequency": "daily",
      "types": {
        "mentions": true,
        "assignments": true,
        "updates": false
      }
    },
    "push": {
      "enabled": false
    },
    "inApp": {
      "enabled": true
    }
  }
}
```

#### Update Notification Preferences
```http
PUT /api/user/notifications/preferences
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": {
    "enabled": true,
    "frequency": "realtime",
    "types": {
      "mentions": true,
      "assignments": true,
      "updates": true
    }
  }
}
```

---

### 3.4 User Integrations

#### Get Connected Integrations
```http
GET /api/user/integrations
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "integrations": [
      {
        "id": 1,
        "provider": "github",
        "accountName": "johndoe",
        "connectedAt": "2025-08-15T10:00:00Z",
        "scopes": ["repo", "user"]
      }
    ],
    "available": [
      {
        "provider": "slack",
        "name": "Slack",
        "description": "Connect to Slack workspace",
        "authUrl": "/api/user/integrations/slack/authorize"
      }
    ]
  }
}
```

#### Connect Integration
```http
POST /api/user/integrations/:provider/connect
Authorization: Bearer {token}
Content-Type: application/json

{
  "code": "oauth_code_123",
  "redirectUri": "https://app.example.com/integrations/callback"
}
```

#### Disconnect Integration
```http
DELETE /api/user/integrations/:integrationId
Authorization: Bearer {token}
```

---

## 🔒 Authorization & Permissions

### Role Hierarchy

```
OWNER > PLATFORM_ADMIN > TENANT_ADMIN > USER > GUEST
```

### Permission Matrix

| Endpoint | OWNER | PLATFORM_ADMIN | TENANT_ADMIN | USER | GUEST |
|----------|-------|----------------|--------------|------|-------|
| Platform Settings | ✅ | ✅ | ❌ | ❌ | ❌ |
| Service Registry | ✅ | ✅ | 👁️ | 👁️ | ❌ |
| All Tenants | ✅ | ✅ | ❌ | ❌ | ❌ |
| Tenant Settings | ✅* | ✅* | ✅ | 👁️ | ❌ |
| Tenant Users | ✅* | ✅* | ✅ | 👁️ | ❌ |
| Tenant Services | ✅* | ✅* | ✅ | 👁️ | ❌ |
| Billing | ✅* | ✅* | ✅ | ❌ | ❌ |
| User Profile | ✅ | ✅ | ✅ | ✅ | 👁️ |
| User Settings | ✅ | ✅ | ✅ | ✅ | ❌ |

Legend:
- ✅ Full access
- ✅* Can access all tenants
- 👁️ Read-only
- ❌ No access

### Middleware Implementation

```typescript
// src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express';

export const requireRole = (roles: string[]) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const user = req.user; // Populated by auth middleware

    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized'
      });
    }

    if (!roles.includes(user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions'
      });
    }

    next();
  };
};

export const requireTenantAccess = () => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const user = req.user;
    const tenantId = req.params.tenantId || req.headers['x-tenant-id'];

    // OWNER and PLATFORM_ADMIN can access all tenants
    if (['OWNER', 'PLATFORM_ADMIN'].includes(user.role)) {
      return next();
    }

    // Other users can only access their tenant
    if (user.tenantId !== parseInt(tenantId)) {
      return res.status(403).json({
        success: false,
        error: 'Access to this tenant is forbidden'
      });
    }

    next();
  };
};
```

---

## 📦 Frontend Implementation (app-settings-frontend)

### Technology Stack

- **Framework**: React 18+
- **State Management**: Zustand + TanStack Query
- **Routing**: React Router v6
- **Forms**: React Hook Form + Zod validation
- **UI**: Tailwind CSS + shadcn/ui
- **API Client**: Axios with interceptors

### Directory Structure

```
app-settings-frontend/
├── src/
│   ├── pages/
│   │   ├── platform/              # OWNER/PLATFORM_ADMIN
│   │   │   ├── PlatformSettings.tsx
│   │   │   ├── ServiceRegistry.tsx
│   │   │   ├── TenantsManagement.tsx
│   │   │   └── Analytics.tsx
│   │   ├── tenant/                # TENANT_ADMIN
│   │   │   ├── TenantSettings.tsx
│   │   │   ├── UsersManagement.tsx
│   │   │   ├── ServicesManagement.tsx
│   │   │   ├── Billing.tsx
│   │   │   └── Security.tsx
│   │   └── user/                  # USER
│   │       ├── Profile.tsx
│   │       ├── Preferences.tsx
│   │       ├── Notifications.tsx
│   │       └── Integrations.tsx
│   ├── components/
│   │   ├── settings/
│   │   │   ├── SettingField.tsx
│   │   │   ├── SettingGroup.tsx
│   │   │   └── SettingCategory.tsx
│   │   ├── forms/
│   │   └── common/
│   ├── api/
│   │   ├── client.ts
│   │   ├── platform.ts
│   │   ├── tenant.ts
│   │   └── user.ts
│   ├── hooks/
│   │   ├── useSettings.ts
│   │   ├── usePermissions.ts
│   │   └── useAudit.ts
│   ├── stores/
│   │   ├── authStore.ts
│   │   ├── settingsStore.ts
│   │   └── uiStore.ts
│   └── types/
│       ├── settings.ts
│       ├── api.ts
│       └── permissions.ts
├── package.json
├── vite.config.ts
└── README.md
```

### API Client Setup

```typescript
// src/api/client.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    const tenantId = localStorage.getItem('tenant_id');
    if (tenantId) {
      config.headers['X-Tenant-ID'] = tenantId;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### React Query Hooks

```typescript
// src/hooks/useSettings.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPlatformSettings, updatePlatformSetting } from '@/api/platform';

export const usePlatformSettings = () => {
  return useQuery({
    queryKey: ['platformSettings'],
    queryFn: getPlatformSettings,
  });
};

export const useUpdatePlatformSetting = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ key, value }: { key: string; value: any }) =>
      updatePlatformSetting(key, value),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['platformSettings'] });
    },
  });
};
```

---

## 🧪 Testing Standards

### Backend API Tests

```typescript
// tests/api/platform-settings.test.ts
import request from 'supertest';
import app from '../src/app';

describe('Platform Settings API', () => {
  let ownerToken: string;
  let userToken: string;

  beforeAll(async () => {
    // Setup test database and create test users
    ownerToken = await getAuthToken('OWNER');
    userToken = await getAuthToken('USER');
  });

  describe('GET /api/admin/platform/settings', () => {
    it('should return settings for OWNER', async () => {
      const response = await request(app)
        .get('/api/admin/platform/settings')
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.settings).toBeInstanceOf(Array);
    });

    it('should deny access for USER', async () => {
      await request(app)
        .get('/api/admin/platform/settings')
        .set('Authorization', `Bearer ${userToken}`)
        .expect(403);
    });
  });

  describe('PUT /api/admin/platform/settings/:key', () => {
    it('should update setting and create audit log', async () => {
      const response = await request(app)
        .put('/api/admin/platform/settings/test.setting')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({
          value: true,
          category: 'general',
        })
        .expect(200);

      expect(response.body.success).toBe(true);

      // Verify audit log created
      const auditLog = await getLatestAuditLog();
      expect(auditLog.action).toBe('UPDATE');
      expect(auditLog.table_name).toBe('platform_settings');
    });
  });
});
```

---

## 📖 Documentation Standards

Each API endpoint MUST be documented with:

1. **OpenAPI/Swagger spec**
2. **Request/Response examples**
3. **Error codes and messages**
4. **Permission requirements**
5. **Rate limits**

### OpenAPI Example

```yaml
/api/admin/platform/settings:
  get:
    summary: Get all platform settings
    tags:
      - Platform Admin
    security:
      - bearerAuth: []
    parameters:
      - in: query
        name: category
        schema:
          type: string
        description: Filter by category
    responses:
      '200':
        description: Success
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PlatformSettingsResponse'
      '401':
        $ref: '#/components/responses/Unauthorized'
      '403':
        $ref: '#/components/responses/Forbidden'
```

---

## 🚀 Deployment Checklist

Before deploying admin panels:

- [ ] All API endpoints have permission checks
- [ ] Audit logging implemented for sensitive operations
- [ ] Rate limiting configured
- [ ] Input validation with Zod schemas
- [ ] Error handling standardized
- [ ] API documentation complete
- [ ] Frontend forms use React Hook Form + Zod
- [ ] All mutations invalidate appropriate queries
- [ ] Loading and error states handled
- [ ] Responsive design tested
- [ ] Accessibility (a11y) tested
- [ ] E2E tests for critical flows
- [ ] Security review completed

---

**Questo documento è OBBLIGATORIO per implementare qualsiasi pannello admin.**

**Non creare endpoint admin senza seguire questa specifica.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
