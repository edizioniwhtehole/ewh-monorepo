# Development Guide - EWH Platform

> Guida completa per sviluppare sulla piattaforma EWH

## 📋 Indice

- [Setup Iniziale](#setup-iniziale)
- [Workflow Sviluppo](#workflow-sviluppo)
- [Lavorare sui Servizi](#lavorare-sui-servizi)
- [Docker Compose](#docker-compose)
- [Testing](#testing)
- [Debugging](#debugging)
- [Best Practices](#best-practices)

---

## Setup Iniziale

### Prerequisiti

```bash
# Verifica versioni
node --version    # v20.x.x
pnpm --version    # v10.x.x
docker --version  # 24.x.x
git --version     # 2.x.x
```

**Installazione:**
```bash
# Node.js 20 LTS
brew install node@20  # macOS
# oppure usa nvm: nvm install 20 && nvm use 20

# pnpm
npm install -g pnpm

# Docker Desktop
# Scarica da https://www.docker.com/products/docker-desktop

# GitHub CLI (opzionale ma consigliato)
brew install gh
gh auth login
```

### Clone del Monorepo

```bash
# Clone con submodules
git clone --recursive https://github.com/edizioniwhtehole/ewh-monorepo.git
cd ewh-monorepo

# Verifica submodules
git submodule status
# Dovresti vedere 52 submodule registrati

# Update submodules (se necessario)
git submodule update --init --recursive
```

### Configurazione Ambiente

```bash
# Copia template environment
cp .env.example .env

# Configura variabili (opzionale per local dev)
# DATABASE_URL, REDIS_URL, etc sono già configurati per Docker
```

---

## Workflow Sviluppo

### Modello Git Submodules

Ogni servizio è un **repository git indipendente**. Il monorepo traccia commit specifici di ogni servizio.

```
ewh-monorepo/                    ← Repo master
├── svc-auth/                    ← Submodule (repo separato)
│   └── .git → github.com/.../svc-auth
├── svc-media/                   ← Submodule (repo separato)
│   └── .git → github.com/.../svc-media
└── .gitmodules                  ← Mappa dei submodule
```

### Branch Strategy

**Repository individuali (svc-*, app-*):**
```
main      → Production (auto-deploy su Scalingo prod)
develop   → Staging (auto-deploy su Scalingo staging)
feature/* → Feature branches
hotfix/*  → Hotfix branches
```

**Monorepo (ewh-monorepo):**
```
main      → Traccia versioni produzione
develop   → Traccia versioni staging (TODO)
```

---

## Lavorare sui Servizi

### Scenario 1: Modificare un Singolo Servizio

```bash
# 1. Entra nel servizio
cd svc-auth

# 2. Verifica branch corrente
git branch --show-current  # develop

# 3. Crea feature branch
git checkout -b feature/oauth-support

# 4. Installa dipendenze (se necessario)
pnpm install

# 5. Sviluppa
# ... modifica codice ...

# 6. Test
pnpm test

# 7. Commit
git add .
git commit -m "feat: add OAuth2 support for Google"

# 8. Push al repository del servizio
git push origin feature/oauth-support

# 9. Crea Pull Request su GitHub
gh pr create --title "feat: OAuth2 support" --body "Implements OAuth2 flow for Google authentication"

# 10. Merge PR → auto-deploy su staging (branch develop)
```

### Scenario 2: Modifiche Cross-Service

Quando devi modificare API in più servizi coordinati:

```bash
# 1. Modifica svc-auth (aggiunge nuovo endpoint)
cd svc-auth
git checkout -b feature/new-auth-endpoint
# ... modifiche ...
git commit -m "feat: add /auth/mfa endpoint"
git push origin feature/new-auth-endpoint

# 2. Modifica svc-api-gateway (usa nuovo endpoint)
cd ../svc-api-gateway
git checkout -b feature/integrate-mfa
# ... modifiche ...
git commit -m "feat: integrate MFA endpoint from svc-auth"
git push origin feature/integrate-mfa

# 3. Testa localmente con Docker Compose
cd ../compose
docker-compose -f docker-compose.dev.yml up svc-auth svc-api-gateway

# 4. Merge entrambe le PR quando tutto funziona

# 5. Aggiorna monorepo per documentare le versioni coordinate
cd ../
git add svc-auth svc-api-gateway
git commit -m "feat: coordinate MFA implementation across auth and gateway"
git push
```

### Scenario 3: Aggiungere Nuovo Servizio

```bash
# 1. Crea repository su GitHub
gh repo create edizioniwhtehole/svc-notifications --public

# 2. Clona nel monorepo
cd /path/to/ewh-monorepo
git clone https://github.com/edizioniwhtehole/svc-notifications.git

# 3. Setup servizio da template
cd svc-notifications
cp ../svc-auth/package.json .
# ... setup TypeScript, Fastify, etc ...

# 4. Registra come submodule
cd ..
git submodule add https://github.com/edizioniwhtehole/svc-notifications.git svc-notifications

# 5. Aggiorna .gitmodules e docker-compose
# Vedi sezione "Aggiungere Servizio a Docker Compose"

# 6. Commit nel monorepo
git add .gitmodules svc-notifications compose/docker-compose.dev.yml
git commit -m "feat: add svc-notifications service"
git push
```

---

## Docker Compose

### Avviare l'Ambiente Completo

```bash
cd compose

# Avvia tutti i servizi (default profile)
docker-compose -f docker-compose.dev.yml up

# Avvia in background
docker-compose -f docker-compose.dev.yml up -d

# Verifica log
docker-compose -f docker-compose.dev.yml logs -f svc-auth
```

### Avviare Per Categoria

```bash
# Solo servizi core (auth, api-gateway, plugins, media, billing)
docker-compose -f docker-compose.dev.yml --profile core up

# Solo servizi creativi
docker-compose -f docker-compose.dev.yml --profile creative up

# Solo servizi ERP
docker-compose -f docker-compose.dev.yml --profile erp up

# Combina profili
docker-compose -f docker-compose.dev.yml --profile core --profile erp up
```

### Avviare Singoli Servizi

```bash
# Solo auth + database dependencies
docker-compose -f docker-compose.dev.yml up svc-auth postgres redis

# Solo frontend + api-gateway + auth
docker-compose -f docker-compose.dev.yml up app-web-frontend svc-api-gateway svc-auth
```

### Debugging con Docker Compose

```bash
# Rebuild singolo servizio
docker-compose -f docker-compose.dev.yml build svc-auth

# Shell interattiva in container
docker-compose -f docker-compose.dev.yml exec svc-auth sh

# Verifica variabili ambiente
docker-compose -f docker-compose.dev.yml exec svc-auth env | grep DATABASE

# Stop senza rimuovere volumi
docker-compose -f docker-compose.dev.yml down

# Stop e rimuovi tutto (attenzione: perde dati!)
docker-compose -f docker-compose.dev.yml down -v
```

### Sviluppo Locale Senza Docker

Se preferisci Node locale invece di Docker:

```bash
# 1. Avvia solo infrastruttura (postgres, redis, minio)
docker-compose -f docker-compose.dev.yml up postgres redis minio

# 2. Esporta variabili
export DATABASE_URL="postgres://ewh:ewhpass@localhost:5432/ewh_master"
export REDIS_URL="redis://localhost:6379/0"
export S3_ENDPOINT="http://localhost:9000"
export S3_ACCESS_KEY="ewh"
export S3_SECRET_KEY="ewhminio"

# 3. Avvia servizio in Node locale
cd svc-auth
pnpm install
pnpm run migrate:dev
pnpm run dev
# Server su http://localhost:4001
```

**Vantaggi:**
- Hot reload più veloce
- Debug con breakpoint in IDE
- No overhead Docker

**Svantaggi:**
- Devi gestire manualmente porte e dependencies
- Possibili conflitti di versione Node

---

## Testing

### Unit Tests (Vitest)

```bash
cd svc-auth

# Run tests
pnpm test

# Watch mode
pnpm test:watch

# Coverage
pnpm test -- --coverage
```

**Struttura test:**
```typescript
// svc-auth/test/auth.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createServer } from '../src/index.js';

describe('POST /auth/signup', () => {
  let app;

  beforeAll(async () => {
    app = await createServer(testConfig);
  });

  afterAll(async () => {
    await app.close();
  });

  it('should create user and organization', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/signup',
      payload: {
        email: 'test@example.com',
        password: 'SecurePass123!',
        organization_name: 'Test Org'
      }
    });

    expect(response.statusCode).toBe(201);
    expect(response.json()).toHaveProperty('user_id');
  });
});
```

### Integration Tests

```bash
# Test con database reale (Docker)
docker-compose -f docker-compose.dev.yml up -d postgres redis
cd svc-auth
pnpm test:integration
```

### E2E Tests (Playwright - TODO)

```bash
cd app-web-frontend
pnpm test:e2e
```

---

## Debugging

### VSCode Debug Config

Crea `.vscode/launch.json` in ogni servizio:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug svc-auth",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run", "dev"],
      "cwd": "${workspaceFolder}",
      "env": {
        "NODE_ENV": "development",
        "DATABASE_URL": "postgres://ewh:ewhpass@localhost:5432/ewh_master"
      },
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

### Chrome DevTools (Node Inspector)

```bash
cd svc-auth
node --inspect-brk node_modules/.bin/tsx src/index.ts

# Apri chrome://inspect in Chrome
# Click "inspect" sul processo Node
```

### Logging

Ogni servizio usa `pino` per structured logging:

```typescript
// Log con correlation-id e tenant context
app.log.info(
  {
    correlationId: request.headers['x-correlation-id'],
    tenantId: request.user.org_id,
    userId: request.user.sub
  },
  'Processing order creation'
);
```

**Visualizza log Docker:**
```bash
docker-compose -f docker-compose.dev.yml logs -f svc-auth | pino-pretty
```

---

## Best Practices

### Codice

1. **TypeScript Strict Mode**
   ```json
   // tsconfig.json
   {
     "compilerOptions": {
       "strict": true,
       "noImplicitAny": true,
       "strictNullChecks": true
     }
   }
   ```

2. **Zod Validation**
   ```typescript
   import { z } from 'zod';

   const signupSchema = z.object({
     email: z.string().email(),
     password: z.string().min(8),
     organization_name: z.string().min(2)
   });

   app.post('/auth/signup', async (request, reply) => {
     const data = signupSchema.parse(request.body);
     // ...
   });
   ```

3. **Error Handling**
   ```typescript
   try {
     const user = await createUser(data);
     return reply.code(201).send({ user });
   } catch (error) {
     if (error.code === '23505') { // Postgres unique violation
       return reply.code(409).send({ error: 'Email already exists' });
     }
     app.log.error(error, 'Unexpected error in signup');
     return reply.code(500).send({ error: 'Internal server error' });
   }
   ```

### Git Commits

**Formato:** `type(scope): subject`

```bash
# Buoni commit
git commit -m "feat(auth): add OAuth2 Google provider"
git commit -m "fix(orders): prevent negative quantity in cart"
git commit -m "docs(readme): update setup instructions"
git commit -m "refactor(media): extract S3 logic to separate module"
git commit -m "test(billing): add Stripe webhook tests"

# Tipi: feat, fix, docs, style, refactor, test, chore
```

### Database Migrations

```bash
# Crea nuova migration
cd svc-auth
npm run migrate:create add_mfa_table

# File creato: db/migrations/004_add_mfa_table.sql
```

```sql
-- db/migrations/004_add_mfa_table.sql
-- Up
CREATE TABLE mfa_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  secret TEXT NOT NULL,
  enabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Down
DROP TABLE mfa_tokens;
```

```bash
# Applica migration
npm run migrate:dev

# Rollback (attenzione!)
npm run migrate:down
```

### Environment Variables

**Mai committare secrets!**

```bash
# ✅ Buono: usa template
.env.example  → commit nel repo
.env          → gitignored, locale

# ❌ Male
.env con API keys hardcoded → commit (NEVER!)
```

**Template `.env.example`:**
```bash
# Database
DATABASE_URL=postgres://ewh:ewhpass@localhost:5432/ewh_master
DB_SCHEMA=auth

# Redis
REDIS_URL=redis://localhost:6379/0

# S3
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=ewh
S3_SECRET_KEY=ewhminio
S3_BUCKET=ewh-dev

# JWT (use generated keys!)
JWT_PRIVATE_KEY_FILE=./jwk_private.pem
JWT_PUBLIC_KEY_FILE=./jwk_public.pem
JWT_ISSUER=http://localhost:4001
JWT_AUDIENCE=ewh-saas

# App
PORT=4001
NODE_ENV=development
LOG_LEVEL=debug
```

### Code Review Checklist

Prima di aprire PR, verifica:

- [ ] Test passano (`pnpm test`)
- [ ] Linter OK (`pnpm lint` se configurato)
- [ ] Build OK (`pnpm build`)
- [ ] Nessun secret committato
- [ ] README aggiornato se necessario
- [ ] Migrazioni database includono `-- Down`
- [ ] Log con correlation-id e tenant context
- [ ] Error handling appropriato
- [ ] Validazione input con Zod

---

## Script Helper

Il monorepo include script per operazioni comuni:

```bash
# Pull di tutti i submodule
./scripts/pull-all.sh

# Stato di tutti i submodule
./scripts/status-all.sh

# Aggiorna riferimenti submodule
./scripts/update-submodules.sh

# Registra nuovi submodule (post git submodule add)
./scripts/register-submodules.sh
```

---

## Troubleshooting

### Submodule non inizializzato

```bash
git submodule init
git submodule update
```

### Submodule detached HEAD

```bash
cd svc-auth
git checkout develop
git pull
```

### Docker "port already allocated"

```bash
# Verifica processi in ascolto
lsof -i :4001

# Kill processo
kill -9 <PID>

# Oppure cambia porta in docker-compose
```

### pnpm install fallisce

```bash
# Pulisci cache
pnpm store prune

# Riprova
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### Database migration fallisce

```bash
# Verifica connessione
psql $DATABASE_URL -c "SELECT version();"

# Reset database (ATTENZIONE: perde dati!)
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up -d postgres
npm run migrate:dev
```

---

## Riferimenti

- [ARCHITECTURE.md](ARCHITECTURE.md) - Architettura sistema
- [README.md](README.md) - Setup monorepo
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deploy su Scalingo
- [Fastify Docs](https://fastify.dev/)
- [Vitest Docs](https://vitest.dev/)
- [Docker Compose Docs](https://docs.docker.com/compose/)

---

**Ultimo aggiornamento:** 2025-10-01
**Maintainer:** Team EWH Platform

Hai domande? Apri issue su GitHub o chiedi nel canale #dev su Slack.
