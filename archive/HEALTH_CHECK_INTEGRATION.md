# Enterprise Health Check System - Integration Guide

## Overview

È stato creato un sistema di health check enterprise-grade condiviso che tutti i microservizi possono utilizzare. Il sistema fornisce tre endpoint standard Kubernetes-compatible:

- `/health` - Stato completo del servizio con tutte le dipendenze
- `/health/live` - Liveness probe (il servizio è vivo?)
- `/health/ready` - Readiness probe (il servizio può ricevere traffico?)

## File Creati

### `/shared/health-check.ts`

Modulo condiviso che fornisce:
- `registerHealthChecks()` - Registra tutti e 3 gli endpoint
- `createDatabaseCheck()` - Health check per PostgreSQL
- `createRedisCheck()` - Health check per Redis
- `createHttpCheck()` - Health check per API esterne

## Come Integrare nei Servizi

### 1. Importare il modulo

```typescript
import { registerHealthChecks, createDatabaseCheck } from '../../shared/health-check.js';
```

### 2. Registrare gli health checks

```typescript
// Dopo aver creato l'istanza Fastify
const fastify = Fastify({ logger: false });

// Registra health checks con le dipendenze del servizio
registerHealthChecks(
  fastify,
  'svc-your-service-name',
  process.env.APP_VERSION || '1.0.0',
  [
    createDatabaseCheck(pool),  // Se usa PostgreSQL
    // Aggiungi altre dipendenze...
  ]
);
```

### 3. Esempio Completo

```typescript
import { Pool } from 'pg';
import Fastify from 'fastify';
import { registerHealthChecks, createDatabaseCheck, createRedisCheck } from '../../shared/health-check.js';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});

const fastify = Fastify({ logger: false });

// Registra health checks
registerHealthChecks(fastify, 'svc-orders', '1.0.0', [
  createDatabaseCheck(pool),
  // Se hai Redis:
  // createRedisCheck(redisClient)
]);

// ... resto del codice
```

## Formato Risposta

### `/health` - Full Health Check

```json
{
  "status": "healthy",  // "healthy" | "degraded" | "unhealthy"
  "timestamp": "2025-10-06T15:20:00.000Z",
  "uptime_seconds": 3600,
  "version": "1.0.0",
  "service_name": "svc-orders",
  "dependencies": {
    "database": {
      "status": "healthy",
      "latency_ms": 5,
      "critical": true
    }
  },
  "system": {
    "memory": {
      "used_mb": 128,
      "total_mb": 512,
      "percentage": 25
    },
    "uptime_seconds": 3600
  }
}
```

**HTTP Status Codes:**
- `200` - healthy o degraded
- `503` - unhealthy (servizio non funzionante)

### `/health/live` - Liveness Probe

```json
{
  "status": "alive",
  "timestamp": "2025-10-06T15:20:00.000Z",
  "uptime_seconds": 3600
}
```

**Sempre ritorna 200** - usato per riavviare container morti

### `/health/ready` - Readiness Probe

```json
{
  "status": "ready",
  "timestamp": "2025-10-06T15:20:00.000Z"
}
```

**HTTP Status Codes:**
- `200` - ready (può ricevere traffico)
- `503` - not ready (non mandare traffico qui)

## Stati delle Dipendenze

### Healthy ✅
- Dipendenza funziona correttamente
- Latenza accettabile

### Degraded ⚠️
- Dipendenza funziona ma con latenza alta
- Performance ridotte
- **Il servizio è ancora utilizzabile**

### Unhealthy ❌
- Dipendenza non risponde o ha errori
- Se la dipendenza è `critical: true`, l'intero servizio è unhealthy

## Critical vs Non-Critical

```typescript
{
  name: 'database',
  critical: true,  // ← Se fallisce, servizio unhealthy
  check: createDatabaseCheck(pool)
}

{
  name: 'redis',
  critical: false,  // ← Se fallisce, servizio degraded (cache opzionale)
  check: createRedisCheck(redis)
}
```

## Kubernetes Integration

### Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: svc-orders
spec:
  template:
    spec:
      containers:
      - name: svc-orders
        image: ewh/svc-orders:1.0.0
        ports:
        - containerPort: 3000

        # Liveness probe: restart se morto
        livenessProbe:
          httpGet:
            path: /health/live
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        # Readiness probe: rimuovi dal load balancer se not ready
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
```

## Scalingo Integration

### scalingo.json

```json
{
  "formation": {
    "web": {
      "amount": 2,
      "size": "M"
    }
  },
  "healthcheck": {
    "endpoint": "/health/ready",
    "timeout": 5,
    "max_retries": 3
  }
}
```

## Monitoraggio

### UptimeRobot

Crea monitor per ogni servizio:
- **Monitor Type:** HTTP(s)
- **URL:** `https://svc-orders.polosaas.it/health`
- **Monitoring Interval:** 5 minutes
- **Alert Contacts:** team@polosaas.it, PagerDuty

### Datadog

```yaml
# monitors/service-health.yaml
name: "Service {{service_name.name}} is unhealthy"
type: metric alert
query: "avg(last_5m):avg:service.health{status:unhealthy} by {service_name} > 0"
message: |
  {{#is_alert}}
  Service {{service_name.name}} is reporting unhealthy status.
  Check /health endpoint for details.
  {{/is_alert}}
thresholds:
  critical: 0
```

## Servizi da Aggiornare

Applicare l'integrazione health check a tutti i 46 microservizi:

```bash
# Lista servizi
svc-assistant
svc-auth
svc-bi
svc-billing
svc-boards
svc-channels
svc-chat
svc-collab
svc-comm
svc-connectors-web
svc-content
svc-crm
svc-dms
svc-enrichment
svc-forms
svc-forum
svc-image-orchestrator
svc-inventory
svc-job-worker
svc-kb
svc-layout
svc-media
svc-metrics-collector  # ✅ FATTO
svc-mockup
svc-mrp
svc-orders
svc-plugins
svc-pm
svc-prepress
svc-procurement
svc-products
svc-projects
svc-quotation
svc-raster-runtime
svc-search
svc-shipping
svc-site-builder
svc-site-publisher
svc-site-renderer
svc-support
svc-timesheet
svc-vector-lab
svc-video-orchestrator
svc-video-runtime
svc-writer
svc-api-gateway
```

## Script di Migrazione Automatica

```bash
#!/bin/bash
# migrate-health-checks.sh

SERVICES=(
  "svc-auth"
  "svc-orders"
  "svc-products"
  # ... altri servizi
)

for SERVICE in "${SERVICES[@]}"; do
  echo "Updating $SERVICE..."

  # 1. Aggiungi import
  sed -i '' "1s;^;import { registerHealthChecks, createDatabaseCheck } from '../../shared/health-check.js';\n;" \
    "$SERVICE/src/index.ts"

  # 2. Sostituisci vecchio health check
  # (questo dipende dalla struttura specifica di ogni servizio)

  echo "✅ $SERVICE updated"
done
```

## Test

### Test Manuale

```bash
# Full health check
curl http://localhost:3000/health

# Liveness
curl http://localhost:3000/health/live

# Readiness
curl http://localhost:3000/health/ready
```

### Test Automatico

```typescript
// tests/health.test.ts
import { test } from 'tap';
import { build } from './helper.js';

test('health check returns 200', async (t) => {
  const app = await build(t);

  const response = await app.inject({
    method: 'GET',
    url: '/health'
  });

  t.equal(response.statusCode, 200);
  const body = JSON.parse(response.body);
  t.ok(['healthy', 'degraded'].includes(body.status));
  t.ok(body.dependencies.database);
});
```

## Best Practices

### 1. Timeout Adeguati

```typescript
// ❌ Timeout troppo lungo
await pool.query('SELECT 1', { timeout: 30000 })

// ✅ Timeout breve per health checks
await pool.query('SELECT 1', { timeout: 3000 })
```

### 2. Cache Results

```typescript
// Per health checks non-critical che sono costosi
const cachedCheck = {
  name: 'external-api',
  critical: false,
  check: cachedHttpCheck('https://api.example.com/health', {
    cacheTTL: 30000 // 30 secondi
  })
};
```

### 3. Dependency Priority

```typescript
// Order by criticality
registerHealthChecks(fastify, 'svc-orders', '1.0.0', [
  createDatabaseCheck(pool),         // Critical: database
  createRedisCheck(redis),           // Non-critical: cache
  createHttpCheck('stripe', '...')   // Non-critical: payment API
]);
```

## Troubleshooting

### "Module not found" Error

```bash
# Assicurati che shared/ sia nella stessa directory root
cd /Users/andromeda/dev/ewh
ls -la shared/health-check.ts
```

### TypeScript Import Issues

```typescript
// ❌ Non funziona con .ts extension
import { registerHealthChecks } from '../../shared/health-check.ts';

// ✅ Usa .js anche se è .ts (Node.js ESM)
import { registerHealthChecks } from '../../shared/health-check.js';
```

### Service Not Starting

Verifica che il pool/dipendenze siano create PRIMA di registrare health checks:

```typescript
// ✅ Corretto ordine
const pool = new Pool({ ... });
const fastify = Fastify();
registerHealthChecks(fastify, 'svc-orders', '1.0.0', [
  createDatabaseCheck(pool)
]);
await fastify.listen({ port: 3000 });
```

## Next Steps

1. ✅ **Creato modulo condiviso** health-check.ts
2. ✅ **Integrato in svc-metrics-collector** come esempio
3. 🔲 Applicare a tutti i 46 microservizi (script automatico)
4. 🔲 Setup UptimeRobot/Datadog monitoring
5. 🔲 Aggiungere health dashboard nell'admin UI
6. 🔲 Configurare Kubernetes probes (se si usa K8s)
7. 🔲 Documentare SLA e escalation procedures

## References

- [Kubernetes Liveness/Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Health Check API Pattern](https://microservices.io/patterns/observability/health-check-api.html)
- [12-Factor App - Admin Processes](https://12factor.net/admin-processes)

---

**Creato:** 2025-10-06
**Versione:** 1.0.0
**Owner:** Platform Team
