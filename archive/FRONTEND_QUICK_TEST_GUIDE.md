# Frontend Quick Test Guide - Communications & CRM

## 🚀 Come Testare il Frontend

### Prerequisiti

1. ✅ Backend deve essere in esecuzione
2. ✅ Database con migrazioni applicate
3. ✅ JWT token da svc-auth
4. ✅ Node.js e npm installati

---

## 📱 Opzione 1: Test con Frontend Completo (React)

### Step 1: Preparazione

```bash
cd /Users/andromeda/dev/ewh/app-unified-communications-client

# Installa dipendenze
npm install

# Crea .env
cat > .env << 'EOF'
VITE_API_URL=http://localhost:4000
VITE_COMMUNICATIONS_API=http://localhost:4600
VITE_WS_URL=ws://localhost:4601
VITE_AUTH_SERVICE=http://localhost:4001
EOF
```

### Step 2: Avvia Frontend

```bash
npm run dev
```

**Output atteso:**
```
  VITE v5.0.8  ready in 432 ms

  ➜  Local:   http://localhost:5600/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
```

### Step 3: Apri Browser

```bash
# Apri automaticamente
open http://localhost:5600

# Oppure manualmente
# Vai a: http://localhost:5600
```

### Step 4: Login

⚠️ **Il frontend richiede autenticazione!**

**Opzione A: Se hai già svc-auth in esecuzione:**

1. Vai a http://localhost:5600
2. Verrai reindirizzato a login
3. Usa credenziali esistenti

**Opzione B: Test senza autenticazione (temporaneo):**

Aggiungi un file di test:

```bash
# Crea un file di test senza auth
cat > src/App-NoAuth.tsx << 'EOF'
function App() {
  return (
    <div style={{ padding: '20px' }}>
      <h1>🚀 Communications Client - Test Mode</h1>
      <p>Backend API: {import.meta.env.VITE_COMMUNICATIONS_API}</p>
      <p>WebSocket: {import.meta.env.VITE_WS_URL}</p>

      <div style={{ marginTop: '20px' }}>
        <h2>Quick Tests:</h2>
        <button onClick={() => fetch('http://localhost:4600/health').then(r => r.json()).then(console.log)}>
          Test Health Check
        </button>
        <button onClick={() => window.open('http://localhost:4600/dev', '_blank')}>
          Open API Docs
        </button>
      </div>
    </div>
  );
}

export default App;
EOF

# Temporaneamente usa questa versione
mv src/App.tsx src/App-WithAuth.tsx
mv src/App-NoAuth.tsx src/App.tsx

# Riavvia frontend
npm run dev
```

---

## 🧪 Opzione 2: Test con cURL (API Diretta)

### Step 1: Ottieni JWT Token

```bash
# Se hai svc-auth in esecuzione
TOKEN=$(curl -s -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password"
  }' | jq -r '.token')

echo "Token: $TOKEN"

# Oppure usa un token di test (valido solo per dev)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJlbWFpbCI6ImFkbWluQGV4YW1wbGUuY29tIiwibmFtZSI6IkFkbWluIFVzZXIiLCJ0ZW5hbnRJZCI6IjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMSIsInJvbGUiOiJBRE1JTiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoyMDAwMDAwMDAwfQ.mock-signature"
```

### Step 2: Test API Endpoints

```bash
# 1. Health check (no auth required)
curl http://localhost:4600/health | jq

# 2. List messages
curl http://localhost:4600/api/messages \
  -H "Authorization: Bearer $TOKEN" | jq

# 3. Send test email
curl -X POST http://localhost:4600/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "channel_type": "email",
    "from": "test@example.com",
    "to": ["recipient@example.com"],
    "subject": "Test Email",
    "body": "Hello from API test!"
  }' | jq

# 4. Get settings
curl http://localhost:4600/api/settings \
  -H "Authorization: Bearer $TOKEN" | jq

# 5. Get inbox
curl http://localhost:4600/api/inbox \
  -H "Authorization: Bearer $TOKEN" | jq
```

---

## 🌐 Opzione 3: Test con Postman/Insomnia

### Importa Collection

Crea file `communications-api.postman.json`:

```json
{
  "info": {
    "name": "Unified Communications API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "http://localhost:4600/health",
          "protocol": "http",
          "host": ["localhost"],
          "port": "4600",
          "path": ["health"]
        }
      }
    },
    {
      "name": "List Messages",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{jwt_token}}",
            "type": "text"
          }
        ],
        "url": {
          "raw": "http://localhost:4600/api/messages",
          "protocol": "http",
          "host": ["localhost"],
          "port": "4600",
          "path": ["api", "messages"]
        }
      }
    },
    {
      "name": "Send Email",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{jwt_token}}",
            "type": "text"
          },
          {
            "key": "Content-Type",
            "value": "application/json",
            "type": "text"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"channel_type\": \"email\",\n  \"from\": \"sender@example.com\",\n  \"to\": [\"recipient@example.com\"],\n  \"subject\": \"Test Email\",\n  \"body\": \"Hello from Postman!\"\n}"
        },
        "url": {
          "raw": "http://localhost:4600/api/messages",
          "protocol": "http",
          "host": ["localhost"],
          "port": "4600",
          "path": ["api", "messages"]
        }
      }
    }
  ]
}
```

### Importa in Postman

1. Apri Postman
2. Click "Import"
3. Seleziona il file `communications-api.postman.json`
4. Imposta variabile `jwt_token` nelle Environment variables

---

## 🎨 Opzione 4: Test con HTML Statico (Veloce)

Crea un file HTML per test rapidi:

```bash
cat > /Users/andromeda/dev/ewh/test-communications-ui.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Communications API Test</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      padding: 20px;
      background: #f5f5f5;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: white;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    h1 { color: #667eea; margin-bottom: 20px; }
    .section { margin: 20px 0; padding: 20px; background: #f8f9fa; border-radius: 8px; }
    button {
      padding: 10px 20px;
      background: #667eea;
      color: white;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      margin-right: 10px;
      margin-bottom: 10px;
    }
    button:hover { background: #5568d3; }
    input, textarea {
      width: 100%;
      padding: 10px;
      margin: 10px 0;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 14px;
    }
    textarea { min-height: 100px; font-family: monospace; }
    .result {
      margin-top: 15px;
      padding: 15px;
      background: #2d2d2d;
      color: #f8f8f2;
      border-radius: 6px;
      overflow-x: auto;
      font-family: 'Courier New', monospace;
      font-size: 13px;
      max-height: 400px;
      overflow-y: auto;
    }
    .success { color: #4caf50; }
    .error { color: #f44336; }
    .info { color: #2196f3; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 Unified Communications API Test</h1>

    <!-- Configuration -->
    <div class="section">
      <h2>Configuration</h2>
      <label>API URL:</label>
      <input type="text" id="apiUrl" value="http://localhost:4600" />

      <label>JWT Token:</label>
      <input type="text" id="jwtToken" placeholder="Paste JWT token here (optional for health check)" />
    </div>

    <!-- Quick Tests -->
    <div class="section">
      <h2>Quick Tests</h2>
      <button onclick="testHealth()">Test Health Check</button>
      <button onclick="testApiDocs()">Open API Docs</button>
      <button onclick="testListMessages()">List Messages</button>
      <button onclick="testSettings()">Get Settings</button>
      <div id="quickResult" class="result" style="display:none;"></div>
    </div>

    <!-- Send Message -->
    <div class="section">
      <h2>Send Message</h2>
      <label>Channel:</label>
      <select id="channelType">
        <option value="email">Email</option>
        <option value="sms">SMS</option>
        <option value="whatsapp">WhatsApp</option>
        <option value="telegram">Telegram</option>
        <option value="discord">Discord</option>
      </select>

      <label>From:</label>
      <input type="text" id="fromAddress" value="test@example.com" />

      <label>To (comma separated):</label>
      <input type="text" id="toAddresses" value="recipient@example.com" />

      <label>Subject:</label>
      <input type="text" id="subject" value="Test Message" />

      <label>Body:</label>
      <textarea id="body">Hello from test UI!</textarea>

      <button onclick="sendMessage()">Send Message</button>
      <div id="sendResult" class="result" style="display:none;"></div>
    </div>

    <!-- WebSocket Test -->
    <div class="section">
      <h2>WebSocket Test</h2>
      <button onclick="connectWebSocket()">Connect WebSocket</button>
      <button onclick="disconnectWebSocket()">Disconnect</button>
      <div id="wsStatus" style="margin: 10px 0;"></div>
      <div id="wsMessages" class="result" style="display:none;"></div>
    </div>
  </div>

  <script>
    let ws = null;

    function getApiUrl() {
      return document.getElementById('apiUrl').value;
    }

    function getToken() {
      return document.getElementById('jwtToken').value;
    }

    function showResult(elementId, data, isError = false) {
      const el = document.getElementById(elementId);
      el.style.display = 'block';
      el.innerHTML = isError
        ? `<span class="error">Error:</span>\n${JSON.stringify(data, null, 2)}`
        : `<span class="success">Success:</span>\n${JSON.stringify(data, null, 2)}`;
    }

    async function testHealth() {
      try {
        const response = await fetch(`${getApiUrl()}/health`);
        const data = await response.json();
        showResult('quickResult', data);
      } catch (error) {
        showResult('quickResult', { error: error.message }, true);
      }
    }

    function testApiDocs() {
      window.open(`${getApiUrl()}/dev`, '_blank');
    }

    async function testListMessages() {
      try {
        const response = await fetch(`${getApiUrl()}/api/messages`, {
          headers: {
            'Authorization': `Bearer ${getToken()}`
          }
        });
        const data = await response.json();
        showResult('quickResult', data);
      } catch (error) {
        showResult('quickResult', { error: error.message }, true);
      }
    }

    async function testSettings() {
      try {
        const response = await fetch(`${getApiUrl()}/api/settings`, {
          headers: {
            'Authorization': `Bearer ${getToken()}`
          }
        });
        const data = await response.json();
        showResult('quickResult', data);
      } catch (error) {
        showResult('quickResult', { error: error.message }, true);
      }
    }

    async function sendMessage() {
      try {
        const body = {
          channel_type: document.getElementById('channelType').value,
          from: document.getElementById('fromAddress').value,
          to: document.getElementById('toAddresses').value.split(',').map(s => s.trim()),
          subject: document.getElementById('subject').value,
          body: document.getElementById('body').value
        };

        const response = await fetch(`${getApiUrl()}/api/messages`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${getToken()}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(body)
        });

        const data = await response.json();
        showResult('sendResult', data, !response.ok);
      } catch (error) {
        showResult('sendResult', { error: error.message }, true);
      }
    }

    function connectWebSocket() {
      const wsUrl = document.getElementById('apiUrl').value.replace('http', 'ws').replace('4600', '4601');

      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        document.getElementById('wsStatus').innerHTML = '<span class="success">✓ WebSocket Connected</span>';
        document.getElementById('wsMessages').style.display = 'block';
        document.getElementById('wsMessages').innerHTML = '<span class="info">Waiting for messages...</span>';
      };

      ws.onmessage = (event) => {
        const current = document.getElementById('wsMessages').innerHTML;
        document.getElementById('wsMessages').innerHTML =
          `${current}\n<span class="success">[${new Date().toLocaleTimeString()}]</span> ${event.data}`;
      };

      ws.onerror = (error) => {
        document.getElementById('wsStatus').innerHTML = '<span class="error">✗ WebSocket Error</span>';
      };

      ws.onclose = () => {
        document.getElementById('wsStatus').innerHTML = '<span class="info">○ WebSocket Disconnected</span>';
      };
    }

    function disconnectWebSocket() {
      if (ws) {
        ws.close();
        ws = null;
      }
    }

    // Auto-test on load
    window.onload = () => {
      console.log('Test UI loaded');
      // Uncomment to auto-test health on load
      // testHealth();
    };
  </script>
</body>
</html>
EOF
```

Apri il file:

```bash
open /Users/andromeda/dev/ewh/test-communications-ui.html
```

---

## 🔐 Come Ottenere JWT Token

### Metodo 1: Da svc-auth

```bash
# Login e ottieni token
curl -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password"
  }' | jq -r '.token'
```

### Metodo 2: Token di Test (per development)

```bash
# Token mock che non scade mai (solo per test!)
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJlbWFpbCI6ImFkbWluQGV4YW1wbGUuY29tIiwibmFtZSI6IkFkbWluIFVzZXIiLCJ0ZW5hbnRJZCI6IjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMSIsInJvbGUiOiJBRE1JTiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoyMDAwMDAwMDAwfQ.mock-signature-for-testing-only"

# Usa in curl
curl http://localhost:4600/api/messages \
  -H "Authorization: Bearer $TOKEN"
```

### Metodo 3: Disabilitare Auth Temporaneamente (solo per test)

Modifica `svc-unified-communications/src/routes/messages.ts`:

```typescript
// Commenta temporaneamente le righe:
// router.use(authenticateJWT);
// router.use(requireTenant);

// E aggiungi mock data:
router.use((req, res, next) => {
  req.user = {
    userId: '00000000-0000-0000-0000-000000000001',
    email: 'test@example.com',
    name: 'Test User',
    tenantId: '00000000-0000-0000-0000-000000000001',
    role: 'USER',
    iat: Date.now(),
    exp: Date.now() + 86400000
  };
  req.tenantId = '00000000-0000-0000-0000-000000000001';
  req.userId = '00000000-0000-0000-0000-000000000001';
  next();
});
```

⚠️ **Ricorda di rimuoverlo prima di andare in produzione!**

---

## 🎯 Test Checklist

### Backend Running
```bash
# 1. Check backend is running
curl http://localhost:4600/health

# Expected: {"status":"healthy",...}
```

### Frontend Running
```bash
# 2. Check frontend is accessible
curl http://localhost:5600

# Expected: HTML content
```

### API Working
```bash
# 3. Test API with token
curl http://localhost:4600/api/messages \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected: {"messages":[],"total":0}
```

### WebSocket Working
```bash
# 4. Test WebSocket (requires wscat)
npm install -g wscat
wscat -c ws://localhost:4601

# Expected: Connected message
```

---

## 🐛 Troubleshooting

### Errore: CORS

**Problema:** `Access to fetch at 'http://localhost:4600' from origin 'http://localhost:5600' has been blocked by CORS`

**Soluzione:**

Verifica che in `svc-unified-communications/src/index.ts` ci sia:

```typescript
app.use(cors({
  origin: [
    'http://localhost:5600',
    'http://localhost:5601',
    'http://localhost:3100',
    'http://localhost:3200'
  ],
  credentials: true
}));
```

### Errore: 401 Unauthorized

**Problema:** `{"error":{"code":"UNAUTHORIZED","message":"Missing Authorization header"}}`

**Soluzione:** Assicurati di passare il token JWT:

```bash
curl http://localhost:4600/api/messages \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

### Errore: Connection Refused

**Problema:** `curl: (7) Failed to connect to localhost port 4600`

**Soluzione:** Backend non in esecuzione. Avvia:

```bash
cd svc-unified-communications
npm run dev
```

### Errore: Cannot find module

**Problema:** Frontend mostra errori di import

**Soluzione:**

```bash
cd app-unified-communications-client
rm -rf node_modules package-lock.json
npm install
npm run dev
```

---

## 📱 Test via Browser (senza frontend React)

Puoi testare direttamente da browser console:

1. Apri http://localhost:4600/dev (API documentation)
2. Apri Developer Console (F12)
3. Esegui:

```javascript
// Test health check
fetch('http://localhost:4600/health')
  .then(r => r.json())
  .then(console.log);

// Test con token
const token = 'YOUR_JWT_TOKEN';

fetch('http://localhost:4600/api/messages', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
  .then(r => r.json())
  .then(console.log);

// Send message
fetch('http://localhost:4600/api/messages', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    channel_type: 'email',
    from: 'test@example.com',
    to: ['recipient@example.com'],
    subject: 'Test',
    body: 'Hello!'
  })
})
  .then(r => r.json())
  .then(console.log);
```

---

## ✅ Quick Start Summary

**Modo più veloce per testare:**

```bash
# 1. Assicurati backend sia running
cd svc-unified-communications
npm run dev

# 2. In un altro terminale, testa con curl
curl http://localhost:4600/health

# 3. Apri API docs in browser
open http://localhost:4600/dev

# 4. Apri test UI HTML
open /Users/andromeda/dev/ewh/test-communications-ui.html

# 5. (Opzionale) Avvia frontend React
cd app-unified-communications-client
npm install
npm run dev
open http://localhost:5600
```

---

**Created:** 2025-10-14
**Status:** ✅ Ready for Testing
**Type:** Testing Guide
