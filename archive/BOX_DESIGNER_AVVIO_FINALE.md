# Box Designer - Guida Avvio Mac Studio ✅

**Ambiente**: Mac Studio (senza Docker)
**Status**: Già configurato nell'orchestratore!

---

## ⚡ Avvio Veloce (Consigliato)

Il Box Designer è **già configurato** nel tuo `service-orchestrator.js`!

### Opzione 1: Usa l'Orchestrator (Migliore)

```bash
cd /Users/andromeda/dev/ewh

# Avvia tutti i servizi (include Box Designer)
node service-orchestrator.js
```

L'orchestrator avvierà automaticamente:
- ✅ `svc-box-designer` sulla porta **5850** (backend)
- ✅ `app-box-designer` sulla porta **3350** (frontend)
- ✅ + tutti gli altri servizi configurati

**Vantaggi**:
- 🔄 Auto-restart su file change
- 📊 Health checks automatici
- 📈 Dashboard status real-time
- 🎯 File watchers per hot-reload
- 📝 Service registry JSON generato

---

## 🎛️ Avvio Standalone

Se vuoi avviare **solo** il Box Designer senza altri servizi:

```bash
cd /Users/andromeda/dev/ewh

# Avvio
./start-box-designer-simple.sh

# Stop
./stop-box-designer-simple.sh
```

---

## 📋 Setup Database (Solo Prima Volta)

```bash
# Applica migration
psql -U ewh -d ewh_platform -f /Users/andromeda/dev/ewh/migrations/080_box_designer_system.sql

# Verifica
psql -U ewh -d ewh_platform -c "\dt box_*"
```

**Output atteso**: 8 tabelle (box_projects, box_quotes, box_orders, etc.)

---

## 🧪 Test Funzionamento

### 1. Health Check

```bash
curl http://localhost:5850/health
```

**Risposta attesa**:
```json
{
  "service": "svc-box-designer",
  "status": "healthy",
  "database": "connected"
}
```

### 2. Apri Frontend

Browser: **http://localhost:3350**

Dovresti vedere:
- Box configurator (parametri)
- 3D viewer (Three.js)
- Die-line viewer (2D)

### 3. Test API

```bash
# Ottieni token (sostituisci con il tuo metodo auth)
TOKEN="your-jwt-token"

# List projects
curl http://localhost:5850/api/box/projects \
  -H "Authorization: Bearer $TOKEN"

# Create project
curl -X POST http://localhost:5850/api/box/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Box",
    "box_config": {
      "style": "fefco_0201",
      "dimensions": {"length": 400, "width": 300, "height": 200},
      "material": {"type": "corrugated_e_flute", "thickness": 3}
    }
  }'
```

---

## 📊 Configurazione Orchestrator

Il Box Designer è già definito in `service-orchestrator.js`:

**Riga 44** - Frontend:
```javascript
{ name: 'app-box-designer', port: 3350, path: 'app-box-designer', type: 'vite' }
```

**Riga 55** - Backend:
```javascript
{ name: 'svc-box-designer', port: 5850, path: 'svc-box-designer', type: 'express' }
```

---

## 🔍 Monitoring

### Con Orchestrator

L'orchestrator mostra status automatico ogni 5 secondi:

```
═══════════════════════════════════════════════════════════════
            EWH Service Orchestrator - Status
═══════════════════════════════════════════════════════════════

Frontends:
  ● app-box-designer              :3350  (45s)

Backends:
  ● svc-box-designer              :5850  (48s)

Commands: [r]estart all | [q]uit | [s]tatus
═══════════════════════════════════════════════════════════════
```

### Standalone

```bash
# View logs
tail -f /tmp/box-designer-backend.log
tail -f /tmp/box-designer-frontend.log

# Check process
ps aux | grep -E "(svc-box-designer|app-box-designer)" | grep -v grep

# Health check loop
watch -n 5 'curl -s http://localhost:5850/health | jq'
```

---

## 🎯 Porte Servizi

| Servizio | Porta | Tipo | Comando |
|----------|-------|------|---------|
| app-box-designer | 3350 | Vite/React | `pnpm run dev` |
| svc-box-designer | 5850 | Express/Node | `pnpm run dev` |
| PostgreSQL | 5432 | Database | - |

---

## 🛠️ Troubleshooting

### Porta occupata

```bash
# Check port
lsof -i :5850  # backend
lsof -i :3350  # frontend

# Kill if needed
lsof -ti:5850 | xargs kill -9
lsof -ti:3350 | xargs kill -9
```

### Database non risponde

```bash
# Check PostgreSQL status
pg_ctl status

# Restart se necessario
pg_ctl restart
```

### Dipendenze mancanti

```bash
# Backend
cd /Users/andromeda/dev/ewh/svc-box-designer
pnpm install

# Frontend
cd /Users/andromeda/dev/ewh/app-box-designer
pnpm install
```

### Logs errori

```bash
# Backend logs
cat /tmp/box-designer-backend.log

# Frontend logs
cat /tmp/box-designer-frontend.log

# O se usi orchestrator
# Logs sono mostrati in console real-time
```

---

## 🚀 Seed Template FEFCO (Opzionale)

Carica 10 template standard:

```bash
# Serve token admin
curl -X POST http://localhost:5850/api/box/templates/seed \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

Templates caricati:
1. FEFCO 0201 - Regular Slotted Container (3 size)
2. FEFCO STE - Straight Tuck End (2 size)
3. FEFCO RTE - Reverse Tuck End
4. Food Box - Gable Top
5. Gift Box - Auto-lock
6. Archive Box
7. E-commerce Mailer

---

## 📖 Accesso dalla Shell EWH

Quando avvii la Shell (app-shell-frontend), trovi il Box Designer in:

### Menu Design
- **Box Designer** → http://localhost:3350
- **Box Templates** → http://localhost:3350/templates

### Menu Business
- **Box Quotes** → http://localhost:3350/quotes
- **Box Production** → http://localhost:3350/orders
- **Box Analytics** → http://localhost:3350/analytics

### Settings
- **Box Designer Settings** → http://localhost:3350/settings

*(Configurato in `app-shell-frontend/src/lib/services.config.ts`)*

---

## 📚 Documentazione Completa

- **BOX_DESIGNER_COMPLETATO.md** - Riepilogo completo sistema
- **BOX_DESIGNER_INTEGRATION_COMPLETE.md** - Integrazione frontend/backend
- **BOX_DESIGNER_QUICK_START.md** - Quick start guide
- **BOX_DESIGNER_ENTERPRISE_READY.md** - Overview enterprise
- **svc-box-designer/README.md** - API reference backend

---

## ✅ Checklist Avvio

- [ ] Database migration applicata
- [ ] Backend risponde su http://localhost:5850/health
- [ ] Frontend accessibile su http://localhost:3350
- [ ] API projects funziona (con JWT token)
- [ ] 3D viewer mostra box
- [ ] Templates seed caricate (opzionale)
- [ ] Integrato nella Shell (opzionale)

---

## 🎉 Tutto Pronto!

Il Box Designer è completamente integrato nel tuo ecosistema EWH:

✅ Backend microservice enterprise (6.900+ LOC)
✅ Frontend React + Three.js (2.000+ LOC API)
✅ 45 API endpoint
✅ Database multi-tenant
✅ Orchestrator configurato
✅ Hot-reload automatico
✅ Health checks
✅ Service registry

**Usa l'orchestrator per il miglior workflow!** 🚀

```bash
node service-orchestrator.js
```

**Fatto!** 🎊
