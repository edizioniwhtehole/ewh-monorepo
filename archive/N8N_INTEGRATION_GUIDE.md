# Guida Integrazione n8n con Autenticazione EWH

## 📋 Panoramica

n8n è ora integrato con il sistema di autenticazione EWH tramite un proxy che valida i token JWT.

## 🏗️ Architettura

```
Frontend/Client
    ↓ (JWT Token in Authorization header)
svc-n8n-proxy (porta 5679)
    ↓ (valida JWT con svc-auth)
    ↓ (aggiunge headers utente)
n8n (porta 5678 - senza auth)
```

## 🚀 Come Usare

### 1. Avviare i Servizi

```bash
# n8n (porta 5678, senza autenticazione)
N8N_PORT=5678 N8N_USER_MANAGEMENT_DISABLED=true npx n8n start

# Proxy di autenticazione (porta 5679)
cd svc-n8n-proxy
npm run dev
```

### 2. Accedere a n8n dal Frontend

**NON** usare direttamente `http://localhost:5678`

**USA** il proxy autenticato su porta 5679:

```javascript
const token = localStorage.getItem('ewh.session');
const session = JSON.parse(token);

const response = await fetch('http://localhost:5679/api/workflows', {
  headers: {
    'Authorization': `Bearer ${session.accessToken}`,
    'Content-Type': 'application/json'
  }
});
```

### 3. Headers Automatici

Il proxy aggiunge automaticamente questi headers a ogni richiesta verso n8n:

- `x-ewh-user-id` - ID utente
- `x-ewh-user-email` - Email utente
- `x-ewh-tenant-id` - ID organizzazione
- `x-ewh-tenant-role` - Ruolo utente nel tenant

Puoi usare questi headers nei workflow n8n per creare automazioni tenant-specific.

## 🔐 Sicurezza

### Come Funziona

1. **Client** → Invia richiesta con `Authorization: Bearer <jwt-token>`
2. **Proxy** → Valida il token con la chiave pubblica di `svc-auth`
3. **Proxy** → Se valido, aggiunge headers utente e fa forward a n8n
4. **Proxy** → Se invalido, ritorna 401 Unauthorized

### Protezione

- n8n gira su porta 5678 (localhost only, nessuna auth)
- Proxy esposto su porta 5679 (richiede JWT valido)
- Solo il proxy può accedere a n8n
- Tutti i token vengono validati contro `svc-auth`

## 🛠️ Configurazione Proxy

File: `svc-n8n-proxy/.env`

```env
PORT=5679
N8N_URL=http://localhost:5678
AUTH_SERVICE_URL=http://localhost:4001
CORS_ORIGIN=http://localhost:3000
NODE_ENV=development
```

## 📡 API Proxy

### Health Check (nessuna auth)

```bash
curl http://localhost:5679/health
```

Response:
```json
{
  "status": "ok",
  "service": "n8n-proxy",
  "n8nConnected": true
}
```

### Refresh Public Key (nessuna auth)

```bash
curl -X POST http://localhost:5679/refresh-key
```

Forza il refresh della chiave pubblica dal servizio auth.

### Tutte le altre rotte (auth richiesta)

Tutte le rotte vengono proxate a n8n previa validazione JWT:

```bash
curl http://localhost:5679/api/workflows \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🔧 Integrazione con API Gateway

Per production, aggiungi una rotta nell'API Gateway:

```javascript
// In svc-api-gateway
app.use('/automation',
  authMiddleware,  // Valida JWT
  proxy('http://localhost:5679')  // Forward al proxy n8n
);
```

Poi accedi tramite:
```
https://api.yourcompany.com/automation/*
```

## 🎯 Esempio Workflow n8n

### Workflow: "Notifica quando nuovo asset caricato"

1. **Webhook Trigger** - Riceve notifica da svc-media
   - URL: `http://localhost:5679/webhook/asset-uploaded`
   - Method: POST
   - Headers automatici: `x-ewh-tenant-id`, `x-ewh-user-id`

2. **HTTP Request** - Recupera dettagli utente
   - URL: `http://svc-auth:4001/users/{{$node["Webhook"].json["headers"]["x-ewh-user-id"]}}`
   - Method: GET

3. **HTTP Request** - Invia notifica
   - URL: `http://svc-comm:4500/notifications/send`
   - Method: POST
   - Body:
     ```json
     {
       "userId": "{{$node["Webhook"].json["headers"]["x-ewh-user-id"]}}",
       "message": "Il tuo asset è stato caricato con successo",
       "tenantId": "{{$node["Webhook"].json["headers"]["x-ewh-tenant-id"]}}"
     }
     ```

## 🐛 Troubleshooting

### Errore: "Missing or invalid authorization header"

- Verifica che l'header `Authorization` sia presente
- Formato corretto: `Bearer <token>`
- Token non deve contenere spazi extra

### Errore: "Invalid or expired token"

- Il token JWT è scaduto (default: 15 minuti)
- Rigenera un nuovo token tramite login
- Verifica che il token sia firmato con la chiave corretta

### Errore: "Failed to connect to n8n service"

- n8n non è in esecuzione sulla porta 5678
- Avvia n8n: `N8N_PORT=5678 npx n8n start`

### Proxy non parte: "Failed to fetch public key"

- `svc-auth` non è in esecuzione sulla porta 4001
- Il proxy ora parte comunque (warning) e tenterà di recuperare la chiave alla prima richiesta
- Avvia i servizi Docker: `docker compose up -d`

## 📚 Risorse

- [n8n Documentation](https://docs.n8n.io/)
- [JWT.io](https://jwt.io/) - Debug JWT tokens
- `svc-n8n-proxy/README.md` - Documentazione tecnica del proxy
- `scripts/generate-dev-token.js` - Genera token di sviluppo

## 🎓 Best Practices

1. **Mai esporre n8n direttamente** - Usa sempre il proxy
2. **Validare sempre i tenant** - Usa `x-ewh-tenant-id` nei workflow
3. **Rate limiting** - Implementa rate limiting nel proxy per production
4. **Logging** - Logga tutte le richieste autenticate per audit
5. **Token rotation** - I token devono scadere (15 min default)
6. **Webhook sicuri** - Usa token di validazione per webhook pubblici

## 🔄 Prossimi Passi

1. ✅ Proxy di autenticazione funzionante
2. ⏳ Integrazione con API Gateway
3. ⏳ Rate limiting e throttling
4. ⏳ Logging strutturato e audit trail
5. ⏳ Dashboard per monitorare webhook e workflow
6. ⏳ Template workflow predefiniti per casi d'uso comuni
