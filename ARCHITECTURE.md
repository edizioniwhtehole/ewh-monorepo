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
| `svc-timesheet` | 4407 | Timesheet, ore lavoro |
| `svc-forms` | 4408 | Form builder dinamici |
| `svc-forum` | 4409 | Forum community |
| `svc-assistant` | 4410 | AI Assistant (GPT-4) |

**Real-time:**
- WebSocket per chat e collab
- Operational Transform per editing collaborativo

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

### PostgreSQL Multi-Tenant

**Strategia:** Database condiviso, schema per servizio, tenant_id in ogni tabella

```sql
-- Esempio: svc-orders schema
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

**Addons Scalingo:**
- 39 servizi con addon PostgreSQL dedicato
- Alcuni servizi condividono addon (media + redis)
- Backup automatici giornalieri

### Object Storage (Wasabi S3)

**Buckets:**
- `ewh-prod` - Produzione
- `ewh-staging` - Staging
- `ewh-dev` - Sviluppo locale (MinIO)

**Struttura:**
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

**CDN:** Cloudflare in front di Wasabi per caching globale

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

- [x] 50+ microservizi deployati su Scalingo
- [x] Autenticazione JWT multi-tenant
- [x] API Gateway con routing base
- [x] PostgreSQL per servizio
- [x] S3 storage (Wasabi)
- [x] Docker Compose per dev locale

### 🚧 v2.0 (In Progress)

- [ ] Event-driven architecture (Redis Streams)
- [ ] RLS PostgreSQL enforcement
- [ ] Monitoring & observability (Sentry, Grafana)
- [ ] CI/CD automatizzato (GitHub Actions)
- [ ] API versioning (v1, v2)
- [ ] GraphQL federation (Apollo)

### 🔮 v3.0 (Future)

- [ ] Service mesh (Istio/Linkerd)
- [ ] Kubernetes migration
- [ ] Multi-region deployment
- [ ] CQRS + Event Sourcing pattern
- [ ] gRPC inter-service communication
- [ ] OpenID Connect SSO

---

## Contribuire

Per contribuire all'architettura:

1. Leggi [CONTRIBUTING.md](CONTRIBUTING.md)
2. Proponi modifiche via Architecture Decision Record (ADR)
3. Discuti in team review prima di implementare breaking changes

## Riferimenti

- [README.md](README.md) - Setup monorepo
- [DEVELOPMENT.md](DEVELOPMENT.md) - Workflow sviluppo
- [DEPLOYMENT.md](DEPLOYMENT.md) - Processo deploy
- [Scalingo Docs](https://doc.scalingo.com/)
- [Fastify Best Practices](https://fastify.dev/docs/latest/Guides/Getting-Started/)

---

**Ultimo aggiornamento:** 2025-10-01
**Maintainer:** Team EWH Platform
