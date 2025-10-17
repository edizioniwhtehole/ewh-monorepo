# 🚀 Guida Avvio Leggero - EWH Platform

## Problema
Avviare tutti i servizi contemporaneamente richiede troppa RAM/CPU.

## Soluzioni

### 1. Avvio per Profilo (RACCOMANDATO)

Avvia solo i servizi necessari per la feature su cui stai lavorando:

```bash
# Sviluppo DAM
./start-profiles.sh dam

# Sviluppo Project Management
./start-profiles.sh pm

# Sviluppo CMS
./start-profiles.sh cms

# Sviluppo Admin
./start-profiles.sh admin

# Solo autenticazione e gateway
./start-profiles.sh minimal
```

### 2. Avvio Manuale Servizi Singoli

Se vuoi controllo totale:

```bash
# 1. Database e Redis (sempre necessari)
docker compose up -d postgres redis

# 2. Servizi core
cd svc-auth && npm run dev &
cd svc-api-gateway && npm run dev &

# 3. Aggiungi quello che ti serve
cd svc-pm && npm run dev &
cd app-pm-frontend && npm run dev &
```

### 3. Docker con Limiti

```bash
# Avvia solo essenziali con limiti di memoria
docker compose -f compose/docker-compose.light.yml up
```

### 4. Usa Hot Swap

Invece di avviare tutto, tieni attivi solo:
- Database/Redis
- Auth
- Gateway
- Shell

Poi avvia/ferma i singoli microservizi quando servono.

## Monitoraggio

```bash
# Vedi cosa sta consumando risorse
./scripts/monitor-resources.sh

# PM2 lista servizi
npx pm2 list

# PM2 stop servizio specifico
npx pm2 stop svc-nome

# Ferma tutto PM2
npx pm2 stop all
npx pm2 delete all
```

## Best Practices

### Per Sviluppo Feature Singola

1. **Identifica dipendenze minime**
   ```
   Feature DAM → Auth + Gateway + Media + DMS + DAM Frontend
   Feature PM → Auth + Gateway + PM + PM Frontend
   ```

2. **Usa profili predefiniti**
   ```bash
   ./start-profiles.sh <profilo>
   ```

3. **Monitora risorse**
   ```bash
   ./scripts/monitor-resources.sh
   ```

### Per Test Integration

Se devi testare interazioni tra servizi:

1. Usa Docker Compose con limiti
2. Avvia solo servizi coinvolti
3. Mock gli altri servizi

### Per Demo/Presentazioni

Se serve il sistema completo:

1. Usa produzione (deployment)
2. Oppure avvia tutto ma in build mode (non dev):
   ```bash
   # Build una volta
   npm run build:all

   # Run production mode (usa meno risorse)
   npm run start:all
   ```

## Configurazione Consigliata PC

| Scenario | RAM | CPU | Servizi |
|----------|-----|-----|---------|
| Sviluppo singolo feature | 8GB | 4 core | 5-8 servizi |
| Sviluppo multi-feature | 16GB | 8 core | 15-20 servizi |
| Sistema completo | 32GB | 12+ core | Tutti |

## Troubleshooting

### PC troppo lento?

```bash
# 1. Vedi cosa consuma
./scripts/monitor-resources.sh

# 2. Ferma tutto
npx pm2 stop all
docker compose down

# 3. Riavvia solo necessario
./start-profiles.sh minimal
# Poi aggiungi quello che serve
```

### Out of Memory?

```bash
# Aumenta limite Node.js
export NODE_OPTIONS="--max-old-space-size=2048"

# Oppure riduci servizi attivi
```

### Port già in uso?

```bash
# Trova processo
lsof -i :3000

# Kill processo
kill -9 <PID>
```

## Riferimenti Rapidi

| Comando | Descrizione |
|---------|-------------|
| `./start-profiles.sh <profile>` | Avvia profilo specifico |
| `./scripts/monitor-resources.sh` | Monitora risorse |
| `npx pm2 list` | Lista servizi PM2 |
| `npx pm2 logs` | Vedi log in tempo reale |
| `npx pm2 stop all` | Ferma tutto PM2 |
| `docker compose down` | Ferma container Docker |

## Profili Disponibili

- **minimal** - Auth + Gateway (2 servizi)
- **core** - Minimal + Shell (3 servizi)
- **dam** - Core + Digital Asset Management (6 servizi)
- **pm** - Core + Project Management (5 servizi)
- **cms** - Core + CMS + Page Builder (6 servizi)
- **admin** - Core + Admin Panel (5 servizi)
- **ecommerce** - Core + E-commerce stack (8 servizi)

## Esempio Workflow Tipico

```bash
# Mattina - Inizio lavoro su PM
./start-profiles.sh pm

# Pomeriggio - Devo testare integrazione con DAM
npx pm2 start svc-media --name media
npx pm2 start app-dam --name dam

# Sera - Fine lavoro
npx pm2 stop all
npx pm2 save
```

---

**TIP**: Usa sempre i profili invece di avviare tutto! Il tuo PC ti ringrazierà 🚀
