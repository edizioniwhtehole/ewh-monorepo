# 🚀 Implementation Roadmap - Complete System

## Status: Ready to Execute

---

## 📦 NEW SERVICES TO CREATE

### 1. svc-inventory (Port 6400)
**Status:** ✅ Structure created
**Next Steps:**
```bash
cd /Users/andromeda/dev/ewh/svc-inventory
npm install
```

**Schema:**
```sql
inventory.items (SKU, product master)
inventory.stock (giacenze per location)
inventory.movements (transazioni)
inventory.locations (magazzini)
inventory.lots (lotti e scadenze)
inventory.inventory_counts (conteggi fisici)
```

**Features:**
- CRUD items/SKU
- Stock management per location
- Movement tracking (in/out)
- Lot/serial number tracking
- Physical inventory counts
- Reorder point alerts
- Barcode support

**API Endpoints:**
```
GET/POST   /api/inventory/items
GET/PUT    /api/inventory/items/:id
GET/POST   /api/inventory/stock
POST       /api/inventory/movements
GET/POST   /api/inventory/locations
GET        /api/inventory/items/:id/history
POST       /api/inventory/count/start
PUT        /api/inventory/count/:id/complete
```

### 2. svc-orders-purchase (Port 6200)
**Status:** 🔨 To create

**Schema:**
```sql
orders.purchase_orders
orders.po_line_items
orders.goods_receipts
orders.supplier_performance
```

**Features:**
- Create PO from RFQ
- Create PO from MRP
- Track PO status
- Goods receipt
- Quality control
- Supplier performance tracking
- Link to inventory (auto-stock on receipt)

### 3. svc-orders-sales (Port 6300)
**Status:** 🔨 To create

**Schema:**
```sql
orders.sales_orders
orders.so_line_items
orders.shipments
orders.delivery_notes
orders.customer_stats
```

**Features:**
- Create SO from quote
- Create SO from ecommerce
- Stock reservation
- Fulfillment workflow
- Shipping management
- Invoice generation
- Customer order history

### 4. svc-pricelists-purchase (Port 6500)
**Status:** 🔨 To create

**Schema:**
```sql
pricelists.supplier_pricelists
pricelists.pricelist_items
pricelists.price_breaks (quantity-based)
pricelists.price_history
pricelists.best_price_cache
```

**Features:**
- Supplier pricelists
- Quantity price breaks
- Validity periods
- Currency support
- Price history tracking
- Best price engine
- AI anomaly detection (via svc-ai-pricing)

### 5. svc-pricelists-sales (Port 6600)
**Status:** 🔨 To create

**Schema:**
```sql
pricelists.customer_pricelists
pricelists.pricelist_rules
pricelists.promotions
pricelists.margin_rules
pricelists.competitive_intel
```

**Features:**
- Customer pricelists
- Pricelist by category (Gold/Silver/Bronze)
- Custom pricelists
- Margin protection rules
- Promotions & discounts
- Market price validation (via Perplexity AI)

### 6. svc-ai-pricing (Port 6000) 🤖
**Status:** 🔨 To create - HIGH PRIORITY

**Features:**
- Perplexity API integration
- Market price research
- RFQ reverse engineering
- Cost curve analysis
- Margin validation
- Price optimization suggestions
- Anomaly detection

**API Endpoints:**
```
POST /api/ai/pricing/market-research
POST /api/ai/pricing/reverse-engineer-rfq
POST /api/ai/pricing/validate-margin
POST /api/ai/pricing/suggest-price
GET  /api/ai/pricing/competitive-intel/:product
```

### 7. svc-mrp (Port 6700)
**Status:** 🔨 To create

**Schema:**
```sql
mrp.bills_of_materials
mrp.bom_components
mrp.production_orders
mrp.material_requirements
mrp.capacity_planning
```

**Features:**
- BOM management
- MRP calculation
- Production scheduling
- Material requirements
- Capacity planning
- Work orders
- Shop floor integration

---

## ⚙️ SETTINGS SYSTEM IMPLEMENTATION

### Phase 1: Database Migration (ALL services)
```bash
# Apply to existing databases
psql -U ewh -d ewh_master < migrations-shared/001_settings_waterfall.sql
```

### Phase 2: Add Settings API (template for all services)

**File:** `src/routes/settings.ts`
```typescript
import { FastifyInstance } from 'fastify';
import { Pool } from 'pg';

export async function registerSettingsRoutes(fastify: FastifyInstance, db: Pool) {

  // Get effective setting (resolved with inheritance)
  fastify.get('/api/settings/:key/effective', async (req, reply) => {
    const { key } = req.params as { key: string };
    const userId = req.headers['x-user-id'] as string;
    const tenantId = req.headers['x-tenant-id'] as string;

    const value = await resolveSettings(db, key, userId, tenantId);
    reply.send({ success: true, data: value });
  });

  // Tenant settings CRUD
  fastify.get('/api/settings', async (req, reply) => {
    const tenantId = req.headers['x-tenant-id'] as string;
    const result = await db.query(
      'SELECT * FROM tenant_settings WHERE tenant_id = $1',
      [tenantId]
    );
    reply.send({ success: true, data: result.rows });
  });

  fastify.put('/api/settings/:key', async (req, reply) => {
    const { key } = req.params as { key: string };
    const { value } = req.body as { value: any };
    const tenantId = req.headers['x-tenant-id'] as string;

    // Check if platform setting is locked
    const platformSetting = await db.query(
      'SELECT is_locked, lock_type FROM platform_settings WHERE setting_key = $1',
      [key]
    );

    if (platformSetting.rows[0]?.is_locked && platformSetting.rows[0].lock_type === 'hard') {
      return reply.code(403).send({
        success: false,
        error: 'Setting is locked by platform administrator'
      });
    }

    await db.query(
      `INSERT INTO tenant_settings (tenant_id, setting_key, setting_value, override_platform)
       VALUES ($1, $2, $3, true)
       ON CONFLICT (tenant_id, setting_key)
       DO UPDATE SET setting_value = $3, override_platform = true, updated_at = NOW()`,
      [tenantId, key, JSON.stringify(value)]
    );

    reply.send({ success: true });
  });

  // User settings
  fastify.get('/api/user/settings', async (req, reply) => {
    const userId = req.headers['x-user-id'] as string;
    const tenantId = req.headers['x-tenant-id'] as string;

    const result = await db.query(
      'SELECT * FROM user_settings WHERE user_id = $1 AND tenant_id = $2',
      [userId, tenantId]
    );
    reply.send({ success: true, data: result.rows });
  });

  fastify.put('/api/user/settings/:key', async (req, reply) => {
    const { key } = req.params as { key: string };
    const { value } = req.body as { value: any };
    const userId = req.headers['x-user-id'] as string;
    const tenantId = req.headers['x-tenant-id'] as string;

    // Check if tenant setting is locked
    const tenantSetting = await db.query(
      'SELECT is_locked, lock_type FROM tenant_settings WHERE tenant_id = $1 AND setting_key = $2',
      [tenantId, key]
    );

    if (tenantSetting.rows[0]?.is_locked && tenantSetting.rows[0].lock_type === 'hard') {
      return reply.code(403).send({
        success: false,
        error: 'Setting is locked by organization'
      });
    }

    await db.query(
      `INSERT INTO user_settings (user_id, tenant_id, setting_key, setting_value, override_tenant)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (user_id, tenant_id, setting_key)
       DO UPDATE SET setting_value = $4, override_tenant = true, updated_at = NOW()`,
      [userId, tenantId, key, JSON.stringify(value)]
    );

    reply.send({ success: true });
  });

  // Admin settings (owner only)
  fastify.get('/api/admin/settings', async (req, reply) => {
    const platformRole = req.headers['x-platform-role'] as string;
    if (platformRole !== 'owner') {
      return reply.code(403).send({ success: false, error: 'Owner role required' });
    }

    const result = await db.query('SELECT * FROM platform_settings');
    reply.send({ success: true, data: result.rows });
  });

  fastify.put('/api/admin/settings/:key', async (req, reply) => {
    const platformRole = req.headers['x-platform-role'] as string;
    if (platformRole !== 'owner') {
      return reply.code(403).send({ success: false, error: 'Owner role required' });
    }

    const { key } = req.params as { key: string };
    const { value, is_locked, lock_type } = req.body as any;

    await db.query(
      `INSERT INTO platform_settings (setting_key, setting_value, is_locked, lock_type)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (setting_key)
       DO UPDATE SET setting_value = $2, is_locked = $3, lock_type = $4, updated_at = NOW()`,
      [key, JSON.stringify(value), is_locked, lock_type]
    );

    reply.send({ success: true });
  });
}

async function resolveSettings(db: Pool, key: string, userId?: string, tenantId?: string) {
  // 1. Get platform default
  const platform = await db.query(
    'SELECT setting_value, is_locked, lock_type FROM platform_settings WHERE setting_key = $1',
    [key]
  );

  let value = platform.rows[0]?.setting_value;
  let isLocked = platform.rows[0]?.is_locked || false;
  let source = 'platform';

  // 2. Apply tenant override if not locked
  if (tenantId && !isLocked) {
    const tenant = await db.query(
      'SELECT setting_value, is_locked, override_platform FROM tenant_settings WHERE tenant_id = $1 AND setting_key = $2',
      [tenantId, key]
    );
    if (tenant.rows[0]?.override_platform) {
      value = tenant.rows[0].setting_value;
      isLocked = tenant.rows[0].is_locked;
      source = 'tenant';
    }
  }

  // 3. Apply user override if not locked
  if (userId && !isLocked) {
    const user = await db.query(
      'SELECT setting_value, override_tenant FROM user_settings WHERE user_id = $1 AND tenant_id = $2 AND setting_key = $3',
      [userId, tenantId, key]
    );
    if (user.rows[0]?.override_tenant) {
      value = user.rows[0].setting_value;
      source = 'user';
    }
  }

  return {
    value,
    source,
    is_locked: isLocked,
    can_override: !isLocked
  };
}
```

### Phase 3: Frontend Settings Pages

**Template for `/settings` (tenant):**
```typescript
// app-*/src/pages/settings.tsx
import { useState, useEffect } from 'react';

export default function TenantSettings() {
  const [settings, setSettings] = useState<any>({});

  useEffect(() => {
    fetch('/api/settings')
      .then(r => r.json())
      .then(data => setSettings(data.data));
  }, []);

  const updateSetting = async (key: string, value: any) => {
    await fetch(`/api/settings/${key}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ value })
    });
  };

  return (
    <div className="settings-container">
      <h1>Organization Settings</h1>

      <Section title="General">
        <SettingField
          label="Company Name"
          value={settings.company_name}
          onChange={(v) => updateSetting('company_name', v)}
        />
        <SettingField
          label="Language"
          type="select"
          options={['it', 'en', 'fr', 'de']}
          value={settings.language}
          onChange={(v) => updateSetting('language', v)}
        />
      </Section>

      <Section title="Features">
        <SettingField
          label="Enable Project Management"
          type="boolean"
          value={settings.pm_enabled}
          onChange={(v) => updateSetting('pm_enabled', v)}
        />
      </Section>
    </div>
  );
}
```

---

## 🎯 EXECUTION PLAN

### Week 1: Settings System
- [x] Create settings migration
- [ ] Apply to all existing services
- [ ] Add settings API to svc-pm
- [ ] Add settings API to svc-procurement
- [ ] Add settings API to svc-quotations
- [ ] Create /settings pages in frontends
- [ ] Create /user/settings pages

### Week 2: Inventory + Orders
- [ ] Complete svc-inventory
- [ ] Complete svc-orders-purchase
- [ ] Complete svc-orders-sales
- [ ] Create app-inventory-frontend
- [ ] Link services together

### Week 3: Pricelists + AI
- [ ] Complete svc-pricelists-purchase
- [ ] Complete svc-pricelists-sales
- [ ] Create svc-ai-pricing
- [ ] Integrate Perplexity API
- [ ] RFQ reverse engineering algorithm

### Week 4: MRP + Integration
- [ ] Complete svc-mrp
- [ ] Integration testing
- [ ] End-to-end workflows
- [ ] Admin dashboard
- [ ] Documentation

---

## 📝 QUICK START COMMANDS

```bash
# Create all new services at once
cd /Users/andromeda/dev/ewh
./scripts/create-all-services.sh

# Apply settings migration to all
for service in svc-pm svc-procurement svc-quotations svc-inventory svc-orders-purchase svc-orders-sales svc-pricelists-purchase svc-pricelists-sales svc-ai-pricing svc-mrp; do
  echo "Applying settings to $service..."
  # Apply migration
done

# Add to PM2
npx pm2 start ecosystem.config.cjs
npx pm2 save

# Access services
open http://localhost:6400/dev/docs  # inventory
open http://localhost:6200/dev/docs  # orders-purchase
open http://localhost:6300/dev/docs  # orders-sales
open http://localhost:6500/dev/docs  # pricelists-purchase
open http://localhost:6600/dev/docs  # pricelists-sales
open http://localhost:6000/dev/docs  # ai-pricing
open http://localhost:6700/dev/docs  # mrp
```

---

## ✅ SUCCESS CRITERIA

Service is complete when it has:
- [x] Database schema with migrations
- [x] Settings tables integrated
- [x] All CRUD API endpoints
- [x] /dev/docs page
- [x] /admin/dev with auth
- [x] Settings API (tenant/user)
- [x] Webhook system
- [x] Health check
- [x] Tests
- [x] Added to PM2
- [x] Registered in gateway
- [x] Frontend (if applicable)

---

*Ready to execute. All specifications are in place.*
