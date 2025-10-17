# Sistema di Metriche Time-Series

Sistema completo di raccolta, aggregazione e visualizzazione di metriche dei servizi con downsampling progressivo.

## 📊 Overview

**svc-metrics-collector** raccoglie metriche Docker ogni 5 secondi e le aggrega progressivamente in 9 livelli di risoluzione, mantenendo max/min/median per ogni metrica.

## 🎯 Metriche Raccolte

Per ogni servizio vengono tracciati:
- **CPU Usage** (%)
- **Memory Usage** (%)
- **Response Time** (ms)
- **Error Rate** (%)
- **Uptime** (%)

## 📈 Livelli di Risoluzione

| Risoluzione | Retention | Campioni | Storage/servizio |
|-------------|-----------|----------|------------------|
| 5s | 5 min | 60 | ~3 KB |
| 10s | 15 min | 90 | ~9 KB |
| 30s | 30 min | 60 | ~6 KB |
| 1m | 1 ora | 60 | ~6 KB |
| 6m | 6 ore | 60 | ~6 KB |
| 12m | 12 ore | 60 | ~6 KB |
| 24m | 24 ore | 60 | ~6 KB |
| 1h | 7 giorni | 168 | ~17 KB |
| 6h | 30 giorni | 120 | ~12 KB |
| 1d | ∞ | illimitati | ~1 KB/giorno |

**Totale per servizio**: ~71 KB (real-time) + ~30 KB/mese (storico)

Con 30 servizi: **~2.1 MB + ~900 KB/mese**

## 🗄️ Database Schema

### Tabelle

1. **metrics.raw_metrics**
   - Dati grezzi raccolti ogni 5s
   - Retention: 15 minuti
   - Cleanup automatico

2. **metrics.aggregated_metrics**
   - Aggregati multi-risoluzione
   - Campi: max, min, median per ogni metrica
   - Indicizzato per service_name, bucket_start, resolution

3. **metrics.daily_summary**
   - Riepilogo giornaliero
   - Retention infinita
   - Solo max/min/median

### Funzione Median

PostgreSQL custom function per calcolo mediana efficiente.

## 🔄 Processo di Aggregazione

```
Docker Stats (real-time)
    ↓ ogni 5s
Raw Metrics Table (15 min retention)
    ↓ downsampling progressivo
┌─────────────────────────────────┐
│ Aggregated Metrics (9 livelli) │
│ - 5s  → 5min                    │
│ - 10s → 15min                   │
│ - 30s → 30min                   │
│ - 1m  → 1h                      │
│ - 6m  → 6h                      │
│ - 12m → 12h                     │
│ - 24m → 24h                     │
│ - 1h  → 7d                      │
│ - 6h  → 30d                     │
└─────────────────────────────────┘
    ↓ aggregazione notturna
Daily Summary (infinite retention)
```

## 🌐 API Endpoints

### GET /health
Health check del servizio

### GET /metrics
Query metriche con filtri

**Parametri:**
- `service`: Nome servizio (opzionale)
- `resolution`: Risoluzione in secondi (default: 60)
- `from`: Timestamp inizio (ISO 8601)
- `to`: Timestamp fine (ISO 8601)

**Esempio:**
```bash
curl "http://localhost:4010/metrics?service=svc-auth&resolution=60&from=2024-10-06T00:00:00Z&to=2024-10-06T23:59:59Z"
```

**Response:**
```json
[
  {
    "id": 1,
    "service_name": "svc-auth",
    "bucket_start": "2024-10-06T10:00:00Z",
    "bucket_end": "2024-10-06T10:01:00Z",
    "resolution_seconds": 60,
    "cpu_max": 45.2,
    "cpu_min": 32.1,
    "cpu_median": 38.5,
    "memory_max": 62.8,
    "memory_min": 58.3,
    "memory_median": 60.1,
    "response_time_max": 156.3,
    "response_time_min": 89.2,
    "response_time_median": 112.5,
    "error_rate_max": 0.5,
    "error_rate_min": 0.1,
    "error_rate_median": 0.3,
    "uptime_max": 100,
    "uptime_min": 100,
    "uptime_median": 100,
    "sample_count": 12
  }
]
```

### GET /services
Lista tutti i servizi monitorati

**Response:**
```json
["svc-auth", "svc-api-gateway", "svc-media", ...]
```

## 🚀 Deployment

### Development (locale)

```bash
cd svc-metrics-collector
npm install
npm run migrate  # Crea schema database
npm run dev      # Avvia in dev mode
```

### Docker Compose

Il servizio è già configurato in `docker-compose.dev.yml`:

```bash
# Avvia con profilo default (include metrics)
docker-compose -f compose/docker-compose.dev.yml up -d

# Solo metrics collector
docker-compose -f compose/docker-compose.dev.yml --profile metrics up -d svc-metrics-collector
```

### Production

```bash
docker build -t svc-metrics-collector .
docker run -d \
  --name svc-metrics-collector \
  -p 4010:4010 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e DB_HOST=postgres \
  -e DB_NAME=ewh_master \
  -e DB_USER=ewh \
  -e DB_PASSWORD=xxx \
  svc-metrics-collector
```

## 🎨 UI Integration

### Widget Real-time (Dashboard)

Integrato nella dashboard di monitoring per visualizzare metriche live con grafici interattivi.

### Pagina System Logs

Voce dedicata nel sidebar per consultare:
- Access logs aggregati
- Error logs per servizio
- Ricerca full-text
- Filtri per timestamp, servizio, tipo

## 🧹 Manutenzione Automatica

### Cleanup Orario
- Elimina raw_metrics > 15 minuti
- Rimuove aggregati oltre retention

### Aggregazione Notturna
- Genera daily_summary alle 00:00
- Ottimizza storage

### Monitoraggio
- Healthcheck ogni 30s
- Metriche esposte su /metrics
- Logs strutturati con pino

## 📊 Performance

### Resource Usage
- **CPU**: <5% (media)
- **RAM**: ~100 MB
- **Disk I/O**: ~50 KB/s (scritture aggregate)
- **Network**: trascurabile (solo query DB)

### Latenza API
- Query <50ms (indici ottimizzati)
- Aggregazione asincrona (non-blocking)

## 🔐 Sicurezza

- Docker socket read-only
- Database con credenziali env
- API senza autenticazione (rete interna)
- Logs non contengono dati sensibili

## 📝 Log Aggregation (TODO)

Prossimi step per logging completo:

1. **Access Logs**: `/var/log/ewh/access/YYYY/MM/DD/access.log`
2. **Error Logs**: `/var/log/ewh/errors/YYYY/MM/DD/{service}.error.log`
3. **Rotazione**: gzip automatico daily
4. **Retention**: 90 giorni compressi
5. **Query API**: ricerca full-text con filtri

## 🛠️ Troubleshooting

### Servizio non parte
```bash
# Check logs
docker logs svc_metrics_collector

# Verifica DB connection
psql -h localhost -U ewh -d ewh_master -c "SELECT * FROM metrics.raw_metrics LIMIT 1;"
```

### Metriche non raccolte
```bash
# Verifica Docker socket
docker ps  # deve funzionare dal container

# Check API health
curl http://localhost:4010/health
```

### Query lente
```bash
# Verifica indici
psql -h localhost -U ewh -d ewh_master -c "\d+ metrics.aggregated_metrics"

# Analizza query
EXPLAIN ANALYZE SELECT...
```

## 📚 References

- [PostgreSQL Time-Series](https://www.postgresql.org/docs/current/functions-datetime.html)
- [Dockerode API](https://github.com/apocas/dockerode)
- [Fastify Framework](https://www.fastify.io/)
- [Downsampling Best Practices](https://prometheus.io/docs/prometheus/latest/storage/)
