# 🎯 Guida Uso Quotidiano - Mac Studio Setup

## Setup Completato ✅

- **MacBook**: 192.168.1.23 (questa macchina)
- **Mac Studio**: fabio@192.168.1.47
- **SSH**: Configurato e funzionante

---

## 🚀 Workflow Quotidiano

### Mattina - Avvio Sviluppo

```bash
# Terminal 1: Deploy e avvia servizi sul Mac Studio
cd /Users/andromeda/dev/ewh
./scripts/deploy-to-mac-studio.sh pm

# Aspetta che finisca (2-3 minuti la prima volta, poi istantaneo)
```

```bash
# Terminal 2: Sync automatico (in un nuovo terminale)
cd /Users/andromeda/dev/ewh
./scripts/watch-and-sync-mac-studio.sh

# Lascia questo terminale aperto!
# Ogni volta che salvi un file, verrà sincronizzato automaticamente
```

### Durante il Giorno - Lavora Normalmente

1. **Apri VS Code sul MacBook**
   ```bash
   code /Users/andromeda/dev/ewh
   ```

2. **Edita file normalmente**
   - Salvi un file
   - Watch & Sync lo trasferisce automaticamente (1-2 secondi)
   - Hot reload sul Mac Studio
   - Servizi si aggiornano

3. **Accedi ai servizi dal browser del MacBook**
   - 🏠 Shell: http://localhost:3001
   - 🔐 Auth: http://localhost:3000
   - 🌐 Gateway: http://localhost:8080
   - 📋 PM: http://localhost:5400

   **Tutto gira sul Mac Studio, ma accedi come fosse locale!**

### Sera - Stop Sviluppo

```bash
# Stop tutto
./scripts/stop-mac-studio-dev.sh

# Ti chiederà se fermare anche i servizi sul Mac Studio
# Rispondi 'y' per fermare tutto
```

---

## 🔧 Comandi Utili

### Gestione Servizi Remoti

```bash
# Vedi status servizi sul Mac Studio
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 list'

# Vedi log di tutti i servizi
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 logs'

# Vedi log di un servizio specifico
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 logs svc-pm'

# Restart un servizio
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 restart svc-pm'

# Restart tutti i servizi
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 restart all'

# Stop tutti i servizi
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 stop all'

# Rimuovi tutti i servizi da PM2
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 delete all'
```

### Profili Disponibili

```bash
# Avvia solo PM (Project Management)
./scripts/deploy-to-mac-studio.sh pm

# Avvia DAM (Digital Asset Management)
./scripts/deploy-to-mac-studio.sh dam

# Avvia CMS
./scripts/deploy-to-mac-studio.sh cms

# Avvia Admin
./scripts/deploy-to-mac-studio.sh admin

# Avvia minimal (solo auth e gateway)
./scripts/deploy-to-mac-studio.sh minimal
```

### Sync Manuale (se serve)

```bash
# Sync singolo (senza watch continuo)
rsync -avz --exclude 'node_modules' --exclude '.git' \
  /Users/andromeda/dev/ewh/ \
  fabio@192.168.1.47:/Users/fabio/dev/ewh/
```

### Accesso Diretto Mac Studio

```bash
# SSH nel Mac Studio
ssh fabio@192.168.1.47

# Poi puoi eseguire comandi direttamente:
cd /Users/fabio/dev/ewh
npx pm2 list
npx pm2 logs
```

---

## 🐛 Troubleshooting

### "Cannot connect" sul browser

```bash
# 1. Verifica che port forward sia attivo
lsof -i :3001

# 2. Se non c'è output, riavvia deploy
./scripts/stop-mac-studio-dev.sh
./scripts/deploy-to-mac-studio.sh pm
```

### "Sync non funziona"

```bash
# 1. Verifica che watch sia attivo
ps aux | grep fswatch

# 2. Se non c'è, riavvia sync
./scripts/watch-and-sync-mac-studio.sh
```

### "Servizi non partono sul Mac Studio"

```bash
# 1. Verifica log sul Mac Studio
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 logs'

# 2. Restart manualmente un servizio
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh/svc-pm && npm install && npx pm2 restart svc-pm'
```

### "Out of memory sul Mac Studio"

```bash
# Vedi risorse sul Mac Studio
ssh fabio@192.168.1.47 'top -l 1 | head -20'

# Ferma servizi non necessari
ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 stop <nome-servizio>'
```

### "Port già in uso"

```bash
# Trova processo
lsof -i :3001

# Kill processo
kill -9 <PID>

# Oppure kill tutti i port forward
pkill -f "ssh.*-L.*192.168.1.47"
```

---

## 📊 Monitoraggio Risorse

### Sul Mac Studio

```bash
# Monitora risorse in tempo reale
ssh fabio@192.168.1.47 'npx pm2 monit'

# Oppure usa htop (se installato)
ssh fabio@192.168.1.47 'htop'

# Oppure Activity Monitor grafico sul Mac Studio stesso
```

### Sul MacBook

```bash
# Vedi processi locali
ps aux | grep -E "ssh|fswatch|rsync"

# Vedi port forward attivi
lsof -i -P | grep LISTEN
```

---

## 💡 Tips & Tricks

### 1. Alias Utili

Aggiungi questi al tuo `~/.zshrc` o `~/.bashrc`:

```bash
# Alias per Mac Studio
alias ms-deploy="cd /Users/andromeda/dev/ewh && ./scripts/deploy-to-mac-studio.sh"
alias ms-sync="cd /Users/andromeda/dev/ewh && ./scripts/watch-and-sync-mac-studio.sh"
alias ms-stop="cd /Users/andromeda/dev/ewh && ./scripts/stop-mac-studio-dev.sh"
alias ms-ssh="ssh fabio@192.168.1.47"
alias ms-logs="ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 logs'"
alias ms-status="ssh fabio@192.168.1.47 'cd /Users/fabio/dev/ewh && npx pm2 list'"
```

Poi ricarica:
```bash
source ~/.zshrc  # oppure source ~/.bashrc
```

Ora puoi usare:
```bash
ms-deploy pm      # Deploy veloce
ms-sync          # Sync automatico
ms-logs          # Vedi log
ms-status        # Status servizi
```

### 2. VS Code Tasks

Crea `.vscode/tasks.json` per avviare tutto da VS Code:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Deploy to Mac Studio",
      "type": "shell",
      "command": "./scripts/deploy-to-mac-studio.sh pm",
      "group": "build"
    },
    {
      "label": "Start Sync",
      "type": "shell",
      "command": "./scripts/watch-and-sync-mac-studio.sh",
      "isBackground": true
    }
  ]
}
```

### 3. Git Workflow

Git rimane sul MacBook! Commit localmente:

```bash
# Sul MacBook
git add .
git commit -m "feat: ..."
git push

# Il sync trasferisce automaticamente al Mac Studio
```

---

## 🎁 Vantaggi del Setup

✅ **MacBook leggero** - Solo editing, git, browser
✅ **Mac Studio potente** - Esegue tutti i servizi
✅ **Hot Reload** - Funziona perfettamente
✅ **Network locale** - Zero latency, velocissimo
✅ **Isolamento** - MacBook rimane pulito
✅ **Flessibilità** - Puoi spegnere il MacBook, Mac Studio continua

---

## 📈 Metriche Tipiche

- **Sync file singolo**: ~1 secondo
- **Deploy completo (prima volta)**: 3-5 minuti
- **Deploy successivi**: 10-30 secondi
- **Hot reload**: Istantaneo
- **Latency network**: <1ms (rete locale)

---

## 🆘 In Caso di Emergenza

```bash
# 1. Stop tutto
./scripts/stop-mac-studio-dev.sh

# 2. Kill tutti i processi SSH
pkill -f "ssh.*192.168.1.47"

# 3. Kill watch
pkill -f fswatch

# 4. Sul Mac Studio, ferma tutto
ssh fabio@192.168.1.47 'npx pm2 kill'

# 5. Riparti da zero
./scripts/deploy-to-mac-studio.sh pm
```

---

**Hai tutto pronto! Inizia con: `./scripts/deploy-to-mac-studio.sh pm`** 🚀
