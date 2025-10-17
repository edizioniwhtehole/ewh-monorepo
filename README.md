# EWH Platform - Enterprise Web Hypervisor

> Multi-tenant SaaS platform per gestione aziendale completa: PM, CRM, DAM, Orders, Inventory e molto altro.

![License](https://img.shields.io/badge/license-Proprietary-red.svg)
[![Database](https://img.shields.io/badge/Database-PostgreSQL%20%2B%20Supabase-green.svg)](https://supabase.com)
[![Storage](https://img.shields.io/badge/Storage-Wasabi-orange.svg)](https://wasabi.com)
[![Node](https://img.shields.io/badge/node-20.x-green.svg)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/typescript-5.6+-blue.svg)](https://typescriptlang.org)

---

## 🔴 CRITICAL: Plugin-First Architecture

> **ALL services and applications MUST follow Plugin-First Architecture.**
>
> **Core = Minimal infrastructure only. Features = Plugins.**
>
> 📖 **Read this BEFORE coding ANY feature:** [PLUGIN_FIRST_ARCHITECTURE.md](docs/architecture/PLUGIN_FIRST_ARCHITECTURE.md)
>
> See also: [PLATFORM_STANDARDS.md](docs/infrastructure/PLATFORM_STANDARDS.md) - Section 0

---

## 📚 Documentazione

### 🗺️ Navigation
- **🤖 [AGENTS.md](AGENTS.md)** - **AI Agents start here!** Essential rules & quick links
- **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** - 🔍 **Complete documentation index**

### Core Documentation
- **[SETUP_COMPLETE_SUMMARY.md](SETUP_COMPLETE_SUMMARY.md)** - ✅ Riepilogo setup completo (START HERE!)
- **[ARCHITECTURE_TIERED_SCALING.md](ARCHITECTURE_TIERED_SCALING.md)** - Architettura 6-tier progressive scaling
- **[ADMIN_SETUP_INSTRUCTIONS.md](ADMIN_SETUP_INSTRUCTIONS.md)** - Setup admin panel (roadmap + task board)
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architettura microservizi legacy
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Setup ambiente, workflow sviluppo, testing, debugging

### Version Management 🆕
- **🔴 [VERSIONING_STRATEGY.md](docs/infrastructure/VERSIONING_STRATEGY.md)** - **CRITICAL:** Complete versioning strategy
- **[VERSION_TRACKING.md](VERSION_TRACKING.md)** - Central version registry (all components)
- **[VERSIONING_SYSTEM_COMPLETE.md](VERSIONING_SYSTEM_COMPLETE.md)** - Implementation summary
- **[scripts/README.md](scripts/README.md)** - Automation scripts documentation

## 🏗️ Architettura

### Database Strategy (NEW! 2025)

**Progressive Scaling Architecture** - Schema-per-servizio con tenant isolation:

```
┌─────────────────────────────────────────────────────────────┐
│                    SERVICE REGISTRY                         │
│  (mappa tenant + service → DB location)                     │
└─────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
    │ DB MAIN   │   │ DB PM     │   │ DB DAM    │
    │ (shared)  │   │ (split)   │   │ (split)   │
    ├───────────┤   ├───────────┤   ├───────────┤
    │ svc_pm    │   │ svc_pm    │   │ svc_dam   │
    │ svc_crm   │   │ tenant_*  │   │ tenant_*  │
    │ svc_dam   │   │           │   │           │
    └───────────┘   └───────────┘   └───────────┘
```

**Tenant Tiers:**
- **TRIAL** (1000 users/shard) → Tabella condivisa, soft limits
- **SINGLE** (500 users/shard) → Tabella condivisa, più risorse
- **TEAM** (max 500 schemas/DB) → Schema dedicato per servizio
- **ENTERPRISE** (DB dedicato) → 1 DB per tenant + SLA
- **MEGA** (DB per servizio) → Custom pricing

**Auto-Split Logic:**
- Revenue > €50k/mese → Split service to dedicated DB
- Tenants > 100 → Split
- Query time > 200ms → Split
- Growth rate > 30%/mese → Split

**Storage:** Wasabi S3 (~€5/TB vs €23/TB AWS) + Glacier archiving

👉 **[Vedi architettura completa](ARCHITECTURE_TIERED_SCALING.md)**

---

### Microservices Structure

Questo è un **monorepo gestito con git submodules** contenente 50+ microservizi indipendenti.

#### Organizzazione Servizi

```
├── ewh-master          # Repository master & documentazione
├── ops-infra           # Infrastructure as Code (Scalingo, Cloudflare, Wasabi)
│
├── app-*               # Frontend Applications (Next.js)
│   ├── app-web-frontend
│   ├── app-admin-console
│   ├── app-raster-editor
│   ├── app-layout-editor
│   └── app-video-editor
│
└── svc-*               # Backend Services (Fastify + TypeScript)
    ├── Core Services (API Gateway, Auth, Plugins, Media, Billing)
    ├── Creative Services (Image, Video, Layout, Vector, Mockup)
    ├── Publishing Services (Projects, Search, Site Builder/Renderer)
    ├── ERP Services (Products, Orders, Inventory, CRM, Shipping)
    ├── Collaboration Services (PM, Support, Chat, DMS, Forms)
    └── Platform Services (Comm, Enrichment, BI)
```

## 🚀 Quick Start

### 1. Admin Panel Setup (PRIORITY!)

**Configura admin panel per roadmap + task tracking:**

```bash
# 1. Esegui migration SQL su Supabase
# Vai su: https://supabase.com/dashboard/project/qubhjidkgpxlyruwkfkb/sql
# Copia contenuto da: migrations/100_admin_roadmap_checklist.sql
# Incolla e RUN

# 2. Verifica setup
node scripts/test-admin-setup.cjs

# 3. Avvia admin frontend
cd app-admin-frontend
cp .env.example .env
npm install
npm run dev

# Apri:
# - Roadmap: http://localhost:5173/roadmap
# - Tasks: http://localhost:5173/development
```

**👉 [Istruzioni dettagliate](ADMIN_SETUP_INSTRUCTIONS.md)**

---

### 2. Development Environment

#### Primo Setup (Nuovo Developer)

```bash
# Clone del monorepo con tutti i submodule
git clone --recursive https://github.com/edizioniwhtehole/ewh-monorepo.git
cd ewh-monorepo

# Install dependencies
pnpm install

# Setup environment
cp .env.example .env
# Edit .env con le tue credenziali Supabase

# Avvia servizi
pnpm dev
```

#### Setup Esistente (Se hai già clonato i repo)

```bash
cd /path/to/ewh

# Registra i submodule esistenti
git submodule init
git submodule update

# Install dependencies
pnpm install
```

## 📦 Gestione Submodules

### Lavorare su un Singolo Servizio

Ogni servizio è un **repository git indipendente**. Puoi lavorarci normalmente:

```bash
cd svc-auth
git checkout -b feature/oauth-support
# ... modifiche ...
git add .
git commit -m "Add OAuth support"
git push origin feature/oauth-support
```

### Aggiornare Tutti i Servizi

```bash
# Pull di tutti i submodule
./scripts/pull-all.sh

# Oppure manualmente:
git submodule update --remote --merge
```

### Vedere lo Stato di Tutti i Servizi

```bash
./scripts/status-all.sh

# Oppure manualmente:
git submodule foreach 'echo "=== $name ===" && git status --short && git branch --show-current'
```

### Aggiornare il Monorepo Dopo Modifiche

Quando aggiorni un servizio, il monorepo deve registrare il nuovo commit:

```bash
cd svc-auth
git pull origin main

cd ..
git add svc-auth
git commit -m "Update svc-auth to include OAuth support"
git push
```

## 🐳 Docker Compose Development

### Avviare Servizi per Categoria

```bash
cd compose

# Solo i servizi core
docker-compose -f docker-compose.dev.yml --profile core up

# Servizi creativi
docker-compose -f docker-compose.dev.yml --profile creative up

# Servizi ERP
docker-compose -f docker-compose.dev.yml --profile erp up

# Tutti i servizi (default)
docker-compose -f docker-compose.dev.yml up
```

### Variabili d'Ambiente

Il docker-compose usa `${EWH_ROOT:-..}` per il mount del volume. Default: cartella parent del compose.

Per override:
```bash
export EWH_ROOT=/Users/tuonome/dev/ewh
docker-compose -f docker-compose.dev.yml up
```

## 🔐 Secrets & Configuration

**⚠️ IMPORTANTE**: Non committare MAI secrets nei repository!

- File ignorati da git (vedi [.gitignore](.gitignore)):
  - `infra/cloudflare.env`
  - `infra/wasabi.env`
  - `infra/scalingo-secrets.*.json`
  - `svc-auth/jwk_private.pem` (e simili)

- Usa template file: `infra/scalingo-secrets.template.json`

## 📊 Deploy su Scalingo

Ogni servizio è deployato come **applicazione Scalingo separata**:

- `svc-auth` → `ewh-prod-svc-auth` (+ Postgres addon)
- `svc-media` → `ewh-prod-svc-media` (+ Postgres + Redis)
- ... × 51 servizi

**Deploy automatico**:
- Scalingo monitora i repository individuali (es: `github.com/edizioniwhtehole/svc-auth`)
- Push su `main` → auto-deploy in production
- Push su `develop` → auto-deploy in staging

**Il monorepo NON impatta il deploy**: Scalingo continua a deployare dai repository individuali.

### Generare Manifest Scalingo

```bash
python3 infra/generate_scalingo_manifest.py
# Output: infra/scalingo-manifest.json
```

## 🛠️ Utility Scripts

```bash
# Pull di tutti i submodule
./scripts/pull-all.sh

# Stato di tutti i submodule
./scripts/status-all.sh

# Aggiorna riferimenti submodule nel monorepo
./scripts/update-submodules.sh

# Clone di tutti i repository (legacy, ora usa git clone --recursive)
./clone_all.sh
```

## 🏛️ Stack Tecnologico

- **Backend**: TypeScript + Fastify + PostgreSQL
- **Frontend**: TypeScript + Next.js + React + TailwindCSS
- **Infrastructure**: Docker + Docker Compose + Scalingo (PaaS)
- **Storage**: Wasabi S3, Redis, PostgreSQL
- **CI/CD**: GitHub Actions + Scalingo auto-deploy

## 📚 Documentazione Servizi

Ogni servizio ha:
- `README.md` - Documentazione tecnica
- `PROMPT.md` - Context per AI/LLM development
- `docs/` - Documentazione dettagliata

## 🤝 Workflow di Sviluppo

### Feature Branch per Singolo Servizio

```bash
cd svc-orders
git checkout develop
git pull origin develop
git checkout -b feature/add-discount-codes

# ... sviluppo ...
git add .
git commit -m "feat: add discount codes support"
git push origin feature/add-discount-codes

# Crea PR su GitHub: svc-orders repo
# Merge → Scalingo auto-deploya
```

### Coordinare Modifiche Cross-Service

Se modifichi API in `svc-auth` che impattano `svc-api-gateway`:

```bash
# 1. Modifica svc-auth
cd svc-auth
# ... modifiche ...
git commit -m "feat: add new auth endpoint"
git push

# 2. Modifica svc-api-gateway
cd ../svc-api-gateway
# ... modifiche per usare nuovo endpoint ...
git commit -m "feat: integrate new auth endpoint"
git push

# 3. Aggiorna monorepo per tracciare entrambi
cd ..
git add svc-auth svc-api-gateway
git commit -m "Coordinate auth endpoint changes across services"
git push
```

Il commit del monorepo **documenta quali versioni funzionano insieme**.

## 🔍 Troubleshooting

### Submodule non inizializzato

```bash
git submodule init
git submodule update
```

### Submodule detached HEAD

```bash
cd <submodule>
git checkout main
git pull
```

### Reset di un submodule

```bash
git submodule deinit <submodule>
git submodule update --init <submodule>
```

## 📞 Supporto

- **Issues**: GitHub Issues su repository specifico
- **Architecture**: Vedi documentazione in `ewh-master/`
- **Infrastructure**: Vedi documentazione in `ops-infra/`

## 📄 License

Proprietario - Edizioni White Hole
