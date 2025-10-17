# 📋 SPECIFICHE SVILUPPO DEFINITIVE - EWH Platform

**Versione:** 2.0 (Ottobre 2025)
**Stato:** Documento Ufficiale di Riferimento
**Target:** Sviluppatori, AI Agents, Team Tecnico

---

## 🎯 VISIONE GENERALE

**EWH (Edizioni White Hole)** è una piattaforma SaaS B2B multi-tenant enterprise per:
- Gestione contenuti creativi (CMS/DAM)
- Publishing digitale e workflow editoriali
- E-commerce e cataloghi prodotti
- Project management e collaborazione
- Automazione workflow e approvazioni

---

## 🏗️ ARCHITETTURA SISTEMA

### Principi Fondamentali

1. **Microservizi Loosely Coupled**
   - 50+ servizi indipendenti
   - Deployabili separatamente
   - Comunicazione via REST API

2. **Multi-Tenancy a 2 Livelli**
   - Database `ewh_master`: Core platform (users, tenants, billing, settings)
   - Database `ewh_tenant`: User-generated content (pages, projects, custom tables)
   - Isolamento RLS (Row Level Security) PostgreSQL

3. **API-First Design**
   - 150+ endpoint REST documentati
   - Validazione con Zod/Joi
   - OpenAPI spec per ogni servizio

4. **Plugin-First Architecture**
   - Zero modifiche al core
   - Estensioni tramite hook system
   - Registry centralizzato (svc-plugins)

5. **Event-Driven (Roadmap v2.5)**
   - Redis Streams per eventi asincroni
   - Webhook system per integrazioni esterne

---

## 📊 STACK TECNOLOGICO

### Backend
- **Runtime:** Node.js 20+ LTS
- **Framework:** Fastify 4.x (nuovi servizi) / Express 4.x (legacy)
- **Linguaggio:** TypeScript 5.x (strict mode)
- **Database:** PostgreSQL 16+ (2 database separati)
- **Cache:** Redis 7+ (sessioni, job queue)
- **Storage:** S3-compatible (Wasabi/AWS)
- **ORM:** Preferenza raw SQL + pg library (performance)

### Frontend
- **Framework:** React 18 + TypeScript
- **Build Tool:** Vite 5.x (apps modulari) / Next.js 14 (SSR apps)
- **Styling:** Tailwind CSS 3.x + CSS Modules
- **State:** Zustand / React Query / Context API
- **Form Validation:** React Hook Form + Zod
- **UI Components:** Shared package `@ewh/ui-components`

### Infrastruttura
- **Deployment:** Mac Studio (dev) → Scalingo PaaS (prod)
- **CI/CD:** GitHub Actions
- **Monitoring:** (Da implementare: Sentry + LogTail)
- **Service Management:** PM2 (dev) / Docker (prod)
- **Reverse Proxy:** Nginx / Traefik

### Shared Packages (pnpm workspace)
```
@ewh/types          - TypeScript types condivisi
@ewh/db-utils       - Utility database + migrations
@ewh/auth           - Middleware autenticazione
@ewh/ui-components  - Componenti UI riusabili
@ewh/api-client     - Client HTTP type-safe
@ewh/validation     - Schema Zod condivisi
@ewh/service-discovery - Auto-registration servizi
```

---

## 🔐 AUTENTICAZIONE & AUTORIZZAZIONE

### Standard SSO (Single Sign-On)

**Fonte Unica:** `svc-auth` (porta 4001)

**JWT Token Structure:**
```json
{
  "email": "user@example.com",
  "org_id": "uuid",
  "org_slug": "organization-slug",
  "tenant_role": "TENANT_ADMIN | USER",
  "platform_role": "OWNER | PLATFORM_ADMIN | USER",
  "scopes": ["feature:cms.edit", "feature:dam.upload", ...],
  "exp": 1234567890,
  "iss": "http://svc-auth:4001",
  "aud": "ewh-saas",
  "sub": "user_uuid",
  "jti": "token_id"
}
```

**Token Lifetime:**
- Access Token: 15 minuti (RS256)
- Refresh Token: 30 giorni (stored in DB)

**Validazione Token:**
- JWKS pubblico: `http://svc-auth:4001/.well-known/jwks.json`
- Middleware in ogni servizio backend
- Header: `Authorization: Bearer <token>`

**Cascade Permessi:**
```
PLATFORM_ADMIN/OWNER
  ↓ accesso completo piattaforma
TENANT_ADMIN
  ↓ accesso completo tenant
USER
  ↓ accesso risorse assegnate
```

**Implementazione SSO Frontend:**
1. Shell passa token via query string: `?token=xxx&tenant_id=yyy`
2. Frontend legge token e valida con `/whoami`
3. Memorizza in localStorage + React Context
4. Refresh automatico prima di scadenza

**Riferimento:** [SSO_ARCHITECTURE.md](SSO_ARCHITECTURE.md)

---

## 🗄️ DATABASE ARCHITECTURE

### Due Database Separati (CRITICO!)

#### 1. `ewh_master` - Core Platform
**Purpose:** Dati della piattaforma SaaS

**Schema Principale:**
```sql
-- Utenti e organizzazioni
users (id, email, password_hash, platform_role)
organizations (id, name, slug, subscription_tier)
memberships (user_id, org_id, tenant_role)

-- Billing e subscription
subscriptions (org_id, plan, status, billing_cycle)
invoices (org_id, amount, status, stripe_id)

-- Settings a cascata
platform_settings (key, value, category)
tenant_settings (org_id, key, value, category)
user_preferences (user_id, key, value)

-- Audit e sicurezza
audit_logs (org_id, user_id, action, resource_type)
api_keys (org_id, key_hash, scopes, expires_at)
```

**Connection String:**
```
postgresql://ewh_master_user:password@localhost:5432/ewh_master
```

#### 2. `ewh_tenant` - User Content
**Purpose:** Contenuti generati dagli utenti

**Schema Principale:**
```sql
-- CMS & Publishing
pages (org_id, title, slug, content_json, status)
templates (org_id, name, structure_json, category)
media_assets (org_id, file_key, mime_type, metadata)

-- Projects & Workflow
projects (org_id, name, type, config_json)
tasks (project_id, assignee_id, status, due_date)
approvals (org_id, resource_id, approver_id, status)

-- Products & Inventory
products (org_id, sku, name, price, stock)
categories (org_id, name, parent_id)
orders (org_id, customer_id, total, status)

-- Custom Tables (Visual DB Editor)
_custom_tables (org_id, table_name, schema_json)
custom_* (org_id, ...dynamic fields...)
```

**Connection String:**
```
postgresql://ewh_tenant_user:password@localhost:5432/ewh_tenant
```

**Regola Multi-Tenancy:**
- OGNI tabella in `ewh_tenant` DEVE avere: `org_id UUID NOT NULL`
- RLS Policy su TUTTE le tabelle: `WHERE org_id = current_setting('app.current_org_id')::uuid`

**Riferimento:**
- [DATABASE_ARCHITECTURE_COMPLETE.md](DATABASE_ARCHITECTURE_COMPLETE.md)
- [ADMIN_PANELS_API_FIRST_SPECIFICATION.md](ADMIN_PANELS_API_FIRST_SPECIFICATION.md)

---

## 🎨 FRONTEND ARCHITECTURE

### Shell Frontend (app-shell-frontend)
**Porta:** 3150
**Framework:** Next.js 14
**Purpose:** Container principale + SSO + Service routing

**Features:**
- Autenticazione centralizzata
- Menu dinamico (caricato da `svc-service-registry`)
- Iframe per microapps
- Passa token automaticamente alle app: `?token=xxx&tenant_id=yyy`
- Theme provider (light/dark)
- User preferences sync

**Key Files:**
- `src/context/ShellContext.tsx` - Auth state
- `src/pages/app.tsx` - Iframe container + SSO
- `src/lib/services.config.ts` - Service discovery

### Micro-Frontend Apps

Ogni app è indipendente ma integrata nella Shell:

```
app-pm-frontend (5400)         - Project Management
app-dam (3300)                 - Digital Asset Management
app-cms-frontend (5310)        - Content Management
app-workflow-editor (7501)     - Visual Workflow Builder
app-page-builder (7600)        - Page Builder (Elementor-like)
app-admin-frontend (3100)      - Admin Console
app-box-designer (3400)        - CAD Box Designer
```

**Pattern Comune:**
```typescript
// AuthContext.tsx - Pattern SSO
useEffect(() => {
  const initAuth = async () => {
    // 1. PRIORITÀ: Token dal query string (Shell SSO)
    const params = new URLSearchParams(window.location.search);
    const token = params.get('token');

    if (token) {
      setToken(token);
      await validateToken(token); // Call /whoami
      setIsLoading(false);
      return;
    }

    // 2. FALLBACK: localStorage (sessione persistente)
    const storedToken = localStorage.getItem('jwt_token');
    if (storedToken) {
      setToken(storedToken);
      setUser(JSON.parse(localStorage.getItem('user')));
    }

    setIsLoading(false);
  };

  initAuth();
}, []);
```

**Riferimento:** [FRONTEND_SPECIFICATIONS.md](FRONTEND_SPECIFICATIONS.md)

---

## 🔌 SERVIZI BACKEND

### Allocazione Porte

**Core Services (4000-4099)**
```
4000 - svc-api-gateway       - Routing + Auth proxy
4001 - svc-auth              - SSO + JWT + Multi-tenancy
4002 - svc-plugins           - Plugin registry
4003 - svc-media             - Upload + S3 + CDN
4004 - svc-billing           - Stripe + Invoicing
```

**Creative Services (4100-4199)**
```
4100 - svc-image-orchestrator  - Image processing (Sharp)
4101 - svc-video-orchestrator  - Video encoding (FFmpeg)
4102 - svc-raster-runtime      - Raster editor backend
4103 - svc-vector-lab          - Vector editor backend
4104 - svc-mockup              - Mockup generator
4105 - svc-photo-editor        - Photo editing pipeline
```

**Publishing Services (4200-4299)**
```
4200 - svc-cms                 - Headless CMS
4201 - svc-page-builder        - Page builder API
4202 - svc-site-builder        - Site generation
4203 - svc-site-publisher      - Multi-channel publish
4204 - svc-site-renderer       - SSR/SSG rendering
4205 - svc-writer              - AI writing assistant
```

**ERP Services (4300-4399)**
```
4300 - svc-inventory           - Stock + Warehouse
4301 - svc-orders              - Order management
4302 - svc-orders-purchase     - Purchase orders
4303 - svc-orders-sales        - Sales orders
4304 - svc-products            - Product catalog
4305 - svc-quotation           - Quote generation
4306 - svc-procurement         - Supplier management
4307 - svc-shipping            - Logistics + Tracking
4308 - svc-mrp                 - Material planning
```

**Collaboration Services (4400-4499)**
```
4400 - svc-pm                  - Project management
4401 - svc-boards              - Kanban boards
4402 - svc-projects            - Project templates
4403 - svc-chat                - Team chat
4404 - svc-comm                - Email/SMS gateway
4405 - svc-channels            - Communication channels
4406 - svc-voice               - VoIP/WebRTC
4407 - svc-timesheet           - Time tracking
4408 - svc-approvals           - Approval workflows
4409 - svc-workflow-tracker    - Workflow engine
```

**Platform Services (4500-4599)**
```
4500 - svc-search              - Elasticsearch wrapper
4501 - svc-metrics-collector   - Analytics + Metrics
4502 - svc-service-registry    - Service discovery
4503 - svc-job-worker          - Background jobs
4504 - svc-assistant           - AI assistant
```

**Riferimento:** [APP_PORTS_ALLOCATION.md](APP_PORTS_ALLOCATION.md)

---

## 📐 STANDARD DI SVILUPPO

### 1. Struttura Servizio Backend

```
svc-example/
├── src/
│   ├── index.ts              - Entry point + Fastify setup
│   ├── routes/               - Route handlers
│   │   ├── auth.ts
│   │   └── api.ts
│   ├── services/             - Business logic
│   │   └── example.service.ts
│   ├── middleware/           - Auth, validation, etc
│   │   └── auth.middleware.ts
│   ├── types/                - TypeScript types
│   │   └── example.types.ts
│   └── utils/                - Helper functions
│       └── db.utils.ts
├── db/
│   └── migrations/           - SQL migrations
│       ├── 001_init.sql
│       └── 002_add_feature.sql
├── tests/                    - Unit + integration tests
├── package.json
├── tsconfig.json
├── .env.example
├── PROMPT.md                 - Istruzioni AI per questo servizio
└── README.md
```

### 2. API Design Standard

**Endpoint Pattern:**
```
/api/v1/{resource}
/api/v1/{resource}/{id}
/api/v1/{resource}/{id}/{action}
```

**Response Format:**
```typescript
// Success
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "pageSize": 20,
    "total": 100
  }
}

// Error
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": { ... }
}
```

**HTTP Status Codes:**
```
200 - OK (success)
201 - Created (resource created)
204 - No Content (delete success)
400 - Bad Request (validation error)
401 - Unauthorized (no token / invalid)
403 - Forbidden (no permission)
404 - Not Found
409 - Conflict (duplicate resource)
422 - Unprocessable Entity (business logic error)
500 - Internal Server Error
```

### 3. Naming Conventions

**Database:**
```sql
-- Tables: snake_case, plural
users, organizations, approval_workflows

-- Columns: snake_case
user_id, created_at, is_active

-- Indexes: table_column_idx
users_email_idx, orders_org_id_created_at_idx

-- Foreign Keys: fk_table_column
fk_memberships_user_id
```

**TypeScript:**
```typescript
// Interfaces: PascalCase
interface UserProfile { ... }

// Types: PascalCase
type OrderStatus = 'pending' | 'approved' | 'rejected';

// Functions: camelCase
async function createProject() { ... }

// Constants: UPPER_SNAKE_CASE
const MAX_FILE_SIZE = 10_000_000;

// Files: kebab-case
user-service.ts, auth-middleware.ts
```

**API Endpoints:**
```
GET    /api/v1/projects
POST   /api/v1/projects
GET    /api/v1/projects/:id
PUT    /api/v1/projects/:id
DELETE /api/v1/projects/:id
POST   /api/v1/projects/:id/archive
```

### 4. Git Workflow

**Branch Strategy:**
```
main              - Production
develop           - Development
feature/xxx       - Nuove feature
fix/xxx           - Bug fixes
hotfix/xxx        - Production hotfix
```

**Commit Messages:**
```
feat: add user profile API
fix: resolve JWT validation bug
refactor: optimize database queries
docs: update API documentation
chore: upgrade dependencies
```

### 5. Environment Variables

**Obbligatorie per ogni servizio:**
```bash
# Server
PORT=4000
HOST=0.0.0.0
NODE_ENV=development|production

# Database (scegliere quale)
DATABASE_URL=postgresql://user:pass@host:5432/ewh_master
TENANT_DATABASE_URL=postgresql://user:pass@host:5432/ewh_tenant

# Auth
JWT_PUBLIC_KEY=...
AUTH_SERVICE_URL=http://localhost:4001

# Storage (se necessario)
S3_ENDPOINT=https://s3.wasabisys.com
S3_BUCKET=ewh-assets
S3_ACCESS_KEY=...
S3_SECRET_KEY=...
```

---

## 🚀 WORKFLOW DI SVILUPPO

### Setup Iniziale

```bash
# 1. Clone monorepo
git clone https://github.com/your-org/ewh.git
cd ewh

# 2. Install dependencies (pnpm workspace)
pnpm install

# 3. Setup environment
cp .env.example .env
# Editare .env con credenziali corrette

# 4. Setup database
pnpm db:setup        # Crea database + schema
pnpm db:migrate      # Applica migrations

# 5. Start development
pnpm dev             # Avvia tutti i servizi con PM2
```

### Sviluppo Nuovo Servizio

```bash
# 1. Scaffold servizio
pnpm create-service svc-example

# 2. Configurare
cd svc-example
cp .env.example .env
# Editare package.json con porta corretta

# 3. Implementare
# - Creare routes in src/routes/
# - Creare migrations in db/migrations/
# - Aggiungere tests in tests/

# 4. Testare
pnpm test
pnpm dev

# 5. Documentare
# - Aggiornare PROMPT.md
# - Aggiornare README.md
# - Aggiornare PROJECT_STATUS.md
```

### Aggiunta Feature a Servizio Esistente

```bash
# 1. Leggere documentazione
cat {servizio}/PROMPT.md
cat {servizio}/FUNCTIONS.md

# 2. Branch
git checkout -b feature/xxx

# 3. Implementare
# - Aggiungere route
# - Aggiungere business logic
# - Creare migration (se serve)
# - Scrivere tests

# 4. Test
pnpm test
pnpm lint

# 5. Commit & PR
git commit -m "feat: add xxx feature"
git push origin feature/xxx
# Aprire PR su GitHub
```

### Environment Remoto (Mac Studio)

```bash
# 1. Setup SSH
ssh-copy-id fabio@192.168.1.47

# 2. Deploy servizio
./scripts/deploy-to-mac-studio.sh svc-example

# 3. Monitor logs
ssh fabio@192.168.1.47 'pm2 logs svc-example'

# 4. Visual Dashboard
# Aprire browser: http://localhost:8080
```

**Riferimento:** [REMOTE_DEVELOPMENT_GUIDE.md](REMOTE_DEVELOPMENT_GUIDE.md)

---

## 📊 STATO IMPLEMENTAZIONE ATTUALE

### Servizi Completi (Production Ready)
- ✅ svc-auth (95% completo)
- ✅ svc-api-gateway (85% completo)

### Servizi in Corso
- 🚧 svc-pm (60% completo)
- 🚧 svc-timesheet (60% completo)
- 🚧 app-shell-frontend (80% completo)

### Servizi Scaffold (Solo struttura base)
- 📝 Tutti gli altri 46 servizi hanno solo scaffolding

**Totale:** 2 completi / 3 in corso / 46 scaffold su 51 servizi

---

## 🎯 PRIORITÀ SVILUPPO (Q4 2025)

### Fase 1: Core MVP (Gennaio 2026)
1. ✅ svc-auth - Completare password recovery + email verification
2. 🚧 svc-cms - Implementare CRUD pages + templates
3. 🚧 svc-media - Upload + S3 integration + thumbnail generation
4. 🚧 app-dam - UI completa + workflow approvazioni
5. 🚧 svc-page-builder - Visual editor + save/publish

### Fase 2: Collaboration (Febbraio 2026)
6. svc-pm - Kanban completo + Gantt + time tracking
7. svc-approvals - Workflow engine + notifiche
8. svc-chat - Real-time messaging
9. svc-comm - Email/SMS gateway

### Fase 3: ERP Basic (Marzo 2026)
10. svc-products - Catalog + variants
11. svc-inventory - Stock tracking
12. svc-orders - Order management + invoicing

### Fase 4: Advanced Features (Aprile-Giugno 2026)
13. Visual DB Editor (Xano-like)
14. AI Assistant integration
15. Advanced analytics
16. Mobile apps (React Native)

**Riferimento:** [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md)

---

## 📖 DOCUMENTAZIONE DI RIFERIMENTO

### Documenti Principali (DA LEGGERE PRIMA)

1. **[AGENTS.md](AGENTS.md)** - Guida navigazione per AI
2. **[MASTER_PROMPT.md](MASTER_PROMPT.md)** - Istruzioni universali AI
3. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architettura sistema
4. **[PLATFORM_STANDARDS.md](PLATFORM_STANDARDS.md)** - Standard tecnici
5. **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Stato implementazione

### Database & API

6. **[DATABASE_ARCHITECTURE_COMPLETE.md](DATABASE_ARCHITECTURE_COMPLETE.md)** - Schema DB
7. **[ADMIN_PANELS_API_FIRST_SPECIFICATION.md](ADMIN_PANELS_API_FIRST_SPECIFICATION.md)** - 150+ API
8. **[API_ENDPOINTS_MAP.md](API_ENDPOINTS_MAP.md)** - Mappa endpoint
9. **[VISUAL_DATABASE_EDITOR_SPECIFICATION.md](VISUAL_DATABASE_EDITOR_SPECIFICATION.md)** - DB Editor

### Integrazione & Deploy

10. **[SHELL_SERVICE_INTEGRATION_COMPLETE.md](SHELL_SERVICE_INTEGRATION_COMPLETE.md)** - Service discovery
11. **[CODE_REUSABILITY_STRATEGY.md](CODE_REUSABILITY_STRATEGY.md)** - Shared packages
12. **[REMOTE_DEVELOPMENT_GUIDE.md](REMOTE_DEVELOPMENT_GUIDE.md)** - Dev environment
13. **[SSO_ARCHITECTURE.md](SSO_ARCHITECTURE.md)** - Autenticazione

### Feature-Specific

14. **[WORKFLOW_EDITOR_ENTERPRISE_FEATURES.md](WORKFLOW_EDITOR_ENTERPRISE_FEATURES.md)** - Workflow automation
15. **[PM_SYSTEM_READY.md](PM_SYSTEM_READY.md)** - Project management
16. **[BOX_DESIGNER_ENTERPRISE_READY.md](BOX_DESIGNER_ENTERPRISE_READY.md)** - CAD designer
17. **[DAM_COMPLETE_IMPLEMENTATION_PLAN.md](DAM_COMPLETE_IMPLEMENTATION_PLAN.md)** - Digital assets

---

## 🤖 ISTRUZIONI PER AI AGENTS

### Prima di Qualsiasi Operazione

1. **Leggere SEMPRE:** [AGENTS.md](AGENTS.md) (3 minuti)
2. **Verificare stato:** [PROJECT_STATUS.md](PROJECT_STATUS.md) (2 minuti)
3. **Controllare servizio specifico:** `{servizio}/PROMPT.md` (1 minuto)

### Pattern di Lavoro

**Modifica Esistente:**
```
1. Leggere {servizio}/FUNCTIONS.md
2. Trovare funzione specifica
3. Leggere solo quel file
4. Modificare
5. Aggiornare FUNCTIONS.md se necessario
```

**Nuova Feature:**
```
1. Verificare in quale servizio va
2. Leggere MODULAR_DEVELOPMENT_STANDARD.md
3. Decidere: plugin o modifica core?
4. Implementare seguendo standard
5. Creare/aggiornare migration
6. Documentare in PROMPT.md
```

**Operazione Database:**
```
1. LEGGERE PRIMA: DATABASE_ARCHITECTURE_COMPLETE.md
2. Determinare: ewh_master o ewh_tenant?
3. Verificare schema esistente
4. Creare migration SQL
5. Testare su database locale
6. Applicare su remoto
```

### Token Optimization

- ✅ Usare FUNCTIONS.md per trovare funzioni (evita lettura file interi)
- ✅ Leggere solo sezioni specifiche di doc lunghi
- ✅ Usare grep per trovare pattern
- ❌ NON leggere mai interi servizi senza motivo
- ❌ NON duplicare codice, usare shared packages

---

## 🆘 TROUBLESHOOTING COMUNE

### Database Connection Error
```bash
# Verificare connessione
psql -h localhost -U ewh_master_user -d ewh_master

# Reset password
ALTER USER ewh_master_user WITH PASSWORD 'newpass';
```

### Port Already in Use
```bash
# Trovare processo
lsof -i :4000

# Killare processo
kill -9 <PID>

# O restart PM2
pm2 restart svc-api-gateway
```

### JWT Validation Failed
```bash
# Verificare JWKS disponibile
curl http://localhost:4001/.well-known/jwks.json

# Verificare token
curl http://localhost:4000/whoami \
  -H "Authorization: Bearer <token>"
```

### Service Not Found in Shell
```bash
# Verificare service registry
curl http://localhost:4502/api/services

# Re-registrare servizio
curl -X POST http://localhost:4502/api/services \
  -H "Content-Type: application/json" \
  -d '{"name": "example", "url": "http://localhost:4000"}'
```

---

## 📞 CONTATTI & SUPPORTO

**Documentation Issues:** Aprire issue su GitHub
**Development Questions:** Team chat interno
**Production Incidents:** On-call engineer

---

**Ultima Revisione:** 15 Ottobre 2025
**Prossimo Review:** 15 Gennaio 2026
**Maintainers:** Team Architecture

---

✅ **Questo documento è la fonte ufficiale di verità per lo sviluppo della piattaforma EWH**
