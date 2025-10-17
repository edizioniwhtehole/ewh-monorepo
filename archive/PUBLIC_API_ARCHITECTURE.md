# 🌐 Public API Architecture

## Sistema di Esposizione API Esterne (Enterprise-Grade)

**Version**: 1.0.0
**Status**: 🔴 Design Phase
**Last Updated**: 2025-10-14

---

## 🎯 OBIETTIVO

Esporre API pubbliche sicure per integrazioni con sistemi esterni (ERP, contabilità, e-commerce) senza mai esporre direttamente i servizi interni.

---

## 🏗️ ARCHITETTURA

```
┌─────────────────────────────────────────────────┐
│  Partner Esterni                                 │
│  - Software Contabilità                         │
│  - ERP Aziendale                                │
│  - E-commerce Platform                          │
│  - Mobile App                                   │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS (TLS 1.3)
                   │ Authentication: API Key + Secret
                   ↓
┌─────────────────────────────────────────────────┐
│  Public API Gateway (porta 8000)                │
│  - Rate Limiting (per API key)                  │
│  - IP Whitelist                                 │
│  - DDoS Protection                              │
│  - Request Validation                           │
│  - API Key Authentication                       │
└──────────────────┬──────────────────────────────┘
                   │ Internal Network (private)
                   ↓
┌─────────────────────────────────────────────────┐
│  svc-public-api (porta 7000)                    │
│  - API Versioning (v1, v2)                      │
│  - Request Transformation                       │
│  - Response Normalization                       │
│  - Webhook Management                           │
│  - Audit Logging                                │
└──────────────────┬──────────────────────────────┘
                   │ Internal service calls
                   │
    ┌──────────────┼──────────────┬──────────────┐
    ↓              ↓              ↓              ↓
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│svc-crm │    │svc-inv │    │svc-ord │    │svc-bill│
│ :4020  │    │ :6400  │    │ :6500  │    │ :4500  │
└────────┘    └────────┘    └────────┘    └────────┘
```

---

## 🔒 PRINCIPI DI SICUREZZA

### 1. **Zero Trust Architecture**
- ✅ Mai fidarsi di richieste esterne
- ✅ Validazione completa di ogni request
- ✅ Autenticazione sempre richiesta
- ✅ Authorization granulare

### 2. **Defense in Depth**
```
Layer 1: Public Gateway (rate limit, IP whitelist, DDoS)
Layer 2: API Key Validation (svc-public-api)
Layer 3: Tenant Isolation (database level)
Layer 4: Resource Authorization (RBAC)
```

### 3. **Audit Everything**
- Ogni chiamata API loggata
- IP address, timestamp, tenant, endpoint
- Request/response payload (sanitized)
- Performance metrics

---

## 📦 SERVIZIO: svc-public-api

### **Responsabilità**

1. **API Versioning**
   - `/api/public/v1/*` - Versione stabile
   - `/api/public/v2/*` - Nuove features
   - Deprecation policy: 12 mesi

2. **Request Transformation**
   ```typescript
   // Input pubblico (semplice)
   {
     "invoice_number": "INV-001",
     "customer": "Acme Corp",
     "amount": 1000,
     "currency": "EUR"
   }

   // Trasformato in formato interno (complesso)
   {
     "tenant_id": "uuid",
     "invoice_metadata": {
       "number": "INV-001",
       "financial_year": 2025
     },
     "customer_id": "uuid",  // lookup da nome
     "amount_cents": 100000,
     "currency_code": "EUR",
     "created_via": "public_api"
   }
   ```

3. **Response Normalization**
   - Formato consistente
   - Error codes standardizzati
   - Pagination standard
   - Metadata comune

4. **Webhook Management**
   - Sottoscrizione eventi
   - Delivery garantita (retry)
   - Firma HMAC per security

---

## 🗄️ DATABASE SCHEMA

### **API Keys Management**

```sql
CREATE SCHEMA public_api;

-- API Keys per partner esterni
CREATE TABLE public_api.api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),

  -- Credentials
  api_key VARCHAR(64) UNIQUE NOT NULL,  -- es: pk_live_abc123...
  api_secret_hash VARCHAR(255) NOT NULL,  -- bcrypt hash

  -- Metadata
  name VARCHAR(255) NOT NULL,  -- "Contabilità Studio ABC"
  description TEXT,
  environment VARCHAR(20) DEFAULT 'production',  -- production, sandbox

  -- Permissions
  scopes TEXT[] NOT NULL,  -- ['invoices:read', 'invoices:write', 'orders:read']
  allowed_ips TEXT[],  -- IP whitelist (nullable = tutti)

  -- Rate Limiting
  rate_limit_per_hour INTEGER DEFAULT 1000,
  rate_limit_per_day INTEGER DEFAULT 10000,

  -- Status
  enabled BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,  -- NULL = never expires
  last_used_at TIMESTAMPTZ,

  -- Audit
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_api_keys_tenant ON public_api.api_keys(tenant_id);
CREATE INDEX idx_api_keys_key ON public_api.api_keys(api_key) WHERE enabled = true;

-- API Key Usage Tracking
CREATE TABLE public_api.api_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID NOT NULL REFERENCES public_api.api_keys(id),

  -- Request Info
  endpoint VARCHAR(255) NOT NULL,
  method VARCHAR(10) NOT NULL,
  status_code INTEGER NOT NULL,

  -- Network
  ip_address INET NOT NULL,
  user_agent TEXT,

  -- Performance
  response_time_ms INTEGER,
  payload_size_bytes INTEGER,

  -- Audit
  request_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partition by month for performance
CREATE INDEX idx_api_usage_key_date ON public_api.api_usage(api_key_id, created_at DESC);
CREATE INDEX idx_api_usage_date ON public_api.api_usage(created_at DESC);

-- Webhook Subscriptions
CREATE TABLE public_api.webhook_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID NOT NULL REFERENCES public_api.api_keys(id),

  -- Event
  event_type VARCHAR(100) NOT NULL,  -- 'invoice.paid', 'order.shipped'
  webhook_url TEXT NOT NULL,
  webhook_secret VARCHAR(255) NOT NULL,  -- per firmare payload HMAC-SHA256

  -- Delivery Settings
  retry_max_attempts INTEGER DEFAULT 3,
  retry_backoff_seconds INTEGER DEFAULT 60,
  timeout_seconds INTEGER DEFAULT 30,

  -- Status
  enabled BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMPTZ,
  last_success_at TIMESTAMPTZ,
  failure_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_webhooks_key ON public_api.webhook_subscriptions(api_key_id);
CREATE INDEX idx_webhooks_event ON public_api.webhook_subscriptions(event_type) WHERE enabled = true;

-- Webhook Delivery Log
CREATE TABLE public_api.webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public_api.webhook_subscriptions(id),

  -- Event
  event_type VARCHAR(100) NOT NULL,
  event_id UUID NOT NULL,
  payload JSONB NOT NULL,

  -- Delivery
  attempt_number INTEGER NOT NULL DEFAULT 1,
  status VARCHAR(20) NOT NULL,  -- 'pending', 'success', 'failed'
  http_status_code INTEGER,
  response_body TEXT,
  error_message TEXT,

  -- Timing
  sent_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  response_time_ms INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_webhook_deliveries_sub ON public_api.webhook_deliveries(subscription_id, created_at DESC);
CREATE INDEX idx_webhook_deliveries_status ON public_api.webhook_deliveries(status, created_at);
```

---

## 🔌 API ENDPOINTS PUBBLICI

### **Base URL**: `https://api.yourdomain.com/public/v1`

### **Autenticazione**
```http
Authorization: Bearer {api_key}
X-API-Secret: {api_secret}
```

### **Standard Endpoints**

#### **1. Invoices**
```
POST   /public/v1/invoices                 # Crea fattura
GET    /public/v1/invoices                 # Lista fatture
GET    /public/v1/invoices/:id             # Dettaglio fattura
PUT    /public/v1/invoices/:id/status      # Aggiorna stato
DELETE /public/v1/invoices/:id             # Cancella fattura
```

#### **2. Orders**
```
POST   /public/v1/orders                   # Crea ordine
GET    /public/v1/orders                   # Lista ordini
GET    /public/v1/orders/:id               # Dettaglio ordine
PUT    /public/v1/orders/:id/status        # Aggiorna stato
POST   /public/v1/orders/:id/ship          # Marca come spedito
```

#### **3. Customers**
```
POST   /public/v1/customers                # Crea cliente
GET    /public/v1/customers                # Lista clienti
GET    /public/v1/customers/:id            # Dettaglio cliente
PUT    /public/v1/customers/:id            # Aggiorna cliente
```

#### **4. Products**
```
POST   /public/v1/products                 # Crea prodotto
GET    /public/v1/products                 # Lista prodotti
GET    /public/v1/products/:id             # Dettaglio prodotto
PUT    /public/v1/products/:id/stock       # Aggiorna stock
```

#### **5. Webhooks**
```
POST   /public/v1/webhooks                 # Sottoscrivi evento
GET    /public/v1/webhooks                 # Lista sottoscrizioni
DELETE /public/v1/webhooks/:id             # Cancella sottoscrizione
GET    /public/v1/webhooks/:id/deliveries  # Log delivery
```

#### **6. Meta**
```
GET    /public/v1/status                   # API status
GET    /public/v1/docs                     # OpenAPI spec (Swagger)
GET    /public/v1/events                   # Lista eventi webhook
```

---

## 📤 WEBHOOK EVENTS

### **Eventi Standard**

```typescript
// Invoice Events
'invoice.created'      // Fattura creata
'invoice.updated'      // Fattura modificata
'invoice.paid'         // Fattura pagata
'invoice.overdue'      // Fattura scaduta
'invoice.cancelled'    // Fattura annullata

// Order Events
'order.created'        // Ordine creato
'order.confirmed'      // Ordine confermato
'order.shipped'        // Ordine spedito
'order.delivered'      // Ordine consegnato
'order.cancelled'      // Ordine annullato

// Customer Events
'customer.created'     // Cliente creato
'customer.updated'     // Cliente aggiornato

// Product Events
'product.stock_low'    // Stock basso
'product.out_of_stock' // Prodotto esaurito
```

### **Payload Standard**

```json
{
  "id": "evt_abc123",
  "type": "invoice.paid",
  "version": "v1",
  "timestamp": "2025-10-14T10:30:00Z",
  "tenant_id": "tenant_xyz",
  "data": {
    "invoice_id": "inv_123",
    "invoice_number": "INV-001",
    "amount": 1000.00,
    "currency": "EUR",
    "paid_at": "2025-10-14T10:25:00Z"
  }
}
```

### **Firma HMAC**

```http
X-Webhook-Signature: sha256=abc123def456...
X-Webhook-Timestamp: 1697280000
```

```typescript
// Verifica firma
const signature = crypto
  .createHmac('sha256', webhook_secret)
  .update(timestamp + '.' + JSON.stringify(payload))
  .digest('hex');
```

---

## 🚦 RATE LIMITING

### **Livelli Standard**

| Piano | Req/Hour | Req/Day | Burst |
|-------|----------|---------|-------|
| Free | 100 | 1,000 | 10 |
| Starter | 1,000 | 10,000 | 50 |
| Professional | 10,000 | 100,000 | 200 |
| Enterprise | 100,000 | 1,000,000 | 1,000 |

### **Headers Response**

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 487
X-RateLimit-Reset: 1697283600
```

### **Error Response**

```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "API rate limit exceeded",
    "retry_after": 3600
  }
}
```

---

## 📊 MONITORING & OBSERVABILITY

### **Metriche da Tracciare**

```typescript
// Performance
- api.request.duration (histogram)
- api.request.count (counter)
- api.error.count (counter)
- api.error.rate (gauge)

// Business
- api.key.active_count (gauge)
- api.usage.by_tenant (counter)
- api.usage.by_endpoint (counter)

// Security
- api.auth_failed.count (counter)
- api.rate_limit.exceeded (counter)
- api.suspicious_activity (alert)
```

### **Alerting**

```yaml
alerts:
  - name: HighErrorRate
    condition: api.error.rate > 5%
    duration: 5m
    severity: critical

  - name: SlowResponse
    condition: p95(api.request.duration) > 2s
    duration: 5m
    severity: warning

  - name: RateLimitAbuse
    condition: api.rate_limit.exceeded > 100/hour
    duration: 1h
    severity: warning
```

---

## 🔐 SECURITY BEST PRACTICES

### **1. API Key Security**

```typescript
// Formato API Key
api_key: 'pk_live_' + random(48)  // 56 caratteri totali
api_secret: random(64)  // 64 caratteri

// Storage
- API Key: plain text (searchable)
- API Secret: bcrypt hash (never stored plain)

// Rotation
- Supportare multiple API keys attive
- Deprecation period: 30 giorni
- Notifica via email prima della scadenza
```

### **2. IP Whitelisting**

```sql
-- Per API key
allowed_ips: ['203.0.113.0/24', '198.51.100.42']

-- Validazione
SELECT EXISTS(
  SELECT 1 FROM public_api.api_keys
  WHERE api_key = $1
    AND enabled = true
    AND (allowed_ips IS NULL OR $2::inet << ANY(allowed_ips::inet[]))
);
```

### **3. Request Signing** (opzionale, extra security)

```http
X-Signature: sha256=abc123...
X-Timestamp: 1697280000
X-Nonce: xyz789
```

---

## 📈 SCALABILITÀ

### **Horizontal Scaling**

```yaml
# Kubernetes deployment
replicas: 3
autoscaling:
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilization: 70%
```

### **Caching Strategy**

```typescript
// Redis cache per API key lookups
Cache-Key: api_key:{api_key}
TTL: 5 minutes

// Cache per rate limiting
Cache-Key: rate_limit:{api_key}:{hour}
TTL: 1 hour
```

### **Database Optimization**

```sql
-- Partition API usage per month
CREATE TABLE public_api.api_usage_2025_10 PARTITION OF public_api.api_usage
FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- Retention policy: 13 mesi
DROP TABLE public_api.api_usage_2024_09;
```

---

## 🧪 TESTING

### **Load Testing**

```bash
# Test rate limiting
ab -n 2000 -c 10 -H "Authorization: Bearer pk_test_123" \
   https://api.yourdomain.com/public/v1/invoices

# Test webhook delivery
artillery run webhook-load-test.yml
```

### **Security Testing**

```bash
# OWASP ZAP scan
zap-cli quick-scan --self-contained https://api.yourdomain.com/public/v1

# Penetration testing
burpsuite --project-file public-api-test.burp
```

---

## 📋 ROADMAP

### **Phase 1: Foundation (Q4 2025)**
- [x] Architecture design
- [ ] svc-public-api implementation
- [ ] API Key management
- [ ] Basic endpoints (invoices, orders)
- [ ] Rate limiting
- [ ] Audit logging

### **Phase 2: Webhooks (Q1 2026)**
- [ ] Webhook subscription system
- [ ] Delivery queue (RabbitMQ)
- [ ] Retry logic with exponential backoff
- [ ] HMAC signature
- [ ] Delivery monitoring

### **Phase 3: Advanced Features (Q2 2026)**
- [ ] GraphQL endpoint
- [ ] Batch operations
- [ ] File uploads
- [ ] Real-time subscriptions (WebSocket)
- [ ] API versioning v2

### **Phase 4: Enterprise (Q3 2026)**
- [ ] SLA guarantees
- [ ] Dedicated IP addresses
- [ ] Custom rate limits
- [ ] Priority support
- [ ] SOC 2 Type II certification

---

## 🎓 BEST PRACTICES

### **Per Partner Esterni**

1. **Always use HTTPS**
2. **Store API secrets securely** (environment variables, vault)
3. **Implement exponential backoff** on failures
4. **Verify webhook signatures**
5. **Use idempotency keys** for mutations
6. **Monitor rate limits**
7. **Handle pagination** correctly

### **Per Sviluppatori Interni**

1. **Mai esporre servizi interni direttamente**
2. **Validare tutti gli input** (JSON schema)
3. **Sanitize error messages** (no stack traces pubblici)
4. **Log everything** (audit trail completo)
5. **Test con API keys reali** (sandbox environment)
6. **Documentazione sempre aggiornata** (OpenAPI)

---

## 📚 RELATED DOCS

- [SETTINGS_WATERFALL_ARCHITECTURE.md](./SETTINGS_WATERFALL_ARCHITECTURE.md)
- [API_GATEWAY_SPECIFICATION.md](./API_GATEWAY_SPECIFICATION.md) (TODO)
- [WEBHOOK_SYSTEM_DESIGN.md](./WEBHOOK_SYSTEM_DESIGN.md) (TODO)
- [RATE_LIMITING_STRATEGY.md](./RATE_LIMITING_STRATEGY.md) (TODO)

---

**Status**: 🔴 Design Complete, Implementation Pending
**Target**: Q4 2025
**Owner**: Platform Team
**Security Review**: Required before production
