# 🚀 Guida Sviluppo Remoto Mac Studio

## ✅ Setup Completato

Il tuo ambiente è ora configurato per sviluppare sul MacBook con esecuzione sul Mac Studio.

### 🔄 Sincronizzazione Automatica Bidirezionale

**Mutagen** è attivo e sincronizza automaticamente in entrambe le direzioni:

```bash
# Controlla stato sync
mutagen sync list

# Monitora modifiche in real-time
mutagen sync monitor ewh-dev

# Pausa sync (se serve)
mutagen sync pause ewh-dev

# Riprendi sync
mutagen sync resume ewh-dev
```

**Come funziona:**
1. Modifichi un file sul MacBook → Sincronizzato al Mac Studio in **<3 secondi**
2. Qualcun altro modifica sul Mac Studio → Sincronizzato al tuo MacBook automaticamente
3. **Bidirezionale**: funziona in entrambe le direzioni
4. **Intelligente**: sincronizza solo file modificati, non tutto

### 🎯 Comandi per Claude Code

Claude Code può ora eseguire comandi **direttamente sul Mac Studio**:

```bash
# Esegui comando sul Mac Studio
./remote-shell.sh <comando>

# Esempi
./remote-shell.sh pm2 list
./remote-shell.sh pm2 restart app-pm-frontend
./remote-shell.sh npm --prefix app-pm-frontend run dev
./remote-shell.sh lsof -i :5400
```

### 💻 Workflow di Sviluppo

**Scenario 1: Sviluppo Normale**
1. Apri VS Code sul MacBook
2. Modifica i file normalmente
3. Mutagen sincronizza automaticamente al Mac Studio
4. Hot reload funziona automaticamente (Vite/Next rilevano modifiche)
5. Apri http://localhost:5400 (via tunnel) o http://192.168.1.47:5400 (diretta)

**Scenario 2: Riavvio Servizio**
```bash
# Da terminale o Claude Code
./remote-shell.sh pm2 restart app-pm-frontend
```

**Scenario 3: Installare Dipendenze**
```bash
# Sul Mac Studio (remoto)
./remote-shell.sh npm --prefix app-pm-frontend install

# Oppure batch per tutti
./install-all-deps.sh
```

### 📱 Dashboard di Gestione

Apri http://localhost:9999 per:
- ✅ Vedere stato servizi
- ✅ Avviare/fermare servizi remoti
- ✅ Aprire app in browser (localhost o network)
- ✅ Installare dipendenze
- ✅ Vedere CPU/RAM usage

### 🔧 Comandi Shell Alias

Nel terminale (`.zshrc` configurato):

```bash
# Esegui comando sul Mac Studio
studio pm2 list
studio npm --prefix app-pm-frontend run dev

# SSH diretto sul Mac Studio
studio-cd

# Deploy manuale (sync + restart)
deploy-to-studio app-pm-frontend
```

### ⚡ Vantaggi di Questo Setup

1. **MacBook Veloce**: Il codice non gira qui, solo editing
2. **Hot Reload Nativo**: Vite/Next rilevano modifiche istantaneamente
3. **Sync Bidirezionale**: Modifiche da entrambe le parti
4. **Backup Automatico**: Codice su 2 macchine sempre
5. **Claude Code Integrato**: Può eseguire comandi remoti
6. **Colleghi Accedono**: Via http://192.168.1.47:PORTA

### 🐛 Troubleshooting

**Sync non funziona?**
```bash
mutagen sync list  # Controlla stato
mutagen daemon restart  # Riavvia daemon
```

**Conflitti di sync?**
```bash
mutagen sync list  # Vedi conflitti
# Risolvi manualmente i file in conflitto
```

**Servizio non si avvia?**
```bash
./remote-shell.sh pm2 logs app-pm-frontend --lines 50
# Controlla gli errori
```

**Porte in conflitto?**
```bash
./remote-shell.sh lsof -i :5400  # Vedi chi usa la porta
./remote-shell.sh pm2 delete all  # Reset completo PM2
```

### 📊 Monitoraggio

```bash
# Stato sync
mutagen sync list

# Stato servizi remoti
./remote-shell.sh pm2 list

# Log servizio
./remote-shell.sh pm2 logs app-pm-frontend

# Porte in uso
./remote-shell.sh lsof -nP -iTCP -sTCP:LISTEN
```

### 🎉 Risultato Finale

Ora puoi:
- ✅ Sviluppare normalmente sul MacBook (veloce)
- ✅ Eseguire sul Mac Studio (potente, non rallenta il Mac)
- ✅ Vedere modifiche in tempo reale (hot reload automatico)
- ✅ Zero terminale (tutto automatico in background)
- ✅ Claude Code può gestire servizi remoti
- ✅ Colleghi possono testare le tue app
- ✅ Codice sincronizzato su entrambe le macchine (backup)

**Non serve più fare nulla manualmente!** 🚀
