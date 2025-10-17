# CORS Fix per Visual Editing System

## Problema

Il frontend della shell (localhost:3150) non poteva comunicare con il backend (localhost:4000/cms) a causa di errori CORS:

```
Access to fetch at 'http://localhost:4000/cms/visual-editing/permissions'
from origin 'http://localhost:3150' has been blocked by CORS policy:
Response to preflight request doesn't pass access control check:
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Causa

L'origin `http://localhost:3150` non era nella whitelist CORS del gateway API.

## Soluzione

Aggiunto `http://localhost:3150` alla lista `ALLOWED_ORIGINS` nel file `.env` del gateway:

**File:** `/svc-api-gateway/.env`

```env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5101,http://localhost:5300,http://localhost:5301,http://localhost:3300,http://localhost:3150
```

## Verifica

Testato con curl:

```bash
curl -X OPTIONS 'http://localhost:4000/cms/visual-editing/permissions' \
  -H 'Origin: http://localhost:3150' \
  -H 'Access-Control-Request-Method: GET'
```

**Risposta:**
```
HTTP/1.1 204 No Content
access-control-allow-origin: http://localhost:3150 ✅
access-control-allow-credentials: true ✅
access-control-allow-methods: GET,POST,PUT,PATCH,DELETE,OPTIONS ✅
```

## Riavvio Gateway

Il gateway è stato riavviato per applicare le modifiche:

```bash
pkill -f "svc-api-gateway"
cd /Users/andromeda/dev/ewh/svc-api-gateway
npm run dev
```

## Status

✅ **CORS risolto** - Il frontend può ora comunicare con il backend per il visual editing system.

## Test nel Browser

Per verificare:

1. Aprire http://localhost:3150
2. Login
3. Controllare console del browser → non dovrebbero più esserci errori CORS
4. Il toggle "Edit" dovrebbe apparire nel footer (se l'utente ha permessi)
