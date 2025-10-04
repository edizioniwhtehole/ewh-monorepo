# EWH Platform - Context Index

> **Indice rapido per trovare informazioni velocemente - LEGGERE SEMPRE PER PRIMO**

**Versione:** 1.0.0
**Target:** AI Agents che operano sulla codebase
**Obiettivo:** Trovare informazioni in < 2 minuti senza leggere migliaia di righe

---

## 🎯 Quick Navigation

| Domanda | Documento | Tempo Lettura |
|---------|-----------|---------------|
| Qual è lo stato del progetto? | [PROJECT_STATUS.md](PROJECT_STATUS.md) | 5 min |
| Come devo lavorare? | [MASTER_PROMPT.md](MASTER_PROMPT.md) | 10 min |
| Quali sono le regole? | [GUARDRAILS.md](GUARDRAILS.md) | 10 min |
| Com'è l'architettura? | [ARCHITECTURE.md](ARCHITECTURE.md) | 15 min |
| Come è strutturato X servizio? | `{service}/PROMPT.md` | 3-5 min |
| Dove trovo esempi di codice? | [Esempi](#esempi-di-codice) ⬇️ | 2 min |
| Specifiche DAM/HR/Frontend? | [Feature-Specific Docs](#-feature-specific-documentation) ⬇️ | 5-10 min |

---

## 📊 Stato Servizi - Quick Reference

### ✅ Production Ready (Usabili Ora)

| Servizio | Porta | Cosa Fa | Link |
|----------|-------|---------|------|
| **svc-auth** | 4001 | Autenticazione JWT multi-tenant | [Details](PROJECT_STATUS.md#-svc-auth-4001---production-ready) |
| **svc-api-gateway** | 4000 | Routing e proxy requests | [Details](PROJECT_STATUS.md#-svc-api-gateway-4000---production-ready) |

**Se devi chiamare uno di questi servizi:** ✅ Vai tranquillo, sono implementati e funzionanti

### 🚧 In Development (Parzialmente Funzionanti)

| Servizio | Porta | Stato | Cosa Funziona | Cosa Manca |
|----------|-------|-------|---------------|------------|
| **svc-timesheet** | 4407 | 60% | Activity tracking API, HR CRUD, Attendance | AI classification, S3 screenshots |
| **app-web-frontend** | 3100 | 30% | DAM UI completa, HR pages base | Backend integration, Real upload |

**Se devi usare questi:** ⚠️ Verificare in [PROJECT_STATUS.md](PROJECT_STATUS.md) cosa è implementato

### 📝 Scaffolding Only (DA IMPLEMENTARE)

**Tutti gli altri 41 servizi** hanno solo health check + 501 responses.

**Lista completa:**
- Creative Services (11): image-orchestrator, job-worker, writer, content, layout, prepress, vector-lab, mockup, video-orchestrator, video-runtime, raster-runtime
- Publishing Services (6): projects, search, site-builder, site-renderer, site-publisher, connectors-web
- ERP Services (9): products, orders, inventory, channels, quotation, procurement, mrp, shipping, crm
- Collaboration (10): pm, support, chat, boards, kb, collab, dms, forms, forum, assistant
- Platform (3): comm, enrichment, bi
- Core (3): plugins, media, billing

**Se devi usare uno di questi:** ❌ Bloccare o usare mock data + TODO

---

## 🗺️ Service Map - Dove Trovare Cosa

### Autenticazione & Sicurezza
- **Login/Signup:** [svc-auth](svc-auth/) → `POST /api/v1/auth/login`
- **Token Refresh:** [svc-auth](svc-auth/) → `POST /api/v1/auth/refresh`
- **JWKS Public Key:** [svc-auth](svc-auth/) → `GET /.well-known/jwks.json`
- **Validazione JWT:** Tutti i servizi usano JWKS da svc-auth

### User & Organization Management
- **User CRUD:** [svc-auth](svc-auth/) → `/api/v1/users`
- **Organization CRUD:** [svc-auth](svc-auth/) → `/api/v1/organizations`
- **Membership:** [svc-auth](svc-auth/) → `/api/v1/memberships`

### Asset Management (⚠️ INCOMPLETE)
- **Upload:** [svc-media](svc-media/) → `POST /api/v1/media/upload` (❌ TODO)
- **Download:** [svc-media](svc-media/) → `GET /api/v1/media/{id}` (❌ TODO)
- **Thumbnails:** [svc-image-orchestrator](svc-image-orchestrator/) (❌ TODO)
- **DAM UI:** [app-web-frontend](app-web-frontend/) → `/dam` (✅ UI completa, ❌ backend missing)

### HR & Timesheet
- **Employees:** [svc-timesheet](svc-timesheet/) → `/api/v1/employees` (✅ CRUD completo)
- **Attendance:** [svc-timesheet](svc-timesheet/) → `/api/v1/attendance` (✅ Check-in/out completo)
- **Activity Tracking:** [svc-timesheet](svc-timesheet/) → `/api/v1/activity/heartbeat` (🚧 API pronta, AI TODO)

### E-Commerce (❌ ALL TODO)
- **Products:** [svc-products](svc-products/) → `/api/v1/products` (❌ TODO)
- **Orders:** [svc-orders](svc-orders/) → `/api/v1/orders` (❌ TODO)
- **Inventory:** [svc-inventory](svc-inventory/) → `/api/v1/inventory` (❌ TODO)
- **Billing:** [svc-billing](svc-billing/) → `/api/v1/invoices` (❌ TODO)

### Communication (❌ ALL TODO)
- **Email:** [svc-comm](svc-comm/) → `/api/v1/email/send` (❌ TODO - BLOCCANTE per password recovery)
- **SMS:** [svc-comm](svc-comm/) → `/api/v1/sms/send` (❌ TODO)

---

## 🔗 Dipendenze Tra Servizi

### Grafo Dipendenze Implementate

```
app-web-frontend
  └─▶ svc-api-gateway (proxy)
        ├─▶ svc-auth (JWT validation via JWKS) ✅
        └─▶ svc-timesheet (activity API) 🚧

svc-api-gateway
  └─▶ svc-auth (JWKS endpoint) ✅

svc-timesheet
  ├─▶ svc-auth (JWT validation) ✅
  ├─▶ PostgreSQL ✅
  ├─▶ S3 Wasabi (screenshots) ❌ TODO
  ├─▶ OpenAI API (classification) ❌ TODO
  └─▶ Redis Streams (events) ❌ TODO

ewh-work-agent (desktop)
  └─▶ svc-timesheet (heartbeat API) ✅
```

### Dipendenze Bloccanti (Non Implementate)

```
DAM Workflow (BLOCCATO):
app-web-frontend (DAM UI)
  └─▶ svc-media ❌ MISSING
        └─▶ svc-image-orchestrator ❌ MISSING
              └─▶ svc-job-worker ❌ MISSING

Order Flow (NON IMPLEMENTATO):
svc-orders
  ├─▶ svc-products ❌ MISSING
  ├─▶ svc-inventory ❌ MISSING
  ├─▶ svc-billing ❌ MISSING
  └─▶ svc-shipping ❌ MISSING

Password Recovery (BLOCCATO):
svc-auth
  └─▶ svc-comm ❌ MISSING (send email endpoint)
```

**Se vedi dipendenza ❌ MISSING:** Bloccare o usare mock + TODO

---

## 📁 File Structure - Dove Trovare Cosa

### Root Directory
```
/
├── ARCHITECTURE.md          # System architecture overview
├── PROJECT_STATUS.md        # Current implementation status
├── GUARDRAILS.md            # Agent coordination rules
├── MASTER_PROMPT.md         # Universal agent instructions
├── CONTEXT_INDEX.md         # This file
├── DAM_APPROVAL_CHANGELOG.md    # DAM feature development log
├── HR_SYSTEM_COMPLETE.md        # HR system documentation
├── ACTIVITY_TRACKING_INTEGRATION.md  # Activity tracking guide
├── svc-*/                   # Backend microservices (45)
├── app-*/                   # Frontend applications (5)
├── ewh-work-agent/          # Desktop agent (Electron)
├── ops-infra/               # Infrastructure scripts
└── scripts/                 # Utility scripts
```

### Servizio Backend (svc-*)
```
svc-{nome}/
├── PROMPT.md               # ⭐ Agent instructions (READ FIRST!)
├── README.md               # User documentation
├── package.json            # Dependencies
├── tsconfig.json           # TypeScript config
├── src/
│   ├── app.ts             # Fastify server setup
│   ├── routes/            # API endpoints
│   │   └── {resource}.ts  # CRUD routes
│   ├── services/          # Business logic
│   │   └── {service}.ts
│   ├── db/
│   │   ├── client.ts      # PostgreSQL client
│   │   └── schema.ts      # TypeScript types
│   └── types/
│       └── index.ts       # Shared types
├── migrations/            # SQL migrations
│   └── 001_{name}.sql
├── tests/                 # Test files
│   ├── routes/
│   └── services/
└── docs/
    └── ENV.md             # Environment variables
```

### Frontend App (app-*)
```
app-{nome}/
├── PROMPT.md              # ⭐ Agent instructions
├── README.md              # User documentation
├── package.json
├── tsconfig.json
├── tailwind.config.js
├── next.config.js
├── src/
│   ├── app/               # Next.js App Router
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/        # React components
│   ├── modules/           # Feature modules
│   ├── stores/            # Zustand stores
│   ├── hooks/             # Custom hooks
│   ├── types/             # TypeScript types
│   └── lib/               # Utilities
└── public/                # Static assets
```

---

## 🔍 Come Trovare Informazioni

### Scenario 1: "Devo implementare feature X"

```typescript
// Step 1: Trovare servizio responsabile (2 min)
// Leggi questa sezione "Service Map" sopra ⬆️

// Step 2: Verificare stato servizio (2 min)
// Vai a PROJECT_STATUS.md → Cerca "{service-name}"
// Guarda stato: ✅ Complete / 🚧 In Progress / 📝 Scaffold

// Step 3: Leggere istruzioni specifiche (3 min)
// Apri {service}/PROMPT.md

// Step 4: Verificare dipendenze (2 min)
// Torna qui sopra ⬆️ a "Grafo Dipendenze"

// Step 5: Iniziare implementazione
// Segui MASTER_PROMPT.md e GUARDRAILS.md
```

**Totale tempo:** ~10 minuti analisi → Poi inizia a codificare

### Scenario 2: "Il servizio X chiama Y ma Y non esiste"

```typescript
// Problema: Dipendenza bloccante

// Step 1: Verificare in "Dipendenze Bloccanti" sopra ⬆️
// Se presente → Problema noto, seguire strategia mock

// Step 2: Se non presente → Aggiungere a PROJECT_STATUS.md
// Sezione "Blocchi Critici Attuali"

// Step 3: Decidere strategia:
// Opzione A: Bloccare feature fino a implementazione Y
// Opzione B: Usare mock data + TODO con tracking issue

// Step 4: Documentare decisione in codice
/**
 * TODO(@future-agent): Replace with real svc-products API
 * Blocked by: svc-products not implemented (scaffolding only)
 * Tracked in: PROJECT_STATUS.md → svc-products → Priority: Alta
 * ETA: Q1 2026
 */
const product = MOCK_PRODUCT_DATA
```

### Scenario 3: "Dove trovo esempi di codice?"

Vai alla sezione [Esempi di Codice](#-esempi-di-codice) sotto ⬇️

---

## 💻 Esempi di Codice

### Esempio 1: Endpoint CRUD Completo

**File:** [svc-auth/src/routes/auth.ts](svc-auth/src/routes/auth.ts) (46KB)

Miglior esempio di:
- ✅ Authentication middleware
- ✅ Input validation con Zod
- ✅ Error handling
- ✅ Multi-tenancy
- ✅ JWT generation
- ✅ Structured logging

### Esempio 2: Migration Database

**File:** [svc-timesheet/migrations/002_hr_system.sql](svc-timesheet/migrations/002_hr_system.sql)

Miglior esempio di:
- ✅ Table creation con tenant_id
- ✅ RLS policies
- ✅ Indexes ottimizzati
- ✅ Triggers per calcoli automatici
- ✅ Foreign keys e constraints

### Esempio 3: Frontend Component Avanzato

**File:** [app-web-frontend/src/modules/dam/approval/ApprovalSlideshow.tsx](app-web-frontend/src/modules/dam/approval/ApprovalSlideshow.tsx)

Miglior esempio di:
- ✅ React hooks complessi
- ✅ Keyboard shortcuts
- ✅ State management locale
- ✅ TailwindCSS styling
- ✅ Component composition

### Esempio 4: Service Integration

**File:** [svc-api-gateway/src/index.ts](svc-api-gateway/src/index.ts) (204 righe)

Miglior esempio di:
- ✅ HTTP proxy con Fastify
- ✅ JWT validation via JWKS
- ✅ CORS handling
- ✅ Header forwarding
- ✅ Correlation ID tracking

### Esempio 5: Test Suite

**File:** [svc-auth/tests/routes/auth.test.ts](svc-auth/tests/routes/auth.test.ts) (se esiste)

Miglior esempio di:
- ✅ Unit testing con Vitest
- ✅ Integration testing
- ✅ Mocking external services
- ✅ Test tenant isolation

---

## 🚀 Quick Start per Task Comuni

### Task: Implementare Nuovo Endpoint

```typescript
// 1. Verificare servizio in PROJECT_STATUS.md (2 min)
// 2. Leggere {service}/PROMPT.md (3 min)
// 3. Copiare template da MASTER_PROMPT.md (2 min)
// 4. Implementare endpoint seguendo pattern (30-60 min)
// 5. Scrivere test (15-30 min)
// 6. Aggiornare documentazione (5 min)

// Template endpoint: MASTER_PROMPT.md → "Pattern 1: Endpoint CRUD Base"
```

### Task: Aggiungere Migration Database

```sql
-- 1. Creare file: {service}/migrations/00X_{nome}.sql
-- 2. Copiare template da svc-timesheet/migrations/002_hr_system.sql
-- 3. Modificare per il tuo caso
-- 4. SEMPRE includere:
--    - tenant_id in OGNI tabella
--    - RLS policy
--    - Indexes su tenant_id, created_at
--    - Trigger per updated_at
-- 5. Testare: docker exec -i ewh_postgres psql -U ewh -d ewh_master < migration.sql
```

### Task: Chiamare Servizio Esterno

```typescript
// 1. Verificare dipendenza in CONTEXT_INDEX.md → "Grafo Dipendenze"
// 2. Se ❌ MISSING → Usare mock + TODO
// 3. Se ✅ Implementato → Usare pattern da MASTER_PROMPT.md → "Pattern 2: Service Call"

// Template service call:
// MASTER_PROMPT.md → "Pattern 2: Service-to-Service Call"
```

### Task: Aggiungere Frontend Component

```typescript
// 1. Decidere dove: app-web-frontend/src/components/ o /modules/
// 2. Copiare pattern da ApprovalSlideshow.tsx (esempio avanzato)
// 3. Usare SEMPRE:
//    - React hooks (non class)
//    - TailwindCSS (no styled-components)
//    - Zod per validation
//    - TypeScript strict
// 4. Test: Vitest + React Testing Library
```

---

## 🎯 Priorità Implementazione (Q4 2025)

### 🔴 CRITICHE (Blockers)

1. **svc-media** (3 settimane) - Blocca DAM workflow
2. **svc-comm** (2 settimane) - Blocca password recovery
3. **Rate limiting in gateway** (1 settimana) - Sicurezza produzione

### 🟡 IMPORTANTI

4. **svc-timesheet completamento** (3 settimane) - AI classification + S3
5. **Frontend-Backend integration** (4 settimane) - Connettere DAM UI a svc-media
6. **svc-image-orchestrator** (3 settimane) - Pipeline thumbnails
7. **svc-job-worker** (2 settimane) - Background jobs

### 🟢 DESIDERABILI

8. **svc-products** (4 settimane) - Catalogo prodotti
9. **svc-orders** (5 settimane) - Order management
10. **svc-chat** (3 settimane) - Real-time messaging

**Per dettagli:** [PROJECT_STATUS.md → Roadmap](PROJECT_STATUS.md#-roadmap--priorità)

---

## 📋 Feature-Specific Documentation

**Quando lavori su feature specifiche, leggi ANCHE questi file:**

### DAM (Digital Asset Management)
- [DAM_APPROVAL_CHANGELOG.md](DAM_APPROVAL_CHANGELOG.md) - Changelog approval workflow
- [app-web-frontend/DAM_PERMISSIONS_SPECS.md](app-web-frontend/DAM_PERMISSIONS_SPECS.md) - Sistema permessi
- [app-web-frontend/DAM_ENTERPRISE_SPECS.md](app-web-frontend/DAM_ENTERPRISE_SPECS.md) - Specifiche enterprise

### HR & Timesheet
- [HR_SYSTEM_COMPLETE.md](HR_SYSTEM_COMPLETE.md) - Sistema HR completo (attendance, leave, etc.)
- [ACTIVITY_TRACKING_INTEGRATION.md](ACTIVITY_TRACKING_INTEGRATION.md) - Activity tracking + screenshots

### Frontend
- [app-web-frontend/APP_CONTEXT.md](app-web-frontend/APP_CONTEXT.md) - Context generale frontend
- [app-web-frontend/CODEBASE_REFERENCE.md](app-web-frontend/CODEBASE_REFERENCE.md) - Reference codebase
- [app-web-frontend/ADMIN_PANEL_QUICKSTART.md](app-web-frontend/ADMIN_PANEL_QUICKSTART.md) - Admin panel guide

**Quando leggere:**
- DAM docs → se task menziona "asset", "media", "upload", "approval"
- HR docs → se task menziona "employee", "attendance", "leave", "timesheet"
- Frontend docs → se task su app-web-frontend

---

## 📞 Quick Links - Documentazione Esterna

### Stack Tecnologico

**Backend:**
- [Fastify Docs](https://fastify.dev/docs/latest/) - Web framework
- [Zod](https://zod.dev/) - Schema validation
- [Pino](https://getpino.io/) - Logging
- [node-postgres](https://node-postgres.com/) - PostgreSQL client
- [Vitest](https://vitest.dev/) - Testing framework

**Frontend:**
- [Next.js Docs](https://nextjs.org/docs) - React framework (App Router)
- [React 18](https://react.dev/) - UI library
- [TailwindCSS](https://tailwindcss.com/docs) - Styling
- [Zustand](https://zustand-demo.pmnd.rs/) - State management
- [TanStack Query](https://tanstack.com/query/latest) - Data fetching

**Infrastructure:**
- [Scalingo Docs](https://doc.scalingo.com/) - PaaS deployment
- [PostgreSQL 15](https://www.postgresql.org/docs/15/) - Database
- [Redis](https://redis.io/docs/) - Caching & queues (planned)
- [Wasabi](https://wasabi.com/s3-api/) - S3-compatible storage

---

## ❓ FAQ Lightning Round

**Q: Da dove inizio se ho un task?**
A: Leggi questo file → PROJECT_STATUS.md → servizio PROMPT.md → MASTER_PROMPT.md

**Q: Servizio esiste?**
A: Controlla tabella "Stato Servizi" sopra ⬆️

**Q: Dipendenza mancante?**
A: Guarda "Grafo Dipendenze" → Se ❌ usa mock + TODO

**Q: Dove copio esempi?**
A: Sezione "Esempi di Codice" sopra ⬆️

**Q: Test necessari?**
A: ✅ SÌ, sempre (min 60% coverage)

**Q: Posso usare altra libreria?**
A: ❌ NO, segui tech stack in MASTER_PROMPT.md

**Q: Conflitto con altro agente?**
A: Lock file + coordinate in PROJECT_STATUS.md → "Work in Progress"

**Q: Breaking change necessario?**
A: Creare v2 endpoint, deprecare v1 (vedi GUARDRAILS.md)

**Q: Produzione rotta dopo deploy?**
A: `git revert` + incident report (vedi GUARDRAILS.md → Rollback)

**Q: Documentazione da aggiornare?**
A: Sempre: PROJECT_STATUS.md + servizio PROMPT.md + README.md

---

## 🔄 Questo File È Vecchio?

**Ultimo aggiornamento:** 2025-10-04
**Prossima revisione:** 2025-10-18 (bi-weekly)

**Come verificare se aggiornato:**

```bash
# Check ultima modifica
git log -1 --format="%ai %an" CONTEXT_INDEX.md

# Se > 2 settimane fa → Probabilmente outdated
# Verifica PROJECT_STATUS.md per stato attuale
```

**Come aggiornare:**

1. Leggi PROJECT_STATUS.md per nuovi cambiamenti
2. Aggiorna sezioni "Stato Servizi" e "Dipendenze"
3. Aggiorna "Priorità Implementazione"
4. Incrementa versione in header
5. Commit: `docs: update CONTEXT_INDEX.md with latest status`

---

**Versione:** 1.0.0
**Maintainer:** Tech Lead Team
**Feedback:** GitHub issue con label "context-index"

---

## 🎉 Hai Finito di Leggere!

**Prossimi Step:**

1. ✅ Hai letto CONTEXT_INDEX.md (questo file)
2. ➡️ Leggi [PROJECT_STATUS.md](PROJECT_STATUS.md) per stato dettagliato
3. ➡️ Leggi [MASTER_PROMPT.md](MASTER_PROMPT.md) per istruzioni coding
4. ➡️ Leggi [GUARDRAILS.md](GUARDRAILS.md) per regole coordinamento
5. ➡️ Leggi `{service}/PROMPT.md` del servizio su cui lavori
6. 🚀 Inizia a codificare!

**Tempo totale lettura documentazione:** ~30 minuti
**Tempo risparmiato evitando errori:** ♾️ ore

Buon lavoro! 💪
