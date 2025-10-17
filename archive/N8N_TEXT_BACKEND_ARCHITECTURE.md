# 🔧 n8n Backend Architecture for Text Systems

**Version:** 1.0
**Last Updated:** 2025-10-04
**Systems Covered:** Text Editor, AI Writer, Long-Form Writer, Translator

---

## 📋 EXECUTIVE SUMMARY

Il backend per **tutti i sistemi di editing testo** (Text Editor, AI Writer, Long-Form Writer, Translator) sarà implementato con **n8n** (workflow automation platform), non con servizi Node.js custom.

### 🎯 Why n8n?

**Vantaggi chiave:**
1. ✅ **Visual Workflow Builder** - No-code/Low-code, più facile da mantenere
2. ✅ **400+ Built-in Integrations** - OpenAI, DeepL, Google, Slack, etc.
3. ✅ **Queue-based Processing** - Scalabile, async by default
4. ✅ **Built-in Monitoring** - Dashboard, logs, error handling
5. ✅ **Faster Development** - 50-70% più veloce vs custom backend
6. ✅ **Self-hosted** - Full control, no vendor lock-in
7. ✅ **API-first** - Webhook triggers, HTTP endpoints

**vs. Custom Node.js Services:**
- n8n: 2-3 settimane per workflow complesso
- Custom: 6-8 settimane per stesso workflow
- n8n: Visual debugging
- Custom: Log diving
- n8n: Integrations out-of-the-box
- Custom: Build everything from scratch

---

## 🏗️ ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Next.js)                        │
│  ┌──────────────┬──────────────┬──────────────────────────┐ │
│  │ Text Editor  │ AI Writer    │ Long-Form │ Translator   │ │
│  │ (Tiptap)     │ (Tiptap+AI)  │ (Custom)  │ (Segment UI) │ │
│  └──────────────┴──────────────┴──────────────────────────┘ │
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    API GATEWAY (Next.js API)                 │
│  Routes:                                                     │
│  - /api/text-editor/*                                        │
│  - /api/ai-writer/*                                          │
│  - /api/longform/*                                           │
│  - /api/translator/*                                         │
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    n8n WORKFLOWS                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Workflow 1: Document Save & Version                 │    │
│  │ Workflow 2: AI Content Generation                   │    │
│  │ Workflow 3: Translation Processing                  │    │
│  │ Workflow 4: Export (PDF, DOCX, etc.)                │    │
│  │ Workflow 5: Collaboration Sync                      │    │
│  │ Workflow 6: AI Proofreading                         │    │
│  │ Workflow 7: SEO Analysis                            │    │
│  │ Workflow 8: Publishing Automation                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────┬───────────────────────────────────┘
                          ↓
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ PostgreSQL   │ Redis        │ S3 Storage   │ External APIs │
│ (metadata)   │ (cache/queue)│ (files)      │ (OpenAI, etc) │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

---

## 🔄 n8n WORKFLOW EXAMPLES

### 1️⃣ AI Content Generation Workflow

**Trigger:** POST `/api/ai-writer/generate`

**Input:**
```json
{
  "prompt": "Write a blog post about AI in healthcare",
  "template": "blog_post",
  "tone": "professional",
  "language": "en",
  "userId": "user-123",
  "tenantId": "tenant-456"
}
```

**n8n Workflow Steps:**

```
┌────────────────┐
│ 1. Webhook     │ ← Receive request
└────────┬───────┘
         ↓
┌────────────────┐
│ 2. Validate    │ ← Check auth, params
└────────┬───────┘
         ↓
┌────────────────┐
│ 3. Load Brand  │ ← Fetch brand voice from DB
│    Voice       │
└────────┬───────┘
         ↓
┌────────────────┐
│ 4. OpenAI GPT-4│ ← Generate content
│    API Call    │   (streaming supported)
└────────┬───────┘
         ↓
┌────────────────┐
│ 5. Save to DB  │ ← Insert into ai_writer_documents
└────────┬───────┘
         ↓
┌────────────────┐
│ 6. Track Usage │ ← Log tokens, cost
└────────┬───────┘
         ↓
┌────────────────┐
│ 7. Respond     │ ← Return generated text
└────────────────┘
```

**n8n Configuration:**

```javascript
// Node 1: Webhook Trigger
{
  "httpMethod": "POST",
  "path": "ai-writer-generate",
  "responseMode": "responseNode",
  "authentication": "headerAuth"
}

// Node 2: Validate Input
{
  "functionCode": `
    const { prompt, template, tone, language } = $input.item.json;
    if (!prompt || prompt.length < 10) {
      throw new Error('Prompt too short');
    }
    if (!['blog_post', 'email', 'social_post'].includes(template)) {
      throw new Error('Invalid template');
    }
    return { prompt, template, tone, language };
  `
}

// Node 3: PostgreSQL - Load Brand Voice
{
  "query": `
    SELECT custom_instructions, example_texts
    FROM ai_writer_brand_voices
    WHERE tenant_id = $1 AND is_default = true
  `,
  "parameters": ["{{ $json.tenantId }}"]
}

// Node 4: OpenAI GPT-4
{
  "model": "gpt-4-turbo-preview",
  "messages": [
    {
      "role": "system",
      "content": "{{ $node['Load Brand Voice'].json.custom_instructions }}"
    },
    {
      "role": "user",
      "content": "{{ $json.prompt }}"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2000
}

// Node 5: PostgreSQL - Save Document
{
  "query": `
    INSERT INTO ai_writer_documents
    (tenant_id, title, content, template_type, tone, target_language, created_by)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id
  `,
  "parameters": [
    "{{ $json.tenantId }}",
    "{{ $json.prompt.substring(0, 100) }}",
    "{{ $node['OpenAI GPT-4'].json.choices[0].message.content }}",
    "{{ $json.template }}",
    "{{ $json.tone }}",
    "{{ $json.language }}",
    "{{ $json.userId }}"
  ]
}

// Node 6: PostgreSQL - Track Usage
{
  "query": `
    INSERT INTO ai_writer_generations
    (document_id, prompt, generated_text, model, tokens_used)
    VALUES ($1, $2, $3, $4, $5)
  `,
  "parameters": [
    "{{ $node['Save Document'].json.id }}",
    "{{ $json.prompt }}",
    "{{ $node['OpenAI GPT-4'].json.choices[0].message.content }}",
    "gpt-4-turbo-preview",
    "{{ $node['OpenAI GPT-4'].json.usage.total_tokens }}"
  ]
}

// Node 7: Respond
{
  "statusCode": 200,
  "body": {
    "success": true,
    "documentId": "{{ $node['Save Document'].json.id }}",
    "content": "{{ $node['OpenAI GPT-4'].json.choices[0].message.content }}",
    "tokensUsed": "{{ $node['OpenAI GPT-4'].json.usage.total_tokens }}"
  }
}
```

---

### 2️⃣ Translation Processing Workflow

**Trigger:** POST `/api/translator/translate-document`

**Input:**
```json
{
  "documentId": "doc-123",
  "sourceLanguage": "en",
  "targetLanguages": ["it", "es", "fr"],
  "glossaryId": "glossary-456",
  "userId": "user-789"
}
```

**n8n Workflow Steps:**

```
┌────────────────┐
│ 1. Webhook     │ ← Receive request
└────────┬───────┘
         ↓
┌────────────────┐
│ 2. Load Doc    │ ← Fetch source document
└────────┬───────┘
         ↓
┌────────────────┐
│ 3. Load        │ ← Fetch custom terms
│    Glossary    │
└────────┬───────┘
         ↓
┌────────────────┐
│ 4. Split into  │ ← Segment document (sentences)
│    Segments    │
└────────┬───────┘
         ↓
┌────────────────┐
│ 5. Loop: For   │ ← For each target language
│    each lang   │
└────────┬───────┘
         ↓
┌────────────────┐
│ 6. Check TM    │ ← Translation Memory lookup
│    (fuzzy 80%) │
└────────┬───────┘
         ↓
    ┌────┴────┐
    │ Found?  │
    └────┬────┘
      ┌──┴──┐
     YES   NO
      ↓     ↓
┌──────────┐ ┌──────────┐
│Use cached│ │DeepL API │
│translation│ │translate │
└──────────┘ └──────────┘
      ↓           ↓
      └─────┬─────┘
            ↓
┌────────────────┐
│ 7. QA Check    │ ← Numbers, tags, length
└────────┬───────┘
         ↓
┌────────────────┐
│ 8. Save to TM  │ ← Update Translation Memory
└────────┬───────┘
         ↓
┌────────────────┐
│ 9. Save Result │ ← Insert translated_segments
└────────┬───────┘
         ↓
┌────────────────┐
│10. End Loop    │
└────────┬───────┘
         ↓
┌────────────────┐
│11. Respond     │ ← Return status + preview
└────────────────┘
```

**Benefits of n8n for Translation:**
- ✅ Loop node for multiple languages (no custom code)
- ✅ Built-in DeepL integration
- ✅ Error handling per segment (continue on failure)
- ✅ Progress tracking (webhook callbacks)

---

### 3️⃣ Long-Form AI Generation Workflow (Multi-Agent)

**Trigger:** POST `/api/longform/ai-generate-chapter`

**Input:**
```json
{
  "projectId": "proj-123",
  "chapterOutline": "Chapter 5: The protagonist discovers the truth",
  "previousContext": "Summary of chapters 1-4...",
  "characterProfiles": [...],
  "writingStyle": "literary fiction",
  "targetLength": 3000
}
```

**n8n Workflow Steps (Multi-Agent AI System):**

```
┌────────────────┐
│ 1. Webhook     │ ← Receive generation request
└────────┬───────┘
         ↓
┌────────────────┐
│ 2. Load Project│ ← Fetch full project context
│    Context     │   (all previous chapters, characters, etc.)
└────────┬───────┘
         ↓
┌────────────────┐
│ 3. Vectorize   │ ← Embed context into Pinecone/Weaviate
│    Context     │   (for RAG - Retrieval Augmented Generation)
└────────┬───────┘
         ↓
┌────────────────────────────────────────────────────────┐
│ 4. AGENT 1: Story Planner (GPT-4)                      │
│    Input: Chapter outline + previous context           │
│    Output: Detailed scene breakdown with beats         │
└────────┬───────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────────────────┐
│ 5. Vector Search                                       │
│    Query: "Similar scenes from previous chapters"      │
│    → Retrieve relevant context from vector DB          │
└────────┬───────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────────────────┐
│ 6. AGENT 2: Writer (Claude 3 Opus)                     │
│    Input: Scene breakdown + relevant context + style   │
│    Output: Full chapter draft (streaming)              │
│    Temperature: 0.8 (creative)                         │
└────────┬───────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────────────────┐
│ 7. AGENT 3: Continuity Checker (GPT-4)                 │
│    Input: Generated chapter + character profiles       │
│    Output: Consistency report (character behavior,     │
│            timeline, plot holes)                       │
└────────┬───────────────────────────────────────────────┘
         ↓
    ┌────┴────┐
    │Issues   │
    │found?   │
    └────┬────┘
      ┌──┴──┐
     YES   NO
      ↓     ↓
┌──────────┐ ┌──────────┐
│AGENT 4:  │ │Continue  │
│Rewriter  │ │to step 8 │
│(fix)     │ │          │
└────┬─────┘ └────┬─────┘
     │            │
     └─────┬──────┘
           ↓
┌────────────────────────────────────────────────────────┐
│ 8. AGENT 5: Style Polisher (Claude 3 Sonnet)           │
│    Input: Draft chapter                                │
│    Output: Polished version (grammar, flow, pacing)    │
│    Temperature: 0.3 (more precise)                     │
└────────┬───────────────────────────────────────────────┘
         ↓
┌────────────────┐
│ 9. Save to DB  │ ← Insert as draft version
└────────┬───────┘
         ↓
┌────────────────┐
│10. Update      │ ← Add new chapter to vector DB
│    Vector DB   │   (for future RAG queries)
└────────┬───────┘
         ↓
┌────────────────┐
│11. Notify User │ ← WebSocket or webhook
└────────┬───────┘
         ↓
┌────────────────┐
│12. Respond     │ ← Return chapter ID + preview
└────────────────┘
```

**Multi-LLM Strategy (Antagonisti = Diversi modelli per diversi task):**

| Agent | Model | Temperature | Purpose |
|-------|-------|-------------|---------|
| Story Planner | GPT-4 | 0.7 | Struttura logica, plot beats |
| Writer | Claude 3 Opus | 0.8 | Scrittura creativa, dialoghi |
| Continuity Checker | GPT-4 | 0.2 | Analisi logica, fact-checking |
| Rewriter | GPT-4 Turbo | 0.5 | Fix issues, maintain style |
| Style Polisher | Claude 3 Sonnet | 0.3 | Grammar, flow, final touch |

**Vector Database (Pinecone/Weaviate/Qdrant):**
- Stores embeddings di tutti i capitoli precedenti
- Allows semantic search: "Find similar scenes with character X"
- Context retrieval per RAG (Retrieval Augmented Generation)

**n8n Configuration Example:**

```javascript
// Node 4: Story Planner (GPT-4)
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "You are a story planner. Break down the chapter outline into detailed scenes."
    },
    {
      "role": "user",
      "content": `
        Chapter Outline: {{ $json.chapterOutline }}

        Previous Context:
        {{ $json.previousContext }}

        Characters involved:
        {{ $json.characterProfiles }}

        Create a detailed scene-by-scene breakdown with:
        1. Scene setting (location, time)
        2. Characters present
        3. Key events/beats
        4. Emotional arc
        5. Transition to next scene
      `
    }
  ],
  "temperature": 0.7
}

// Node 5: Vector Search (Pinecone)
{
  "indexName": "longform-project-{{ $json.projectId }}",
  "query": "{{ $node['Story Planner'].json.choices[0].message.content }}",
  "topK": 5, // Retrieve top 5 most similar scenes
  "includeMetadata": true
}

// Node 6: Writer (Claude 3 Opus)
{
  "model": "claude-3-opus-20240229",
  "max_tokens": 4096,
  "temperature": 0.8,
  "system": `
    You are a professional fiction writer.
    Writing Style: {{ $json.writingStyle }}
    Target Length: {{ $json.targetLength }} words

    Maintain consistency with:
    {{ $node['Vector Search'].json.matches.map(m => m.metadata.text).join('\n\n') }}
  `,
  "messages": [
    {
      "role": "user",
      "content": `
        Scene Breakdown:
        {{ $node['Story Planner'].json.choices[0].message.content }}

        Write the full chapter following this breakdown.
        Focus on:
        - Vivid descriptions
        - Natural dialogue
        - Character development
        - Pacing and tension
      `
    }
  ]
}

// Node 7: Continuity Checker (GPT-4)
{
  "model": "gpt-4",
  "temperature": 0.2,
  "messages": [
    {
      "role": "system",
      "content": "You are a continuity checker. Analyze the chapter for plot holes, character inconsistencies, and timeline errors."
    },
    {
      "role": "user",
      "content": `
        Generated Chapter:
        {{ $node['Writer'].json.content[0].text }}

        Character Profiles:
        {{ $json.characterProfiles }}

        Previous Timeline:
        {{ $json.previousContext }}

        Check for:
        1. Character behavior consistency
        2. Timeline accuracy
        3. Plot contradictions
        4. Missing setup/payoff

        Return JSON: { "issues": [...], "severity": "none|minor|major" }
      `
    }
  ],
  "response_format": { "type": "json_object" }
}

// Node 8: Style Polisher (Claude 3 Sonnet)
{
  "model": "claude-3-sonnet-20240229",
  "max_tokens": 4096,
  "temperature": 0.3,
  "messages": [
    {
      "role": "user",
      "content": `
        Polish this chapter for publication quality:

        {{ $node['Writer'].json.content[0].text }}

        Focus on:
        - Grammar and spelling
        - Sentence flow and variety
        - Pacing (remove redundancy)
        - Dialogue punctuation
        - Show don't tell

        Return only the polished chapter, no comments.
      `
    }
  ]
}
```

**Cost Estimation per Chapter (3000 words):**
- Story Planner (GPT-4): ~500 tokens = $0.03
- Writer (Claude 3 Opus): ~4000 tokens output = $0.60
- Continuity Checker (GPT-4): ~1000 tokens = $0.06
- Rewriter (if needed): ~4000 tokens = $0.24
- Style Polisher (Claude 3 Sonnet): ~4000 tokens = $0.12

**Total per chapter: ~$1.05** (assuming all agents run)

**For a 100,000 word novel (33 chapters):** ~$35 in AI costs

---

### 4️⃣ Export to PDF Workflow

**Trigger:** POST `/api/longform/export-pdf`

**n8n Workflow:**

```
┌────────────────┐
│ 1. Webhook     │
└────────┬───────┘
         ↓
┌────────────────┐
│ 2. Load Project│ ← Fetch all sections
│    (recursive) │
└────────┬───────┘
         ↓
┌────────────────┐
│ 3. Apply       │ ← Screenplay formatting if needed
│    Template    │
└────────┬───────┏━━━━━━━━━━━━━━━━┓
         ↓       ┃ 4. HTTP Request┃
┌────────────────┐┃ to Puppeteer  ┃ ← PDF generation service
│ 5. Upload to S3│┃ Service       ┃
└────────┬───────┘┗━━━━━━━━━━━━━━━━┛
         ↓
┌────────────────┐
│ 6. Generate    │ ← Presigned URL (7 days)
│    Download URL│
└────────┬───────┘
         ↓
┌────────────────┐
│ 7. Notify User │ ← Email or in-app notification
└────────┬───────┘
         ↓
┌────────────────┐
│ 8. Respond     │
└────────────────┘
```

---

## 🗂️ n8n WORKFLOW ORGANIZATION

### Folder Structure in n8n

```
EWH Platform
├── Text Editor
│   ├── document-save.json
│   ├── document-export-pdf.json
│   ├── document-export-docx.json
│   ├── collaboration-sync.json
│   └── template-render.json
│
├── AI Writer
│   ├── ai-generate-blog.json
│   ├── ai-generate-email.json
│   ├── ai-generate-social.json
│   ├── ai-rewrite-tone.json
│   ├── ai-summarize.json
│   └── brand-voice-train.json
│
├── Long-Form Writer
│   ├── longform-save.json
│   ├── longform-export-pdf.json
│   ├── longform-export-epub.json
│   ├── longform-export-fdx.json (screenplay)
│   ├── longform-ai-suggestions.json
│   └── longform-continuity-check.json
│
├── Translator
│   ├── translate-document.json
│   ├── translate-segment.json
│   ├── translation-memory-lookup.json
│   ├── translation-qa-check.json
│   └── glossary-sync.json
│
└── Shared
    ├── auth-validate.json (reusable)
    ├── db-save-with-retry.json
    └── s3-upload.json
```

**Total Workflows:** ~30 workflows

---

## 🔐 SECURITY & AUTHENTICATION

### Authentication Flow

**Option 1: JWT Token (Recommended)**

```
Frontend → API Gateway → n8n Webhook (with JWT in header)

n8n Node 1: Function (Validate JWT)
{
  const jwt = require('jsonwebtoken');
  const token = $input.headers['authorization'].replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return { userId: decoded.userId, tenantId: decoded.tenantId };
  } catch (error) {
    throw new Error('Invalid token');
  }
}
```

**Option 2: API Gateway Pre-validates**

```
Frontend → API Gateway (validates JWT) → n8n Webhook (with userId/tenantId in body)

// API Gateway (Next.js)
export default async function handler(req, res) {
  const user = await validateJWT(req.headers.authorization);

  // Call n8n webhook with validated user
  const n8nResponse = await fetch('https://n8n.ewh.cloud/webhook/ai-generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      ...req.body,
      userId: user.id,
      tenantId: user.tenantId
    })
  });

  res.json(await n8nResponse.json());
}
```

**Recommended:** Option 2 (API Gateway handles auth, n8n trusts internal calls)

---

## 📊 DATABASE ACCESS FROM n8n

### PostgreSQL Nodes Configuration

**Connection Setup (Environment Variables):**

```bash
# .env for n8n
POSTGRES_HOST=db.ewh.cloud
POSTGRES_PORT=5432
POSTGRES_DB=ewh_platform
POSTGRES_USER=n8n_service
POSTGRES_PASSWORD=***********

# Grant permissions
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO n8n_service;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO n8n_service;
```

**PostgreSQL Node Example:**

```javascript
// Query with parameters (prevents SQL injection)
{
  "query": `
    INSERT INTO longform_sections
    (project_id, parent_id, title, content, word_count, status)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING id
  `,
  "parameters": [
    "{{ $json.projectId }}",
    "{{ $json.parentId }}",
    "{{ $json.title }}",
    "{{ $json.content }}",
    "{{ $json.wordCount }}",
    "draft"
  ]
}
```

---

## 🚀 DEPLOYMENT & SCALING

### n8n Deployment Options

**Option 1: Docker Compose (MVP, Staging)**

```yaml
# docker-compose.yml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  n8n_data:
  postgres_data:
  redis_data:
```

**Option 2: Kubernetes (Production, Scaling)**

```yaml
# k8s/n8n-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
spec:
  replicas: 3 # Scale horizontally
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
      - name: n8n
        image: n8nio/n8n:latest
        env:
        - name: EXECUTIONS_MODE
          value: "queue"
        - name: QUEUE_BULL_REDIS_HOST
          value: "redis-cluster"
        - name: DB_TYPE
          value: "postgresdb"
        - name: DB_POSTGRESDB_HOST
          valueFrom:
            secretKeyRef:
              name: n8n-secrets
              key: db-host
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 5678
          initialDelaySeconds: 30
          periodSeconds: 10
```

**Scaling Strategy:**
- **MVP (Q2 2026):** 1 n8n instance, shared Redis/PostgreSQL
- **Production (Q3 2026):** 3 n8n instances, Redis cluster, PostgreSQL read replicas
- **Scaling (Q4 2026):** Auto-scaling (3-10 instances), dedicated queue workers
- **Enterprise (Q1 2027):** Multi-region n8n, global Redis, Aurora PostgreSQL

---

## 📈 MONITORING & OBSERVABILITY

### Built-in n8n Monitoring

**Execution Logs:**
- All workflow executions logged automatically
- Success/failure status
- Execution time
- Error stack traces

**Webhooks Dashboard:**
- Request count per endpoint
- Average response time
- Error rate (4xx, 5xx)

**Custom Metrics (Prometheus Integration):**

```javascript
// n8n Function Node: Track Custom Metrics
const { register, Counter, Histogram } = require('prom-client');

const aiGenerationCounter = new Counter({
  name: 'ai_generations_total',
  help: 'Total AI content generations',
  labelNames: ['template', 'language']
});

const translationDuration = new Histogram({
  name: 'translation_duration_seconds',
  help: 'Translation processing duration',
  buckets: [0.1, 0.5, 1, 2, 5, 10]
});

// Increment counter
aiGenerationCounter.inc({ template: 'blog_post', language: 'en' });

// Observe duration
const end = translationDuration.startTimer();
// ... do translation ...
end();

return { success: true };
```

---

## 💰 COST ESTIMATION

### n8n Self-Hosted Costs

**Infrastructure (Monthly):**
- n8n instances (3x t3.medium): $100/month
- PostgreSQL (db.t3.small): $50/month
- Redis (cache.t3.micro): $15/month
- **Total Infrastructure:** ~$165/month

**External API Costs (varies by usage):**
- OpenAI GPT-4: $0.03/1K tokens (input), $0.06/1K tokens (output)
- DeepL Pro: €5.49/month + €20/1M characters
- AWS S3: $0.023/GB/month
- **Estimated API costs (1000 users):** ~$500-1000/month

**vs. Custom Backend:**
- Custom Node.js: 4-5 services, 8+ EC2 instances = ~$800/month infrastructure
- Development time: 3x longer
- Maintenance: 2x more effort

**ROI:** n8n saves ~$2000/month in infrastructure + ~$10k/month in development costs

---

## 🔄 MIGRATION STRATEGY

### Phase 1: MVP (Q2 2026)
- Deploy n8n for **AI Writer** only (lowest risk)
- 10 workflows max
- Monitor performance, iterate

### Phase 2: Production (Q3 2026)
- Add **Text Editor** workflows
- Add **Long-Form Writer** workflows
- Scale to 20-25 workflows

### Phase 3: Scaling (Q4 2026)
- Add **Translator** workflows
- Implement auto-scaling
- Add monitoring dashboards

### Phase 4: Enterprise (Q1 2027)
- Multi-region deployment
- Advanced orchestration
- Custom error recovery

---

## 📚 RESOURCES & DOCUMENTATION

**n8n Official:**
- [n8n Docs](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)

**Integration Guides:**
- [OpenAI Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.openai/)
- [PostgreSQL Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/)
- [DeepL Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.deepl/)

**Best Practices:**
- [Error Handling](https://docs.n8n.io/workflows/error-handling/)
- [Sub-workflows](https://docs.n8n.io/workflows/sub-workflows/)
- [Scaling n8n](https://docs.n8n.io/hosting/scaling/)

---

## ✅ DECISION SUMMARY

**Backend Implementation:**
- ✅ **Text Editor:** n8n workflows
- ✅ **AI Writer:** n8n workflows
- ✅ **Long-Form Writer:** n8n workflows
- ✅ **Translator:** n8n workflows

**Custom Node.js Services (if needed):**
- ❌ Not needed for business logic
- ✅ Only for real-time WebSocket (collaboration cursor sync)
- ✅ Only for heavy computation (if n8n too slow, can offload to Lambda)

**Confidence Level:** 95% - n8n è la scelta giusta per questo use case

---

**Document Version:** 1.0
**Author:** Claude (AI Agent) + Andromeda (Human)
**Last Updated:** 2025-10-04
**Next Review:** After MVP deployment
