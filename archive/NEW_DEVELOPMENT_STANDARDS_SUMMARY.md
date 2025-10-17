# 🚀 EWH Platform - Standard di Sviluppo Aggiornati

**Data:** 15 Ottobre 2025
**Status:** OBBLIGATORIO PER TUTTO LO SVILUPPO
**Basato su:** CODE_ORGANIZATION_STANDARDS.md + PLATFORM_MANDATORY_STANDARDS.md + MASTER_PROMPT.md

---

## ⚡ TL;DR - Regole Principali

### 🎯 Le 5 Regole D'Oro

1. **Una Funzione = Un File** → File separati per ogni funzione
2. **Documentazione Obbligatoria** → JSDoc/TSDoc completi con esempi
3. **Codice Modulare** → Funzioni piccole, testate, riutilizzabili
4. **UI Editabile** → Interfacce costruibili con Page Builder interno
5. **Health Check** → `/health` endpoint obbligatorio per ogni servizio

---

## 📁 1. ORGANIZZAZIONE CODICE (CRITICI!)

### Principio: "Una Funzione = Un File"

**✅ CORRETTO:**
```typescript
// svc-crm/src/controllers/companies/createCompany.ts
/**
 * Create a new company in the CRM
 * @param {CreateCompanyRequest} req - Request with company data
 * @param {Response} res - Response object
 * @returns {Promise<Company>} Created company object
 * @example
 * POST /api/companies
 * Body: { name: "Acme Corp", vat_number: "IT12345" }
 * Response: { id: "uuid", name: "Acme Corp", ... }
 */
export async function createCompany(req: Request, res: Response) {
  const { tenantId, userId } = req.authContext;
  const companyData = await validateCompanyData(req.body);

  // Insert into database
  const company = await insertCompany(tenantId, companyData, userId);

  // Create activity log
  await createActivity({
    entityType: 'company',
    entityId: company.id,
    activityType: 'company_created',
    userId
  });

  return res.status(201).json(company);
}
```

```typescript
// svc-crm/src/services/companies/validateCompanyData.ts
/**
 * Validate company data before insertion
 * @param {unknown} data - Raw input data
 * @returns {CompanyData} Validated company data
 * @throws {ValidationError} If data is invalid
 * @example
 * const validated = await validateCompanyData({ name: "Acme" });
 */
export async function validateCompanyData(data: unknown): Promise<CompanyData> {
  const schema = z.object({
    name: z.string().min(1).max(255),
    vat_number: z.string().optional(),
    email: z.string().email().optional(),
    // ...
  });

  return schema.parse(data);
}
```

```typescript
// svc-crm/src/database/queries/companies/insertCompany.ts
/**
 * Insert new company into database
 * @param {string} tenantId - Tenant ID for multi-tenancy
 * @param {CompanyData} data - Validated company data
 * @param {string} createdBy - User ID who created the company
 * @returns {Promise<Company>} Inserted company with generated ID
 */
export async function insertCompany(
  tenantId: string,
  data: CompanyData,
  createdBy: string
): Promise<Company> {
  const result = await pool.query(`
    INSERT INTO companies (tenant_id, name, vat_number, email, created_by)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `, [tenantId, data.name, data.vat_number, data.email, createdBy]);

  return result.rows[0];
}
```

**❌ SBAGLIATO:**
```typescript
// svc-crm/src/controllers/companies.ts ❌ File unico con tutte le funzioni
export async function createCompany(req, res) { /* ... */ }
export async function getCompany(req, res) { /* ... */ }
export async function updateCompany(req, res) { /* ... */ }
export async function deleteCompany(req, res) { /* ... */ }
export async function listCompanies(req, res) { /* ... */ }
// ❌ Troppe funzioni in un file!
```

### Struttura Directory Obbligatoria

```
svc-example/
├── src/
│   ├── index.ts                           # Entry point (orchestration only)
│   ├── config/
│   │   ├── database.ts                   # DB connection
│   │   ├── env.ts                        # Environment vars
│   │   └── constants.ts                  # Constants
│   ├── routes/
│   │   ├── index.ts                      # Route aggregation
│   │   ├── companies.routes.ts           # Company routes
│   │   └── contacts.routes.ts            # Contact routes
│   ├── controllers/
│   │   ├── companies/
│   │   │   ├── createCompany.ts          # ✅ One function per file
│   │   │   ├── getCompany.ts
│   │   │   ├── updateCompany.ts
│   │   │   ├── deleteCompany.ts
│   │   │   ├── listCompanies.ts
│   │   │   └── index.ts                  # Export all
│   │   └── contacts/
│   │       ├── createContact.ts
│   │       ├── getContact.ts
│   │       └── index.ts
│   ├── services/
│   │   ├── companies/
│   │   │   ├── validateCompanyData.ts    # ✅ Business logic separated
│   │   │   ├── checkCompanyExists.ts
│   │   │   ├── enrichCompanyData.ts
│   │   │   └── index.ts
│   │   └── notifications/
│   │       ├── sendWelcomeEmail.ts
│   │       └── index.ts
│   ├── database/
│   │   ├── queries/
│   │   │   ├── companies/
│   │   │   │   ├── insertCompany.ts      # ✅ SQL queries separated
│   │   │   │   ├── findCompanyById.ts
│   │   │   │   ├── updateCompanyById.ts
│   │   │   │   ├── deleteCompanyById.ts
│   │   │   │   └── index.ts
│   │   │   └── contacts/
│   │   │       ├── insertContact.ts
│   │   │       └── index.ts
│   │   └── pool.ts                       # Connection pool
│   ├── middleware/
│   │   ├── authenticateToken.ts          # ✅ One middleware per file
│   │   ├── checkTenantAccess.ts
│   │   ├── validateRequest.ts
│   │   └── index.ts
│   └── types/
│       ├── Company.ts
│       ├── Contact.ts
│       └── index.ts
├── package.json
├── tsconfig.json
└── README.md
```

---

## 📝 2. DOCUMENTAZIONE OBBLIGATORIA

### JSDoc/TSDoc Completi

**Ogni funzione DEVE avere:**
1. **Descrizione chiara** (cosa fa la funzione)
2. **@param** per ogni parametro
3. **@returns** con tipo di ritorno
4. **@throws** per eccezioni possibili
5. **@example** con caso d'uso reale

**Template Standard:**
```typescript
/**
 * [Descrizione chiara di cosa fa la funzione]
 *
 * @param {Type} paramName - Descrizione del parametro
 * @param {Type} otherParam - Altra descrizione
 * @returns {Promise<ReturnType>} Descrizione del valore di ritorno
 * @throws {ErrorType} Quando l'errore può verificarsi
 *
 * @example
 * // Esempio pratico di utilizzo
 * const result = await functionName(param1, param2);
 * console.log(result); // Expected output
 *
 * @example
 * // Caso d'uso alternativo
 * const result2 = await functionName(differentParam);
 */
export async function functionName(
  paramName: Type,
  otherParam: Type
): Promise<ReturnType> {
  // Implementation
}
```

### Commenti Inline per Logica Complessa

```typescript
export async function calculateDiscount(
  amount: number,
  customerType: string
): Promise<number> {
  // Sconto progressivo basato su tipo cliente e importo
  // - Clienti VIP: 15% fino a €1000, 20% oltre
  // - Clienti Standard: 5% fino a €1000, 10% oltre
  // - Clienti Nuovi: nessuno sconto

  if (customerType === 'vip') {
    return amount > 1000 ? 0.20 : 0.15;
  } else if (customerType === 'standard') {
    return amount > 1000 ? 0.10 : 0.05;
  }

  return 0;
}
```

---

## 🎨 3. UI MODULARE ED EDITABILE

### Principio: "Page Builder First"

**Ogni interfaccia DEVE essere costruibile con il Page Builder interno.**

### Componenti Widget-Based

```typescript
// ✅ CORRETTO: Componente configurabile via Page Builder
interface CompanyCardProps {
  companyId: string;
  layout?: 'compact' | 'detailed' | 'minimal';
  showLogo?: boolean;
  showContacts?: boolean;
  customFields?: string[];
}

/**
 * Company Card Widget - Editable via Page Builder
 * @widget crm.company-card
 * @category CRM
 * @configurable layout, showLogo, showContacts, customFields
 */
export function CompanyCard({
  companyId,
  layout = 'compact',
  showLogo = true,
  showContacts = false,
  customFields = []
}: CompanyCardProps) {
  const { data: company } = useCompany(companyId);

  return (
    <Card layout={layout}>
      {showLogo && <CompanyLogo url={company.logo_url} />}
      <CompanyName>{company.name}</CompanyName>

      {showContacts && (
        <ContactsList companyId={companyId} />
      )}

      {customFields.map(field => (
        <CustomField key={field} name={field} value={company.custom_fields[field]} />
      ))}
    </Card>
  );
}

// Configurazione per Page Builder
CompanyCard.editorConfig = {
  category: 'CRM',
  icon: 'building',
  label: 'Company Card',
  props: {
    companyId: { type: 'company-selector', required: true },
    layout: { type: 'select', options: ['compact', 'detailed', 'minimal'] },
    showLogo: { type: 'boolean', default: true },
    showContacts: { type: 'boolean', default: false },
    customFields: { type: 'multi-select', options: 'dynamic:customFields' }
  }
};
```

### Layout Configurabili

```typescript
// Frontend deve supportare layout drag-and-drop
interface PageLayout {
  id: string;
  name: string;
  sections: Section[];
}

interface Section {
  id: string;
  type: 'row' | 'column' | 'grid';
  widgets: Widget[];
  style?: CSSProperties;
}

interface Widget {
  id: string;
  component: string; // 'CompanyCard', 'ContactList', ecc.
  props: Record<string, any>;
  position: { x: number; y: number; w: number; h: number };
}
```

---

## 🔧 4. BACKEND SERVICES - STANDARD MANDATORI

### Entry Point Standard (index.ts)

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

const app = express();
const PORT = process.env.PORT || 3310;
const SERVICE_NAME = 'svc-crm';

// OBBLIGATORIO: Middleware di base
app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '10mb' }));

// OBBLIGATORIO: Health Check
app.get('/health', async (req, res) => {
  try {
    // Test database connection
    await pool.query('SELECT 1');

    res.json({
      service: SERVICE_NAME,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: '1.0.0',
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      service: SERVICE_NAME,
      status: 'unhealthy',
      error: error.message
    });
  }
});

// OBBLIGATORIO: Service Info
app.get('/', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    version: '1.0.0',
    description: 'Customer Relationship Management',
    endpoints: {
      health: '/health',
      api: '/api',
      docs: '/docs'
    }
  });
});

// API Routes
app.use('/api', routes);

// Error Handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 ${SERVICE_NAME} running on port ${PORT}`);
  console.log(`❤️  Health: http://localhost:${PORT}/health`);
});
```

---

## 🗄️ 5. DATABASE STANDARDS

### Multi-Tenancy Obbligatoria

```typescript
// ✅ SEMPRE filtrare per tenant_id
const companies = await pool.query(`
  SELECT * FROM companies
  WHERE tenant_id = $1 AND user_id = $2
`, [tenantId, userId]);

// ❌ MAI query senza tenant_id
const companies = await pool.query(`
  SELECT * FROM companies WHERE user_id = $1
`, [userId]);
```

### Schema Tabelle Standard

```sql
CREATE TABLE example_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,           -- OBBLIGATORIO

  -- Business fields
  name VARCHAR(255) NOT NULL,

  -- Custom fields (JSONB for flexibility)
  custom_fields JSONB DEFAULT '{}',

  -- Audit fields
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP                -- Soft delete
);

-- OBBLIGATORIO: Index per tenant
CREATE INDEX idx_example_tenant ON example_table(tenant_id) WHERE deleted_at IS NULL;

-- OBBLIGATORIO: Trigger per updated_at
CREATE TRIGGER update_example_updated_at
  BEFORE UPDATE ON example_table
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🎯 6. FRONTEND STANDARDS

### Stack Obbligatorio
- **React 18+** con hooks (NO class components)
- **TypeScript** (mandatory)
- **Vite** per build tool
- **Tailwind CSS** per styling (NO CSS modules, NO styled-components)
- **Tanstack Query** per data fetching
- **Zustand** per state management (NO Redux)

### Configurazione Vite

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5310,
    cors: true,  // ⚠️ IMPORTANTE per iframe in Shell
  }
});
```

### Tailwind Config

```javascript
// tailwind.config.js
const baseConfig = require('../shared/tailwind/tailwind.config.base');

module.exports = {
  ...baseConfig,
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
}
```

---

## 🧪 7. TESTING STANDARDS

```typescript
// tests/createCompany.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { createCompany } from '../src/controllers/companies/createCompany';

describe('createCompany', () => {
  beforeEach(async () => {
    // Setup test database
    await setupTestDb();
  });

  it('should create company successfully', async () => {
    const mockReq = {
      authContext: { tenantId: 'test-tenant', userId: 'test-user' },
      body: { name: 'Acme Corp', vat_number: 'IT12345' }
    };

    const result = await createCompany(mockReq, mockRes);

    expect(result.statusCode).toBe(201);
    expect(result.body.name).toBe('Acme Corp');
  });

  it('should validate required fields', async () => {
    const mockReq = {
      authContext: { tenantId: 'test-tenant', userId: 'test-user' },
      body: {} // Missing name
    };

    await expect(createCompany(mockReq, mockRes)).rejects.toThrow('Validation error');
  });
});
```

---

## 📊 8. PORT ALLOCATION

| Range | Categoria | Esempi |
|-------|-----------|--------|
| 3000-3099 | Core Services | 3000 (API Gateway) |
| 3200-3299 | Media/Content | 3200 (DAM), 3210 (Communications) |
| 3300-3399 | Business | **3310 (CRM)**, 3320 (Inventory) |
| 5300-5399 | Business Frontends | **5310 (CRM UI)** |

---

## ✅ CHECKLIST Pre-Deploy

### Backend Service
- [ ] Struttura directory standard
- [ ] Una funzione = un file
- [ ] JSDoc completi con @example
- [ ] `/health` endpoint implementato
- [ ] Multi-tenancy in tutte le query
- [ ] Error handling completo
- [ ] package.json con script standard
- [ ] README.md con esempi

### Frontend App
- [ ] Componenti widget-based
- [ ] Configurabili da Page Builder
- [ ] Tailwind configurato
- [ ] Vite con CORS abilitato
- [ ] Responsive design
- [ ] Loading states
- [ ] Error boundaries

---

## 🚀 SUMMARY

**Prima di scrivere QUALSIASI codice:**

1. ✅ Leggi [CODE_ORGANIZATION_STANDARDS.md](CODE_ORGANIZATION_STANDARDS.md)
2. ✅ Leggi [PLATFORM_MANDATORY_STANDARDS.md](PLATFORM_MANDATORY_STANDARDS.md)
3. ✅ Una funzione = un file
4. ✅ JSDoc completi
5. ✅ Health check endpoint
6. ✅ Multi-tenancy sempre
7. ✅ UI configurabile via Page Builder

**Qualità > Velocità. Codice manutenibile > Codice veloce.**

---

**Versione:** 1.0
**Ultimo Aggiornamento:** 15 Ottobre 2025
**Autore:** EWH Platform Team
