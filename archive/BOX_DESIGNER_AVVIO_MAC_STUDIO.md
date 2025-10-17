# Box Designer - Avvio su Mac Studio (Senza Docker)

**Data**: 2025-10-15
**Environment**: Mac Studio - Sviluppo locale senza Docker

---

## Setup Iniziale (Una Volta)

### 1. Database Migration

```bash
# Applica migration al database PostgreSQL
psql -U ewh -d ewh_platform -f /Users/andromeda/dev/ewh/migrations/080_box_designer_system.sql

# Verifica tabelle create
psql -U ewh -d ewh_platform -c "\dt box_*"
```

**Output atteso**:
```
              List of relations
 Schema |         Name          | Type  | Owner
--------+-----------------------+-------+-------
 public | box_design_metrics    | table | ewh
 public | box_export_jobs       | table | ewh
 public | box_machines          | table | ewh
 public | box_orders            | table | ewh
 public | box_project_versions  | table | ewh
 public | box_projects          | table | ewh
 public | box_quotes            | table | ewh
 public | box_templates         | table | ewh
```

### 2. Installa Dipendenze

**Backend**:
```bash
cd /Users/andromeda/dev/ewh/svc-box-designer
npm install
```

**Frontend**:
```bash
cd /Users/andromeda/dev/ewh/app-box-designer
npm install
```

---

## Avvio Servizi

### Terminal 1: Backend API

```bash
cd /Users/andromeda/dev/ewh/svc-box-designer

# Imposta variabili ambiente
export PORT=5850
export NODE_ENV=development
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ewh_platform
export DB_USER=ewh
export DB_PASSWORD=ewhpass
export JWT_SECRET=dev-secret-key

# Avvia backend
npm run dev
```

**Output atteso**:
```
╔═══════════════════════════════════════════════════════════════╗
║                                                                 ║
║   📦  BOX DESIGNER SERVICE                                     ║
║                                                                 ║
║   Status: Running                                              ║
║   Port: 5850                                                   ║
║   Environment: development                                     ║
║   Database: localhost:5432                                     ║
║                                                                 ║
║   Endpoints:                                                   ║
║   - Health Check: http://localhost:5850/health                ║
║   - Projects API: http://localhost:5850/api/box/projects      ║
║                                                                 ║
╚═══════════════════════════════════════════════════════════════╝
```

### Terminal 2: Frontend React

```bash
cd /Users/andromeda/dev/ewh/app-box-designer

# Imposta variabili ambiente
export PORT=3350
export VITE_API_BASE_URL=/api/box
export VITE_BACKEND_URL=http://localhost:5850

# Avvia frontend
npm run dev
```

**Output atteso**:
```
  VITE v5.0.11  ready in 234 ms

  ➜  Local:   http://localhost:3350/
  ➜  Network: http://192.168.1.100:3350/
  ➜  press h + enter to show help
```

---

## Verifica Funzionamento

### 1. Health Check Backend

```bash
curl http://localhost:5850/health
```

**Risposta attesa**:
```json
{
  "service": "svc-box-designer",
  "status": "healthy",
  "timestamp": "2025-10-15T10:00:00.000Z",
  "uptime": 12.345,
  "database": "connected"
}
```

### 2. Test Frontend

Apri browser: **http://localhost:3350**

Dovresti vedere l'interfaccia del Box Designer con:
- Box configurator (parametri)
- 3D viewer (Three.js)
- Die-line viewer (2D)

### 3. Test API con Token

```bash
# Login per ottenere token (usa il tuo auth service)
TOKEN="your-jwt-token-here"

# Oppure usa un token di test
TOKEN="dev-token-for-testing"

# Test API - List projects
curl http://localhost:5850/api/box/projects \
  -H "Authorization: Bearer $TOKEN"

# Test API - Create project
curl -X POST http://localhost:5850/api/box/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Box Mac Studio",
    "box_config": {
      "style": "fefco_0201",
      "dimensions": {
        "length": 400,
        "width": 300,
        "height": 200
      },
      "material": {
        "type": "corrugated_e_flute",
        "thickness": 3
      }
    }
  }'
```

---

## Seed FEFCO Templates (Opzionale)

Carica i 10 template FEFCO standard:

```bash
# Serve un token admin
curl -X POST http://localhost:5850/api/box/templates/seed \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Risposta attesa**:
```json
{
  "message": "Templates seeded successfully",
  "count": 10
}
```

---

## Script di Avvio Rapido

Crea uno script per avviare tutto insieme:

### File: `/Users/andromeda/dev/ewh/start-box-designer.sh`

```bash
#!/bin/bash

# Box Designer Startup Script per Mac Studio
# Usage: ./start-box-designer.sh

echo "🚀 Starting Box Designer..."

# Colori per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory root
EWH_ROOT="/Users/andromeda/dev/ewh"

# Verifica database
echo -e "${BLUE}Checking database...${NC}"
psql -U ewh -d ewh_platform -c "SELECT COUNT(*) FROM box_projects;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "⚠️  Database tables not found. Running migration..."
  psql -U ewh -d ewh_platform -f "$EWH_ROOT/migrations/080_box_designer_system.sql"
  echo -e "${GREEN}✅ Migration complete${NC}"
fi

# Funzione per avviare servizio in background
start_service() {
  local name=$1
  local dir=$2
  local port=$3
  local logfile="/tmp/ewh-$name.log"

  echo -e "${BLUE}Starting $name on port $port...${NC}"

  cd "$EWH_ROOT/$dir"

  if [ "$name" = "backend" ]; then
    # Backend
    export PORT=5850
    export NODE_ENV=development
    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_NAME=ewh_platform
    export DB_USER=ewh
    export DB_PASSWORD=ewhpass
    export JWT_SECRET=dev-secret-key

    npm run dev > "$logfile" 2>&1 &
    echo $! > "/tmp/ewh-$name.pid"
  else
    # Frontend
    export PORT=3350
    export VITE_API_BASE_URL=/api/box
    export VITE_BACKEND_URL=http://localhost:5850

    npm run dev > "$logfile" 2>&1 &
    echo $! > "/tmp/ewh-$name.pid"
  fi

  echo -e "${GREEN}✅ $name started (PID: $(cat /tmp/ewh-$name.pid))${NC}"
  echo "   Logs: $logfile"
}

# Avvia backend
start_service "backend" "svc-box-designer" 5850

# Aspetta che backend sia pronto
echo "⏳ Waiting for backend to be ready..."
for i in {1..30}; do
  curl -s http://localhost:5850/health > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend ready${NC}"
    break
  fi
  sleep 1
done

# Avvia frontend
start_service "frontend" "app-box-designer" 3350

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                            ║${NC}"
echo -e "${GREEN}║   📦  Box Designer Started Successfully   ║${NC}"
echo -e "${GREEN}║                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "🌐 Frontend: http://localhost:3350"
echo "🔧 Backend:  http://localhost:5850"
echo "❤️  Health:   http://localhost:5850/health"
echo ""
echo "📋 Logs:"
echo "   Backend:  tail -f /tmp/ewh-backend.log"
echo "   Frontend: tail -f /tmp/ewh-frontend.log"
echo ""
echo "🛑 To stop: ./stop-box-designer.sh"
```

### File: `/Users/andromeda/dev/ewh/stop-box-designer.sh`

```bash
#!/bin/bash

# Box Designer Stop Script per Mac Studio
# Usage: ./stop-box-designer.sh

echo "🛑 Stopping Box Designer..."

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

stop_service() {
  local name=$1
  local pidfile="/tmp/ewh-$name.pid"

  if [ -f "$pidfile" ]; then
    local pid=$(cat "$pidfile")
    echo -e "Stopping $name (PID: $pid)..."
    kill $pid 2>/dev/null
    rm "$pidfile"
    echo -e "${GREEN}✅ $name stopped${NC}"
  else
    echo -e "${RED}⚠️  $name not running${NC}"
  fi
}

stop_service "backend"
stop_service "frontend"

echo -e "${GREEN}✅ Box Designer stopped${NC}"
```

### Rendi eseguibili

```bash
chmod +x /Users/andromeda/dev/ewh/start-box-designer.sh
chmod +x /Users/andromeda/dev/ewh/stop-box-designer.sh
```

---

## Utilizzo Script

### Avvio

```bash
cd /Users/andromeda/dev/ewh
./start-box-designer.sh
```

### Verifica Logs

```bash
# Backend logs
tail -f /tmp/ewh-backend.log

# Frontend logs
tail -f /tmp/ewh-frontend.log
```

### Stop

```bash
cd /Users/andromeda/dev/ewh
./stop-box-designer.sh
```

---

## Integrazione con Dashboard Mac Studio

Se hai il tuo dashboard HTML, puoi aggiungere:

```html
<!-- Box Designer Section -->
<div class="service-card">
  <h3>📦 Box Designer</h3>
  <div class="status" id="box-designer-status">Checking...</div>
  <div class="actions">
    <button onclick="startBoxDesigner()">Start</button>
    <button onclick="stopBoxDesigner()">Stop</button>
    <button onclick="openBoxDesigner()">Open</button>
  </div>
</div>

<script>
// Check status
async function checkBoxDesignerStatus() {
  try {
    const response = await fetch('http://localhost:5850/health');
    const data = await response.json();
    document.getElementById('box-designer-status').textContent =
      data.status === 'healthy' ? '🟢 Running' : '🔴 Down';
  } catch (e) {
    document.getElementById('box-designer-status').textContent = '🔴 Down';
  }
}

function startBoxDesigner() {
  // Esegui via Node.js child_process o SSH
  fetch('/api/services/start', {
    method: 'POST',
    body: JSON.stringify({ service: 'box-designer' })
  });
}

function stopBoxDesigner() {
  fetch('/api/services/stop', {
    method: 'POST',
    body: JSON.stringify({ service: 'box-designer' })
  });
}

function openBoxDesigner() {
  window.open('http://localhost:3350', '_blank');
}

// Check every 5 seconds
setInterval(checkBoxDesignerStatus, 5000);
checkBoxDesignerStatus();
</script>
```

---

## Troubleshooting

### Problema: Backend non parte

**Verifica PostgreSQL**:
```bash
psql -U ewh -d ewh_platform -c "SELECT 1;"
```

Se fallisce:
```bash
# Verifica che PostgreSQL sia avviato
pg_ctl status

# Avvia se necessario
pg_ctl start
```

### Problema: Porta 5850 già occupata

**Trova processo**:
```bash
lsof -i :5850
```

**Kill processo**:
```bash
kill -9 <PID>
```

### Problema: Frontend non si connette al backend

**Verifica proxy Vite**: Dovrebbe essere automatico, ma puoi testare:
```bash
# Test diretto backend
curl http://localhost:5850/health

# Test tramite frontend (dovrebbe fallire con CORS)
curl http://localhost:3350/api/box/health
```

**Fix**: Il proxy Vite è già configurato in `vite.config.ts`:
```typescript
proxy: {
  '/api/box': {
    target: 'http://localhost:5850',
    changeOrigin: true,
  },
}
```

### Problema: Database migration fallisce

**Reset completo** (ATTENZIONE: cancella dati):
```bash
# Drop tabelle
psql -U ewh -d ewh_platform -c "DROP TABLE IF EXISTS box_projects CASCADE;"
psql -U ewh -d ewh_platform -c "DROP TABLE IF EXISTS box_quotes CASCADE;"
psql -U ewh -d ewh_platform -c "DROP TABLE IF EXISTS box_orders CASCADE;"
# ... etc per tutte le tabelle

# Re-apply migration
psql -U ewh -d ewh_platform -f migrations/080_box_designer_system.sql
```

---

## Monitoring

### Health Check Loop

```bash
# Monitor backend health
watch -n 5 'curl -s http://localhost:5850/health | jq'
```

### Process Monitor

```bash
# Check se processi sono attivi
ps aux | grep -E "(svc-box-designer|app-box-designer)" | grep -v grep
```

### Log Monitoring

```bash
# Monitor entrambi i logs
tail -f /tmp/ewh-backend.log /tmp/ewh-frontend.log
```

---

## Performance Tips

### 1. Hot Reload Veloce

Vite è già ottimizzato, ma puoi ridurre il polling:

**File**: `app-box-designer/vite.config.ts`
```typescript
server: {
  watch: {
    usePolling: false, // Usa eventi FS nativi (più veloce)
  }
}
```

### 2. Backend Watch Mode

Il backend usa `nodemon` o `ts-node-dev` per hot reload automatico.

### 3. Database Connection Pool

Già configurato in `svc-box-designer/src/db/pool.ts`:
```typescript
const pool = new Pool({
  max: 20, // Max connessioni
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

---

## Next Steps

1. ✅ **Avvia servizi** con `./start-box-designer.sh`
2. ✅ **Apri browser** su http://localhost:3350
3. ✅ **Testa API** con curl
4. ✅ **Seed templates** (opzionale)
5. 🚀 **Inizia a usare il Box Designer!**

---

## Quick Reference

| Comando | Descrizione |
|---------|-------------|
| `./start-box-designer.sh` | Avvia tutto |
| `./stop-box-designer.sh` | Ferma tutto |
| `tail -f /tmp/ewh-backend.log` | Backend logs |
| `tail -f /tmp/ewh-frontend.log` | Frontend logs |
| `curl http://localhost:5850/health` | Health check |
| `psql -U ewh -d ewh_platform` | Database access |

---

**Tutto pronto per l'avvio su Mac Studio senza Docker!** 🚀
