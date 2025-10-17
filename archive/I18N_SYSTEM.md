# EWH Platform - Internationalization (i18n) System

> **Sistema di internazionalizzazione completo con AI-powered translations, gestione UI + contenuti utente**

**Versione:** 1.0.0
**Target:** Global expansion, multi-language support
**Ultima revisione:** 2025-10-04

---

## 🎯 Obiettivo

Supportare **multi-lingua completo** per:
- ✅ UI/UX (labels, buttons, messages)
- ✅ Contenuti utente (tags, descriptions, notes)
- ✅ Documentation & Help articles
- ✅ Email templates
- ✅ Landing pages per vertical
- ✅ AI-powered automatic translations

**Principio:** "Ogni tenant può operare nella sua lingua nativa, con traduzioni automatiche AI-powered per contenuti"

---

## 📋 Architettura i18n

```
┌─────────────────────────────────────────────────────────────┐
│  i18n Architecture                                          │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  1. Static UI Translations             │
│     • next-intl / react-i18next        │
│     • JSON files per lingua            │
│     • Compile-time translations        │
└────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  2. Dynamic Content Translations       │
│     • Database: multi-column (JSON)    │
│     • AI auto-translate (GPT-4)        │
│     • User-editable translations       │
└────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  3. Translation Management UI          │
│     • Admin CMS for translations       │
│     • AI-assisted bulk translate       │
│     • Translation memory (cache)       │
└────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  4. Language Detection & Switching     │
│     • Auto-detect from browser         │
│     • User preference (saved)          │
│     • Per-tenant default language      │
└────────────────────────────────────────┘
```

---

## 1. Static UI Translations (Frontend)

### Supported Languages (MVP)

```typescript
// Tier 1: Fully Supported (native speakers reviewed)
const TIER_1_LANGUAGES = [
  'en', // English (default)
  'it', // Italian
  'es', // Spanish
  'fr', // French
  'de', // German
]

// Tier 2: AI-translated (community reviewed)
const TIER_2_LANGUAGES = [
  'pt', // Portuguese
  'nl', // Dutch
  'pl', // Polish
  'ja', // Japanese
  'zh', // Chinese (Simplified)
  'ar', // Arabic (RTL support)
]

// Total: 11 languages in MVP
```

### Implementation (Next.js)

#### Setup next-intl

```bash
npm install next-intl
```

```typescript
// app/[locale]/layout.tsx
import { NextIntlClientProvider } from 'next-intl'
import { notFound } from 'next/navigation'

const locales = ['en', 'it', 'es', 'fr', 'de']

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }))
}

export default async function LocaleLayout({
  children,
  params: { locale }
}: {
  children: React.ReactNode
  params: { locale: string }
}) {
  // Validate locale
  if (!locales.includes(locale)) {
    notFound()
  }

  // Load messages
  let messages
  try {
    messages = (await import(`@/messages/${locale}.json`)).default
  } catch (error) {
    notFound()
  }

  return (
    <html lang={locale}>
      <body>
        <NextIntlClientProvider locale={locale} messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  )
}
```

#### Translation Files Structure

```
messages/
├── en.json          # English (base)
├── it.json          # Italian
├── es.json          # Spanish
├── fr.json          # French
├── de.json          # German
└── common.json      # Shared keys (merged into all)
```

#### English Base (en.json)

```json
{
  "common": {
    "save": "Save",
    "cancel": "Cancel",
    "delete": "Delete",
    "edit": "Edit",
    "loading": "Loading...",
    "error": "An error occurred",
    "success": "Success!"
  },
  "nav": {
    "documents": "Documents",
    "projects": "Projects",
    "settings": "Settings",
    "help": "Help"
  },
  "documents": {
    "title": "Documents",
    "upload": "Upload Document",
    "uploadDescription": "Drag & drop files or click to browse",
    "emptyState": "No documents yet. Upload your first document!",
    "deleteConfirm": "Are you sure you want to delete this document? This action cannot be undone.",
    "deleteSuccess": "Document deleted successfully",
    "tags": {
      "add": "Add tag",
      "placeholder": "Enter tag name..."
    }
  },
  "help": {
    "tooltip": {
      "uploadButton": "Upload new documents. Supports PDF, DOCX, XLSX, and more.",
      "shareButton": "Share this document with team members",
      "deleteButton": "Permanently delete this document (irreversible)"
    }
  }
}
```

#### Usage in Components

```tsx
// components/DocumentList.tsx
import { useTranslations } from 'next-intl'
import { HelpButton } from '@/components/HelpButton'

export function DocumentList() {
  const t = useTranslations('documents')
  const tCommon = useTranslations('common')
  const tHelp = useTranslations('help.tooltip')

  return (
    <div>
      <h1>{t('title')}</h1>

      <HelpButton
        tooltip={tHelp('uploadButton')}
        onClick={handleUpload}
      >
        {t('upload')}
      </HelpButton>

      {documents.length === 0 ? (
        <p>{t('emptyState')}</p>
      ) : (
        <DocumentTable documents={documents} />
      )}
    </div>
  )
}
```

#### Pluralization Support

```json
{
  "documents": {
    "count": "{count, plural, =0 {No documents} =1 {1 document} other {# documents}}"
  }
}
```

```tsx
// Usage
t('documents.count', { count: documents.length })
// → "No documents" or "1 document" or "5 documents"
```

#### Date/Number Formatting

```tsx
import { useFormatter } from 'next-intl'

function DocumentCard({ document }) {
  const format = useFormatter()

  return (
    <div>
      <p>Created: {format.dateTime(document.created_at, {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })}</p>
      <p>Size: {format.number(document.size, {
        style: 'unit',
        unit: 'megabyte'
      })}</p>
    </div>
  )
}

// Output (en): "Created: January 15, 2024" | "Size: 2.4 MB"
// Output (it): "Creato: 15 gennaio 2024" | "Dimensione: 2,4 MB"
```

---

## 2. Dynamic Content Translations (Database)

### Database Schema

```sql
-- Multi-language content storage (JSONB approach)
CREATE TABLE documents (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  file_name TEXT NOT NULL,

  -- Multi-language fields (JSONB)
  tags JSONB DEFAULT '{}',
  -- { "en": ["invoice", "2024"], "it": ["fattura", "2024"], "es": [...] }

  description JSONB DEFAULT '{}',
  -- { "en": "Q1 Sales Report", "it": "Report Vendite Q1", ... }

  notes JSONB DEFAULT '{}',
  -- { "en": "Review with team", "it": "Rivedere con il team", ... }

  -- Metadata
  default_language TEXT DEFAULT 'en',
  available_languages TEXT[] DEFAULT ARRAY['en'],
  auto_translated BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for full-text search (multi-language)
CREATE INDEX idx_documents_tags_search ON documents USING GIN (tags);
CREATE INDEX idx_documents_description_search ON documents USING GIN (description);

-- Helper function: Get translated value
CREATE OR REPLACE FUNCTION get_translation(
  content JSONB,
  preferred_lang TEXT,
  fallback_lang TEXT DEFAULT 'en'
) RETURNS TEXT AS $$
BEGIN
  -- Try preferred language
  IF content ? preferred_lang THEN
    RETURN content->>preferred_lang;
  END IF;

  -- Fallback to default
  IF content ? fallback_lang THEN
    RETURN content->>fallback_lang;
  END IF;

  -- Return first available
  RETURN content->>((SELECT jsonb_object_keys(content) LIMIT 1));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### API Usage

```typescript
// svc-dms/src/routes/documents.ts
import { FastifyInstance } from 'fastify'

app.get('/api/v1/documents/:id', async (req, rep) => {
  const { id } = req.params
  const { tenant_id, preferred_language } = req.authContext

  const result = await db.query(
    `SELECT
      id,
      file_name,
      get_translation(tags, $2) as tags,
      get_translation(description, $2) as description,
      get_translation(notes, $2) as notes,
      default_language,
      available_languages
     FROM documents
     WHERE id = $1 AND tenant_id = $3`,
    [id, preferred_language, tenant_id]
  )

  return result.rows[0]
})

// POST: Create document with initial translation
app.post('/api/v1/documents', async (req, rep) => {
  const { file_name, tags, description, notes } = req.body
  const { tenant_id, preferred_language } = req.authContext

  // Insert with initial language
  const result = await db.query(
    `INSERT INTO documents (
      tenant_id,
      file_name,
      tags,
      description,
      notes,
      default_language
    ) VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *`,
    [
      tenant_id,
      file_name,
      { [preferred_language]: tags },
      { [preferred_language]: description },
      { [preferred_language]: notes },
      preferred_language
    ]
  )

  const document = result.rows[0]

  // Queue AI translation for enabled languages
  await queueAutoTranslation(document.id, tenant_id)

  return document
})
```

---

## 3. AI-Powered Auto-Translation

### Translation Service (svc-i18n)

```typescript
// svc-i18n/src/services/translator.ts
import OpenAI from 'openai'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

interface TranslationRequest {
  text: string
  sourceLanguage: string
  targetLanguages: string[]
  context?: string // Document type, domain
}

export class AITranslator {
  // Translate single text
  async translate(req: TranslationRequest): Promise<Record<string, string>> {
    const translations: Record<string, string> = {}

    // Batch translate to all target languages
    for (const targetLang of req.targetLanguages) {
      translations[targetLang] = await this.translateTo(
        req.text,
        req.sourceLanguage,
        targetLang,
        req.context
      )
    }

    return translations
  }

  // Translate to single language
  private async translateTo(
    text: string,
    sourceLang: string,
    targetLang: string,
    context?: string
  ): Promise<string> {
    // Check translation cache first
    const cached = await this.getFromCache(text, sourceLang, targetLang)
    if (cached) return cached

    // Call GPT-4 for translation
    const prompt = this.buildTranslationPrompt(text, sourceLang, targetLang, context)

    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo',
      messages: [
        {
          role: 'system',
          content: `You are a professional translator specializing in business and technical content.
Translate naturally while preserving:
- Technical terms accuracy
- Business context
- Tone and formality
- Format (if any markdown/HTML)

${context ? `Context: This is a ${context}` : ''}`
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.3, // Low temperature for consistent translations
      max_tokens: 1000
    })

    const translation = completion.choices[0].message.content.trim()

    // Cache translation
    await this.saveToCache(text, sourceLang, targetLang, translation)

    return translation
  }

  private buildTranslationPrompt(
    text: string,
    sourceLang: string,
    targetLang: string,
    context?: string
  ): string {
    return `Translate the following text from ${sourceLang} to ${targetLang}.

Original text:
${text}

Translated text:`
  }

  // Translation memory cache
  private async getFromCache(
    text: string,
    sourceLang: string,
    targetLang: string
  ): Promise<string | null> {
    const key = this.getCacheKey(text, sourceLang, targetLang)
    return await redis.get(key)
  }

  private async saveToCache(
    text: string,
    sourceLang: string,
    targetLang: string,
    translation: string
  ): Promise<void> {
    const key = this.getCacheKey(text, sourceLang, targetLang)
    // Cache for 90 days
    await redis.setex(key, 90 * 24 * 60 * 60, translation)
  }

  private getCacheKey(text: string, sourceLang: string, targetLang: string): string {
    const hash = crypto.createHash('md5').update(text).digest('hex')
    return `i18n:${sourceLang}:${targetLang}:${hash}`
  }

  // Batch translate (for bulk operations)
  async translateBatch(items: TranslationRequest[]): Promise<Record<string, Record<string, string>>> {
    const results: Record<string, Record<string, string>> = {}

    // Process in parallel (max 5 concurrent)
    const batches = chunk(items, 5)

    for (const batch of batches) {
      const promises = batch.map(item =>
        this.translate(item).then(translations => ({
          text: item.text,
          translations
        }))
      )

      const batchResults = await Promise.all(promises)

      batchResults.forEach(({ text, translations }) => {
        results[text] = translations
      })
    }

    return results
  }
}
```

### Auto-Translation Trigger

```typescript
// Automatic translation on content save
app.post('/api/v1/documents/:id/tags', async (req, rep) => {
  const { id } = req.params
  const { tags } = req.body
  const { tenant_id, preferred_language } = req.authContext

  // Get tenant's enabled languages
  const tenant = await getTenant(tenant_id)
  const enabledLanguages = tenant.enabled_languages || ['en']

  // Save tags in user's language
  await db.query(
    `UPDATE documents
     SET tags = jsonb_set(tags, '{${preferred_language}}', $1)
     WHERE id = $2 AND tenant_id = $3`,
    [JSON.stringify(tags), id, tenant_id]
  )

  // Auto-translate to other enabled languages
  if (enabledLanguages.length > 1) {
    const otherLanguages = enabledLanguages.filter(lang => lang !== preferred_language)

    // Queue translation job
    await queueJob('translate_document_tags', {
      document_id: id,
      tenant_id,
      tags,
      source_language: preferred_language,
      target_languages: otherLanguages
    })
  }

  return { success: true }
})

// Background job: Process translation
async function processTranslationJob(job: Job) {
  const { document_id, tenant_id, tags, source_language, target_languages } = job.data

  const translator = new AITranslator()

  // Translate each tag
  const translatedTags: Record<string, string[]> = {}

  for (const tag of tags) {
    const translations = await translator.translate({
      text: tag,
      sourceLanguage: source_language,
      targetLanguages: target_languages,
      context: 'document_tag'
    })

    // Store translations
    for (const [lang, translation] of Object.entries(translations)) {
      if (!translatedTags[lang]) {
        translatedTags[lang] = []
      }
      translatedTags[lang].push(translation)
    }
  }

  // Update database with translations
  for (const [lang, translated] of Object.entries(translatedTags)) {
    await db.query(
      `UPDATE documents
       SET tags = jsonb_set(tags, '{${lang}}', $1),
           available_languages = array_append(available_languages, $2),
           auto_translated = true
       WHERE id = $3 AND tenant_id = $4`,
      [JSON.stringify(translated), lang, document_id, tenant_id]
    )
  }

  console.log(`Translated tags for document ${document_id} to ${target_languages.join(', ')}`)
}
```

---

## 4. Translation Management UI (Admin)

### Enable Languages per Tenant

```tsx
// app-admin-console/pages/settings/languages.tsx
export default function LanguageSettings() {
  const [enabledLanguages, setEnabledLanguages] = useState<string[]>(['en'])
  const [autoTranslate, setAutoTranslate] = useState(true)

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Language Settings</h1>

      {/* Default Language */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">
          Default Language
        </label>
        <Select
          value={defaultLanguage}
          onChange={setDefaultLanguage}
          options={[
            { value: 'en', label: '🇬🇧 English' },
            { value: 'it', label: '🇮🇹 Italian' },
            { value: 'es', label: '🇪🇸 Spanish' },
            { value: 'fr', label: '🇫🇷 French' },
            { value: 'de', label: '🇩🇪 German' },
          ]}
        />
      </div>

      {/* Enabled Languages */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">
          Enabled Languages
        </label>
        <p className="text-sm text-gray-600 mb-3">
          Users can switch to these languages. Content will be auto-translated.
        </p>

        <div className="space-y-2">
          {AVAILABLE_LANGUAGES.map(lang => (
            <label key={lang.code} className="flex items-center gap-3">
              <input
                type="checkbox"
                checked={enabledLanguages.includes(lang.code)}
                onChange={(e) => {
                  if (e.target.checked) {
                    setEnabledLanguages([...enabledLanguages, lang.code])
                  } else {
                    setEnabledLanguages(enabledLanguages.filter(l => l !== lang.code))
                  }
                }}
              />
              <span>{lang.flag} {lang.name}</span>
              {lang.tier === 2 && (
                <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                  AI-translated
                </span>
              )}
            </label>
          ))}
        </div>
      </div>

      {/* Auto-translate Toggle */}
      <div className="mb-6">
        <label className="flex items-center gap-3">
          <input
            type="checkbox"
            checked={autoTranslate}
            onChange={(e) => setAutoTranslate(e.target.checked)}
          />
          <div>
            <span className="font-medium">Auto-translate content</span>
            <p className="text-sm text-gray-600">
              Automatically translate tags, descriptions, and notes when users save content
            </p>
          </div>
        </label>
      </div>

      {/* Cost Estimate */}
      <div className="bg-blue-50 p-4 rounded-lg mb-6">
        <h3 className="font-semibold mb-2">💰 Translation Cost Estimate</h3>
        <p className="text-sm text-gray-700">
          With {enabledLanguages.length} languages enabled and auto-translate on:
        </p>
        <p className="text-lg font-bold text-blue-600 mt-2">
          ~€{estimatedCost}/month
        </p>
        <p className="text-xs text-gray-600 mt-1">
          Based on average usage (5,000 words/month translated)
        </p>
      </div>

      {/* Bulk Translate Existing Content */}
      <div className="border-t pt-6">
        <h3 className="font-semibold mb-3">Bulk Translate Existing Content</h3>
        <p className="text-sm text-gray-600 mb-4">
          Translate all existing documents, tags, and descriptions to newly enabled languages
        </p>

        <button
          onClick={handleBulkTranslate}
          className="bg-blue-500 text-white px-4 py-2 rounded-lg"
        >
          Translate All Content
        </button>

        {bulkTranslateStatus && (
          <div className="mt-4 p-4 bg-gray-50 rounded-lg">
            <p className="text-sm">Progress: {bulkTranslateStatus.progress}%</p>
            <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
              <div
                className="bg-blue-500 h-2 rounded-full"
                style={{ width: `${bulkTranslateStatus.progress}%` }}
              />
            </div>
            <p className="text-xs text-gray-600 mt-2">
              {bulkTranslateStatus.completed} / {bulkTranslateStatus.total} items translated
            </p>
          </div>
        )}
      </div>

      <button
        onClick={saveSettings}
        className="bg-green-500 text-white px-6 py-2 rounded-lg mt-6"
      >
        Save Settings
      </button>
    </div>
  )
}
```

### Translation Editor (Edit AI Translations)

```tsx
// components/TranslationEditor.tsx
interface TranslationEditorProps {
  field: 'tags' | 'description' | 'notes'
  documentId: string
  currentValue: Record<string, any>
  enabledLanguages: string[]
}

export function TranslationEditor({
  field,
  documentId,
  currentValue,
  enabledLanguages
}: TranslationEditorProps) {
  const [translations, setTranslations] = useState(currentValue)
  const [editingLang, setEditingLang] = useState<string | null>(null)

  const handleRetranslate = async (targetLang: string) => {
    const sourceLang = Object.keys(translations)[0]
    const sourceText = translations[sourceLang]

    const result = await fetch('/api/i18n/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: sourceText,
        source_language: sourceLang,
        target_language: targetLang,
        context: field
      })
    })

    const { translation } = await result.json()

    setTranslations({
      ...translations,
      [targetLang]: translation
    })
  }

  return (
    <div className="border rounded-lg p-4">
      <h4 className="font-semibold mb-4">Translations for {field}</h4>

      <div className="space-y-4">
        {enabledLanguages.map(lang => (
          <div key={lang} className="border-b pb-3">
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-medium">
                {LANGUAGE_FLAGS[lang]} {LANGUAGE_NAMES[lang]}
              </label>

              <div className="flex gap-2">
                {translations[lang] && (
                  <button
                    onClick={() => handleRetranslate(lang)}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    🔄 Re-translate
                  </button>
                )}
                <button
                  onClick={() => setEditingLang(lang)}
                  className="text-xs text-gray-600 hover:underline"
                >
                  ✏️ Edit
                  </button>
              </div>
            </div>

            {editingLang === lang ? (
              <textarea
                value={translations[lang] || ''}
                onChange={(e) => setTranslations({
                  ...translations,
                  [lang]: e.target.value
                })}
                className="w-full border rounded p-2 text-sm"
                rows={3}
              />
            ) : (
              <p className="text-sm text-gray-700">
                {translations[lang] || (
                  <span className="text-gray-400 italic">Not translated yet</span>
                )}
              </p>
            )}
          </div>
        ))}
      </div>

      <button
        onClick={() => saveTranslations(documentId, field, translations)}
        className="mt-4 bg-blue-500 text-white px-4 py-2 rounded text-sm"
      >
        Save Translations
      </button>
    </div>
  )
}
```

---

## 5. Language Switcher (User UI)

```tsx
// components/LanguageSwitcher.tsx
import { useRouter, usePathname } from 'next/navigation'
import { Globe } from 'lucide-react'

export function LanguageSwitcher() {
  const router = useRouter()
  const pathname = usePathname()
  const currentLocale = pathname.split('/')[1]

  const availableLanguages = [
    { code: 'en', flag: '🇬🇧', name: 'English' },
    { code: 'it', flag: '🇮🇹', name: 'Italiano' },
    { code: 'es', flag: '🇪🇸', name: 'Español' },
    { code: 'fr', flag: '🇫🇷', name: 'Français' },
    { code: 'de', flag: '🇩🇪', name: 'Deutsch' },
  ]

  const switchLanguage = async (newLocale: string) => {
    // Update user preference
    await fetch('/api/user/preferences', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ preferred_language: newLocale })
    })

    // Navigate to new locale
    const newPathname = pathname.replace(`/${currentLocale}`, `/${newLocale}`)
    router.push(newPathname)
  }

  return (
    <div className="relative">
      <button className="flex items-center gap-2 px-3 py-2 hover:bg-gray-100 rounded-lg">
        <Globe className="w-4 h-4" />
        <span className="text-sm">
          {availableLanguages.find(l => l.code === currentLocale)?.flag}
        </span>
      </button>

      {/* Dropdown */}
      <div className="absolute right-0 mt-2 w-48 bg-white border rounded-lg shadow-lg z-50">
        {availableLanguages.map(lang => (
          <button
            key={lang.code}
            onClick={() => switchLanguage(lang.code)}
            className={`w-full flex items-center gap-3 px-4 py-2 hover:bg-gray-50 ${
              lang.code === currentLocale ? 'bg-blue-50' : ''
            }`}
          >
            <span className="text-xl">{lang.flag}</span>
            <span className="text-sm">{lang.name}</span>
            {lang.code === currentLocale && (
              <span className="ml-auto text-blue-500">✓</span>
            )}
          </button>
        ))}
      </div>
    </div>
  )
}
```

---

## 6. RTL (Right-to-Left) Support

For Arabic and Hebrew:

```tsx
// app/[locale]/layout.tsx
export default function LocaleLayout({ params, children }) {
  const { locale } = params
  const direction = ['ar', 'he'].includes(locale) ? 'rtl' : 'ltr'

  return (
    <html lang={locale} dir={direction}>
      <body>{children}</body>
    </html>
  )
}
```

```css
/* globals.css */
[dir="rtl"] {
  text-align: right;
}

[dir="rtl"] .sidebar {
  left: auto;
  right: 0;
}

[dir="rtl"] .ml-4 {
  margin-left: 0;
  margin-right: 1rem;
}
```

---

## 7. Email Templates i18n

```typescript
// svc-comm/src/templates/welcome-email.ts
interface WelcomeEmailData {
  user_name: string
  login_url: string
  language: string
}

const WELCOME_EMAIL_TEMPLATES = {
  en: {
    subject: 'Welcome to EWH Platform!',
    body: `Hi {{user_name}},

Welcome to EWH Platform! We're excited to have you on board.

Get started by logging in:
{{login_url}}

If you have any questions, our support team is here to help.

Best regards,
The EWH Team`
  },
  it: {
    subject: 'Benvenuto su EWH Platform!',
    body: `Ciao {{user_name}},

Benvenuto su EWH Platform! Siamo entusiasti di averti con noi.

Inizia effettuando il login:
{{login_url}}

Se hai domande, il nostro team di supporto è qui per aiutarti.

Cordiali saluti,
Il Team EWH`
  },
  // ...other languages
}

export function renderWelcomeEmail(data: WelcomeEmailData): { subject: string, body: string } {
  const template = WELCOME_EMAIL_TEMPLATES[data.language] || WELCOME_EMAIL_TEMPLATES.en

  return {
    subject: template.subject,
    body: template.body
      .replace('{{user_name}}', data.user_name)
      .replace('{{login_url}}', data.login_url)
  }
}
```

---

## 8. Translation Workflow (AI-Aided Form)

### Translation Form with AI Assistance

```tsx
// components/AITranslationForm.tsx
export function AITranslationForm() {
  const [sourceText, setSourceText] = useState('')
  const [sourceLang, setSourceLang] = useState('en')
  const [targetLangs, setTargetLangs] = useState<string[]>(['it'])
  const [translations, setTranslations] = useState<Record<string, string>>({})
  const [isTranslating, setIsTranslating] = useState(false)

  const handleAutoTranslate = async () => {
    setIsTranslating(true)

    const result = await fetch('/api/i18n/translate-batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: sourceText,
        source_language: sourceLang,
        target_languages: targetLangs
      })
    })

    const { translations: aiTranslations } = await result.json()
    setTranslations(aiTranslations)
    setIsTranslating(false)
  }

  return (
    <div className="space-y-6">
      {/* Source Text */}
      <div>
        <label className="block text-sm font-medium mb-2">
          Source Text
        </label>
        <div className="flex gap-2 mb-2">
          <Select
            value={sourceLang}
            onChange={setSourceLang}
            options={LANGUAGE_OPTIONS}
            className="w-32"
          />
        </div>
        <textarea
          value={sourceText}
          onChange={(e) => setSourceText(e.target.value)}
          className="w-full border rounded-lg p-3"
          rows={5}
          placeholder="Enter text to translate..."
        />
      </div>

      {/* Target Languages */}
      <div>
        <label className="block text-sm font-medium mb-2">
          Translate to:
        </label>
        <div className="flex flex-wrap gap-2">
          {AVAILABLE_LANGUAGES.filter(l => l !== sourceLang).map(lang => (
            <label key={lang} className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={targetLangs.includes(lang)}
                onChange={(e) => {
                  if (e.target.checked) {
                    setTargetLangs([...targetLangs, lang])
                  } else {
                    setTargetLangs(targetLangs.filter(l => l !== lang))
                  }
                }}
              />
              {LANGUAGE_FLAGS[lang]} {LANGUAGE_NAMES[lang]}
            </label>
          ))}
        </div>
      </div>

      {/* AI Translate Button */}
      <button
        onClick={handleAutoTranslate}
        disabled={!sourceText || targetLangs.length === 0 || isTranslating}
        className="bg-blue-500 text-white px-6 py-2 rounded-lg disabled:opacity-50"
      >
        {isTranslating ? (
          <>
            <Loader className="animate-spin w-4 h-4 inline mr-2" />
            Translating...
          </>
        ) : (
          <>
            🤖 Auto-Translate with AI
          </>
        )}
      </button>

      {/* Translations */}
      {Object.keys(translations).length > 0 && (
        <div className="space-y-4">
          <h3 className="font-semibold">Translations:</h3>

          {Object.entries(translations).map(([lang, translation]) => (
            <div key={lang} className="border rounded-lg p-4">
              <div className="flex justify-between items-center mb-2">
                <label className="font-medium">
                  {LANGUAGE_FLAGS[lang]} {LANGUAGE_NAMES[lang]}
                </label>
                <button
                  onClick={() => handleAutoTranslate()}
                  className="text-xs text-blue-600 hover:underline"
                >
                  🔄 Re-translate
                </button>
              </div>

              <textarea
                value={translation}
                onChange={(e) => setTranslations({
                  ...translations,
                  [lang]: e.target.value
                })}
                className="w-full border rounded p-2"
                rows={3}
              />

              <p className="text-xs text-gray-500 mt-1">
                ✏️ You can edit AI translations manually
              </p>
            </div>
          ))}
        </div>
      )}

      {/* Save */}
      {Object.keys(translations).length > 0 && (
        <button
          onClick={handleSave}
          className="bg-green-500 text-white px-6 py-2 rounded-lg"
        >
          Save Translations
        </button>
      )}
    </div>
  )
}
```

---

## 9. Cost Estimation

### AI Translation Costs

```typescript
// Pricing (OpenAI GPT-4 Turbo)
const COST_PER_1K_INPUT_TOKENS = 0.01 // $0.01
const COST_PER_1K_OUTPUT_TOKENS = 0.03 // $0.03

// Average tokens per word: ~1.3
// Average translation: 100 words = 130 input + 130 output tokens = 260 tokens total

function estimateTranslationCost(
  wordsPerMonth: number,
  numberOfLanguages: number
): number {
  const tokensPerWord = 1.3
  const totalTokens = wordsPerMonth * tokensPerWord * 2 // input + output

  const costPerThousandTokens = (COST_PER_1K_INPUT_TOKENS + COST_PER_1K_OUTPUT_TOKENS) / 2
  const costPerLanguage = (totalTokens / 1000) * costPerThousandTokens

  return costPerLanguage * (numberOfLanguages - 1) // -1 because source is not translated
}

// Example:
// 5,000 words/month, 5 languages enabled
// = €26/month

// 50,000 words/month (busy tenant), 5 languages
// = €260/month
```

### Cost Optimization Strategies

1. **Translation Memory (Cache)**
   - Cache common phrases
   - 80%+ hit rate → save 80% costs

2. **Batch Processing**
   - Translate in bulk during off-peak hours
   - Lower priority = lower cost (if using tiered API)

3. **Smart Translation**
   - Don't re-translate unchanged content
   - Only translate when content actually changes

4. **Hybrid Approach**
   - Tier 1 languages: Professional human review
   - Tier 2 languages: AI-only (acceptable quality)

---

## 10. Implementation Roadmap

**Phase 1: Foundation (2 weeks)**
- [ ] Setup next-intl
- [ ] Create base translation files (en, it, es, fr, de)
- [ ] Implement language switcher
- [ ] User preference storage

**Phase 2: Database i18n (2 weeks)**
- [ ] JSONB multi-language schema
- [ ] API support for multi-language content
- [ ] Migration script for existing data

**Phase 3: AI Translation Service (2 weeks)**
- [ ] svc-i18n microservice
- [ ] OpenAI GPT-4 integration
- [ ] Translation cache (Redis)
- [ ] Batch processing queue

**Phase 4: Admin UI (1 week)**
- [ ] Language settings page
- [ ] Translation editor
- [ ] Bulk translate tool
- [ ] Cost estimator

**Phase 5: Auto-Translation (1 week)**
- [ ] Background job processing
- [ ] Auto-translate triggers
- [ ] Translation status tracking
- [ ] Error handling & retry

**Phase 6: Polish & Optimization (1 week)**
- [ ] RTL support (Arabic)
- [ ] Email templates i18n
- [ ] Help articles translation
- [ ] Performance optimization

**Total: 9 weeks**

---

## 📊 Success Metrics

```typescript
interface I18nMetrics {
  // Adoption
  languagesEnabled: number
  usersPerLanguage: Record<string, number>
  contentTranslatedPercent: number

  // Quality
  aiTranslationAccuracy: number // % user-approved
  manualEditRate: number // % AI translations edited by users
  retranslationRate: number

  // Cost
  translationsPerMonth: number
  costPerTranslation: number
  totalMonthlySpend: number
  costSavingsFromCache: number // % saved via cache hits

  // Impact
  userSatisfaction: number // Survey score
  contentDiscoveryRate: number // % users find content in their language
  supportTicketsReduced: number // % reduction in "language barrier" tickets
}
```

---

## 🎯 Future Enhancements (v3.0)

- [ ] **Neural Machine Translation (NMT)**
  - Train custom model on domain-specific corpus
  - Better accuracy for technical/business terms

- [ ] **Community Translation Platform**
  - Let users suggest better translations
  - Crowdsource translations for Tier 2 languages
  - Gamification (badges, leaderboards)

- [ ] **Voice Translation**
  - Text-to-speech in multiple languages
  - Voice notes auto-transcribed + translated

- [ ] **Real-Time Translation**
  - Live chat translation (user A speaks Italian, user B reads in English)
  - Collaboration without language barriers

- [ ] **Context-Aware Translation**
  - Different translations based on context (formal vs casual, technical vs marketing)

---

**Maintainer:** Platform Team
**Cost:** €100-500/month (depends on usage)
**ROI:** Global expansion, 3x potential market size
**Last Updated:** 2025-10-04
