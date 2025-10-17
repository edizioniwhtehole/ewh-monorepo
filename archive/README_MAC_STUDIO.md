# 🚀 EWH su Mac Studio - Guida Veloce

## Setup Completato ✅

Il tuo sistema è configurato per far girare tutto sul **Mac Studio M2** mentre sviluppi comodamente dal **MacBook**.

---

## 🎯 Uso Quotidiano - 3 Comandi

### 1️⃣ Avvia Tutto (Mattina)

```bash
cd /Users/andromeda/dev/ewh
./start-mac-studio.sh
```

**Cosa fa:**
- ✅ Sincronizza codice al Mac Studio
- ✅ Avvia tutti i servizi
- ✅ Configura port forwarding
- ✅ Attiva sync automatico
- ✅ Apre browser su http://localhost:5400

**Tempo:** ~10-15 secondi

**Dopo averlo lanciato:**
- Puoi chiudere il terminale
- Tutto gira in background
- Salvi file → Sync automatico in 1-2 secondi

---

### 2️⃣ Vedi Status (Opzionale)

```bash
./scripts/status-mac-studio.sh
```

Mostra:
- Servizi attivi
- Port forwarding
- Sync automatico

---

### 3️⃣ Ferma Tutto (Sera)

```bash
./stop-mac-studio.sh
```

Chiede se vuoi fermare anche i servizi sul Mac Studio.

---

## 💻 Workflow Completo

```bash
# === MATTINA ===
cd /Users/andromeda/dev/ewh
./start-mac-studio.sh
# Aspetta 10 secondi, poi chiudi il terminale

# === DURANTE IL GIORNO ===
code .                    # Apri VS Code
# Edita file normalmente
# Salvi → Sync automatico → Hot reload

# Browser già aperto su http://localhost:5400

# === SERA ===
./stop-mac-studio.sh
# Premi 'y' per fermare anche Mac Studio
```

---

## 🌐 URL Disponibili

Dopo `./start-mac-studio.sh` accedi a:

- **PM Frontend**: http://localhost:5400
- **API Gateway**: http://localhost:4000
- **PM Service**: http://localhost:5500

---

## 📊 Gestione Servizi Mac Studio

```bash
# Status servizi
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 list'

# Log in tempo reale
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 logs'

# Restart servizio specifico
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 restart svc-pm'

# Restart tutti
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 restart all'

# Stop tutti
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 stop all'
```

---

## 🐛 Troubleshooting

### "Cannot connect" nel browser

```bash
# Riavvia tutto
./stop-mac-studio.sh
./start-mac-studio.sh
```

### "Sync non funziona"

```bash
# Verifica status
./scripts/status-mac-studio.sh

# Se sync non è attivo, riavvia
./stop-mac-studio.sh
./start-mac-studio.sh
```

### Mac Studio non risponde

1. Verifica Mac Studio sia acceso
2. Verifica Remote Login: System Settings → Sharing → Remote Login (ON)
3. Verifica stessa rete WiFi

```bash
# Test connessione
ssh fabio@192.168.1.47 echo "OK"
```

### Port già in uso

```bash
# Kill tutti i processi
./stop-mac-studio.sh

# Verifica porte libere
lsof -i :5400 -i :4000 -i :5500

# Riavvia
./start-mac-studio.sh
```

---

## 🎁 Vantaggi

✅ **MacBook leggero** - Solo editing, nessun servizio locale
✅ **Un comando** - `./start-mac-studio.sh` e via
✅ **Background** - Processi in background, chiudi il terminale
✅ **Sync automatico** - Salvi → 1 sec → Mac Studio aggiornato
✅ **Hot reload** - Modifiche visibili istantaneamente
✅ **Network locale** - Zero latency, velocissimo

---

## 📝 Note Tecniche

- **Servizi gestiti con PM2** sul Mac Studio
- **Port forwarding via SSH** (sicuro)
- **Sync automatico con fswatch + rsync**
- **Processi daemonizzati** - girano anche dopo chiusura terminale

---

## 🆘 Comandi di Emergenza

```bash
# Reset completo locale
./stop-mac-studio.sh
pkill -f "ssh.*192.168.1.47"
pkill -f fswatch
rm -f /tmp/ewh-mac-studio-*.pid

# Reset completo Mac Studio
ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:$PATH && pm2 kill'

# Riavvia da zero
./start-mac-studio.sh
```

---

## 📚 File Utili

- **[GUIDA_USO_MAC_STUDIO.md](GUIDA_USO_MAC_STUDIO.md)** - Guida dettagliata completa
- **[SETUP_MAC_STUDIO.md](SETUP_MAC_STUDIO.md)** - Setup iniziale (già fatto)
- **[TROVA_MAC_STUDIO.md](TROVA_MAC_STUDIO.md)** - Come trovare IP Mac Studio

---

## 🎉 TL;DR

```bash
# Mattina
./start-mac-studio.sh

# Lavora normalmente su VS Code

# Sera
./stop-mac-studio.sh
```

**That's it!** 🚀
