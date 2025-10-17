# 💡 Esempio Pratico: Setup Remoto in 10 Minuti

## Scenario Esempio
- **Mac locale**: MacBook Pro 2020, 8GB RAM
- **Server remoto**: Intel NUC, 32GB RAM, IP `192.168.1.50`

## Step 1: Setup Server (5 minuti)

```bash
# 1. SSH nel server
ssh andrea@192.168.1.50

# 2. Installa Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Installa Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker andrea

# 4. Verifica
node --version  # v20.x.x
docker --version  # Docker version 24.x.x

# 5. Logout e login (per applicare docker group)
exit
```

## Step 2: Configura SSH (2 minuti)

```bash
# Sul Mac
ssh-keygen -t rsa -b 4096  # Premi enter 3 volte
ssh-copy-id andrea@192.168.1.50

# Configura host
cat >> ~/.ssh/config <<EOF
Host ewh-server
  HostName 192.168.1.50
  User andrea
  Port 22
EOF

# Testa
ssh ewh-server echo "OK"  # Dovrebbe dire "OK" senza password
```

## Step 3: Deploy Iniziale (3 minuti)

```bash
# Sul Mac, nella cartella ewh

# 1. Modifica script
sed -i '' 's/user@192.168.1.100/andrea@192.168.1.50/g' scripts/deploy-to-remote.sh
sed -i '' 's|/home/user/ewh|/home/andrea/ewh|g' scripts/deploy-to-remote.sh

# 2. Deploy!
./scripts/deploy-to-remote.sh pm

# Output:
# 🚀 Deploy EWH su Server Remoto
# 📦 Sincronizzazione codice...
# ✅ Codice sincronizzato
# 🚀 Avvio profilo 'pm' sul server remoto...
# ✅ Servizi avviati
# 🌐 Setup port forwarding...
# 🎉 Deploy completato!
```

## Step 4: Usa! (subito)

```bash
# Apri browser
open http://localhost:3001

# Il sito gira sul server, ma lo accedi come se fosse locale!
```

## Step 5: Sync Automatico

```bash
# In un nuovo terminale
./scripts/watch-and-sync.sh ewh-server /home/andrea/ewh

# Ora ogni volta che salvi un file:
# 👁️  Watching per cambiamenti...
# 🔄 14:35:12 Sincronizzazione in corso...
# ✅ 14:35:13 Sync completato
```

## Esempio Workflow Reale

```bash
# === MATTINA ===

# Terminal 1: Deploy e port forward
./scripts/deploy-to-remote.sh pm

# Terminal 2: Sync automatico
./scripts/watch-and-sync.sh ewh-server /home/andrea/ewh

# Terminal 3: Lavoro normale
cd app-pm-frontend/src
code .

# === DURANTE IL GIORNO ===

# Editi file in VS Code sul Mac
# Salvi → sync automatico
# Hot reload sul server
# Browser su localhost:3001 si aggiorna

# === SERA ===

# Stop tutto
./scripts/stop-remote-dev.sh

# Stop servizi sul server
ssh ewh-server 'cd ewh && npx pm2 stop all'
```

## Variante: VS Code Remote (ancora più semplice!)

```bash
# 1. Installa estensione
code --install-extension ms-vscode-remote.remote-ssh

# 2. Cmd+Shift+P → "Remote-SSH: Connect to Host"

# 3. Digita: ewh-server

# 4. Si apre una nuova finestra VS Code

# 5. File → Open Folder → /home/andrea/ewh

# 6. Terminal integrato (Ctrl+`):
./start-profiles.sh pm

# 7. LAVORI COME SE FOSSE LOCALE!
# - File explorer mostra file sul server
# - Terminal esegue comandi sul server
# - Git funziona sul server
# - Extensions girano sul server
```

## Confronto Veloce

### Metodo Deploy + Sync (Opzione A)

**Pro:**
- Git rimane sul Mac (commit locali)
- Puoi lavorare offline (poi sync)
- Controllo totale

**Contro:**
- 2 terminali aperti
- Latency sync 2-3 secondi

**Quando usare:** Preferisco git locale, lavoro su più branch

### Metodo VS Code Remote (Opzione B)

**Pro:**
- Una finestra sola
- Zero latency
- Come sviluppo locale

**Contro:**
- Git sul server (commit remoti)
- Richiede connessione stabile

**Quando usare:** Connessione stabile, workflow semplice

## Monitoraggio

```bash
# Vedi cosa gira sul server
ssh ewh-server 'npx pm2 list'

# Vedi log in tempo reale
ssh ewh-server 'npx pm2 logs svc-pm'

# Vedi risorse
ssh ewh-server 'htop'

# Restart servizio
ssh ewh-server 'cd ewh && npx pm2 restart svc-pm'
```

## Troubleshooting Comune

### Browser dice "Cannot connect"

```bash
# Verifica port forward sia attivo
lsof -i :3001

# Se non c'è output, riavvia deploy
./scripts/stop-remote-dev.sh
./scripts/deploy-to-remote.sh pm
```

### Sync non funziona

```bash
# Installa fswatch
brew install fswatch

# Verifica connessione
ssh ewh-server echo "OK"

# Riavvia sync
./scripts/watch-and-sync.sh ewh-server /home/andrea/ewh
```

### Cambio file ma non vedo modifiche

```bash
# Verifica sync sia attivo
ps aux | grep fswatch

# Forza sync manuale
rsync -avz --exclude node_modules \
  /Users/andromeda/dev/ewh/ \
  ewh-server:/home/andrea/ewh/
```

## Costi

### Server Dedicato
- Raspberry Pi 4 8GB: €80 una tantum
- Mini PC Intel: €200-400
- Mac Mini M1: €500-700
- Consumo elettrico: ~€2-5/mese

### Cloud VM
- DigitalOcean Droplet 4GB: $24/mese
- AWS t3.medium: ~$30/mese
- Linode 4GB: $20/mese

## Raccomandazione

**Per iniziare subito:**
1. Usa un vecchio laptop/desktop che hai già
2. Installa Ubuntu Server
3. Usa Opzione A (Deploy + Sync)

**Dopo qualche giorno:**
1. Se ti piace, passa a VS Code Remote
2. Considera hardware dedicato se lavori così sempre

---

**Risultato finale**: Mac leggero e veloce, server fa il lavoro pesante! 🚀
