# Guida Implementazione Pannelli Admin per Servizi

## Obiettivo

Ogni servizio deve esporre un endpoint standard `/admin/dev/api` che fornisce tutte le informazioni necessarie al frontend admin (porta 3200) per mostrare:

- Elenco completo API endpoints
- Webhooks disponibili
- Settings configurabili
- Health status
- Documentazione

## Standard Endpoint

### GET /admin/dev/api

Risposta JSON con questo formato:

```typescript
{
  service: string;           // ID univoco servizio (es: "pm", "inventory")
  name: string;              // Nome leggibile (es: "Project Management")
  description: string;       // Descrizione breve
  version: string;           // Versione (da package.json)
  status: 'healthy' | 'degraded' | 'down';
  port: number;              // Porta su cui gira il servizio
  gateway_prefix: string;    // Prefisso gateway (es: "/api/pm")
  category: string;          // Categoria: Core, ERP, CMS, Commerce, Workflow, Integration

  endpoints: Array<{
    path: string;            // Path completo (es: "/api/pm/projects")
    method: string;          // GET, POST, PUT, DELETE, PATCH
    description: string;     // Cosa fa l'endpoint
    auth_required: boolean;  // Se richiede autenticazione
    params?: string[];       // Parametri URL (es: ["id"])
    query?: string[];        // Query params (es: ["limit", "offset"])
    body_schema?: object;    // Schema body request (opzionale)
  }>;

  webhooks: Array<{
    event: string;           // Nome evento (es: "project.created")
    description: string;     // Quando viene triggerato
    payload_schema?: object; // Schema payload webhook
  }>;

  settings?: Array<{
    key: string;             // Chiave setting (es: "max_projects")
    name: string;            // Nome leggibile
    description: string;     // Descrizione setting
    type: 'string' | 'number' | 'boolean' | 'json';
    default_value: any;      // Valore di default
    required: boolean;       // Se è obbligatorio
  }>;

  documentation_url?: string;    // URL docs (opzionale)
  health_endpoint?: string;      // Endpoint health check
  metrics_endpoint?: string;     // Endpoint metriche
}
```

## Implementazione Step-by-Step

### 1. Crea il file admin-panel.ts

Copia il template da `/templates/service-admin-panel-template.ts` nel tuo servizio:

```bash
cp templates/service-admin-panel-template.ts svc-YOUR-SERVICE/src/routes/admin-panel.ts
```

### 2. Personalizza le informazioni servizio

Modifica i campi base:

```typescript
return {
  service: 'pm',                    // ← ID servizio
  name: 'Project Management',       // ← Nome
  description: 'Gestione progetti e task',  // ← Descrizione
  version: '2.1.0',                 // ← Versione
  port: 5500,                       // ← Porta
  gateway_prefix: '/api/pm',        // ← Prefisso gateway
  category: 'ERP',                  // ← Categoria
  // ...
}
```

### 3. Mappa tutti gli endpoints

Per ogni route del tuo servizio, aggiungi un oggetto nell'array `endpoints`:

```typescript
endpoints: [
  {
    path: '/api/pm/projects',
    method: 'GET',
    description: 'Lista tutti i progetti',
    auth_required: true,
    query: ['user_id', 'status', 'limit', 'offset']
  },
  {
    path: '/api/pm/projects/:id',
    method: 'GET',
    description: 'Dettaglio progetto per ID',
    auth_required: true,
    params: ['id']
  },
  {
    path: '/api/pm/projects',
    method: 'POST',
    description: 'Crea nuovo progetto',
    auth_required: true,
    body_schema: {
      name: 'string',
      description: 'string',
      start_date: 'date',
      end_date: 'date'
    }
  }
]
```

### 4. Aggiungi webhooks (se presenti)

```typescript
webhooks: [
  {
    event: 'project.created',
    description: 'Triggered quando viene creato un nuovo progetto',
    payload_schema: {
      project_id: 'uuid',
      name: 'string',
      created_by: 'uuid',
      created_at: 'timestamp'
    }
  }
]
```

### 5. Definisci settings (opzionale)

```typescript
settings: [
  {
    key: 'max_projects_per_user',
    name: 'Max Projects Per User',
    description: 'Numero massimo di progetti per utente',
    type: 'number',
    default_value: 100,
    required: false
  }
]
```

### 6. Registra la route in index.ts

Nel file `src/index.ts` del servizio:

```typescript
import adminPanelRoutes from './routes/admin-panel';

// ... dopo aver creato l'istanza fastify

await server.register(adminPanelRoutes);
```

### 7. Testa l'endpoint

```bash
curl http://localhost:YOUR_PORT/admin/dev/api | jq
```

Dovresti vedere il JSON completo con tutte le info del servizio.

## Integrazione Frontend Admin

Una volta implementato l'endpoint, il frontend admin (porta 3200) lo scoprirà automaticamente tramite il Service Registry e mostrerà:

1. **Services Registry Page** (`/admin/services-registry`)
   - Card del servizio con status
   - Numero endpoints e webhooks
   - Link alla documentazione

2. **Service Detail Page** (da creare)
   - Lista completa endpoints con filtri
   - Documentazione API interattiva
   - Test API (simile Postman)
   - Configurazione webhooks
   - Settings management

## Servizi Prioritari da Implementare

### Tier 1 - Core Services (implementare SUBITO)
- [x] svc-pm (già fatto)
- [x] svc-inventory (già fatto)
- [x] svc-auth (ha admin.ts, da standardizzare)
- [ ] svc-media
- [ ] svc-api-gateway

### Tier 2 - ERP Services
- [x] svc-orders-purchase (già fatto)
- [x] svc-orders-sales (già fatto)
- [ ] svc-billing
- [ ] svc-procurement
- [ ] svc-quotations
- [ ] svc-shipping

### Tier 3 - CMS/Content Services
- [ ] svc-cms
- [ ] svc-content
- [ ] svc-page-builder
- [ ] svc-site-builder
- [ ] svc-dms

### Tier 4 - Collaboration
- [ ] svc-chat
- [ ] svc-collab
- [ ] svc-boards
- [ ] svc-channels

### Tier 5 - Integration & Automation
- [ ] svc-n8n-bridge
- [ ] svc-workflow-tracker
- [ ] svc-connectors-web

## Categorie Servizi

- **Core**: Auth, Media, API Gateway, Service Registry
- **ERP**: PM, Inventory, Billing, Orders, Procurement, Quotations, Shipping, MRP
- **CMS**: Content, Page Builder, Site Builder, DMS, Writer
- **Commerce**: Products, E-commerce features
- **Workflow**: N8N bridge, Workflow tracker, Job worker
- **Integration**: Connectors, External APIs
- **Communication**: Chat, Collab, Email, Forums
- **Analytics**: BI, Metrics, Search

## Checklist per Ogni Servizio

- [ ] File `admin-panel.ts` creato
- [ ] Tutti gli endpoints mappati
- [ ] Webhooks documentati (se presenti)
- [ ] Settings definiti (se presenti)
- [ ] Route registrata in `index.ts`
- [ ] Endpoint testato con curl
- [ ] Service appare nel Services Registry frontend

## Benefici

✅ **Visibilità**: Tutti i servizi visibili in un unico pannello admin
✅ **Documentazione**: API docs sempre aggiornate e auto-generate
✅ **Monitoring**: Health status in tempo reale
✅ **Testing**: Test API direttamente dal pannello admin
✅ **Governance**: Settings centralizzati ma distribuiti
✅ **Onboarding**: Nuovi developer capiscono subito cosa fa ogni servizio

## Prossimi Passi

1. ✅ Template creato
2. ⏳ Implementare nei 5 servizi che hanno già admin routes
3. ⏳ Implementare nei servizi Tier 1 (Core)
4. ⏳ Implementare nei servizi Tier 2 (ERP)
5. ⏳ Creare Service Detail Page nel frontend admin
6. ⏳ Implementare API testing integrato
7. ⏳ Implementare settings management UI
