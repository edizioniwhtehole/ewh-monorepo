# EWH Platform - Development Standards 2025

**Versione:** 2.0
**Data:** 15 Ottobre 2025
**Obiettivo:** Standard uniformi per sviluppo modulare, scalabile e manutenibile

---

## 🏗️ Architettura Generale

### Principi Fondamentali

1. **Modular Monorepo**: Un repository, servizi indipendenti
2. **API-First**: Ogni servizio espone API REST/GraphQL
3. **Microservices-Ready**: Deploy indipendente per ogni servizio
4. **Shared Database con Tenant Isolation**: Multi-tenancy su singolo DB
5. **Event-Driven dove necessario**: NATS/Redis per comunicazione asincrona

### Pattern Architetturale: **3-Tier Modulare**

```
┌─────────────────────────────────────────────────────┐
│              app-shell-frontend (Next.js)           │
│           Single Entry Point - Port 3150            │
└───────────────────────┬─────────────────────────────┘
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    ▼                   ▼                   ▼
┌─────────┐      ┌─────────┐        ┌─────────┐
│ app-pm  │      │ app-crm │   ...  │ app-dam │
│ (5400)  │      │ (5310)  │        │ (3300)  │
│ React   │      │ React   │        │ React   │
└────┬────┘      └────┬────┘        └────┬────┘
     │                │                   │
     ▼                ▼                   ▼
┌─────────┐      ┌─────────┐        ┌─────────┐
│ svc-pm  │      │ svc-crm │   ...  │ svc-dam │
│ (5500)  │      │ (3310)  │        │ (3200)  │
│ Express │      │ Fastify │        │ Express │
└────┬────┘      └────┬────┘        └────┬────┘
     │                │                   │
     └────────────────┼───────────────────┘
                      ▼
            ┌──────────────────┐
            │   PostgreSQL     │
            │   Multi-Tenant   │
            └──────────────────┘
```

---

## 📁 Struttura File Standard

### Backend Service (svc-*)

```
svc-example/
├── src/
│   ├── index.ts                 # Entry point
│   ├── config/
│   │   ├── database.ts          # DB connection
│   │   └── env.ts               # Environment variables
│   ├── middleware/
│   │   ├── auth.ts              # JWT authentication
│   │   ├── tenant.ts            # Multi-tenancy
│   │   ├── validation.ts        # Request validation
│   │   └── rate-limit.ts        # Rate limiting
│   ├── routes/
│   │   ├── index.ts             # Route registration
│   │   ├── items.ts             # Example: /api/items
│   │   └── health.ts            # /health endpoint
│   ├── services/
│   │   ├── item-service.ts      # Business logic
│   │   └── notification.ts      # External integrations
│   ├── models/
│   │   └── item.ts              # Data models/types
│   ├── utils/
│   │   ├── logger.ts            # Winston/Pino logger
│   │   └── errors.ts            # Custom error classes
│   └── types/
│       └── index.ts             # TypeScript types
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

### Frontend App (app-*)

```
app-example-frontend/
├── src/
│   ├── main.tsx                 # Entry point
│   ├── App.tsx                  # Root component
│   ├── components/
│   │   ├── Layout.tsx           # Shared layout
│   │   ├── ui/                  # Reusable UI components
│   │   └── shared/              # Cross-feature components
│   ├── features/
│   │   ├── items/
│   │   │   ├── ItemsList.tsx
│   │   │   ├── ItemDetail.tsx
│   │   │   └── ItemForm.tsx
│   │   └── dashboard/
│   │       └── Dashboard.tsx
│   ├── services/
│   │   └── api.ts               # API client (axios/fetch)
│   ├── hooks/
│   │   ├── useAuth.ts           # Authentication hook
│   │   └── useItems.ts          # Data fetching hooks
│   ├── lib/
│   │   ├── constants.ts         # App constants
│   │   └── utils.ts             # Utility functions
│   ├── types/
│   │   └── index.ts             # TypeScript types
│   └── index.css                # Global styles
├── public/
│   └── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
└── README.md
```

---

## 🎨 Frontend Standards

### Stack Obbligatorio

- **Framework:** React 18.2+ con TypeScript
- **Build Tool:** Vite 5.x
- **Styling:** Tailwind CSS 3.x
- **State Management:** Zustand (piccole app) o Tanstack Query (API state)
- **Routing:** React Router 6.x
- **Forms:** React Hook Form + Zod validation
- **UI Components:** Radix UI primitives + custom styling
- **Icons:** Lucide React

### Configurazione Tailwind (OBBLIGATORIO)

**File:** `tailwind.config.js`
```javascript
const baseConfig = require('../shared/tailwind/tailwind.config.base');

/** @type {import('tailwindcss').Config} */
module.exports = {
  ...baseConfig,
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
}
```

**File:** `postcss.config.js`
```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

**File:** `src/index.css`
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom styles here */
```

### Vite Config Standard

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  server: {
    port: 5xxx, // Assigned port
    cors: true,  // ⚠️ IMPORTANTE per iframe in shell
    proxy: {
      '/api': {
        target: process.env.VITE_API_URL || 'http://localhost:3xxx',
        changeOrigin: true
      }
    }
  }
});
```

### Component Naming & Organization

**✅ DO:**
```typescript
// components/ItemCard.tsx
export default function ItemCard({ item }: ItemCardProps) {
  return <div className="rounded-lg shadow">...</div>;
}

// features/items/ItemsList.tsx
export default function ItemsList() {
  const { data: items } = useItems();
  return <div>...</div>;
}
```

**❌ DON'T:**
```typescript
// components/item-card.tsx  ❌ kebab-case
// components/itemCard.tsx   ❌ camelCase
// features/Items/List.tsx   ❌ Nested capitals
```

### Styling Guidelines

**✅ Usa Tailwind:**
```tsx
<button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
  Click Me
</button>
```

**❌ Evita inline styles:**
```tsx
<button style={{ backgroundColor: 'blue', color: 'white' }}>  ❌
  Click Me
</button>
```

**Quando usare CSS modules:** Solo per animazioni complesse o stili non supportati da Tailwind.

---

## 🔧 Backend Standards

### Stack Obbligatorio

- **Runtime:** Node.js 20+ con TypeScript
- **Framework:** Express (default) o Fastify (performance-critical)
- **Database:** PostgreSQL 16+ con `pg` driver
- **ORM:** Evitato - Query SQL dirette con builder leggero
- **Validation:** Zod
- **Authentication:** JWT (jsonwebtoken)
- **Logging:** Winston o Pino
- **Testing:** Vitest

### Port Allocation Strategy

**Pattern:** `3xxx` per backend, `5xxx` per frontend

| Range | Categoria | Esempi |
|-------|-----------|--------|
| 3000-3099 | Core Services | 3000 (API Gateway) |
| 3100-3199 | Admin/Platform | 3150 (Shell), 3160 (Admin) |
| 3200-3299 | Media/Content | 3200 (DAM), 3210 (Communications) |
| 3300-3399 | Business | 3310 (CRM), 3320 (Inventory) |
| 3400-3499 | Projects | 3400 (PM), 3410 (Timesheet) |
| 5000-5099 | Core Frontends | 5000 (Main Portal) |
| 5100-5199 | Admin Frontends | 5150 (Admin Console) |
| 5200-5299 | Media Frontends | 5200 (DAM UI) |
| 5300-5399 | Business Frontends | 5310 (CRM UI) |
| 5400-5499 | Project Frontends | 5400 (PM UI) |
| 5700-5799 | Communications | 5701 (Email), 5702 (Newsletter) |

### Entry Point Standard (index.ts)

```typescript
import express from 'express';
import cors from 'cors';
import { pool } from './config/database';
import routes from './routes';

const app = express();
const startTime = Date.now();

// Middleware
app.use(cors());
app.use(express.json());

// Health Check (OBBLIGATORIO)
app.get('/health', async (req, res) => {
  const dbHealth = await pool.query('SELECT 1');
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'svc-example',
    version: '1.0.0',
    uptime_seconds: Math.floor((Date.now() - startTime) / 1000),
    dependencies: {
      database: dbHealth ? 'healthy' : 'unhealthy'
    }
  });
});

// API Routes
app.use('/api', routes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found', path: req.url });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = Number(process.env.PORT ?? 3000);
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 svc-example running on port ${PORT}`);
  console.log(`❤️  Health: http://localhost:${PORT}/health`);
});
```

### Authentication Middleware Standard

```typescript
// middleware/auth.ts
import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';

export interface AuthRequest extends Request {
  userId?: string;
  tenantId?: string;
  userRole?: string;
}

export const authenticateJWT = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Missing authorization header' }
    });
  }

  const token = authHeader.replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    req.userId = decoded.userId || decoded.user_id || decoded.sub;
    req.tenantId = decoded.tenantId || decoded.tenant_id;
    req.userRole = decoded.role;
    next();
  } catch (error) {
    return res.status(401).json({
      error: { code: 'INVALID_TOKEN', message: 'Invalid or expired token' }
    });
  }
};

// Optional auth (per endpoint pubblici con dati extra se autenticato)
export const optionalAuth = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return next();
  }

  const token = authHeader.replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    req.userId = decoded.userId;
    req.tenantId = decoded.tenantId;
    req.userRole = decoded.role;
  } catch (error) {
    // Token invalido ma continuiamo come non autenticato
  }

  next();
};
```

### Multi-Tenancy Pattern

**Ogni tabella deve avere `tenant_id`:**

```sql
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,  -- ⚠️ OBBLIGATORIO
  name VARCHAR(255) NOT NULL,
  -- ... other fields
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Index per performance
CREATE INDEX idx_items_tenant ON items(tenant_id);
```

**Middleware per auto-filtrare per tenant:**

```typescript
// middleware/tenant.ts
export const enforceTenant = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  if (!req.tenantId) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Tenant ID required' }
    });
  }
  next();
};

// In query, SEMPRE filtrare per tenant_id
const items = await pool.query(
  'SELECT * FROM items WHERE tenant_id = $1',
  [req.tenantId]
);
```

---

## 🗄️ Database Standards

### Naming Conventions

**Tabelle:** `snake_case`, plurale
```sql
CREATE TABLE user_profiles (...)  ✅
CREATE TABLE UserProfile (...)    ❌
CREATE TABLE user_profile (...)   ❌ singolare
```

**Colonne:** `snake_case`
```sql
first_name VARCHAR(100)  ✅
firstName VARCHAR(100)   ❌
FirstName VARCHAR(100)   ❌
```

**Primary Keys:** Sempre `id UUID`
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()  ✅
id SERIAL PRIMARY KEY                          ❌ (no auto-increment)
user_id UUID PRIMARY KEY                       ❌ (usa solo 'id')
```

**Foreign Keys:** `{table}_id`
```sql
user_id UUID REFERENCES users(id)     ✅
company_id UUID REFERENCES companies(id)  ✅
```

**Timestamps:** Sempre includere
```sql
created_at TIMESTAMP DEFAULT NOW() NOT NULL,
updated_at TIMESTAMP DEFAULT NOW() NOT NULL,
deleted_at TIMESTAMP  -- per soft delete
```

### Migration Files

**Pattern:** `XXX_descriptive_name.sql`

```sql
-- migrations/050_create_crm_tables.sql

-- Companies table
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  -- ...
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_companies_tenant ON companies(tenant_id);
CREATE INDEX idx_companies_name ON companies(name);

-- Trigger per updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔐 Security Standards

### Environment Variables

**File:** `.env` (gitignored)
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/ewhdb

# Authentication
JWT_SECRET=super-secret-change-in-production-min-32-chars
JWT_EXPIRY=7d

# External Services
SENDGRID_API_KEY=SG.xxxxx
TWILIO_ACCOUNT_SID=ACxxxxx
TWILIO_AUTH_TOKEN=xxxxx

# App Config
NODE_ENV=development
PORT=3310
```

**File:** `.env.example` (committed)
```bash
DATABASE_URL=postgresql://user:password@localhost:5432/ewhdb
JWT_SECRET=change-me-in-production
SENDGRID_API_KEY=your-sendgrid-key
```

### Secrets Management

**❌ MAI committare:**
- `.env` file
- API keys
- Passwords
- Private keys

**✅ Usare:**
- `.env` per development locale
- Environment variables su server
- Secrets manager per production (AWS Secrets Manager, Vault)

---

## 📦 Package.json Standard

### Backend (svc-*)

```json
{
  "name": "svc-example",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "jsonwebtoken": "^9.0.2",
    "zod": "^3.22.4",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "@types/express": "^4.17.21",
    "@types/pg": "^8.10.9",
    "tsx": "^4.7.0",
    "typescript": "^5.3.3",
    "vitest": "^1.0.4"
  }
}
```

### Frontend (app-*)

```json
{
  "name": "app-example-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --port 5310",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.1",
    "@tanstack/react-query": "^5.14.2",
    "zustand": "^4.4.7",
    "axios": "^1.6.2",
    "zod": "^3.22.4",
    "lucide-react": "^0.294.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.3.6",
    "typescript": "^5.2.2",
    "vite": "^5.0.8"
  }
}
```

---

## 🧪 Testing Standards

### Backend Tests (Vitest)

```typescript
// src/services/item-service.test.ts
import { describe, it, expect } from 'vitest';
import { createItem } from './item-service';

describe('ItemService', () => {
  it('should create item successfully', async () => {
    const item = await createItem({
      tenantId: 'test-tenant',
      name: 'Test Item'
    });

    expect(item).toBeDefined();
    expect(item.name).toBe('Test Item');
  });
});
```

### Frontend Tests (Vitest + Testing Library)

```typescript
// src/components/ItemCard.test.tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import ItemCard from './ItemCard';

describe('ItemCard', () => {
  it('renders item name', () => {
    render(<ItemCard item={{ id: '1', name: 'Test' }} />);
    expect(screen.getByText('Test')).toBeInTheDocument();
  });
});
```

---

## 📝 Documentation Standards

### README.md Template

```markdown
# svc-example / app-example-frontend

Brief description of what this service/app does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Tech Stack

- Node.js 20+ / React 18+
- Express / Vite
- PostgreSQL / Tailwind CSS

## Installation

\`\`\`bash
npm install
\`\`\`

## Environment Variables

Copy `.env.example` to `.env` and fill in values.

## Development

\`\`\`bash
npm run dev
\`\`\`

## API Endpoints (Backend only)

- `GET /api/items` - List all items
- `POST /api/items` - Create item
- `GET /health` - Health check

## Port

- Backend: 3xxx
- Frontend: 5xxx
```

### Code Comments

**✅ DO comment:**
- Complex business logic
- Non-obvious algorithms
- API integrations
- Workarounds

**❌ DON'T comment:**
- Obvious code
- Variable declarations
- Simple functions

```typescript
// ✅ Good
// Calcola sconto progressivo: 5% fino a €1000, 10% oltre
const discount = amount > 1000 ? 0.10 : 0.05;

// ❌ Bad
// Set discount variable
const discount = 0.05;
```

---

## 🚀 Deployment Standards

### Docker Support (Opzionale ma raccomandato)

```dockerfile
# Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN npm run build

CMD ["npm", "start"]
```

### Health Checks

**Ogni servizio DEVE esporre `/health`:**

```typescript
app.get('/health', async (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'svc-example',
    version: process.env.npm_package_version,
    uptime_seconds: process.uptime(),
    dependencies: {
      database: await checkDB(),
      redis: await checkRedis()
    }
  });
});
```

---

## 🎯 Git Standards

### Branch Naming

- `main` - Production-ready code
- `develop` - Development branch
- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring

### Commit Messages

**Format:** `type(scope): message`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation
- `style`: Formatting
- `test`: Tests
- `chore`: Build/config

**Examples:**
```
feat(crm): add custom fields support
fix(email): resolve SMTP timeout issue
refactor(auth): simplify JWT middleware
docs(readme): update installation steps
```

---

## ✅ Checklist per Nuovo Servizio

### Backend (svc-*)

- [ ] Struttura cartelle standard
- [ ] `package.json` con script dev/build/start
- [ ] `tsconfig.json` configurato
- [ ] `.env.example` creato
- [ ] Health endpoint implementato
- [ ] Authentication middleware (se necessario)
- [ ] Tenant middleware (multi-tenancy)
- [ ] Migration SQL per tabelle
- [ ] README.md completo
- [ ] Port allocato e documentato

### Frontend (app-*)

- [ ] Struttura cartelle standard
- [ ] `tailwind.config.js` configurato
- [ ] `postcss.config.js` configurato
- [ ] `vite.config.ts` con CORS abilitato
- [ ] `index.css` con Tailwind imports
- [ ] Layout component creato
- [ ] API service client configurato
- [ ] README.md completo
- [ ] Port allocato e documentato

### Integration

- [ ] Registrato in `app-shell-frontend/src/lib/services.config.ts`
- [ ] Testato standalone (direct URL)
- [ ] Testato in shell (iframe)
- [ ] CORS verificato
- [ ] Database migration applicata

---

## 🆕 Novità 2025

### 1. **Shared Utilities Package** (In Development)

Location: `/shared/packages/`

Utilities condivise:
- `@ewh/auth` - Authentication helpers
- `@ewh/ui` - Shared React components
- `@ewh/utils` - Common utilities
- `@ewh/types` - Shared TypeScript types

### 2. **API Gateway Pattern** (Planned)

Centralizzare routing tramite gateway:

```
Client → API Gateway (3000) → svc-crm (3310)
                            → svc-pm (5500)
                            → svc-email (3211)
```

Benefits:
- Unified authentication
- Rate limiting centrale
- API versioning
- Load balancing

### 3. **Event Bus** (Planned)

NATS.io per eventi cross-service:

```typescript
// Publish event
eventBus.publish('crm.company.created', {
  companyId: '...',
  tenantId: '...'
});

// Subscribe
eventBus.subscribe('crm.company.created', async (data) => {
  // Auto-create PM workspace
});
```

---

**Ultimo aggiornamento:** 15 Ottobre 2025

Per domande o suggerimenti, contattare il team di architettura.
