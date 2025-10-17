# 📱 Installazione App EWH Mac Studio

## 🎯 Hai 2 App Pronte!

Nel Finder che si è appena aperto vedi:
- **EWH-Mac-Studio.app** 🟢 
- **EWH-Mac-Studio-Stop.app** 🔴

---

## 🚀 Setup (30 secondi)

### Step 1: Aggiungi al Dock

1. **Trascina** `EWH-Mac-Studio.app` nel **Dock** (in basso)
2. Posizionala dove preferisci (es. vicino a VS Code)
3. (Opzionale) Trascina anche `EWH-Mac-Studio-Stop.app`

### Step 2: Primo Avvio

1. **Click** su **EWH-Mac-Studio** nel Dock
2. Se appare "Non si può aprire perché proviene da sviluppatore non identificato":
   - **Click destro** sull'app → **Apri**
   - Oppure: System Settings → Privacy & Security → "Apri comunque"
3. Conferma "Apri"

### Step 3: Enjoy!

Da ora in poi:
- ✅ **Click sull'icona** → Avvia tutto
- ✅ **Notifiche** ti dicono cosa sta succedendo
- ✅ **Browser si apre** automaticamente
- ✅ **Lavori normalmente** in VS Code
- ✅ **Click Stop** quando hai finito

---

## 🎨 Come Funziona

### Primo Click → Avvio

Vedrai queste notifiche in sequenza:
```
📦 Avvio in corso...
📦 Sincronizzazione codice...
🚀 Avvio servizi...
🌐 Port forwarding attivo...
✅ Tutto pronto! Apertura browser...
🎉 Sistema attivo e sincronizzato
    http://localhost:5400
```

### Durante il Lavoro

Ogni volta che salvi un file:
```
Sincronizzato
(notifica discreta)
```

### Se Click di Nuovo (già attivo)

Appare menu:
```
EWH Mac Studio è già in esecuzione!

[Apri Browser] [Ferma] [Status]
```

### Click su Stop

```
Fermare EWH Mac Studio?
Vuoi fermare anche i servizi sul Mac Studio?

[Annulla] [Solo Locale] [Tutto]
```

---

## 💡 Tips

### Spotlight
Premi `Cmd+Space` e digita "EWH" → Avvia l'app

### Alias Tastiera
System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts
Aggiungi shortcut personalizzato per l'app

### Status Veloce
Click sull'app quando già attiva → "Status" → Vedi servizi

---

## 🐛 Se Qualcosa Non Va

### "Impossibile aprire l'app"

```bash
# Dai permessi di esecuzione
chmod +x "/Users/andromeda/dev/ewh/EWH-Mac-Studio.app/Contents/MacOS/EWH-Mac-Studio"
chmod +x "/Users/andromeda/dev/ewh/EWH-Mac-Studio-Stop.app/Contents/MacOS/EWH-Mac-Studio-Stop"
```

### "Non vedo notifiche"

System Settings → Notifications → Script Editor → Abilita

### Reset

```bash
# Ferma tutto
./stop-mac-studio.sh

# Pulisci
rm -f /tmp/ewh-mac-studio-*.pid

# Riprova
Click sull'app
```

---

## 🎉 That's It!

**Trascina nel Dock e sei pronto!**

Leggi [COME_USARE_APP.md](COME_USARE_APP.md) per dettagli completi.
