# 🚀 PM Enterprise - Kickoff Plan

**Data**: 2025-10-12
**Obiettivo**: Da MVP a Enterprise in 6 mesi
**Investment**: €200k
**Team**: 3 engineers (2 backend + 1 DevOps)

---

## 🎯 Sprint 1 (Week 1-2): Multi-Tenant Foundation

### Obiettivo
Trasformare il sistema da single-tenant a multi-tenant con isolamento completo.

### Tasks Prioritizzate

#### 1. Database: Row-Level Security (Giorno 1-2)
```sql
-- migrations/100_enable_rls.sql

-- Enable RLS on all PM tables
ALTER TABLE pm.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm.project_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm.time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm.comments ENABLE ROW LEVEL SECURITY;

-- Function to set tenant context
CREATE OR REPLACE FUNCTION set_tenant_context(p_tenant_id uuid)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_tenant_id', p_tenant_id::text, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy: Users can only see their tenant's data
CREATE POLICY tenant_isolation_select ON pm.projects
  FOR SELECT
  USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

CREATE POLICY tenant_isolation_insert ON pm.projects
  FOR INSERT
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

CREATE POLICY tenant_isolation_update ON pm.projects
  FOR UPDATE
  USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

CREATE POLICY tenant_isolation_delete ON pm.projects
  FOR DELETE
  USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Repeat for all PM tables
\echo 'Applying RLS to pm.tasks...'
CREATE POLICY tenant_isolation_select ON pm.tasks
  FOR SELECT USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
CREATE POLICY tenant_isolation_insert ON pm.tasks
  FOR INSERT WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
CREATE POLICY tenant_isolation_update ON pm.tasks
  FOR UPDATE USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
CREATE POLICY tenant_isolation_delete ON pm.tasks
  FOR DELETE USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- ... ripetere per tutte le tabelle PM
```

**Deliverable**: Database con RLS attivo

---

#### 2. Backend: Tenant Middleware (Giorno 3-4)
```typescript
// svc-pm/src/middleware/tenant.ts

import { FastifyRequest, FastifyReply } from 'fastify'
import { db } from '../database'

interface TenantContext {
  id: string
  subdomain: string
  name: string
  features: Record<string, boolean>
}

declare module 'fastify' {
  interface FastifyRequest {
    tenantId: string
    tenant: TenantContext
  }
}

export async function tenantMiddleware(
  req: FastifyRequest,
  rep: FastifyReply
) {
  // 1. Resolve tenant from request
  const tenant = await resolveTenant(req)

  if (!tenant) {
    return rep.code(400).send({
      error: 'Cannot identify tenant',
      hint: 'Use subdomain or X-Tenant-ID header'
    })
  }

  // 2. Set tenant context
  req.tenantId = tenant.id
  req.tenant = tenant

  // 3. Set database session variable (for RLS)
  await db.query('SELECT set_tenant_context($1)', [tenant.id])

  // 4. Log tenant context
  req.log = req.log.child({ tenant_id: tenant.id })
}

async function resolveTenant(req: FastifyRequest): Promise<TenantContext | null> {
  // Strategy 1: Subdomain (acme.polosaas.it)
  const hostname = req.hostname
  if (hostname.includes('.polosaas.it') && !hostname.startsWith('www')) {
    const subdomain = hostname.split('.')[0]
    return await getTenantBySubdomain(subdomain)
  }

  // Strategy 2: Header (for API clients)
  const tenantId = req.headers['x-tenant-id'] as string
  if (tenantId) {
    return await getTenantById(tenantId)
  }

  // Strategy 3: Custom domain (future)
  // return await getTenantByDomain(hostname)

  return null
}

async function getTenantBySubdomain(subdomain: string): Promise<TenantContext | null> {
  const result = await db.query(`
    SELECT id, subdomain, name, features
    FROM tenants
    WHERE subdomain = $1 AND active = true
  `, [subdomain])

  if (result.rows.length === 0) return null

  return result.rows[0]
}

async function getTenantById(id: string): Promise<TenantContext | null> {
  const result = await db.query(`
    SELECT id, subdomain, name, features
    FROM tenants
    WHERE id = $1 AND active = true
  `, [id])

  if (result.rows.length === 0) return null

  return result.rows[0]
}
```

**Registra il middleware**:
```typescript
// svc-pm/src/index.ts

import { tenantMiddleware } from './middleware/tenant'

// Apply to all routes
fastify.addHook('preHandler', tenantMiddleware)

// Or apply selectively
fastify.register(async (app) => {
  app.addHook('preHandler', tenantMiddleware)

  // All these routes are tenant-aware
  app.get('/api/pm/projects', ...)
  app.post('/api/pm/tasks', ...)
  // ...
})
```

**Deliverable**: Backend con tenant context automatico

---

#### 3. Frontend: Tenant Detection (Giorno 5)
```typescript
// app-pm-frontend/src/services/tenant.ts

interface TenantInfo {
  id: string
  name: string
  subdomain: string
  logo?: string
  primaryColor?: string
}

class TenantService {
  private tenantInfo: TenantInfo | null = null

  async detect(): Promise<TenantInfo> {
    // 1. Try to get from subdomain
    const hostname = window.location.hostname
    if (hostname.includes('.polosaas.it')) {
      const subdomain = hostname.split('.')[0]
      return this.fetchBySubdomain(subdomain)
    }

    // 2. Try to get from localStorage (for localhost dev)
    const cachedTenant = localStorage.getItem('tenant_id')
    if (cachedTenant) {
      return this.fetchById(cachedTenant)
    }

    // 3. Prompt user to select tenant (for multi-tenant admins)
    return this.promptTenantSelection()
  }

  async fetchBySubdomain(subdomain: string): Promise<TenantInfo> {
    const res = await fetch(`/api/tenants/by-subdomain/${subdomain}`)
    const data = await res.json()
    this.tenantInfo = data.tenant
    return this.tenantInfo
  }

  getCurrentTenant(): TenantInfo | null {
    return this.tenantInfo
  }
}

export const tenantService = new TenantService()
```

**Update API service**:
```typescript
// app-pm-frontend/src/services/api.ts

import { tenantService } from './tenant'

export const api = {
  async getProjects() {
    const tenant = tenantService.getCurrentTenant()

    const res = await fetch('/api/pm/projects', {
      headers: {
        'X-Tenant-ID': tenant!.id
      }
    })

    return res.json()
  },

  // ... rest of API methods
}
```

**Deliverable**: Frontend tenant-aware

---

#### 4. Tenant Management (Giorno 6-7)
```sql
-- migrations/101_tenants_table.sql

CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  subdomain VARCHAR(50) NOT NULL UNIQUE,
  custom_domain VARCHAR(100) UNIQUE,

  -- Plan & limits
  plan VARCHAR(20) NOT NULL DEFAULT 'starter',
  max_projects INTEGER DEFAULT 10,
  max_users INTEGER DEFAULT 5,
  max_storage_gb INTEGER DEFAULT 10,

  -- Branding
  logo_url TEXT,
  primary_color VARCHAR(7) DEFAULT '#4CAF50',
  favicon_url TEXT,

  -- Features
  features JSONB DEFAULT '{
    "ai_assignment": false,
    "gantt_chart": false,
    "time_tracking": true,
    "budget_tracking": false,
    "custom_fields": true
  }'::jsonb,

  -- Status
  active BOOLEAN DEFAULT true,
  trial_ends_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed demo tenants
INSERT INTO tenants (id, name, subdomain, plan, features) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Demo Publishing', 'demo', 'professional', '{
    "ai_assignment": true,
    "gantt_chart": true,
    "time_tracking": true,
    "budget_tracking": true
  }'),
  ('00000000-0000-0000-0000-000000000002', 'Acme Corp', 'acme', 'enterprise', '{
    "ai_assignment": true,
    "gantt_chart": true,
    "time_tracking": true,
    "budget_tracking": true,
    "custom_fields": true,
    "sso": true
  }'),
  ('00000000-0000-0000-0000-000000000003', 'Startup Inc', 'startup', 'starter', '{
    "ai_assignment": false,
    "gantt_chart": false,
    "time_tracking": true
  }');
```

**Admin UI for tenant management**:
```tsx
// app-admin-frontend/src/pages/Tenants.tsx

export function TenantsPage() {
  const [tenants, setTenants] = useState<Tenant[]>([])

  return (
    <AdminLayout>
      <PageHeader title="Tenants" />

      <TenantsList>
        {tenants.map(tenant => (
          <TenantCard key={tenant.id}>
            <TenantLogo src={tenant.logoUrl} />
            <TenantName>{tenant.name}</TenantName>
            <TenantSubdomain>{tenant.subdomain}.polosaas.it</TenantSubdomain>
            <TenantPlan>{tenant.plan}</TenantPlan>
            <TenantStatus active={tenant.active} />

            <Actions>
              <Button onClick={() => editTenant(tenant.id)}>Edit</Button>
              <Button onClick={() => viewMetrics(tenant.id)}>Metrics</Button>
              <Button onClick={() => impersonate(tenant.id)}>Login As</Button>
            </Actions>
          </TenantCard>
        ))}
      </TenantsList>

      <Button onClick={createNewTenant}>+ New Tenant</Button>
    </AdminLayout>
  )
}
```

**Deliverable**: Tenant management completo

---

#### 5. Testing (Giorno 8-10)
```typescript
// svc-pm/tests/multi-tenant.test.ts

import { describe, it, expect, beforeAll } from 'vitest'
import { app } from '../src/index'

describe('Multi-Tenant Isolation', () => {
  let tenant1Id: string
  let tenant2Id: string
  let tenant1Token: string
  let tenant2Token: string

  beforeAll(async () => {
    // Setup 2 tenants
    tenant1Id = '00000000-0000-0000-0000-000000000001'
    tenant2Id = '00000000-0000-0000-0000-000000000002'

    // Create projects for each tenant
    await createProject(tenant1Id, 'Tenant 1 Project')
    await createProject(tenant2Id, 'Tenant 2 Project')
  })

  it('should only return projects for current tenant', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/pm/projects',
      headers: {
        'X-Tenant-ID': tenant1Id
      }
    })

    expect(res.statusCode).toBe(200)
    const projects = res.json().data

    // Should only see tenant 1's projects
    expect(projects).toHaveLength(1)
    expect(projects[0].tenantId).toBe(tenant1Id)
  })

  it('should prevent cross-tenant data access', async () => {
    // Get project ID from tenant 2
    const tenant2Projects = await getProjects(tenant2Id)
    const projectId = tenant2Projects[0].id

    // Try to access from tenant 1
    const res = await app.inject({
      method: 'GET',
      url: `/api/pm/projects/${projectId}`,
      headers: {
        'X-Tenant-ID': tenant1Id
      }
    })

    // Should return 404 (not found) not 403 (forbidden)
    // to prevent tenant enumeration
    expect(res.statusCode).toBe(404)
  })

  it('should enforce tenant context in all operations', async () => {
    // Create task with wrong tenant_id in body
    const res = await app.inject({
      method: 'POST',
      url: '/api/pm/tasks',
      headers: {
        'X-Tenant-ID': tenant1Id
      },
      payload: {
        projectId: 'some-project-id',
        tenantId: tenant2Id,  // Trying to create for different tenant
        taskName: 'Malicious Task'
      }
    })

    // Should fail or override with correct tenant
    expect(res.statusCode).toBe(403)
  })
})
```

**Deliverable**: Test suite per multi-tenant

---

### Sprint 1 Summary

**Deliverables**:
- ✅ Database con Row-Level Security
- ✅ Backend tenant middleware
- ✅ Frontend tenant detection
- ✅ Tenant management UI
- ✅ Test suite completo

**Timeline**: 10 giorni lavorativi (2 settimane)
**Team**: 2 backend engineers
**Output**: Sistema multi-tenant funzionante e sicuro

---

## 📋 Checklist Sprint 1

### Database
- [ ] Migration 100: Enable RLS on all tables
- [ ] Migration 101: Create tenants table
- [ ] Seed demo tenants
- [ ] Test RLS policies manually

### Backend
- [ ] Implement tenant middleware
- [ ] Add tenant resolution logic
- [ ] Update all API endpoints to use tenant context
- [ ] Add tenant validation
- [ ] Error handling for missing tenant

### Frontend
- [ ] Tenant detection service
- [ ] Update API client to include tenant ID
- [ ] Handle tenant selection UI
- [ ] Cache tenant info locally

### Admin
- [ ] Tenant list page
- [ ] Tenant creation form
- [ ] Tenant edit form
- [ ] Tenant metrics dashboard

### Testing
- [ ] Unit tests for tenant middleware
- [ ] Integration tests for RLS
- [ ] End-to-end tests for tenant isolation
- [ ] Security audit (penetration test)

### Documentation
- [ ] Multi-tenant architecture doc
- [ ] API documentation update
- [ ] Admin guide for tenant management
- [ ] Developer guide for tenant-aware code

---

## 🚀 Come Iniziare OGGI

### Step 1: Setup Dev Environment (30 min)
```bash
# 1. Create feature branch
git checkout -b feature/multi-tenant

# 2. Create migration file
touch migrations/100_enable_rls.sql

# 3. Create middleware folder
mkdir -p svc-pm/src/middleware
touch svc-pm/src/middleware/tenant.ts

# 4. Create test file
mkdir -p svc-pm/tests
touch svc-pm/tests/multi-tenant.test.ts
```

### Step 2: Implement RLS (2 hours)
```bash
# Edit migrations/100_enable_rls.sql
# Copy content from above

# Apply migration
psql -h localhost -U ewh -d ewh_master -f migrations/100_enable_rls.sql

# Verify
psql -h localhost -U ewh -d ewh_master -c "
  SELECT schemaname, tablename, rowsecurity
  FROM pg_tables
  WHERE schemaname = 'pm';
"
```

### Step 3: Implement Middleware (4 hours)
```bash
# Edit svc-pm/src/middleware/tenant.ts
# Copy content from above

# Register in svc-pm/src/index.ts
# Test locally
npm run dev

# Test with curl
curl -H "X-Tenant-ID: 00000000-0000-0000-0000-000000000001" \
  http://localhost:5500/api/pm/projects
```

### Step 4: Test End-to-End (1 hour)
```bash
# Run tests
cd svc-pm
npm test

# Manual test with 2 tenants
curl -H "X-Tenant-ID: tenant-1" http://localhost:5500/api/pm/projects
curl -H "X-Tenant-ID: tenant-2" http://localhost:5500/api/pm/projects

# Verify isolation
```

---

## 📊 Success Metrics Sprint 1

### Technical
- [ ] 100% of PM tables have RLS enabled
- [ ] 0 cross-tenant data leaks in tests
- [ ] Tenant middleware has < 5ms overhead
- [ ] All API endpoints are tenant-aware

### Business
- [ ] Can create 3+ test tenants
- [ ] Each tenant sees only their data
- [ ] Admin can switch between tenants
- [ ] Ready for first enterprise customer

---

## 🎯 Next Sprint Preview

**Sprint 2 (Week 3-4): RBAC**
- Permission model
- Role management
- Permission middleware
- Admin UI for roles

**Sprint 3 (Week 5-6): Audit Logging**
- Audit event capture
- Immutable log storage
- Audit viewer UI
- Alerting rules

---

**Status**: 🚀 **Ready to Start Sprint 1**
**Next Action**: Review plan and begin implementation
**Timeline**: 2 weeks to multi-tenant ready
**Team**: 2 backend engineers

💪 **Let's build Enterprise-grade PM!**
