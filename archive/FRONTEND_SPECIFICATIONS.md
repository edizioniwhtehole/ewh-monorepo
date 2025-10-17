# 🎨 Frontend Applications - Complete Specifications

## Overview

Tutti i frontend seguono la stessa architettura:
- **Framework**: React + Vite (o Next.js per admin)
- **Styling**: Inline styles / TailwindCSS
- **State**: React hooks + Context
- **Routing**: React Router
- **API**: Fetch via API Gateway
- **i18n**: Multilingue (it, en, fr, de)
- **Settings**: 4-tier waterfall system

---

## 📦 INVENTORY FRONTEND

### app-inventory-frontend (Port 6800)

#### Pages Structure:
```
/                          → Dashboard
/items                     → Items/SKU List
/items/new                 → Create Item
/items/:id                 → Item Detail
/items/:id/edit            → Edit Item
/stock                     → Stock Overview
/stock/movements           → Movement History
/stock/transfer            → Transfer Stock
/locations                 → Warehouse Locations
/lots                      → Lot/Serial Tracking
/count                     → Physical Inventory Count
/count/new                 → Start New Count
/count/:id                 → Count Detail
/reports                   → Reports (stock value, movements, etc.)
/settings                  → Tenant Settings
/user/settings             → User Preferences
```

#### Dashboard Components:
```typescript
function Dashboard() {
  return (
    <>
      <StatsCards>
        <StatCard title="Total Items" value={stats.total_items} />
        <StatCard title="Low Stock" value={stats.low_stock} color="red" />
        <StatCard title="Total Value" value={formatCurrency(stats.total_value)} />
        <StatCard title="Locations" value={stats.locations} />
      </StatsCards>

      <RecentMovements limit={10} />

      <LowStockAlerts />

      <ExpiringLots />
    </>
  );
}
```

#### Item List:
```typescript
function ItemsList() {
  const [items, setItems] = useState([]);
  const [filters, setFilters] = useState({ category: '', search: '' });

  return (
    <>
      <Toolbar>
        <SearchInput />
        <FilterByCategory />
        <Button onClick={exportCSV}>Export</Button>
        <Button onClick={createNew}>+ New Item</Button>
      </Toolbar>

      <DataTable
        columns={[
          { key: 'code', label: 'Code' },
          { key: 'name', label: 'Name' },
          { key: 'category', label: 'Category' },
          { key: 'stock', label: 'Stock', align: 'right' },
          { key: 'unit', label: 'UoM' },
          { key: 'value', label: 'Value', format: 'currency' }
        ]}
        data={items}
        onRowClick={viewDetails}
      />
    </>
  );
}
```

#### Stock Management:
```typescript
function StockOverview() {
  return (
    <>
      <LocationTabs />

      <StockGrid>
        {items.map(item => (
          <StockCard
            item={item}
            stock={item.stock}
            minStock={item.min_stock}
            maxStock={item.max_stock}
            location={currentLocation}
            onAdjust={openAdjustModal}
          />
        ))}
      </StockGrid>

      <QuickActions>
        <Button>Receive Goods</Button>
        <Button>Issue Materials</Button>
        <Button>Transfer</Button>
        <Button>Adjust</Button>
      </QuickActions>
    </>
  );
}
```

#### API Integration:
```typescript
const api = {
  items: {
    list: () => fetch('/api/inventory/items').then(r => r.json()),
    create: (data) => fetch('/api/inventory/items', { method: 'POST', body: JSON.stringify(data) }),
    update: (id, data) => fetch(`/api/inventory/items/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
    delete: (id) => fetch(`/api/inventory/items/${id}`, { method: 'DELETE' })
  },
  stock: {
    byLocation: (locationId) => fetch(`/api/inventory/stock?location=${locationId}`),
    movements: (itemId) => fetch(`/api/inventory/items/${itemId}/movements`)
  },
  movements: {
    create: (data) => fetch('/api/inventory/movements', { method: 'POST', body: JSON.stringify(data) })
  }
};
```

---

## 📋 ORDERS FRONTEND (Unified: Purchase + Sales)

### app-orders-frontend (Port 6900)

#### Pages Structure:
```
/                          → Dashboard (both PO & SO)
/purchase                  → Purchase Orders List
/purchase/new              → Create PO
/purchase/:id              → PO Detail
/purchase/:id/receive      → Goods Receipt
/sales                     → Sales Orders List
/sales/new                 → Create SO
/sales/:id                 → SO Detail
/sales/:id/ship            → Create Shipment
/shipments                 → Shipments Tracking
/suppliers                 → Supplier Performance (link to CRM)
/customers                 → Customer Stats (link to CRM)
/reports                   → Orders Reports
/settings                  → Settings
```

#### Purchase Orders:
```typescript
function PurchaseOrdersList() {
  const [orders, setOrders] = useState([]);

  return (
    <>
      <StatusFilter tabs={['all', 'draft', 'sent', 'confirmed', 'received']} />

      <DataTable
        columns={[
          { key: 'po_number', label: 'PO #' },
          { key: 'supplier', label: 'Supplier' },
          { key: 'date', label: 'Date', format: 'date' },
          { key: 'total', label: 'Total', format: 'currency' },
          { key: 'status', label: 'Status', render: (v) => <StatusBadge status={v} /> },
          { key: 'expected_date', label: 'Expected' }
        ]}
        data={orders}
      />
    </>
  );
}

function PurchaseOrderDetail({ orderId }) {
  const [po, setPO] = useState(null);

  return (
    <>
      <POHeader po={po} />

      <LineItemsTable items={po.line_items} />

      <POActions>
        {po.status === 'draft' && <Button onClick={sendToSupplier}>Send to Supplier</Button>}
        {po.status === 'confirmed' && <Button onClick={receiveGoods}>Receive Goods</Button>}
      </POActions>

      <POHistory events={po.events} />
    </>
  );
}
```

#### Sales Orders:
```typescript
function SalesOrdersList() {
  return (
    <>
      <StatusFilter tabs={['all', 'draft', 'confirmed', 'in_production', 'shipped', 'delivered']} />

      <DataTable
        columns={[
          { key: 'so_number', label: 'SO #' },
          { key: 'customer', label: 'Customer' },
          { key: 'date', label: 'Date' },
          { key: 'total', label: 'Total', format: 'currency' },
          { key: 'status', label: 'Status' },
          { key: 'delivery_date', label: 'Delivery' }
        ]}
        data={orders}
      />
    </>
  );
}

function SalesOrderDetail({ orderId }) {
  const [so, setSO] = useState(null);

  return (
    <>
      <SOHeader so={so} />

      <LineItemsTable items={so.line_items} />

      <StockAvailability items={so.line_items} />

      <SOActions>
        {so.status === 'confirmed' && <Button onClick={reserveStock}>Reserve Stock</Button>}
        {so.status === 'ready' && <Button onClick={createShipment}>Create Shipment</Button>}
        {so.status === 'shipped' && <Button onClick={generateInvoice}>Generate Invoice</Button>}
      </SOActions>
    </>
  );
}
```

---

## 💰 PRICELISTS FRONTEND (Unified: Purchase + Sales)

### app-pricelists-frontend (Port 7000)

#### Pages Structure:
```
/                          → Dashboard
/purchase                  → Purchase Pricelists (from suppliers)
/purchase/new              → Create Purchase Pricelist
/purchase/:id              → Pricelist Detail
/purchase/:id/items        → Pricelist Items
/purchase/compare          → Compare Suppliers
/sales                     → Sales Pricelists (to customers)
/sales/new                 → Create Sales Pricelist
/sales/:id                 → Sales Pricelist Detail
/sales/rules               → Pricing Rules Engine
/sales/margins             → Margin Rules
/promotions                → Promotions & Discounts
/competitive               → Competitive Intelligence (AI)
/history                   → Price History
/reports                   → Pricing Reports
/settings                  → Settings
```

#### Purchase Pricelists:
```typescript
function PurchasePricelists() {
  const [pricelists, setPricelists] = useState([]);

  return (
    <>
      <Toolbar>
        <SupplierFilter />
        <ValidityFilter />
        <Button onClick={compareSuppliers}>Compare Suppliers</Button>
      </Toolbar>

      <PricelistGrid>
        {pricelists.map(pl => (
          <PricelistCard
            key={pl.id}
            pricelist={pl}
            supplier={pl.supplier}
            validFrom={pl.valid_from}
            validUntil={pl.valid_until}
            itemsCount={pl.items_count}
          />
        ))}
      </PricelistGrid>
    </>
  );
}

function SupplierComparison({ itemId }) {
  const [comparison, setComparison] = useState([]);

  return (
    <ComparisonTable>
      <thead>
        <tr>
          <th>Supplier</th>
          <th>100 pz</th>
          <th>500 pz</th>
          <th>1000 pz</th>
          <th>5000 pz</th>
          <th>Lead Time</th>
          <th>Quality</th>
          <th>Best</th>
        </tr>
      </thead>
      <tbody>
        {comparison.map(supplier => (
          <tr key={supplier.id}>
            <td>{supplier.name}</td>
            <td>{formatPrice(supplier.price_100)}</td>
            <td>{formatPrice(supplier.price_500)} {supplier.best_500 && '✓'}</td>
            <td>{formatPrice(supplier.price_1000)} {supplier.best_1000 && '✓'}</td>
            <td>{formatPrice(supplier.price_5000)} {supplier.best_5000 && '✓'}</td>
            <td>{supplier.lead_time_days}d</td>
            <td><Rating value={supplier.quality_score} /></td>
            <td>{supplier.overall_best && <Badge>Best</Badge>}</td>
          </tr>
        ))}
      </tbody>
    </ComparisonTable>
  );
}
```

#### Sales Pricelists:
```typescript
function SalesPricelists() {
  return (
    <>
      <PricelistTabs>
        <Tab>Standard</Tab>
        <Tab>Gold Customers</Tab>
        <Tab>Silver Customers</Tab>
        <Tab>Custom</Tab>
      </PricelistTabs>

      <PricelistEditor>
        <ItemsTable
          items={items}
          onPriceChange={updatePrice}
          showMargin={true}
          showCompetitive={true}
        />

        <MarginIndicator>
          <Warning if={margin < minMargin}>
            ⚠️ Margin below minimum ({minMargin}%)
          </Warning>
        </MarginIndicator>
      </PricelistEditor>
    </>
  );
}

function PricingRulesEngine() {
  const [rules, setRules] = useState([]);

  return (
    <>
      <RulesList>
        {rules.map(rule => (
          <RuleCard
            key={rule.id}
            rule={rule}
            onEdit={editRule}
            onDelete={deleteRule}
          />
        ))}
      </RulesList>

      <AddRuleDialog>
        <Select label="Rule Type">
          <option value="cost_plus">Cost + Markup %</option>
          <option value="fixed_margin">Fixed Margin</option>
          <option value="competitive">Match Competition</option>
          <option value="dynamic">Dynamic (AI)</option>
        </Select>

        <Input label="Base Cost Source" />
        <Input label="Markup %" type="number" />
        <Input label="Min Margin %" type="number" />

        <Checkbox label="Apply to category" />
        <Checkbox label="Require approval if < min margin" />
      </AddRuleDialog>
    </>
  );
}
```

#### AI-Powered Features:
```typescript
function CompetitiveIntelligence({ productId }) {
  const [intel, setIntel] = useState(null);

  useEffect(() => {
    // Call svc-ai-pricing via gateway
    fetch(`/api/ai-pricing/competitive-intel/${productId}`)
      .then(r => r.json())
      .then(data => setIntel(data));
  }, [productId]);

  return (
    <IntelPanel>
      <h3>🤖 AI Market Intelligence</h3>

      <PriceRange>
        <Label>Market Range:</Label>
        <Range min={intel.price_min} max={intel.price_max} />
        <Average value={intel.price_avg} />
      </PriceRange>

      <YourPrice value={currentPrice}>
        {currentPrice < intel.price_min && (
          <Alert variant="warning">Your price is below market minimum</Alert>
        )}
        {currentPrice > intel.price_max && (
          <Alert variant="danger">Your price is above market maximum</Alert>
        )}
      </YourPrice>

      <Recommendations>
        {intel.suggestions.map(suggestion => (
          <Suggestion
            key={suggestion.id}
            text={suggestion.text}
            confidence={suggestion.confidence}
            onApply={() => applyPrice(suggestion.price)}
          />
        ))}
      </Recommendations>

      <Sources>
        <small>Sources: {intel.sources.join(', ')}</small>
        <small>Last updated: {formatDate(intel.updated_at)}</small>
      </Sources>
    </IntelPanel>
  );
}
```

---

## 🤖 AI PRICING FRONTEND (Admin Tool)

### Integrated in web-admin-frontend

#### Pages:
```
/admin/ai-pricing              → Dashboard
/admin/ai-pricing/market       → Market Research Tool
/admin/ai-pricing/rfq-analysis → RFQ Reverse Engineering
/admin/ai-pricing/margin       → Margin Validation
/admin/ai-pricing/suggestions  → Price Optimization
/admin/ai-pricing/config       → AI Configuration
```

#### Market Research Tool:
```typescript
function MarketResearchTool() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  const runResearch = async () => {
    setLoading(true);
    const res = await fetch('/api/ai-pricing/market-research', {
      method: 'POST',
      body: JSON.stringify({
        product: query,
        quantity: 1000,
        market: 'Italy'
      })
    });
    const data = await res.json();
    setResults(data);
    setLoading(false);
  };

  return (
    <>
      <SearchBox>
        <Input
          placeholder="e.g., Stampa 1000 libretti A5 100 pagine"
          value={query}
          onChange={setQuery}
        />
        <Button onClick={runResearch} loading={loading}>
          🔍 Research Market Prices
        </Button>
      </SearchBox>

      {results && (
        <ResultsPanel>
          <PriceRange
            min={results.price_min}
            max={results.price_max}
            avg={results.price_avg}
          />

          <SourcesList>
            {results.sources.map(source => (
              <Source key={source.url} source={source} />
            ))}
          </SourcesList>

          <InsightsList>
            {results.insights.map(insight => (
              <Insight text={insight} />
            ))}
          </InsightsList>
        </ResultsPanel>
      )}
    </>
  );
}
```

#### RFQ Reverse Engineering:
```typescript
function RFQAnalysisTool() {
  const [quotes, setQuotes] = useState([]);
  const [analysis, setAnalysis] = useState(null);

  const analyzeQuotes = async () => {
    const res = await fetch('/api/ai-pricing/reverse-engineer-rfq', {
      method: 'POST',
      body: JSON.stringify({ quotes })
    });
    const data = await res.json();
    setAnalysis(data);
  };

  return (
    <>
      <QuotesInput>
        <h3>Enter Supplier Quotes</h3>
        {quotes.map((quote, i) => (
          <QuoteRow key={i}>
            <Input label="Quantity" type="number" value={quote.quantity} />
            <Input label="Price" type="number" value={quote.price} />
            <Button onClick={() => removeQuote(i)}>×</Button>
          </QuoteRow>
        ))}
        <Button onClick={addQuoteRow}>+ Add Quantity</Button>
      </QuotesInput>

      <Button onClick={analyzeQuotes} primary>
        🧮 Analyze Cost Structure
      </Button>

      {analysis && (
        <AnalysisResults>
          <CostStructure>
            <Stat label="Fixed Cost" value={analysis.fixed_cost} />
            <Stat label="Variable Cost" value={analysis.variable_cost} />
            <Stat label="Confidence" value={`${analysis.confidence}%`} />
          </CostStructure>

          <CostCurveChart data={analysis.curve} />

          <Projections>
            <h4>Projected Prices:</h4>
            {analysis.projections.map(proj => (
              <Projection
                quantity={proj.quantity}
                price={proj.price}
                confidence={proj.confidence}
              />
            ))}
          </Projections>

          <Breakpoints>
            <h4>Price Breakpoints:</h4>
            {analysis.breakpoints.map(bp => (
              <Breakpoint quantity={bp.quantity} note={bp.note} />
            ))}
          </Breakpoints>
        </AnalysisResults>
      )}
    </>
  );
}
```

---

## 🎨 SHARED UI COMPONENTS

### Components Package: `@ewh/ui-components`

```typescript
// DataTable
export function DataTable({ columns, data, onRowClick }) { ... }

// StatusBadge
export function StatusBadge({ status }) { ... }

// SettingField (with lock indicator)
export function SettingField({ label, value, locked, onChange }) { ... }

// SearchInput
export function SearchInput({ placeholder, onSearch }) { ... }

// Modal
export function Modal({ open, onClose, children }) { ... }

// Tabs
export function Tabs({ tabs, activeTab, onChange }) { ... }

// StatsCard
export function StatsCard({ title, value, change, icon }) { ... }

// DateRangePicker
export function DateRangePicker({ from, to, onChange }) { ... }

// CurrencyInput
export function CurrencyInput({ value, currency, onChange }) { ... }
```

---

## 🔧 VITE CONFIGURATION TEMPLATE

```typescript
// vite.config.ts (for all frontends)
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 6800, // change per app
    proxy: {
      '/api': {
        target: 'http://localhost:5000', // API Gateway
        changeOrigin: true
      }
    }
  }
});
```

---

## 📦 PM2 CONFIGURATION UPDATE

```javascript
// ecosystem.config.cjs
module.exports = {
  apps: [
    // ... existing services ...

    // New services
    { name: 'svc-inventory', cwd: './svc-inventory', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6400 } },
    { name: 'app-inventory-frontend', cwd: './app-inventory-frontend', script: 'npm', args: 'run dev' },

    { name: 'svc-orders-purchase', cwd: './svc-orders-purchase', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6200 } },
    { name: 'svc-orders-sales', cwd: './svc-orders-sales', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6300 } },
    { name: 'app-orders-frontend', cwd: './app-orders-frontend', script: 'npm', args: 'run dev' },

    { name: 'svc-pricelists-purchase', cwd: './svc-pricelists-purchase', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6500 } },
    { name: 'svc-pricelists-sales', cwd: './svc-pricelists-sales', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6600 } },
    { name: 'app-pricelists-frontend', cwd: './app-pricelists-frontend', script: 'npm', args: 'run dev' },

    { name: 'svc-ai-pricing', cwd: './svc-ai-pricing', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6000 } },
    { name: 'svc-mrp', cwd: './svc-mrp', script: 'npx', args: 'tsx src/index.ts', env: { PORT: 6700 } }
  ]
};
```

---

## ✅ CREATION CHECKLIST

For each frontend:

- [ ] Create directory structure
- [ ] Setup package.json with dependencies
- [ ] Configure Vite
- [ ] Create routing structure
- [ ] Implement dashboard
- [ ] Implement list views
- [ ] Implement detail views
- [ ] Implement forms
- [ ] Add API integration
- [ ] Add i18n support
- [ ] Add /settings page
- [ ] Add /user/settings page
- [ ] Test with backend
- [ ] Add to PM2

---

*All specifications ready. Ready to create all services and frontends.*
