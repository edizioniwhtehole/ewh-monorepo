# 🔍 Come Trovare IP del Mac Studio

## Metodo 1: Sul Mac Studio (CONSIGLIATO - 10 secondi)

**Sul Mac Studio**, apri Terminal:

```bash
# Trova IP
ifconfig en0 | grep "inet " | awk '{print $2}'

# Oppure più semplice: guarda nelle Preferenze
# System Settings → Network → Wi-Fi (o Ethernet) → Details → Vedi IP Address
```

---

## Metodo 2: Dal MacBook - Usa il nome computer

Il Mac Studio probabilmente ha un nome tipo "Mac-Studio.local" o "NomeUtente-Mac-Studio.local"

### Trova il nome:

**Sul Mac Studio**:
```bash
# Mostra il nome del computer
scutil --get ComputerName

# Oppure il nome locale
scutil --get LocalHostName
```

Ti dirà qualcosa tipo: `Mac-Studio` o `Andrea-Mac-Studio`

### Connettiti usando il nome:

**Sul MacBook**:
```bash
# Prova a connetterti usando .local
ssh USERNAME@Mac-Studio.local

# Oppure con trattini bassi
ssh USERNAME@Mac_Studio.local

# Se non sai username, prova nomi comuni:
# - Il tuo nome (es. andrea, marco, luca)
# - admin
# - macstudio
```

---

## Metodo 3: Scan della rete (Dal MacBook)

```bash
# Installa nmap
brew install nmap

# Trova il tuo range di rete
ipconfig getifaddr en0  # Es. 192.168.1.100

# Scan della rete (sostituisci con il tuo range)
nmap -sn 192.168.1.0/24 | grep -B 2 "Apple"

# Oppure scan porte SSH
nmap -p 22 192.168.1.0/24 --open
```

---

## Metodo 4: Finder (PIÙ VISUALE)

**Sul MacBook**:

1. Apri **Finder**
2. Guarda la sidebar sinistra sotto "Locations" o "Network"
3. Dovresti vedere il Mac Studio
4. Clicca su di esso
5. Clicca "Connect As..." in alto a destra
6. L'indirizzo sarà mostrato in alto (es. `afp://192.168.1.50`)

---

## Metodo 5: Router Admin Panel

1. Apri browser
2. Vai su: `http://192.168.1.1` (o `192.168.0.1` o `10.0.0.1`)
3. Login al router (username/password sul retro del router)
4. Cerca "Connected Devices" o "DHCP Clients"
5. Trova "Mac-Studio" nella lista
6. Vedi l'IP assegnato

---

## Metodo 6: System Settings (Sul Mac Studio)

**Sul Mac Studio**:

1. **System Settings**
2. **Network**
3. Seleziona la connessione attiva (Wi-Fi o Ethernet)
4. Clicca **Details...**
5. Vedi **IP Address** (es. 192.168.1.50)

---

## Quick Test (Dal MacBook)

Una volta che hai l'IP o il nome, testa:

```bash
# Con IP
ping 192.168.1.50

# Con nome
ping Mac-Studio.local

# Se risponde, prova SSH
ssh USERNAME@192.168.1.50
# oppure
ssh USERNAME@Mac-Studio.local
```

---

## 🎯 CONSIGLIO

Il modo **PIÙ VELOCE** è:

1. **Sul Mac Studio**: System Settings → Network → Details → Copia IP
2. **Sul MacBook**: Usa quell'IP

Oppure se preferisci il nome:

1. **Sul Mac Studio**: `scutil --get LocalHostName`
2. **Sul MacBook**: `ssh username@quel-nome.local`

---

## Problemi Comuni

### "Host not found"
- Verifica che entrambi i Mac siano sulla stessa rete Wi-Fi/Ethernet
- Controlla che il firewall non blocchi SSH

### "Connection refused"
- Verifica che Remote Login sia abilitato sul Mac Studio
- System Settings → General → Sharing → Remote Login (ON)

### "Permission denied"
- Username errato
- Prova con l'username che usi sul Mac Studio (vedi con `whoami`)

---

**Una volta trovato l'IP o il nome, dimmi e configuro tutto! 🚀**
