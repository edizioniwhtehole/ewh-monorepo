# EWH Monorepo

> Monorepo per il sistema EWH (Edizioni White Hole) SaaS platform - 50+ microservizi, architettura a eventi, multi-tenant B2B.

[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Scalingo-blue.svg)](https://scalingo.com)
[![Node](https://img.shields.io/badge/node-20.x-green.svg)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/typescript-5.6+-blue.svg)](https://typescriptlang.org)

## 📚 Documentazione

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architettura completa del sistema, stack tecnologico, flussi principali
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Setup ambiente, workflow sviluppo, testing, debugging
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deploy su Scalingo, gestione secrets, monitoring, rollback
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Linee guida per contribuire al progetto

## 🏗️ Architettura

Questo è un **monorepo gestito con git submodules** contenente 52 microservizi indipendenti, ciascuno deployabile separatamente su Scalingo.

### Organizzazione Servizi

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

### Primo Setup (Nuovo Developer)

```bash
# Clone del monorepo con tutti i submodule
git clone --recursive https://github.com/edizioniwhtehole/ewh-monorepo.git
cd ewh-monorepo

# Avvia i servizi con Docker Compose
cd compose
docker-compose -f docker-compose.dev.yml up
```

### Setup Esistente (Se hai già clonato i repo)

Se hai già le cartelle dei servizi ma vuoi usare il monorepo:

```bash
cd /path/to/ewh
git init
git remote add origin https://github.com/edizioniwhtehole/ewh-monorepo.git
git fetch
git reset --hard origin/main

# Registra i submodule esistenti
git submodule init
git submodule update
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
- **Architecture**: Vedi [ewh-master](ewh-master/README.md)
- **Infrastructure**: Vedi [ops-infra](ops-infra/README.md)

## 📄 License

Proprietario - Edizioni White Hole
