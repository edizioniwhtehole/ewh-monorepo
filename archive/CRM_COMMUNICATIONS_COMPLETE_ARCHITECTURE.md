# CRM & Communications - Architettura Completa

**Data:** 15 Ottobre 2025
**Obiettivo:** Sistema CRM enterprise-grade con comunicazioni multi-canale integrate

---

## 🎯 Visione Generale

Un sistema CRM che segue il cliente in **ogni fase del ciclo di vita**:
- Pre-vendita (Cold email, Newsletter)
- Vendita (Email, Messaging, Video Call)
- Produzione (Note condivise, Timeline)
- Post-vendita (Support, Accounting, Finance)

**Caratteristiche Uniche:**
- ✅ Anagrafiche condivise cross-modulo (PM, Accounting, Production, ecc.)
- ✅ Custom fields configurabili per tenant
- ✅ Note multi-utente con timeline
- ✅ Persone di contatto illimitate per azienda
- ✅ Integrazione comunicazioni (Email, SMS, WhatsApp, Video)

---

## 📊 Moduli Principali

### 1. CRM Core (Anagrafiche)

**Servizio:** `svc-crm`
**Frontend:** `app-crm-frontend`
**Port:** 3310 (backend), 5310 (frontend)

**Funzionalità:**
- Gestione Clienti (Companies + Contacts)
- Gestione Fornitori (Suppliers)
- Gestione Stakeholders (Partners, Investors, etc.)
- Custom Fields configurabili
- Note multi-utente con timeline
- Activity tracking (chiamate, meeting, task)
- Deals & Pipeline
- Document attachments

**Database Tables:**
```sql
-- Aziende (Companies)
CREATE TABLE companies (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'client', 'supplier', 'stakeholder'
  vat_number VARCHAR(50),
  tax_code VARCHAR(50),
  website VARCHAR(255),
  industry VARCHAR(100),
  size VARCHAR(50), -- 'small', 'medium', 'large', 'enterprise'
  annual_revenue DECIMAL(15,2),
  logo_url TEXT,
  billing_address JSONB,
  shipping_address JSONB,
  custom_fields JSONB, -- Campi personalizzati
  tags TEXT[],
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'prospect'
  assigned_to UUID, -- User responsible
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Persone di Contatto (1:N con Companies)
CREATE TABLE contacts (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  mobile VARCHAR(50),
  role VARCHAR(100), -- 'CEO', 'CFO', 'Buyer', 'Technical Contact', etc.
  department VARCHAR(100),
  is_primary BOOLEAN DEFAULT false, -- Contatto principale
  avatar_url TEXT,
  linkedin_url VARCHAR(255),
  birthday DATE,
  custom_fields JSONB,
  notes TEXT,
  tags TEXT[],
  status VARCHAR(50) DEFAULT 'active',
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Note Multi-Utente
CREATE TABLE notes (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  entity_type VARCHAR(50) NOT NULL, -- 'company', 'contact', 'deal', etc.
  entity_id UUID NOT NULL, -- ID dell'entità
  content TEXT NOT NULL,
  note_type VARCHAR(50), -- 'general', 'call', 'meeting', 'email', 'production', 'accounting'
  is_pinned BOOLEAN DEFAULT false,
  mentions UUID[], -- User IDs menzionati
  attachments JSONB, -- File allegati
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Timeline Activities (auto-generate)
CREATE TABLE activities (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID NOT NULL,
  activity_type VARCHAR(50) NOT NULL, -- 'note_added', 'email_sent', 'call_made', 'meeting_scheduled', 'deal_updated'
  title VARCHAR(255) NOT NULL,
  description TEXT,
  metadata JSONB, -- Dati specifici dell'attività
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Custom Fields Configuration (per tenant)
CREATE TABLE custom_fields_config (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  entity_type VARCHAR(50) NOT NULL, -- 'company', 'contact', 'deal'
  field_name VARCHAR(100) NOT NULL,
  field_label VARCHAR(255) NOT NULL,
  field_type VARCHAR(50) NOT NULL, -- 'text', 'number', 'date', 'select', 'multiselect', 'boolean', 'url', 'email'
  field_options JSONB, -- Per select/multiselect
  is_required BOOLEAN DEFAULT false,
  default_value TEXT,
  display_order INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, entity_type, field_name)
);

-- Deals (Pipeline)
CREATE TABLE deals (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  company_id UUID REFERENCES companies(id),
  title VARCHAR(255) NOT NULL,
  value DECIMAL(15,2),
  currency VARCHAR(3) DEFAULT 'EUR',
  stage VARCHAR(50) NOT NULL, -- 'lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost'
  probability INTEGER, -- 0-100%
  expected_close_date DATE,
  actual_close_date DATE,
  source VARCHAR(100), -- 'website', 'referral', 'cold_email', 'event', etc.
  custom_fields JSONB,
  assigned_to UUID,
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Documents & Attachments
CREATE TABLE documents (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(100),
  file_size BIGINT,
  file_url TEXT NOT NULL,
  category VARCHAR(50), -- 'contract', 'invoice', 'presentation', 'other'
  uploaded_by UUID NOT NULL,
  uploaded_at TIMESTAMP DEFAULT NOW()
);
```

---

### 2. Email Management

**Servizio:** `svc-email`
**Frontend:** `app-email-client`
**Port:** 3211 (backend), 5701 (frontend)

**Funzionalità:**
- Multi-account email (Gmail, Outlook, IMAP)
- Unified inbox
- Email templates
- Send/receive tracking
- Link to CRM contacts
- Email signatures
- Auto-reply rules

**Integrazioni:**
- SendGrid (transactional)
- Gmail API
- Microsoft Graph API
- IMAP/SMTP custom

---

### 3. Newsletter Management

**Servizio:** `svc-newsletter`
**Frontend:** `app-newsletter-client`
**Port:** 3212 (backend), 5702 (frontend)

**Funzionalità:**
- Newsletter campaigns
- Subscriber lists (sync da CRM)
- Drag & drop editor
- A/B testing
- Analytics (open rate, click rate)
- Unsubscribe management
- GDPR compliance

**Integrazioni:**
- Mailchimp
- SendGrid Marketing
- Custom SMTP

---

### 4. Cold Email Outreach

**Servizio:** `svc-coldmail`
**Frontend:** `app-coldmail-client`
**Port:** 3213 (backend), 5703 (frontend)

**Funzionalità:**
- Multi-step sequences
- Personalization tokens
- Smart scheduling (timezone-aware)
- Reply detection
- Automatic follow-ups
- Bounce handling
- Warmup automation
- Performance analytics

**Best Practices Built-in:**
- Gradual ramp-up sending
- Domain reputation monitoring
- SPF/DKIM/DMARC validation
- Spam score checker

**Integrazioni:**
- Lemlist
- Reply.io
- Apollo.io
- Custom SMTP rotation

---

### 5. Messaging (SMS, WhatsApp, Telegram, Discord)

**Servizio:** `svc-messaging`
**Frontend:** `app-messaging-client`
**Port:** 3214 (backend), 5704 (frontend)

**Funzionalità:**
- Unified messaging inbox
- SMS (Twilio, Vonage)
- WhatsApp Business API
- Telegram Bot
- Discord Webhooks
- Message templates
- Bulk messaging
- Chatbot automation

**Database Tables:**
```sql
CREATE TABLE messaging_accounts (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  channel VARCHAR(50) NOT NULL, -- 'sms', 'whatsapp', 'telegram', 'discord'
  account_name VARCHAR(255),
  credentials JSONB ENCRYPTED,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE messages (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  account_id UUID REFERENCES messaging_accounts(id),
  contact_id UUID REFERENCES contacts(id),
  company_id UUID REFERENCES companies(id),
  direction VARCHAR(10) NOT NULL, -- 'inbound', 'outbound'
  channel VARCHAR(50) NOT NULL,
  content TEXT NOT NULL,
  status VARCHAR(50), -- 'sent', 'delivered', 'read', 'failed'
  metadata JSONB,
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

### 6. Video Calls

**Servizio:** `svc-videocall`
**Frontend:** `app-videocall-client`
**Port:** 3215 (backend), 5705 (frontend)

**Opzione A: Integrazione Servizi Esterni (RACCOMANDATO per MVP)**

| Provider | Pro | Contro | Costo |
|----------|-----|--------|-------|
| **Zoom SDK** | Embed diretto, API robuste, recording | Dipendenza vendor | $100-200/mese |
| **Google Meet** | Gratis con Workspace, Calendar sync | Meno features embed | Gratis o $6-18/user |
| **Jitsi Embed** | Open source, customizzabile | Hosting nostro opzionale | Gratis |
| **Daily.co** | API moderna, facile integrazione | Startup risk | $99-499/mese |
| **Whereby Embedded** | UI bellissima, no download | Limiti free tier | Gratis-$99/mese |

**Implementazione suggerita:** **Jitsi Meet Embedded**
```typescript
// Componente React per Jitsi
import { JitsiMeeting } from '@jitsi/react-sdk';

function VideoCallRoom({ roomName, userInfo }) {
  return (
    <JitsiMeeting
      domain="meet.jit.si" // o nostro dominio se self-hosted
      roomName={roomName}
      userInfo={{
        displayName: userInfo.name,
        email: userInfo.email
      }}
      configOverwrite={{
        startWithAudioMuted: true,
        startWithVideoMuted: true,
        enableWelcomePage: false
      }}
      interfaceConfigOverwrite={{
        SHOW_JITSI_WATERMARK: false,
        SHOW_BRAND_WATERMARK: false
      }}
    />
  );
}
```

**Opzione B: Self-Hosted (per Enterprise)**

**Jitsi Meet Self-Hosted:**
```yaml
# docker-compose.yml
version: '3.8'
services:
  jitsi-web:
    image: jitsi/web:latest
    ports:
      - "8443:443"
    environment:
      - ENABLE_AUTH=1
      - ENABLE_GUESTS=0
      - ENABLE_RECORDING=1
    volumes:
      - ./config:/config
      - ./transcripts:/usr/share/jitsi-meet/transcripts

  jitsi-prosody:
    image: jitsi/prosody:latest
    environment:
      - ENABLE_AUTH=1
      - ENABLE_GUESTS=0

  jitsi-jicofo:
    image: jitsi/jicofo:latest
    depends_on:
      - prosody

  jitsi-jvb:
    image: jitsi/jvb:latest
    ports:
      - "10000:10000/udp"
```

**Funzionalità Video Call:**
- ✅ Schedule meetings (Calendar integration)
- ✅ Instant meetings (Quick join link)
- ✅ Screen sharing
- ✅ Recording (cloud storage)
- ✅ Chat durante call
- ✅ Link to CRM contact/company
- ✅ Automatic note creation post-call
- ✅ Transcript (con AI speech-to-text)

**Database Tables:**
```sql
CREATE TABLE video_meetings (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  company_id UUID REFERENCES companies(id),
  contact_id UUID REFERENCES contacts(id),
  title VARCHAR(255) NOT NULL,
  scheduled_at TIMESTAMP,
  duration_minutes INTEGER DEFAULT 60,
  meeting_url TEXT NOT NULL,
  provider VARCHAR(50), -- 'jitsi', 'zoom', 'meet', 'teams'
  room_id VARCHAR(255),
  host_user_id UUID NOT NULL,
  participants JSONB, -- Lista partecipanti
  status VARCHAR(50), -- 'scheduled', 'in_progress', 'completed', 'cancelled'
  recording_url TEXT,
  transcript TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE meeting_recordings (
  id UUID PRIMARY KEY,
  meeting_id UUID REFERENCES video_meetings(id),
  file_url TEXT NOT NULL,
  file_size BIGINT,
  duration_seconds INTEGER,
  thumbnail_url TEXT,
  transcript_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🏗️ Architettura Database Completa

### Entity Relationship Diagram

```
┌─────────────────┐
│   COMPANIES     │
│  (Anagrafiche)  │
└────────┬────────┘
         │ 1:N
         ├──────────────────┐
         │                  │
         ▼                  ▼
┌─────────────┐    ┌──────────────┐
│  CONTACTS   │    │    DEALS     │
│  (Persone)  │    │  (Pipeline)  │
└──────┬──────┘    └──────┬───────┘
       │                  │
       └──────┬───────────┘
              │ N:1
              ▼
      ┌───────────────┐
      │  ACTIVITIES   │
      │  (Timeline)   │
      └───────────────┘
              │
              ▼
      ┌───────────────┐
      │     NOTES     │
      │ (Multi-User)  │
      └───────────────┘

┌──────────────────┐
│    MESSAGES      │ ──┐
│ (Email/SMS/Chat) │   │
└──────────────────┘   │
                       ├─► Link to CONTACTS/COMPANIES
┌──────────────────┐   │
│ VIDEO_MEETINGS   │ ──┘
│   (Calls)        │
└──────────────────┘
```

---

## 🔗 Integrazione Cross-Modulo

### Come CRM segue il cliente ovunque:

**1. Project Management (PM)**
```typescript
// In PM, quando crei un progetto
const project = {
  name: "Website Redesign",
  company_id: "uuid-from-crm", // ⬅️ Link a CRM
  contact_id: "uuid-from-crm",  // ⬅️ Link a persona di contatto
  // ...
};

// Automaticamente, PM può mostrare:
// - Nome cliente
// - Persone di contatto
// - Note CRM
// - Storia comunicazioni
```

**2. Accounting (Fatturazione)**
```typescript
// Quando crei una fattura
const invoice = {
  company_id: "uuid-from-crm", // ⬅️ Anagrafica condivisa
  // Dati billing pre-compilati da CRM:
  billing_address: company.billing_address,
  vat_number: company.vat_number,
  payment_terms: company.custom_fields.payment_terms
};
```

**3. Production (Produzione)**
```typescript
// Durante produzione, operatore può:
// - Vedere note cliente
// - Aggiungere note produzione
// - Vedere storia ordini
// - Contattare direttamente (click-to-call, email)
```

**API condivisa:**
```typescript
// /api/crm/companies/:id/full-context
{
  company: {...},
  contacts: [...],
  recent_notes: [...],
  recent_activities: [...],
  active_projects: [...],
  pending_invoices: [...],
  production_jobs: [...]
}
```

---

## 🎨 UI/UX Design Pattern

### Scheda Azienda (Company Card)

```
┌─────────────────────────────────────────────────────────┐
│ 🏢 Acme Corp                                    [Edit] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ 📧 info@acme.com        📞 +39 02 1234567              │
│ 🌐 www.acme.com         🏷️ Client · Active             │
│                                                         │
│ ┌─────────────┬─────────────┬──────────────┐          │
│ │   TABS:     │             │              │          │
│ │  Overview   │  Contacts   │  Notes       │          │
│ │  Deals      │  Projects   │  Documents   │          │
│ │  Invoices   │  Timeline   │  Settings    │          │
│ └─────────────┴─────────────┴──────────────┘          │
│                                                         │
│ [Tab Content Area]                                     │
│                                                         │
│ Quick Actions:                                         │
│ [📧 Send Email] [📞 Call] [💬 Message] [🎥 Video Call]│
└─────────────────────────────────────────────────────────┘
```

### Timeline/Activity Feed

```
┌─────────────────────────────────────────────┐
│ 📅 Timeline                                 │
├─────────────────────────────────────────────┤
│                                             │
│ 🔵 Today 10:30 - @mario added note         │
│    "Cliente richiede cambio specifiche"    │
│    [Production] 📎 specs_v2.pdf            │
│                                             │
│ 📧 Today 09:15 - Email sent by @sara       │
│    "Quote for Website Redesign"            │
│    ✓ Opened  ✓ Clicked                     │
│                                             │
│ 🎥 Yesterday - Video call completed        │
│    Duration: 45 min  [View Recording]      │
│    Auto-note: "Discussed Q4 requirements"  │
│                                             │
│ 💰 3 days ago - Deal moved to "Negotiation"│
│    Value: €45,000  Probability: 70%        │
│                                             │
│ 📝 1 week ago - @luca added note           │
│    [Accounting] "Payment received - Inv#123"│
└─────────────────────────────────────────────┘
```

---

## 📦 Port Allocation

| Service | Backend Port | Frontend Port | Description |
|---------|-------------|---------------|-------------|
| svc-crm | 3310 | 5310 | CRM Core (Anagrafiche) |
| svc-email | 3211 | 5701 | Email Management |
| svc-newsletter | 3212 | 5702 | Newsletter Campaigns |
| svc-coldmail | 3213 | 5703 | Cold Email Outreach |
| svc-messaging | 3214 | 5704 | SMS/WhatsApp/Telegram |
| svc-videocall | 3215 | 5705 | Video Calls (Jitsi) |

---

## 🚀 Implementazione - Roadmap

### Phase 1: CRM Core (Settimana 1-2)
- [x] Planning & Architecture
- [ ] Database schema completo
- [ ] svc-crm API endpoints
- [ ] app-crm-frontend base UI
- [ ] CRUD Companies
- [ ] CRUD Contacts
- [ ] Custom Fields system
- [ ] Notes multi-utente
- [ ] Timeline activities

### Phase 2: Email & Messaging (Settimana 3-4)
- [ ] svc-email implementation
- [ ] Email account connections
- [ ] Unified inbox
- [ ] svc-messaging (SMS, WhatsApp)
- [ ] Link messages to CRM

### Phase 3: Newsletter & Cold Email (Settimana 5-6)
- [ ] svc-newsletter implementation
- [ ] Campaign editor
- [ ] svc-coldmail sequences
- [ ] Analytics dashboard

### Phase 4: Video Calls (Settimana 7)
- [ ] Jitsi integration
- [ ] Meeting scheduler
- [ ] Recording & transcripts
- [ ] Calendar sync

### Phase 5: Cross-Module Integration (Settimana 8)
- [ ] PM ↔️ CRM integration
- [ ] Accounting ↔️ CRM integration
- [ ] Production ↔️ CRM notes
- [ ] Unified search

---

## 💡 Features Avanzate (Future)

### AI-Powered Features
- **Email Assistant:** Suggerimenti risposte, tone detection
- **Lead Scoring:** ML-based probability prediction
- **Chatbot:** Risposta automatica via messaging
- **Transcript Analysis:** Sentiment analysis delle call
- **Predictive Analytics:** Churn prediction, upsell opportunities

### Automation
- **Workflow Automation:** Trigger-based actions
- **Email Sequences:** Drip campaigns automatiche
- **Task Creation:** Auto-create task da email/note
- **Smart Reminders:** Follow-up intelligenti

### Collaboration
- **Shared Inbox:** Team collaboration su email
- **Note Mentions:** @mention team members
- **Real-time Updates:** WebSocket per timeline
- **Mobile App:** React Native per iOS/Android

---

## 🎯 Domande Architetturali

**Q: Video call - Jitsi hosted o servizi esterni?**
- **Raccomandazione:** Iniziare con **Jitsi embedded** (meet.jit.si free)
- **Upgrade path:** Self-hosted Jitsi quando necessario (>100 utenti)
- **Alternative:** Whereby Embedded ($99/mese) per UI migliore

**Q: Separare svc-communications o creare 4 servizi?**
- **Raccomandazione:** **4 servizi separati** per:
  - Scalabilità indipendente
  - Deploy granulare
  - Team ownership
  - Migrazione provider facilitata

**Q: Custom fields - dove salvarli?**
- **Raccomandazione:** JSONB column `custom_fields` in ogni entity
- **Config:** Tabella `custom_fields_config` per definizioni
- **Validazione:** Schema validation a runtime

---

**Pronto per iniziare?** 🚀

Dimmi da dove vuoi partire e procedo in autonomia!
