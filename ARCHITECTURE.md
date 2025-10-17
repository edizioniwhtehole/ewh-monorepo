# EWH Platform - Architettura Sistema

> Documentazione architetturale della piattaforma SaaS EWH (Edizioni White Hole)

## 📋 Indice

- [Overview](#overview)
- [Architettura Microservizi](#architettura-microservizi)
- [Domini Funzionali](#domini-funzionali)
- [Stack Tecnologico](#stack-tecnologico)
- [Flussi Principali](#flussi-principali)
- [Database & Storage](#database--storage)
- [Sicurezza & Autenticazione](#sicurezza--autenticazione)
- [Deployment & Scalabilità](#deployment--scalabilità)

---

## Overview

EWH è una piattaforma SaaS B2B multi-tenant per la gestione end-to-end di contenuti creativi, publishing digitale ed e-commerce. Il sistema è progettato come **architettura a microservizi** con 50+ servizi indipendenti, ognuno con il proprio database e ciclo di vita.

### Principi Architetturali

1. **Microservizi Loosely Coupled** - Ogni servizio è indipendente, deployabile separatamente
2. **Database per Servizio** - Ogni microservizio ha il proprio schema PostgreSQL
3. **API-First Design** - Comunicazione REST JSON tra servizi
4. **Multi-Tenancy** - Isolamento dati a livello applicativo + database RLS
5. **Event-Driven** (in roadmap) - Comunicazione asincrona via Redis Streams
6. **Cloud-Native** - Deploy su Scalingo (PaaS), storage S3-compatible (Wasabi)

---

## Architettura Microservizi

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Applications                     │
├─────────────────────────────────────────────────────────────┤
│  app-web-frontend  │  app-admin-console  │  app-*-editor   │
│     (Next.js)      │      (Next.js)      │    (Next.js)    │
└──────────────────┬──────────────────────┬───────────────────┘
                   │                      │
                   ▼                      ▼
         ┌─────────────────────────────────────┐
         │      svc-api-gateway :4000          │
         │  (Routing, Auth, Rate Limiting)     │
         └─────────────────┬───────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │   Core   │      │ Creative │      │   ERP    │
  │ Services │      │ Services │      │ Services │
  └──────────┘      └──────────┘      └──────────┘
        │                  │                  │
        ▼                  ▼                  ▼
  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │Publishing│      │  Collab  │      │ Platform │
  │ Services │      │ Services │      │ Services │
  └──────────┘      └──────────┘      └──────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                ┌────────────────────┐
                │   Shared Storage   │
                │  PostgreSQL + S3   │
                └────────────────────┘
```

### Comunicazione Tra Servizi

- **Sincrona**: HTTP/REST via `svc-api-gateway` (service mesh in roadmap)
- **Asincrona** (TODO v2): Redis Streams per eventi (`user.created`, `order.placed`, etc)
- **Autenticazione**: JWT firmati da `svc-auth`, validati tramite JWKS

---

## Domini Funzionali

### 🔐 Core Services (Porta 4000-4004)

| Servizio | Porta | Responsabilità | Database |
|----------|-------|----------------|----------|
| `svc-api-gateway` | 4000 | Routing, auth proxy, rate limiting | - |
| `svc-auth` | 4001 | Autenticazione, multi-tenancy, JWT | ✅ PG |
| `svc-plugins` | 4002 | Registry plugin, estensioni | ✅ PG |
| `svc-media` | 4003 | Upload, gestione asset S3, CDN | ✅ PG + S3 |
| `svc-billing` | 4004 | Fatturazione, pagamenti Stripe | ✅ PG |

**Key Features:**
- JWT access token 15min, refresh 30 giorni
- Multi-tenant con RLS PostgreSQL
- Feature flags & RBAC granulare

### 🎨 Creative Services (Porta 4100-4110)

| Servizio | Porta | Responsabilità | Stack |
|----------|-------|----------------|-------|
| `svc-image-orchestrator` | 4100 | Pipeline elaborazione immagini | Sharp, FFmpeg |
| `svc-job-worker` | 4101 | Background jobs asincroni | BullMQ + Redis |
| `svc-writer` | 4102 | Editor testi AI-powered | OpenAI API |
| `svc-content` | 4103 | CMS headless, versioning | PG + S3 |
| `svc-layout` | 4104 | Engine impaginazione | Custom engine |
| `svc-prepress` | 4105 | Preflight PDF, export stampa | PDFKit |
| `svc-vector-lab` | 4106 | Editor grafica vettoriale | Canvas API |
| `svc-mockup` | 4107 | Generazione mockup 3D | Three.js |
| `svc-video-orchestrator` | 4108 | Pipeline video encoding | FFmpeg |
| `svc-video-runtime` | 4109 | Streaming video HLS/DASH | - |
| `svc-raster-runtime` | 4110 | Rendering immagini real-time | Canvas |

**Tech Highlights:**
- Job queue: BullMQ con Redis
- Storage: Wasabi S3 per asset
- AI: OpenAI GPT-4 per content generation

### 🌐 Publishing Services (Porta 4200-4205)

| Servizio | Porta | Responsabilità |
|----------|-------|----------------|
| `svc-projects` | 4200 | Gestione progetti multi-utente |
| `svc-search` | 4201 | Full-text search (Meilisearch) |
| `svc-site-builder` | 4202 | Website builder drag&drop |
| `svc-site-renderer` | 4203 | SSR siti web clienti |
| `svc-site-publisher` | 4204 | Deploy automatico siti |
| `svc-connectors-web` | 4205 | Integrazione Shopify, WordPress |

**Features:**
- Meilisearch per ricerca full-text
- Deploy automatico su Cloudflare Workers
- Template engine custom

### 🏭 ERP Services (Porta 4300-4308)

| Servizio | Porta | Responsabilità |
|----------|-------|----------------|
| `svc-products` | 4300 | Catalogo prodotti multi-variant |
| `svc-orders` | 4301 | Ordini, carrelli, checkout |
| `svc-inventory` | 4302 | Gestione magazzino, scorte |
| `svc-channels` | 4303 | Multi-channel (B2B, B2C, marketplace) |
| `svc-quotation` | 4304 | Preventivi, configuratore |
| `svc-procurement` | 4305 | Acquisti fornitori |
| `svc-mrp` | 4306 | Material Requirements Planning |
| `svc-shipping` | 4307 | Spedizioni, tracking |
| `svc-crm` | 4308 | CRM clienti, lead management |

**Business Logic:**
- Multi-currency (EUR default)
- Workflow approvazione preventivi
- Integrazione corrieri (tracking API)

### 🤝 Collaboration Services (Porta 4400-4410)

| Servizio | Porta | Responsabilità |
|----------|-------|----------------|
| `svc-pm` | 4400 | Project management, Kanban |
| `svc-support` | 4401 | Ticketing, customer support |
| `svc-chat` | 4402 | Chat real-time WebSocket |
| `svc-boards` | 4403 | Bacheche condivise, whiteboard |
| `svc-kb` | 4404 | Knowledge base, wiki |
| `svc-collab` | 4405 | Collaborazione real-time |
| `svc-dms` | 4406 | Document management system |
| `svc-timesheet` | 4407 | **Activity tracking, timesheet, zero-trust monitoring** |
| `svc-forms` | 4408 | Form builder dinamici |
| `svc-forum` | 4409 | Forum community |
| `svc-assistant` | 4410 | AI Assistant (GPT-4) |

**Real-time:**
- WebSocket per chat e collab
- Operational Transform per editing collaborativo

**Activity Tracking (svc-timesheet v2.0):**
- 🖥️ **Desktop Agent** ([ewh-work-agent](ewh-work-agent/)) - Electron cross-platform
  - Heartbeat ogni 30s con app attiva, window title, input activity
  - Screenshot capture (opzionale, S3)
  - Browser embedded Chromium con content filtering
  - Policy enforcer (kill processi non autorizzati)
- 🤖 **AI Classification** - 3-level strategy (Heuristics → GPT-4 Vision → GPT-4 Text)
  - Distingue uso lavorativo da personale (es: YouTube tutorial vs entertainment)
  - Confidence score 85-95%
- 🔐 **Contextual Access Control** - Justified sessions con approval workflow
  - Whitelist/blacklist app + domini
  - Budget temporali (es: 60 min YouTube/giorno)
  - Richiesta accesso con giustificazione → auto-approval o manager
- 📊 **Reports & Analytics** - Dashboard manager in [app-admin-console](app-admin-console/)
  - Report individuali e team
  - Productivity score, time budgets, violations
  - GDPR compliant: consent, audit log, data export
- 🛡️ **Zero-Trust Model** - Monitoraggio continuo con trasparenza obbligatoria

### ⚙️ Platform Services (Porta 4500-4502 + n8n)

| Servizio | Porta | Responsabilità |
|----------|-------|----------------|
| `svc-comm` | 4500 | Email/SMS transazionali |
| `svc-enrichment` | 4501 | Data enrichment APIs |
| `svc-bi` | 4502 | Business Intelligence, dashboard |
| `svc-n8n` | 5678 | Workflow automation (n8n) |

---

## Stack Tecnologico

### Backend (Microservizi)

```yaml
Runtime: Node.js 20 LTS
Language: TypeScript 5.6+
Framework: Fastify 4.28+
Database: PostgreSQL 15+
Cache: Redis 7
Validation: Zod 3.23+
Testing: Vitest 2.1+
```

**Librerie Comuni:**
- `fastify` - Web framework
- `@fastify/jwt` - JWT auth
- `pg` - PostgreSQL driver
- `zod` - Schema validation
- `ts-pattern` - Pattern matching
- `pino` - Structured logging

### Frontend (Apps)

```yaml
Framework: Next.js 14.2 (App Router)
Language: TypeScript 5.6+
UI: React 18 + TailwindCSS 3.4
State: Zustand 5 + React Query 5
Testing: Vitest
```

**Librerie UI:**
- `lucide-react` - Icon set
- `class-variance-authority` - CSS variants
- `@dnd-kit` - Drag & drop
- `@tanstack/react-query` - Data fetching

### Infrastructure

```yaml
PaaS: Scalingo (EU-West)
Storage: Wasabi S3 (EU)
CDN: Cloudflare
DNS: Cloudflare
CI/CD: GitHub Actions (in roadmap)
Monitoring: Scalingo built-in + Sentry (TODO)
```

---

## Flussi Principali

### 🔐 Autenticazione Multi-Tenant

```
1. User → POST /auth/signup
   ↓
2. svc-auth: crea org + user + membership
   ↓
3. Email verifica (svc-comm) → TODO
   ↓
4. User → POST /auth/login
   ↓
5. svc-auth: valida password, genera JWT
   ↓
6. Response: { access_token, refresh_token }
   ↓
7. Client: Authorization: Bearer <access_token>
   ↓
8. svc-api-gateway: valida JWT via JWKS
   ↓
9. Forward request a microservizio target
```

**JWT Claims:**
```json
{
  "sub": "user-uuid",
  "org_id": "org-uuid",
  "platform_role": "ADMIN",
  "tenant_role": "TENANT_ADMIN",
  "scopes": ["read:orders", "write:products"],
  "iss": "https://api.polosaas.it/auth",
  "aud": "ewh-saas",
  "exp": 1234567890
}
```

### 🛒 Order Processing Flow

```
1. app-web-frontend → POST /orders
   ↓
2. svc-api-gateway → auth check → svc-orders
   ↓
3. svc-orders: valida inventory
   ↓
4. svc-inventory: decrementa scorte (transazione)
   ↓
5. svc-billing: crea fattura + Stripe payment intent
   ↓
6. Event: order.created → Redis Stream
   ↓
7. svc-shipping: listener pickup, genera spedizione
   ↓
8. svc-comm: invia email conferma
```

### 🎨 Asset Processing Pipeline

```
1. app-web-frontend → POST /media/upload
   ↓
2. svc-media: pre-signed S3 URL
   ↓
3. Client: upload diretto a Wasabi S3
   ↓
4. Webhook S3 → svc-media
   ↓
5. Event: asset.uploaded → svc-job-worker
   ↓
6. Job: svc-image-orchestrator
   - Generate thumbnails (100x100, 300x300, 1200x1200)
   - Extract EXIF metadata
   - AI tagging (Rekognition AWS)
   ↓
7. Update svc-media database con variants
   ↓
8. CDN: Cloudflare cache invalidation
```

---

## Database & Storage

### PostgreSQL Multi-Tenant Strategy

#### Core Platform: Shared Database per Service

**Strategia Base:** Database condiviso, schema per servizio, tenant_id in ogni tabella

```sql
-- Esempio: svc-orders schema (core platform)
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.organizations(id),
  user_id UUID NOT NULL,
  status TEXT NOT NULL,
  total_amount DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policy (enabled in v2)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

#### Vertical Isolation: Multi-Tier Data Separation

**Per verticali specializzati (Real Estate, Medical, E-commerce):**

```
┌─────────────────────────────────────────────────┐
│  EWH/POLOSAS - Core Platform (Shared)          │
├─────────────────────────────────────────────────┤
│  • svc-auth       → db_auth (shared)            │
│  • svc-billing    → db_billing (shared)         │
│  • svc-api-gateway → stateless                  │
│  • app-admin      → stateless                   │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Vertical: Real Estate                          │
├─────────────────────────────────────────────────┤
│  Option A - Shared DB, Separate Schema:        │
│    db_ewh → schema: realestate_dms              │
│           → schema: realestate_crm              │
│                                                 │
│  Option B - Dedicated DB per Vertical:         │
│    db_ewh_realestate → all schemas              │
│                                                 │
│  Option C - Dedicated DB per Tenant:           │
│    db_tenant_acme_realestate → isolated         │
│                                                 │
│  Storage: s3://ewh-prod/realestate/{tenant}/    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Vertical: Medical (HIPAA Compliant)           │
├─────────────────────────────────────────────────┤
│  Mandatory: Dedicated Infrastructure            │
│    db_ewh_medical → encrypted at rest           │
│    s3://ewh-medical → separate bucket           │
│    Deployed on: separate Scalingo stack        │
└─────────────────────────────────────────────────┘
```

**Three-Tier Isolation Model:**

1. **Tier 1 - Schema Separation** (Cost-effective):
   ```sql
   -- Stesso database, schema dedicato per verticale
   CREATE SCHEMA realestate_dms;
   CREATE SCHEMA medical_dms;

   CREATE TABLE realestate_dms.documents (
     id UUID PRIMARY KEY,
     tenant_id UUID NOT NULL,
     vertical VARCHAR(50) DEFAULT 'realestate',
     -- ...
   );
   ```
   - **Use case**: Verticali low-risk, costi ridotti
   - **Compliance**: Sufficiente per GDPR base

2. **Tier 2 - Database Separation** (Balanced):
   ```yaml
   # scalingo.yml
   addons:
     - plan: postgresql:postgresql-starter-1024
       name: db-realestate
     - plan: postgresql:postgresql-starter-1024
       name: db-medical
   ```
   - **Use case**: Verticali con volumi diversi o compliance specifiche
   - **Scaling**: Indipendente per verticale
   - **Cost**: ~€30/month per DB addon

3. **Tier 3 - Tenant-Dedicated Database** (Maximum Isolation):
   ```yaml
   # For enterprise clients with strict compliance
   db-tenant-acme-medical:
     plan: postgresql-business-1024
     encryption: true
     backup_retention: 365_days
     dedicated_instance: true
   ```
   - **Use case**: Healthcare, Finance, Enterprise SLA
   - **Compliance**: HIPAA, SOC2, ISO27001 ready
   - **Cost**: €100-500/month per tenant

**Addons Scalingo (Current):**
- 39 servizi con addon PostgreSQL dedicato (core platform)
- Alcuni servizi condividono addon (media + redis)
- Backup automatici giornalieri
- **Vertical addons**: Provisioning on-demand via Scalingo API

### Object Storage (Wasabi S3)

#### Core Platform Buckets

**Standard Buckets:**
- `ewh-prod` - Produzione core platform
- `ewh-staging` - Staging
- `ewh-dev` - Sviluppo locale (MinIO)

**Struttura Core:**
```
ewh-prod/
├── media/
│   ├── {tenant-id}/
│   │   ├── images/
│   │   ├── videos/
│   │   └── documents/
├── exports/
└── backups/
```

#### Vertical-Specific Storage Isolation

**Option A - Prefix-based Separation** (Same bucket):
```
ewh-prod/
├── core/{tenant-id}/          # Core platform tenants
├── realestate/{tenant-id}/    # Real estate vertical
├── medical/{tenant-id}/       # Medical vertical (non-compliant)
└── ecommerce/{tenant-id}/     # E-commerce vertical
```
- **Pros**: Single bucket, cost-effective
- **Cons**: No physical isolation, harder compliance

**Option B - Dedicated Buckets per Vertical** (Recommended):
```
Buckets:
  - ewh-prod-core          # Core platform
  - ewh-prod-realestate    # Real estate vertical
  - ewh-prod-medical       # Medical vertical (HIPAA-compliant)
  - ewh-prod-ecommerce     # E-commerce vertical

Structure per bucket:
ewh-prod-medical/
├── {tenant-id}/
│   ├── patient-records/
│   ├── imaging/
│   └── reports/
├── encrypted-backups/
└── audit-logs/
```
- **Pros**: Physical isolation, compliance-ready, independent lifecycle
- **Cons**: Multiple buckets to manage (~$6/month each)

**Option C - Tenant-Dedicated Buckets** (Enterprise):
```
ewh-tenant-acme-medical/     # Dedicated for Acme Corp
ewh-tenant-cityhosp-medical/ # Dedicated for City Hospital
```
- **Use case**: Enterprise clients with strict data residency requirements
- **Features**: Custom retention, encryption keys, geo-location

**CDN Strategy:**
- **Core Platform**: Cloudflare in front of Wasabi for global caching
- **Verticals**: Separate CDN zones with vertical-specific caching rules
- **Medical/Sensitive**: No CDN, direct S3 access with signed URLs

---

## Sicurezza & Autenticazione

### JWT Strategy

**Access Token (15 minuti):**
- Firmato con RS256 (chiave privata `svc-auth`)
- Claims: user_id, org_id, roles, scopes
- Validato da ogni servizio tramite JWKS pubblico

**Refresh Token (30 giorni):**
- Salvato come hash Argon2 in `svc-auth` database
- Rotazione automatica a ogni refresh
- Revocabile (logout, security breach)

### Rate Limiting

- **Global:** 600 req/min per tenant (staging), 2000 req/min (prod)
- **Endpoint-specific:** login 5 req/min, signup 2 req/hour
- Implementato in `svc-api-gateway` con Redis

### Secrets Management

- **Development:** `.env` files (gitignored)
- **Production:** Scalingo environment variables
- **Sensitive:** Encrypted in `infra/scalingo-secrets.*.json` (gitignored)

**Never commit:**
- `jwk_private.pem`
- `cloudflare.env`
- `wasabi.env`
- Stripe API keys

---

## Deployment & Scalabilità

### Scalingo Deployment

#### Core Platform Deployment

**Ogni microservizio = 1 Scalingo app:**

```
ewh-prod-svc-auth     → github.com/edizioniwhtehole/svc-auth (main)
ewh-prod-svc-media    → github.com/edizioniwhtehole/svc-media (main)
ewh-stg-svc-auth      → github.com/edizioniwhtehole/svc-auth (develop)
```

**Auto-deploy:**
- Push su `main` → deploy production
- Push su `develop` → deploy staging

**Scaling:**
- Horizontal: 1-2 container per servizio
- Vertical: S (512MB) staging, M (1GB) production

#### Vertical-Specific Deployment Strategies

**Strategy A - Single Infrastructure, Multi-Tenant Routing** (Recommended for MVP):

```
┌────────────────────────────────────────┐
│   Shared Scalingo Stack                │
├────────────────────────────────────────┤
│  svc-dms (single instance)             │
│    ├─ Routes to: db_core               │
│    ├─ Routes to: db_realestate         │
│    └─ Routes to: db_medical            │
│                                        │
│  Routing logic:                        │
│    tenant.vertical → database_url      │
└────────────────────────────────────────┘
```

**Implementation:**
```typescript
// Database connection routing based on vertical
function getDatabaseUrl(tenant: Tenant): string {
  const verticalDbMap = {
    'core': process.env.DATABASE_URL_CORE,
    'realestate': process.env.DATABASE_URL_REALESTATE,
    'medical': process.env.DATABASE_URL_MEDICAL,
  }
  return verticalDbMap[tenant.vertical] || verticalDbMap['core']
}
```

**Pros:**
- Single deployment per service
- Cost-effective (~€30/month per vertical DB addon)
- Easier maintenance
- Code reuse

**Cons:**
- Single point of failure
- Shared compute resources
- All verticals deploy together

**Strategy B - Separate Infrastructure per Vertical** (Recommended for Scale):

```
Core Platform:
  ewh-prod-svc-auth      → db_auth (shared across all)
  ewh-prod-svc-billing   → db_billing (shared)
  ewh-prod-svc-gateway   → routes by vertical subdomain

Real Estate Vertical:
  ewh-prod-re-svc-dms       → db_realestate_dms
  ewh-prod-re-svc-crm       → db_realestate_crm
  ewh-prod-re-svc-projects  → db_realestate_projects
  Storage: s3://ewh-prod-realestate/

Medical Vertical:
  ewh-prod-med-svc-dms      → db_medical_dms (encrypted)
  ewh-prod-med-svc-crm      → db_medical_crm (encrypted)
  Storage: s3://ewh-prod-medical/ (HIPAA-compliant)
  Region: EU-WEST (compliance requirement)
```

**Deployment per Vertical:**
```bash
# Deploy real estate vertical services
./deploy-vertical.sh realestate production

# Deploys:
# - ewh-prod-re-svc-dms
# - ewh-prod-re-svc-crm
# - ewh-prod-re-svc-projects
# With environment variables for realestate-specific DB/storage
```

**Pros:**
- Complete isolation (security, compliance)
- Independent scaling per vertical
- Independent deployment cycles
- Vertical can fail without affecting others
- Easier to sell/spin-off a vertical

**Cons:**
- Higher infrastructure costs (~€200-400/month per vertical)
- More complex CI/CD pipeline
- Duplicate monitoring/alerting setup

**Strategy C - Hybrid Approach** (Recommended for Production):

```
Phase 1 (MVP): Strategy A
  - All verticals on shared infrastructure
  - Separate databases per vertical
  - Cost: ~€100/month

Phase 2 (Growth): Migrate high-value verticals
  - Medical → Separate infrastructure (compliance)
  - Real Estate → Separate if volume justifies
  - E-commerce → Remains shared
  - Cost: ~€300-500/month

Phase 3 (Enterprise): Tenant-specific infrastructure
  - Enterprise clients get dedicated stacks
  - White-label deployments
  - Cost: Pass-through to client
```

### Infrastructure as Code

```python
# infra/generate_scalingo_manifest.py
# Genera configurazione per tutti i 51 servizi

python3 infra/generate_scalingo_manifest.py
# Output: infra/scalingo-manifest.json
```

**DNS (Cloudflare):**
```
api.polosaas.it         → svc-api-gateway (prod)
app.polosaas.it         → app-web-frontend (prod)
admin.polosaas.it       → app-admin-console (prod)
api.staging.ewhsaas.it  → svc-api-gateway (staging)
```

### Monitoring & Observability (Roadmap v2)

- **Logs:** Structured JSON con `pino`, aggregati in Scalingo
- **Metrics:** Prometheus + Grafana (TODO)
- **Tracing:** OpenTelemetry (TODO)
- **Alerting:** Sentry error tracking (TODO)
- **Uptime:** UptimeRobot (TODO)

**Correlation ID:**
Ogni request ha `x-correlation-id` per tracciare flusso cross-service

---

## Roadmap Architetturale

### ✅ v1.0 (MVP - Completato)

**Focus:** Piattaforma funzionante per SMB (Small-Medium Business)

- [x] 50+ microservizi deployati su Scalingo
- [x] Autenticazione JWT multi-tenant
- [x] API Gateway con routing base
- [x] PostgreSQL per servizio
- [x] S3 storage (Wasabi)
- [x] Docker Compose per dev locale
- [x] Vertical isolation (3-tier: schema/database/dedicated)
- [x] Tenant migration framework documentato

**Stato:** ✅ Production-ready per SMB
**Reliability:** ~99.5% uptime (single instance)
**Target Customers:** Startup, Small Business, Freelancers

---

### 🚧 v2.0 (In Progress) - Monetization & Verticals

**Focus:** Vertical-specific features e preparazione enterprise

#### Vertical Management & Creation

**Vertical Creator (Admin Console):**
- [ ] Visual vertical builder (no-code)
  - [ ] Define vertical metadata (name, icon, color scheme)
  - [ ] Select enabled services (DMS, CRM, Projects, etc.)
  - [ ] Configure database isolation tier (schema/database/dedicated)
  - [ ] Set storage bucket strategy
  - [ ] Define default pricing plan

- [ ] Landing page editor per vertical
  - [ ] Drag-and-drop page builder (visual editor)
  - [ ] Template library (Real Estate, Medical, E-commerce)
  - [ ] Custom blocks (hero, features, pricing, testimonials)
  - [ ] SEO settings (meta tags, OpenGraph, structured data)
  - [ ] Domain mapping (custom domains per vertical)
  - [ ] Multi-language support
  - [ ] A/B testing variants
  - **Tech:** Headless CMS + `svc-site-builder`

**Base App Landing Pages:**
- [ ] Main platform landing (polosaas.it)
- [ ] Per-vertical landing pages:
  - [ ] realestate.polosaas.it
  - [ ] medical.polosaas.it
  - [ ] ecommerce.polosaas.it
- [ ] Dynamic content based on vertical
- [ ] Lead capture forms → `svc-crm`
- [ ] Analytics integration (Plausible/Google Analytics)

#### Contextual Help & Documentation System

**In-App Documentation Drawer:**
- [ ] Contextual help sidebar (slide-in drawer)
  - [ ] Context-aware: mostra docs rilevanti per pagina corrente
  - [ ] Search bar (fuzzy search su tutta la documentazione)
  - [ ] Video tutorials embedded
  - [ ] Quick links (getting started, FAQ, API docs)
  - [ ] Markdown rendering con syntax highlighting
  - **Tech:** `svc-kb` (Knowledge Base service) + Algolia search

**Widget Tooltips (Fool-Proof UI):**
- [ ] Interactive tooltips su ogni elemento UI
  - [ ] Pulsanti: "Cosa fa questo pulsante? [?]"
  - [ ] Grafici: "Come leggere questo grafico? [?]"
  - [ ] Form fields: "Cosa inserire qui? [?]"
  - [ ] Keyboard shortcuts overlay (Cmd+K)
- [ ] Onboarding tours (step-by-step walkthroughs)
  - [ ] First login tour (5-step intro)
  - [ ] Feature-specific tours (es: "Carica il tuo primo documento")
  - [ ] Progress tracking (checklist completamento)
- [ ] Inline help videos (Loom/YouTube embedded)
- [ ] "Copy to clipboard" buttons (API keys, code snippets)
- **Tech:** `@floating-ui/react` + `react-joyride` + `svc-assistant` (AI help)

**Documentation Widget System:**
```tsx
// Example: Button con tooltip contestuale
<HelpButton
  action="delete_document"
  tooltip="Elimina definitivamente il documento. Azione irreversibile."
  helpArticle="kb/documents/delete"
  videoUrl="https://help.polosaas.it/videos/delete-doc.mp4"
>
  Elimina Documento
</HelpButton>

// Example: Grafico con tooltip
<Chart
  type="bar"
  data={salesData}
  helpTooltip={{
    title: "Grafico Vendite per Regione",
    description: "Mostra il totale vendite (€) per ogni regione negli ultimi 30 giorni",
    helpArticle: "kb/analytics/sales-by-region",
    interactive: true // Mostra valori al hover
  }}
/>
```

**Help Content Management:**
- [ ] Admin panel per gestire help content
  - [ ] WYSIWYG editor per articles (Markdown)
  - [ ] Video upload/embed manager
  - [ ] Tooltip library (riutilizzabili)
  - [ ] Analytics: "Quali help sono più visualizzati?"
  - [ ] A/B testing (varianti tooltip)

**AI-Powered Help (svc-assistant):**
- [ ] Chatbot in-app (bottom-right bubble)
  - [ ] "Chiedimi qualsiasi cosa..." input
  - [ ] GPT-4 trained su documentazione EWH
  - [ ] Context-aware (sa cosa stai facendo in app)
  - [ ] Suggerimenti proattivi: "Ho notato che stai caricando molti file. Vuoi provare il bulk upload?"
  - [ ] Handoff to human support (se AI non può risolvere)

#### Internationalization (i18n) System

**Multi-Language Support:**
- [ ] Frontend UI translations (11 languages)
  - [ ] Tier 1: en, it, es, fr, de (native reviewed)
  - [ ] Tier 2: pt, nl, pl, ja, zh, ar (AI-translated)
  - [ ] next-intl integration (Next.js)
  - [ ] Language switcher component
  - [ ] RTL support (Arabic, Hebrew)

- [ ] Dynamic content translations
  - [ ] Database: JSONB multi-language fields
  - [ ] User tags, descriptions, notes → auto-translated
  - [ ] Per-tenant enabled languages
  - [ ] Translation memory cache (Redis)

- [ ] AI-Powered Auto-Translation
  - [ ] GPT-4 integration for content translation
  - [ ] Automatic translation on save
  - [ ] Batch translate existing content
  - [ ] User-editable AI translations
  - [ ] Context-aware translations (business vs technical)
  - **Cost:** €100-500/month (usage-based)

- [ ] Translation Management CMS
  - [ ] Admin panel: enable/disable languages
  - [ ] Translation editor (edit AI results)
  - [ ] Bulk translate tool with progress tracking
  - [ ] Cost estimator per tenant
  - [ ] Analytics: most viewed help articles per language

**Email & Help Content i18n:**
- [ ] Email templates per language
- [ ] Help articles translation (11 languages)
- [ ] Video subtitles (AI-generated)
- [ ] Landing pages per vertical + language
  - Example: realestate.polosaas.it/it
            medical.polosaas.it/de

**Tech Stack:**
- `next-intl` (Frontend UI)
- `OpenAI GPT-4 Turbo` (AI translation)
- `Redis` (Translation cache)
- `JSONB` (Multi-language DB fields)
- **Effort:** 9 weeks

#### Core Technical Features

- [ ] Vertical plugins (Real Estate, Medical, E-commerce)
- [ ] Tenant migration control panel (visual, no-code)
- [ ] Scalingo API integration (automated provisioning)
- [ ] Event-driven architecture (Redis Streams)
- [ ] RLS PostgreSQL enforcement
- [ ] API versioning (v1, v2)

**Timeline:** 5-6 mesi (extended per landing pages + help + i18n)
**Stato:** 📝 Documented, ready for implementation
**Target Customers:** Growing SMB, vertical-specific businesses, global expansion

---

### 🔮 v2.5 (Next 6 Months) - Enterprise Foundations

**Focus:** Enterprise-Grade reliability e security

#### Critical (Deal-breakers for Enterprise)

**Backup & Disaster Recovery:**
- [ ] WAL archiving con Point-in-Time Recovery (PITR 5 min)
- [ ] Cross-region replication (EU-WEST + US-EAST)
- [ ] Automated backup testing (monthly)
- [ ] Disaster recovery runbook + quarterly drills
- [ ] Retention: 30d/90d/12m/7y (compliance)
- **Effort:** 3 weeks | **Cost:** +€100/month

**High Availability (99.99% SLA):**
- [ ] Multi-container deployment (min 2 instances)
- [ ] PostgreSQL HA cluster (automatic failover)
- [ ] Read replicas (2x per vertical)
- [ ] Health checks + graceful shutdown
- [ ] Zero-downtime deployments
- **Effort:** 6 weeks | **Cost:** +€400/month

**Security & Compliance:**
- [ ] Multi-Factor Authentication (MFA) - TOTP, WebAuthn
- [ ] Single Sign-On (SSO) - SAML, OAuth, LDAP
- [ ] Secrets management (HashiCorp Vault)
- [ ] Vulnerability scanning (Snyk, automated)
- [ ] Penetration testing (quarterly)
- [ ] Security headers (CSP, HSTS)
- **Effort:** 8 weeks | **Cost:** +€100/month

**Audit Logging (Immutable):**
- [ ] Append-only audit trail (PostgreSQL + S3)
- [ ] HMAC signatures per integrity verification
- [ ] 7-year retention (S3 Object Lock)
- [ ] Compliance reporting (GDPR, HIPAA)
- [ ] Anomaly detection alerts
- **Effort:** 3 weeks | **Cost:** +€50/month

#### High Priority (Competitive Advantage)

**Monitoring & Observability:**
- [ ] Centralized logging (Datadog/New Relic)
- [ ] Distributed tracing (OpenTelemetry)
- [ ] APM (Application Performance Monitoring)
- [ ] AI-powered anomaly detection
- [ ] Custom dashboards per vertical
- [ ] PagerDuty integration (on-call)
- **Effort:** 4 weeks | **Cost:** +€400/month

**Advanced RBAC:**
- [ ] Fine-grained permissions (resource-level)
- [ ] Custom role builder (UI)
- [ ] Attribute-based access control (ABAC)
- [ ] Permission conditions (e.g., order.amount < €10k)
- [ ] Role templates per vertical
- **Effort:** 4 weeks | **Cost:** €0

#### Medium Priority (Nice-to-have)

**Data Residency & Multi-Region:**
- [ ] Multi-region deployment (EU/US/APAC)
- [ ] Per-tenant data residency selection
- [ ] Cross-region failover (automatic)
- [ ] Geo-routing (Cloudflare)
- **Effort:** 4 weeks | **Cost:** +€500/month

**White-Label & Multi-Brand:**
- [ ] Custom domains per tenant
- [ ] Branded UI (logo, colors, fonts)
- [ ] Custom email templates
- [ ] Whitelabel mobile apps
- **Effort:** 4 weeks | **Cost:** €0

**Performance & Auto-Scaling:**
- [ ] Redis caching layer (query results)
- [ ] CDN optimization (Cloudflare Workers)
- [ ] Database query optimization
- [ ] Horizontal auto-scaling (CPU-based)
- [ ] Connection pooling (PgBouncer)
- **Effort:** 6 weeks | **Cost:** +€200/month

**Timeline:** 6 mesi (con 2 FTE)
**Investment:** ~€240k (personnel + infrastructure)
**ROI:** Break-even con 40 clienti enterprise (€12k/mese)

---

### 🏆 v3.0 (9-12 Months) - Enterprise-Grade Certification

**Focus:** SOC 2, HIPAA, ISO 27001 compliance

**Compliance Certifications:**
- [ ] SOC 2 Type II audit (6-9 mesi)
  - [ ] Security officer designated
  - [ ] Policy documentation (60+ policies)
  - [ ] Evidence collection (3-6 mesi)
  - [ ] External audit (Deloitte, PwC)
  - **Cost:** €50k-80k one-time

- [ ] HIPAA compliance (Medical vertical)
  - [ ] Business Associate Agreements (BAA)
  - [ ] PHI data classification
  - [ ] Automatic PHI detection (ML)
  - [ ] Breach notification workflow
  - [ ] Annual risk assessment
  - **Cost:** €30k one-time + €10k/year

- [ ] ISO 27001 (optional)
  - [ ] ISMS (Information Security Management System)
  - [ ] Risk assessment framework
  - [ ] Annual surveillance audit
  - **Cost:** €40k one-time + €15k/year

**Enterprise Features:**
- [ ] 99.99%+ uptime SLA (contractual)
- [ ] 24/7 support (P1: 15 min response)
- [ ] Dedicated success manager
- [ ] Custom SLA agreements
- [ ] Legal: Master Service Agreement (MSA)
- [ ] Legal: Data Processing Agreement (DPA)

**Target Customers:** Fortune 500, Healthcare, Finance, Government

**Timeline:** 9-12 mesi
**Investment:** €150k-250k (audit + legal + infrastructure)

---

### 🚀 v4.0 (Future) - Scale & Innovation

**Focus:** Hyperscale infrastructure e AI-native

**Infrastructure Evolution:**
- [ ] Kubernetes migration (da Scalingo)
- [ ] Service mesh (Istio/Linkerd)
- [ ] Multi-cloud (AWS + GCP + Azure)
- [ ] CQRS + Event Sourcing pattern
- [ ] gRPC inter-service communication
- [ ] Edge computing (Cloudflare Workers)

**AI-Native Features:**
- [ ] AI-powered content generation (GPT-4)
- [ ] Intelligent document classification
- [ ] Predictive analytics (churn, revenue)
- [ ] Natural language search
- [ ] Auto-tagging e metadata extraction

**Advanced Capabilities:**
- [ ] Real-time collaboration (CRDT)
- [ ] Blockchain audit trail (immutable proof)
- [ ] Quantum-safe encryption
- [ ] GraphQL federation (Apollo)
- [ ] OpenID Connect SSO

**Timeline:** 18-24 mesi
**Prerequisite:** Product-market fit, €5M+ ARR

---

## 📚 Documentazione per AI Agents

Questa piattaforma è progettata per essere sviluppata da team umani + AI agents coordinati.

**Documentazione Coordinamento AI:**
- **[CONTEXT_INDEX.md](CONTEXT_INDEX.md)** - ⚡ Indice rapido (LEGGI PER PRIMO)
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - 📊 Stato attuale di tutti i servizi
- **[MASTER_PROMPT.md](MASTER_PROMPT.md)** - 🎯 Istruzioni universali per agenti
- **[GUARDRAILS.md](GUARDRAILS.md)** - 🚦 Regole coordinamento e workflow
- **[.ai/context.json](.ai/context.json)** - 💾 Cache compatta stato progetto

**Ogni servizio ha:**
- `{service}/PROMPT.md` - Istruzioni specifiche per agenti
- `{service}/README.md` - Documentazione utente
- `{service}/docs/ENV.md` - Variabili ambiente

## Contribuire

Per contribuire all'architettura:

1. **Se sei un AI Agent:**
   - Leggi [MASTER_PROMPT.md](MASTER_PROMPT.md) per istruzioni complete
   - Segui workflow in [GUARDRAILS.md](GUARDRAILS.md)
   - Aggiorna [PROJECT_STATUS.md](PROJECT_STATUS.md) dopo ogni modifica

2. **Se sei uno sviluppatore umano:**
   - Leggi [CONTRIBUTING.md](CONTRIBUTING.md)
   - Proponi modifiche via Architecture Decision Record (ADR)
   - Discuti in team review prima di implementare breaking changes

## Riferimenti

**Documentazione Progetto:**
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - Stato implementazione servizi
- [CONTEXT_INDEX.md](CONTEXT_INDEX.md) - Indice rapido per trovare info
- [README.md](README.md) - Setup monorepo
- [DEVELOPMENT.md](DEVELOPMENT.md) - Workflow sviluppo
- [DEPLOYMENT.md](DEPLOYMENT.md) - Processo deploy

**Feature-Specific Docs:**
- [DAM_APPROVAL_CHANGELOG.md](DAM_APPROVAL_CHANGELOG.md) - DAM development log
- [HR_SYSTEM_COMPLETE.md](HR_SYSTEM_COMPLETE.md) - HR system guide
- [ACTIVITY_TRACKING_INTEGRATION.md](ACTIVITY_TRACKING_INTEGRATION.md) - Activity tracking

**External Resources:**
- [Scalingo Docs](https://doc.scalingo.com/)
- [Fastify Best Practices](https://fastify.dev/docs/latest/Guides/Getting-Started/)

---

**Ultimo aggiornamento:** 2025-10-04
**Maintainer:** Team EWH Platform

> 💡 **Nota per AI Agents:** Questo documento descrive l'architettura *pianificata*. Per lo stato *attuale* di implementazione, consultare [PROJECT_STATUS.md](PROJECT_STATUS.md).
