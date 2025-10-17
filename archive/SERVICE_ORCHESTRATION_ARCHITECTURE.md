# Service Orchestration Architecture

## Overview

Sistema di orchestrazione API centralizzato che consente la comunicazione e l'integrazione tra tutti i microservizi della piattaforma EWH.

Data: 2025-10-14
Status: ✅ **IMPLEMENTATO E ATTIVO**

---

## 🏗️ Architettura

### 1. **Service Registry** (Port 7200)
📍 `svc-service-registry`

**Funzione**: Registro centrale di tutti i servizi e le loro API

**Caratteristiche**:
- Definizioni JSON di tutti i servizi
- Mappatura completa degli endpoint
- Definizione dei workflows tra servizi
- Service discovery (controllo stato servizi)

**Endpoints**:
- `GET /api/registry/services` - Lista tutti i servizi
- `GET /api/registry/services/:name` - Dettaglio singolo servizio
- `GET /api/registry/workflows` - Lista workflows disponibili
- `GET /api/registry/discovery` - Stato di tutti i servizi (online/offline)
- `POST /api/registry/resolve` - Risolve un endpoint specifico

### 2. **API Orchestrator** (Port 7300)
📍 `svc-api-orchestrator`

**Funzione**: Orchestratore centrale per chiamate API tra servizi

**Caratteristiche**:
- Proxy intelligente per chiamate API
- Esecuzione di workflows multi-step
- Cache del registry (TTL 1 minuto)
- Gestione automatica dei parametri e routing

**Endpoints**:
- `POST /api/orchestrator/call` - Esegue singola chiamata API
- `POST /api/orchestrator/workflow` - Esegue workflow completo
- `GET /api/orchestrator/services/status` - Stato servizi (via registry)
- `GET /api/orchestrator/services` - Lista servizi disponibili
- `GET /api/orchestrator/workflows` - Lista workflows disponibili

---

## 📋 Servizi Registrati

### 1. **svc-pm** (Project Management)
- **Port**: 5500
- **Frontend**: 5400
- **Endpoints**: projects, tasks
- **Status**: ✅ Online

### 2. **svc-procurement** (Procurement & RFQ)
- **Port**: 5600
- **Frontend**: 5700
- **Endpoints**: suppliers, rfq
- **Status**: ✅ Online

### 3. **svc-quotations** (Quotations)
- **Port**: 5800
- **Frontend**: 5900
- **Endpoints**: quotations
- **Status**: ✅ Online

### 4. **svc-inventory** (Inventory Management)
- **Port**: 6400
- **Frontend**: 6800
- **Endpoints**: items, stock, specs
- **Status**: ✅ Online

### 5. **svc-orders-purchase** (Purchase Orders)
- **Port**: 6200
- **Frontend**: 6900
- **Endpoints**: orders, receiving
- **Status**: ✅ Online

### 6. **svc-orders-sales** (Sales Orders)
- **Port**: 6300
- **Frontend**: 7000
- **Endpoints**: orders, shipments
- **Status**: ✅ Online

---

## 🔄 Workflows Definiti

### 1. `procurement_to_purchase_order`
Crea ordine di acquisto da RFQ procurement

**Steps**:
1. GET rfq data da `svc-procurement`
2. CREATE purchase order in `svc-orders-purchase`

### 2. `quotation_to_sales_order`
Converte quotazione approvata in ordine di vendita

**Steps**:
1. GET quotation data da `svc-quotations`
2. CREATE sales order in `svc-orders-sales`

### 3. `purchase_order_to_inventory`
Riceve ordine di acquisto e aggiorna inventario

**Steps**:
1. CREATE receipt in `svc-orders-purchase`
2. UPDATE stock in `svc-inventory`

### 4. `sales_order_to_inventory`
Spedisce ordine di vendita e riduce inventario

**Steps**:
1. CREATE shipment in `svc-orders-sales`
2. UPDATE stock in `svc-inventory`

---

## 💻 Esempi di Utilizzo

### Esempio 1: Chiamata Singola API

```bash
curl -X POST http://localhost:7300/api/orchestrator/call \
  -H "Content-Type: application/json" \
  -d '{
    "service": "svc-inventory",
    "category": "items",
    "action": "list",
    "headers": {
      "x-tenant-id": "00000000-0000-0000-0000-000000000001"
    }
  }'
```

**Response**:
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "service": "svc-inventory",
    "endpoint": "items.list",
    "url": "http://localhost:6400/api/inventory/items",
    "method": "GET"
  }
}
```

### Esempio 2: Esecuzione Workflow

```bash
curl -X POST http://localhost:7300/api/orchestrator/workflow \
  -H "Content-Type: application/json" \
  -d '{
    "workflow": "quotation_to_sales_order",
    "input": {
      "quotation_id": "quote-123"
    }
  }'
```

**Response**:
```json
{
  "success": true,
  "workflow": "quotation_to_sales_order",
  "steps": [
    {
      "step": "svc-quotations.quotations.get",
      "success": true,
      "data": { ... }
    },
    {
      "step": "svc-orders-sales.orders.create",
      "success": true,
      "data": { ... }
    }
  ],
  "context": { ... }
}
```

### Esempio 3: Service Discovery

```bash
curl http://localhost:7300/api/orchestrator/services/status
```

**Response**:
```json
{
  "success": true,
  "data": {
    "svc-pm": { "status": "online", "health": {...} },
    "svc-procurement": { "status": "online", "health": {...} },
    "svc-quotations": { "status": "online", "health": {...} },
    "svc-inventory": { "status": "online", "health": {...} },
    "svc-orders-purchase": { "status": "online", "health": {...} },
    "svc-orders-sales": { "status": "online", "health": {...} }
  },
  "summary": {
    "total": 6,
    "online": 6,
    "offline": 0
  }
}
```

---

## 🔧 Configurazione Frontend

Per utilizzare l'orchestrator dai frontend, creare un client API:

```typescript
// api-client.ts
const ORCHESTRATOR_URL = 'http://localhost:7300';

export async function callService(
  service: string,
  category: string,
  action: string,
  options: {
    params?: Record<string, any>;
    body?: any;
    headers?: Record<string, string>;
  } = {}
) {
  const response = await fetch(`${ORCHESTRATOR_URL}/api/orchestrator/call`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    },
    body: JSON.stringify({
      service,
      category,
      action,
      params: options.params,
      body: options.body,
      headers: options.headers
    })
  });

  return response.json();
}

export async function executeWorkflow(
  workflow: string,
  input: any,
  context: any = {}
) {
  const response = await fetch(`${ORCHESTRATOR_URL}/api/orchestrator/workflow`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ workflow, input, context })
  });

  return response.json();
}
```

**Uso nel frontend**:
```typescript
// Esempio: Lista inventory items
const items = await callService('svc-inventory', 'items', 'list', {
  headers: { 'x-tenant-id': tenantId }
});

// Esempio: Esegui workflow
const result = await executeWorkflow('quotation_to_sales_order', {
  quotation_id: 'quote-123'
});
```

---

## 📊 Vantaggi dell'Architettura

1. **Centralizzazione**: Punto unico per tutte le chiamate API
2. **Service Discovery**: Controllo automatico stato servizi
3. **Workflows**: Orchestrazione automatica operazioni multi-step
4. **Flessibilità**: Facile aggiunta di nuovi servizi e workflows
5. **Manutenibilità**: Definizioni JSON centralizzate e versionabili
6. **Resilienza**: Cache e gestione errori integrata
7. **Monitoring**: Visibilità completa sullo stato del sistema

---

## 🚀 Prossimi Passi

1. ✅ Service Registry implementato
2. ✅ API Orchestrator implementato
3. ⏳ Integrare orchestrator nei frontend esistenti
4. ⏳ Aggiungere autenticazione/autorizzazione
5. ⏳ Implementare rate limiting
6. ⏳ Aggiungere metrics e monitoring
7. ⏳ Creare dashboard di controllo orchestrator

---

## 📁 File Importanti

- `/svc-service-registry/services-definitions/services-map.json` - Definizioni servizi
- `/svc-service-registry/src/index.ts` - Service Registry
- `/svc-api-orchestrator/src/index.ts` - API Orchestrator

---

## 🔗 URLs

- **Service Registry**: http://localhost:7200
- **API Orchestrator**: http://localhost:7300
- **Health Checks**:
  - Registry: http://localhost:7200/health
  - Orchestrator: http://localhost:7300/health
- **Discovery**: http://localhost:7300/api/orchestrator/services/status

---

**Status Finale**: 🎉 **15 servizi attivi** (6 backend + 7 frontend + Registry + Orchestrator)
