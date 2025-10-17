# Test Communications Apps - Checklist

**Data test:** 15 Ottobre 2025, ore 20:25

## Servizi Backend Status

```bash
# Test svc-communications (port 3210)
curl http://localhost:3210/health

# Test svc-crm (port 3310)
curl http://localhost:3310/health

# Test app-communications-client (port 5700)
curl -I http://localhost:5700
```

## App Communications da Testare

Apri: http://localhost:3150

Poi clicca su categoria "Communications" e testa ogni app:

### 1. Inbox ✅
- **URL:** http://localhost:5700
- **Test diretto:** `open http://localhost:5700`
- **Cosa dovrebbe mostrare:** Vista inbox unificata con icone Email, SMS, WhatsApp
- **Verifica CSS:** Dovrebbe avere sfondo bianco, testo stilizzato, icone colorate

### 2. Campaigns ✅
- **URL:** http://localhost:5700/campaigns
- **Test diretto:** `open http://localhost:5700/campaigns`
- **Cosa dovrebbe mostrare:** Dashboard campagne con metriche (Total Sent, Open Rate, Subscribers)
- **Verifica CSS:** Card con background grigio, bottone blu "New Campaign"

### 3. Accounts ✅
- **URL:** http://localhost:5700/accounts
- **Test diretto:** `open http://localhost:5700/accounts`
- **Cosa dovrebbe mostrare:** Grid di account types (Email, SMS, WhatsApp, Telegram, Discord)
- **Verifica CSS:** Card con bordi, icone colorate

### 4. Settings ✅
- **URL:** http://localhost:5700/settings
- **Test diretto:** `open http://localhost:5700/settings`
- **Cosa dovrebbe mostrare:** Lista di sezioni settings (Profile, Notifications, Security, Automation)
- **Verifica CSS:** Card con icone e frecce

### 5. CRM ✅
- **URL:** http://localhost:3310/dev
- **Test diretto:** `open http://localhost:3310/dev`
- **Cosa dovrebbe mostrare:** Documentazione API CRM con lista endpoints
- **Verifica CSS:** HTML con stili inline, sfondo grigio chiaro per endpoints

## Problemi Noti

### Se le app non caricano i CSS:

**Problema:** Le classi Tailwind non vengono applicate

**Possibili cause:**
1. ❌ Tailwind config mancante → **RISOLTO** (creato tailwind.config.js e postcss.config.js)
2. ❌ Vite server non riavviato → **RISOLTO** (server riavviato)
3. ⚠️ CORS issues quando caricato da iframe nella shell
4. ⚠️ CSS non viene incluso quando servito tramite iframe

**Soluzione CORS/iframe:**

Se le app funzionano standalone ma non nella shell, è un problema di CORS o CSP. Aggiungi headers CORS a Vite:

```js
// vite.config.ts
export default {
  server: {
    cors: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
  }
}
```

### Se le app non si aprono proprio:

**Problema:** Errore 404 o connessione rifiutata

**Diagnosi:**
```bash
# Verifica che i processi siano attivi
lsof -i :5700  # app-communications-client
lsof -i :3210  # svc-communications
lsof -i :3310  # svc-crm

# Test diretto
curl http://localhost:5700
curl http://localhost:3210/health
curl http://localhost:3310/health
```

**Soluzione:** Riavviare i servizi mancanti

## Test Completo

Esegui questo script per testare tutto:

```bash
#!/bin/bash

echo "🧪 Testing Communications Apps..."
echo ""

echo "1️⃣ Testing app-communications-client (5700)..."
curl -s -I http://localhost:5700 | head -1

echo "2️⃣ Testing svc-communications (3210)..."
curl -s http://localhost:3210/health | jq -r '.status'

echo "3️⃣ Testing svc-crm (3310)..."
curl -s http://localhost:3310/health | jq -r '.status'

echo ""
echo "4️⃣ Testing CSS generation..."
curl -s http://localhost:5700 | grep -o "type=\"module\"" | wc -l

echo ""
echo "✅ All tests complete!"
```

## Risultati Attesi

**Se tutto funziona:**
- ✅ Vite server su 5700 risponde HTTP 200
- ✅ svc-communications health = "healthy"
- ✅ svc-crm health = "healthy"
- ✅ Le app mostrano layout stilizzato con Tailwind
- ✅ Navigazione tra le pagine funziona (Inbox → Campaigns → Accounts → Settings)

**Tailwind JIT Output:**
```
Source path: /Users/andromeda/dev/ewh/app-communications-client/src/index.css
Setting up new context...
Finding changed files: 2.838ms
Reading changed files: 6.881ms
Sorting candidates: 0.141ms
Generate rules: 10.737ms
Build stylesheet: 0.678ms
Potential classes:  391  ✅ QUESTO È IL SEGNALE CHE TAILWIND FUNZIONA
Active contexts:  1
JIT TOTAL: 96.745ms
```

## Note per Debugging

1. **Aprire DevTools nel browser** (F12) e verificare:
   - Console: cercare errori JavaScript
   - Network: verificare che index.css venga caricato
   - Elements: ispezionare se le classi Tailwind sono applicate

2. **Test standalone vs iframe:**
   - Standalone: `open http://localhost:5700` (dovrebbe funzionare)
   - Iframe nella shell: Potrebbe avere problemi CORS

3. **Se vedi testo non stilizzato:**
   - Significa che React funziona ma CSS no
   - Verificare che Vite serva correttamente index.css
   - Controllare DevTools → Network → verificare /src/index.css

