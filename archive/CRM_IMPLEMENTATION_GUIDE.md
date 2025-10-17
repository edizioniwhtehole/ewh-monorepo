# svc-crm Implementation Guide

**Status:** Struttura creata, implementazione in corso
**Standard:** Una Funzione = Un File (OBBLIGATORIO)

---

## ✅ COMPLETATO

### 1. Struttura Directory
```
svc-crm/src/
├── config/
│   ├── database.ts ✅
│   ├── env.ts ✅
│   └── constants.ts ✅
├── types/
│   └── index.ts ✅
├── routes/
├── controllers/companies/
├── services/companies/
├── database/queries/companies/
└── middleware/
```

### 2. Database
- ✅ Migration 060_crm_complete_system.sql applicata
- ✅ 7 tabelle create
- ✅ Trigger configurati

---

## 📋 DA COMPLETARE

### STEP 1: Database Queries (Una funzione = un file)

Creare in `src/database/queries/companies/`:

**insertCompany.ts:**
```typescript
import { pool } from '../../../config/database';
import type { Company } from '../../../types';

export async function insertCompany(
  tenantId: string,
  data: Partial<Company>,
  createdBy: string
): Promise<Company> {
  const result = await pool.query(`
    INSERT INTO companies (
      tenant_id, name, type, email, phone, website,
      status, created_by
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
  `, [tenantId, data.name, data.type, data.email, data.phone, data.website, data.status || 'active', createdBy]);

  return result.rows[0];
}
```

**findCompanyById.ts**, **updateCompanyById.ts**, **deleteCompanyById.ts**, **listCompanies.ts**

### STEP 2: Middleware

**src/middleware/auth.ts:**
```typescript
import type { Request, Response, NextFunction } from 'express';

export async function authenticateToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Simplified for dev - parse tenant/user from header
  (req as any).authContext = {
    tenantId: req.headers['x-tenant-id'] || '00000000-0000-0000-0000-000000000001',
    userId: req.headers['x-user-id'] || '00000000-0000-0000-0000-000000000001'
  };
  next();
}
```

### STEP 3: Controllers

**src/controllers/companies/createCompany.ts:**
```typescript
import type { Request, Response } from 'express';
import { insertCompany } from '../../database/queries/companies/insertCompany';

export async function createCompany(req: Request, res: Response) {
  try {
    const { tenantId, userId } = (req as any).authContext;
    const company = await insertCompany(tenantId, req.body, userId);
    res.status(201).json(company);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
```

### STEP 4: Routes

**src/routes/companies.ts:**
```typescript
import { Router } from 'express';
import { createCompany } from '../controllers/companies/createCompany';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

router.post('/', createCompany);
// router.get('/:id', getCompany);
// router.put('/:id', updateCompany);
// router.delete('/:id', deleteCompany);
// router.get('/', listCompanies);

export default router;
```

### STEP 5: Entry Point

**src/index.ts:**
```typescript
import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import { testConnection } from './config/database';
import companiesRouter from './routes/companies';

const app = express();

app.use(cors({ origin: '*' }));
app.use(express.json());

// Health Check
app.get('/health', async (req, res) => {
  const dbConnected = await testConnection();
  res.json({
    service: env.SERVICE_NAME,
    status: dbConnected ? 'healthy' : 'unhealthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Routes
app.use('/api/companies', companiesRouter);

app.listen(Number(env.PORT), '0.0.0.0', () => {
  console.log(`🚀 ${env.SERVICE_NAME} running on port ${env.PORT}`);
});
```

---

## 🧪 TEST

```bash
# Create company
curl -X POST http://localhost:3310/api/companies \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: 00000000-0000-0000-0000-000000000001" \
  -H "x-user-id: 00000000-0000-0000-0000-000000000001" \
  -d '{
    "name": "Acme Corp",
    "type": "client",
    "email": "info@acme.com",
    "phone": "+39 02 1234567",
    "website": "https://acme.com"
  }'
```

---

## 📦 Dependencies da installare

```bash
cd /Users/andromeda/dev/ewh/svc-crm
npm install express cors pg
npm install -D @types/express @types/cors @types/pg tsx typescript
```

---

## 🚀 Prossimi Step

1. Completare Companies CRUD (5 funzioni)
2. Aggiungere Contacts CRUD
3. Aggiungere Notes API
4. Frontend app-crm-frontend

**Tempo stimato:** 4-6 ore
