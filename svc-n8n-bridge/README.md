# n8n Bridge Service - Request/Response Correlation

## 🎯 Problema

Quando usi n8n per workflow esterni (AI, API terze parti), come garantire che la risposta sia matchata alla richiesta originale del tenant corretto?

## ✅ Soluzione: Correlation ID Bridge

Questo servizio fa da ponte tra frontend EWH e n8n, garantendo:
- **Correlation ID tracking** - match request → response
- **Tenant isolation** - risposta va solo al tenant che ha fatto la richiesta
- **Polling & WebSocket** - client può scegliere come ricevere risultati

## 🏗️ Architettura

```
Frontend (Tenant A)
    ↓ POST /workflows/ai-form/execute
svc-n8n-bridge
    ├─→ Genera correlation_id: abc-123
    ├─→ Salva in Redis: {tenant_id, user_id, status: "pending"}
    └─→ Forward a n8n con correlation_id
              ↓
         n8n Workflow
              ├─→ Chiama OpenAI API
              ├─→ Processa risposta
              └─→ POST /workflows/results/abc-123 (risultato)
                      ↓
              svc-n8n-bridge
                      ├─→ Salva risultato in Redis
                      ├─→ Pubblica evento WebSocket
                      └─→ Client riceve notifica
```

## 🚀 Quick Start

### 1. Installa dipendenze

```bash
cd svc-n8n-bridge
npm install
```

### 2. Configura environment

```env
PORT=5680
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
```

### 3. Avvia servizio

```bash
npm run dev
```

## 📝 Uso dal Frontend

### Opzione 1: Polling (Semplice)

```typescript
// 1. Invia richiesta
const response = await fetch('http://localhost:5680/workflows/ai-form-process/execute', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    form_data: {
      question: "Scrivi un post LinkedIn sul machine learning",
      tone: "professional",
      length: "medium"
    }
  })
});

const { correlation_id, poll_url } = await response.json();
// correlation_id: "abc-123-def-456"

// 2. Poll per risultato
const pollForResult = async () => {
  const result = await fetch(`http://localhost:5680${poll_url}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });

  if (result.status === 200) {
    const data = await result.json();

    if (data.status === 'completed') {
      console.log('✅ Result:', data.result);
      return data.result;
    } else if (data.status === 'processing') {
      // Riprova tra 2 secondi
      setTimeout(pollForResult, 2000);
    } else if (data.status === 'failed') {
      console.error('❌ Error:', data.error);
    }
  }
};

pollForResult();
```

### Opzione 2: WebSocket (Real-time)

```typescript
import { io } from 'socket.io-client';

// 1. Connetti a WebSocket
const socket = io('http://localhost:5680');

// 2. Invia richiesta
const response = await fetch('http://localhost:5680/workflows/ai-form-process/execute', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ form_data: {...} })
});

const { correlation_id } = await response.json();

// 3. Subscribe per risultato
socket.emit('subscribe', correlation_id);

socket.on('result', (data) => {
  if (data.correlation_id === correlation_id) {
    console.log('✅ Result received:', data.result);
    // Mostra risultato all'utente
    showResult(data.result);
  }
});
```

## 🔧 Configurare n8n Workflow

### Workflow n8n: "AI Form Processor"

**1. Webhook Trigger**
```
URL: http://localhost:5678/webhook/ai-form-process
Method: POST
```

**2. Set Headers Node**
- Estrae `X-Correlation-ID` dal header
- Estrae `X-Tenant-ID` dal header

**3. OpenAI Node**
```javascript
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "user",
      "content": "{{$json.form_data.question}}"
    }
  ]
}
```

**4. HTTP Request Node - Save Result**
```
URL: http://localhost:5680/workflows/results/{{$node["Webhook"].json["headers"]["x-correlation-id"]}}
Method: POST
Body:
{
  "result": "{{$json.choices[0].message.content}}",
  "status": "completed"
}
```

### Esempio Workflow Completo (JSON)

```json
{
  "name": "AI Form Processor",
  "nodes": [
    {
      "parameters": {
        "path": "ai-form-process",
        "responseMode": "lastNode"
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300]
    },
    {
      "parameters": {
        "model": "gpt-4",
        "messages": {
          "values": [
            {
              "role": "user",
              "content": "={{$json.form_data.question}}"
            }
          ]
        }
      },
      "name": "OpenAI",
      "type": "@n8n/n8n-nodes-langchain.openAi",
      "position": [450, 300]
    },
    {
      "parameters": {
        "url": "=http://localhost:5680/workflows/results/{{$node[\"Webhook\"].json[\"correlation_id\"]}}",
        "method": "POST",
        "jsonParameters": true,
        "options": {},
        "bodyParametersJson": "={\n  \"result\": {{$json.choices[0].message.content}},\n  \"status\": \"completed\"\n}"
      },
      "name": "Save Result",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 300]
    }
  ]
}
```

## 🔐 Tenant Isolation

Il bridge garantisce tenant isolation in 3 modi:

### 1. JWT Validation
```typescript
// Bridge valida JWT e estrae tenant_id
const token = req.headers.authorization?.split(' ')[1];
const decoded = jwt.verify(token, publicKey);
const tenant_id = decoded.org_id;
```

### 2. Correlation ID Storage
```typescript
// Salva tenant_id con correlation_id
await redis.set(`correlation:${correlationId}`, JSON.stringify({
  tenant_id,
  user_id,
  // ...
}));
```

### 3. Result Access Check
```typescript
// Solo il tenant owner può vedere risultato
app.get('/workflows/results/:correlation_id', (req, res) => {
  const context = await redis.get(`correlation:${req.params.correlation_id}`);

  if (context.tenant_id !== req.tenant_id) {
    return res.status(403).json({ error: 'Access denied' });
  }

  // ✅ Tenant verified, return result
  res.json(context.result);
});
```

## 📊 Monitoring

### Check Pending Workflows

```bash
curl http://localhost:5680/workflows/stats
```

Response:
```json
{
  "total_pending": 5,
  "total_processing": 12,
  "total_completed": 342,
  "average_duration_ms": 2500
}
```

### Workflow Execution History

```bash
curl http://localhost:5680/workflows/history \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
[
  {
    "correlation_id": "abc-123",
    "workflow_name": "ai-form-process",
    "status": "completed",
    "duration_ms": 2300,
    "created_at": "2025-10-13T00:00:00Z"
  }
]
```

## 🎓 Best Practices

### 1. Timeout Handling

```typescript
const pollForResult = async (correlationId: string, maxAttempts = 30) => {
  for (let i = 0; i < maxAttempts; i++) {
    const result = await fetch(`/workflows/results/${correlationId}`);
    const data = await result.json();

    if (data.status === 'completed') return data.result;
    if (data.status === 'failed') throw new Error(data.error);

    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  throw new Error('Workflow timeout after 60 seconds');
};
```

### 2. Error Handling in n8n

Aggiungi nodo "Error Handler" nel workflow:

```
On Error → HTTP Request → Save Error Result
URL: http://localhost:5680/workflows/results/{{correlation_id}}
Body: { "status": "failed", "error": "{{$json.message}}" }
```

### 3. Progress Updates

Per workflow lunghi, n8n può inviare update intermedi:

```javascript
// Step 1 completato
await fetch(`http://localhost:5680/workflows/results/${correlationId}`, {
  method: 'POST',
  body: JSON.stringify({
    status: 'processing',
    progress: 33,
    message: 'Step 1 completed'
  })
});
```

Client riceve:
```json
{
  "status": "processing",
  "progress": 33,
  "message": "Step 1 completed"
}
```

## 🚦 Rate Limiting

Per evitare abusi, implementa rate limiting per tenant:

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: 10, // max 10 richieste per minuto per tenant
  keyGenerator: (req) => (req as any).tenant_id,
  message: 'Too many requests from this tenant'
});

app.post('/workflows/:workflow_name/execute', limiter, ...);
```

## 📚 API Reference

### POST /workflows/:workflow_name/execute
Esegue workflow n8n

**Headers:**
- `Authorization: Bearer <jwt>`

**Body:**
```json
{
  "form_data": {
    "question": "...",
    "context": "..."
  }
}
```

**Response:**
```json
{
  "correlation_id": "uuid",
  "status": "processing",
  "poll_url": "/workflows/results/uuid"
}
```

### GET /workflows/results/:correlation_id
Recupera risultato workflow

**Headers:**
- `Authorization: Bearer <jwt>`

**Response:**
```json
{
  "correlation_id": "uuid",
  "status": "completed|processing|failed",
  "result": {...},
  "error": "...",
  "created_at": "timestamp",
  "completed_at": "timestamp"
}
```

### POST /workflows/results/:correlation_id
Usato da n8n per salvare risultato

**Body:**
```json
{
  "result": {...},
  "status": "completed|failed",
  "error": "..."
}
```

## 🔄 Workflow Examples

### Example 1: AI Content Generation

```typescript
const result = await executeWorkflow('ai-content-generation', {
  prompt: "Write a blog post about AI",
  tone: "professional",
  length: 500
});
// result: { content: "AI has revolutionized..." }
```

### Example 2: Email Processing

```typescript
const result = await executeWorkflow('email-classification', {
  email_body: "...",
  email_subject: "..."
});
// result: { category: "support", priority: "high", sentiment: "negative" }
```

### Example 3: Image Analysis

```typescript
const result = await executeWorkflow('image-analysis', {
  image_url: "https://..."
});
// result: { objects: ["person", "car"], colors: ["blue", "red"], text: "..." }
```
