# Sistema di Auto-Avvio e Hot-Reload EWH

Sistema automatico per avviare, monitorare e ricaricare tutti i frontend e backend dell'ecosistema EWH.

## 🎯 Caratteristiche

- ✅ **Auto-Discovery**: Rileva automaticamente tutti i servizi (app-* e svc-*)
- ✅ **Auto-Start**: Avvia tutti i servizi automaticamente
- ✅ **Hot-Reload**: Riavvia i servizi quando rileva modifiche ai file
- ✅ **Health Monitoring**: Verifica continuamente lo stato dei servizi
- ✅ **Dynamic Mounting**: Monta automaticamente i servizi nella shell frontend
- ✅ **Service Registry**: Registro JSON in tempo reale di tutti i servizi attivi
- ✅ **Auto-Recovery**: Riavvia automaticamente i servizi in caso di crash

## 📦 Componenti

### 1. Service Orchestrator (`service-orchestrator.js`)
L'orchestratore principale che:
- Scopre tutti i servizi nel monorepo
- Li avvia in sequenza (backend prima, poi frontend)
- Monitora i file per hot-reload automatico
- Esegue health check periodici
- Genera un registro dei servizi in tempo reale

### 2. Service Registry Hook (`useServiceRegistry.ts`)
Hook React per accedere al registro dei servizi:
```typescript
import { useServiceRegistry, useFrontends, useBackends } from '@/hooks/useServiceRegistry';

// Tutti i servizi
const { registry, loading, refresh } = useServiceRegistry();

// Solo frontend
const { frontends } = useFrontends();

// Solo backend
const { backends } = useBackends();
```

### 3. Service Navigator (`ServiceNavigator.tsx`)
Componente UI per navigare tra i servizi:
```tsx
import ServiceNavigator from '@/components/ServiceNavigator';

<ServiceNavigator
  onServiceSelect={(service) => {
    // Naviga al servizio
    router.push(`/service/${service.name}`);
  }}
/>
```

### 4. Dynamic Service Mount (`DynamicServiceMount.tsx`)
Componente per montare servizi in iframe con hot-reload:
```tsx
import DynamicServiceMount from '@/components/DynamicServiceMount';

// By name
<DynamicServiceMount serviceName="app-dam" />

// By port
<DynamicServiceMount servicePort={3300} />
```

## 🚀 Utilizzo

### Avvio Rapido

```bash
# Avvia l'orchestratore
./start-orchestrator.sh
```

L'orchestratore:
1. Installa le dipendenze necessarie (chokidar)
2. Crea il service-registry.json
3. Scopre tutti i servizi
4. Avvia i backend (porte 4000+)
5. Avvia i frontend (porte 3000+)
6. Attiva i watcher per hot-reload

### Monitoraggio

L'orchestratore mostra in tempo reale:
- ✅ Servizi attivi (pallino verde)
- ⏳ Servizi in avvio (pallino giallo)
- ❌ Servizi non raggiungibili (pallino rosso)
- ⏱️ Uptime di ogni servizio
- 🔄 Eventi di reload

### Service Registry

Il file `service-registry.json` viene aggiornato ogni 10 secondi:

```json
{
  "frontends": [
    {
      "name": "app-dam",
      "port": 3300,
      "type": "nextjs",
      "url": "http://localhost:3300",
      "status": "healthy",
      "uptime": 123456
    }
  ],
  "backends": [
    {
      "name": "svc-api-gateway",
      "port": 4000,
      "type": "express",
      "url": "http://localhost:4000",
      "status": "healthy",
      "uptime": 123456
    }
  ],
  "generated": "2025-10-15T10:30:00.000Z"
}
```

## 🔧 Configurazione

### Aggiungere un Nuovo Servizio

1. **Frontend**: Crea una cartella `app-{nome}` con:
   - `package.json` con script `dev`
   - Aggiungi a `SERVICE_DEFINITIONS.frontends` in `service-orchestrator.js`:
   ```javascript
   { name: 'app-{nome}', port: 3xxx, path: 'app-{nome}', type: 'nextjs' }
   ```

2. **Backend**: Crea una cartella `svc-{nome}` con:
   - `package.json` con script `dev`
   - Aggiungi a `SERVICE_DEFINITIONS.backends` in `service-orchestrator.js`:
   ```javascript
   { name: 'svc-{nome}', port: 4xxx, path: 'svc-{nome}', type: 'express' }
   ```

### Personalizzare i Watcher

In `service-orchestrator.js`, modifica `CONFIG.watchPatterns`:

```javascript
watchPatterns: [
  '**/src/**/*.{ts,tsx,js,jsx}',  // Codice sorgente
  '**/package.json',               // Dipendenze
  '**/.env*'                       // Variabili d'ambiente
]
```

### Personalizzare gli Intervalli

```javascript
CONFIG = {
  pollInterval: 5000,           // Polling generale (5s)
  restartDelay: 2000,           // Delay prima del restart (2s)
  healthCheckInterval: 10000,   // Health check (10s)
}
```

## 📱 Integrazione nella Shell

### 1. Aggiungere il ServiceNavigator alla Sidebar

```tsx
// app-shell-frontend/src/components/Sidebar.tsx
import ServiceNavigator from './ServiceNavigator';

export function Sidebar() {
  return (
    <aside>
      {/* ... menu esistente ... */}

      <div className="mt-auto">
        <ServiceNavigator
          onServiceSelect={(service) => {
            router.push(`/service/${service.name}`);
          }}
        />
      </div>
    </aside>
  );
}
```

### 2. Creare una Pagina per Ogni Servizio

```tsx
// app-shell-frontend/src/pages/service/[serviceId].tsx
import { useRouter } from 'next/router';
import DynamicServiceMount from '@/components/DynamicServiceMount';

export default function ServicePage() {
  const router = useRouter();
  const { serviceId } = router.query;

  return (
    <div className="h-screen">
      <DynamicServiceMount
        serviceName={serviceId as string}
        onLoad={() => console.log('Service loaded')}
        onError={(err) => console.error('Service error:', err)}
      />
    </div>
  );
}
```

### 3. Dashboard dei Servizi

```tsx
// app-shell-frontend/src/pages/services/index.tsx
import { useFrontends, useBackends } from '@/hooks/useServiceRegistry';

export default function ServicesPage() {
  const { frontends } = useFrontends();
  const { backends } = useBackends();

  return (
    <div className="grid grid-cols-2 gap-4 p-4">
      {frontends.map(service => (
        <div key={service.name} className="border rounded p-4">
          <h3>{service.name}</h3>
          <p>Status: {service.status}</p>
          <p>Port: {service.port}</p>
          <a href={`/service/${service.name}`}>Open →</a>
        </div>
      ))}
    </div>
  );
}
```

## 🔄 Flusso di Lavoro

### Sviluppo Normale

1. **Avvia l'orchestratore**:
   ```bash
   ./start-orchestrator.sh
   ```

2. **Modifica un file** in qualsiasi servizio

3. **Auto-reload**: L'orchestratore rileva il cambiamento e:
   - Ferma il servizio
   - Aspetta 2 secondi
   - Riavvia il servizio
   - Aggiorna il registry

4. **Shell auto-reload**: La shell rileva il nuovo registry e:
   - Aggiorna la lista dei servizi
   - Ricarica l'iframe se il servizio è montato

### Dopo un Riavvio del Sistema

1. **Avvia l'orchestratore**: `./start-orchestrator.sh`
2. **Tutto si riavvia automaticamente**:
   - Backend vengono avviati per primi
   - Frontend vengono avviati dopo
   - La shell si connette automaticamente

### Aggiungere un Nuovo Servizio

1. **Crea il servizio** (es. `app-nuovo`)
2. **Aggiungi a SERVICE_DEFINITIONS** in `service-orchestrator.js`
3. **Riavvia l'orchestratore**
4. **Il servizio appare automaticamente** nella shell

## 🐛 Troubleshooting

### Servizio non si avvia

1. Verifica che esista `package.json` con script `dev`
2. Controlla che la porta non sia già in uso: `lsof -i :PORT`
3. Verifica i log dell'orchestratore

### Servizio crashato

L'orchestratore tenta il **restart automatico** dopo 2 secondi. Se continua a crashare:
1. Controlla i log nel terminale dell'orchestratore
2. Verifica le dipendenze: `cd servizio && pnpm install`
3. Testa manualmente: `cd servizio && pnpm run dev`

### Hot-reload non funziona

1. Verifica che i pattern di watch siano corretti
2. Controlla che il file modificato non sia in `.gitignore`
3. Aumenta `CHOKIDAR_INTERVAL` se su filesystem lento

### Shell non vede i servizi

1. Verifica che `service-registry.json` esista nella root
2. Controlla che il file sia accessibile via HTTP
3. Verifica la console del browser per errori CORS

## 🎨 Personalizzazione UI

### Stile del ServiceNavigator

```tsx
<ServiceNavigator
  className="bg-gray-100 dark:bg-gray-900"
  onServiceSelect={(service) => {
    // Custom logic
  }}
/>
```

### Stile del DynamicServiceMount

```tsx
<DynamicServiceMount
  serviceName="app-dam"
  className="rounded-lg shadow-xl"
/>
```

## 📊 Metriche

L'orchestratore traccia:
- **Uptime**: Tempo di attività di ogni servizio
- **Restarts**: Numero di riavvii
- **Health Status**: Stato di salute (healthy/unhealthy/starting)
- **Response Time**: Tempo di risposta agli health check

## 🔐 Sicurezza

- I servizi girano su `localhost` (non esposti)
- Gli iframe usano `sandbox` con permessi limitati
- Il registry è read-only per i client
- CORS configurato per domini trusted

## 🚦 Stato dei Servizi

- 🟢 **Healthy**: Servizio attivo e funzionante
- 🟡 **Starting**: Servizio in fase di avvio
- 🟠 **Unhealthy**: Servizio attivo ma non risponde
- ⚪ **Unknown**: Stato non determinato
- 🔴 **Crashed**: Servizio terminato (auto-restart attivo)

## 📝 Best Practices

1. **Non committare `service-registry.json`**: È generato automaticamente
2. **Usa porte consistenti**: Frontend 3xxx, Backend 4xxx, Special 5xxx
3. **Implementa `/health` endpoint**: Per health check accurati
4. **Gestisci SIGTERM**: Per shutdown graceful
5. **Log strutturato**: Facilita il debug nell'orchestratore

## 🎯 Roadmap

- [ ] Clustering support (multi-instance)
- [ ] Load balancing tra istanze
- [ ] Metrics dashboard integrato
- [ ] Service dependencies management
- [ ] Auto-scaling basato su carico
- [ ] Remote orchestration (Docker Swarm/K8s)
