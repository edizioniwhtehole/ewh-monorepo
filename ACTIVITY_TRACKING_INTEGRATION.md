# Activity Tracking System - Integration Guide

> Guida completa all'integrazione del sistema di activity tracking e monitoraggio dipendenti zero-trust.

## 📋 Indice

1. [Overview](#overview)
2. [Componenti](#componenti)
3. [Flusso Dati](#flusso-dati)
4. [Setup & Deploy](#setup--deploy)
5. [Testing](#testing)

---

## Overview

Sistema completo di **activity tracking** con approccio **zero-trust** per monitoraggio dipendenti trasparente e conforme GDPR.

### Architettura Completa

```
┌─────────────────────────────────────────────────────────────────────┐
│                      EWH Activity Tracking System                    │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  Desktop Agent   │         │   svc-timesheet  │         │ Manager Dashboard│
│ (ewh-work-agent) │────────▶│   Backend API    │◀────────│ (app-admin-      │
│                  │         │                  │         │  console)        │
│  - Electron      │         │  - Fastify       │         │  - Next.js       │
│  - Native APIs   │         │  - PostgreSQL    │         │  - React 18      │
│  - Chromium      │         │  - Redis         │         │                  │
│  - Screenshots   │         │  - OpenAI GPT-4  │         │                  │
└──────────────────┘         └──────────────────┘         └──────────────────┘
        │                             │                             │
        │ Heartbeat 30s              │ RLS Multi-tenant           │ Real-time
        │ App Tracking               │ AI Classification          │ Dashboard
        │ Policy Enforcement         │ Violation Detection        │ Reports
        │                             │                             │
        └─────────────────────────────┴─────────────────────────────┘
                                      │
                              ┌───────▼────────┐
                              │  PostgreSQL    │
                              │  + Redis       │
                              │  + S3 (Wasabi) │
                              └────────────────┘
```

---

## Componenti

### 1. Desktop Agent (ewh-work-agent/)

**Electron app** installata su ogni computer dipendente.

#### Features:
- ⏱️ **Heartbeat ogni 30s** - Invia snapshot attività (app attiva, window title, mouse/key counts)
- 📱 **App Monitoring** - Traccia app aperte su Windows/macOS/Linux (Win32/NSWorkspace/X11)
- 🌐 **Embedded Browser** - Chromium con content filtering e whitelist/blacklist domini
- 🔒 **Policy Enforcer** - Kill automatico processi non autorizzati
- 📸 **Screenshot Capture** - Opzionale, caricamento su S3 per AI Vision
- 🖥️ **UI Dashboard** - React UI per dipendente (trasparenza: vede i propri dati)

#### Files:
```
ewh-work-agent/
├── src/main/
│   ├── index.ts              # Electron main process
│   ├── app-monitor.ts        # Cross-platform app tracking
│   ├── heartbeat-sender.ts   # API client + offline queue
│   ├── browser.ts            # Chromium embedded browser
│   ├── enforcer.ts           # Policy enforcement (kill apps)
│   └── screenshot.ts         # Screenshot capture
├── src/renderer/
│   └── App.tsx               # React UI dashboard
└── package.json
```

#### Heartbeat Payload:
```typescript
{
  user_id: "uuid",
  timestamp: "2025-10-03T10:30:00Z",
  active_app: {
    name: "Google Chrome",
    window_title: "React Tutorial - YouTube",
    executable: "/Applications/Google Chrome.app"
  },
  input_activity: {
    mouse_moves: 42,
    key_presses: 18,
    is_idle: false
  },
  screenshot_s3_url: "s3://bucket/uuid.png" // opzionale
}
```

### 2. Backend (svc-timesheet/)

**Fastify microservice** su porta **4407**.

#### Features:
- 📊 **Activity API** - Ricevi heartbeat, browser history, idle time
- 🤖 **AI Classifier** - 3-level strategy:
  1. **Heuristics** (fast, free) - Keyword matching su titoli/URL
  2. **GPT-4 Vision** (accurate, $$$) - Screenshot analysis
  3. **GPT-4 Text** (fallback) - URL/title classification
- 🔐 **Policy Engine** - Whitelist/blacklist, budget temporali, contextual access
- 🚨 **Violation Detection** - Unauthorized apps, blocked domains, budget exceeded
- 📈 **Reports API** - Individual, team, aggregate reports
- ✅ **GDPR Compliance** - Consent, audit log, data export, retention

#### Files:
```
svc-timesheet/
├── migrations/
│   └── 001_activity_tracking.sql   # Database schema (14 tables + RLS)
├── src/
│   ├── db/
│   │   ├── client.ts               # Multi-tenant context
│   │   └── schema.ts               # TypeScript types
│   ├── services/
│   │   ├── ai-classifier.ts        # OpenAI GPT-4 integration
│   │   └── policy-engine.ts        # Access control logic
│   ├── routes/
│   │   ├── activity.ts             # POST /activity/heartbeat
│   │   ├── policy.ts               # POST /policy/access-request
│   │   └── reports.ts              # GET /reports/individual/:userId
│   └── app.ts                      # Fastify setup
└── package.json
```

#### Key Endpoints:
```
POST   /api/v1/activity/heartbeat           # Desktop agent heartbeat
POST   /api/v1/activity/browser-history     # Browser history batch
GET    /api/v1/reports/individual/:userId   # Individual report
GET    /api/v1/reports/team                 # Team overview
POST   /api/v1/policy/access-request        # Justified access request
GET    /api/v1/policy/budgets               # Check time budgets
GET    /api/v1/policy/violations            # List violations
```

### 3. Manager Dashboard (app-admin-console/)

**Next.js frontend** per manager.

#### Features:
- 📊 **Team Overview** - Real-time status di tutti i dipendenti
- 👤 **Individual Reports** - Dettaglio singolo dipendente con timeline
- 🔐 **Justified Sessions** - Log richieste di accesso con AI relevance score
- 🚨 **Violations Dashboard** - Alert violazioni con severity levels
- 🔄 **Auto-refresh** - Aggiornamento automatico (30s team, 15s violations)

#### Files:
```
app-admin-console/pages/
├── monitoring/
│   ├── index.tsx                    # Team overview
│   ├── individual/[userId].tsx      # Individual report
│   ├── justified-sessions.tsx       # Access requests log
│   ├── violations.tsx               # Violations dashboard
│   └── README.md                    # Documentation
└── api/monitoring/
    ├── team.ts                      # Proxy to svc-timesheet
    ├── stats.ts                     # Team stats
    ├── individual/[userId].ts       # Individual report
    ├── justified-sessions.ts        # Access requests
    └── violations.ts                # Violations
```

#### Routes:
- `/monitoring` - Dashboard principale
- `/monitoring/individual/[userId]` - Report dettagliato
- `/monitoring/justified-sessions` - Richieste di accesso
- `/monitoring/violations` - Violazioni policy

---

## Flusso Dati

### 1. Heartbeat Flow (ogni 30s)

```
Desktop Agent                    Backend                     Database
─────────────                   ─────────                   ─────────
1. Get current app
   (Win32/NSWorkspace)
   │
2. Count mouse/key
   events
   │
3. Optional: capture
   screenshot → S3
   │
4. POST /activity/heartbeat ───▶ 5. Validate JWT
                                    │
                                 6. Set tenant context
                                    │
                                 7. Insert heartbeat ────▶ activity_heartbeats
                                    │
                                 8. Check policy ─────▶ policy_definitions
                                    │                     access_budgets
                                 9. Detect violations
                                    │
                                10. Update session ────▶ work_sessions
                                    │
                                ◀── Response {status, violations}
   │
11. If violations: show warning
```

### 2. Contextual Access Flow

```
Employee                        Backend                     Manager
────────                       ─────────                   ────────
1. Try to access youtube.com
   │
2. Browser checks policy ───▶ 3. GET /policy/check
                                  domain=youtube.com
                              ◀── {allowed: false,
                                   requires_justification: true}
   │
4. Show justification dialog
   │
5. Submit justification ────▶ 6. POST /policy/access-request
   "Need React tutorial"          {domain, reason, justification}
                                  │
                              7. Check budget
                                  │
                              8. Auto-approve or ────────▶ 9. Notify manager
                                 pending approval              (pending approval)
                                  │                             │
                              ◀── {session_id,           ◀──── 10. Manager approves
                                   session_expires_at}
   │
11. Access granted for 2h
    │
12. Page-by-page monitoring
    with AI classification
```

### 3. AI Classification Flow

```
Activity Data                   AI Classifier               Result
─────────────                  ──────────────              ──────
1. Input:
   - Domain: youtube.com
   - URL: /watch?v=abc123
   - Title: "React Hooks Tutorial"
   - Screenshot (optional)
   │
   └─────────────────────────▶ 2. Level 1: Heuristics
                                  - Check keywords in title
                                  - "tutorial", "react" → WORK
                                  - Confidence: 85%
                                  │
                               3. If confidence < 85% →
                                  Level 2: GPT-4 Vision
                                  - Analyze screenshot
                                  - Detect code, diagrams
                                  - Confidence: 92%
                                  │
                               4. If no screenshot →
                                  Level 3: GPT-4 Text
                                  - Analyze URL + title
                                  - Confidence: 75%
                                  │
                               ◀── {is_work_related: true,
                                    confidence: 92,
                                    activity_type: "learning",
                                    reasoning: "..."}
```

### 4. Violation Detection Flow

```
Policy Enforcer (Desktop)       Backend                     Database
─────────────────────────      ─────────                   ─────────
1. Every 10s: check running apps
   │
2. Get all processes
   │
3. Check against whitelist
   │
4. Found: Steam.exe (not in whitelist)
   │
5. Kill process
   │
6. Log violation ───────────▶ 7. POST /policy/violation
                                 {type: "unauthorized_app",
                                  details: {app: "Steam"}}
                                 │
                              8. Insert violation ────▶ policy_violations
                                 │
                              9. Check severity
                                 │
                             10. If critical: notify
                                 manager immediately
```

---

## Setup & Deploy

### 1. Backend (svc-timesheet)

#### Prerequisites:
- Node.js 20+
- PostgreSQL 15+
- Redis 7+
- OpenAI API Key

#### Setup:
```bash
cd svc-timesheet

# Install dependencies
npm install

# Create database
createdb ewh_timesheet

# Run migrations
npm run migrate

# Configure .env
cp .env.example .env
# Edit: DATABASE_URL, REDIS_URL, OPENAI_API_KEY, JWT_SECRET

# Start dev server
npm run dev  # Port 4407
```

#### Deploy (Scalingo):
```bash
# Add Scalingo remote
git remote add scalingo-timesheet git@ssh.osc-fr1.scalingo.com:ewh-svc-timesheet.git

# Deploy
git push scalingo-timesheet main

# Set env vars
scalingo -a ewh-svc-timesheet env-set OPENAI_API_KEY=sk-xxx
scalingo -a ewh-svc-timesheet env-set JWT_SECRET=xxx

# Run migrations
scalingo -a ewh-svc-timesheet run npm run migrate
```

### 2. Desktop Agent (ewh-work-agent)

#### Build:
```bash
cd ewh-work-agent

# Install dependencies
npm install

# Configure
cp .env.example .env
# Edit: API_URL=https://api.polosaas.it/timesheet

# Build for all platforms
npm run build:win   # Windows
npm run build:mac   # macOS
npm run build:linux # Linux
```

#### Distribution:
```bash
# Windows: ewh-work-agent-setup.exe
# macOS: ewh-work-agent.dmg
# Linux: ewh-work-agent.AppImage
```

#### Installation Employee:
1. Download installer per il proprio OS
2. Installare l'app
3. Login con credenziali EWH
4. App parte automaticamente all'avvio sistema
5. Dashboard disponibile dal system tray

### 3. Manager Dashboard (app-admin-console)

#### Setup:
```bash
cd app-admin-console

# Install dependencies
npm install

# Configure .env.local
echo "TIMESHEET_API_URL=http://localhost:4407" > .env.local
# Or production: https://api.polosaas.it/timesheet

# Start dev server
npm run dev  # Port 3000
```

#### Deploy (Vercel/Scalingo):
```bash
# Build
npm run build

# Start production
npm start

# Or deploy to Vercel
vercel deploy --prod
```

---

## Testing

### 1. Backend API Testing

```bash
cd svc-timesheet

# Run tests
npm test

# Test coverage
npm run test:coverage
```

#### Manual Testing:
```bash
# Get JWT token
TOKEN=$(curl -X POST http://localhost:4407/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  | jq -r '.access_token')

# Send heartbeat
curl -X POST http://localhost:4407/api/v1/activity/heartbeat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid",
    "timestamp": "2025-10-03T10:30:00Z",
    "active_app": {
      "name": "Google Chrome",
      "window_title": "React Tutorial"
    },
    "input_activity": {
      "mouse_moves": 42,
      "key_presses": 18
    }
  }'

# Get individual report
curl http://localhost:4407/api/v1/reports/individual/uuid \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Desktop Agent Testing

```bash
cd ewh-work-agent

# Run in dev mode
npm run dev

# Test monitoring
# 1. Apri diverse app
# 2. Controlla che vengano rilevate nella UI
# 3. Verifica heartbeat nel backend (logs)

# Test policy enforcement
# 1. Configura whitelist app
# 2. Apri app non autorizzata
# 3. Verifica che venga chiusa automaticamente
```

### 3. Integration Testing

#### Scenario 1: Unauthorized App
1. Employee apre Steam (non autorizzato)
2. Desktop agent: rileva Steam nei processi
3. Desktop agent: kill Steam
4. Desktop agent: invia violazione al backend
5. Backend: inserisce in policy_violations
6. Manager dashboard: mostra alert real-time

#### Scenario 2: Justified Access
1. Employee prova ad accedere youtube.com
2. Browser: blocca accesso, mostra dialog giustificazione
3. Employee: invia giustificazione "React tutorial"
4. Backend: auto-approva (budget disponibile)
5. Backend: crea session temporanea (2h)
6. Browser: consente accesso con monitoring
7. Backend: AI classifica ogni pagina visitata
8. Manager dashboard: mostra session log con relevance score

#### Scenario 3: Budget Exceeded
1. Employee usa YouTube per 61 minuti (budget: 60 min/day)
2. Backend: rileva budget_exceeded
3. Desktop agent: blocca accesso a YouTube
4. Desktop agent: mostra notifica "Budget giornaliero esaurito"
5. Backend: crea violazione (severity: low)
6. Manager dashboard: mostra violazione

### 4. End-to-End Test

```bash
# 1. Start backend
cd svc-timesheet && npm run dev

# 2. Start frontend
cd app-admin-console && npm run dev

# 3. Start desktop agent
cd ewh-work-agent && npm run dev

# 4. Login as employee
# 5. Usa il computer normalmente per 5 minuti
# 6. Apri /monitoring come manager
# 7. Verifica:
#    - Status online dell'employee
#    - App tracking funziona
#    - Heartbeat ogni 30s
#    - Timeline si aggiorna
```

---

## 🔗 Collegamenti

- **Backend API**: [svc-timesheet/](../svc-timesheet/)
- **Desktop Agent**: [ewh-work-agent/](../ewh-work-agent/)
- **Manager Dashboard**: [app-admin-console/pages/monitoring/](../app-admin-console/pages/monitoring/)
- **Architecture**: [ARCHITECTURE.md](../ARCHITECTURE.md)

---

## 📝 Note Finali

### GDPR Compliance Checklist:
- ✅ Consent management (digital signature)
- ✅ Data access logging (audit trail)
- ✅ Employee data export (JSON/CSV)
- ✅ Data retention (12 mesi max)
- ✅ Right to erasure
- ✅ Trasparenza (employee vede i propri dati)
- ✅ No keylogging (solo key press count)

### Costi Stimati (50 dipendenti):
- **OpenAI API**: ~$150-200/mese (GPT-4 Vision + Text)
- **S3 Storage (Wasabi)**: ~$6/mese (1 TB)
- **PostgreSQL**: Incluso in Scalingo
- **Redis**: Incluso in Scalingo

### Performance:
- **Heartbeat**: 30s interval = 2 req/min/employee = 100 req/min (50 employees)
- **Database**: ~3000 rows/day/employee = 150k rows/day (50 employees)
- **Storage**: ~1 GB/month/employee con screenshot ogni 5 min

---

**Version:** 1.0.0
**Last Updated:** 2025-10-03
**Maintainer:** EWH Platform Team
