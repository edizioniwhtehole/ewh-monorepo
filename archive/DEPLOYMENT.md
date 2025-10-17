# Deployment Guide - EWH Platform

> Guida completa per il deployment su Scalingo

## 📋 Indice

- [Overview](#overview)
- [Strategia Deploy](#strategia-deploy)
- [Setup Scalingo](#setup-scalingo)
- [Processo Deploy](#processo-deploy)
- [Gestione Secrets](#gestione-secrets)
- [Monitoring & Rollback](#monitoring--rollback)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Architettura Deploy

```
GitHub Repository (Individual)         Scalingo (PaaS)
┌────────────────────────┐            ┌──────────────────────┐
│ github.com/            │            │ ewh-prod-svc-auth    │
│ edizioniwhtehole/      │  auto      │                      │
│ svc-auth               ├──deploy──→ │ + PostgreSQL addon   │
│                        │            │ + Redis addon (opt)  │
│ Branch: main           │            │                      │
└────────────────────────┘            └──────────────────────┘
         │
         │ pull request
         ▼
┌────────────────────────┐            ┌──────────────────────┐
│ Branch: develop        │  auto      │ ewh-stg-svc-auth     │
│                        ├──deploy──→ │                      │
│                        │            │ + PostgreSQL addon   │
└────────────────────────┘            └──────────────────────┘
```

**Key Points:**
- **1 servizio = 1 repo GitHub = 1 app Scalingo**
- Deploy automatico: push su `main` → production, push su `develop` → staging
- Database separati per ogni servizio (addon PostgreSQL dedicato)
- Il monorepo `ewh-monorepo` NON deploya - serve solo per coordinamento locale

---

## Strategia Deploy

### Ambienti

| Ambiente | Branch | URL Pattern | Scaling |
|----------|--------|-------------|---------|
| **Production** | `main` | `*.polosaas.it` | 1-2 containers M |
| **Staging** | `develop` | `*.staging.ewhsaas.it` | 1 container S |
| **Development** | local | `localhost:*` | Docker Compose |

### Naming Convention Scalingo Apps

```
ewh-{env}-{service-name}

Esempi:
ewh-prod-svc-auth           → Production
ewh-prod-app-web-frontend   → Production
ewh-stg-svc-auth            → Staging
ewh-stg-app-web-frontend    → Staging
```

### Auto-Deploy Strategy

**Production (`main` branch):**
```bash
# Developer: merge PR su main
gh pr merge 123

# Scalingo: auto-deploya entro 2-3 minuti
# - Build dell'app
# - Run migrations (se `npm run migrate` in package.json)
# - Rolling restart (zero downtime)
# - Health check
```

**Staging (`develop` branch):**
```bash
# Developer: push su develop
git push origin develop

# Scalingo: auto-deploya immediatamente
```

### Manual Deploy (Emergency)

```bash
# Deploy forzato (bypassa auto-deploy)
cd svc-auth
git push scalingo-prod main

# Deploy di un branch specifico
git push scalingo-prod feature/hotfix:main
```

---

## Setup Scalingo

### Installazione CLI

```bash
# macOS
brew install scalingo

# Login
scalingo login
```

### Creazione App

#### Metodo 1: Via CLI (Manuale)

```bash
# Crea app production
scalingo create ewh-prod-svc-auth --region osc-fr1

# Aggiungi addon PostgreSQL
scalingo --app ewh-prod-svc-auth addons-add postgresql postgresql-starter-512

# Aggiungi addon Redis (se necessario)
scalingo --app ewh-prod-svc-auth addons-add redis redis-starter-256

# Link GitHub repo
scalingo --app ewh-prod-svc-auth integration-link-manual-deploy \
  --integration github \
  --url https://github.com/edizioniwhtehole/svc-auth \
  --branch main \
  --auto-deploy

# Set environment variables
scalingo --app ewh-prod-svc-auth env-set \
  NODE_ENV=production \
  PORT=4001 \
  DB_SCHEMA=auth \
  JWT_ISSUER="https://api.polosaas.it/auth" \
  JWT_AUDIENCE="ewh-saas"
```

#### Metodo 2: Via Script Python (Automatico)

Il monorepo include script per provisioning automatico:

```bash
cd infra

# Genera manifest di tutti i 51 servizi
python3 generate_scalingo_manifest.py

# Output: scalingo-manifest.json con configurazione completa

# Provisiona su Scalingo (TODO: implementare)
python3 scalingo_provision.py --env production
```

**`scalingo-manifest.json` Structure:**
```json
{
  "services": [
    {
      "name": "svc-auth",
      "repo": {
        "url": "https://github.com/edizioniwhtehole/svc-auth.git"
      },
      "processes": {
        "web": {
          "type": "web",
          "addons": ["postgres"],
          "env": {
            "required": ["DATABASE_URL", "JWT_PRIVATE_KEY", "..."],
            "production": {
              "NODE_ENV": "production",
              "PORT": "4001",
              "..."
            }
          },
          "scale": {
            "production": "2:M"
          }
        }
      },
      "subdomains": {
        "production": "api.polosaas.it"
      }
    }
  ]
}
```

### Configurazione DNS (Cloudflare)

```bash
# Script per setup automatico DNS
cd infra
cp cloudflare.env.example cloudflare.env
# Popola con API token Cloudflare

python3 setup_cloudflare_dns.py

# Crea record:
# api.polosaas.it → CNAME ewh-prod-svc-api-gateway.osc-fr1.scalingo.io
# app.polosaas.it → CNAME ewh-prod-app-web-frontend.osc-fr1.scalingo.io
# ...
```

---

## Processo Deploy

### Deploy Normale (Auto)

```bash
# 1. Sviluppa in feature branch
cd svc-auth
git checkout -b feature/new-endpoint

# 2. Commit & push
git commit -m "feat: add new endpoint"
git push origin feature/new-endpoint

# 3. Crea PR su GitHub
gh pr create --base develop

# 4. Review & merge
gh pr merge 123

# 5. Scalingo auto-deploya su staging
# Verifica: https://ewh-stg-svc-auth.osc-fr1.scalingo.io/health

# 6. Se OK, merge develop → main
git checkout main
git pull origin main
git merge develop
git push origin main

# 7. Scalingo auto-deploya su production
# Verifica: https://api.polosaas.it/auth/health
```

### Deploy con Migrazioni Database

**Se modifichi schema database:**

```bash
# 1. Crea migration file
cd svc-auth
npm run migrate:create add_mfa_table

# 2. Scrivi SQL migration
# db/migrations/004_add_mfa_table.sql

# 3. Commit migration
git add db/migrations/
git commit -m "feat: add MFA table migration"

# 4. Push → auto-deploy
git push origin main

# 5. Scalingo esegue automaticamente:
#    - npm install
#    - npm run migrate (se presente in package.json)
#    - npm run build
#    - npm start
```

**⚠️ Attenzione Migration:**
- Sempre scrivere migration reversibili (`-- Down`)
- Testare prima su staging
- Backup database prima di migration pesanti

### Rollback

**Metodo 1: Rollback Scalingo UI**
```bash
# Via dashboard Scalingo
# App Settings → Deployments → "Rollback to previous"
```

**Metodo 2: Git Revert**
```bash
# Revert commit problematico
git revert <commit-hash>
git push origin main

# Scalingo auto-deploya il revert
```

**Metodo 3: Database Rollback**
```bash
# Se migration è il problema
cd svc-auth

# Connetti a DB production (attenzione!)
scalingo --app ewh-prod-svc-auth run bash
npm run migrate:down

# Verifica
psql $DATABASE_URL -c "\dt"
```

---

## Gestione Secrets

### Environment Variables

**Never commit secrets!** Use Scalingo environment:

```bash
# Set secrets su production
scalingo --app ewh-prod-svc-auth env-set \
  JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..." \
  STRIPE_SECRET_KEY="sk_live_..." \
  SMTP_PASSWORD="secret"

# Get env vars
scalingo --app ewh-prod-svc-auth env

# Unset
scalingo --app ewh-prod-svc-auth env-unset SMTP_PASSWORD
```

### Secrets Management Workflow

```bash
# 1. Genera secrets localmente
cd svc-auth
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# 2. Salva in file ignorato da git
echo "SECRET_KEY=abc123..." >> .env.local  # gitignored

# 3. Set su Scalingo
scalingo --app ewh-prod-svc-auth env-set SECRET_KEY=abc123...

# 4. Documenta in template (senza valori reali)
echo "SECRET_KEY=<generate-random-32-bytes>" >> .env.example  # committed
```

### JWT Keys Management

```bash
# Generate RSA key pair
cd svc-auth
openssl genrsa -out jwk_private.pem 2048
openssl rsa -in jwk_private.pem -pubout -out jwk_public.pem

# Convert to single-line for env var
JWT_PRIVATE_KEY=$(awk '{printf "%s\\n", $0}' jwk_private.pem)
JWT_PUBLIC_KEY=$(awk '{printf "%s\\n", $0}' jwk_public.pem)

# Set on Scalingo
scalingo --app ewh-prod-svc-auth env-set \
  JWT_PRIVATE_KEY="$JWT_PRIVATE_KEY" \
  JWT_PUBLIC_KEY="$JWT_PUBLIC_KEY"

# Rotate keys (rolling update)
# 1. Generate new keys
# 2. Add as JWT_PRIVATE_KEY_NEW
# 3. Update code to sign with new, verify with both
# 4. After 30d (refresh token TTL), remove old key
```

### Secrets Rotation Schedule

| Secret | Rotation | Method |
|--------|----------|--------|
| JWT keys | 90 giorni | Rolling update |
| API keys (Stripe, etc) | 180 giorni | Update + immediate restart |
| Database password | 365 giorni | Scalingo addon config |
| S3 credentials | 180 giorni | Wasabi dashboard + env update |

---

## Monitoring & Rollback

### Health Checks

Ogni servizio espone:
```bash
GET /health → 200 OK se app running
GET /ready  → 200 OK se DB connesso
```

**Monitoraggio Scalingo:**
- Auto-restart se health check fallisce 3 volte
- Alert via email/Slack se app down > 5 minuti

### Logs

```bash
# Real-time logs
scalingo --app ewh-prod-svc-auth logs -f

# Filtra per errore
scalingo --app ewh-prod-svc-auth logs | grep ERROR

# Cerca correlation-id specifico
scalingo --app ewh-prod-svc-auth logs | grep "correlation-id-123"

# Export logs per analisi
scalingo --app ewh-prod-svc-auth logs --since 1h > logs.txt
```

### Metrics

Scalingo dashboard mostra:
- **Response time** (P50, P95, P99)
- **Requests per second**
- **Memory usage**
- **CPU usage**

**Alert Thresholds (TODO: configurare):**
- Response time P95 > 1s → warning
- Memory > 90% → scale up
- Error rate > 1% → alert

### Rollback Decision Tree

```
Deploy fallisce?
├─ Build error → Fix code, re-deploy
├─ Migration error → Rollback migration, revert deploy
└─ Runtime error
   ├─ Errore critico (500 rate >5%) → Rollback immediato
   └─ Errore minore → Hotfix + deploy
```

---

## Troubleshooting

### Deploy Fallisce

```bash
# 1. Verifica build logs
scalingo --app ewh-prod-svc-auth logs | grep "Build failed"

# Errori comuni:
# - Missing dependency → add to package.json
# - TypeScript error → fix and re-deploy
# - Migration error → check SQL syntax
```

### App Crash Loop

```bash
# 1. Check logs
scalingo --app ewh-prod-svc-auth logs

# 2. Common causes:
# - Port mismatch (app listen su porta diversa da $PORT)
# - Database connection error (check DATABASE_URL)
# - Missing env var

# 3. Quick fix: scale down to 0, fix issue, scale up
scalingo --app ewh-prod-svc-auth scale web:0
# ... fix issue ...
scalingo --app ewh-prod-svc-auth scale web:1:M
```

### Database Connection Issues

```bash
# Verifica addon attivo
scalingo --app ewh-prod-svc-auth addons

# Connetti manualmente
scalingo --app ewh-prod-svc-auth run bash
echo $DATABASE_URL
psql $DATABASE_URL -c "SELECT version();"

# Se fallisce: riavvia addon (attenzione: downtime!)
scalingo --app ewh-prod-svc-auth addons-upgrade postgresql <addon-id>
```

### Out of Memory

```bash
# Check memory usage
scalingo --app ewh-prod-svc-auth stats

# Scale up se necessario
scalingo --app ewh-prod-svc-auth scale web:1:L  # S → M → L

# Investigate memory leak
# - Connetti con SSH: scalingo --app ewh-prod-svc-auth run bash
# - node --inspect index.js
# - Use Chrome DevTools Memory Profiler
```

### Slow Response Time

```bash
# Check metrics
scalingo --app ewh-prod-svc-auth stats

# Possibili cause:
# - Database slow queries → check pg_stat_statements
# - External API timeout → add circuit breaker
# - High load → scale horizontally

# Scale horizontally
scalingo --app ewh-prod-svc-auth scale web:3:M
```

---

## Checklist Pre-Deploy Production

Prima di fare merge su `main`:

- [ ] Test passano su staging (`ewh-stg-*`)
- [ ] Smoke test manuale su staging
- [ ] Performance test se cambio critico (load test)
- [ ] Database migration testata su staging
- [ ] Secrets configurati su production
- [ ] Rollback plan documentato
- [ ] Team notificato (Slack #deploy)
- [ ] Deploy durante orario lavorativo (no venerdì sera!)

---

## Emergency Hotfix Procedure

```bash
# 1. Crea hotfix branch da main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug

# 2. Fix rapido
# ... modifica ...
git commit -m "hotfix: fix critical authentication bug"

# 3. Test localmente
pnpm test

# 4. Deploy diretto a production (senza staging)
git push origin hotfix/critical-bug

# Crea PR emergency
gh pr create --base main --title "HOTFIX: Critical auth bug"

# 5. Merge immediatamente se approvato
gh pr merge --admin

# 6. Scalingo auto-deploya

# 7. Verifica fix
curl https://api.polosaas.it/auth/health

# 8. Backport a develop
git checkout develop
git merge main
git push origin develop
```

---

## Riferimenti

- [ARCHITECTURE.md](ARCHITECTURE.md) - Architettura sistema
- [DEVELOPMENT.md](DEVELOPMENT.md) - Workflow sviluppo
- [README.md](README.md) - Setup monorepo
- [Scalingo Docs](https://doc.scalingo.com/)
- [Scalingo CLI Reference](https://doc.scalingo.com/cli)

---

**Ultimo aggiornamento:** 2025-10-01
**Maintainer:** Team EWH DevOps

Per emergenze deploy: #ops su Slack
