# Istruzioni Avvio Manuale DAM

## ❌ Problema Attuale
Ci sono troppi processi Node in background che si sovrappongono e causano conflitti.

## ✅ Soluzione Definitiva (DA FARE MANUALMENTE)

### 1. Apri 2 Terminali Separati

**Terminale 1 - Backend:**
```bash
cd /Users/andromeda/dev/ewh/svc-media
npm run dev
```

**Terminale 2 - Frontend:**
```bash
cd /Users/andromeda/dev/ewh/app-dam
npm run dev
```

### 2. Aspetta che Entrambi Compilino

Backend dirà:
```
🚀 svc-media listening on http://0.0.0.0:4003
```

Frontend dirà:
```
✓ Ready in 2s
```

### 3. Apri Browser

http://localhost:3300/library

---

## 🐛 Se il Backend Dice "EADDRINUSE"

Significa che la porta 4003 è occupata. Esegui:

```bash
lsof -ti:4003 | xargs kill -9
```

Poi riprova step 1.

---

## ✅ Cosa È Stato Risolto nel Codice

1. **React Portal** - Il modal è renderizzato in `document.body`, sempre sopra rc-dock
2. **Z-index 99999** - Garantisce visibilità massima
3. **Dropdown Context** - Mostra i 7 modi DAM dal database
4. **Salvataggio Sicuro** - Non crasherà più l'interfaccia (salva formato rc-dock corretto)
5. **Messaggio Informativo** - Spiega che la modifica numerica non è implementata

---

## 🎯 Cosa Aspettarsi

1. ✅ Anteprime degli asset visibili
2. ✅ Pulsante "Advanced" nella topbar
3. ✅ Modal appare sopra tutto con backdrop scuro
4. ✅ Dropdown mostra 7 modi DAM (Library Overview, Upload Mode, ecc.)
5. ✅ Selezioni un modo → carica il layout
6. ✅ Vedi tutti i panel con i loro valori
7. ✅ Clicchi "Salva" → l'interfaccia continua a funzionare

---

## ⚠️ Limitazione Temporanea

I valori numerici sono **VISUALIZZATI** ma **NON MODIFICABILI**.

Modificare i valori non avrà effetto - il salvataggio preserva sempre il layout originale.

Questo previene il bug critico che causava il crash dell'interfaccia.

---

## 📁 File Modificati

- `/Users/andromeda/dev/ewh/app-dam/src/components/AdvancedLayoutEditor.tsx`
  - Aggiunto `createPortal` da react-dom
  - Modal renderizzato in document.body
  - Z-index aumentato a 99999
  - Salvataggio corretto del layout originale
  - Messaggio informativo aggiunto

---

## 🚀 Script Automatico (Alternativa)

Se preferisci uno script:

```bash
/Users/andromeda/dev/ewh/start-dam.sh
```

Ma se non funziona, usa i 2 terminali manuali (più affidabile).
