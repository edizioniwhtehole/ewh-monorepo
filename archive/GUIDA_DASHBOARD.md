# 🎛️ Dashboard EWH Mac Studio - Guida Completa

## 🚀 Setup Completato!

Hai sincronizzato **89 progetti** sul Mac Studio:
- ✅ 64 Services (svc-*)
- ✅ 25 Apps (app-*)

**Installazione dipendenze in corso...** (30-45 minuti)

---

## 📊 Stato Attuale

### Sul MacBook:
- ✅ Codice sorgente (96 progetti)
- ✅ Dashboard Manager (Python)
- ✅ Script di gestione

### Sul Mac Studio:
- ✅ 89 progetti sincronizzati
- ⏳ Dipendenze in installazione (background)
- ✅ PM2 configurato
- ✅ Node.js v20.18.0
- ✅ Port forwarding attivo

---

## 🎯 Come Usare il Dashboard

### 1. Avvia Dashboard

```bash
cd /Users/andromeda/dev/ewh
python3 ewh-manager.py
```

**Si apre automaticamente su:** http://localhost:9999

### 2. Interfaccia Dashboard

```
┌─────────────────────────────────────────────────┐
│ 🖥️ EWH Mac Studio Manager                      │
│ Services: 64 | Apps: 25 | Running: X           │
│ [▶️ Avvia Tutti] [⏸️ Ferma Tutti] [🔄 Aggiorna]│
└─────────────────────────────────────────────────┘

🔧 Services (64)
┌──────────────────────────────────────┐
│ Filtri: [Tutti] [Running] [Stopped] │
└──────────────────────────────────────┘

┌──────────────┬──────────────┬──────────────┐
│ svc-auth     │ svc-pm       │ svc-api-gw   │
│ ● Running    │ ○ Stopped    │ ● Running    │
│ CPU: 2%      │              │ CPU: 5%      │
│ RAM: 56MB    │              │ RAM: 61MB    │
│              │              │              │
│ [⏸️ Stop]    │ [▶️ Start]   │ [⏸️ Stop]    │
│ [🔄 Restart] │ [🔄 Restart] │ [🔄 Restart] │
└──────────────┴──────────────┴──────────────┘

... altri 61 servizi ...

📱 Apps (25)
... stessa struttura ...
```

### 3. Operazioni Disponibili

#### Per Singolo Progetto:
- **▶️ Start** - Avvia il servizio/app
- **⏸️ Stop** - Ferma il servizio/app
- **🔄 Restart** - Riavvia

#### Globali:
- **▶️ Avvia Tutti** - Avvia tutti gli 89 progetti (PESANTE!)
- **⏸️ Ferma Tutti** - Ferma tutto PM2
- **🔄 Aggiorna** - Refresh manuale

#### Filtri:
- **Tutti** - Mostra tutti i progetti
- **Running** - Solo quelli attivi
- **Stopped** - Solo quelli fermati

---

## 💡 Workflow Raccomandato

### Non Avviare Mai Tutti Insieme!

89 servizi contemporaneamente = **sistema inutilizzabile**

### Usa Profili:

#### Profilo "PM" (Project Management)
```
svc-auth
svc-api-gateway
svc-pm
app-pm-frontend
```

#### Profilo "DAM" (Digital Asset Management)
```
svc-auth
svc-api-gateway
svc-media
svc-dms
app-dam
```

#### Profilo "CMS"
```
svc-auth
svc-api-gateway
svc-cms
svc-page-builder
app-cms-frontend
```

### Come Usare:

1. **Apri Dashboard**
2. **Filtra "Stopped"**
3. **Avvia solo i 4-5 servizi del profilo che ti serve**
4. **Lavora su quella feature**
5. **Ferma quando hai finito**

---

## 📊 Monitoraggio

### Check Status Installazione

```bash
# Vedi quali hanno node_modules
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && for dir in svc-* app-*; do [ -d $dir/node_modules ] && echo "✅ $dir" || echo "⏳ $dir"; done | head -20'
```

### Vedi Servizi Attivi

```bash
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 list'
```

### Log Servizio Specifico

```bash
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 logs svc-pm'
```

---

## 🐛 Troubleshooting

### "Servizio non si avvia"

**Possibili cause:**
1. ⏳ Dipendenze ancora in installazione
   ```bash
   ssh fabio@192.168.1.47 'ls /Users/fabio/dev/ewh/NOME_SERVIZIO/node_modules'
   ```

2. ❌ Errore nel codice
   ```bash
   ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 logs NOME_SERVIZIO --err'
   ```

3. 🔌 Porta già in uso
   ```bash
   ssh fabio@192.168.1.47 'lsof -i :PORTA'
   ```

### "Dashboard non carica progetti"

```bash
# Verifica connessione Mac Studio
ssh fabio@192.168.1.47 echo "OK"

# Restart dashboard
pkill -f ewh-manager.py
python3 ewh-manager.py
```

### "Troppo lento"

**Hai troppi servizi attivi!**
```bash
# Ferma tutto
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 stop all'

# Riavvia solo necessari
```

---

## ⏱️ Timeline Setup

- ✅ **Fatto**: Sync progetti (5 min)
- ⏳ **In corso**: Install dipendenze (30-45 min)
- ⏳ **Prossimo**: Test avvio servizi (quando finisce install)

### Check Progress Installazione

```bash
# Conta quanti hanno node_modules
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && ls -d */node_modules 2>/dev/null | wc -l'

# Totale: 89
# Quando arriva a ~85-89 = installazione completa
```

---

## 🎉 Quando Installazione Finisce

1. **Refresh Dashboard** (si auto-aggiorna ogni 5s)
2. **Testa con profilo piccolo**:
   - Click su svc-auth → Start
   - Click su svc-api-gateway → Start
   - Click su svc-pm → Start
   - Click su app-pm-frontend → Start
3. **Apri** http://localhost:5400
4. **Verifica funziona**

---

## 📚 File Utili

- **Dashboard**: `python3 ewh-manager.py`
- **Sync**: `./sync-all-to-mac-studio.sh`
- **Install**: `./install-dependencies-fast.sh`
- **Stop tutto**: `ssh fabio@192.168.1.47 'pm2 stop all'`

---

## 💾 Backup Raccomandato

Una volta che tutto funziona:

```bash
# Sul Mac Studio, crea snapshot
ssh fabio@192.168.1.47 'cd /Users/fabio && tar -czf ewh-backup-$(date +%Y%m%d).tar.gz dev/ewh'
```

---

**Dashboard è già attivo! Guardalo mentre si installano le dipendenze!** 🚀

Tra 30-45 minuti tutto sarà pronto per essere usato! ⏰
