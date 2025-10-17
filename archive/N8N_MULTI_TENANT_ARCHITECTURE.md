# Architettura Multi-Tenant per n8n

## 🎯 Problema

n8n **non è multi-tenant nativo**:
- Tutti gli utenti condividono gli stessi workflow
- Non c'è isolamento tra organizzazioni
- Un tenant può vedere i workflow di altri tenant

## ✅ Soluzione: Istanze Dedicate per Tenant

### Approccio 1: Database Isolation (Raccomandato)

Ogni tenant ha il suo database n8n, ma condivide la stessa istanza:

```
┌─────────────────────────────────────────────────────┐
│              API Gateway / Proxy                     │
│           (rileva tenant da JWT)                     │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │  n8n    │    │  n8n    │    │  n8n    │
   │ Process │    │ Process │    │ Process │
   │ Tenant A│    │ Tenant B│    │ Tenant C│
   │ Port    │    │ Port    │    │ Port    │
   │ 5678    │    │ 5679    │    │ 5680    │
   └─────────┘    └─────────┘    └─────────┘
        │               │               │
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │   DB    │    │   DB    │    │   DB    │
   │tenant_a │    │tenant_b │    │tenant_c │
   │(schema) │    │(schema) │    │(schema) │
   └─────────┘    └─────────┘    └─────────┘
```

### Approccio 2: Container per Tenant (Più Isolamento)

Ogni tenant ha un container Docker dedicato:

```yaml
# docker-compose.tenant-a.yml
services:
  n8n-tenant-a:
    image: n8nio/n8n
    environment:
      - DB_POSTGRESDB_DATABASE=ewh_tenant_a
      - N8N_PORT=5678
    ports:
      - "5678:5678"

# docker-compose.tenant-b.yml
services:
  n8n-tenant-b:
    image: n8nio/n8n
    environment:
      - DB_POSTGRESDB_DATABASE=ewh_tenant_b
      - N8N_PORT=5678
    ports:
      - "5679:5678"
```

## 🏗️ Implementazione Consigliata

### 1. Servizio di Provisioning Tenant

```typescript
// svc-n8n-manager/src/provision.ts
async function provisionTenantN8n(tenantId: string) {
  // 1. Crea database schema per tenant
  await createTenantSchema(tenantId);

  // 2. Trova porta disponibile
  const port = await findAvailablePort();

  // 3. Avvia istanza n8n per tenant
  const process = spawn('npx', ['n8n', 'start'], {
    env: {
      N8N_PORT: port,
      DB_POSTGRESDB_DATABASE: `ewh_${tenantId}`,
      DB_POSTGRESDB_SCHEMA: `n8n_${tenantId}`,
      N8N_ENCRYPTION_KEY: generateTenantEncryptionKey(tenantId)
    }
  });

  // 4. Registra mapping tenant → porta
  await registerTenantInstance(tenantId, port);

  return { tenantId, port };
}
```

### 2. Proxy di Routing

```typescript
// svc-n8n-proxy/src/tenant-router.ts
app.use('/', async (req, res, next) => {
  // Estrai tenant ID dal JWT
  const token = req.headers.authorization?.split(' ')[1];
  const decoded = jwt.verify(token, publicKey);
  const tenantId = decoded.org_id;

  // Trova porta dell'istanza n8n del tenant
  const tenantPort = await getTenantN8nPort(tenantId);

  if (!tenantPort) {
    // Provisiona istanza se non esiste
    const { port } = await provisionTenantN8n(tenantId);
    tenantPort = port;
  }

  // Proxy alla porta del tenant
  proxy({
    target: `http://localhost:${tenantPort}`,
    changeOrigin: true
  })(req, res, next);
});
```

### 3. Database Schema per Tenant

```sql
-- Per ogni tenant
CREATE SCHEMA IF NOT EXISTS n8n_tenant_a;
CREATE SCHEMA IF NOT EXISTS n8n_tenant_b;
CREATE SCHEMA IF NOT EXISTS n8n_tenant_c;

-- Configura permessi
GRANT ALL ON SCHEMA n8n_tenant_a TO ewh;
GRANT ALL ON SCHEMA n8n_tenant_b TO ewh;
GRANT ALL ON SCHEMA n8n_tenant_c TO ewh;
```

## 📊 Comparazione Approcci

| Feature | Database Schema | Container per Tenant | Multi-Instance Process |
|---------|----------------|---------------------|----------------------|
| **Isolamento** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Costi RAM** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Scaling** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Complessità** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## 🎯 Raccomandazione per EWH

**Approccio Ibrido:**

1. **Per tenant piccoli (<100 workflow)**: Database schema isolation
2. **Per tenant enterprise**: Container dedicato su nodo separato
3. **Per tenant premium**: VM/server dedicato

### Implementazione Fase 1 (MVP)

```
Tutti i tenant → Database schema isolation
├── n8n-tenant-manager (gestisce provisioning)
├── n8n-router (routing basato su JWT)
└── PostgreSQL con schema per tenant
```

### Implementazione Fase 2 (Scale)

```
Tenant piccoli → Shared n8n process (schema isolation)
Tenant grandi → Dedicated container
Tenant enterprise → Dedicated VM
```

## 🔧 File da Creare

1. **svc-n8n-manager** - Gestione lifecycle istanze n8n
   - `src/provision.ts` - Provisioning tenant
   - `src/registry.ts` - Registry tenant → porta
   - `src/health.ts` - Health check istanze

2. **svc-n8n-router** - Proxy intelligente
   - `src/router.ts` - Routing basato su tenant
   - `src/auth.ts` - Validazione JWT
   - `src/cache.ts` - Cache mapping tenant

3. **Database migrations**
   - `migrations/create-tenant-schema.sql`
   - `migrations/tenant-registry-table.sql`

## 🚀 Prossimi Passi

1. ✅ Creare `svc-n8n-manager`
2. ⏳ Implementare provisioning automatico
3. ⏳ Creare routing proxy
4. ⏳ Testare con 2-3 tenant
5. ⏳ Monitoring e scaling

## 💡 Considerazioni

### Pro Database Schema Approach
- ✅ Basso consumo risorse (1 processo n8n serve N tenant)
- ✅ Startup rapido per nuovi tenant
- ✅ Facile backup/restore per tenant
- ✅ Cost-effective

### Contro
- ⚠️ Un crash impatta tutti i tenant
- ⚠️ Più complesso debugging
- ⚠️ Condivisione risorse (CPU/RAM)

### Pro Container Approach
- ✅ Isolamento completo
- ✅ Scaling indipendente
- ✅ Failure isolation
- ✅ Resource limits per tenant

### Contro
- ⚠️ Più RAM richiesta (300-500MB per container)
- ⚠️ Più complesso orchestrazione
- ⚠️ Startup più lento

## 🎓 Best Practices

1. **Lazy Loading**: Provisiona istanze n8n solo quando tenant accede la prima volta
2. **Auto-Shutdown**: Ferma istanze n8n inattive da >30 giorni
3. **Resource Limits**: Imposta CPU/RAM limits per tenant
4. **Monitoring**: Track workflow executions per tenant
5. **Backup**: Backup automatico schema DB per tenant

## 📚 Risorse

- [n8n Self-Hosting](https://docs.n8n.io/hosting/)
- [PostgreSQL Schema Isolation](https://www.postgresql.org/docs/current/ddl-schemas.html)
- [Multi-tenancy Patterns](https://docs.microsoft.com/en-us/azure/architecture/patterns/multitenancy)
