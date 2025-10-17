# Separated Apps Architecture - Communications & CRM Ecosystem

## 🎯 Overview

Invece di un'unica app di comunicazioni, creiamo **app separate e specializzate** per ogni funzionalità principale:

1. **Email Client** - Gestione inbox/invio email standard
2. **Cold Email** - Campagne cold email con rotazione domini
3. **Newsletter** - Gestione newsletter e mailing list
4. **SMS Client** - Invio e gestione SMS
5. **CRM** - Customer Relationship Management completo
6. **Support/Tickets** - Gestione ticket di supporto (opzionale)

---

## 📦 Apps & Services Schema

### 1. Email Client (Inbox & Composer)

**Frontend:**
- **app-email-client** (Port 5600)
- Features: Inbox unificata, compose email, folders, search
- Tech: React + TypeScript

**Backend:**
- **svc-email-client** (Port 4600)
- Features: CRUD messages, Gmail/Outlook sync, attachments
- Tech: Node.js + Express

**Integrazione:**
- SendGrid per invio
- Gmail API / Outlook API per ricezione
- IMAP fallback

---

### 2. Cold Email Campaigns

**Frontend:**
- **app-cold-email** (Port 5610)
- Features: Campaign builder, sequence editor, analytics
- Tech: React + TypeScript

**Backend:**
- **svc-cold-email** (Port 4610)
- Features: Campaign engine, domain rotation, warmup automation
- Tech: Node.js + Express + Bull queues

**Features Specifiche:**
- Domain/account rotation
- IP warmup automation
- A/B testing
- Deliverability tracking
- Bounce handling

---

### 3. Newsletter Management

**Frontend:**
- **app-newsletter** (Port 5620)
- Features: Newsletter editor, subscriber lists, templates
- Tech: React + TypeScript + Email template builder

**Backend:**
- **svc-newsletter** (Port 4620)
- Features: Subscriber management, send engine, analytics
- Tech: Node.js + Express

**Features Specifiche:**
- Subscriber list segmentation
- Template library
- Scheduled sends
- Unsubscribe management
- Open/click tracking

---

### 4. SMS Client

**Frontend:**
- **app-sms-client** (Port 5630)
- Features: SMS composer, conversation view, bulk send
- Tech: React + TypeScript

**Backend:**
- **svc-sms-client** (Port 4630)
- Features: Twilio integration, SMS campaigns
- Tech: Node.js + Express

**Features Specifiche:**
- Twilio integration
- Character count (160 limit)
- International support
- Delivery receipts

---

### 5. CRM (Customer Relationship Management)

**Frontend:**
- **app-crm** (Port 5640)
- Features: Contacts, deals, pipeline, activities, reports
- Tech: React + TypeScript

**Backend:**
- **svc-crm-advanced** (Port 4640)
- Features: Full CRM logic, lead scoring, automation
- Tech: Node.js + Express

**Features Specifiche:**
- Contact/company management
- Deal pipeline
- Lead scoring
- Workflow automation
- Reporting & analytics

---

### 6. Support/Tickets (Opzionale)

**Frontend:**
- **app-support** (Port 5650)
- Features: Ticket management, knowledge base
- Tech: React + TypeScript

**Backend:**
- **svc-support** (Port 4650) - (⚠️ Esiste già come 4401!)
- Features: Ticket routing, SLA tracking
- Tech: Node.js + Express

---

## 📊 Complete Port Allocation

### Backend Services (46xx range)

| Service | Port HTTP | Port WS | Description |
|---------|-----------|---------|-------------|
| **svc-email-client** | 4600 | 4601 | Email inbox & composer |
| **svc-cold-email** | 4610 | 4611 | Cold email campaigns |
| **svc-newsletter** | 4620 | 4621 | Newsletter management |
| **svc-sms-client** | 4630 | 4631 | SMS management |
| **svc-crm-advanced** | 4640 | 4641 | CRM system |
| **svc-support-advanced** | 4650 | 4651 | Support tickets (opzionale) |

### Frontend Apps (56xx range)

| App | Port | Description |
|-----|------|-------------|
| **app-email-client** | 5600 | Email client UI |
| **app-cold-email** | 5610 | Cold email campaigns UI |
| **app-newsletter** | 5620 | Newsletter UI |
| **app-sms-client** | 5630 | SMS UI |
| **app-crm** | 5640 | CRM UI |
| **app-support** | 5650 | Support UI (opzionale) |

---

## 🏗️ Directory Structure

```
/Users/andromeda/dev/ewh/
│
├── svc-email-client/              # Backend: Email inbox/composer
│   ├── package.json
│   ├── src/
│   │   ├── index.ts              # Port 4600
│   │   ├── routes/
│   │   │   ├── messages.ts
│   │   │   ├── folders.ts
│   │   │   ├── attachments.ts
│   │   │   └── accounts.ts       # Gmail/Outlook OAuth
│   │   ├── services/
│   │   │   ├── gmail-sync.ts
│   │   │   ├── outlook-sync.ts
│   │   │   └── sendgrid.ts
│   │   └── config/
│   └── .env (PORT=4600, WS_PORT=4601)
│
├── app-email-client/              # Frontend: Email UI
│   ├── package.json
│   ├── src/
│   │   ├── features/
│   │   │   ├── inbox/
│   │   │   ├── compose/
│   │   │   └── settings/
│   │   └── components/
│   └── vite.config.ts (port: 5600)
│
├── svc-cold-email/                # Backend: Cold email campaigns
│   ├── package.json
│   ├── src/
│   │   ├── index.ts              # Port 4610
│   │   ├── routes/
│   │   │   ├── campaigns.ts
│   │   │   ├── sequences.ts
│   │   │   └── analytics.ts
│   │   ├── services/
│   │   │   ├── campaign-engine.ts
│   │   │   ├── domain-rotation.ts
│   │   │   └── warmup.ts
│   │   └── jobs/
│   │       └── send-queue.ts
│   └── .env (PORT=4610, WS_PORT=4611)
│
├── app-cold-email/                # Frontend: Cold email UI
│   ├── package.json
│   ├── src/
│   │   ├── features/
│   │   │   ├── campaigns/
│   │   │   ├── sequences/
│   │   │   ├── analytics/
│   │   │   └── accounts/
│   │   └── components/
│   └── vite.config.ts (port: 5610)
│
├── svc-newsletter/                # Backend: Newsletter
│   ├── package.json
│   ├── src/
│   │   ├── index.ts              # Port 4620
│   │   ├── routes/
│   │   │   ├── newsletters.ts
│   │   │   ├── subscribers.ts
│   │   │   └── templates.ts
│   │   └── services/
│   │       └── send-engine.ts
│   └── .env (PORT=4620, WS_PORT=4621)
│
├── app-newsletter/                # Frontend: Newsletter UI
│   ├── package.json
│   ├── src/
│   │   ├── features/
│   │   │   ├── editor/
│   │   │   ├── subscribers/
│   │   │   └── templates/
│   │   └── components/
│   └── vite.config.ts (port: 5620)
│
├── svc-sms-client/                # Backend: SMS
│   ├── package.json
│   ├── src/
│   │   ├── index.ts              # Port 4630
│   │   ├── routes/
│   │   │   └── sms.ts
│   │   └── services/
│   │       └── twilio.ts
│   └── .env (PORT=4630, WS_PORT=4631)
│
├── app-sms-client/                # Frontend: SMS UI
│   ├── package.json
│   ├── src/
│   │   ├── features/
│   │   │   ├── conversations/
│   │   │   ├── compose/
│   │   │   └── bulk-send/
│   │   └── components/
│   └── vite.config.ts (port: 5630)
│
├── svc-crm-advanced/              # Backend: CRM
│   ├── package.json
│   ├── src/
│   │   ├── index.ts              # Port 4640
│   │   ├── routes/
│   │   │   ├── contacts.ts
│   │   │   ├── companies.ts
│   │   │   ├── deals.ts
│   │   │   ├── activities.ts
│   │   │   ├── pipelines.ts
│   │   │   └── reports.ts
│   │   ├── services/
│   │   │   ├── scoring.ts
│   │   │   └── automation.ts
│   │   └── jobs/
│   └── .env (PORT=4640, WS_PORT=4641)
│
└── app-crm/                       # Frontend: CRM UI
    ├── package.json
    ├── src/
    │   ├── features/
    │   │   ├── dashboard/
    │   │   ├── contacts/
    │   │   ├── deals/
    │   │   ├── pipeline/
    │   │   └── reports/
    │   └── components/
    └── vite.config.ts (port: 5640)
```

---

## 🔗 Integration Between Apps

### Data Sharing

**Esempio: Email Client → CRM**

```typescript
// In svc-email-client quando email inviata:
await axios.post('http://localhost:4640/api/integrations/email-sent', {
  contact_email: 'john@acme.com',
  subject: 'Proposal',
  timestamp: new Date()
});

// svc-crm-advanced riceve e:
// - Trova/crea contatto
// - Aggiorna last_contacted_at
// - Crea activity log
// - Calcola lead score
```

**Esempio: Cold Email → CRM**

```typescript
// svc-cold-email quando recipient risponde:
await axios.post('http://localhost:4640/api/integrations/campaign-reply', {
  campaign_id: 'uuid',
  recipient_email: 'john@acme.com',
  replied: true
});

// svc-crm-advanced:
// - Aumenta lead score (+30 punti)
// - Cambia lifecycle stage (lead → mql)
// - Trigger workflow (assegna a sales rep)
```

---

## 🗄️ Database Schema

### Shared Tables (in main `ewh` database)

```sql
-- Contacts (shared by all apps)
CREATE TABLE contacts (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  email VARCHAR(500),
  phone VARCHAR(50),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  -- ... altri campi
);

-- Messages (unified log of all communications)
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  channel VARCHAR(20), -- email, sms, whatsapp
  source_app VARCHAR(50), -- 'email-client', 'cold-email', 'newsletter'
  from_address VARCHAR(500),
  to_address VARCHAR(500),
  subject VARCHAR(1000),
  body TEXT,
  sent_at TIMESTAMPTZ,
  contact_id UUID REFERENCES contacts(id)
);
```

### App-Specific Tables

**svc-email-client:**
- `email_folders`
- `email_labels`
- `email_accounts` (Gmail/Outlook connections)

**svc-cold-email:**
- `cold_campaigns`
- `cold_sequences`
- `cold_recipients`
- `sending_accounts` (for rotation)

**svc-newsletter:**
- `newsletters`
- `subscriber_lists`
- `newsletter_templates`
- `subscriber_segments`

**svc-crm-advanced:**
- `crm_contacts`
- `crm_companies`
- `crm_deals`
- `crm_activities`
- `crm_pipelines`

---

## 🚀 API Gateway Routing

Aggiungi a `svc-api-gateway` (Port 4000):

```typescript
// svc-api-gateway/routes.ts
{
  '/email': {
    target: 'http://localhost:4600',
    auth: true
  },
  '/cold-email': {
    target: 'http://localhost:4610',
    auth: true
  },
  '/newsletter': {
    target: 'http://localhost:4620',
    auth: true
  },
  '/sms': {
    target: 'http://localhost:4630',
    auth: true
  },
  '/crm': {
    target: 'http://localhost:4640',
    auth: true
  }
}
```

---

## 🎨 UI Navigation

### App Shell (app-shell-frontend)

Menu principale che permette di navigare tra le app:

```tsx
// app-shell-frontend/src/components/AppMenu.tsx
<nav>
  <MenuItem href="http://localhost:5600" icon="📧">
    Email Client
  </MenuItem>
  <MenuItem href="http://localhost:5610" icon="🎯">
    Cold Email
  </MenuItem>
  <MenuItem href="http://localhost:5620" icon="📰">
    Newsletter
  </MenuItem>
  <MenuItem href="http://localhost:5630" icon="📱">
    SMS
  </MenuItem>
  <MenuItem href="http://localhost:5640" icon="👥">
    CRM
  </MenuItem>
</nav>
```

**Oppure**: Single Page con micro-frontends

---

## 📋 Migration from Unified to Separated

### Step 1: Crea nuove directory

```bash
cd /Users/andromeda/dev/ewh

# Backend services
mkdir -p svc-email-client svc-cold-email svc-newsletter svc-sms-client svc-crm-advanced

# Frontend apps
mkdir -p app-email-client app-cold-email app-newsletter app-sms-client app-crm
```

### Step 2: Split existing code

```bash
# Da svc-unified-communications, sposta:

# Email inbox/composer → svc-email-client
cp -r svc-unified-communications/src/routes/messages.ts svc-email-client/src/routes/
cp -r svc-unified-communications/src/routes/inbox.ts svc-email-client/src/routes/

# Campaigns → svc-cold-email
cp -r svc-unified-communications/src/routes/campaigns.ts svc-cold-email/src/routes/

# Accounts/OAuth → svc-email-client
cp -r svc-unified-communications/src/routes/accounts.ts svc-email-client/src/routes/
```

### Step 3: Update ports

Vedi sezione "Port Allocation" sopra.

---

## 🔧 Environment Variables per App

### svc-email-client (.env)
```bash
PORT=4600
WS_PORT=4601
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET=...

SENDGRID_API_KEY=...
GOOGLE_CLIENT_ID=...
MICROSOFT_CLIENT_ID=...

# Integration
CRM_SERVICE_URL=http://localhost:4640
```

### svc-cold-email (.env)
```bash
PORT=4610
WS_PORT=4611
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET=...

SENDGRID_API_KEY=...

# Integration
EMAIL_CLIENT_URL=http://localhost:4600
CRM_SERVICE_URL=http://localhost:4640
```

### svc-newsletter (.env)
```bash
PORT=4620
WS_PORT=4621
DATABASE_URL=postgresql://...
SENDGRID_API_KEY=...

# Integration
CRM_SERVICE_URL=http://localhost:4640
```

### svc-sms-client (.env)
```bash
PORT=4630
WS_PORT=4631
DATABASE_URL=postgresql://...
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...

# Integration
CRM_SERVICE_URL=http://localhost:4640
```

### svc-crm-advanced (.env)
```bash
PORT=4640
WS_PORT=4641
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Integration with other services
EMAIL_CLIENT_URL=http://localhost:4600
COLD_EMAIL_URL=http://localhost:4610
NEWSLETTER_URL=http://localhost:4620
SMS_CLIENT_URL=http://localhost:4630
```

---

## 📊 Deployment Strategy

### Development (Docker Compose)

```yaml
version: '3.8'
services:
  # Backend services
  svc-email-client:
    build: ./svc-email-client
    ports: ["4600:4600", "4601:4601"]

  svc-cold-email:
    build: ./svc-cold-email
    ports: ["4610:4610", "4611:4611"]

  svc-newsletter:
    build: ./svc-newsletter
    ports: ["4620:4620", "4621:4621"]

  svc-sms-client:
    build: ./svc-sms-client
    ports: ["4630:4630", "4631:4631"]

  svc-crm-advanced:
    build: ./svc-crm-advanced
    ports: ["4640:4640", "4641:4641"]

  # Frontend apps
  app-email-client:
    build: ./app-email-client
    ports: ["5600:5600"]

  app-cold-email:
    build: ./app-cold-email
    ports: ["5610:5610"]

  app-newsletter:
    build: ./app-newsletter
    ports: ["5620:5620"]

  app-sms-client:
    build: ./app-sms-client
    ports: ["5630:5630"]

  app-crm:
    build: ./app-crm
    ports: ["5640:5640"]
```

---

## 🎯 Priorità di Implementazione

### Phase 1 (Core - 2 settimane)
1. ✅ **svc-email-client** + **app-email-client**
   - Inbox, compose, Gmail/Outlook sync

2. ✅ **svc-crm-advanced** + **app-crm**
   - Contacts, deals, basic pipeline

### Phase 2 (Campaigns - 2 settimane)
3. ✅ **svc-cold-email** + **app-cold-email**
   - Campaign builder, rotation, analytics

4. ✅ **svc-newsletter** + **app-newsletter**
   - Subscriber lists, templates, send

### Phase 3 (Additional - 1 settimana)
5. ✅ **svc-sms-client** + **app-sms-client**
   - Twilio integration

### Phase 4 (Integration - 1 settimana)
6. ✅ Cross-app integration
7. ✅ Unified search
8. ✅ Shared analytics dashboard

---

## 📚 Documentation per App

Ogni app deve avere:

```
app-xxx/
├── README.md              # Setup e quick start
├── API.md                 # API documentation
├── ARCHITECTURE.md        # Design decisions
└── .env.example           # Environment template

svc-xxx/
├── README.md
├── src/routes/dev.ts      # /dev endpoint (HTML docs)
├── src/routes/health.ts   # /health endpoint
└── .env.example
```

---

## ✅ Benefits of Separated Apps

**Pro:**
- ✅ **Separazione chiara** delle responsabilità
- ✅ **Deploy indipendente** (aggiorna una senza toccare le altre)
- ✅ **Scalabilità** (scala solo ciò che serve)
- ✅ **Team diversi** possono lavorare su app diverse
- ✅ **Codebase più piccola** per app (più facile da mantenere)
- ✅ **Testing isolato**

**Contro:**
- ⚠️ Più complessità di deployment
- ⚠️ Più duplicazione di codice (risolto con shared libraries)
- ⚠️ Più servizi da monitorare

---

## 🔄 Next Steps

1. ✅ Creare struttura directory per tutte le app
2. ✅ Setup package.json per ogni servizio
3. ✅ Split codice da svc-unified-communications
4. ✅ Creare migration database per ogni app
5. ✅ Implementare integration layer
6. ✅ Setup Docker Compose
7. ✅ Testing end-to-end

---

**Status:** ✅ Architecture Defined - Ready to Split
**Created:** 2025-10-14
**Type:** Multi-App Architecture
