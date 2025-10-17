# Sistema di Log Aggregation

Sistema completo di logging su filesystem con lettura real-time per monitoring dashboard.

## Architettura

```
Servizi → File Logger → Filesystem (/var/log/ewh/)
                              ↓
                        Log Reader API
                              ↓
                    Admin Frontend Widgets
```

## Struttura Filesystem

```
/var/log/ewh/
├── access/
│   └── YYYY/
│       └── MM/
│           └── DD/
│               └── access.log
└── errors/
    └── YYYY/
        └── MM/
            └── DD/
                ├── svc-auth.error.log
                ├── svc-api-gateway.error.log
                └── svc-*.error.log
```

## Formato Log

### Access Log
```
[2024-10-06T09:45:23.123Z] [INFO] [svc-api-gateway] GET /api/tenants 200 45ms user=user123 tenant=tenant456 Request completed
```

### Error Log
```
[2024-10-06T09:45:10.456Z] [ERROR] [svc-media] POST /upload 500 2300ms user=user789 Failed to process image: Out of memory
```

## Implementazione

### 1. FileLogger Class

File: `svc-metrics-collector/src/logging/file-logger.ts`

```typescript
export class FileLogger {
  async logAccess(entry: LogEntry): Promise<void>
  async logError(entry: LogEntry): Promise<void>
  async readLogs(options): Promise<string[]>
  async streamLogs(options): Promise<void>
}
```

### 2. API Endpoints

Aggiungere a `svc-metrics-collector`:

```typescript
// GET /logs?type=access&date=2024-10-06&limit=100
fastify.get('/logs', async (request, reply) => {
  const { type, date, service, limit } = request.query;
  const logger = new FileLogger();
  const logs = await logger.readLogs({ type, date, service, limit });
  return logs;
});

// GET /logs/stream (SSE)
fastify.get('/logs/stream', async (request, reply) => {
  reply.raw.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  });

  const logger = new FileLogger();
  await logger.streamLogs({
    type: 'access',
    callback: (line) => {
      reply.raw.write(`data: ${JSON.stringify({ log: line })}\n\n`);
    }
  });
});
```

### 3. Middleware per Servizi

Ogni servizio deve loggare le richieste:

```typescript
// Esempio per svc-api-gateway
import { FileLogger } from './logging/file-logger';

const logger = new FileLogger();

fastify.addHook('onResponse', async (request, reply) => {
  await logger.logAccess({
    timestamp: new Date().toISOString(),
    level: reply.statusCode >= 400 ? 'warning' : 'info',
    service: 'svc-api-gateway',
    method: request.method,
    path: request.url,
    status: reply.statusCode,
    duration: reply.getResponseTime(),
    message: 'Request completed',
    userId: request.user?.id,
    tenantId: request.tenant?.id
  });

  if (reply.statusCode >= 500) {
    await logger.logError({
      timestamp: new Date().toISOString(),
      level: 'error',
      service: 'svc-api-gateway',
      method: request.method,
      path: request.url,
      status: reply.statusCode,
      message: reply.error?.message || 'Internal server error'
    });
  }
});
```

### 4. Frontend Integration

#### LogStreamWidget (Real-time SSE)

```typescript
useEffect(() => {
  const eventSource = new EventSource('http://localhost:4010/logs/stream');
  
  eventSource.onmessage = (event) => {
    const data = JSON.parse(event.data);
    setLogs(prev => [...prev, parselog(data.log)]);
  };

  return () => eventSource.close();
}, []);
```

#### System Logs Page (Historical)

```typescript
async function fetchLogs() {
  const response = await fetch(
    `/api/logs?type=${logType}&date=${selectedDate}&service=${selectedService}&limit=100`
  );
  const logs = await response.json();
  setLogs(logs.map(parselog));
}
```

## Rotazione Log

### Script Giornaliero

File: `svc-metrics-collector/scripts/rotate-logs.sh`

```bash
#!/bin/bash
# Comprimi log più vecchi di 1 giorno

LOG_DIR="/var/log/ewh"
FIND_DATE=$(date -d "1 day ago" +%Y/%m/%d)

find "$LOG_DIR" -type f -name "*.log" -path "*/$FIND_DATE/*" -exec gzip {} \;

# Elimina log compressi più vecchi di 90 giorni
find "$LOG_DIR" -type f -name "*.log.gz" -mtime +90 -delete

echo "Log rotation completed at $(date)"
```

### Cron Job

```cron
0 1 * * * /path/to/rotate-logs.sh >> /var/log/ewh/rotation.log 2>&1
```

## Performance

### Scrittura Asincrona

- Usa buffer in memoria per batch writes
- Flush ogni 1 secondo o 100 entry
- Non blocca le richieste

### Lettura Ottimizzata

- Indexing con `tail` per ultimi log
- Caching per query frequenti
- Streaming per file grandi

## Storage Estimates

### Volume tipico (30 servizi, 1000 req/min)

- Access logs: ~500 MB/giorno
- Error logs: ~50 MB/giorno
- Compressi: ~50 MB/giorno
- 90 giorni retention: ~4.5 GB

## Security

- File permission 640 (rw-r-----)
- Directory permission 750 (rwxr-x---)
- Owner: metrics-collector user
- Group: admin group
- No sensitive data in logs (mask passwords, tokens)

## Monitoring

Metriche da tracciare:

- Log write rate (entries/sec)
- Disk usage (/var/log/ewh)
- Failed writes count
- Rotation job status

## Next Steps

1. [ ] Implementare FileLogger class
2. [ ] Aggiungere logging middleware a tutti i servizi
3. [ ] Creare API /logs e /logs/stream
4. [ ] Integrare SSE in LogStreamWidget
5. [ ] Implementare script rotazione
6. [ ] Configurare cron job
7. [ ] Testare con carico reale
8. [ ] Aggiungere monitoring metriche log

## References

- [Winston Logger](https://github.com/winstonjs/winston)
- [Pino Fast Logger](https://github.com/pinojs/pino)
- [Log4js](https://log4js-node.github.io/log4js-node/)
- [Syslog Protocol](https://datatracker.ietf.org/doc/html/rfc5424)
