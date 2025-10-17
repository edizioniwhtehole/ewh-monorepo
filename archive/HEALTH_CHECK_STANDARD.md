# Health Check Standard - EWH Platform

## Overview

Tutti i servizi nella piattaforma EWH devono implementare un endpoint `/health` standardizzato per il monitoraggio enterprise-grade.

## Standard Endpoint

### URL Pattern
- **Path**: `/health` (per servizi backend)
- **Path**: `/api/health` (per Next.js frontend)
- **Method**: `GET`
- **Response Type**: `application/json`
- **HTTP Status**: `200 OK` (se healthy), `503 Service Unavailable` (se unhealthy)

## Response Format Standard

### Formato Minimo (Required)

```json
{
  "status": "healthy",
  "timestamp": "2025-10-06T20:00:00.000Z",
  "service": "service-name"
}
```

### Formato Completo (Recommended)

```json
{
  "status": "healthy",
  "timestamp": "2025-10-06T20:00:00.000Z",
  "service": "service-name",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "dependencies": {
    "database": {
      "status": "healthy",
      "latency_ms": 2,
      "critical": true
    },
    "redis": {
      "status": "healthy",
      "latency_ms": 1,
      "critical": false
    }
  },
  "system": {
    "memory": {
      "used_mb": 256,
      "total_mb": 1024,
      "percentage": 25
    },
    "cpu": {
      "percentage": 15
    }
  }
}
```

## Field Definitions

### Required Fields

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `status` | string | `"healthy"`, `"degraded"`, `"unhealthy"` | Current service health status |
| `timestamp` | string | ISO 8601 | Timestamp when health was checked |
| `service` | string | - | Service identifier (e.g., "svc-auth", "app-web-frontend") |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Service version (semver) |
| `uptime_seconds` | number | Seconds since service started |
| `dependencies` | object | Health status of critical dependencies |
| `system` | object | System resource usage |

### Status Values

- **`healthy`**: Service is fully operational
- **`degraded`**: Service is operational but with reduced performance
- **unhealthy`**: Service is not operational (should return HTTP 503)

## Implementation Examples

### Next.js Frontend (TypeScript)

```typescript
// pages/api/health.ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'app-web-frontend',
    version: process.env.APP_VERSION || '1.0.0'
  });
}
```

### Fastify Backend (TypeScript)

```typescript
// Using shared health-check.ts
import { registerHealthChecks, createDatabaseCheck } from './shared/health-check.js';

registerHealthChecks(fastify, 'svc-auth', '1.0.0', [
  createDatabaseCheck(pool)
]);
```

### Express Backend (TypeScript)

```typescript
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'svc-billing',
    version: '1.0.0',
    uptime_seconds: Math.floor(process.uptime())
  });
});
```

## Service Registry

Tutti i servizi devono essere registrati in `INFRASTRUCTURE_REGISTRY.json`:

```json
{
  "name": "svc-example",
  "type": "core",
  "port": 4001,
  "healthEndpoint": "http://localhost:4001/health",
  "critical": true,
  "description": "Example service"
}
```

## Monitoring Integration

### svc-metrics-collector

Il servizio `svc-metrics-collector` raccoglie metriche Docker automaticamente per tutti i container.

**Non è necessario** implementare HTTP health check per container Docker - il metrics collector usa Docker API.

### app-admin-frontend Dashboard

Il dashboard enterprise monitoring usa due fonti:

1. **HTTP Health Checks** - Per servizi con endpoint `/health`
2. **Docker Metrics** - Per tutti i container Docker (via svc-metrics-collector)

## Migration Guide

### Servizi Esistenti

Per aggiornare un servizio esistente:

1. **Verificare endpoint attuale**
   ```bash
   curl http://localhost:PORT/health
   ```

2. **Aggiornare response format**
   - Cambiare `"status": "ok"` → `"status": "healthy"`
   - Aggiungere `timestamp` e `service` fields

3. **Testare con dashboard**
   ```bash
   curl http://localhost:3200/api/infrastructure/status | grep "service-name"
   ```

### Nuovi Servizi

Per nuovi servizi, usare il template da `shared/health-check.ts`:

```typescript
import { registerHealthChecks } from '../shared/health-check.js';

registerHealthChecks(fastify, 'service-name', '1.0.0', [
  // Add dependency checks here
]);
```

## Common Issues

### Issue: Dashboard shows service as unhealthy

**Cause**: Response format mismatch

**Fix**: Ensure `status` field is exactly `"healthy"` (not "ok", "up", etc.)

```json
✅ { "status": "healthy" }
❌ { "status": "ok" }
❌ { "status": "UP" }
```

### Issue: Health check timeout

**Cause**: Slow dependency checks

**Fix**: Add timeout to dependency health checks (max 2 seconds)

```typescript
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 2000);
```

## Testing

### Unit Test Example

```typescript
describe('Health Endpoint', () => {
  it('should return healthy status', async () => {
    const response = await fetch('http://localhost:4001/health');
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.status).toBe('healthy');
    expect(data.service).toBeDefined();
    expect(data.timestamp).toBeDefined();
  });
});
```

### Integration Test

```bash
# Test all services health
curl http://localhost:3200/api/infrastructure/status | jq '.healthy'

# Should return count of healthy services
```

## Compliance Checklist

- [ ] Endpoint accessible at `/health` or `/api/health`
- [ ] Returns JSON with `status`, `timestamp`, `service` fields
- [ ] Status is exactly `"healthy"`, `"degraded"`, or `"unhealthy"`
- [ ] Response time < 2 seconds
- [ ] Registered in `INFRASTRUCTURE_REGISTRY.json`
- [ ] Documented in service README
- [ ] Unit tests for health endpoint
- [ ] Monitoring dashboard shows correct status

## References

- [INFRASTRUCTURE_REGISTRY.json](/INFRASTRUCTURE_REGISTRY.json)
- [Enterprise Monitoring Analysis](/ENTERPRISE_MONITORING_ANALYSIS.md)
- [shared/health-check.ts](/shared/health-check.ts)

---

**Last Updated**: 2025-10-06
**Version**: 1.0.0
**Status**: ✅ Active Standard
