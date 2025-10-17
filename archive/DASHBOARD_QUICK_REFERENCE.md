# 📊 Dashboard - Quick Reference

## Accesso Rapido

**URL**: http://localhost:8080

**Start Server**:
```bash
cd /Users/andromeda/dev/ewh
python3 dashboard-server.py
```

---

## 🎯 Layout Dashboard v2

```
┌───────────────────────────────────────────────────┐
│  🚀 EWH Dashboard v2                              │
│  🖥️ CPU: 45% | 💾 RAM: 8.2GB | 💿 Disk: 67%      │
│  [▶️ Start Selected] [⏹️ Stop] [☑️ Select All]    │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│  ⭐ INDISPENSABILI               [▶️ Avvia Tutti] │
│  ┌─────────────────────────────────────────────┐ │
│  │ Trascina qui i servizi core...              │ │
│  │                                              │ │
│  │ ┌─────────────┐ ┌─────────────┐            │ │
│  │ │ svc-auth    │ │ svc-gateway │            │ │
│  │ │ ON 🔥 2%    │ │ ON 🔥 5%    │  [❌]       │ │
│  │ └─────────────┘ └─────────────┘            │ │
│  └─────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│  📦 TUTTI I SERVIZI              [🔄 Rileva Nuovi]│
│                                                    │
│  ┌──────────────┬──────────────┐                 │
│  │  Backend     │  Frontend    │  (coppia 1)     │
│  ├──────────────┼──────────────┤                 │
│  │ svc-pm       │ app-pm-      │                 │
│  │ ON 🔥 8%     │ frontend     │                 │
│  │ 💾 234MB     │ ON 🔥 12%    │                 │
│  │ 🌐 :5500     │ 💾 456MB     │                 │
│  │ [⏹️][🔄][📋] │ 🌐 :5400     │                 │
│  │              │ [⏹️][🔄][📋]  │                 │
│  └──────────────┴──────────────┘                 │
│                                                    │
│  ┌──────────────┬──────────────┐                 │
│  │  Backend     │  Frontend    │  (coppia 2)     │
│  ├──────────────┼──────────────┤                 │
│  │ svc-dam      │ app-dam      │                 │
│  │ OFF          │ OFF          │                 │
│  │ [▶️][📋]     │ [▶️][📋]      │                 │
│  └──────────────┴──────────────┘                 │
│                                                    │
│  ... (altre coppie) ...                           │
└───────────────────────────────────────────────────┘
```

---

## 🎬 Azioni Rapide

### Avvio Servizi Essenziali

1. Apri http://localhost:8080
2. Sezione "⭐ INDISPENSABILI"
3. Click "▶️ Avvia Tutti"

**Servizi consigliati per "Indispensabili"**:
- `svc-auth` (autenticazione)
- `svc-api-gateway` (routing)
- `svc-pm` (project management backend)
- `app-pm-frontend` (UI project management)
- `app-admin-frontend` (pannello admin)

### Multi-Select e Avvio Batch

1. Click checkbox su ogni servizio desiderato
2. Oppure click su card body (area fuori dai bottoni)
3. Header: "▶️ Start Selected"

### Drag & Drop Essenziali

1. Trova servizio in "📦 Tutti i Servizi"
2. Drag card verso sezione "⭐ Indispensabili"
3. Drop nella dropzone
4. Configurazione salvata automaticamente in localStorage

### Debug con Logs

1. Click "📋 Logs" su servizio
2. Modal mostra ultimi 100 righe
3. Output in formato console

### Apri in Browser

1. Assicurati servizio sia ON
2. Click "🌐 Apri"
3. Si apre a http://192.168.1.47:PORT

---

## 🔧 Configurazione Porte

**File**: `dashboard-v2.html`

**Linea**: ~272-286

```javascript
const PORTS = {
    'svc-auth': 4001,
    'svc-api-gateway': 4000,
    'svc-pm': 5500,
    'app-pm-frontend': 5400,
    'app-dam': 5100,
    'app-cms-frontend': 5200,
    'app-admin-frontend': 3200,
    'svc-media': 4003,
    'svc-boards': 4010,
    'svc-bi': 4011,
    'svc-projects': 4012,
    'app-web-frontend': 3100,
    'app-shell-frontend': 3000,
    'svc-dms': 4013,
    'svc-crm': 4014,
    // Aggiungi nuovi servizi qui
};
```

**Per aggiungere nuovo servizio**:
1. Edit `dashboard-v2.html`
2. Aggiungi riga in `PORTS` object
3. Riavvia server: `pkill -f dashboard-server.py && python3 dashboard-server.py`
4. Refresh browser
5. Click "🔄 Rileva Nuovi" in dashboard

---

## 📡 Auto-Discovery

**Funzionamento automatico**:
- Scansiona tutte le cartelle `app-*` e `svc-*`
- Click "🔄 Rileva Nuovi" per refresh manuale
- Accoppiamento automatico: `app-X-frontend` ↔ `svc-X`
- Servizi senza coppia mostrati singolarmente

**Esempio accoppiamento**:
```
app-pm-frontend  ↔  svc-pm        ✅ Accoppiato
app-dam          ↔  svc-media     ❌ Non accoppiato (nomi diversi)
app-admin        ↔  (nessuno)     ⚠️  Solo frontend
(nessuno)        ↔  svc-auth      ⚠️  Solo backend
```

---

## 🎨 Stati Visivi

### Card Status Colors

```
┌────────────┐
│░░░░░░░░░░░░│ Grigio = OFFLINE
│  Servizio  │
│ [▶️ Start] │
└────────────┘

┌────────────┐
│▌           │ Verde = ONLINE
│▌ Servizio  │
│▌[⏹️][🔄][📋]│
└────────────┘

┌────────────┐
│▌           │ Rosso = ERROR
│▌ Servizio  │
│▌[▶️][📋]   │
└────────────┘
```

### Badge Status

- 🟢 **ON** = Online
- 🔴 **ERR** = Error
- ⚪ **OFF** = Stopped

### Selection State

```
┌────────────┐         ┌────────────┐
│ ☐ Normal   │   →     │ ☑️ Selected │
│            │  click  │ (blue bg)  │
└────────────┘         └────────────┘
```

---

## 🚀 Workflow Tipico

### Mattina - Setup

```bash
# 1. Start Mutagen (se non già attivo)
mutagen daemon start

# 2. Check sync
mutagen sync list

# 3. Start dashboard
python3 dashboard-server.py

# 4. Open browser
open http://localhost:8080

# 5. Avvia essenziali
Click "⭐ INDISPENSABILI" → "▶️ Avvia Tutti"
```

### Durante Sviluppo

```bash
# 1. Edit code su MacBook
code app-pm-frontend/src/pages/Dashboard.tsx

# 2. Mutagen sincronizza automaticamente (< 3s)
# (nessuna azione richiesta)

# 3. Hot reload automatico su Mac Studio
# (nessuna azione richiesta)

# 4. Verifica in browser
open http://192.168.1.47:5400

# 5. Se servizio ha problemi:
# Dashboard → Click "📋 Logs" sul servizio
```

### Debug Servizio

```bash
# Via Dashboard:
1. Find service card
2. Check status badge (ON/OFF/ERR)
3. Click "📋 Logs"
4. Modal shows last 100 lines
5. If needed, click "🔄 Restart"

# Via Terminal (alternative):
studio "pm2 logs svc-pm --lines 100"
studio "pm2 restart svc-pm"
```

### Aggiungere Nuovo Servizio

```bash
# 1. Create folder
mkdir svc-newservice
cd svc-newservice
npm init -y

# 2. Mutagen syncs automatically

# 3. Dashboard auto-discovery
Open http://localhost:8080
Click "🔄 Rileva Nuovi"

# 4. Service appears in list
Click "▶️ Start" on service card

# 5. (Optional) Add to essentials
Drag card to "⭐ INDISPENSABILI"

# 6. (Optional) Add port mapping
Edit dashboard-v2.html → PORTS object
Restart server
```

---

## 🐛 Troubleshooting Dashboard

### Dashboard non carica

```bash
# Check server
lsof -nP -iTCP:8080 | grep LISTEN

# Restart
pkill -f dashboard-server.py
python3 dashboard-server.py

# Open
open http://localhost:8080
```

### Servizi non appaiono

```bash
# Check SSH connection
ssh mac-studio "echo ok"

# Check PM2 su Mac Studio
studio "pm2 list"

# Force refresh dashboard
Click "🔄 Rileva Nuovi"
```

### Comando timeout

```bash
# Check SSH config
cat ~/.ssh/config | grep mac-studio

# Test connection
ssh -v mac-studio "pwd"

# Check Mutagen
mutagen sync list
```

### "Apri" non funziona

```bash
# 1. Check if service is ON in dashboard
# 2. Check if port mapped in PORTS object
# 3. Check network config:

cat app-pm-frontend/vite.config.ts | grep host

# Should show:
# host: '0.0.0.0'

# If missing, add it:
server: {
  host: '0.0.0.0',
  port: 5400
}
```

---

## 💾 Persistenza

### LocalStorage

**Chiave**: `ewh_essentials`

**Formato**: `["svc-auth", "svc-api-gateway", ...]`

**Location**: Browser localStorage

**Reset**:
```javascript
// In browser console:
localStorage.removeItem('ewh_essentials');
location.reload();
```

---

## 📈 Performance

- **Service refresh**: Ogni 5 secondi
- **Telemetry refresh**: Ogni 3 secondi
- **Auto-discovery**: On-demand (click "🔄 Rileva Nuovi")
- **Sync latency**: < 3 secondi (Mutagen)
- **Dashboard load**: < 1 secondo

---

## 🔐 Note Sicurezza

- Dashboard **NO auth** (solo localhost)
- SSH keys passwordless (macOS Keychain)
- Network access (0.0.0.0) solo su LAN
- Production usa security boundaries

---

## 📝 Checklist Pre-Deploy

Prima di deployare su staging/production:

- [ ] Tutti i servizi essenziali configurati in dashboard
- [ ] Port mappings aggiornati in `PORTS` object
- [ ] Vite configs hanno `host: '0.0.0.0'`
- [ ] Mutagen sync attivo e senza conflitti
- [ ] PM2 processes senza duplicati
- [ ] Logs verificati per errori critici
- [ ] Mac Studio telemetry entro limiti (CPU < 80%, RAM disponibile)

---

**Last Updated**: 2025-10-14
**Dashboard Version**: v2
**Server Port**: 8080
**Remote Host**: 192.168.1.47
