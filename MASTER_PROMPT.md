# EWH Platform - Master Prompt for AI Agents

> **Istruzioni universali per tutti gli agenti AI che operano su questa codebase**

**Versione:** 1.0.0
**Target:** Claude Code, GitHub Copilot, Cursor AI, e qualsiasi LLM agent
**Obbligatorietà:** MASSIMA - Leggere SEMPRE prima di ogni operazione

---

## 🎯 Tu Sei

Un **agente AI esperto** che lavora su **EWH Platform**, una piattaforma SaaS B2B multi-tenant per gestione contenuti creativi, publishing digitale ed e-commerce.

**Architettura:** 45 microservizi backend (Fastify + TypeScript) + 5 frontend apps (Next.js + React)

**Responsabilità:**
- Implementare features seguendo architettura esistente
- Mantenere coerenza tech stack
- Garantire multi-tenancy e sicurezza
- Documentare ogni modifica
- Coordinare con altri agenti

---

## 📚 Documentazione da Leggere (Obbligatorio)

**Prima di QUALSIASI operazione, leggi in questo ordine:**

### 1. [CONTEXT_INDEX.md](CONTEXT_INDEX.md) ⚡ - 2 minuti
- Indice rapido per trovare informazioni
- Mappa dei servizi e loro stato
- Collegamenti a documentazione rilevante

### 2. [PROJECT_STATUS.md](PROJECT_STATUS.md) 📊 - 5 minuti
- Stato attuale di TUTTI i 45 servizi
- Features implementate vs mancanti
- Priorità e roadmap
- Blocchi e dipendenze

### 3. [GUARDRAILS.md](GUARDRAILS.md) 🚦 - 10 minuti
- Regole obbligatorie per coordinamento
- Workflow di lavoro
- Gestione conflitti
- Ottimizzazione token

### 4. [ARCHITECTURE.md](ARCHITECTURE.md) 🏗️ - 15 minuti (se serve)
- Architettura complessiva sistema
- Stack tecnologico
- Comunicazione tra servizi
- Database e storage

### 5. Service-Specific PROMPT.md
- `{servizio}/PROMPT.md` - Istruzioni specifiche per il servizio
- Da leggere se lavori su quel servizio specifico

---

## 🚀 Quick Start Guide

### Step 1: Capire il Task (2-5 minuti)

```typescript
// Domande da farti PRIMA di iniziare:

1. "Quale servizio devo modificare?"
   → Cercare in CONTEXT_INDEX.md per trovarlo

2. "Il servizio è già implementato?"
   → Verificare in PROJECT_STATUS.md:
     ✅ Complete = Aggiungere feature
     🚧 In Progress = Verificare conflitti
     📝 Scaffolding = Implementare da zero

3. "Dipende da altri servizi?"
   → Controllare sezione "Dipendenze" in PROJECT_STATUS.md
   → Se dipendenze non pronte = BLOCCARE o usare mock

4. "Ci sono conflitti architetturali?"
   → Verificare ARCHITECTURE.md per principi
   → Verificare GUARDRAILS.md per regole
```

### Step 2: Analisi Rapida (5 minuti max)

```bash
# Leggere questi file nell'ordine:
1. CONTEXT_INDEX.md → trovare servizio
2. PROJECT_STATUS.md → verificare stato
3. {servizio}/PROMPT.md → istruzioni specifiche
4. {servizio}/README.md → documentazione esistente
5. git log --oneline {servizio} → ultime modifiche
```

### Step 3: Implementazione

Seguire workflow in [GUARDRAILS.md](GUARDRAILS.md#workflow-di-lavoro)

### Step 4: Documentazione (Obbligatoria)

```bash
# Aggiornare SEMPRE questi file:
1. PROJECT_STATUS.md → spostare feature da "Mancanti" a "Implementate"
2. {servizio}/PROMPT.md → aggiornare stato per prossimi agenti
3. {servizio}/README.md → aggiungere esempi uso
4. CHANGELOG.md (se esiste) → loggare modifiche
```

---

## 🎓 Principi Fondamentali

### Principio 1: "Read First, Write Later"

```typescript
// ❌ MALE: Iniziare subito a scrivere codice
async function createOrder() {
  // Assumo che svc-products esista...
  const product = await fetch('http://svc-products:4300/api/v1/products/123')
}

// ✅ BENE: Verificare dipendenze prima
// 1. Leggo PROJECT_STATUS.md → svc-products è "SCAFFOLDING ONLY"
// 2. Blocco implementazione o uso mock
async function createOrder() {
  // TODO(@agent-future): Replace with real svc-products when implemented
  // Tracked in: PROJECT_STATUS.md → svc-products → Priority: Alta
  const product = MOCK_PRODUCT_DATA
}
```

### Principio 2: "Multi-Tenancy Sempre"

```typescript
// ❌ MALE: Query senza tenant_id
const orders = await db.query('SELECT * FROM orders WHERE user_id = $1', [userId])

// ✅ BENE: SEMPRE includere tenant_id
const orders = await db.query(
  'SELECT * FROM orders WHERE tenant_id = $1 AND user_id = $2',
  [tenantId, userId]
)
```

### Principio 3: "Fail Fast, Document Always"

```typescript
// ❌ MALE: Nascondere problemi
try {
  await callExternalService()
} catch (error) {
  // Ignoro l'errore e continuo...
}

// ✅ BENE: Bloccare e documentare
try {
  await callExternalService()
} catch (error) {
  req.log.error({ error, service: 'svc-products' }, 'Service unavailable')

  // Documentare in PROJECT_STATUS.md:
  // "svc-orders BLOCCATO da svc-products non implementato"

  return rep.code(503).send({
    error: 'Service temporarily unavailable',
    correlation_id: req.headers['x-correlation-id']
  })
}
```

### Principio 4: "Convention over Configuration"

Seguire SEMPRE le convenzioni esistenti invece di inventarne di nuove.

```typescript
// ✅ Struttura directory SEMPRE uguale:
svc-{nome}/
├── src/
│   ├── routes/        # Tutti gli endpoint
│   ├── services/      # Business logic
│   ├── db/            # Database client e schema
│   └── app.ts         # Fastify setup
├── migrations/        # SQL migrations
├── tests/             # Test files
├── PROMPT.md          # Istruzioni agente
├── README.md          # Documentazione
└── package.json

// ❌ Non creare strutture custom come:
svc-{nome}/
├── controllers/   # ❌ Usare routes/
├── models/        # ❌ Usare db/schema.ts
└── lib/           # ❌ Usare services/
```

---

## 🔧 Tech Stack (Obbligatorio)

### Backend Microservizi

```typescript
// ✅ SEMPRE usare questo stack
import Fastify from 'fastify'
import { z } from 'zod'
import pg from 'pg'
import pino from 'pino'

// ❌ MAI usare alternative:
// - Express, Koa, Hapi (usare Fastify)
// - Joi, Yup (usare Zod)
// - Winston, Bunyan (usare Pino)
// - Prisma, TypeORM (usare pg diretto)
```

**Package.json Template:**
```json
{
  "name": "svc-{nome}",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/app.ts",
    "build": "tsc",
    "start": "node dist/app.js",
    "test": "vitest"
  },
  "dependencies": {
    "fastify": "^4.28.1",
    "@fastify/cors": "^9.0.1",
    "@fastify/jwt": "^8.0.0",
    "pg": "^8.12.0",
    "zod": "^3.23.8",
    "pino": "^9.0.0"
  },
  "devDependencies": {
    "typescript": "^5.6.3",
    "tsx": "^4.7.1",
    "vitest": "^2.1.3"
  }
}
```

### Frontend Apps

```typescript
// ✅ SEMPRE usare questo stack
import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { z } from 'zod'

// Next.js 14 con App Router
// TailwindCSS per styling
// Zustand per state management

// ❌ MAI usare:
// - Pages Router (usare App Router)
// - styled-components (usare Tailwind)
// - Redux (usare Zustand)
// - Class components (usare hooks)
```

**Package.json Template:**
```json
{
  "name": "app-{nome}",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.2.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^5.0.0",
    "zod": "^3.23.8",
    "tailwindcss": "^3.4.0"
  }
}
```

### Database (PostgreSQL)

```sql
-- ✅ SEMPRE seguire questo pattern:
CREATE TABLE {table_name} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.organizations(id),

  -- Business fields qui

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Index OBBLIGATORI:
CREATE INDEX idx_{table}_tenant_id ON {table}(tenant_id);
CREATE INDEX idx_{table}_created_at ON {table}(created_at);

-- RLS Policy OBBLIGATORIA:
ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON {table}
  USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- Trigger per updated_at:
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON {table}
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔐 Sicurezza (Critiche)

### 1. Autenticazione JWT

```typescript
// ✅ SEMPRE validare JWT in OGNI request
import type { FastifyRequest } from 'fastify'

interface AuthContext {
  user_id: string
  tenant_id: string
  org_id: string
  platform_role: string
  scopes: string[]
}

declare module 'fastify' {
  interface FastifyRequest {
    authContext: AuthContext
  }
}

// Hook globale per auth
app.addHook('onRequest', async (req, rep) => {
  // Skip auth per health check
  if (req.url === '/health') return

  const token = req.headers.authorization?.replace('Bearer ', '')
  if (!token) {
    return rep.code(401).send({ error: 'Unauthorized' })
  }

  try {
    const decoded = await app.jwt.verify(token)
    req.authContext = decoded
  } catch (error) {
    return rep.code(401).send({ error: 'Invalid token' })
  }
})
```

### 2. Input Validation

```typescript
// ✅ SEMPRE validare input con Zod
import { z } from 'zod'

const CreateOrderSchema = z.object({
  product_id: z.string().uuid(),
  quantity: z.number().int().positive(),
  shipping_address: z.object({
    street: z.string().min(1).max(255),
    city: z.string().min(1).max(100),
    country: z.string().length(2) // ISO code
  })
})

app.post('/api/v1/orders', async (req, rep) => {
  // Validate
  const result = CreateOrderSchema.safeParse(req.body)
  if (!result.success) {
    return rep.code(400).send({
      error: 'Validation failed',
      details: result.error.errors
    })
  }

  const data = result.data
  // Usa data validato
})
```

### 3. SQL Injection Prevention

```typescript
// ❌ MAI fare query con string concatenation
const orders = await db.query(
  `SELECT * FROM orders WHERE id = '${orderId}'` // VULNERABILE!
)

// ✅ SEMPRE usare prepared statements
const orders = await db.query(
  'SELECT * FROM orders WHERE tenant_id = $1 AND id = $2',
  [tenantId, orderId]
)
```

### 4. Sensitive Data

```typescript
// ❌ MAI loggare dati sensibili
req.log.info({ user: { email, password } }, 'User login') // ❌ NO!

// ✅ Mascherare o omettere
req.log.info({
  user: { email, password: '[REDACTED]' }
}, 'User login')

// ✅ Ancora meglio: non loggare proprio
req.log.info({ user_id }, 'User login')
```

---

## 📝 Patterns Comuni

### Pattern 1: Endpoint CRUD Base

```typescript
// GET List
app.get('/api/v1/orders', async (req, rep) => {
  const { tenant_id } = req.authContext
  const { page = 1, limit = 20 } = req.query

  const offset = (page - 1) * limit

  const result = await db.query(
    `SELECT * FROM orders
     WHERE tenant_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [tenant_id, limit, offset]
  )

  return {
    data: result.rows,
    meta: {
      page,
      limit,
      total: result.rowCount
    }
  }
})

// GET Single
app.get('/api/v1/orders/:id', async (req, rep) => {
  const { tenant_id } = req.authContext
  const { id } = req.params

  const result = await db.query(
    'SELECT * FROM orders WHERE tenant_id = $1 AND id = $2',
    [tenant_id, id]
  )

  if (result.rows.length === 0) {
    return rep.code(404).send({ error: 'Order not found' })
  }

  return result.rows[0]
})

// POST Create
app.post('/api/v1/orders', async (req, rep) => {
  const { tenant_id, user_id } = req.authContext

  // Validate
  const result = CreateOrderSchema.safeParse(req.body)
  if (!result.success) {
    return rep.code(400).send({
      error: 'Validation failed',
      details: result.error.errors
    })
  }

  const data = result.data

  // Insert
  const inserted = await db.query(
    `INSERT INTO orders (tenant_id, user_id, product_id, quantity, status)
     VALUES ($1, $2, $3, $4, 'pending')
     RETURNING *`,
    [tenant_id, user_id, data.product_id, data.quantity]
  )

  return rep.code(201).send(inserted.rows[0])
})

// PUT Update
app.put('/api/v1/orders/:id', async (req, rep) => {
  const { tenant_id } = req.authContext
  const { id } = req.params

  // Validate
  const result = UpdateOrderSchema.safeParse(req.body)
  if (!result.success) {
    return rep.code(400).send({
      error: 'Validation failed',
      details: result.error.errors
    })
  }

  const data = result.data

  // Update
  const updated = await db.query(
    `UPDATE orders
     SET status = $1, updated_at = NOW()
     WHERE tenant_id = $2 AND id = $3
     RETURNING *`,
    [data.status, tenant_id, id]
  )

  if (updated.rows.length === 0) {
    return rep.code(404).send({ error: 'Order not found' })
  }

  return updated.rows[0]
})

// DELETE Soft Delete
app.delete('/api/v1/orders/:id', async (req, rep) => {
  const { tenant_id } = req.authContext
  const { id } = req.params

  // Soft delete
  const deleted = await db.query(
    `UPDATE orders
     SET deleted_at = NOW()
     WHERE tenant_id = $1 AND id = $2 AND deleted_at IS NULL
     RETURNING id`,
    [tenant_id, id]
  )

  if (deleted.rows.length === 0) {
    return rep.code(404).send({ error: 'Order not found' })
  }

  return rep.code(204).send()
})
```

### Pattern 2: Service-to-Service Call

```typescript
// ✅ Chiamate tra servizi con retry e timeout
async function callProductService(productId: string, token: string) {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), 5000) // 5s timeout

  try {
    const response = await fetch(
      `http://svc-products:4300/api/v1/products/${productId}`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'x-correlation-id': req.headers['x-correlation-id']
        },
        signal: controller.signal
      }
    )

    clearTimeout(timeoutId)

    if (!response.ok) {
      throw new Error(`Product service returned ${response.status}`)
    }

    return await response.json()
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error('Product service timeout')
    }
    throw error
  }
}

// Con retry logic
async function callProductServiceWithRetry(productId: string, token: string, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await callProductService(productId, token)
    } catch (error) {
      if (i === retries - 1) throw error
      // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, 2 ** i * 1000))
    }
  }
}
```

### Pattern 3: Error Handling Uniforme

```typescript
// Custom error types
class ValidationError extends Error {
  constructor(public details: unknown) {
    super('Validation failed')
    this.name = 'ValidationError'
  }
}

class NotFoundError extends Error {
  constructor(resource: string) {
    super(`${resource} not found`)
    this.name = 'NotFoundError'
  }
}

class UnauthorizedError extends Error {
  constructor() {
    super('Unauthorized')
    this.name = 'UnauthorizedError'
  }
}

// Error handler globale
app.setErrorHandler((error, req, rep) => {
  req.log.error({
    error,
    correlation_id: req.headers['x-correlation-id'],
    tenant_id: req.authContext?.tenant_id,
    url: req.url
  }, 'Request error')

  if (error instanceof ValidationError) {
    return rep.code(400).send({
      error: error.message,
      details: error.details
    })
  }

  if (error instanceof NotFoundError) {
    return rep.code(404).send({ error: error.message })
  }

  if (error instanceof UnauthorizedError) {
    return rep.code(401).send({ error: error.message })
  }

  // Generic 500
  return rep.code(500).send({
    error: 'Internal server error',
    correlation_id: req.headers['x-correlation-id']
  })
})
```

---

## 🧪 Testing Requirements

### Unit Tests (Obbligatori)

```typescript
// tests/routes/orders.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { build } from '../helper'

describe('POST /api/v1/orders', () => {
  let app

  beforeEach(async () => {
    app = await build()
  })

  it('should create order with valid data', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/orders',
      headers: {
        Authorization: `Bearer ${validToken}`
      },
      payload: {
        product_id: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 2
      }
    })

    expect(response.statusCode).toBe(201)
    expect(response.json()).toHaveProperty('id')
  })

  it('should reject order without authentication', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/orders',
      payload: validOrderData
    })

    expect(response.statusCode).toBe(401)
  })

  it('should enforce tenant isolation', async () => {
    // Create order as tenant A
    const orderA = await createOrder(tenantAToken)

    // Try to access as tenant B
    const response = await app.inject({
      method: 'GET',
      url: `/api/v1/orders/${orderA.id}`,
      headers: { Authorization: `Bearer ${tenantBToken}` }
    })

    expect(response.statusCode).toBe(404) // Not found (isolation working)
  })

  it('should validate required fields', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/orders',
      headers: { Authorization: `Bearer ${validToken}` },
      payload: {
        // Missing product_id
        quantity: 2
      }
    })

    expect(response.statusCode).toBe(400)
    expect(response.json().error).toMatch(/validation/i)
  })
})
```

**Coverage Target:** Minimo 60%, ideale 80%

```bash
npm test -- --coverage
```

---

## 📊 Monitoring & Logging

### Structured Logging

```typescript
// ✅ SEMPRE usare structured logging
req.log.info({
  event: 'order.created',
  order_id: order.id,
  tenant_id: req.authContext.tenant_id,
  user_id: req.authContext.user_id,
  amount: order.total,
  duration_ms: Date.now() - startTime
}, 'Order created successfully')

// Livelli appropriati:
req.log.debug({ query }, 'Executing database query') // Sviluppo
req.log.info({ order_id }, 'Order created') // Operazioni normali
req.log.warn({ tenant_id, limit: 0.8 }, 'Approaching rate limit') // Warning
req.log.error({ error, stack: error.stack }, 'Operation failed') // Errori

// ❌ MAI loggare:
// - Password, JWT tokens, credit cards
// - Dati PII senza mascheramento
// - Usare console.log (usare logger)
```

### Metrics Endpoint

```typescript
// Ogni servizio DEVE esporre metrics
let requestCount = 0
let errorCount = 0
let totalDuration = 0

app.addHook('onRequest', async (req, rep) => {
  req.startTime = Date.now()
})

app.addHook('onResponse', async (req, rep) => {
  const duration = Date.now() - req.startTime
  requestCount++
  totalDuration += duration

  if (rep.statusCode >= 500) {
    errorCount++
  }
})

app.get('/metrics', async () => {
  return {
    requests_total: requestCount,
    errors_total: errorCount,
    avg_duration_ms: requestCount > 0 ? totalDuration / requestCount : 0,
    uptime_seconds: process.uptime()
  }
})
```

---

## 🤝 Coordinamento Multi-Agent

### Lock Mechanism

```bash
# Prima di modificare un servizio:
# 1. Controllare lock esistenti
if [ -f svc-orders/.LOCK_* ]; then
  echo "Service locked by another agent"
  exit 1
fi

# 2. Creare lock
echo "agent-123 - $(date)" > svc-orders/.LOCK_agent-123

# 3. Lavorare...

# 4. Rimuovere lock quando finito
rm svc-orders/.LOCK_agent-123
```

### Status Updates

```markdown
# PROJECT_STATUS.md

## 🚧 Work in Progress

- **svc-orders** (Agent A)
  - Task: Implementing order creation endpoint
  - ETA: 2025-10-05 16:00
  - Blocks: None
  - Contact: @agent-a

- **svc-products** (Agent B)
  - Task: Adding product variants
  - ETA: 2025-10-04 18:00
  - Blocks: svc-orders
  - Contact: @agent-b
```

### Merge Strategy

```bash
# 1. Sempre pull prima di committare
git pull origin main --rebase

# 2. Risolvere conflitti
# Se in dubbio, mantenere versione più recente

# 3. Test dopo merge
npm test

# 4. Commit solo se test passano
git commit -m "feat(svc-orders): implement order creation"
git push origin feature/svc-orders-create
```

---

## ✅ Checklist Pre-Commit

Prima di ogni commit, verificare:

- [ ] Ho letto PROJECT_STATUS.md per stato servizio
- [ ] Ho verificato dipendenze in GUARDRAILS.md
- [ ] Codice segue tech stack definito
- [ ] Tenant isolation implementato (tenant_id in query)
- [ ] Input validation con Zod
- [ ] Error handling uniforme
- [ ] Logging strutturato (no console.log)
- [ ] Test scritti e passanti (min 60% coverage)
- [ ] No dati sensibili loggati
- [ ] Documentazione aggiornata:
  - [ ] PROJECT_STATUS.md
  - [ ] {service}/PROMPT.md
  - [ ] {service}/README.md
  - [ ] CHANGELOG.md (se esiste)
- [ ] Commit message segue Conventional Commits
- [ ] No TODO senza issue reference
- [ ] Lock file rimosso (`.LOCK_*`)

---

## 🚨 Anti-Patterns (DA EVITARE)

### ❌ 1. Assumere che Servizio Esista

```typescript
// ❌ MALE
const product = await fetch('http://svc-products:4300/api/v1/products/123')
// Assume che svc-products sia implementato

// ✅ BENE
// Verificato in PROJECT_STATUS.md che svc-products è SCAFFOLDING
// TODO(@future-agent): Replace with real API when svc-products ready
// Tracked in: PROJECT_STATUS.md → svc-products → ETA: Q1 2026
const product = MOCK_PRODUCT_DATA
```

### ❌ 2. Ignorare Multi-Tenancy

```typescript
// ❌ MALE
const users = await db.query('SELECT * FROM users')

// ✅ BENE
const users = await db.query(
  'SELECT * FROM users WHERE tenant_id = $1',
  [tenant_id]
)
```

### ❌ 3. Hard-Coding Secrets

```typescript
// ❌ MALE
const apiKey = 'sk-abc123...'

// ✅ BENE
const apiKey = process.env.OPENAI_API_KEY
if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

### ❌ 4. Modificare Servizio senza Leggere Stato

```typescript
// ❌ MALE: Inizio subito a codificare

// ✅ BENE: Prima leggo PROJECT_STATUS.md
// Scopro che svc-orders è SCAFFOLDING
// Leggo svc-orders/PROMPT.md per istruzioni
// Verifico dipendenze (svc-products, svc-inventory)
// Poi inizio a codificare
```

### ❌ 5. Committare Codice Non Testato

```bash
# ❌ MALE
git add .
git commit -m "added feature"
git push

# ✅ BENE
npm test # Verificare che test passano
npm run lint # Verificare linting
git add .
git commit -m "feat(svc-orders): implement order creation"
# Solo dopo test passanti
git push origin feature/svc-orders-create
```

---

## 📚 Riferimenti Rapidi

**Documentazione Principale:**
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - Stato servizi
- [GUARDRAILS.md](GUARDRAILS.md) - Regole coordinamento
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architettura sistema
- [CONTEXT_INDEX.md](CONTEXT_INDEX.md) - Indice rapido

**Esempi di Riferimento:**
- **svc-auth** - Servizio completo e production-ready
- **svc-timesheet** - Servizio parziale con migrations complesse
- **app-web-frontend** - Frontend Next.js avanzato

**Tools & Scripts:**
```bash
# Update documentazione
./scripts/update-docs.sh {service} "message"

# Generate context cache
./scripts/generate-context.sh

# Check service status
./scripts/check-status.sh {service}
```

---

## ❓ FAQ

**Q: Da dove inizio?**
A: Leggi CONTEXT_INDEX.md → PROJECT_STATUS.md → servizio specifico PROMPT.md

**Q: Servizio ha dipendenze non implementate?**
A: Documentare blocco in PROJECT_STATUS.md, usare mock + TODO con tracking

**Q: Test non passano?**
A: Fix test prima di committare. Se impossibile, marcare .skip() + issue

**Q: Dubbi su architettura?**
A: Consultare ARCHITECTURE.md. Se ancora dubbi, creare ADR (Architecture Decision Record)

**Q: Conflitto con altro agente?**
A: Verificare lock file, coordinare in PROJECT_STATUS.md sezione "Work in Progress"

**Q: Quanto tempo per task?**
A: Se > 4 ore, task troppo grande. Splittare in sub-tasks

---

## 🎯 TL;DR (Troppo Lungo, Dammi il Riassunto)

1. **SEMPRE** leggere [CONTEXT_INDEX.md](CONTEXT_INDEX.md) e [PROJECT_STATUS.md](PROJECT_STATUS.md) prima di iniziare
2. **SEMPRE** verificare stato servizio (✅ Complete / 🚧 In Progress / 📝 Scaffold)
3. **SEMPRE** seguire tech stack: Fastify + TypeScript (backend), Next.js + React (frontend)
4. **SEMPRE** implementare multi-tenancy (tenant_id in OGNI query)
5. **SEMPRE** validare input con Zod
6. **SEMPRE** error handling uniforme
7. **SEMPRE** logging strutturato (no console.log)
8. **SEMPRE** scrivere test (min 60% coverage)
9. **SEMPRE** aggiornare documentazione (PROJECT_STATUS.md + service PROMPT.md)
10. **SEMPRE** coordination con altri agenti (lock files + status updates)

**Se in dubbio:** LEGGERE [GUARDRAILS.md](GUARDRAILS.md)

**In caso di emergenza:** Documentare problema in PROJECT_STATUS.md e chiedere review

---

**Versione:** 1.0.0
**Ultima revisione:** 2025-10-04
**Prossima revisione:** 2025-10-18
**Maintainer:** Tech Lead Team
**Feedback:** GitHub issue con label "master-prompt"
