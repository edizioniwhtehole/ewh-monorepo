# Quick Start - Sistema Auto-Avvio EWH

## 🚀 Avvio in 3 Passi

### 1. Installa le dipendenze
```bash
cd /Users/andromeda/dev/ewh
pnpm install
```

### 2. Avvia l'orchestratore
```bash
./start-orchestrator.sh
```
oppure
```bash
pnpm start
```

### 3. Apri la shell
Vai su http://localhost:3000 (o la porta configurata per app-shell-frontend)

## ✅ Cosa Succede Automaticamente

1. **L'orchestratore si avvia** e cerca tutti i servizi
2. **Backend vengono avviati** per primi (svc-*)
   - svc-api-gateway (4000)
   - svc-auth (4001)
   - svc-pm (4400)
   - ... e tutti gli altri
3. **Frontend vengono avviati** dopo (app-*)
   - app-shell-frontend (3000)
   - app-web-frontend (3100)
   - app-admin-frontend (3200)
   - app-dam (3300)
   - ... e tutti gli altri
4. **Service registry viene creato** (`service-registry.json`)
5. **Watcher vengono attivati** per hot-reload
6. **Health check partono** ogni 10 secondi

## 📊 Cosa Vedi

Il terminale mostra:
```
═══════════════════════════════════════════════════════════════
            EWH Service Orchestrator - Status
═══════════════════════════════════════════════════════════════

Frontends:
  ● app-shell-frontend         :3000  (120s)
  ● app-web-frontend            :3100  (115s)
  ● app-admin-frontend          :3200  (110s)
  ● app-dam                     :3300  (105s)

Backends:
  ● svc-api-gateway             :4000  (130s)
  ● svc-auth                    :4001  (128s)
  ● svc-pm                      :4400  (100s)

Commands: [r]estart all | [q]uit | [s]tatus
═══════════════════════════════════════════════════════════════
```

**Legenda:**
- 🟢 `●` = Servizio healthy
- 🟡 `◐` = Servizio starting
- 🔴 `◯` = Servizio unhealthy

## 🔄 Workflow Automatico

### Modifica un File
1. Edita `app-dam/src/components/Example.tsx`
2. Salva il file
3. **Automaticamente**:
   - L'orchestratore rileva il cambiamento
   - Riavvia `app-dam`
   - La shell si aggiorna da sola
   - L'iframe ricarica il contenuto

### Aggiungi un Servizio
1. Crea `app-nuovo/` con `package.json`
2. Aggiungi lo script `dev` in package.json
3. Aggiungi al `service-orchestrator.js`:
   ```javascript
   { name: 'app-nuovo', port: 3xxx, path: 'app-nuovo', type: 'nextjs' }
   ```
4. Riavvia l'orchestratore
5. **Il servizio appare automaticamente** nella shell

## 🎯 Accesso ai Servizi

### Dalla Shell Frontend

#### Hook per tutti i servizi:
```tsx
import { useServiceRegistry } from '@/hooks/useServiceRegistry';

const { registry, loading } = useServiceRegistry();
// registry.frontends = array di frontend
// registry.backends = array di backend
```

#### Hook per frontends:
```tsx
import { useFrontends } from '@/hooks/useServiceRegistry';

const { frontends, loading, refresh } = useFrontends();
```

#### Hook per backends:
```tsx
import { useBackends } from '@/hooks/useServiceRegistry';

const { backends, loading, refresh } = useBackends();
```

### Montare un Servizio in Iframe

```tsx
import DynamicServiceMount from '@/components/DynamicServiceMount';

// Nel tuo componente
<DynamicServiceMount
  serviceName="app-dam"
  onLoad={() => console.log('DAM loaded!')}
  onError={(err) => console.error('Error:', err)}
/>
```

### Navigatore Servizi

```tsx
import ServiceNavigator from '@/components/ServiceNavigator';

<ServiceNavigator
  onServiceSelect={(service) => {
    router.push(`/service/${service.name}`);
  }}
/>
```

## 🔧 Comandi Utili

```bash
# Avvia tutto
pnpm start

# Solo orchestratore
pnpm run orchestrator

# Ferma tutto
Ctrl+C nel terminale dell'orchestratore

# Verifica porte in uso
lsof -i :3000
lsof -i :4000

# Libera una porta
lsof -ti:3000 | xargs kill -9

# Vedi il registry
cat service-registry.json | jq
```

## 📝 File Importanti

```
/Users/andromeda/dev/ewh/
├── service-orchestrator.js          # Orchestratore principale
├── start-orchestrator.sh            # Script di avvio
├── service-registry.json            # Registry (auto-generato, non committare)
├── package.json                     # Dipendenze orchestratore
│
├── app-shell-frontend/
│   └── src/
│       ├── hooks/
│       │   └── useServiceRegistry.ts   # Hook per accedere al registry
│       └── components/
│           ├── ServiceNavigator.tsx     # UI per navigare servizi
│           └── DynamicServiceMount.tsx  # Monta servizi in iframe
│
└── app-*/                           # Tutti i frontend
└── svc-*/                           # Tutti i backend
```

## 🐛 Problemi Comuni

### Porta già in uso
```bash
# Trova il processo
lsof -i :3000

# Uccidilo
lsof -ti:3000 | xargs kill -9

# Riavvia orchestratore
pnpm start
```

### Servizio non parte
1. Verifica `package.json` ha script `dev`
2. Testa manualmente:
   ```bash
   cd app-dam
   pnpm run dev
   ```
3. Controlla i log dell'orchestratore

### Hot-reload non funziona
1. Verifica che il file sia dentro una cartella watchata
2. Aspetta 1-2 secondi dopo il salvataggio
3. Controlla i log per vedere se il watcher si è attivato

### Shell non vede i servizi
1. Verifica che `service-registry.json` esista:
   ```bash
   ls -la service-registry.json
   ```
2. Verifica il contenuto:
   ```bash
   cat service-registry.json | jq
   ```
3. Ricarica la shell (F5)

## 🎨 Personalizzazione

### Cambia intervalli di polling
In `service-orchestrator.js`:
```javascript
const CONFIG = {
  pollInterval: 5000,           // 5 secondi (cambia qui)
  restartDelay: 2000,           // 2 secondi prima di restart
  healthCheckInterval: 10000,   // 10 secondi health check
}
```

### Cambia file da watchare
In `service-orchestrator.js`:
```javascript
watchPatterns: [
  '**/src/**/*.{ts,tsx,js,jsx}',  // Tutto il src/
  '**/package.json',               // package.json
  '**/.env*',                      // .env files
  '**/pages/**/*.tsx',             // Aggiungi questo per Next.js pages
]
```

### Aggiungi health check custom
In ogni servizio, aggiungi endpoint `/health`:
```typescript
// Express
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

// Next.js API Route
// pages/api/health.ts
export default function handler(req, res) {
  res.status(200).json({ status: 'ok' });
}
```

## 📊 Monitoring

### Vedi tutti i servizi running
```bash
ps aux | grep "pnpm run dev"
```

### Vedi porte in ascolto
```bash
lsof -iTCP -sTCP:LISTEN | grep node
```

### Vedi uptime servizi
Guarda il terminale dell'orchestratore o il `service-registry.json`

## 🎓 Tutorial Completo

Vedi [AUTO_START_SYSTEM.md](./AUTO_START_SYSTEM.md) per:
- Architettura dettagliata
- API Reference
- Esempi avanzati
- Troubleshooting completo
- Best practices

## 🚦 Status Check

Dopo l'avvio, verifica:

✅ Orchestratore running (vedi logs)
✅ service-registry.json esiste e si aggiorna
✅ Frontend raggiungibili (localhost:3xxx)
✅ Backend raggiungibili (localhost:4xxx)
✅ Shell mostra i servizi nel ServiceNavigator
✅ Hot-reload funziona (modifica un file e vedi reload)

Se tutto è ✅ sei pronto! 🎉
