# 🔧 PM System - Quick Fix

**Issue**: Frontend error "Unexpected token '<', "<!doctype "... is not valid JSON"
**Root Cause**: Multiple frontend processes on same port
**Status**: ✅ **FIXED**

---

## 🐛 Problema

Frontend stava ritornando errore:
```
Error loading templates: SyntaxError: Unexpected token '<', "<!doctype "... is not valid JSON
```

**Causa**: Il proxy Vite non funzionava perché c'erano processi duplicati:
- Frontend su porta 5400 (vecchio)
- Frontend su porta 5401 (nuovo)
- Browser chiamava 5400 → riceveva HTML invece di proxy a backend

---

## ✅ Soluzione

```bash
# 1. Kill processi duplicati
lsof -ti:5400 | xargs kill -9
lsof -ti:5401 | xargs kill -9

# 2. Riavvia frontend pulito
cd /Users/andromeda/dev/ewh/app-pm-frontend
npm run dev

# Output:
# ✅ VITE v5.4.20 ready in 177 ms
# ✅ Local: http://localhost:5400/
```

---

## 🧪 Verifica

```bash
# Test proxy
curl "http://localhost:5400/api/pm/templates?tenant_id=00000000-0000-0000-0000-000000000001"

# Output:
# ✅ Success: True
# ✅ Templates: 4
```

---

## 🚀 Sistema Ora Funzionante

**Backend**: ✅ http://localhost:5500
**Frontend**: ✅ http://localhost:5400
**Proxy**: ✅ /api/* → localhost:5500

**Apri browser**: http://localhost:5400

Ora dovresti vedere:
- ✅ 4 template cards
- ✅ Nessun errore console
- ✅ Template selector funzionante
- ✅ Puoi creare progetti

---

## 📝 Restart Clean (Se Necessario)

```bash
# Script per restart pulito
#!/bin/bash

echo "🧹 Cleaning up..."
lsof -ti:5500 | xargs kill -9 2>/dev/null
lsof -ti:5400 | xargs kill -9 2>/dev/null

echo "🚀 Starting backend..."
cd /Users/andromeda/dev/ewh/svc-pm
npm run dev > /tmp/pm-backend.log 2>&1 &
sleep 2

echo "🚀 Starting frontend..."
cd /Users/andromeda/dev/ewh/app-pm-frontend
npm run dev > /tmp/pm-frontend.log 2>&1 &
sleep 3

echo "✅ System ready!"
echo "📍 Backend: http://localhost:5500"
echo "📍 Frontend: http://localhost:5400"
```

Salva come `scripts/pm-restart.sh` e rendi eseguibile:
```bash
chmod +x scripts/pm-restart.sh
./scripts/pm-restart.sh
```

---

**Status**: ✅ Sistema operativo al 100%
