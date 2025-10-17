# 🗄️ Database Architecture Complete
## Architettura Database Core e User-Generated - EWH Platform

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Executive Summary

Questo documento consolida l'architettura completa dei database della piattaforma EWH, definendo la separazione mandatoria tra:

1. **`ewh_master`** - Database Core (piattaforma e gestione)
2. **`ewh_tenant`** - Database User-Generated (contenuti e dati business)

### 🔴 REGOLA MANDATORIA

**OGNI servizio DEVE connettersi al database appropriato:**

- ✅ Servizi CORE → `ewh_master` (auth, settings, billing)
- ✅ Servizi BUSINESS → `ewh_tenant` (pm, inventory, cms, products, etc.)

---

## 📊 Architettura Database

```
┌─────────────────────────────────────────────────────────────┐
│                      ewh_master                              │
│                   (Core Platform DB)                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  👥 users                                             │  │
│  │  🏢 tenants                                           │  │
│  │  🔑 roles, permissions                                │  │
│  │  ⚙️  platform_settings, tenant_settings               │  │
│  │  🔧 service_registry, tenant_services                 │  │
│  │  📊 audit_logs, sessions                              │  │
│  │  💳 billing, subscriptions, invoices                  │  │
│  │  📧 email_templates, notifications                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  Accesso da:                                                 │
│  • svc-auth (4100)                                          │
│  • svc-settings (5960)                                      │
│  • svc-billing (5400)                                       │
│  • svc-api-gateway (4000)                                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      ewh_tenant                              │
│                (User-Generated Content DB)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  📄 pages, templates, components                      │  │
│  │  🧩 custom_blocks, widgets                            │  │
│  │  📋 projects, tasks, boards                           │  │
│  │  📦 products, inventory, orders                       │  │
│  │  🖼️  media_assets, files, folders                     │  │
│  │  📧 email_campaigns, contacts                         │  │
│  │  🗄️  custom_* tables (user-created)                   │  │
│  │  📊 custom_tables_registry                            │  │
│  │  🔍 custom_views, custom_api_endpoints                │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  Accesso da:                                                 │
│  • svc-pm (5500)                                            │
│  • svc-inventory (5650)                                     │
│  • svc-products (5800)                                      │
│  • svc-cms (5350)                                           │
│  • svc-page-builder (5750)                                  │
│  • svc-media (5700)                                         │
│  • svc-database-editor (5950) 🆕                            │
│  • tutti i business services                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Tabelle per Database

### ewh_master (Core Platform)

#### Authentication & Authorization
```sql
users
├── id, email, password_hash, name, avatar
├── tenant_id (FK → tenants)
├── role (OWNER, PLATFORM_ADMIN, TENANT_ADMIN, USER)
├── status (active, suspended, deleted)
└── created_at, updated_at, last_login

tenants
├── id, name, slug, status
├── plan (free, starter, professional, enterprise)
├── subscription_status (active, trial, suspended, cancelled)
└── created_at, updated_at

roles
├── id, role_key, role_name, description
└── permissions (JSONB)

sessions
├── id, user_id (FK), token_hash
├── ip_address, user_agent
├── expires_at, last_activity
└── created_at
```

#### Platform Configuration
```sql
platform_settings
├── id, setting_key (UNIQUE), setting_value (JSONB)
├── category, description, schema (JSONB)
├── is_public
└── created_at, updated_at, created_by, updated_by

tenant_settings
├── id, tenant_id (FK), setting_key
├── setting_value (JSONB)
├── inherits_from_platform
└── created_at, updated_at, created_by, updated_by

service_registry
├── id, service_id (UNIQUE), service_name
├── service_type (backend, frontend)
├── category, port, health_check_url
├── is_core, default_enabled
└── created_at, updated_at

tenant_services
├── id, tenant_id (FK), service_id (FK)
├── is_enabled, configuration (JSONB)
├── enabled_at, enabled_by
└── disabled_at, disabled_by
```

#### Audit & Security
```sql
settings_audit
├── id, table_name, record_id, action
├── old_value (JSONB), new_value (JSONB)
├── changed_by (FK → users), changed_at
└── ip_address, user_agent

audit_logs
├── id, tenant_id, user_id
├── action, entity_type, entity_id
├── details (JSONB)
└── ip_address, user_agent, created_at
```

#### Billing & Subscriptions
```sql
subscriptions
├── id, tenant_id (FK)
├── plan, status, current_period_start, current_period_end
├── cancel_at_period_end
└── created_at, updated_at

invoices
├── id, tenant_id (FK), subscription_id (FK)
├── amount, currency, status
├── invoice_pdf_url, stripe_invoice_id
└── created_at, paid_at, due_date

payment_methods
├── id, tenant_id (FK)
├── type (card, bank_transfer, paypal)
├── last4, brand, exp_month, exp_year
└── is_default, created_at
```

### ewh_tenant (User-Generated)

#### Pages & Templates
```sql
pages
├── id (UUID), tenant_id, page_key (UNIQUE per tenant)
├── page_title, layout_config (JSONB)
├── template_id (FK → templates), status
├── version, published_at
└── created_at, updated_at, created_by, updated_by

templates
├── id (UUID), tenant_id (NULL = system template)
├── template_key (UNIQUE), template_name
├── layout_config (JSONB), thumbnail_url
├── visibility (private, tenant, public)
└── created_at, updated_at, created_by

components
├── id (UUID), tenant_id, component_key
├── component_name, config_schema (JSONB)
├── default_props (JSONB), render_config (JSONB)
├── visibility, version
└── created_at, updated_at, created_by

custom_blocks
├── id (UUID), tenant_id, block_key
├── block_label, block_content (HTML)
├── block_styles (CSS), block_category
└── created_at, updated_at, created_by

widgets
├── id (UUID), tenant_id, widget_key
├── widget_name, widget_type, config (JSONB)
├── permissions (JSONB)
└── created_at, updated_at, created_by
```

#### Business Data - Project Management
```sql
projects
├── id (UUID), tenant_id, project_key
├── project_name, description, status
├── start_date, due_date, budget
├── owner_id (references ewh_master.users.id)
└── created_at, updated_at

tasks
├── id (UUID), tenant_id, project_id (FK)
├── task_name, description, status
├── priority, assigned_to, due_date
└── created_at, updated_at, created_by

boards
├── id (UUID), tenant_id, project_id (FK)
├── board_name, board_type (kanban, scrum)
├── columns_config (JSONB)
└── created_at, updated_at
```

#### Business Data - Inventory & Products
```sql
products
├── id (UUID), tenant_id, product_sku
├── product_name, description
├── price, currency, stock_quantity
├── category, is_active
└── created_at, updated_at, created_by

inventory_items
├── id (UUID), tenant_id, product_id (FK)
├── warehouse_location, quantity
├── reorder_level, reorder_quantity
└── created_at, updated_at

orders
├── id (UUID), tenant_id, order_number
├── customer_id, status, total_amount
├── currency, shipping_address (JSONB)
└── created_at, updated_at, fulfilled_at
```

#### Media & Assets
```sql
media_assets
├── id (UUID), tenant_id, file_name
├── file_path, file_size, mime_type
├── asset_type (image, video, document)
├── width, height, duration, metadata (JSONB)
├── folder_id (FK → media_folders)
└── created_at, updated_at, uploaded_by

media_folders
├── id (UUID), tenant_id, folder_name
├── parent_id (FK → self)
└── created_at, updated_at, created_by
```

#### Custom Tables (Visual DB Editor)
```sql
custom_tables_registry
├── id (UUID), tenant_id, table_name
├── display_name, description
├── icon, color
├── schema_config (JSONB)
├── relationships (JSONB)
├── permissions (JSONB)
├── api_enabled, api_prefix
└── created_at, updated_at, created_by

custom_views
├── id (UUID), tenant_id, view_name
├── display_name, base_table
├── query_config (JSONB)
├── is_materialized
└── created_at, updated_at, created_by

custom_api_endpoints
├── id (UUID), tenant_id, endpoint_key
├── endpoint_path, http_method
├── description, base_table
├── query_config (JSONB), permissions (JSONB)
├── rate_limit, is_active
└── created_at, updated_at, created_by

-- Example of dynamically created table
custom_contacts (created by user via DB editor)
├── id (UUID), tenant_id
├── email, name, phone (user-defined columns)
├── company_id (FK → custom_companies)
└── created_at, updated_at, created_by
```

---

## 🔌 Connection Configuration

### Environment Variables per Service

#### Servizi CORE (ewh_master)

```bash
# svc-auth/.env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_master
PORT=4100

# svc-settings/.env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_master
PORT=5960

# svc-billing/.env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_master
PORT=5400
```

#### Servizi BUSINESS (ewh_tenant)

```bash
# svc-pm/.env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_tenant
PORT=5500

# svc-inventory/.env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_tenant
PORT=5650

# svc-products/.env
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_tenant
PORT=5800

# svc-database-editor/.env (NEW!)
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_tenant
PORT=5950
```

### Cross-Database Queries

Quando un servizio business deve accedere a dati da `ewh_master` (es: user info), usare:

```typescript
// In svc-pm (connects to ewh_tenant)
import { Pool } from 'pg';

const tenantPool = new Pool({
  connectionString: process.env.DATABASE_URL, // ewh_tenant
});

const masterPool = new Pool({
  connectionString: process.env.DATABASE_MASTER_URL, // ewh_master
});

// Get project with user info
async function getProjectWithOwner(projectId: string, tenantId: number) {
  // Get project from ewh_tenant
  const project = await tenantPool.query(
    'SELECT * FROM projects WHERE id = $1 AND tenant_id = $2',
    [projectId, tenantId]
  );

  // Get owner info from ewh_master
  const owner = await masterPool.query(
    'SELECT id, name, email, avatar FROM users WHERE id = $1',
    [project.rows[0].owner_id]
  );

  return {
    ...project.rows[0],
    owner: owner.rows[0],
  };
}
```

---

## 🔄 Migration Strategy

### Creating the Databases

```sql
-- Connect to PostgreSQL as superuser
psql -U postgres

-- Create databases
CREATE DATABASE ewh_master;
CREATE DATABASE ewh_tenant;

-- Create dedicated users (optional)
CREATE USER ewh_core_user WITH PASSWORD 'secure_password';
CREATE USER ewh_tenant_user WITH PASSWORD 'secure_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE ewh_master TO ewh_core_user;
GRANT ALL PRIVILEGES ON DATABASE ewh_tenant TO ewh_tenant_user;
```

### Running Migrations

```bash
# Core platform migrations
cd migrations/core
psql -U postgres -d ewh_master -f 001_create_users_tenants.sql
psql -U postgres -d ewh_master -f 002_create_platform_settings.sql
psql -U postgres -d ewh_master -f 003_create_service_registry.sql
psql -U postgres -d ewh_master -f 004_create_audit_tables.sql
psql -U postgres -d ewh_master -f 005_create_billing_tables.sql

# Tenant/business migrations
cd migrations/tenant
psql -U postgres -d ewh_tenant -f 010_create_pages_templates.sql
psql -U postgres -d ewh_tenant -f 020_create_projects_tasks.sql
psql -U postgres -d ewh_tenant -f 030_create_products_inventory.sql
psql -U postgres -d ewh_tenant -f 040_create_media_tables.sql
psql -U postgres -d ewh_tenant -f 050_create_custom_tables_registry.sql
```

### Migration Script Helper

```typescript
// scripts/run-migration.ts
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

const masterPool = new Pool({
  connectionString: 'postgresql://postgres:password@localhost:5432/ewh_master',
});

const tenantPool = new Pool({
  connectionString: 'postgresql://postgres:password@localhost:5432/ewh_tenant',
});

async function runMigration(database: 'master' | 'tenant', filename: string) {
  const pool = database === 'master' ? masterPool : tenantPool;
  const sql = fs.readFileSync(
    path.join(__dirname, `../migrations/${database}/${filename}`),
    'utf-8'
  );

  try {
    await pool.query('BEGIN');
    await pool.query(sql);
    await pool.query('COMMIT');
    console.log(`✅ Migration ${filename} applied to ${database}`);
  } catch (error) {
    await pool.query('ROLLBACK');
    console.error(`❌ Migration ${filename} failed:`, error);
    throw error;
  }
}

// Usage
async function migrate() {
  // Run core migrations
  await runMigration('master', '001_create_users_tenants.sql');
  await runMigration('master', '002_create_platform_settings.sql');

  // Run tenant migrations
  await runMigration('tenant', '010_create_pages_templates.sql');
  await runMigration('tenant', '020_create_projects_tasks.sql');
}

migrate().then(() => {
  console.log('🎉 All migrations completed');
  process.exit(0);
});
```

---

## 📋 Checklist Implementazione

### Per Nuovi Servizi

Quando crei un nuovo servizio, segui questo checklist:

- [ ] Determina se è servizio CORE o BUSINESS
- [ ] Configura `DATABASE_URL` corretto nel `.env`
- [ ] Se serve accesso cross-database, aggiungi `DATABASE_MASTER_URL`
- [ ] Crea migration SQL per le tabelle necessarie
- [ ] Tutte le tabelle tenant devono avere colonna `tenant_id`
- [ ] Aggiungi indici su `tenant_id` per performance
- [ ] Implementa tenant isolation (WHERE tenant_id = $1)
- [ ] Testa che non ci sia data leakage tra tenant
- [ ] Documenta quali tabelle usa il servizio
- [ ] Aggiungi il servizio al SERVICE_REGISTRY

### Per Tabelle Esistenti da Migrare

Se hai tabelle nel database sbagliato, segui questi step:

1. **Backup dei dati**
```sql
-- Export data
COPY your_table TO '/tmp/your_table_backup.csv' CSV HEADER;
```

2. **Crea tabella nel database corretto**
```sql
-- In ewh_tenant se è user-generated
CREATE TABLE your_table (...);
```

3. **Importa i dati**
```sql
COPY your_table FROM '/tmp/your_table_backup.csv' CSV HEADER;
```

4. **Aggiorna il servizio** per usare il nuovo DATABASE_URL

5. **Testa tutto** prima di eliminare la vecchia tabella

---

## 🔐 Security Best Practices

### Tenant Isolation

**SEMPRE** filtrare per `tenant_id` quando accedi a dati in `ewh_tenant`:

```typescript
// ❌ WRONG - Espone dati di altri tenant
const projects = await pool.query('SELECT * FROM projects');

// ✅ CORRECT - Isolamento tenant
const projects = await pool.query(
  'SELECT * FROM projects WHERE tenant_id = $1',
  [tenantId]
);
```

### Row-Level Security (RLS) - Optional

Per sicurezza extra, puoi abilitare RLS su PostgreSQL:

```sql
-- Enable RLS on ewh_tenant tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY tenant_isolation ON projects
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant')::int);

-- In application, set tenant context
SET app.current_tenant = '1';
```

---

## 📊 Performance Considerations

### Indexes Mandatori

Tutte le tabelle in `ewh_tenant` devono avere:

```sql
-- Index su tenant_id (MANDATORIO)
CREATE INDEX idx_tablename_tenant ON tablename(tenant_id);

-- Composite indexes per query comuni
CREATE INDEX idx_projects_tenant_status ON projects(tenant_id, status);
CREATE INDEX idx_tasks_project ON tasks(project_id);
```

### Connection Pooling

```typescript
// Usa connection pooling per performance
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

---

## 🎓 Riferimenti Documenti

1. **[ADMIN_PANELS_API_FIRST_SPECIFICATION.md](./ADMIN_PANELS_API_FIRST_SPECIFICATION.md)**
   - Contiene schema completo `ewh_master` (platform_settings, service_registry, etc.)
   - Contiene schema completo `ewh_tenant` (pages, templates, components, etc.)

2. **[VISUAL_DATABASE_EDITOR_SPECIFICATION.md](./VISUAL_DATABASE_EDITOR_SPECIFICATION.md)**
   - Specifica completa per editor DB visuale (Xano-like)
   - Schema per `custom_tables_registry`, `custom_views`, `custom_api_endpoints`
   - Controller per creazione dinamica tabelle

3. **[API_ENDPOINTS_MAP.md](./API_ENDPOINTS_MAP.md)**
   - Mappa completa di tutti gli endpoint (150+)
   - Include nuovi endpoint `/api/db-editor/*`

4. **[PLATFORM_MANDATORY_STANDARDS.md](./PLATFORM_MANDATORY_STANDARDS.md)**
   - Standard per health check, PM2 config, etc.

5. **[CODE_ORGANIZATION_STANDARDS.md](./CODE_ORGANIZATION_STANDARDS.md)**
   - Standard per organizzazione codice (one-function-per-file)

---

## ✅ Validation Checklist

Prima di fare deployment, verifica:

- [ ] Entrambi i database (`ewh_master`, `ewh_tenant`) esistono
- [ ] Tutte le migration sono state applicate
- [ ] Ogni servizio ha `DATABASE_URL` corretto
- [ ] Tutte le tabelle tenant hanno colonna `tenant_id`
- [ ] Tutti gli indici su `tenant_id` sono stati creati
- [ ] Test di tenant isolation passano (no data leakage)
- [ ] Backup strategy è configurata (diversa per master vs tenant)
- [ ] Connection pooling è configurato
- [ ] Cross-database queries usano pool separati
- [ ] Documentation aggiornata

---

**Questo documento è MANDATORIO per l'architettura database della piattaforma.**

**Non creare servizi senza separare correttamente i database.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
