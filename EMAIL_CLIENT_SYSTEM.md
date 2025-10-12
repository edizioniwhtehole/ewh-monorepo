# EWH Platform - Advanced Email Client & CRM Integration

> **Sistema email unificato con gestione multi-account, cold email aggregator per CRM, e auto-categorizzazione intelligente**

**Versione:** 1.0.0
**Target:** Personal email management + Cold email campaigns + CRM integration
**Ultima revisione:** 2025-10-04
**Roadmap:** MVP → Production Ready → Scaling → **Enterprise Grade**

---

## 🎯 4-TIER ROADMAP: MVP → ENTERPRISE

### 🟢 TIER 1: MVP (4-6 settimane)
**Core functionality per validare il sistema**

✅ Connessione 1-3 account email (Gmail/Outlook OAuth2)
✅ Inbox unificata (solo lettura)
✅ Invio email base (to, subject, body, allegati)
✅ Ricerca base (full-text su subject/body)
✅ Thread grouping semplice
✅ Cartelle base (Inbox, Sent, Drafts, Trash)
✅ Editor WYSIWYG base (TipTap)
✅ Sync manuale + auto ogni 5min

### 🟡 TIER 2: PRODUCTION READY (8-10 settimane)
**Sistema completo per uso quotidiano aziendale**

✅ Multi-account illimitati (10-50 account)
✅ Dual view (unified + per-account)
✅ Auto-translation con lingue escluse + side-by-side view
✅ AI Quick Reply base (template + AI suggestions)
✅ Smart Routing (regole IF/THEN)
✅ Calendar integration (Google/Outlook)
✅ CRM integration base (routing a tecnico)
✅ Etichette e categorie custom
✅ Filtri avanzati + Snooze + Signature management
✅ Rich notifications (desktop + mobile)

### 🟠 TIER 3: SCALING (14-16 settimane)
**Per organizzazioni in crescita (50-500 utenti)**

**Performance:**
✅ Multi-region deployment + Redis caching
✅ Elasticsearch per ricerca avanzata
✅ CDN per allegati + Database read replicas
✅ Queue system (BullMQ) + Rate limiting
✅ Batch processing (100+ account in parallelo)

**Cold Email & Campaigns:**
✅ Cold email campaigns (thousands/day)
✅ Domain rotation + Email warm-up
✅ Deliverability monitoring + Reply detection
✅ A/B testing + Drip campaigns + Unsubscribe management

**Security & Compliance:**
✅ SSO/SAML (Okta, Azure AD)
✅ 2FA enforcement + Audit logs completi
✅ GDPR compliance + Data retention policies
✅ Encryption at rest + IP whitelisting
✅ Role-based permissions granulari

**Advanced Features:**
✅ Credential vault con auto-extraction
✅ Email templates team-wide + Shared inboxes
✅ Internal notes + Task creation da email
✅ Zapier/Make integration + Custom fields

**Analytics:**
✅ Dashboard analytics + Team performance metrics
✅ Campaign reports + SLA monitoring + Export reports

### 🔴 TIER 4: ENTERPRISE (20-24 settimane)
**Per grandi organizzazioni (500+ utenti, mission-critical)**

**Infrastructure & Reliability:**
✅ 99.99% SLA garantito (downtime < 52min/anno)
✅ Multi-zone deployment (3+ availability zones)
✅ Active-active replication (zero downtime failover)
✅ Disaster recovery: RPO < 5min, RTO < 15min
✅ Auto-scaling (Kubernetes) + Circuit breakers
✅ Blue-green deployments

**Enterprise Security:**
✅ SOC2 Type II + ISO 27001 + HIPAA compliance
✅ Private cloud deployment option (on-premise)
✅ VPN/VPC peering + HSM per encryption keys
✅ Penetration testing trimestrale + Bug bounty
✅ DLP integration + eDiscovery support
✅ Compliance reports automatici

**Advanced AI & Automation:**
✅ Sentiment analysis real-time (urgenza, tone)
✅ Priority scoring ML-based + Smart categorization custom
✅ Predictive reply time (SLA forecasting)
✅ Auto-summarization + Meeting extraction
✅ Action items extraction + Contact enrichment
✅ Duplicate detection + Anomaly detection

**White-Label & Multi-Tenancy:**
✅ Full white-label (custom domain, branding, logo)
✅ Dedicated database per tenant enterprise
✅ Custom domain email (mail.clientcompany.com)
✅ Tenant-specific infrastructure + Custom SLA
✅ Tenant admin console + API rate limits custom

**Integrations & Extensibility:**
✅ Salesforce/HubSpot/Dynamics/ServiceNow native
✅ Slack/Teams deep integration + Custom webhooks
✅ GraphQL API + SDK per extensions + Marketplace

**Advanced Analytics:**
✅ BI tool integration (Tableau, PowerBI, Looker)
✅ Data warehouse export (Snowflake, BigQuery)
✅ Predictive analytics + Custom dashboards
✅ Real-time alerts + Benchmarking

**Support & Operations:**
✅ 24/7 support con SLA (<15min critical)
✅ Dedicated account manager + Slack channel
✅ Quarterly business reviews (QBR)
✅ Custom training + Implementation support
✅ Migration services + Custom feature development

**Compliance & Governance:**
✅ Multi-region data residency (EU data in EU)
✅ Data sovereignty guarantees + Legal hold automation
✅ DLP policies custom + Retention policies avanzate
✅ Auto-archiving compliance (SOX, FINRA)

---

| Feature | MVP | Production | Scaling | Enterprise |
|---------|-----|-----------|---------|-----------|
| Max accounts | 3 | 50 | Unlimited | Unlimited |
| Max users/tenant | 5 | 50 | 500 | Unlimited |
| Uptime SLA | - | 99% | 99.9% | **99.99%** |
| Multi-region | ❌ | ❌ | ✅ | ✅ (3+ zones) |
| AI Quick Reply | ❌ | ✅ Basic | ✅ Advanced | ✅ + ML custom |
| Cold email | ❌ | ❌ | ✅ | ✅ + Warm-up |
| SSO/SAML | ❌ | ❌ | ✅ | ✅ |
| Audit logs | ❌ | ❌ | ✅ | ✅ + eDiscovery |
| White-label | ❌ | ❌ | ❌ | ✅ Full |
| Support | Community | Email | Email+Chat | **24/7 + AM** |
| Compliance | - | GDPR | GDPR+SOC2 | **All+ISO** |
| Disaster recovery | ❌ | Backup daily | RPO 1hr | **RPO 5min** |

---

## 🎯 Obiettivi

### 1. **Personal Email Client**
- ✅ Gestione multi-account (SMTP, IMAP, Gmail API, Outlook API)
- ✅ **Dual View Mode:**
  - **Unified Inbox** - Flusso unico di tutte le email da tutti gli account
  - **Per-Account View** - Inbox/Sent/Drafts/Trash separati per ogni singola casella
- ✅ Supporto provider: Gmail, Outlook, IMAP/SMTP generico
- ✅ Sync bidirezionale (read, send, archive, delete)
- ✅ **Auto-translation per account** - Traduci automaticamente email in arrivo (escludendo lingue selezionate)

### 2. **Cold Email Aggregator per CRM**
- ✅ Gestione decine/centinaia di caselle per cold outreach
- ✅ Aggregazione risposte da tutti i domini
- ✅ Processamento automatico → Lead CRM
- ✅ Reply tracking e engagement scoring

### 3. **Smart Categorization**
- ✅ Filtri automatici AI-powered
- ✅ Categorie: Newsletter, Transazionali, Rilevanti, Fornitori, Spam
- ✅ Regole personalizzabili + machine learning
- ✅ Migrazione automatica in cartelle

### 4. **Full-Text Search**
- ✅ Ricerca istantanea su tutte le email (on-the-fly)
- ✅ Index PostgreSQL full-text + Elasticsearch (opzionale)
- ✅ Filtri avanzati: mittente, allegati, date range, categorie

### 5. **Credentials Vault**
- ✅ Estrazione automatica login/password da email
- ✅ Storage criptato (AES-256)
- ✅ Auto-detect pattern (signup emails, password reset, etc.)

### 6. **AI Quick Reply System**
- ✅ Suggerimenti automatici risposta AI-powered
- ✅ Template pre-impostati (Sì, No, Fissa appuntamento, etc.)
- ✅ Regole condizionali per mittente/contenuto
- ✅ Draft approval prima dell'invio
- ✅ Integrazione calendar per appuntamenti

### 7. **Smart Email Routing**
- ✅ Routing automatico su email generiche (info@, support@, etc.)
- ✅ Regole basate su contenuto/mittente
- ✅ Assegnazione a utenti/team specifici
- ✅ Integrazione CRM (es: email cliente → tecnico assegnato)

---

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Email System Architecture                                  │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  1. Email Ingestion Layer              │
│     • IMAP/SMTP sync                   │
│     • Gmail API / Outlook API          │
│     • Multi-account polling            │
│     • Webhook listeners (Gmail push)   │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  2. Processing & Categorization        │
│     • AI classification                │
│     • Spam detection                   │
│     • Credential extraction            │
│     • Thread grouping                  │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  3. Storage & Indexing                 │
│     • PostgreSQL (metadata + body)     │
│     • S3 (attachments)                 │
│     • Full-text search index           │
│     • Thread relationships             │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  4. CRM Integration (Cold Email)       │
│     • Reply aggregation                │
│     • Lead scoring                     │
│     • Auto-create CRM contacts         │
│     • Campaign tracking                │
└────────────────────────────────────────┘
```

---

## 1. Email Account Management

### Account Types

```typescript
// svc-email/src/types/accounts.ts

export enum EmailProvider {
  GMAIL = 'gmail',
  OUTLOOK = 'outlook',
  IMAP_SMTP = 'imap_smtp',
  EXCHANGE = 'exchange',
}

export enum AccountPurpose {
  PERSONAL = 'personal', // Single user inbox
  COLD_OUTREACH = 'cold_outreach', // For cold email campaigns
  SHARED = 'shared', // Team inbox (future)
}

export interface EmailAccount {
  id: string
  tenant_id: string
  user_id: string

  // Account details
  email: string
  display_name: string
  provider: EmailProvider
  purpose: AccountPurpose

  // Connection settings
  config: {
    // Gmail
    gmail?: {
      access_token: string
      refresh_token: string
      client_id: string
      client_secret: string
    }

    // Outlook
    outlook?: {
      access_token: string
      refresh_token: string
      client_id: string
      client_secret: string
    }

    // IMAP/SMTP
    imap_smtp?: {
      imap_host: string
      imap_port: number
      imap_secure: boolean
      smtp_host: string
      smtp_port: number
      smtp_secure: boolean
      username: string
      password_encrypted: string
    }
  }

  // Sync settings
  sync_enabled: boolean
  sync_frequency_minutes: number // 1, 5, 15, 30, 60
  last_synced_at: Date
  sync_status: 'idle' | 'syncing' | 'error'

  // Translation settings
  auto_translate_enabled: boolean
  target_language: string // 'it', 'en', 'es', etc.
  excluded_languages: string[] // Languages to NOT translate (e.g., ['it', 'en'])

  // Stats
  total_emails: number
  unread_count: number

  created_at: Date
  updated_at: Date
}
```

### Database Schema

```sql
-- Email accounts
CREATE TABLE email_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.organizations(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  provider VARCHAR(50) NOT NULL, -- 'gmail', 'outlook', 'imap_smtp'
  purpose VARCHAR(50) NOT NULL DEFAULT 'personal', -- 'personal', 'cold_outreach'

  config JSONB NOT NULL, -- Provider-specific config (encrypted)

  sync_enabled BOOLEAN DEFAULT true,
  sync_frequency_minutes INTEGER DEFAULT 15,
  last_synced_at TIMESTAMPTZ,
  sync_status VARCHAR(20) DEFAULT 'idle',
  sync_error TEXT,

  -- Translation settings
  auto_translate_enabled BOOLEAN DEFAULT false,
  target_language VARCHAR(5) DEFAULT 'it', -- ISO 639-1 code
  excluded_languages TEXT[] DEFAULT '{}', -- Languages to skip translation

  total_emails INTEGER DEFAULT 0,
  unread_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, email)
);

-- Emails
CREATE TABLE emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES email_accounts(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  -- Email metadata
  message_id VARCHAR(500) NOT NULL, -- Original Message-ID header
  thread_id VARCHAR(255), -- Gmail thread ID or computed
  in_reply_to VARCHAR(500), -- In-Reply-To header
  references TEXT[], -- References header (array of message IDs)

  -- Headers
  from_email VARCHAR(255) NOT NULL,
  from_name VARCHAR(255),
  to_emails TEXT[] NOT NULL, -- Array of recipients
  cc_emails TEXT[],
  bcc_emails TEXT[],
  subject TEXT,

  -- Content
  body_text TEXT, -- Plain text version
  body_html TEXT, -- HTML version
  snippet TEXT, -- First 200 chars preview

  -- Translation
  detected_language VARCHAR(5), -- Auto-detected language (ISO 639-1)
  translated BOOLEAN DEFAULT false,
  translation_target_lang VARCHAR(5), -- Language translated to
  translated_subject TEXT,
  translated_body_text TEXT,
  translated_body_html TEXT,

  -- Attachments
  has_attachments BOOLEAN DEFAULT false,
  attachments JSONB, -- [{ filename, size, content_type, s3_key }]

  -- Metadata
  date TIMESTAMPTZ NOT NULL,
  is_read BOOLEAN DEFAULT false,
  is_starred BOOLEAN DEFAULT false,
  is_draft BOOLEAN DEFAULT false,
  is_sent BOOLEAN DEFAULT false,

  -- Categorization
  category VARCHAR(50), -- 'newsletter', 'transactional', 'relevant', 'supplier', 'spam', 'cold_reply'
  labels TEXT[], -- User-defined labels
  folder VARCHAR(100) DEFAULT 'inbox', -- 'inbox', 'sent', 'archive', 'trash', custom folders

  -- AI Processing
  ai_category_confidence DECIMAL(3,2), -- 0.00 to 1.00
  ai_summary TEXT, -- AI-generated summary (optional)
  extracted_credentials JSONB, -- { username, password, service, url }

  -- CRM Integration (for cold outreach replies)
  is_cold_reply BOOLEAN DEFAULT false,
  crm_contact_id UUID, -- Link to CRM contact
  campaign_id UUID, -- Link to cold email campaign

  -- Full-text search
  search_vector tsvector, -- PostgreSQL full-text search

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(account_id, message_id)
);

-- Indexes
CREATE INDEX idx_emails_account ON emails(account_id, date DESC);
CREATE INDEX idx_emails_tenant ON emails(tenant_id, date DESC);
CREATE INDEX idx_emails_user ON emails(user_id, date DESC);
CREATE INDEX idx_emails_thread ON emails(thread_id, date);
CREATE INDEX idx_emails_category ON emails(category, date DESC);
CREATE INDEX idx_emails_folder ON emails(folder, date DESC);
CREATE INDEX idx_emails_from ON emails(from_email, date DESC);
CREATE INDEX idx_emails_unread ON emails(is_read, date DESC) WHERE is_read = false;
CREATE INDEX idx_emails_cold_reply ON emails(is_cold_reply, date DESC) WHERE is_cold_reply = true;

-- Full-text search index
CREATE INDEX idx_emails_search ON emails USING gin(search_vector);

-- Trigger to update search vector
CREATE FUNCTION emails_search_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.subject, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.body_text, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.from_name, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(NEW.from_email, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER emails_search_update
BEFORE INSERT OR UPDATE ON emails
FOR EACH ROW EXECUTE FUNCTION emails_search_trigger();

-- Email folders (custom folders)
CREATE TABLE email_folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  name VARCHAR(100) NOT NULL,
  color VARCHAR(20), -- Hex color for UI
  icon VARCHAR(50), -- Icon name

  -- Auto-categorization rules
  auto_move_enabled BOOLEAN DEFAULT false,
  auto_move_rules JSONB, -- { from_contains: [], subject_contains: [], category: '' }

  email_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, user_id, name)
);

-- Credentials vault (extracted from emails)
CREATE TABLE email_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  email_id UUID REFERENCES emails(id) ON DELETE SET NULL,

  service_name VARCHAR(255), -- e.g., "GitHub", "AWS", "Stripe"
  service_url VARCHAR(500),

  username VARCHAR(255),
  email_address VARCHAR(255),
  password_encrypted TEXT NOT NULL, -- AES-256 encrypted

  extraction_confidence DECIMAL(3,2), -- AI confidence
  verified BOOLEAN DEFAULT false, -- User verified it's correct

  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_credentials_tenant ON email_credentials(tenant_id, service_name);
CREATE INDEX idx_credentials_email ON email_credentials(email_id);
```

---

## 2. Dual View Mode: Unified + Per-Account

### View Modes

```typescript
// Two main viewing modes for emails

export enum EmailViewMode {
  UNIFIED = 'unified', // All emails from all accounts in one stream
  PER_ACCOUNT = 'per_account', // Separate view for each account (Inbox, Sent, Drafts, etc.)
}

export interface EmailViewState {
  mode: EmailViewMode

  // Unified mode
  unified?: {
    folder: 'all' | 'inbox' | 'starred' | 'archive'
    accounts: string[] // Filter by specific accounts (empty = all)
  }

  // Per-account mode
  perAccount?: {
    accountId: string // Which account is selected
    folder: 'inbox' | 'sent' | 'drafts' | 'archive' | 'trash' | string // custom folder
  }
}
```

### UI Navigation Structure

```tsx
// Sidebar navigation supports both modes

<Sidebar>
  {/* Unified Views */}
  <Section title="Unified">
    <NavItem icon="📬" label="All Inboxes" count={245} />
    <NavItem icon="⭐" label="All Starred" count={34} />
    <NavItem icon="📤" label="All Sent" count={892} />
  </Section>

  {/* Per-Account Views */}
  <Section title="Accounts">
    <AccountNavItem
      email="john@company.com"
      unread={125}
      folders={['inbox', 'sent', 'drafts', 'archive', 'trash']}
    >
      <FolderItem label="Inbox" count={125} />
      <FolderItem label="Sent" count={453} />
      <FolderItem label="Drafts" count={7} />
      <FolderItem label="Archive" count={2341} />
      <FolderItem label="Trash" count={12} />
    </AccountNavItem>

    <AccountNavItem
      email="john@personal.com"
      unread={43}
      folders={['inbox', 'sent', 'drafts', 'archive', 'trash']}
    />

    <AccountNavItem
      email="cold1@domain1.com"
      unread={8}
      purpose="cold_outreach"
      folders={['inbox', 'sent']}
    />
  </Section>

  {/* Categories (cross-account) */}
  <Section title="Categories">
    <CategoryItem icon="📰" label="Newsletters" count={78} />
    <CategoryItem icon="🧾" label="Receipts" count={45} />
    <CategoryItem icon="📧" label="Cold Replies" count={23} />
  </Section>
</Sidebar>
```

### Query Logic for Dual Views

```typescript
// svc-email/src/views/email-views.ts

export class EmailViewService {
  // Unified inbox: All emails from all accounts
  async getUnifiedInbox(
    tenantId: string,
    userId: string,
    folder: string = 'inbox',
    accountIds?: string[]
  ): Promise<Email[]> {
    let query = `
      SELECT e.*, ea.email as account_email, ea.display_name as account_name
      FROM emails e
      JOIN email_accounts ea ON e.account_id = ea.id
      WHERE e.tenant_id = $1 AND e.user_id = $2
    `

    const params: any[] = [tenantId, userId]

    // Filter by folder
    if (folder === 'inbox') {
      query += ` AND e.folder = 'inbox' AND e.is_sent = false`
    } else if (folder === 'starred') {
      query += ` AND e.is_starred = true`
    } else if (folder === 'all') {
      // All emails
    } else {
      query += ` AND e.folder = $3`
      params.push(folder)
    }

    // Filter by specific accounts (optional)
    if (accountIds && accountIds.length > 0) {
      query += ` AND e.account_id = ANY($${params.length + 1})`
      params.push(accountIds)
    }

    query += ` ORDER BY e.date DESC LIMIT 100`

    const result = await db.query(query, params)
    return result.rows
  }

  // Per-account view: Emails for specific account + folder
  async getAccountEmails(
    accountId: string,
    folder: string = 'inbox'
  ): Promise<Email[]> {
    let query = `
      SELECT * FROM emails
      WHERE account_id = $1
    `

    const params: any[] = [accountId]

    // Folder-specific logic
    if (folder === 'inbox') {
      query += ` AND folder = 'inbox' AND is_sent = false AND is_draft = false`
    } else if (folder === 'sent') {
      query += ` AND is_sent = true`
    } else if (folder === 'drafts') {
      query += ` AND is_draft = true`
    } else if (folder === 'trash') {
      query += ` AND folder = 'trash'`
    } else {
      query += ` AND folder = $2`
      params.push(folder)
    }

    query += ` ORDER BY date DESC LIMIT 100`

    const result = await db.query(query, params)
    return result.rows
  }

  // Get folder counts for an account
  async getAccountFolderCounts(accountId: string): Promise<Record<string, number>> {
    const result = await db.query(
      `SELECT
        COUNT(*) FILTER (WHERE folder = 'inbox' AND is_sent = false) as inbox,
        COUNT(*) FILTER (WHERE is_sent = true) as sent,
        COUNT(*) FILTER (WHERE is_draft = true) as drafts,
        COUNT(*) FILTER (WHERE folder = 'archive') as archive,
        COUNT(*) FILTER (WHERE folder = 'trash') as trash,
        COUNT(*) FILTER (WHERE is_read = false AND folder = 'inbox') as unread
       FROM emails
       WHERE account_id = $1`,
      [accountId]
    )

    return result.rows[0]
  }

  // Get unified folder counts (across all accounts)
  async getUnifiedFolderCounts(tenantId: string, userId: string): Promise<Record<string, number>> {
    const result = await db.query(
      `SELECT
        COUNT(*) FILTER (WHERE folder = 'inbox' AND is_sent = false) as all_inbox,
        COUNT(*) FILTER (WHERE is_sent = true) as all_sent,
        COUNT(*) FILTER (WHERE is_starred = true) as all_starred,
        COUNT(*) FILTER (WHERE folder = 'archive') as all_archive,
        COUNT(*) FILTER (WHERE is_read = false) as all_unread
       FROM emails
       WHERE tenant_id = $1 AND user_id = $2`,
      [tenantId, userId]
    )

    return result.rows[0]
  }
}
```

---

## 3. Auto-Translation System

### Translation Configuration

```typescript
// svc-email/src/translation/email-translator.ts

export interface TranslationConfig {
  enabled: boolean
  targetLanguage: string // Primary language to translate to
  excludedLanguages: string[] // Don't translate these languages
  autoDetect: boolean // Auto-detect email language
}

export class EmailTranslationService {
  async translateEmail(email: Email, account: EmailAccount) {
    // Check if translation is enabled for this account
    if (!account.auto_translate_enabled) {
      return
    }

    // Detect language
    const detectedLang = await this.detectLanguage(email.body_text || email.subject)

    // Update email with detected language
    await db.query(
      `UPDATE emails SET detected_language = $1 WHERE id = $2`,
      [detectedLang, email.id]
    )

    // Check if language is in excluded list
    if (account.excluded_languages.includes(detectedLang)) {
      console.log(`Skipping translation for ${detectedLang} (excluded)`)
      return
    }

    // Check if already in target language
    if (detectedLang === account.target_language) {
      console.log(`Email already in target language ${account.target_language}`)
      return
    }

    // Translate subject and body
    const translated = await this.translateContent({
      subject: email.subject,
      body_text: email.body_text,
      body_html: email.body_html,
      fromLang: detectedLang,
      toLang: account.target_language,
    })

    // Save translation
    await db.query(
      `UPDATE emails
       SET
         translated = true,
         translation_target_lang = $1,
         translated_subject = $2,
         translated_body_text = $3,
         translated_body_html = $4
       WHERE id = $5`,
      [
        account.target_language,
        translated.subject,
        translated.body_text,
        translated.body_html,
        email.id,
      ]
    )
  }

  // Detect language using GPT-4 or external service
  private async detectLanguage(text: string): Promise<string> {
    // Option 1: Use Google Translate API detect
    // Option 2: Use GPT-4 to detect language

    const prompt = `Detect the language of this text and return ONLY the ISO 639-1 code (e.g., 'en', 'it', 'es', 'fr').

Text:
${text.substring(0, 500)}

Return only the 2-letter language code.`

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Fast and cheap
      messages: [
        { role: 'system', content: 'You are a language detection expert. Return only ISO 639-1 codes.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.1,
      max_tokens: 10,
    })

    return response.choices[0].message.content.trim().toLowerCase()
  }

  // Translate content using GPT-4 or Google Translate API
  private async translateContent(req: {
    subject: string
    body_text: string
    body_html?: string
    fromLang: string
    toLang: string
  }): Promise<{ subject: string; body_text: string; body_html: string }> {
    // Use existing I18N AI Translation system
    const aiTranslator = new AITranslator()

    const translatedSubject = await aiTranslator.translate({
      text: req.subject,
      source_lang: req.fromLang,
      target_lang: req.toLang,
    })

    const translatedBody = await aiTranslator.translate({
      text: req.body_text,
      source_lang: req.fromLang,
      target_lang: req.toLang,
    })

    // Translate HTML (preserve formatting)
    let translatedHtml = req.body_html
    if (req.body_html) {
      // Extract text from HTML, translate, re-inject
      translatedHtml = await this.translateHtml(req.body_html, req.fromLang, req.toLang)
    }

    return {
      subject: translatedSubject,
      body_text: translatedBody,
      body_html: translatedHtml,
    }
  }

  private async translateHtml(html: string, fromLang: string, toLang: string): Promise<string> {
    // Use GPT-4 to translate HTML while preserving structure
    const prompt = `Translate this HTML email from ${fromLang} to ${toLang}.
Preserve all HTML tags, attributes, styles, and structure.
Only translate the visible text content.

HTML:
${html}

Return the translated HTML.`

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: 'You are an expert translator. Preserve HTML structure.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.3,
    })

    return response.choices[0].message.content
  }
}
```

### Account Settings UI - Translation Tab

```tsx
// app-web-frontend/pages/email/settings/[accountId]/translation.tsx

export default function AccountTranslationSettings({ accountId }: { accountId: string }) {
  const [account, setAccount] = useState<EmailAccount | null>(null)
  const [translationEnabled, setTranslationEnabled] = useState(false)
  const [targetLanguage, setTargetLanguage] = useState('it')
  const [excludedLanguages, setExcludedLanguages] = useState<string[]>([])

  useEffect(() => {
    loadAccountSettings()
  }, [accountId])

  const loadAccountSettings = async () => {
    const response = await fetch(`/api/v1/email/accounts/${accountId}`)
    const data = await response.json()
    setAccount(data.account)
    setTranslationEnabled(data.account.auto_translate_enabled)
    setTargetLanguage(data.account.target_language)
    setExcludedLanguages(data.account.excluded_languages || [])
  }

  const saveSettings = async () => {
    await fetch(`/api/v1/email/accounts/${accountId}/translation`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auto_translate_enabled: translationEnabled,
        target_language: targetLanguage,
        excluded_languages: excludedLanguages,
      }),
    })

    toast.success('Translation settings saved')
  }

  return (
    <div className="p-8 max-w-2xl">
      <h1 className="text-2xl font-bold mb-2">Auto-Translation Settings</h1>
      <p className="text-gray-600 mb-6">
        Automatically translate incoming emails for: <strong>{account?.email}</strong>
      </p>

      {/* Enable/Disable Toggle */}
      <div className="border rounded-lg p-6 mb-6">
        <label className="flex items-center justify-between cursor-pointer">
          <div>
            <p className="font-semibold">Enable Auto-Translation</p>
            <p className="text-sm text-gray-600">
              Automatically translate emails to your preferred language
            </p>
          </div>
          <Toggle checked={translationEnabled} onChange={setTranslationEnabled} />
        </label>
      </div>

      {translationEnabled && (
        <>
          {/* Target Language */}
          <div className="border rounded-lg p-6 mb-6">
            <label className="block mb-2 font-semibold">Translate emails to:</label>
            <select
              value={targetLanguage}
              onChange={(e) => setTargetLanguage(e.target.value)}
              className="w-full border rounded-lg px-4 py-2"
            >
              <option value="it">🇮🇹 Italian</option>
              <option value="en">🇬🇧 English</option>
              <option value="es">🇪🇸 Spanish</option>
              <option value="fr">🇫🇷 French</option>
              <option value="de">🇩🇪 German</option>
              <option value="pt">🇵🇹 Portuguese</option>
              <option value="nl">🇳🇱 Dutch</option>
              <option value="pl">🇵🇱 Polish</option>
              <option value="ru">🇷🇺 Russian</option>
              <option value="zh">🇨🇳 Chinese</option>
              <option value="ja">🇯🇵 Japanese</option>
            </select>
          </div>

          {/* Excluded Languages */}
          <div className="border rounded-lg p-6 mb-6">
            <label className="block mb-2 font-semibold">
              Don't translate emails in these languages:
            </label>
            <p className="text-sm text-gray-600 mb-4">
              Select languages that you understand and don't need translation for.
            </p>

            <LanguageSelector
              selectedLanguages={excludedLanguages}
              onChange={setExcludedLanguages}
              options={[
                { code: 'it', label: '🇮🇹 Italian' },
                { code: 'en', label: '🇬🇧 English' },
                { code: 'es', label: '🇪🇸 Spanish' },
                { code: 'fr', label: '🇫🇷 French' },
                { code: 'de', label: '🇩🇪 German' },
                { code: 'pt', label: '🇵🇹 Portuguese' },
                { code: 'nl', label: '🇳🇱 Dutch' },
                { code: 'pl', label: '🇵🇱 Polish' },
              ]}
            />

            <div className="mt-4 bg-blue-50 border border-blue-200 rounded p-3 text-sm">
              💡 <strong>Tip:</strong> If you speak Italian and English, add both to excluded
              languages. Only emails in other languages will be translated to{' '}
              <strong>{LANGUAGE_NAMES[targetLanguage]}</strong>.
            </div>
          </div>

          {/* Example Preview */}
          <div className="border rounded-lg p-6 mb-6 bg-gray-50">
            <h3 className="font-semibold mb-3">Example:</h3>
            <div className="space-y-3">
              <ExampleEmail
                lang="es"
                subject="Hola, propuesta de colaboración"
                result="🔄 Will be translated to Italian"
                willTranslate={!excludedLanguages.includes('es')}
              />
              <ExampleEmail
                lang="en"
                subject="RE: Your project proposal"
                result="✓ No translation (English excluded)"
                willTranslate={!excludedLanguages.includes('en')}
              />
              <ExampleEmail
                lang="fr"
                subject="Invitation à notre événement"
                result="🔄 Will be translated to Italian"
                willTranslate={!excludedLanguages.includes('fr')}
              />
            </div>
          </div>

          {/* AI Cost Notice */}
          <div className="border rounded-lg p-4 mb-6 bg-yellow-50 border-yellow-200">
            <p className="text-sm text-yellow-800">
              ⚠️ <strong>AI Cost:</strong> Translation uses AI credits. Average cost: ~10 credits
              per email. Consider using BYOK (Bring Your Own Key) to reduce costs by 50%.
            </p>
          </div>
        </>
      )}

      {/* Save Button */}
      <div className="flex justify-end gap-3">
        <button onClick={() => window.history.back()} className="px-4 py-2 border rounded-lg">
          Cancel
        </button>
        <button
          onClick={saveSettings}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
        >
          Save Settings
        </button>
      </div>
    </div>
  )
}

function LanguageSelector({
  selectedLanguages,
  onChange,
  options,
}: {
  selectedLanguages: string[]
  onChange: (langs: string[]) => void
  options: { code: string; label: string }[]
}) {
  const toggleLanguage = (code: string) => {
    if (selectedLanguages.includes(code)) {
      onChange(selectedLanguages.filter((l) => l !== code))
    } else {
      onChange([...selectedLanguages, code])
    }
  }

  return (
    <div className="grid grid-cols-2 gap-2">
      {options.map((option) => (
        <label
          key={option.code}
          className={`flex items-center gap-2 p-3 border rounded-lg cursor-pointer ${
            selectedLanguages.includes(option.code)
              ? 'bg-blue-50 border-blue-500'
              : 'hover:bg-gray-50'
          }`}
        >
          <input
            type="checkbox"
            checked={selectedLanguages.includes(option.code)}
            onChange={() => toggleLanguage(option.code)}
            className="w-4 h-4"
          />
          <span>{option.label}</span>
        </label>
      ))}
    </div>
  )
}

function ExampleEmail({
  lang,
  subject,
  result,
  willTranslate,
}: {
  lang: string
  subject: string
  result: string
  willTranslate: boolean
}) {
  return (
    <div className="flex items-center justify-between p-3 bg-white border rounded">
      <div>
        <span className="text-xs bg-gray-200 px-2 py-1 rounded mr-2">{lang.toUpperCase()}</span>
        <span className="text-sm">{subject}</span>
      </div>
      <span className={`text-xs ${willTranslate ? 'text-blue-600' : 'text-green-600'}`}>
        {result}
      </span>
    </div>
  )
}
```

---

## 4. Email Ingestion & Sync

### Gmail API Integration

```typescript
// svc-email/src/sync/gmail-sync.ts
import { google } from 'googleapis'

export class GmailSyncService {
  async syncAccount(account: EmailAccount) {
    const auth = this.getOAuth2Client(account)
    const gmail = google.gmail({ version: 'v1', auth })

    // Get last sync token (incremental sync)
    const historyId = account.config.gmail?.last_history_id

    if (historyId) {
      // Incremental sync using history API
      await this.syncHistory(gmail, account, historyId)
    } else {
      // Full sync (first time)
      await this.fullSync(gmail, account)
    }
  }

  private async fullSync(gmail: any, account: EmailAccount) {
    const response = await gmail.users.messages.list({
      userId: 'me',
      maxResults: 100,
      q: 'in:inbox OR in:sent', // Customize query
    })

    const messages = response.data.messages || []

    for (const message of messages) {
      const fullMessage = await gmail.users.messages.get({
        userId: 'me',
        id: message.id,
        format: 'full',
      })

      await this.processMessage(fullMessage.data, account)
    }
  }

  private async syncHistory(gmail: any, account: EmailAccount, startHistoryId: string) {
    const response = await gmail.users.history.list({
      userId: 'me',
      startHistoryId,
      historyTypes: ['messageAdded', 'messageDeleted'],
    })

    const history = response.data.history || []

    for (const record of history) {
      // Handle added messages
      if (record.messagesAdded) {
        for (const added of record.messagesAdded) {
          const fullMessage = await gmail.users.messages.get({
            userId: 'me',
            id: added.message.id,
            format: 'full',
          })
          await this.processMessage(fullMessage.data, account)
        }
      }

      // Handle deleted messages
      if (record.messagesDeleted) {
        for (const deleted of record.messagesDeleted) {
          await this.deleteMessage(deleted.message.id, account)
        }
      }
    }

    // Update last history ID
    await this.updateLastHistoryId(account.id, response.data.historyId)
  }

  private async processMessage(message: any, account: EmailAccount) {
    const headers = message.payload.headers

    const email = {
      account_id: account.id,
      tenant_id: account.tenant_id,
      user_id: account.user_id,
      message_id: this.getHeader(headers, 'Message-ID'),
      thread_id: message.threadId,
      from_email: this.parseEmail(this.getHeader(headers, 'From')),
      from_name: this.parseName(this.getHeader(headers, 'From')),
      to_emails: this.parseEmails(this.getHeader(headers, 'To')),
      cc_emails: this.parseEmails(this.getHeader(headers, 'Cc')),
      subject: this.getHeader(headers, 'Subject'),
      date: new Date(parseInt(message.internalDate)),
      body_text: this.extractTextBody(message.payload),
      body_html: this.extractHtmlBody(message.payload),
      snippet: message.snippet,
      has_attachments: message.payload.parts?.some(p => p.filename) || false,
      is_read: !message.labelIds?.includes('UNREAD'),
      is_sent: message.labelIds?.includes('SENT'),
    }

    // Save to database
    await this.saveEmail(email)

    // Process for categorization
    await this.categorizeEmail(email)

    // Extract credentials if present
    await this.extractCredentials(email)
  }
}
```

### IMAP/SMTP Integration

```typescript
// svc-email/src/sync/imap-sync.ts
import Imap from 'imap'
import { simpleParser } from 'mailparser'

export class ImapSyncService {
  async syncAccount(account: EmailAccount) {
    const config = account.config.imap_smtp!

    const imap = new Imap({
      user: config.username,
      password: await this.decryptPassword(config.password_encrypted),
      host: config.imap_host,
      port: config.imap_port,
      tls: config.imap_secure,
    })

    return new Promise((resolve, reject) => {
      imap.once('ready', async () => {
        try {
          await this.syncFolder(imap, account, 'INBOX')
          await this.syncFolder(imap, account, 'SENT')
          imap.end()
          resolve(true)
        } catch (error) {
          reject(error)
        }
      })

      imap.once('error', reject)
      imap.connect()
    })
  }

  private async syncFolder(imap: Imap, account: EmailAccount, folderName: string) {
    imap.openBox(folderName, false, (err, box) => {
      if (err) throw err

      // Fetch only new messages since last sync
      const lastSyncDate = account.last_synced_at || new Date('2024-01-01')
      const searchCriteria = ['UNSEEN', ['SINCE', lastSyncDate]]

      imap.search(searchCriteria, (err, results) => {
        if (err) throw err

        if (results.length === 0) {
          console.log('No new messages')
          return
        }

        const fetch = imap.fetch(results, { bodies: '' })

        fetch.on('message', (msg, seqno) => {
          msg.on('body', async (stream) => {
            const parsed = await simpleParser(stream)
            await this.processMessage(parsed, account, folderName)
          })
        })

        fetch.once('end', () => {
          console.log(`Synced ${results.length} messages from ${folderName}`)
        })
      })
    })
  }

  private async processMessage(parsed: any, account: EmailAccount, folder: string) {
    const email = {
      account_id: account.id,
      tenant_id: account.tenant_id,
      user_id: account.user_id,
      message_id: parsed.messageId,
      thread_id: parsed.inReplyTo || parsed.messageId, // Simple threading
      from_email: parsed.from.value[0].address,
      from_name: parsed.from.value[0].name,
      to_emails: parsed.to?.value.map(t => t.address) || [],
      cc_emails: parsed.cc?.value.map(t => t.address) || [],
      subject: parsed.subject,
      date: parsed.date,
      body_text: parsed.text,
      body_html: parsed.html,
      snippet: parsed.text?.substring(0, 200),
      has_attachments: parsed.attachments?.length > 0,
      folder: folder.toLowerCase(),
    }

    // Save attachments to S3
    if (parsed.attachments?.length > 0) {
      email.attachments = await this.saveAttachments(parsed.attachments, account)
    }

    await this.saveEmail(email)
    await this.categorizeEmail(email)
    await this.extractCredentials(email)
  }
}
```

---

## 3. Smart Categorization System

### AI-Powered Classification

```typescript
// svc-email/src/categorization/ai-classifier.ts

export enum EmailCategory {
  NEWSLETTER = 'newsletter',
  TRANSACTIONAL = 'transactional',
  RELEVANT = 'relevant', // Important/actionable
  SUPPLIER = 'supplier',
  SPAM = 'spam',
  COLD_REPLY = 'cold_reply', // Reply to cold outreach
  PERSONAL = 'personal',
}

export class EmailClassifier {
  async categorize(email: Email): Promise<{ category: EmailCategory; confidence: number }> {
    // Use GPT-4 for intelligent classification
    const prompt = `Classify this email into one of these categories:
- newsletter: Marketing emails, promotional content, bulk emails
- transactional: Order confirmations, receipts, shipping notifications
- relevant: Important emails requiring action or response
- supplier: Emails from vendors, contractors, service providers
- spam: Unwanted or suspicious emails
- cold_reply: Reply to a cold outreach email
- personal: Personal communication

Email details:
From: ${email.from_email}
Subject: ${email.subject}
Preview: ${email.snippet}

Return JSON: { "category": "...", "confidence": 0.95, "reasoning": "..." }`

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Fast & cheap
      messages: [
        { role: 'system', content: 'You are an email classification expert.' },
        { role: 'user', content: prompt },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.3,
    })

    const result = JSON.parse(response.choices[0].message.content)

    // Update email category
    await db.query(
      `UPDATE emails
       SET category = $1, ai_category_confidence = $2
       WHERE id = $3`,
      [result.category, result.confidence, email.id]
    )

    return { category: result.category, confidence: result.confidence }
  }

  // Rule-based classification (fast, no AI cost)
  async quickClassify(email: Email): Promise<EmailCategory | null> {
    const from = email.from_email.toLowerCase()
    const subject = email.subject?.toLowerCase() || ''

    // Newsletter patterns
    if (
      from.includes('newsletter') ||
      from.includes('marketing') ||
      from.includes('noreply') ||
      subject.includes('unsubscribe')
    ) {
      return EmailCategory.NEWSLETTER
    }

    // Transactional patterns
    if (
      subject.includes('receipt') ||
      subject.includes('order') ||
      subject.includes('invoice') ||
      subject.includes('payment') ||
      subject.includes('shipped')
    ) {
      return EmailCategory.TRANSACTIONAL
    }

    // Check if reply to cold outreach
    if (await this.isReplyToColdEmail(email)) {
      return EmailCategory.COLD_REPLY
    }

    return null // Needs AI classification
  }

  private async isReplyToColdEmail(email: Email): Promise<boolean> {
    // Check if this is a reply to an email we sent from cold outreach accounts
    if (!email.in_reply_to) return false

    const originalEmail = await db.query(
      `SELECT ea.purpose
       FROM emails e
       JOIN email_accounts ea ON e.account_id = ea.id
       WHERE e.message_id = $1`,
      [email.in_reply_to]
    )

    return originalEmail.rows[0]?.purpose === 'cold_outreach'
  }
}
```

### Auto-Folder Rules

```typescript
// svc-email/src/categorization/auto-folder.ts

export class AutoFolderService {
  async applyRules(email: Email) {
    // Get user's custom folders with auto-move rules
    const folders = await db.query(
      `SELECT * FROM email_folders
       WHERE tenant_id = $1 AND user_id = $2 AND auto_move_enabled = true`,
      [email.tenant_id, email.user_id]
    )

    for (const folder of folders.rows) {
      const rules = folder.auto_move_rules

      if (this.matchesRules(email, rules)) {
        await this.moveToFolder(email.id, folder.name)
        break
      }
    }

    // Default categorization folders
    if (email.category === 'newsletter') {
      await this.moveToFolder(email.id, 'Newsletters')
    } else if (email.category === 'transactional') {
      await this.moveToFolder(email.id, 'Receipts')
    } else if (email.category === 'cold_reply') {
      await this.moveToFolder(email.id, 'Cold Replies')
      await this.createCrmLead(email)
    }
  }

  private matchesRules(email: Email, rules: any): boolean {
    if (rules.from_contains) {
      for (const pattern of rules.from_contains) {
        if (email.from_email.includes(pattern)) return true
      }
    }

    if (rules.subject_contains) {
      for (const pattern of rules.subject_contains) {
        if (email.subject?.includes(pattern)) return true
      }
    }

    if (rules.category && email.category === rules.category) {
      return true
    }

    return false
  }
}
```

---

## 4. Full-Text Search

### Search API

```typescript
// svc-email/src/search/email-search.ts

export interface EmailSearchQuery {
  query?: string // Full-text search
  from?: string
  to?: string
  subject?: string
  category?: EmailCategory
  folder?: string
  has_attachments?: boolean
  is_read?: boolean
  is_starred?: boolean
  date_from?: Date
  date_to?: Date
  account_ids?: string[]
  labels?: string[]
}

export class EmailSearchService {
  async search(
    tenantId: string,
    userId: string,
    query: EmailSearchQuery,
    limit: number = 50,
    offset: number = 0
  ): Promise<{ emails: Email[]; total: number }> {
    let sql = `
      SELECT *,
        ts_rank(search_vector, websearch_to_tsquery('english', $1)) AS rank
      FROM emails
      WHERE tenant_id = $2 AND user_id = $3
    `

    const params: any[] = [query.query || '', tenantId, userId]
    let paramIndex = 4

    // Full-text search
    if (query.query) {
      sql += ` AND search_vector @@ websearch_to_tsquery('english', $1)`
    }

    // From filter
    if (query.from) {
      sql += ` AND from_email ILIKE $${paramIndex}`
      params.push(`%${query.from}%`)
      paramIndex++
    }

    // Subject filter
    if (query.subject) {
      sql += ` AND subject ILIKE $${paramIndex}`
      params.push(`%${query.subject}%`)
      paramIndex++
    }

    // Category filter
    if (query.category) {
      sql += ` AND category = $${paramIndex}`
      params.push(query.category)
      paramIndex++
    }

    // Folder filter
    if (query.folder) {
      sql += ` AND folder = $${paramIndex}`
      params.push(query.folder)
      paramIndex++
    }

    // Attachments filter
    if (query.has_attachments !== undefined) {
      sql += ` AND has_attachments = $${paramIndex}`
      params.push(query.has_attachments)
      paramIndex++
    }

    // Read status
    if (query.is_read !== undefined) {
      sql += ` AND is_read = $${paramIndex}`
      params.push(query.is_read)
      paramIndex++
    }

    // Date range
    if (query.date_from) {
      sql += ` AND date >= $${paramIndex}`
      params.push(query.date_from)
      paramIndex++
    }

    if (query.date_to) {
      sql += ` AND date <= $${paramIndex}`
      params.push(query.date_to)
      paramIndex++
    }

    // Account filter
    if (query.account_ids?.length) {
      sql += ` AND account_id = ANY($${paramIndex})`
      params.push(query.account_ids)
      paramIndex++
    }

    // Labels filter
    if (query.labels?.length) {
      sql += ` AND labels && $${paramIndex}::text[]`
      params.push(query.labels)
      paramIndex++
    }

    // Order by relevance (if text search) or date
    if (query.query) {
      sql += ` ORDER BY rank DESC, date DESC`
    } else {
      sql += ` ORDER BY date DESC`
    }

    // Pagination
    sql += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`
    params.push(limit, offset)

    const result = await db.query(sql, params)

    // Get total count
    const countResult = await db.query(
      sql.replace('SELECT *', 'SELECT COUNT(*)').split('ORDER BY')[0],
      params.slice(0, -2) // Remove limit/offset
    )

    return {
      emails: result.rows,
      total: parseInt(countResult.rows[0].count),
    }
  }
}
```

---

## 5. Credentials Vault

### Auto-Extract Credentials from Emails

```typescript
// svc-email/src/credentials/credential-extractor.ts

export class CredentialExtractor {
  async extractFromEmail(email: Email) {
    // Check if email looks like signup/welcome/password reset
    const isRelevant = this.isCredentialEmail(email)
    if (!isRelevant) return

    // Use GPT-4 to extract credentials
    const prompt = `Extract login credentials from this email if present.

Email:
From: ${email.from_email}
Subject: ${email.subject}
Body:
${email.body_text}

Extract:
- Service name (e.g., "GitHub", "AWS Console")
- Service URL
- Username or email
- Password (if visible)

Return JSON: { "service_name": "...", "service_url": "...", "username": "...", "password": "...", "confidence": 0.95 }
If no credentials found, return: { "found": false }`

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: 'You are a credential extraction expert. Extract login details from emails.' },
        { role: 'user', content: prompt },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.1,
    })

    const result = JSON.parse(response.choices[0].message.content)

    if (result.found === false) return

    // Encrypt password
    const encryptedPassword = await this.encryptPassword(result.password)

    // Save to credentials vault
    await db.query(
      `INSERT INTO email_credentials (
        tenant_id, user_id, email_id,
        service_name, service_url, username, email_address,
        password_encrypted, extraction_confidence
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        email.tenant_id,
        email.user_id,
        email.id,
        result.service_name,
        result.service_url,
        result.username,
        result.email || email.to_emails[0],
        encryptedPassword,
        result.confidence,
      ]
    )

    // Update email to mark it has extracted credentials
    await db.query(
      `UPDATE emails
       SET extracted_credentials = $1
       WHERE id = $2`,
      [JSON.stringify({ service: result.service_name }), email.id]
    )
  }

  private isCredentialEmail(email: Email): boolean {
    const subject = email.subject?.toLowerCase() || ''
    const body = email.body_text?.toLowerCase() || ''

    const patterns = [
      'welcome',
      'account created',
      'verify your email',
      'password',
      'login',
      'credentials',
      'access code',
      'temporary password',
      'reset password',
      'new account',
    ]

    return patterns.some(p => subject.includes(p) || body.includes(p))
  }

  private async encryptPassword(password: string): Promise<string> {
    const iv = crypto.randomBytes(16)
    const cipher = crypto.createCipheriv('aes-256-gcm', ENCRYPTION_KEY, iv)

    let encrypted = cipher.update(password, 'utf8', 'hex')
    encrypted += cipher.final('hex')

    const authTag = cipher.getAuthTag()

    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`
  }
}
```

### Credentials Vault UI

```tsx
// app-web-frontend/pages/email/credentials.tsx

export default function CredentialsVault() {
  const [credentials, setCredentials] = useState<Credential[]>([])
  const [showPassword, setShowPassword] = useState<Record<string, boolean>>({})

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">🔐 Credentials Vault</h1>
          <p className="text-gray-600">
            Login credentials automatically extracted from your emails
          </p>
        </div>

        <button className="bg-blue-500 text-white px-4 py-2 rounded-lg">
          + Add Manual Credential
        </button>
      </div>

      {/* Credentials Table */}
      <div className="border rounded-lg overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-semibold">Service</th>
              <th className="px-4 py-3 text-left text-xs font-semibold">Username/Email</th>
              <th className="px-4 py-3 text-left text-xs font-semibold">Password</th>
              <th className="px-4 py-3 text-left text-xs font-semibold">Source Email</th>
              <th className="px-4 py-3 text-left text-xs font-semibold">Extracted</th>
              <th className="px-4 py-3 text-center text-xs font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {credentials.map((cred) => (
              <tr key={cred.id} className="hover:bg-gray-50">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <img
                      src={`https://www.google.com/s2/favicons?domain=${cred.service_url}`}
                      className="w-4 h-4"
                    />
                    <div>
                      <p className="font-semibold">{cred.service_name}</p>
                      {cred.service_url && (
                        <a
                          href={cred.service_url}
                          target="_blank"
                          className="text-xs text-blue-600 hover:underline"
                        >
                          {new URL(cred.service_url).hostname}
                        </a>
                      )}
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3">
                  <p className="font-mono text-sm">{cred.username || cred.email_address}</p>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <code className="bg-gray-100 px-2 py-1 rounded text-sm">
                      {showPassword[cred.id] ? cred.password : '••••••••'}
                    </code>
                    <button
                      onClick={() =>
                        setShowPassword({ ...showPassword, [cred.id]: !showPassword[cred.id] })
                      }
                      className="text-gray-500 hover:text-gray-700"
                    >
                      {showPassword[cred.id] ? '🙈' : '👁️'}
                    </button>
                    <button
                      onClick={() => copyToClipboard(cred.password)}
                      className="text-gray-500 hover:text-gray-700"
                    >
                      📋
                    </button>
                  </div>
                </td>
                <td className="px-4 py-3">
                  {cred.email_id && (
                    <a
                      href={`/email/view/${cred.email_id}`}
                      className="text-blue-600 text-sm hover:underline"
                    >
                      View email →
                    </a>
                  )}
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">
                  {new Date(cred.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-center">
                  <div className="flex justify-center gap-2">
                    <button className="text-blue-600 text-sm hover:underline">Edit</button>
                    <button className="text-red-600 text-sm hover:underline">Delete</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Security Notice */}
      <div className="mt-6 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <p className="text-sm text-yellow-800">
          🔒 All passwords are encrypted using AES-256-GCM. Only you can decrypt them with your
          account key.
        </p>
      </div>
    </div>
  )
}
```

---

## 6. Cold Email CRM Integration

### Campaign Tracking

```sql
-- Cold email campaigns
CREATE TABLE cold_email_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Campaign settings
  sender_accounts UUID[] NOT NULL, -- Array of email_account IDs
  target_list_id UUID, -- Reference to CRM list

  -- Stats
  emails_sent INTEGER DEFAULT 0,
  emails_opened INTEGER DEFAULT 0,
  emails_replied INTEGER DEFAULT 0,
  leads_created INTEGER DEFAULT 0,

  status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'active', 'paused', 'completed'

  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cold email tracking
CREATE TABLE cold_email_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES cold_email_campaigns(id),
  email_id UUID NOT NULL REFERENCES emails(id),

  recipient_email VARCHAR(255) NOT NULL,

  sent_at TIMESTAMPTZ NOT NULL,
  opened_at TIMESTAMPTZ,
  replied_at TIMESTAMPTZ,

  reply_email_id UUID REFERENCES emails(id), -- Link to reply
  crm_contact_created BOOLEAN DEFAULT false,
  crm_contact_id UUID,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cold_tracking_campaign ON cold_email_tracking(campaign_id);
CREATE INDEX idx_cold_tracking_recipient ON cold_email_tracking(recipient_email);
```

### Reply Processor

```typescript
// svc-email/src/cold-email/reply-processor.ts

export class ColdEmailReplyProcessor {
  async processReply(email: Email) {
    // Find original cold email this is replying to
    const originalEmail = await this.findOriginalColdEmail(email)
    if (!originalEmail) return

    // Get campaign
    const tracking = await db.query(
      `SELECT * FROM cold_email_tracking WHERE email_id = $1`,
      [originalEmail.id]
    )

    if (tracking.rows.length === 0) return

    const track = tracking.rows[0]

    // Update tracking
    await db.query(
      `UPDATE cold_email_tracking
       SET replied_at = NOW(), reply_email_id = $1
       WHERE id = $2`,
      [email.id, track.id]
    )

    // Update campaign stats
    await db.query(
      `UPDATE cold_email_campaigns
       SET emails_replied = emails_replied + 1
       WHERE id = $1`,
      [track.campaign_id]
    )

    // Create CRM contact if doesn't exist
    await this.createOrUpdateCrmContact(email, track.campaign_id)

    // Mark email as cold reply
    await db.query(
      `UPDATE emails
       SET is_cold_reply = true, campaign_id = $1
       WHERE id = $2`,
      [track.campaign_id, email.id]
    )

    // Send notification to user
    await this.notifyNewReply(email, track.campaign_id)
  }

  private async createOrUpdateCrmContact(email: Email, campaignId: string) {
    // Check if contact exists
    const existing = await db.query(
      `SELECT id FROM crm_contacts WHERE email = $1`,
      [email.from_email]
    )

    if (existing.rows.length > 0) {
      // Update existing contact
      const contactId = existing.rows[0].id

      await db.query(
        `UPDATE crm_contacts
         SET
           last_interaction = NOW(),
           cold_campaign_id = $1,
           status = 'replied'
         WHERE id = $2`,
        [campaignId, contactId]
      )

      return contactId
    } else {
      // Create new contact
      const result = await db.query(
        `INSERT INTO crm_contacts (
          tenant_id, email, name, source, cold_campaign_id, status
        ) VALUES ($1, $2, $3, 'cold_email', $4, 'replied')
        RETURNING id`,
        [email.tenant_id, email.from_email, email.from_name, campaignId]
      )

      const contactId = result.rows[0].id

      // Update tracking
      await db.query(
        `UPDATE cold_email_tracking
         SET crm_contact_created = true, crm_contact_id = $1
         WHERE campaign_id = $2 AND recipient_email = $3`,
        [contactId, campaignId, email.from_email]
      )

      return contactId
    }
  }
}
```

---

## 7. AI Quick Reply & Smart Routing

### AI Quick Reply System

#### Database Schema

```sql
-- Reply templates (pre-configured responses)
CREATE TABLE email_reply_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID, -- NULL = shared template for all users in tenant

  name VARCHAR(255) NOT NULL, -- e.g., "Accetta proposta", "Rifiuta gentilmente"
  description TEXT,
  category VARCHAR(50), -- 'quick_reply', 'appointment', 'reject', 'accept', 'custom'

  -- Template content
  subject_template TEXT,
  body_template TEXT,
  body_html_template TEXT,

  -- Variables in template: {{sender_name}}, {{user_name}}, {{date}}, etc.
  variables JSONB, -- { "sender_name": "required", "date": "optional" }

  -- Trigger conditions (when to suggest this template)
  auto_suggest_rules JSONB, -- { from_contains: [], subject_contains: [], body_contains: [] }

  -- Calendar integration
  creates_calendar_event BOOLEAN DEFAULT false,
  calendar_event_template JSONB, -- { title: "...", duration: 60, location: "..." }

  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conditional reply rules (if X then Y)
CREATE TABLE email_reply_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID, -- NULL = applies to all users

  name VARCHAR(255) NOT NULL,
  description TEXT,
  enabled BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0, -- Higher priority rules execute first

  -- Conditions (when this rule applies)
  conditions JSONB NOT NULL,
  /* Example conditions:
  {
    "from_email": { "equals": "tizio@example.com" },
    "from_domain": { "contains": ["supplier.com", "vendor.com"] },
    "subject": { "contains": ["pagamento", "fattura"] },
    "body": { "contains": ["appuntamento", "meeting"] },
    "category": { "equals": "transactional" },
    "crm_contact_exists": true,
    "crm_contact_status": { "equals": "cliente" }
  }
  */

  -- Actions (what to do when conditions match)
  actions JSONB NOT NULL,
  /* Example actions:
  {
    "auto_reply": {
      "template_id": "uuid",
      "require_approval": true
    },
    "forward_to": "accounting@company.com",
    "assign_to_user": "user_id",
    "route_to_team": "team_id",
    "create_task": { "title": "...", "assigned_to": "..." },
    "add_label": ["importante", "urgente"]
  }
  */

  execution_count INTEGER DEFAULT 0,
  last_executed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Email routing assignments (for generic inboxes)
CREATE TABLE email_routing_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email_id UUID NOT NULL REFERENCES emails(id),
  tenant_id UUID NOT NULL,

  -- Original recipient (generic inbox)
  original_to_email VARCHAR(255) NOT NULL, -- e.g., info@company.com

  -- Routed to
  assigned_to_user_id UUID, -- Assigned to specific user
  assigned_to_team_id UUID, -- Assigned to team
  forwarded_to_email VARCHAR(255), -- Forwarded to external email

  -- Routing reason
  routing_rule_id UUID REFERENCES email_reply_rules(id),
  routing_reason TEXT,

  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'completed', 'rejected'
  accepted_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Calendar integration
CREATE TABLE calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL, -- Event owner

  title VARCHAR(255) NOT NULL,
  description TEXT,
  location VARCHAR(255),

  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  all_day BOOLEAN DEFAULT false,

  -- Attendees
  attendees JSONB, -- [{ email, name, response_status }]

  -- Integration
  email_id UUID REFERENCES emails(id), -- Created from email
  crm_contact_id UUID, -- Related to CRM contact

  -- Calendar sync
  google_calendar_id VARCHAR(255),
  outlook_calendar_id VARCHAR(255),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reply_templates_tenant ON email_reply_templates(tenant_id, category);
CREATE INDEX idx_reply_rules_tenant ON email_reply_rules(tenant_id, enabled);
CREATE INDEX idx_routing_assignments_email ON email_routing_assignments(email_id);
CREATE INDEX idx_routing_assignments_user ON email_routing_assignments(assigned_to_user_id, status);
CREATE INDEX idx_calendar_events_user ON calendar_events(user_id, start_time);
```

### AI Quick Reply Service

```typescript
// svc-email/src/quick-reply/ai-reply-generator.ts

export class AIReplyGenerator {
  // Generate AI-powered reply suggestions
  async generateReplySuggestions(email: Email): Promise<ReplySuggestion[]> {
    // 1. Get pre-configured templates that match
    const matchingTemplates = await this.getMatchingTemplates(email)

    // 2. Generate AI suggestions
    const aiSuggestions = await this.generateAISuggestions(email)

    // 3. Combine and rank
    return [...matchingTemplates, ...aiSuggestions].slice(0, 5) // Top 5
  }

  private async getMatchingTemplates(email: Email): Promise<ReplySuggestion[]> {
    // Find templates with matching auto_suggest_rules
    const templates = await db.query(
      `SELECT * FROM email_reply_templates
       WHERE tenant_id = $1
       AND auto_suggest_rules IS NOT NULL`,
      [email.tenant_id]
    )

    const matching: ReplySuggestion[] = []

    for (const template of templates.rows) {
      const rules = template.auto_suggest_rules

      // Check if rules match this email
      if (this.matchesRules(email, rules)) {
        matching.push({
          id: template.id,
          type: 'template',
          label: template.name,
          description: template.description,
          template_id: template.id,
          confidence: 0.95,
        })
      }
    }

    return matching
  }

  private matchesRules(email: Email, rules: any): boolean {
    if (rules.from_contains) {
      const match = rules.from_contains.some((str: string) =>
        email.from_email.toLowerCase().includes(str.toLowerCase())
      )
      if (!match) return false
    }

    if (rules.subject_contains) {
      const match = rules.subject_contains.some((str: string) =>
        email.subject?.toLowerCase().includes(str.toLowerCase())
      )
      if (!match) return false
    }

    if (rules.body_contains) {
      const match = rules.body_contains.some((str: string) =>
        email.body_text?.toLowerCase().includes(str.toLowerCase())
      )
      if (!match) return false
    }

    return true
  }

  private async generateAISuggestions(email: Email): Promise<ReplySuggestion[]> {
    // Use GPT-4 to generate smart reply suggestions
    const prompt = `You are an email assistant. Analyze this email and suggest 3-5 quick reply options.

Email:
From: ${email.from_email}
Subject: ${email.subject}
Body:
${email.body_text?.substring(0, 1000)}

Generate reply suggestions with:
1. A short label (2-4 words in Italian)
2. Brief description
3. Confidence score (0-1)

Return JSON array:
[
  {
    "label": "Accetta proposta",
    "description": "Risposta positiva con disponibilità",
    "type": "accept",
    "confidence": 0.85
  },
  ...
]`

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: 'You are an email assistant specialized in Italian business communication.' },
        { role: 'user', content: prompt },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.3,
    })

    const suggestions = JSON.parse(response.choices[0].message.content)

    return suggestions.suggestions.map((s: any) => ({
      id: `ai-${Date.now()}-${Math.random()}`,
      type: 'ai_generated',
      label: s.label,
      description: s.description,
      reply_type: s.type,
      confidence: s.confidence,
    }))
  }

  // Generate full reply draft based on selected suggestion
  async generateReplyDraft(
    email: Email,
    suggestion: ReplySuggestion,
    userContext?: any
  ): Promise<EmailDraft> {
    if (suggestion.type === 'template') {
      // Use template
      return this.generateFromTemplate(email, suggestion.template_id!, userContext)
    } else {
      // AI-generated reply
      return this.generateAIReply(email, suggestion, userContext)
    }
  }

  private async generateFromTemplate(
    email: Email,
    templateId: string,
    userContext?: any
  ): Promise<EmailDraft> {
    const template = await db.query(
      `SELECT * FROM email_reply_templates WHERE id = $1`,
      [templateId]
    )

    if (template.rows.length === 0) {
      throw new Error('Template not found')
    }

    const tmpl = template.rows[0]

    // Replace variables in template
    let subject = tmpl.subject_template
    let body = tmpl.body_template

    const variables = {
      sender_name: email.from_name || email.from_email.split('@')[0],
      sender_email: email.from_email,
      user_name: userContext?.name || 'Il Team',
      company_name: userContext?.company || 'Azienda',
      date: new Date().toLocaleDateString('it-IT'),
      time: new Date().toLocaleTimeString('it-IT', { hour: '2-digit', minute: '2-digit' }),
    }

    // Replace {{variable}} with values
    for (const [key, value] of Object.entries(variables)) {
      subject = subject?.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), value)
      body = body.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), value)
    }

    return {
      to: email.from_email,
      subject: subject || `RE: ${email.subject}`,
      body_text: body,
      in_reply_to: email.message_id,
      template_id: templateId,
    }
  }

  private async generateAIReply(
    email: Email,
    suggestion: ReplySuggestion,
    userContext?: any
  ): Promise<EmailDraft> {
    const prompt = `Generate a professional email reply in Italian based on this context:

Original email:
From: ${email.from_name} <${email.from_email}>
Subject: ${email.subject}
Body:
${email.body_text?.substring(0, 1000)}

Reply type: ${suggestion.label}
Intent: ${suggestion.description}

User context:
- Name: ${userContext?.name || 'Il Team'}
- Company: ${userContext?.company || 'Azienda'}
- Role: ${userContext?.role || 'Assistente'}

Generate a complete, professional reply email in Italian.
Keep it concise (max 200 words), friendly but professional.

Return JSON:
{
  "subject": "RE: ...",
  "body": "Gentile [name],\\n\\n..."
}`

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: 'You are a professional email writer for Italian business communication.' },
        { role: 'user', content: prompt },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.7,
    })

    const reply = JSON.parse(response.choices[0].message.content)

    return {
      to: email.from_email,
      subject: reply.subject,
      body_text: reply.body,
      in_reply_to: email.message_id,
    }
  }
}
```

### Smart Email Routing Service

```typescript
// svc-email/src/routing/email-router.ts

export class EmailRoutingService {
  async processIncomingEmail(email: Email) {
    // Check if email is to a generic inbox (info@, support@, etc.)
    if (!this.isGenericInbox(email.to_emails[0])) {
      return // Skip routing for personal inboxes
    }

    // Find matching routing rules
    const rules = await this.getMatchingRules(email)

    for (const rule of rules) {
      await this.executeRule(email, rule)
    }
  }

  private isGenericInbox(email: string): boolean {
    const genericPrefixes = ['info', 'support', 'help', 'contact', 'sales', 'hello', 'admin']
    const prefix = email.split('@')[0].toLowerCase()
    return genericPrefixes.includes(prefix)
  }

  private async getMatchingRules(email: Email): Promise<EmailReplyRule[]> {
    const rules = await db.query(
      `SELECT * FROM email_reply_rules
       WHERE tenant_id = $1 AND enabled = true
       ORDER BY priority DESC`,
      [email.tenant_id]
    )

    const matching: EmailReplyRule[] = []

    for (const rule of rules.rows) {
      if (await this.evaluateConditions(email, rule.conditions)) {
        matching.push(rule)
      }
    }

    return matching
  }

  private async evaluateConditions(email: Email, conditions: any): Promise<boolean> {
    // From email exact match
    if (conditions.from_email?.equals) {
      if (email.from_email !== conditions.from_email.equals) return false
    }

    // From domain contains
    if (conditions.from_domain?.contains) {
      const domain = email.from_email.split('@')[1]
      const match = conditions.from_domain.contains.some((d: string) =>
        domain.includes(d)
      )
      if (!match) return false
    }

    // Subject contains keywords
    if (conditions.subject?.contains) {
      const match = conditions.subject.contains.some((keyword: string) =>
        email.subject?.toLowerCase().includes(keyword.toLowerCase())
      )
      if (!match) return false
    }

    // Body contains keywords
    if (conditions.body?.contains) {
      const match = conditions.body.contains.some((keyword: string) =>
        email.body_text?.toLowerCase().includes(keyword.toLowerCase())
      )
      if (!match) return false
    }

    // Category match
    if (conditions.category?.equals) {
      if (email.category !== conditions.category.equals) return false
    }

    // CRM contact integration
    if (conditions.crm_contact_exists) {
      const contactExists = await this.checkCRMContact(email.from_email, email.tenant_id)
      if (!contactExists) return false
    }

    if (conditions.crm_contact_status) {
      const contact = await this.getCRMContact(email.from_email, email.tenant_id)
      if (!contact || contact.status !== conditions.crm_contact_status.equals) {
        return false
      }
    }

    return true
  }

  private async executeRule(email: Email, rule: EmailReplyRule) {
    const actions = rule.actions

    // Auto-reply
    if (actions.auto_reply) {
      await this.createAutoReplyDraft(email, actions.auto_reply)
    }

    // Forward to email
    if (actions.forward_to) {
      await this.forwardEmail(email, actions.forward_to)
    }

    // Assign to user
    if (actions.assign_to_user) {
      await this.assignToUser(email, actions.assign_to_user, rule.id)
    }

    // Route to team
    if (actions.route_to_team) {
      await this.routeToTeam(email, actions.route_to_team, rule.id)
    }

    // Create task
    if (actions.create_task) {
      await this.createTask(email, actions.create_task)
    }

    // Add labels
    if (actions.add_label) {
      await this.addLabels(email.id, actions.add_label)
    }

    // Update rule execution count
    await db.query(
      `UPDATE email_reply_rules
       SET execution_count = execution_count + 1, last_executed_at = NOW()
       WHERE id = $1`,
      [rule.id]
    )
  }

  private async assignToUser(email: Email, userId: string, ruleId: string) {
    // Create routing assignment
    await db.query(
      `INSERT INTO email_routing_assignments (
        email_id, tenant_id, original_to_email,
        assigned_to_user_id, routing_rule_id,
        routing_reason, status
      ) VALUES ($1, $2, $3, $4, $5, $6, 'pending')`,
      [
        email.id,
        email.tenant_id,
        email.to_emails[0],
        userId,
        ruleId,
        'Auto-assigned by routing rule',
      ]
    )

    // Send notification to user
    await this.notifyUserAssignment(userId, email)
  }

  // CRM Integration: Route to assigned technician
  private async getCRMContact(emailAddress: string, tenantId: string) {
    const result = await db.query(
      `SELECT * FROM crm_contacts WHERE email = $1 AND tenant_id = $2`,
      [emailAddress, tenantId]
    )

    return result.rows[0] || null
  }

  async routeToAssignedTechnician(email: Email) {
    // Get CRM contact
    const contact = await this.getCRMContact(email.from_email, email.tenant_id)

    if (!contact || !contact.assigned_technician_id) {
      return // No assigned technician
    }

    // Route email to technician
    await this.assignToUser(email, contact.assigned_technician_id, 'crm-auto-route')

    // Optionally: Create appointment suggestion
    await this.suggestAppointment(email, contact)
  }
}
```

---

## 8. Email Client UI

### Inbox View

```tsx
// app-web-frontend/pages/email/inbox.tsx

export default function EmailInbox() {
  const [selectedFolder, setSelectedFolder] = useState('inbox')
  const [selectedEmail, setSelectedEmail] = useState<Email | null>(null)
  const [emails, setEmails] = useState<Email[]>([])
  const [searchQuery, setSearchQuery] = useState('')

  return (
    <div className="flex h-screen">
      {/* Left Sidebar - Folders */}
      <div className="w-64 bg-gray-50 border-r overflow-y-auto">
        <div className="p-4">
          <button className="w-full bg-blue-500 text-white py-2 rounded-lg mb-4">
            ✉️ Compose
          </button>

          <div className="space-y-1">
            <FolderItem icon="📥" name="Inbox" count={125} active />
            <FolderItem icon="⭐" name="Starred" count={12} />
            <FolderItem icon="📤" name="Sent" count={89} />
            <FolderItem icon="📝" name="Drafts" count={3} />
            <FolderItem icon="🗄️" name="Archive" count={1240} />
            <FolderItem icon="🗑️" name="Trash" count={45} />
          </div>

          <div className="mt-6">
            <h3 className="text-xs font-semibold text-gray-500 uppercase mb-2">Categories</h3>
            <CategoryItem icon="📰" name="Newsletters" count={45} color="blue" />
            <CategoryItem icon="🧾" name="Receipts" count={23} color="green" />
            <CategoryItem icon="📧" name="Cold Replies" count={8} color="orange" />
            <CategoryItem icon="👥" name="Suppliers" count={15} color="purple" />
          </div>

          <div className="mt-6">
            <h3 className="text-xs font-semibold text-gray-500 uppercase mb-2">Accounts</h3>
            <AccountItem email="john@company.com" unread={12} />
            <AccountItem email="john@personal.com" unread={5} />
            <AccountItem email="cold1@domain1.com" unread={2} purpose="cold" />
          </div>
        </div>
      </div>

      {/* Middle Panel - Email List */}
      <div className="w-96 border-r flex flex-col">
        {/* Search Bar */}
        <div className="p-4 border-b">
          <input
            type="text"
            placeholder="Search emails..."
            className="w-full border rounded-lg px-3 py-2"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {/* Email List */}
        <div className="flex-1 overflow-y-auto">
          {emails.map((email) => (
            <EmailListItem
              key={email.id}
              email={email}
              selected={selectedEmail?.id === email.id}
              onClick={() => setSelectedEmail(email)}
            />
          ))}
        </div>
      </div>

      {/* Right Panel - Email Content */}
      <div className="flex-1 flex flex-col">
        {selectedEmail ? (
          <EmailViewer email={selectedEmail} />
        ) : (
          <div className="flex items-center justify-center h-full text-gray-400">
            Select an email to view
          </div>
        )}
      </div>
    </div>
  )
}

function EmailListItem({ email, selected, onClick }) {
  // Show translated content if available, otherwise original
  const displaySubject = email.translated ? email.translated_subject : email.subject
  const displaySnippet = email.translated ? email.translated_body_text?.substring(0, 200) : email.snippet

  return (
    <div
      className={`p-4 border-b cursor-pointer hover:bg-gray-50 ${
        selected ? 'bg-blue-50 border-l-4 border-blue-500' : ''
      } ${!email.is_read ? 'bg-blue-50/30 font-semibold' : ''}`}
      onClick={onClick}
    >
      <div className="flex items-start justify-between mb-1">
        <span className="text-sm font-semibold">{email.from_name || email.from_email}</span>
        <div className="flex items-center gap-2">
          {/* Language badge */}
          {email.detected_language && (
            <span className="text-xs bg-gray-100 px-1.5 py-0.5 rounded">
              {email.detected_language.toUpperCase()}
            </span>
          )}
          <span className="text-xs text-gray-500">{formatDate(email.date)}</span>
        </div>
      </div>

      {/* Account indicator (for unified view) */}
      {email.account_email && (
        <div className="text-xs text-gray-500 mb-1">
          via {email.account_email}
        </div>
      )}

      <div className="text-sm mb-1">{displaySubject}</div>
      <div className="text-xs text-gray-600 truncate">{displaySnippet}</div>

      {/* Badges */}
      <div className="flex gap-1 mt-2">
        {email.translated && (
          <span className="text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded">
            🌐 Translated
          </span>
        )}
        {email.has_attachments && (
          <span className="text-xs bg-gray-200 px-1.5 py-0.5 rounded">📎</span>
        )}
        {email.category === 'cold_reply' && (
          <span className="text-xs bg-orange-100 text-orange-700 px-1.5 py-0.5 rounded">
            Cold Reply
          </span>
        )}
        {email.extracted_credentials && (
          <span className="text-xs bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded">
            🔐 Credentials
          </span>
        )}
      </div>
    </div>
  )
}

function EmailViewer({ email }: { email: Email }) {
  const [viewMode, setViewMode] = useState<'translation' | 'original' | 'side-by-side'>('translation')

  return (
    <div className="flex flex-col h-full">
      {/* Email Header */}
      <div className="p-6 border-b">
        <div className="flex items-start justify-between mb-4">
          <div className="flex-1">
            {/* Subject - show both if side-by-side, otherwise based on mode */}
            {viewMode === 'side-by-side' && email.translated ? (
              <div className="grid grid-cols-2 gap-4 mb-2">
                <div>
                  <span className="text-xs text-gray-500 block mb-1">
                    Original ({email.detected_language?.toUpperCase()})
                  </span>
                  <h2 className="text-xl font-semibold">{email.subject}</h2>
                </div>
                <div>
                  <span className="text-xs text-gray-500 block mb-1">
                    Translation ({email.translation_target_lang?.toUpperCase()})
                  </span>
                  <h2 className="text-xl font-semibold">{email.translated_subject}</h2>
                </div>
              </div>
            ) : (
              <h1 className="text-2xl font-semibold mb-2">
                {viewMode === 'original' || !email.translated ? email.subject : email.translated_subject}
              </h1>
            )}

            <div className="flex items-center gap-3 text-sm text-gray-600">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-blue-500 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                  {email.from_name?.[0] || email.from_email[0].toUpperCase()}
                </div>
                <div>
                  <p className="font-semibold text-gray-900">{email.from_name || email.from_email}</p>
                  <p className="text-xs text-gray-500">{email.from_email}</p>
                </div>
              </div>

              <span className="text-gray-400">•</span>
              <span>{formatDate(email.date, true)}</span>
            </div>

            {/* Translation view mode selector */}
            {email.translated && (
              <div className="mt-3 flex items-center gap-3">
                <span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded flex items-center gap-1">
                  🌐 Translated from {email.detected_language?.toUpperCase()} to{' '}
                  {email.translation_target_lang?.toUpperCase()}
                </span>

                {/* 3-button view mode selector */}
                <div className="flex items-center gap-1 bg-gray-100 rounded p-1">
                  <button
                    onClick={() => setViewMode('translation')}
                    className={`px-3 py-1 text-xs rounded transition ${
                      viewMode === 'translation'
                        ? 'bg-white shadow-sm font-semibold'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                    title="Show only translation"
                  >
                    Translation
                  </button>
                  <button
                    onClick={() => setViewMode('original')}
                    className={`px-3 py-1 text-xs rounded transition ${
                      viewMode === 'original'
                        ? 'bg-white shadow-sm font-semibold'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                    title="Show only original"
                  >
                    Original
                  </button>
                  <button
                    onClick={() => setViewMode('side-by-side')}
                    className={`px-3 py-1 text-xs rounded transition ${
                      viewMode === 'side-by-side'
                        ? 'bg-white shadow-sm font-semibold'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                    title="Show both side-by-side"
                  >
                    <span className="hidden sm:inline">Side-by-Side</span>
                    <span className="sm:hidden">⇆</span>
                  </button>
                </div>
              </div>
            )}
          </div>

          <div className="flex gap-2">
            <button className="p-2 hover:bg-gray-100 rounded">↩️ Reply</button>
            <button className="p-2 hover:bg-gray-100 rounded">↪️ Forward</button>
            <button className="p-2 hover:bg-gray-100 rounded">🗑️ Delete</button>
            <button className="p-2 hover:bg-gray-100 rounded">⭐ Star</button>
          </div>
        </div>

        {/* Attachments */}
        {email.has_attachments && email.attachments && (
          <div className="mt-4 p-3 bg-gray-50 rounded-lg">
            <h3 className="text-xs font-semibold text-gray-600 mb-2">ATTACHMENTS</h3>
            <div className="flex gap-2">
              {JSON.parse(email.attachments).map((att: any, idx: number) => (
                <div
                  key={idx}
                  className="flex items-center gap-2 bg-white border rounded px-3 py-2 text-sm"
                >
                  <span>📎</span>
                  <span>{att.filename}</span>
                  <span className="text-xs text-gray-500">({formatFileSize(att.size)})</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Extracted credentials banner */}
        {email.extracted_credentials && (
          <div className="mt-4 p-3 bg-purple-50 border border-purple-200 rounded-lg flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span>🔐</span>
              <span className="text-sm font-semibold">
                Login credentials detected in this email
              </span>
            </div>
            <a
              href={`/email/credentials?email_id=${email.id}`}
              className="text-sm text-purple-600 hover:underline"
            >
              View in Vault →
            </a>
          </div>
        )}
      </div>

      {/* Email Body */}
      <div className="flex-1 overflow-y-auto p-6">
        {viewMode === 'side-by-side' && email.translated ? (
          // Side-by-side view: Two columns
          <div className="grid grid-cols-2 gap-6">
            {/* Original column */}
            <div className="border-r pr-6">
              <div className="sticky top-0 bg-white pb-2 mb-3 border-b">
                <h3 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                  <span className="text-xs bg-gray-200 px-2 py-1 rounded">
                    {email.detected_language?.toUpperCase()}
                  </span>
                  Original
                </h3>
              </div>
              {email.body_html ? (
                <div
                  className="prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: email.body_html }}
                />
              ) : (
                <pre className="whitespace-pre-wrap font-sans text-sm">{email.body_text}</pre>
              )}
            </div>

            {/* Translation column */}
            <div>
              <div className="sticky top-0 bg-white pb-2 mb-3 border-b">
                <h3 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                  <span className="text-xs bg-blue-200 px-2 py-1 rounded">
                    {email.translation_target_lang?.toUpperCase()}
                  </span>
                  Translation
                </h3>
              </div>
              {email.translated_body_html ? (
                <div
                  className="prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: email.translated_body_html }}
                />
              ) : (
                <pre className="whitespace-pre-wrap font-sans text-sm">
                  {email.translated_body_text}
                </pre>
              )}
            </div>
          </div>
        ) : (
          // Single view (original or translation)
          <>
            {viewMode === 'original' || !email.translated ? (
              email.body_html ? (
                <div
                  className="prose max-w-none"
                  dangerouslySetInnerHTML={{ __html: email.body_html }}
                />
              ) : (
                <pre className="whitespace-pre-wrap font-sans">{email.body_text}</pre>
              )
            ) : (
              email.translated_body_html ? (
                <div
                  className="prose max-w-none"
                  dangerouslySetInnerHTML={{ __html: email.translated_body_html }}
                />
              ) : (
                <pre className="whitespace-pre-wrap font-sans">{email.translated_body_text}</pre>
              )
            )}
          </>
        )}
      </div>
    </div>
  )
}
```

### Translation View Modes - Visual Example

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Translation View Mode Selector                                         │
└─────────────────────────────────────────────────────────────────────────┘

🌐 Translated from ES to IT   [ Translation ] [ Original ] [ Side-by-Side ]
                                    ▲
                              (Selected)

─────────────────────────────────────────────────────────────────────────

MODE 1: Translation Only
┌─────────────────────────────────────────────────────────────────────────┐
│  Subject: Proposta di collaborazione commerciale                       │
│                                                                          │
│  Gentile Signore,                                                       │
│  Siamo interessati a una possibile collaborazione...                   │
│  [Full translated email content]                                        │
└─────────────────────────────────────────────────────────────────────────┘

─────────────────────────────────────────────────────────────────────────

MODE 2: Original Only
┌─────────────────────────────────────────────────────────────────────────┐
│  Subject: Propuesta de colaboración comercial                          │
│                                                                          │
│  Estimado Señor,                                                        │
│  Estamos interesados en una posible colaboración...                    │
│  [Full original email content in Spanish]                              │
└─────────────────────────────────────────────────────────────────────────┘

─────────────────────────────────────────────────────────────────────────

MODE 3: Side-by-Side (2 columns)
┌────────────────────────────────┬────────────────────────────────────────┐
│  [ES] Original                 │  [IT] Translation                      │
├────────────────────────────────┼────────────────────────────────────────┤
│  Subject:                      │  Subject:                              │
│  Propuesta de colaboración     │  Proposta di collaborazione            │
│                                │                                        │
│  Estimado Señor,               │  Gentile Signore,                      │
│                                │                                        │
│  Estamos interesados en una    │  Siamo interessati a una possibile     │
│  posible colaboración con      │  collaborazione con la vostra          │
│  su empresa...                 │  azienda...                            │
│                                │                                        │
│  [Original email scrolls]      │  [Translation scrolls in parallel]     │
└────────────────────────────────┴────────────────────────────────────────┘
```

**Benefits:**
- **Translation Only**: Default, cleaner view for quick reading
- **Original Only**: Verify translation accuracy, or if you prefer original
- **Side-by-Side**: Perfect for learning languages, or checking translation quality

**Implementation:**
- Side-by-side uses CSS Grid `grid-cols-2`
- Sticky headers for language indicators
- Independent scrolling for each column
- Subject displayed in both columns at top

---

## 📊 Implementation Summary

### Services

1. **svc-email** (New Service)
   - Email sync (Gmail API, IMAP/SMTP, Outlook API)
   - AI categorization
   - Credential extraction
   - Search engine
   - Cold email tracking

2. **Database Tables** (13 tables)
   - `email_accounts` - Connected email accounts
   - `emails` - All emails with full-text search
   - `email_folders` - Custom folders with auto-rules
   - `email_credentials` - Extracted credentials vault
   - `cold_email_campaigns` - Campaign management
   - `cold_email_tracking` - Tracking per recipient
   - `email_reply_templates` - Quick reply templates
   - `email_reply_rules` - Conditional routing rules (IF/THEN)
   - `email_routing_assignments` - Email assignments to users/teams
   - `calendar_events` - Calendar integration

### Timeline

| Phase | Duration | Deliverables |
|-------|----------|-------------|
| **Phase 1: Email Sync** | 3 weeks | IMAP/SMTP, Gmail API, account management |
| **Phase 2: Categorization** | 2 weeks | AI classification, auto-folders |
| **Phase 3: Search** | 1 week | Full-text search, filters |
| **Phase 4: Credentials** | 1 week | Auto-extraction, vault UI |
| **Phase 5: Cold Email** | 2 weeks | Campaign tracking, CRM integration |
| **Phase 6: Translation** | 1 week | Auto-translation, language detection, settings UI |
| **Phase 7: Quick Reply & Routing** | 2 weeks | AI suggestions, templates, routing rules, calendar |
| **Phase 8: UI** | 2 weeks | Dual-view inbox, compose, settings |
| **TOTAL** | **14 weeks** | Full email system |

### Key Features Summary

✅ **Dual View Mode:**
- Unified Inbox - Tutte le email in un flusso unico
- Per-Account View - Inbox/Sent/Drafts/Archive/Trash per ogni casella

✅ **Auto-Translation:**
- Rilevamento automatico lingua (GPT-4o-mini)
- Traduzione automatica per account
- Lingue escluse configurabili (es: parli IT+EN, escludi entrambe)
- **3 modalità visualizzazione:**
  - **Translation Only** - Solo traduzione
  - **Original Only** - Solo originale
  - **Side-by-Side** - Originale e traduzione affiancati (2 colonne)
- Badge lingua nella UI (ES, FR, DE, etc.)

✅ **Smart Categorization:**
- 6 categorie AI (Newsletter, Transazionali, Rilevanti, Fornitori, Spam, Cold Reply)
- Regole auto-folder personalizzabili
- Migrazione automatica

✅ **Cold Email CRM:**
- Aggregazione centinaia caselle
- Auto-creazione lead da risposte
- Campaign tracking completo

✅ **Credentials Vault:**
- Estrazione automatica login/password
- Storage AES-256-GCM
- UI con show/hide, copy

✅ **Full-Text Search:**
- PostgreSQL tsvector + ranking
- Filtri avanzati (account, category, date, attachments)
- Ricerca istantanea

### Cost Estimate

**Development:** €55,000 (12 weeks - includes translation)
**Infrastructure:** €50-100/month
- Email storage (S3): €20/month
- Database: €30/month
- AI classification: €50/month (GPT-4o-mini)

**ROI:** Included in platform, no direct revenue but increases product value

---

**Maintainer:** Platform Team
**Effort:** 11 weeks
**Integration:** CRM, AI Provider System
**Last Updated:** 2025-10-04

🚀 **Ready for implementation!**
