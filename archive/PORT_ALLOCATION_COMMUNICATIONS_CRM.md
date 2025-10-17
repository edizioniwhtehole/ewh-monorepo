# Port Allocation - Communications & CRM System

## 🚨 Port Conflict Resolution

**Issue:** Port 5700 già assegnato a procurement in alcuni documenti (non in INFRASTRUCTURE_REGISTRY.json)

**Solution:** Allocare porte seguendo lo schema esistente della piattaforma EWH

---

## 📊 Schema Porte Esistenti

### Infrastructure (Base)
- **5432** - PostgreSQL
- **6379** - Redis
- **9000** - MinIO (S3)
- **9001** - MinIO Console

### API Gateway & Core
- **4000** - svc-api-gateway (API Gateway principale)
- **4001** - svc-auth (Authentication)
- **4002** - svc-plugins
- **4003** - svc-media
- **4004** - svc-billing
- **4010** - svc-metrics-collector

### Creative Services (41xx)
- **4100** - svc-image-orchestrator
- **4101** - svc-job-worker
- **4102** - svc-writer
- **4103** - svc-content
- **4104** - svc-layout
- **4105** - svc-prepress
- **4106** - svc-vector-lab
- **4107** - svc-mockup
- **4108** - svc-video-orchestrator
- **4109** - svc-video-runtime
- **4110** - svc-raster-runtime

### Publishing Services (42xx)
- **4200** - svc-projects
- **4201** - svc-search
- **4202** - svc-site-builder
- **4203** - svc-site-renderer
- **4204** - svc-site-publisher
- **4205** - svc-connectors-web

### ERP Services (43xx)
- **4300** - svc-products
- **4301** - svc-orders
- **4302** - svc-inventory
- **4303** - svc-channels (esistente)
- **4304** - svc-quotation
- **4305** - svc-procurement
- **4306** - svc-mrp
- **4307** - svc-shipping
- **4308** - svc-crm (esistente - ⚠️ CONFLITTO!)

### Collaboration Services (44xx)
- **4400** - svc-pm
- **4401** - svc-support
- **4402** - svc-chat
- **4403** - svc-boards
- **4404** - svc-kb
- **4405** - svc-collab
- **4406** - svc-dms
- **4407** - svc-timesheet
- **4408** - svc-forms
- **4409** - svc-forum
- **4410** - svc-assistant

### Platform Services (45xx)
- **4500** - svc-comm (esistente - ⚠️ CONFLITTO!)
- **4501** - svc-enrichment
- **4502** - svc-bi

### External
- **5678** - n8n (workflow automation)

### Frontends (31xx, 32xx)
- **3100** - app-web-frontend
- **3200** - app-admin-frontend

---

## 🆕 Nuove Allocazioni (Communications & CRM)

### ⚠️ CONFLITTI RILEVATI

1. **svc-crm** esiste già su porta **4308**
2. **svc-comm** esiste già su porta **4500**
3. **svc-channels** esiste già su porta **4303**

### ✅ SOLUZIONE: Rinominare e Riorganizzare

#### Opzione A: Rinominare i Nuovi Servizi

```
svc-communications → svc-unified-comms (porta 4600)
svc-crm → svc-crm-advanced (porta 4601)
```

#### Opzione B: Usare i Servizi Esistenti e Estendere

```
Estendere svc-crm esistente (4308)
Estendere svc-comm esistente (4500)
Estendere svc-channels esistente (4303)
```

#### ✅ Opzione C (RACCOMANDATA): Nuova Category 46xx per "Advanced ERP"

```
46xx - Advanced ERP & Communications
4600 - svc-unified-communications
4601 - svc-crm-plus
```

---

## 📋 Port Schema Finale (Opzione C)

### Backend Services

#### Advanced ERP & Communications (46xx) - NEW CATEGORY
```
4600 - svc-unified-communications (HTTP)
4601 - svc-unified-communications (WebSocket)
4602 - svc-crm-plus (HTTP)
4603 - svc-crm-plus (WebSocket)
```

**Naming Convention:**
- `svc-unified-communications` = Nuovo servizio multi-canale (Email/SMS/WhatsApp/Telegram/Discord)
- `svc-crm-plus` = Nuovo CRM avanzato con integrazione communications

### Frontend Services

#### Communication & CRM Frontends (56xx) - NEW RANGE
```
5600 - app-unified-communications-client
5601 - app-crm-plus-frontend
```

**Perché 56xx?**
- 31xx: core frontends (web, admin)
- 56xx: specialized business frontends
- Evita conflitto con 5700 (procurement)

---

## 🔄 Mappatura Completa Aggiornata

### Services to Create

```json
{
  "name": "svc-unified-communications",
  "type": "advanced-erp",
  "description": "Unified multi-channel communications (Email, SMS, WhatsApp, Telegram, Discord)",
  "port": 4600,
  "wsPort": 4601,
  "healthEndpoint": "http://localhost:4600/health",
  "apiDocs": "http://localhost:4600/dev",
  "critical": false
}

{
  "name": "svc-crm-plus",
  "type": "advanced-erp",
  "description": "Advanced CRM with native communications integration",
  "port": 4602,
  "wsPort": 4603,
  "healthEndpoint": "http://localhost:4602/health",
  "apiDocs": "http://localhost:4602/dev",
  "critical": false
}

{
  "name": "app-unified-communications-client",
  "type": "frontend",
  "description": "Unified communications client frontend",
  "port": 5600,
  "healthEndpoint": "http://localhost:5600/api/health",
  "critical": false
}

{
  "name": "app-crm-plus-frontend",
  "type": "frontend",
  "description": "Advanced CRM frontend",
  "port": 5601,
  "healthEndpoint": "http://localhost:5601/api/health",
  "critical": false
}
```

---

## 🗺️ API Gateway Routing

### Aggiunte necessarie a svc-api-gateway (4000)

```typescript
// In svc-api-gateway/routes.ts

{
  path: '/unified-communications',
  target: 'http://localhost:4600',
  auth: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
},
{
  path: '/crm-plus',
  target: 'http://localhost:4602',
  auth: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
}
```

### URLs Pubblici

```
# Via API Gateway
https://api.yourdomain.com/unified-communications/...
https://api.yourdomain.com/crm-plus/...

# Direct (development)
http://localhost:4600/...
http://localhost:4602/...

# Frontends
http://localhost:5600  (communications client)
http://localhost:5601  (CRM frontend)
```

---

## 📝 File da Aggiornare

### 1. svc-unified-communications

**Files to update:**
```bash
svc-communications/.env.example
  PORT=4600
  WS_PORT=4601

svc-communications/package.json
  "name": "svc-unified-communications"

svc-communications/src/index.ts
  const PORT = process.env.PORT || 4600;
  const WS_PORT = process.env.WS_PORT || 4601;
```

### 2. app-unified-communications-client

**Files to update:**
```bash
app-communications-client/.env.example
  VITE_API_URL=http://localhost:4000  # API Gateway
  VITE_COMMUNICATIONS_API=http://localhost:4600
  VITE_WS_URL=ws://localhost:4601

app-communications-client/vite.config.ts
  server: { port: 5600 }

app-communications-client/package.json
  "name": "app-unified-communications-client"
  "dev": "vite --port 5600"
```

### 3. svc-crm-plus

**Files to create:**
```bash
svc-crm-plus/.env.example
  PORT=4602
  WS_PORT=4603

svc-crm-plus/package.json
  "name": "svc-crm-plus"
```

### 4. app-crm-plus-frontend

**Files to create:**
```bash
app-crm-plus-frontend/.env.example
  VITE_API_URL=http://localhost:4000  # API Gateway
  VITE_CRM_API=http://localhost:4602
  VITE_WS_URL=ws://localhost:4603

app-crm-plus-frontend/vite.config.ts
  server: { port: 5601 }
```

---

## 🔧 Comandi Update

```bash
# Rinomina directory
mv svc-communications svc-unified-communications
mv app-communications-client app-unified-communications-client

# Oppure crea nuovi e copia
mkdir svc-crm-plus
mkdir app-crm-plus-frontend

# Update ports nei file
cd svc-unified-communications
sed -i '' 's/PORT=3200/PORT=4600/g' .env.example
sed -i '' 's/WS_PORT=3201/WS_PORT=4601/g' .env.example

cd ../app-unified-communications-client
sed -i '' 's/5700/5600/g' vite.config.ts package.json
sed -i '' 's/3200/4600/g' .env.example
sed -i '' 's/3201/4601/g' .env.example
```

---

## 📊 Port Summary Table

| Service | Type | Port (HTTP) | Port (WS) | Status |
|---------|------|-------------|-----------|--------|
| **svc-unified-communications** | Backend | 4600 | 4601 | ✅ New |
| **svc-crm-plus** | Backend | 4602 | 4603 | ✅ New |
| **app-unified-communications-client** | Frontend | 5600 | - | ✅ New |
| **app-crm-plus-frontend** | Frontend | 5601 | - | ✅ New |
| svc-crm (existing) | Backend | 4308 | - | ⚠️ Keep |
| svc-comm (existing) | Backend | 4500 | - | ⚠️ Keep |
| svc-channels (existing) | Backend | 4303 | - | ⚠️ Keep |

---

## 🚀 Quick Start con Porte Corrette

```bash
# 1. Backend Unified Communications
cd svc-unified-communications
npm install
cp .env.example .env
# Edit .env: PORT=4600, WS_PORT=4601
npm run dev
# → http://localhost:4600
# → ws://localhost:4601

# 2. Frontend Communications
cd app-unified-communications-client
npm install
cp .env.example .env
# Edit .env: ports as above
npm run dev
# → http://localhost:5600

# 3. Backend CRM Plus
cd svc-crm-plus
npm install
cp .env.example .env
# Edit .env: PORT=4602, WS_PORT=4603
npm run dev
# → http://localhost:4602

# 4. Frontend CRM Plus
cd app-crm-plus-frontend
npm install
npm run dev
# → http://localhost:5601
```

---

## 🔍 Conflict Checks

### Verifica porte disponibili

```bash
# Check if ports are in use
lsof -i :4600  # Should be empty
lsof -i :4601  # Should be empty
lsof -i :4602  # Should be empty
lsof -i :4603  # Should be empty
lsof -i :5600  # Should be empty
lsof -i :5601  # Should be empty
```

### Verifica nel registry

```bash
# Check INFRASTRUCTURE_REGISTRY.json
grep "4600\|4601\|4602\|4603\|5600\|5601" INFRASTRUCTURE_REGISTRY.json
# Should return nothing
```

---

## 📋 Update Checklist

- [ ] Rinominare `svc-communications` → `svc-unified-communications`
- [ ] Rinominare `app-communications-client` → `app-unified-communications-client`
- [ ] Creare `svc-crm-plus` (basato su architettura CRM_SYSTEM_COMPLETE.md)
- [ ] Creare `app-crm-plus-frontend`
- [ ] Aggiornare tutte le `.env.example` con porte corrette
- [ ] Aggiornare `package.json` files con nomi corretti
- [ ] Aggiornare `vite.config.ts` con porta 5600
- [ ] Aggiornare `src/index.ts` con porte 4600/4601
- [ ] Aggiornare `INFRASTRUCTURE_REGISTRY.json` con nuovi servizi
- [ ] Aggiornare `svc-api-gateway` con nuove routes
- [ ] Aggiornare tutta la documentazione con porte corrette
- [ ] Aggiornare `docker-compose.dev.yml` (se presente)

---

## 📚 Documentation Updates Needed

Files to update with correct ports:

1. ✅ **PORT_ALLOCATION_COMMUNICATIONS_CRM.md** (this file)
2. ⚠️ **COMMUNICATIONS_SYSTEM_COMPLETE.md** - Update all references to 3200 → 4600
3. ⚠️ **CRM_SYSTEM_COMPLETE.md** - Update all references to 3300 → 4602
4. ⚠️ **IMPLEMENTATION_COMPLETE_SUMMARY.md** - Update port references
5. ⚠️ **QUICK_START_COMMUNICATIONS_CRM.md** - Update all commands
6. ⚠️ **COMMUNICATIONS_CRM_IMPLEMENTATION_STATUS.md** - Update port references
7. ⚠️ **INFRASTRUCTURE_REGISTRY.json** - Add new services

---

## 🎯 Final Port Schema

### Backend Services (sorted by port)
```
4000  - svc-api-gateway (API Gateway)
4001  - svc-auth
4002  - svc-plugins
4003  - svc-media
4004  - svc-billing
4010  - svc-metrics-collector

41xx  - Creative Services (4100-4110)
42xx  - Publishing Services (4200-4205)
43xx  - ERP Services (4300-4308)
44xx  - Collaboration Services (4400-4410)
45xx  - Platform Services (4500-4502)

4600  - svc-unified-communications (NEW - HTTP)
4601  - svc-unified-communications (NEW - WebSocket)
4602  - svc-crm-plus (NEW - HTTP)
4603  - svc-crm-plus (NEW - WebSocket)
```

### Frontend Services
```
3100  - app-web-frontend
3200  - app-admin-frontend

5600  - app-unified-communications-client (NEW)
5601  - app-crm-plus-frontend (NEW)
```

### Infrastructure
```
5432  - PostgreSQL
6379  - Redis
9000  - MinIO
9001  - MinIO Console
5678  - n8n
```

---

## ✅ Conclusione

**Port allocation finale:**
- ✅ Nessun conflitto con servizi esistenti
- ✅ Schema logico e scalabile (46xx = Advanced ERP)
- ✅ Frontend separati (56xx range)
- ✅ WebSocket su porte consecutive (4600→4601, 4602→4603)
- ✅ Facile da ricordare e documentare

**Next Actions:**
1. Rinominare directories
2. Update configuration files
3. Update INFRASTRUCTURE_REGISTRY.json
4. Update documentation
5. Test startup con nuove porte

---

**Created:** 2025-10-14
**Status:** ✅ Port Schema Approved
**Category:** Infrastructure / Port Management
