# Platform Missing Features - Complete Architecture
## Audit Immutabili, i18n, Contextual Help, Universal Image System, DAM Versioning

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: ARCHITECTURAL SPECIFICATION

---

## 🎯 Features Mancanti Identificate

1. ✅ **Immutable Audit System** - Audit trail non modificabile per compliance
2. ✅ **Multi-Language System (i18n)** - Supporto multilingua con file di traduzione
3. ✅ **Contextual Help + KB Drawer** - Help contestuale + Knowledge Base in drawer a destra
4. ✅ **Universal Image Insertion** - Upload / Drag from DAM / Insert from DAM (InDesign-style)
5. ✅ **DAM Link vs Version Tracking** - Link statico vs auto-update all'ultima versione
6. ✅ **Waterfall Settings for DAM References** - Control panel per gestione cascata

---

## 📐 Parte 1: Immutable Audit System

### Requisiti

- **Immutabilità** - I record di audit NON possono essere modificati o cancellati
- **Blockchain-style** - Ogni record è hash-linked al precedente
- **Compliance** - GDPR, SOC2, ISO 27001 compliant
- **Performance** - Milioni di record senza degradare performance
- **Query efficiency** - Ricerca veloce per user, entity, timeframe

### Database Schema (Append-Only)

```sql
-- Immutable audit log (append-only table)
CREATE TABLE IF NOT EXISTS audit.immutable_log (
  id BIGSERIAL PRIMARY KEY,
  -- Blockchain-style hash chain
  previous_hash VARCHAR(64),
  current_hash VARCHAR(64) NOT NULL UNIQUE,

  -- Event data
  tenant_id UUID NOT NULL,
  user_id UUID, -- NULL for system events
  event_type VARCHAR(100) NOT NULL, -- 'create', 'update', 'delete', 'access', 'export', etc.
  entity_type VARCHAR(100) NOT NULL, -- 'project', 'document', 'user', 'setting', etc.
  entity_id UUID,

  -- Action details
  action VARCHAR(255) NOT NULL,
  description TEXT,

  -- Changes (for update events)
  old_values JSONB,
  new_values JSONB,

  -- Context
  ip_address INET,
  user_agent TEXT,
  session_id UUID,
  request_id UUID,

  -- Metadata
  severity VARCHAR(20) DEFAULT 'info', -- 'debug', 'info', 'warning', 'error', 'critical'
  tags TEXT[], -- For categorization

  -- Timestamp (immutable!)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Compliance flags
  is_sensitive BOOLEAN DEFAULT false,
  retention_policy VARCHAR(50) DEFAULT 'standard', -- 'standard', 'long_term', 'permanent'

  CHECK (created_at <= NOW()) -- Prevent future timestamps
);

-- Indexes for performance
CREATE INDEX idx_audit_tenant_time ON audit.immutable_log(tenant_id, created_at DESC);
CREATE INDEX idx_audit_user_time ON audit.immutable_log(user_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit.immutable_log(entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_event_type ON audit.immutable_log(event_type, created_at DESC);
CREATE INDEX idx_audit_hash ON audit.immutable_log(current_hash);
CREATE INDEX idx_audit_tags ON audit.immutable_log USING GIN(tags);

-- Prevent UPDATE and DELETE on audit log
CREATE RULE audit_log_no_update AS ON UPDATE TO audit.immutable_log DO INSTEAD NOTHING;
CREATE RULE audit_log_no_delete AS ON DELETE TO audit.immutable_log DO INSTEAD NOTHING;

-- Partitioning by month for performance (100M+ records)
CREATE TABLE audit.immutable_log_y2025m10 PARTITION OF audit.immutable_log
  FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- Auto-create partitions via cron job
```

### Hash Chain Implementation

```typescript
// shared/packages/audit/src/audit-logger.ts
import crypto from 'crypto';

export class ImmutableAuditLogger {
  private lastHash: string | null = null;

  async log(event: AuditEvent): Promise<string> {
    // 1. Get last hash if not cached
    if (!this.lastHash) {
      const last = await db.query(
        `SELECT current_hash FROM audit.immutable_log
         ORDER BY id DESC LIMIT 1`
      );
      this.lastHash = last.rows[0]?.current_hash || '0'.repeat(64);
    }

    // 2. Create event data
    const eventData = {
      tenant_id: event.tenantId,
      user_id: event.userId,
      event_type: event.eventType,
      entity_type: event.entityType,
      entity_id: event.entityId,
      action: event.action,
      description: event.description,
      old_values: event.oldValues,
      new_values: event.newValues,
      ip_address: event.ipAddress,
      user_agent: event.userAgent,
      session_id: event.sessionId,
      request_id: event.requestId,
      severity: event.severity || 'info',
      tags: event.tags || [],
      created_at: new Date().toISOString()
    };

    // 3. Calculate hash (SHA-256)
    const dataString = JSON.stringify(eventData) + this.lastHash;
    const currentHash = crypto
      .createHash('sha256')
      .update(dataString)
      .digest('hex');

    // 4. Insert audit record
    await db.query(
      `INSERT INTO audit.immutable_log
         (previous_hash, current_hash, tenant_id, user_id, event_type, entity_type,
          entity_id, action, description, old_values, new_values, ip_address,
          user_agent, session_id, request_id, severity, tags)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
      [
        this.lastHash,
        currentHash,
        eventData.tenant_id,
        eventData.user_id,
        eventData.event_type,
        eventData.entity_type,
        eventData.entity_id,
        eventData.action,
        eventData.description,
        eventData.old_values,
        eventData.new_values,
        eventData.ip_address,
        eventData.user_agent,
        eventData.session_id,
        eventData.request_id,
        eventData.severity,
        eventData.tags
      ]
    );

    // 5. Update last hash
    this.lastHash = currentHash;

    return currentHash;
  }

  // Verify chain integrity
  async verifyChain(startId?: number, endId?: number): Promise<{
    valid: boolean;
    brokenAt?: number;
  }> {
    const records = await db.query(
      `SELECT id, previous_hash, current_hash, tenant_id, user_id, event_type,
              entity_type, entity_id, action, description, old_values, new_values,
              ip_address, user_agent, session_id, request_id, severity, tags, created_at
       FROM audit.immutable_log
       WHERE ($1::bigint IS NULL OR id >= $1)
         AND ($2::bigint IS NULL OR id <= $2)
       ORDER BY id ASC`,
      [startId || null, endId || null]
    );

    let previousHash = records.rows[0]?.previous_hash || '0'.repeat(64);

    for (const record of records.rows) {
      const eventData = {
        tenant_id: record.tenant_id,
        user_id: record.user_id,
        event_type: record.event_type,
        entity_type: record.entity_type,
        entity_id: record.entity_id,
        action: record.action,
        description: record.description,
        old_values: record.old_values,
        new_values: record.new_values,
        ip_address: record.ip_address,
        user_agent: record.user_agent,
        session_id: record.session_id,
        request_id: record.request_id,
        severity: record.severity,
        tags: record.tags,
        created_at: record.created_at.toISOString()
      };

      const dataString = JSON.stringify(eventData) + previousHash;
      const expectedHash = crypto
        .createHash('sha256')
        .update(dataString)
        .digest('hex');

      if (expectedHash !== record.current_hash) {
        return { valid: false, brokenAt: record.id };
      }

      previousHash = record.current_hash;
    }

    return { valid: true };
  }
}
```

### Audit Middleware

```typescript
// shared/packages/middleware/src/audit-middleware.ts
export function auditMiddleware(options?: {
  excludePaths?: string[];
  excludeMethods?: string[];
}) {
  const auditLogger = new ImmutableAuditLogger();

  return async (req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();

    // Capture original res.json
    const originalJson = res.json.bind(res);

    // Override res.json to capture response
    res.json = function(data: any) {
      // Log audit event after response
      setImmediate(async () => {
        try {
          const duration = Date.now() - start;

          // Determine if this is a mutation
          const isMutation = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method);

          if (isMutation) {
            await auditLogger.log({
              tenantId: req.tenantId,
              userId: req.user?.id,
              eventType: getEventType(req.method),
              entityType: extractEntityType(req.path),
              entityId: req.params.id || data?.id,
              action: `${req.method} ${req.path}`,
              description: getDescription(req),
              oldValues: req.auditOldValues, // Set by controller
              newValues: req.body,
              ipAddress: req.ip,
              userAgent: req.headers['user-agent'],
              sessionId: req.sessionId,
              requestId: req.headers['x-request-id'],
              severity: res.statusCode >= 400 ? 'error' : 'info',
              tags: [req.path.split('/')[1], req.method.toLowerCase()]
            });
          }
        } catch (error) {
          console.error('[AuditMiddleware] Failed to log audit event:', error);
        }
      });

      return originalJson(data);
    };

    next();
  };
}

function getEventType(method: string): string {
  const map = {
    POST: 'create',
    PUT: 'update',
    PATCH: 'update',
    DELETE: 'delete',
    GET: 'access'
  };
  return map[method] || 'action';
}
```

### Audit Query API

```typescript
// svc-audit/src/controllers/audit-logs.ts
export async function queryAuditLogs(req: Request, res: Response) {
  const {
    tenant_id,
    user_id,
    entity_type,
    entity_id,
    event_type,
    from_date,
    to_date,
    severity,
    tags,
    limit = 100,
    offset = 0
  } = req.query;

  const filters = [];
  const params: any[] = [];
  let paramIndex = 1;

  if (tenant_id) {
    filters.push(`tenant_id = $${paramIndex++}`);
    params.push(tenant_id);
  }

  if (user_id) {
    filters.push(`user_id = $${paramIndex++}`);
    params.push(user_id);
  }

  if (entity_type) {
    filters.push(`entity_type = $${paramIndex++}`);
    params.push(entity_type);
  }

  if (entity_id) {
    filters.push(`entity_id = $${paramIndex++}`);
    params.push(entity_id);
  }

  if (event_type) {
    filters.push(`event_type = $${paramIndex++}`);
    params.push(event_type);
  }

  if (from_date) {
    filters.push(`created_at >= $${paramIndex++}`);
    params.push(from_date);
  }

  if (to_date) {
    filters.push(`created_at <= $${paramIndex++}`);
    params.push(to_date);
  }

  if (severity) {
    filters.push(`severity = $${paramIndex++}`);
    params.push(severity);
  }

  if (tags) {
    filters.push(`tags && $${paramIndex++}`);
    params.push(Array.isArray(tags) ? tags : [tags]);
  }

  const whereClause = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';

  const result = await db.query(
    `SELECT * FROM audit.immutable_log
     ${whereClause}
     ORDER BY created_at DESC
     LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
    [...params, limit, offset]
  );

  return res.json({
    logs: result.rows,
    total: result.rowCount,
    limit: parseInt(limit as string),
    offset: parseInt(offset as string)
  });
}
```

---

## 📐 Parte 2: Multi-Language System (i18n)

### Requirements

- **File-based translations** - JSON files per lingua
- **Lazy loading** - Carica solo lingua attiva
- **Namespace support** - Organizzazione per feature/modulo
- **Fallback chain** - en-US → en → default
- **Hot reload** - Aggiorna traduzioni senza restart (dev mode)
- **Translation management UI** - Admin panel per gestire traduzioni

### Directory Structure

```
shared/locales/
├── en/
│   ├── common.json
│   ├── auth.json
│   ├── projects.json
│   ├── dam.json
│   └── billing.json
├── it/
│   ├── common.json
│   ├── auth.json
│   ├── projects.json
│   ├── dam.json
│   └── billing.json
├── es/
│   └── ...
└── de/
    └── ...
```

### Translation File Format

```json
// shared/locales/en/projects.json
{
  "projects": {
    "title": "Projects",
    "create": "Create Project",
    "edit": "Edit Project",
    "delete": "Delete Project",
    "deleteConfirm": "Are you sure you want to delete project \"{{name}}\"?",
    "status": {
      "planning": "Planning",
      "active": "Active",
      "on_hold": "On Hold",
      "completed": "Completed",
      "cancelled": "Cancelled"
    },
    "fields": {
      "name": "Project Name",
      "description": "Description",
      "startDate": "Start Date",
      "endDate": "End Date",
      "budget": "Budget",
      "assignedTo": "Assigned To"
    },
    "validation": {
      "nameRequired": "Project name is required",
      "nameMinLength": "Project name must be at least {{min}} characters",
      "budgetPositive": "Budget must be a positive number"
    },
    "messages": {
      "createSuccess": "Project created successfully",
      "updateSuccess": "Project updated successfully",
      "deleteSuccess": "Project deleted successfully",
      "error": "An error occurred while processing your request"
    }
  }
}
```

### Database Schema

```sql
-- Store translations in DB (optional, for dynamic content)
CREATE TABLE IF NOT EXISTS locales.translations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  locale VARCHAR(10) NOT NULL, -- 'en', 'it', 'es', 'de', etc.
  namespace VARCHAR(100) NOT NULL, -- 'projects', 'auth', 'common', etc.
  key VARCHAR(255) NOT NULL, -- 'projects.title', 'projects.create', etc.
  value TEXT NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(locale, namespace, key)
);

CREATE INDEX idx_translations_locale_namespace ON locales.translations(locale, namespace);

-- Tenant-specific translations (override platform defaults)
CREATE TABLE IF NOT EXISTS locales.tenant_translations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES auth.organizations(id),
  locale VARCHAR(10) NOT NULL,
  namespace VARCHAR(100) NOT NULL,
  key VARCHAR(255) NOT NULL,
  value TEXT NOT NULL,
  updated_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, locale, namespace, key)
);

CREATE INDEX idx_tenant_translations_tenant ON locales.tenant_translations(tenant_id, locale, namespace);
```

### i18n Service

```typescript
// shared/packages/i18n/src/i18n-service.ts
import i18next from 'i18next';
import Backend from 'i18next-fs-backend';
import { join } from 'path';

export class I18nService {
  private static instance: I18nService;

  private constructor() {}

  static getInstance(): I18nService {
    if (!I18nService.instance) {
      I18nService.instance = new I18nService();
    }
    return I18nService.instance;
  }

  async initialize(options?: {
    defaultLanguage?: string;
    supportedLanguages?: string[];
    localesPath?: string;
  }) {
    await i18next
      .use(Backend)
      .init({
        lng: options?.defaultLanguage || 'en',
        fallbackLng: 'en',
        supportedLngs: options?.supportedLanguages || ['en', 'it', 'es', 'de', 'fr'],
        ns: ['common', 'auth', 'projects', 'dam', 'billing'],
        defaultNS: 'common',
        backend: {
          loadPath: join(
            options?.localesPath || './shared/locales',
            '{{lng}}/{{ns}}.json'
          )
        },
        interpolation: {
          escapeValue: false
        },
        detection: {
          order: ['header', 'querystring', 'cookie'],
          lookupHeader: 'accept-language',
          lookupQuerystring: 'lang',
          lookupCookie: 'i18next',
          caches: ['cookie']
        }
      });
  }

  t(key: string, options?: any): string {
    return i18next.t(key, options);
  }

  async changeLanguage(lng: string): Promise<void> {
    await i18next.changeLanguage(lng);
  }

  getLanguage(): string {
    return i18next.language;
  }

  async loadNamespace(namespace: string): Promise<void> {
    await i18next.loadNamespaces(namespace);
  }
}
```

### React Hook

```typescript
// shared/packages/i18n/src/use-translation.ts
import { useTranslation as useI18nextTranslation } from 'react-i18next';

export function useTranslation(namespace?: string | string[]) {
  const { t, i18n } = useI18nextTranslation(namespace);

  const changeLanguage = async (lng: string) => {
    await i18n.changeLanguage(lng);
    // Update user preference
    await fetch('/api/v1/users/me/preferences', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ language: lng })
    });
  };

  return {
    t,
    language: i18n.language,
    changeLanguage,
    languages: i18n.languages
  };
}

// Usage in components:
export function ProjectsList() {
  const { t } = useTranslation('projects');

  return (
    <div>
      <h1>{t('projects.title')}</h1>
      <button>{t('projects.create')}</button>

      <p>{t('projects.deleteConfirm', { name: 'My Project' })}</p>
      {/* Output: Are you sure you want to delete project "My Project"? */}
    </div>
  );
}
```

### Language Selector Component

```typescript
// shared/packages/ui-components/src/LanguageSelector.tsx
import { useTranslation } from '@ewh/i18n';
import { Globe } from 'lucide-react';

const LANGUAGES = [
  { code: 'en', name: 'English', flag: '🇬🇧' },
  { code: 'it', name: 'Italiano', flag: '🇮🇹' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'de', name: 'Deutsch', flag: '🇩🇪' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' }
];

export function LanguageSelector() {
  const { language, changeLanguage } = useTranslation();

  return (
    <div className="relative">
      <button className="flex items-center gap-2 px-3 py-2 rounded hover:bg-gray-100">
        <Globe size={16} />
        <span>{LANGUAGES.find(l => l.code === language)?.flag}</span>
      </button>

      <div className="absolute right-0 mt-2 w-48 bg-white shadow-lg rounded">
        {LANGUAGES.map(lang => (
          <button
            key={lang.code}
            onClick={() => changeLanguage(lang.code)}
            className={`w-full text-left px-4 py-2 hover:bg-gray-50 ${
              language === lang.code ? 'bg-blue-50' : ''
            }`}
          >
            <span className="mr-2">{lang.flag}</span>
            {lang.name}
          </button>
        ))}
      </div>
    </div>
  );
}
```

---

## 📐 Parte 3: Contextual Help + Knowledge Base Drawer

### Requirements

- **Context-aware help** - Help specifico per pagina/componente corrente
- **KB Drawer** - Pannello a destra della shell, sotto mini DAM
- **Search** - Ricerca full-text nel KB
- **Categories** - Organizzazione gerarchica del KB
- **Rich content** - Markdown, immagini, video embedded
- **Favoriti** - Utente può salvare articoli preferiti

### Database Schema

```sql
-- Knowledge base articles
CREATE TABLE IF NOT EXISTS kb.articles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(500) NOT NULL,
  slug VARCHAR(500) NOT NULL UNIQUE,
  content TEXT NOT NULL, -- Markdown
  excerpt TEXT,

  -- Categorization
  category_id UUID REFERENCES kb.categories(id),
  tags TEXT[],

  -- Context mapping
  app_id VARCHAR(100), -- 'app-pm-frontend', 'app-dam', etc.
  page_path VARCHAR(500), -- '/projects', '/projects/:id', etc.
  component_name VARCHAR(255), -- 'ProjectForm', 'TaskCard', etc.

  -- Metadata
  author_id UUID REFERENCES auth.users(id),
  published_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- SEO
  meta_title VARCHAR(500),
  meta_description TEXT,

  -- Status
  status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'published', 'archived'

  -- Metrics
  views_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  not_helpful_count INTEGER DEFAULT 0
);

CREATE INDEX idx_kb_articles_app_page ON kb.articles(app_id, page_path);
CREATE INDEX idx_kb_articles_category ON kb.articles(category_id);
CREATE INDEX idx_kb_articles_status ON kb.articles(status, published_at DESC);
CREATE INDEX idx_kb_articles_search ON kb.articles USING GIN(to_tsvector('english', title || ' ' || content));

-- Categories
CREATE TABLE IF NOT EXISTS kb.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  parent_id UUID REFERENCES kb.categories(id),
  icon VARCHAR(50),
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User favorites
CREATE TABLE IF NOT EXISTS kb.user_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  article_id UUID NOT NULL REFERENCES kb.articles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, article_id)
);

-- Article feedback
CREATE TABLE IF NOT EXISTS kb.article_feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id UUID NOT NULL REFERENCES kb.articles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  is_helpful BOOLEAN NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Contextual Help Service

```typescript
// shared/packages/help/src/contextual-help-service.ts
export class ContextualHelpService {
  async getHelpForContext(context: {
    appId: string;
    pagePath: string;
    componentName?: string;
  }): Promise<Article[]> {
    const articles = await db.query(
      `SELECT a.*, c.name as category_name
       FROM kb.articles a
       LEFT JOIN kb.categories c ON c.id = a.category_id
       WHERE a.status = 'published'
         AND (
           (a.app_id = $1 AND a.page_path = $2)
           OR (a.app_id = $1 AND a.component_name = $3)
           OR (a.app_id = $1 AND a.page_path IS NULL)
         )
       ORDER BY
         CASE
           WHEN a.page_path = $2 AND a.component_name = $3 THEN 1
           WHEN a.page_path = $2 THEN 2
           WHEN a.component_name = $3 THEN 3
           ELSE 4
         END,
         a.helpful_count DESC
       LIMIT 5`,
      [context.appId, context.pagePath, context.componentName]
    );

    return articles.rows;
  }

  async searchArticles(query: string, filters?: {
    appId?: string;
    categoryId?: string;
    tags?: string[];
  }): Promise<Article[]> {
    let sql = `
      SELECT a.*, c.name as category_name,
             ts_rank(to_tsvector('english', a.title || ' ' || a.content), plainto_tsquery('english', $1)) as rank
      FROM kb.articles a
      LEFT JOIN kb.categories c ON c.id = a.category_id
      WHERE a.status = 'published'
        AND to_tsvector('english', a.title || ' ' || a.content) @@ plainto_tsquery('english', $1)
    `;

    const params: any[] = [query];
    let paramIndex = 2;

    if (filters?.appId) {
      sql += ` AND a.app_id = $${paramIndex++}`;
      params.push(filters.appId);
    }

    if (filters?.categoryId) {
      sql += ` AND a.category_id = $${paramIndex++}`;
      params.push(filters.categoryId);
    }

    if (filters?.tags && filters.tags.length > 0) {
      sql += ` AND a.tags && $${paramIndex++}`;
      params.push(filters.tags);
    }

    sql += ` ORDER BY rank DESC, a.helpful_count DESC LIMIT 20`;

    const result = await db.query(sql, params);
    return result.rows;
  }
}
```

### KB Drawer Component

```typescript
// app-shell-frontend/src/components/KBDrawer.tsx
import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Book, Search, Star, ExternalLink, ThumbsUp, ThumbsDown } from 'lucide-react';
import { useContextualHelp } from '@ewh/help';

export function KBDrawer({ isOpen, onClose }: Props) {
  const location = useLocation();
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState<'context' | 'search' | 'favorites'>('context');

  const {
    contextualArticles,
    searchResults,
    favorites,
    searchArticles,
    toggleFavorite,
    submitFeedback
  } = useContextualHelp({
    appId: getCurrentAppId(),
    pagePath: location.pathname
  });

  return (
    <div className={`fixed right-0 top-[60px] bottom-0 w-96 bg-white shadow-lg transform transition-transform ${
      isOpen ? 'translate-x-0' : 'translate-x-full'
    }`}>
      {/* Header */}
      <div className="p-4 border-b">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Book size={20} />
            <h2 className="font-semibold">Knowledge Base</h2>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            ×
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search help articles..."
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              if (e.target.value) {
                searchArticles(e.target.value);
                setActiveTab('search');
              }
            }}
            className="w-full pl-10 pr-4 py-2 border rounded-lg"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b">
        <button
          onClick={() => setActiveTab('context')}
          className={`flex-1 px-4 py-2 ${
            activeTab === 'context' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600'
          }`}
        >
          Help for this page
        </button>
        <button
          onClick={() => setActiveTab('favorites')}
          className={`flex-1 px-4 py-2 ${
            activeTab === 'favorites' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600'
          }`}
        >
          <Star size={16} className="inline mr-1" />
          Favorites
        </button>
      </div>

      {/* Content */}
      <div className="overflow-y-auto h-[calc(100vh-240px)]">
        {activeTab === 'context' && (
          <div className="p-4 space-y-4">
            {contextualArticles.length === 0 ? (
              <div className="text-center text-gray-500 py-8">
                No help articles for this page yet.
              </div>
            ) : (
              contextualArticles.map(article => (
                <ArticleCard
                  key={article.id}
                  article={article}
                  onToggleFavorite={toggleFavorite}
                  onFeedback={submitFeedback}
                />
              ))
            )}
          </div>
        )}

        {activeTab === 'search' && (
          <div className="p-4 space-y-4">
            {searchResults.length === 0 ? (
              <div className="text-center text-gray-500 py-8">
                {searchQuery ? 'No results found' : 'Start typing to search...'}
              </div>
            ) : (
              searchResults.map(article => (
                <ArticleCard
                  key={article.id}
                  article={article}
                  onToggleFavorite={toggleFavorite}
                  onFeedback={submitFeedback}
                />
              ))
            )}
          </div>
        )}

        {activeTab === 'favorites' && (
          <div className="p-4 space-y-4">
            {favorites.length === 0 ? (
              <div className="text-center text-gray-500 py-8">
                No favorites yet. Click the star on articles to save them.
              </div>
            ) : (
              favorites.map(article => (
                <ArticleCard
                  key={article.id}
                  article={article}
                  onToggleFavorite={toggleFavorite}
                  onFeedback={submitFeedback}
                />
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function ArticleCard({ article, onToggleFavorite, onFeedback }: ArticleCardProps) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="border rounded-lg p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-2">
        <h3 className="font-medium text-sm flex-1">{article.title}</h3>
        <button
          onClick={() => onToggleFavorite(article.id)}
          className={`ml-2 ${article.isFavorite ? 'text-yellow-500' : 'text-gray-400'}`}
        >
          <Star size={16} fill={article.isFavorite ? 'currentColor' : 'none'} />
        </button>
      </div>

      <p className="text-xs text-gray-600 mb-3">{article.excerpt}</p>

      {expanded && (
        <div className="prose prose-sm mb-3">
          <ReactMarkdown>{article.content}</ReactMarkdown>
        </div>
      )}

      <div className="flex items-center justify-between text-xs">
        <button
          onClick={() => setExpanded(!expanded)}
          className="text-blue-600 hover:underline"
        >
          {expanded ? 'Show less' : 'Read more'}
        </button>

        <div className="flex items-center gap-3">
          <button
            onClick={() => onFeedback(article.id, true)}
            className="flex items-center gap-1 text-gray-600 hover:text-green-600"
          >
            <ThumbsUp size={14} />
            {article.helpfulCount}
          </button>
          <button
            onClick={() => onFeedback(article.id, false)}
            className="flex items-center gap-1 text-gray-600 hover:text-red-600"
          >
            <ThumbsDown size={14} />
            {article.notHelpfulCount}
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## 📐 Parte 4: Universal Image Insertion System

### Requirements

1. **Upload from file** - Drag & drop o file picker
2. **Drag from DAM** - Mini DAM drawer → drag to target
3. **Insert from DAM** - InDesign-style modal browser

### Database Schema

```sql
-- Track image insertions across all apps
CREATE TABLE IF NOT EXISTS dam.image_insertions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL,

  -- Source (DAM asset)
  asset_id UUID NOT NULL REFERENCES dam.assets(id),
  asset_version_id UUID REFERENCES dam.asset_versions(id), -- NULL = latest

  -- Destination (where inserted)
  app_id VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100) NOT NULL, -- 'project', 'page', 'post', 'product', etc.
  entity_id UUID NOT NULL,
  field_name VARCHAR(255), -- 'cover_image', 'gallery[2]', 'content.block[3].image', etc.

  -- Link behavior
  link_type VARCHAR(20) DEFAULT 'static', -- 'static' (linked version) or 'dynamic' (auto-update)

  -- Insertion context
  inserted_by UUID REFERENCES auth.users(id),
  inserted_at TIMESTAMPTZ DEFAULT NOW(),

  -- Usage tracking
  last_accessed_at TIMESTAMPTZ,
  access_count INTEGER DEFAULT 0
);

CREATE INDEX idx_image_insertions_asset ON dam.image_insertions(asset_id);
CREATE INDEX idx_image_insertions_entity ON dam.image_insertions(entity_type, entity_id);
CREATE INDEX idx_image_insertions_tenant ON dam.image_insertions(tenant_id);
```

### Universal Image Picker Component

```typescript
// shared/packages/ui-components/src/ImagePicker/ImagePicker.tsx
import { useState } from 'react';
import { Upload, Image as ImageIcon, Link } from 'lucide-react';
import { useDropzone } from 'react-dropzone';

export type ImagePickerMode = 'upload' | 'dam-drag' | 'dam-browse';
export type LinkType = 'static' | 'dynamic';

interface ImagePickerProps {
  value?: ImageInsertion;
  onChange: (insertion: ImageInsertion) => void;
  allowedModes?: ImagePickerMode[];
  defaultLinkType?: LinkType;
  entityType: string;
  entityId: string;
  fieldName: string;
}

export function ImagePicker({
  value,
  onChange,
  allowedModes = ['upload', 'dam-drag', 'dam-browse'],
  defaultLinkType = 'dynamic',
  entityType,
  entityId,
  fieldName
}: ImagePickerProps) {
  const [mode, setMode] = useState<ImagePickerMode | null>(null);
  const [linkType, setLinkType] = useState<LinkType>(defaultLinkType);

  // Upload mode
  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    accept: { 'image/*': [] },
    maxFiles: 1,
    onDrop: async (files) => {
      const file = files[0];
      if (!file) return;

      // Upload to DAM
      const asset = await uploadToDAM(file);

      // Create insertion
      const insertion: ImageInsertion = {
        assetId: asset.id,
        assetVersionId: linkType === 'static' ? asset.currentVersionId : null,
        linkType,
        url: asset.url,
        width: asset.width,
        height: asset.height,
        alt: asset.title
      };

      // Track insertion
      await trackInsertion({
        assetId: asset.id,
        assetVersionId: insertion.assetVersionId,
        entityType,
        entityId,
        fieldName,
        linkType
      });

      onChange(insertion);
    }
  });

  if (!value && !mode) {
    return (
      <div className="border-2 border-dashed rounded-lg p-8">
        <div className="flex flex-col items-center gap-4">
          <div className="text-gray-400">
            <ImageIcon size={48} />
          </div>

          <p className="text-sm text-gray-600">Choose how to add an image:</p>

          <div className="flex gap-2">
            {allowedModes.includes('upload') && (
              <button
                onClick={() => setMode('upload')}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              >
                <Upload size={16} />
                Upload File
              </button>
            )}

            {allowedModes.includes('dam-browse') && (
              <button
                onClick={() => setMode('dam-browse')}
                className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                <ImageIcon size={16} />
                Browse DAM
              </button>
            )}
          </div>

          {allowedModes.includes('dam-drag') && (
            <p className="text-xs text-gray-500">
              Or drag an image from the DAM drawer →
            </p>
          )}
        </div>
      </div>
    );
  }

  if (mode === 'upload') {
    return (
      <div>
        <div
          {...getRootProps()}
          className={`border-2 border-dashed rounded-lg p-8 cursor-pointer transition-colors ${
            isDragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'
          }`}
        >
          <input {...getInputProps()} />
          <div className="flex flex-col items-center gap-2">
            <Upload size={32} className="text-gray-400" />
            <p className="text-sm text-gray-600">
              {isDragActive ? 'Drop image here' : 'Drag & drop or click to upload'}
            </p>
          </div>
        </div>

        {/* Link type selector */}
        <LinkTypeSelector value={linkType} onChange={setLinkType} />
      </div>
    );
  }

  if (mode === 'dam-browse') {
    return (
      <DAMBrowserModal
        onSelect={async (asset) => {
          const insertion: ImageInsertion = {
            assetId: asset.id,
            assetVersionId: linkType === 'static' ? asset.currentVersionId : null,
            linkType,
            url: asset.url,
            width: asset.width,
            height: asset.height,
            alt: asset.title
          };

          await trackInsertion({
            assetId: asset.id,
            assetVersionId: insertion.assetVersionId,
            entityType,
            entityId,
            fieldName,
            linkType
          });

          onChange(insertion);
          setMode(null);
        }}
        onClose={() => setMode(null)}
      />
    );
  }

  // Show selected image
  return (
    <div className="space-y-2">
      <div className="relative group">
        <img
          src={value.url}
          alt={value.alt}
          className="w-full rounded-lg"
        />

        <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center gap-2">
          <button
            onClick={() => setMode('dam-browse')}
            className="px-3 py-2 bg-white text-gray-900 rounded hover:bg-gray-100"
          >
            Replace
          </button>
          <button
            onClick={() => onChange(null)}
            className="px-3 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Remove
          </button>
        </div>
      </div>

      <LinkTypeSelector value={linkType} onChange={setLinkType} />

      {linkType === 'dynamic' && (
        <div className="flex items-center gap-2 text-sm text-blue-600">
          <Link size={14} />
          <span>This image will auto-update when a new version is uploaded to DAM</span>
        </div>
      )}
    </div>
  );
}

function LinkTypeSelector({ value, onChange }: { value: LinkType; onChange: (v: LinkType) => void }) {
  return (
    <div className="mt-4 p-4 bg-gray-50 rounded-lg">
      <label className="block text-sm font-medium mb-2">Link Behavior</label>

      <div className="space-y-2">
        <label className="flex items-start gap-2 cursor-pointer">
          <input
            type="radio"
            value="static"
            checked={value === 'static'}
            onChange={(e) => onChange(e.target.value as LinkType)}
            className="mt-1"
          />
          <div>
            <div className="font-medium text-sm">Static (Current Version)</div>
            <div className="text-xs text-gray-600">
              Link to this specific version. Won't change when DAM is updated.
            </div>
          </div>
        </label>

        <label className="flex items-start gap-2 cursor-pointer">
          <input
            type="radio"
            value="dynamic"
            checked={value === 'dynamic'}
            onChange={(e) => onChange(e.target.value as LinkType)}
            className="mt-1"
          />
          <div>
            <div className="font-medium text-sm">Dynamic (Auto-Update)</div>
            <div className="text-xs text-gray-600">
              Always use the latest version from DAM. Updates automatically.
            </div>
          </div>
        </label>
      </div>
    </div>
  );
}
```

### DAM Browser Modal (InDesign-style)

```typescript
// shared/packages/ui-components/src/DAMBrowserModal.tsx
export function DAMBrowserModal({ onSelect, onClose }: Props) {
  const [assets, setAssets] = useState<Asset[]>([]);
  const [selectedAsset, setSelectedAsset] = useState<Asset | null>(null);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState({ type: 'image', tags: [] });

  useEffect(() => {
    // Load assets from DAM
    loadAssets({ search: searchQuery, ...filters });
  }, [searchQuery, filters]);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-[90vw] h-[80vh] flex flex-col">
        {/* Header */}
        <div className="p-4 border-b flex items-center justify-between">
          <h2 className="text-xl font-semibold">Select Image from DAM</h2>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded">×</button>
        </div>

        {/* Toolbar */}
        <div className="p-4 border-b flex items-center gap-4">
          <input
            type="text"
            placeholder="Search assets..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="flex-1 px-4 py-2 border rounded"
          />

          <select
            value={viewMode}
            onChange={(e) => setViewMode(e.target.value as any)}
            className="px-3 py-2 border rounded"
          >
            <option value="grid">Grid</option>
            <option value="list">List</option>
          </select>
        </div>

        {/* Content */}
        <div className="flex-1 flex overflow-hidden">
          {/* Asset Grid/List */}
          <div className="flex-1 overflow-y-auto p-4">
            {viewMode === 'grid' ? (
              <div className="grid grid-cols-4 gap-4">
                {assets.map(asset => (
                  <AssetCard
                    key={asset.id}
                    asset={asset}
                    isSelected={selectedAsset?.id === asset.id}
                    onSelect={() => setSelectedAsset(asset)}
                    onDoubleClick={() => onSelect(asset)}
                  />
                ))}
              </div>
            ) : (
              <div className="space-y-2">
                {assets.map(asset => (
                  <AssetListItem
                    key={asset.id}
                    asset={asset}
                    isSelected={selectedAsset?.id === asset.id}
                    onSelect={() => setSelectedAsset(asset)}
                    onDoubleClick={() => onSelect(asset)}
                  />
                ))}
              </div>
            )}
          </div>

          {/* Preview Panel */}
          {selectedAsset && (
            <div className="w-80 border-l p-4 overflow-y-auto">
              <img
                src={selectedAsset.url}
                alt={selectedAsset.title}
                className="w-full rounded mb-4"
              />

              <h3 className="font-semibold mb-2">{selectedAsset.title}</h3>
              <p className="text-sm text-gray-600 mb-4">{selectedAsset.description}</p>

              <div className="space-y-2 text-sm">
                <div><strong>Type:</strong> {selectedAsset.mimeType}</div>
                <div><strong>Size:</strong> {formatFileSize(selectedAsset.fileSize)}</div>
                <div>
                  <strong>Dimensions:</strong> {selectedAsset.width} × {selectedAsset.height}
                </div>
                <div><strong>Version:</strong> {selectedAsset.currentVersion}</div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t flex justify-end gap-2">
          <button
            onClick={onClose}
            className="px-4 py-2 border rounded hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={() => selectedAsset && onSelect(selectedAsset)}
            disabled={!selectedAsset}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
          >
            Insert
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## 📐 Parte 5: DAM Link vs Version Tracking + Waterfall Settings

### Automatic Version Update Job

```typescript
// svc-job-worker/src/jobs/update-dynamic-image-links.ts
export async function updateDynamicImageLinks(assetId: string, newVersionId: string) {
  // Find all dynamic insertions for this asset
  const insertions = await db.query(
    `SELECT * FROM dam.image_insertions
     WHERE asset_id = $1 AND link_type = 'dynamic'`,
    [assetId]
  );

  for (const insertion of insertions.rows) {
    // Update entity with new version
    await updateEntityImage({
      appId: insertion.app_id,
      entityType: insertion.entity_type,
      entityId: insertion.entity_id,
      fieldName: insertion.field_name,
      newVersionId
    });

    // Log audit
    await auditLogger.log({
      tenantId: insertion.tenant_id,
      eventType: 'update',
      entityType: insertion.entity_type,
      entityId: insertion.entity_id,
      action: 'auto_update_image',
      description: `Image auto-updated to version ${newVersionId}`,
      tags: ['dam', 'auto-update']
    });
  }
}
```

### Waterfall Settings Panel

```typescript
// app-settings-frontend/src/pages/DAMReferences.tsx
export function DAMReferencesSettings() {
  const { settings, updateSettings } = useSettings('dam_references');

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-2xl font-bold">DAM References Management</h1>

      {/* Global Policy */}
      <section className="border rounded-lg p-4">
        <h2 className="font-semibold mb-4">Default Link Behavior (Platform-wide)</h2>

        <label className="flex items-start gap-2 mb-3">
          <input
            type="radio"
            value="static"
            checked={settings.platform.defaultLinkType === 'static'}
            onChange={() => updateSettings({ platform: { defaultLinkType: 'static' } })}
          />
          <div>
            <div className="font-medium">Static (Version-locked)</div>
            <div className="text-sm text-gray-600">
              All new image insertions link to specific version by default
            </div>
          </div>
        </label>

        <label className="flex items-start gap-2">
          <input
            type="radio"
            value="dynamic"
            checked={settings.platform.defaultLinkType === 'dynamic'}
            onChange={() => updateSettings({ platform: { defaultLinkType: 'dynamic' } })}
          />
          <div>
            <div className="font-medium">Dynamic (Auto-update)</div>
            <div className="text-sm text-gray-600">
              All new image insertions auto-update to latest version by default
            </div>
          </div>
        </label>
      </section>

      {/* Tenant Override */}
      <section className="border rounded-lg p-4">
        <h2 className="font-semibold mb-4">Tenant Override</h2>

        <div className="space-y-4">
          {tenants.map(tenant => (
            <div key={tenant.id} className="flex items-center justify-between p-3 bg-gray-50 rounded">
              <div>
                <div className="font-medium">{tenant.name}</div>
                <div className="text-sm text-gray-600">
                  Current: {settings.tenants[tenant.id]?.defaultLinkType || 'Inherit platform'}
                </div>
              </div>

              <select
                value={settings.tenants[tenant.id]?.defaultLinkType || 'inherit'}
                onChange={(e) => updateSettings({
                  tenants: {
                    ...settings.tenants,
                    [tenant.id]: { defaultLinkType: e.target.value }
                  }
                })}
                className="px-3 py-2 border rounded"
              >
                <option value="inherit">Inherit Platform Default</option>
                <option value="static">Static</option>
                <option value="dynamic">Dynamic</option>
              </select>
            </div>
          ))}
        </div>
      </section>

      {/* App-specific Override */}
      <section className="border rounded-lg p-4">
        <h2 className="font-semibold mb-4">App-specific Override</h2>

        <div className="space-y-4">
          {apps.map(app => (
            <div key={app.id} className="flex items-center justify-between p-3 bg-gray-50 rounded">
              <div>
                <div className="font-medium">{app.name}</div>
                <div className="text-sm text-gray-600">
                  Current: {settings.apps[app.id]?.defaultLinkType || 'Inherit tenant/platform'}
                </div>
              </div>

              <select
                value={settings.apps[app.id]?.defaultLinkType || 'inherit'}
                onChange={(e) => updateSettings({
                  apps: {
                    ...settings.apps,
                    [app.id]: { defaultLinkType: e.target.value }
                  }
                })}
                className="px-3 py-2 border rounded"
              >
                <option value="inherit">Inherit Tenant/Platform Default</option>
                <option value="static">Static</option>
                <option value="dynamic">Dynamic</option>
              </select>
            </div>
          ))}
        </div>
      </section>

      {/* Bulk Operations */}
      <section className="border rounded-lg p-4">
        <h2 className="font-semibold mb-4">Bulk Operations</h2>

        <div className="space-y-3">
          <button className="w-full px-4 py-2 border rounded hover:bg-gray-50 text-left">
            Convert all dynamic links to static (version-lock all images)
          </button>

          <button className="w-full px-4 py-2 border rounded hover:bg-gray-50 text-left">
            Convert all static links to dynamic (enable auto-update)
          </button>

          <button className="w-full px-4 py-2 border rounded hover:bg-gray-50 text-left">
            Find and list all broken image references
          </button>

          <button className="w-full px-4 py-2 border rounded hover:bg-gray-50 text-left">
            Generate report of image usage across all apps
          </button>
        </div>
      </section>
    </div>
  );
}
```

---

## 📊 Summary

### ✅ Architetture Aggiunte

1. **Immutable Audit System**
   - Blockchain-style hash chain
   - Append-only table con regole di protezione
   - Audit middleware automatico
   - Chain integrity verification

2. **Multi-Language (i18n)**
   - File-based translations (JSON)
   - Namespace organization
   - React hooks + context
   - Language selector component
   - Database storage per dynamic content

3. **Contextual Help + KB Drawer**
   - Context-aware help articles
   - Full-text search
   - Categories + tags
   - Favorites system
   - Feedback (helpful/not helpful)

4. **Universal Image Insertion**
   - 3 modes: Upload / Drag from DAM / Browse DAM
   - InDesign-style modal browser
   - Link type selector (static vs dynamic)
   - Tracking insertions

5. **DAM Version Tracking**
   - Static links (version-locked)
   - Dynamic links (auto-update)
   - Automatic update job
   - Waterfall settings panel (Platform → Tenant → App)

---

**Status**: ✅ ARCHITECTURE COMPLETE
**Next**: Integrazione con architettura esistente + Implementation
