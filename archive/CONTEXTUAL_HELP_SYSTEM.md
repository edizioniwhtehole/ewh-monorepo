# EWH Platform - Contextual Help & Documentation System

> **Sistema di help contestuale "a prova di cretino" - ogni elemento UI ha tooltip, documentazione e video integrati**

**Versione:** 1.0.0
**Target:** End users (tenant users + admins)
**Ultima revisione:** 2025-10-04

---

## 🎯 Obiettivo

Creare un'esperienza utente **zero-friction** dove:
- ✅ Ogni pulsante, grafico, form ha help inline
- ✅ Documentazione accessibile senza lasciare l'app
- ✅ Video tutorial contestuali per ogni feature
- ✅ AI assistant che risponde a qualsiasi domanda
- ✅ Onboarding guidato per nuovi utenti

**Principio:** "Nessun utente dovrebbe dover cercare documentazione esterna"

---

## 📋 Componenti del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│  EWH Platform - Contextual Help Architecture               │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  1. Help Drawer (Slide-in Sidebar)      │
│     • Context-aware documentation        │
│     • Search bar                         │
│     • Video library                      │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  2. Widget Tooltips (Inline Help)       │
│     • Button tooltips                    │
│     • Chart explanations                 │
│     • Form field hints                   │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  3. Onboarding Tours                     │
│     • First login walkthrough            │
│     • Feature tours                      │
│     • Progress checklist                 │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  4. AI Assistant Chatbot                 │
│     • GPT-4 powered                      │
│     • Context-aware                      │
│     • Proactive suggestions              │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  5. Video Tutorials (Embedded)           │
│     • Per-feature screencasts            │
│     • YouTube/Loom integration           │
│     • Interactive overlays               │
└──────────────────────────────────────────┘
```

---

## 1. Help Drawer (Documentation Sidebar)

### UI/UX Design

```
┌────────────────────────────────────────────────────────────┐
│  App UI (Main Content)                      [?] Help  [×]  │ ← Help button (top-right)
│                                                            │
│  ┌──────────────────────────┐  ┌─────────────────────────┐│
│  │  Document List           │  │  Help Drawer (Slide-in) ││
│  │  ┌────────────────────┐  │  │  ┌───────────────────┐  ││
│  │  │ Invoice_2024.pdf   │  │  │  │ 🔍 Search help... │  ││
│  │  │ Contract.docx      │  │  │  └───────────────────┘  ││
│  │  │ Report_Q1.xlsx     │  │  │                         ││
│  │  └────────────────────┘  │  │  📚 Documents           ││
│  │                          │  │  ───────────────────    ││
│  │  [+ Upload Document]     │  │  • Upload documents     ││
│  │        ↑                 │  │  • Delete documents     ││
│  │        └─ Tooltip: "Carica│  │  • Share with team      ││
│  │           nuovi file..."  │  │  • Version history      ││
│  │                          │  │                         ││
│  └──────────────────────────┘  │  🎬 Video Tutorial      ││
│                                │  ───────────────────    ││
│                                │  ▶ How to upload (2:30) ││
│                                │                         ││
│                                │  ⌨️ Shortcuts           ││
│                                │  ───────────────────    ││
│                                │  Cmd+U - Upload         ││
│                                │  Cmd+D - Delete         ││
│                                │                         ││
│                                │  💬 Still need help?    ││
│                                │  [Chat with AI]         ││
│                                └─────────────────────────┘│
└────────────────────────────────────────────────────────────┘
```

### Implementation

```tsx
// components/HelpDrawer.tsx
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import { Drawer } from '@/components/ui/Drawer'
import { Search } from '@/components/ui/Search'
import Markdown from 'react-markdown'

interface HelpArticle {
  id: string
  title: string
  content: string
  category: string
  videoUrl?: string
  relatedArticles: string[]
}

export function HelpDrawer() {
  const [isOpen, setIsOpen] = useState(false)
  const [articles, setArticles] = useState<HelpArticle[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const router = useRouter()

  // Context-aware: load help based on current page
  useEffect(() => {
    const loadContextualHelp = async () => {
      const context = getContextFromRoute(router.pathname)
      const response = await fetch(`/api/help/articles?context=${context}`)
      const data = await response.json()
      setArticles(data.articles)
    }

    if (isOpen) {
      loadContextualHelp()
    }
  }, [isOpen, router.pathname])

  return (
    <>
      {/* Help Button (top-right) */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed top-4 right-4 p-2 bg-blue-500 text-white rounded-full"
      >
        <QuestionMarkIcon />
      </button>

      {/* Drawer */}
      <Drawer
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        position="right"
        width="400px"
      >
        <div className="p-6">
          {/* Search */}
          <Search
            value={searchQuery}
            onChange={setSearchQuery}
            placeholder="Search help..."
            onSearch={handleSearch}
          />

          {/* Context-aware articles */}
          <div className="mt-6">
            <h3 className="text-lg font-semibold mb-4">
              Help for: {getCurrentPageTitle(router.pathname)}
            </h3>

            {filteredArticles.map(article => (
              <HelpArticleCard
                key={article.id}
                article={article}
                onClick={() => openArticle(article)}
              />
            ))}
          </div>

          {/* Video Tutorials */}
          {currentVideo && (
            <div className="mt-6">
              <h3 className="text-lg font-semibold mb-2">Video Tutorial</h3>
              <VideoEmbed url={currentVideo.url} />
            </div>
          )}

          {/* Keyboard Shortcuts */}
          <div className="mt-6">
            <h3 className="text-lg font-semibold mb-2">Keyboard Shortcuts</h3>
            <KeyboardShortcuts context={router.pathname} />
          </div>

          {/* AI Chat CTA */}
          <div className="mt-6 p-4 bg-gray-100 rounded-lg">
            <p className="text-sm text-gray-600 mb-2">Still need help?</p>
            <button
              onClick={openAIChat}
              className="w-full bg-blue-500 text-white py-2 rounded-lg"
            >
              💬 Chat with AI Assistant
            </button>
          </div>
        </div>
      </Drawer>
    </>
  )
}

// Helper: Get context from route
function getContextFromRoute(pathname: string): string {
  const contextMap = {
    '/documents': 'documents',
    '/projects': 'projects',
    '/settings': 'settings',
    '/analytics': 'analytics',
    // ...
  }

  return contextMap[pathname] || 'general'
}
```

### Backend API

```typescript
// svc-kb/src/routes/help.ts
import { FastifyInstance } from 'fastify'
import { z } from 'zod'

const GetArticlesSchema = z.object({
  context: z.string(),
  query: z.string().optional()
})

export async function helpRoutes(app: FastifyInstance) {
  // Get contextual help articles
  app.get('/api/help/articles', async (req, rep) => {
    const { context, query } = GetArticlesSchema.parse(req.query)
    const { tenant_id } = req.authContext

    // Get articles for context
    let articles = await db.query(
      `SELECT * FROM kb_articles
       WHERE context = $1
       AND (tenant_id IS NULL OR tenant_id = $2)
       ORDER BY priority DESC`,
      [context, tenant_id]
    )

    // If search query, filter by full-text search
    if (query) {
      articles = await db.query(
        `SELECT * FROM kb_articles
         WHERE to_tsvector('english', title || ' ' || content) @@ plainto_tsquery('english', $1)
         AND (tenant_id IS NULL OR tenant_id = $2)
         ORDER BY ts_rank(to_tsvector('english', title || ' ' || content), plainto_tsquery('english', $1)) DESC`,
        [query, tenant_id]
      )
    }

    return { articles: articles.rows }
  })

  // Get single article
  app.get('/api/help/articles/:id', async (req, rep) => {
    const { id } = req.params

    const article = await db.query(
      `SELECT * FROM kb_articles WHERE id = $1`,
      [id]
    )

    if (article.rows.length === 0) {
      return rep.code(404).send({ error: 'Article not found' })
    }

    // Track article view
    await trackArticleView(id, req.authContext.user_id)

    return article.rows[0]
  })

  // Search articles (Algolia integration)
  app.get('/api/help/search', async (req, rep) => {
    const { query } = req.query

    // Use Algolia for better search
    const results = await algolia.search(query, {
      filters: `tenant_id:${req.authContext.tenant_id} OR tenant_id:null`
    })

    return { results }
  })
}
```

---

## 2. Widget Tooltips (Inline Help)

### Design Patterns

```tsx
// Pattern 1: Help Button with Tooltip
<HelpButton
  action="delete_document"
  variant="danger"
  tooltip={{
    title: "Delete Document",
    description: "Permanently delete this document. This action cannot be undone.",
    warning: "⚠️ This is irreversible",
    helpArticle: "kb/documents/delete",
    videoUrl: "https://help.polosaas.it/videos/delete-doc.mp4"
  }}
  onConfirm={handleDelete}
>
  Delete Document
</HelpButton>

// Pattern 2: Chart with Contextual Help
<Chart
  type="bar"
  data={salesData}
  helpTooltip={{
    title: "Sales by Region",
    description: "Shows total sales (€) per region in the last 30 days",
    helpArticle: "kb/analytics/sales-by-region",
    interactive: true, // Show values on hover
    legend: {
      "Blue bars": "Current month",
      "Gray bars": "Previous month"
    }
  }}
/>

// Pattern 3: Form Field with Hint
<FormField
  name="api_key"
  label="API Key"
  type="password"
  helpHint={{
    text: "Your secret API key. Keep it safe!",
    learnMore: "kb/api/authentication",
    example: "pk_live_51H8...",
    copyable: true // Show "Copy" button
  }}
/>

// Pattern 4: Complex Action with Wizard
<Button
  onClick={openMigrationWizard}
  helpTooltip={{
    title: "Migrate Tenant",
    description: "Move tenant to a different database tier",
    complexity: "advanced", // Show "Advanced" badge
    estimatedTime: "10-15 minutes",
    prerequisites: [
      "Backup completed",
      "No active users",
      "Sufficient storage"
    ],
    helpArticle: "kb/admin/tenant-migration"
  }}
>
  Migrate Tenant
</Button>
```

### Component Implementation

```tsx
// components/HelpButton.tsx
import { useState } from 'react'
import { Tooltip } from '@/components/ui/Tooltip'
import { HelpCircle, Video, Book } from 'lucide-react'

interface HelpButtonProps {
  action: string
  tooltip: {
    title: string
    description: string
    warning?: string
    helpArticle?: string
    videoUrl?: string
  }
  onConfirm: () => void
  children: React.ReactNode
  variant?: 'primary' | 'danger' | 'secondary'
}

export function HelpButton({
  action,
  tooltip,
  onConfirm,
  children,
  variant = 'primary'
}: HelpButtonProps) {
  const [showTooltip, setShowTooltip] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  return (
    <div className="relative inline-block">
      {/* Main Button */}
      <button
        onClick={() => setShowConfirm(true)}
        onMouseEnter={() => setShowTooltip(true)}
        onMouseLeave={() => setShowTooltip(false)}
        className={`px-4 py-2 rounded-lg ${getVariantClasses(variant)}`}
      >
        {children}
        <HelpCircle className="ml-2 w-4 h-4 inline" />
      </button>

      {/* Tooltip */}
      {showTooltip && (
        <Tooltip position="top">
          <div className="max-w-xs p-4">
            <h4 className="font-semibold mb-2">{tooltip.title}</h4>
            <p className="text-sm text-gray-600 mb-3">{tooltip.description}</p>

            {tooltip.warning && (
              <div className="bg-yellow-50 border-l-4 border-yellow-400 p-3 mb-3">
                <p className="text-sm text-yellow-800">{tooltip.warning}</p>
              </div>
            )}

            {/* Quick Links */}
            <div className="flex gap-2 mt-3">
              {tooltip.helpArticle && (
                <a
                  href={`/help/${tooltip.helpArticle}`}
                  className="text-xs text-blue-600 flex items-center gap-1"
                >
                  <Book className="w-3 h-3" />
                  Read more
                </a>
              )}

              {tooltip.videoUrl && (
                <a
                  href={tooltip.videoUrl}
                  target="_blank"
                  className="text-xs text-blue-600 flex items-center gap-1"
                >
                  <Video className="w-3 h-3" />
                  Watch video
                </a>
              )}
            </div>
          </div>
        </Tooltip>
      )}

      {/* Confirmation Dialog */}
      {showConfirm && (
        <ConfirmDialog
          title={tooltip.title}
          message={tooltip.description}
          warning={tooltip.warning}
          onConfirm={() => {
            onConfirm()
            setShowConfirm(false)
            trackHelpAction(action, 'confirmed')
          }}
          onCancel={() => {
            setShowConfirm(false)
            trackHelpAction(action, 'cancelled')
          }}
        />
      )}
    </div>
  )
}
```

---

## 3. Onboarding Tours

### First Login Tour

```tsx
// components/OnboardingTour.tsx
import Joyride, { Step } from 'react-joyride'
import { useState, useEffect } from 'react'

const FIRST_LOGIN_STEPS: Step[] = [
  {
    target: '.sidebar-navigation',
    content: '👋 Welcome to EWH Platform! This is your main navigation.',
    placement: 'right'
  },
  {
    target: '.upload-button',
    content: '📁 Upload your first document here. Drag & drop is supported!',
    placement: 'bottom'
  },
  {
    target: '.search-bar',
    content: '🔍 Search across all your documents with full-text search.',
    placement: 'bottom'
  },
  {
    target: '.help-button',
    content: '❓ Need help? Click here anytime for contextual documentation.',
    placement: 'left'
  },
  {
    target: '.user-menu',
    content: '⚙️ Manage your settings and team members here.',
    placement: 'bottom'
  }
]

export function OnboardingTour() {
  const [run, setRun] = useState(false)
  const [stepIndex, setStepIndex] = useState(0)

  useEffect(() => {
    // Check if user has seen tour
    const hasSeenTour = localStorage.getItem('onboarding_tour_completed')

    if (!hasSeenTour) {
      // Wait 1 second for page to load
      setTimeout(() => setRun(true), 1000)
    }
  }, [])

  const handleJoyrideCallback = (data: any) => {
    const { status, index, action } = data

    if (status === 'finished' || status === 'skipped') {
      setRun(false)
      localStorage.setItem('onboarding_tour_completed', 'true')
      trackOnboardingCompleted(status)
    }

    if (action === 'next') {
      setStepIndex(index + 1)
    }
  }

  return (
    <Joyride
      steps={FIRST_LOGIN_STEPS}
      run={run}
      stepIndex={stepIndex}
      continuous={true}
      showProgress={true}
      showSkipButton={true}
      callback={handleJoyrideCallback}
      styles={{
        options: {
          primaryColor: '#3B82F6',
          zIndex: 10000
        }
      }}
    />
  )
}
```

### Feature-Specific Tours

```tsx
// Trigger tour when user clicks "Learn this feature"
const DOCUMENT_UPLOAD_TOUR: Step[] = [
  {
    target: '.upload-zone',
    content: 'Drop files here or click to browse. Multiple files supported!',
  },
  {
    target: '.file-preview',
    content: 'Preview your files before uploading. You can remove any file.',
  },
  {
    target: '.metadata-form',
    content: 'Add tags and description to help organize your documents.',
  },
  {
    target: '.upload-confirm',
    content: 'Click here when ready. Upload happens in the background.',
  }
]

// Trigger in component
function DocumentUploadPage() {
  const [showTour, setShowTour] = useState(false)

  return (
    <>
      <button onClick={() => setShowTour(true)}>
        📚 Learn how to upload documents
      </button>

      {showTour && (
        <FeatureTour
          steps={DOCUMENT_UPLOAD_TOUR}
          onComplete={() => setShowTour(false)}
        />
      )}
    </>
  )
}
```

### Progress Checklist

```tsx
// components/OnboardingChecklist.tsx
interface ChecklistItem {
  id: string
  title: string
  description: string
  completed: boolean
  action: string
  helpArticle?: string
}

const ONBOARDING_CHECKLIST: ChecklistItem[] = [
  {
    id: 'upload_first_document',
    title: 'Upload your first document',
    description: 'Add a file to your workspace',
    completed: false,
    action: '/documents/upload'
  },
  {
    id: 'invite_team_member',
    title: 'Invite a team member',
    description: 'Collaborate with your team',
    completed: false,
    action: '/settings/team'
  },
  {
    id: 'create_project',
    title: 'Create your first project',
    description: 'Organize your work',
    completed: false,
    action: '/projects/new'
  },
  {
    id: 'setup_integrations',
    title: 'Connect an integration',
    description: 'Sync with your tools',
    completed: false,
    action: '/settings/integrations'
  }
]

export function OnboardingChecklist() {
  const [checklist, setChecklist] = useState(ONBOARDING_CHECKLIST)
  const progress = checklist.filter(item => item.completed).length

  return (
    <div className="bg-white p-6 rounded-lg shadow">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-semibold">Getting Started</h3>
        <span className="text-sm text-gray-500">
          {progress} / {checklist.length} completed
        </span>
      </div>

      {/* Progress bar */}
      <div className="w-full bg-gray-200 rounded-full h-2 mb-6">
        <div
          className="bg-blue-500 h-2 rounded-full transition-all"
          style={{ width: `${(progress / checklist.length) * 100}%` }}
        />
      </div>

      {/* Checklist items */}
      <div className="space-y-3">
        {checklist.map(item => (
          <ChecklistItem
            key={item.id}
            item={item}
            onComplete={() => markComplete(item.id)}
          />
        ))}
      </div>
    </div>
  )
}
```

---

## 4. AI Assistant Chatbot

### UI Design

```
┌────────────────────────────────────────────────────────────┐
│  App UI (Main Content)                                     │
│                                                            │
│                                                            │
│                                             ┌────────────┐ │
│                                             │  💬 Chat   │ │ ← Floating button
│                                             │  with AI   │ │
│                                             └────────────┘ │
│                                                    ↓       │
│                             ┌──────────────────────────────┤
│                             │  AI Assistant                │
│                             ├──────────────────────────────┤
│                             │  🤖 Hi! How can I help?      │
│                             │                              │
│                             │  💭 You: How do I share a    │
│                             │           document?          │
│                             │                              │
│                             │  🤖 To share a document:     │
│                             │     1. Click the document    │
│                             │     2. Click "Share" button  │
│                             │     3. Enter email           │
│                             │                              │
│                             │     [📺 Watch video]         │
│                             │     [📖 Read full guide]     │
│                             │                              │
│                             │  ┌─────────────────────────┐ │
│                             │  │ Ask anything...         │ │
│                             │  └─────────────────────────┘ │
└─────────────────────────────┴──────────────────────────────┘
```

### Implementation

```tsx
// components/AIAssistant.tsx
import { useState } from 'react'
import { MessageCircle, Send, X } from 'lucide-react'

interface Message {
  role: 'user' | 'assistant'
  content: string
  sources?: { title: string, url: string }[]
  actions?: { label: string, action: () => void }[]
}

export function AIAssistant() {
  const [isOpen, setIsOpen] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      content: '👋 Hi! I\'m your AI assistant. Ask me anything about EWH Platform!'
    }
  ])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const sendMessage = async () => {
    if (!input.trim()) return

    // Add user message
    const userMessage: Message = { role: 'user', content: input }
    setMessages(prev => [...prev, userMessage])
    setInput('')
    setIsLoading(true)

    // Get AI response
    const response = await fetch('/api/assistant/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: input,
        context: getCurrentPageContext(),
        history: messages.slice(-5) // Last 5 messages for context
      })
    })

    const data = await response.json()

    // Add AI response
    const assistantMessage: Message = {
      role: 'assistant',
      content: data.message,
      sources: data.sources,
      actions: data.actions
    }

    setMessages(prev => [...prev, assistantMessage])
    setIsLoading(false)

    // Track interaction
    trackAIChat(input, data.message)
  }

  return (
    <>
      {/* Floating Button */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 bg-blue-500 text-white p-4 rounded-full shadow-lg hover:bg-blue-600"
      >
        <MessageCircle className="w-6 h-6" />
      </button>

      {/* Chat Window */}
      {isOpen && (
        <div className="fixed bottom-6 right-6 w-96 h-[600px] bg-white rounded-lg shadow-2xl flex flex-col">
          {/* Header */}
          <div className="bg-blue-500 text-white p-4 rounded-t-lg flex justify-between items-center">
            <h3 className="font-semibold">AI Assistant</h3>
            <button onClick={() => setIsOpen(false)}>
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.map((msg, i) => (
              <ChatMessage key={i} message={msg} />
            ))}

            {isLoading && (
              <div className="flex items-center gap-2 text-gray-500">
                <div className="animate-spin h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full" />
                Thinking...
              </div>
            )}
          </div>

          {/* Input */}
          <div className="p-4 border-t">
            <div className="flex gap-2">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
                placeholder="Ask anything..."
                className="flex-1 px-3 py-2 border rounded-lg"
              />
              <button
                onClick={sendMessage}
                disabled={!input.trim() || isLoading}
                className="bg-blue-500 text-white p-2 rounded-lg disabled:opacity-50"
              >
                <Send className="w-5 h-5" />
              </button>
            </div>

            {/* Quick Actions */}
            <div className="flex gap-2 mt-2">
              <button
                onClick={() => setInput('How do I upload a document?')}
                className="text-xs bg-gray-100 px-2 py-1 rounded"
              >
                Upload docs
              </button>
              <button
                onClick={() => setInput('How do I share with team?')}
                className="text-xs bg-gray-100 px-2 py-1 rounded"
              >
                Share files
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

// Message component
function ChatMessage({ message }: { message: Message }) {
  const isUser = message.role === 'user'

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
      <div
        className={`max-w-[80%] p-3 rounded-lg ${
          isUser ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-900'
        }`}
      >
        <p className="text-sm">{message.content}</p>

        {/* Sources */}
        {message.sources && message.sources.length > 0 && (
          <div className="mt-2 pt-2 border-t border-gray-200">
            <p className="text-xs text-gray-500 mb-1">Sources:</p>
            {message.sources.map((source, i) => (
              <a
                key={i}
                href={source.url}
                className="text-xs text-blue-600 block hover:underline"
              >
                📖 {source.title}
              </a>
            ))}
          </div>
        )}

        {/* Actions */}
        {message.actions && message.actions.length > 0 && (
          <div className="mt-2 space-y-1">
            {message.actions.map((action, i) => (
              <button
                key={i}
                onClick={action.action}
                className="w-full text-xs bg-white text-gray-900 px-2 py-1 rounded border"
              >
                {action.label}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
```

### Backend (GPT-4 Integration)

```typescript
// svc-assistant/src/routes/chat.ts
import OpenAI from 'openai'
import { FastifyInstance } from 'fastify'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

export async function chatRoutes(app: FastifyInstance) {
  app.post('/api/assistant/chat', async (req, rep) => {
    const { message, context, history } = req.body
    const { tenant_id, user_id } = req.authContext

    // Build system prompt with EWH documentation
    const systemPrompt = `You are a helpful AI assistant for EWH Platform, a SaaS application for document management and collaboration.

Your role:
- Answer questions about how to use EWH Platform
- Provide step-by-step instructions
- Link to relevant documentation
- Be friendly and concise

Current context:
- User is on page: ${context.page}
- User's vertical: ${context.vertical || 'core'}
- User's role: ${context.userRole}

Documentation available:
${await loadRelevantDocs(message)}

Always provide:
1. Clear answer
2. Link to relevant help article
3. Optional: Quick action buttons`

    // Call GPT-4
    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo',
      messages: [
        { role: 'system', content: systemPrompt },
        ...history.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        { role: 'user', content: message }
      ],
      temperature: 0.7,
      max_tokens: 500
    })

    const aiMessage = completion.choices[0].message.content

    // Find relevant sources
    const sources = await findRelevantArticles(message)

    // Generate action buttons
    const actions = generateActions(message, context)

    // Track conversation
    await trackAIConversation({
      tenant_id,
      user_id,
      message,
      response: aiMessage,
      context
    })

    return {
      message: aiMessage,
      sources,
      actions
    }
  })
}

// Load relevant documentation for context
async function loadRelevantDocs(query: string): Promise<string> {
  // Search knowledge base
  const articles = await searchKB(query, { limit: 3 })

  return articles.map(a =>
    `- ${a.title}: ${a.summary}`
  ).join('\n')
}

// Find relevant articles to cite
async function findRelevantArticles(query: string) {
  const results = await searchKB(query, { limit: 2 })

  return results.map(article => ({
    title: article.title,
    url: `/help/${article.slug}`
  }))
}

// Generate contextual action buttons
function generateActions(message: string, context: any) {
  const actions = []

  // Detect intent and add actions
  if (message.toLowerCase().includes('upload')) {
    actions.push({
      label: '📁 Go to Upload',
      action: 'navigate:/documents/upload'
    })
  }

  if (message.toLowerCase().includes('share')) {
    actions.push({
      label: '👥 Open Share Dialog',
      action: 'open-modal:share'
    })
  }

  return actions
}
```

### Proactive Suggestions

```typescript
// Detect user patterns and suggest help
function useProactiveSuggestions() {
  useEffect(() => {
    // Monitor user activity
    const activityMonitor = new ActivityMonitor()

    // Trigger suggestions based on behavior
    activityMonitor.on('pattern-detected', (pattern) => {
      if (pattern.type === 'multiple-failed-uploads') {
        showAISuggestion({
          message: "I noticed you're having trouble uploading files. Would you like help?",
          actions: [
            { label: 'Show me how', action: () => startUploadTour() },
            { label: 'Dismiss', action: () => {} }
          ]
        })
      }

      if (pattern.type === 'never-used-feature' && pattern.feature === 'projects') {
        showAISuggestion({
          message: "💡 Did you know you can organize documents into projects? Want to learn how?",
          actions: [
            { label: 'Learn more', action: () => openHelpArticle('projects') },
            { label: 'Later', action: () => {} }
          ]
        })
      }
    })
  }, [])
}
```

---

## 5. Video Tutorials System

### Video Library Structure

```typescript
// Database schema
interface VideoTutorial {
  id: string
  title: string
  description: string
  duration: number // seconds
  thumbnail_url: string
  video_url: string // YouTube, Loom, or self-hosted
  category: string // 'getting-started', 'documents', 'projects', etc.
  context: string[] // Pages where this video is relevant
  language: string // 'en', 'it', etc.
  views: number
  helpful_count: number
  created_at: Date
}
```

### Video Player Component

```tsx
// components/VideoPlayer.tsx
import ReactPlayer from 'react-player'

interface VideoPlayerProps {
  videoId: string
  autoplay?: boolean
  onComplete?: () => void
}

export function VideoPlayer({ videoId, autoplay, onComplete }: VideoPlayerProps) {
  const video = useVideo(videoId)

  return (
    <div className="relative aspect-video bg-black rounded-lg overflow-hidden">
      <ReactPlayer
        url={video.video_url}
        width="100%"
        height="100%"
        controls
        playing={autoplay}
        onEnded={() => {
          markVideoComplete(videoId)
          onComplete?.()
        }}
      />

      {/* Overlay with helpful actions */}
      <div className="absolute bottom-4 left-4 right-4 flex justify-between items-center">
        <div className="text-white text-sm">
          {video.title} ({formatDuration(video.duration)})
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => markVideoHelpful(videoId)}
            className="text-white px-3 py-1 bg-green-500 rounded text-xs"
          >
            👍 Helpful
          </button>
          <button
            onClick={() => openRelatedArticle(video.related_article)}
            className="text-white px-3 py-1 bg-blue-500 rounded text-xs"
          >
            📖 Read More
          </button>
        </div>
      </div>
    </div>
  )
}
```

---

## 6. Admin Panel: Help Content Management

### Help CMS UI

```tsx
// app-admin-console/pages/help-content.tsx
export default function HelpContentManager() {
  return (
    <AdminLayout>
      <div className="p-8">
        <h1 className="text-2xl font-bold mb-6">Help Content Management</h1>

        <Tabs>
          {/* Articles Tab */}
          <Tab label="Articles">
            <ArticleList
              onEdit={openArticleEditor}
              onCreate={createNewArticle}
            />
          </Tab>

          {/* Videos Tab */}
          <Tab label="Videos">
            <VideoList
              onUpload={uploadVideo}
              onEdit={editVideo}
            />
          </Tab>

          {/* Tooltips Tab */}
          <Tab label="Tooltips">
            <TooltipLibrary
              onEdit={editTooltip}
              onCreate={createTooltip}
            />
          </Tab>

          {/* Analytics Tab */}
          <Tab label="Analytics">
            <HelpAnalytics />
          </Tab>
        </Tabs>
      </div>
    </AdminLayout>
  )
}

// Article Editor
function ArticleEditor({ articleId }: { articleId?: string }) {
  const [article, setArticle] = useState<Article | null>(null)

  return (
    <div className="grid grid-cols-2 gap-6">
      {/* Editor */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Edit Article</h3>

        <Input
          label="Title"
          value={article.title}
          onChange={(val) => setArticle({ ...article, title: val })}
        />

        <Select
          label="Category"
          options={['Getting Started', 'Documents', 'Projects', 'Settings']}
          value={article.category}
        />

        <Select
          label="Context (where to show)"
          multiple
          options={['/documents', '/projects', '/settings']}
          value={article.contexts}
        />

        <MarkdownEditor
          value={article.content}
          onChange={(val) => setArticle({ ...article, content: val })}
        />

        <Button onClick={saveArticle}>Save Article</Button>
      </div>

      {/* Preview */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Preview</h3>
        <div className="border rounded-lg p-4 bg-white">
          <Markdown content={article.content} />
        </div>
      </div>
    </div>
  )
}
```

### Analytics Dashboard

```tsx
// Help content analytics
function HelpAnalytics() {
  const stats = useHelpStats()

  return (
    <div className="space-y-6">
      {/* Overview */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          title="Total Articles"
          value={stats.totalArticles}
          trend="+12%"
        />
        <StatCard
          title="Total Videos"
          value={stats.totalVideos}
          trend="+5%"
        />
        <StatCard
          title="Help Views (7d)"
          value={stats.viewsLast7Days}
          trend="+23%"
        />
        <StatCard
          title="Avg. Helpfulness"
          value={`${stats.avgHelpfulness}%`}
          trend="+3%"
        />
      </div>

      {/* Top Articles */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Most Viewed Articles</h3>
        <Table
          columns={['Title', 'Category', 'Views', 'Helpful %']}
          data={stats.topArticles}
        />
      </div>

      {/* Search Queries (no results) */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Search Queries with No Results</h3>
        <p className="text-sm text-gray-600 mb-4">
          These searches didn't find relevant help. Consider creating content for them.
        </p>
        <Table
          columns={['Query', 'Count', 'Last Searched']}
          data={stats.failedSearches}
        />
      </div>
    </div>
  )
}
```

---

## 📊 Success Metrics

Track effectiveness of help system:

```typescript
interface HelpMetrics {
  // Engagement
  helpDrawerOpens: number
  tooltipHovers: number
  videoPlays: number
  aiChatMessages: number

  // Effectiveness
  avgTimeToAnswer: number // How fast users find answers
  helpfulnessRate: number // % of "helpful" votes
  featureAdoptionRate: number // % users complete onboarding

  // Content gaps
  unansweredQuestions: string[] // AI couldn't answer
  lowHelpfulnessArticles: Article[] // Articles with <50% helpful rate

  // Support reduction
  supportTicketsReduced: number // % reduction vs. baseline
}
```

---

## 🚀 Implementation Roadmap

**Phase 1: Foundation (2 weeks)**
- [ ] Help drawer component
- [ ] Basic tooltip system
- [ ] Knowledge base backend (`svc-kb`)
- [ ] First 20 help articles

**Phase 2: Video System (1 week)**
- [ ] Video player component
- [ ] Video library (10 getting-started videos)
- [ ] Video tracking & analytics

**Phase 3: AI Assistant (2 weeks)**
- [ ] GPT-4 integration
- [ ] Context-aware responses
- [ ] Proactive suggestions
- [ ] Handoff to human support

**Phase 4: Onboarding (1 week)**
- [ ] First login tour
- [ ] Feature tours (5 main features)
- [ ] Progress checklist
- [ ] Completion rewards

**Phase 5: Admin CMS (1 week)**
- [ ] Help content editor
- [ ] Video upload/management
- [ ] Analytics dashboard
- [ ] A/B testing framework

**Total: 7 weeks**

---

## 💰 Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| Algolia (search) | €50 |
| OpenAI GPT-4 (assistant) | €200-400 |
| Video hosting (Vimeo/Wistia) | €100 |
| Analytics (Mixpanel) | €50 |
| **Total** | **€400-600/month** |

**ROI:** Reduced support tickets (save €2k-5k/month in support time)

---

**Maintainer:** Product Team
**Last Updated:** 2025-10-04
