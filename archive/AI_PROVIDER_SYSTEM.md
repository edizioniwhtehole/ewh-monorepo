# EWH Platform - AI Provider & Credit System

> **Sistema multi-provider per AI con BYOK (Bring Your Own Key) e unified credit system**

**Versione:** 1.0.0
**Target:** Cost optimization, tenant flexibility, future-proof AI integration
**Ultima revisione:** 2025-10-04

---

## 🎯 Obiettivi

### 1. **Provider Flexibility**
- ✅ Support multiple AI providers (OpenAI, Anthropic, Google, etc.)
- ✅ Easy to add new providers as they emerge
- ✅ Model selection per task (GPT-4, GPT-5, Claude 3.5, Gemini, etc.)

### 2. **BYOK (Bring Your Own Key)**
- ✅ Tenants can use their own API keys
- ✅ **Zero credit deduction** when using BYOK (tenant's own key)
- ✅ Lower pricing tier for BYOK tenants (50% discount if still using credits)
- ✅ Zero AI costs for platform when tenant uses BYOK
- ✅ Full transaction logging and history regardless of BYOK usage

### 3. **Unified Credit System**
- ✅ Single metric: "Credits" (not tokens, not API calls)
- ✅ Credit wallet per tenant
- ✅ Transparent credit consumption tracking
- ✅ Prepaid packages + pay-as-you-go

### 4. **Future-Proof**
- ✅ Abstract AI providers (no vendor lock-in)
- ✅ Support emerging models (video generation, voice, etc.)
- ✅ Easy migration between providers

---

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  AI Provider System Architecture                            │
└─────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  1. AI Provider Abstraction Layer      │
│     • Unified interface                │
│     • Multi-provider support           │
│     • Model registry                   │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  2. BYOK (Bring Your Own Key)          │
│     • Tenant API key storage           │
│     • Encrypted vault                  │
│     • Validation & testing             │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  3. Credit System & Wallet             │
│     • Credit conversion                │
│     • Consumption tracking             │
│     • Prepaid packages                 │
└────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  4. Usage Analytics & Billing          │
│     • Real-time credit balance         │
│     • Usage reports                    │
│     • Alerts (low balance)             │
└────────────────────────────────────────┘
```

---

## 1. AI Provider Abstraction Layer

### Provider Registry

```typescript
// svc-ai-providers/src/registry.ts

export enum AIProvider {
  OPENAI = 'openai',
  ANTHROPIC = 'anthropic',
  GOOGLE = 'google',
  MISTRAL = 'mistral',
  COHERE = 'cohere',
  STABILITY = 'stability', // Image generation
  ELEVENLABS = 'elevenlabs', // Voice
  RUNWAYML = 'runwayml', // Video generation
}

export enum AICapability {
  TEXT_GENERATION = 'text_generation',
  TEXT_TRANSLATION = 'text_translation',
  IMAGE_GENERATION = 'image_generation',
  IMAGE_ANALYSIS = 'image_analysis',
  VIDEO_GENERATION = 'video_generation',
  VOICE_GENERATION = 'voice_generation',
  VOICE_TRANSCRIPTION = 'voice_transcription',
  EMBEDDINGS = 'embeddings',
}

export interface AIModel {
  id: string
  provider: AIProvider
  name: string
  displayName: string
  capabilities: AICapability[]
  inputCostPer1M: number // USD per 1M input tokens
  outputCostPer1M: number // USD per 1M output tokens
  contextWindow: number
  deprecated: boolean
  releaseDate: Date
  metadata: {
    maxOutputTokens?: number
    supportedLanguages?: string[]
    supportsVision?: boolean
    supportsTools?: boolean
  }
}

// Model Registry (auto-updated via API or manual)
export const AI_MODELS: AIModel[] = [
  // OpenAI Models
  {
    id: 'gpt-4o',
    provider: AIProvider.OPENAI,
    name: 'gpt-4o',
    displayName: 'GPT-4o (Latest)',
    capabilities: [
      AICapability.TEXT_GENERATION,
      AICapability.IMAGE_ANALYSIS,
    ],
    inputCostPer1M: 2.50,
    outputCostPer1M: 10.00,
    contextWindow: 128000,
    deprecated: false,
    releaseDate: new Date('2024-05-13'),
    metadata: {
      maxOutputTokens: 4096,
      supportsVision: true,
      supportsTools: true,
    }
  },
  {
    id: 'gpt-4-turbo',
    provider: AIProvider.OPENAI,
    name: 'gpt-4-turbo',
    displayName: 'GPT-4 Turbo',
    capabilities: [AICapability.TEXT_GENERATION],
    inputCostPer1M: 10.00,
    outputCostPer1M: 30.00,
    contextWindow: 128000,
    deprecated: false,
    releaseDate: new Date('2024-04-09'),
    metadata: {
      maxOutputTokens: 4096,
      supportsTools: true,
    }
  },
  {
    id: 'gpt-3.5-turbo',
    provider: AIProvider.OPENAI,
    name: 'gpt-3.5-turbo',
    displayName: 'GPT-3.5 Turbo',
    capabilities: [AICapability.TEXT_GENERATION],
    inputCostPer1M: 0.50,
    outputCostPer1M: 1.50,
    contextWindow: 16385,
    deprecated: false,
    releaseDate: new Date('2023-11-06'),
    metadata: {
      maxOutputTokens: 4096,
    }
  },

  // Anthropic Models
  {
    id: 'claude-3-5-sonnet',
    provider: AIProvider.ANTHROPIC,
    name: 'claude-3-5-sonnet-20241022',
    displayName: 'Claude 3.5 Sonnet',
    capabilities: [
      AICapability.TEXT_GENERATION,
      AICapability.IMAGE_ANALYSIS,
    ],
    inputCostPer1M: 3.00,
    outputCostPer1M: 15.00,
    contextWindow: 200000,
    deprecated: false,
    releaseDate: new Date('2024-10-22'),
    metadata: {
      maxOutputTokens: 8192,
      supportsVision: true,
    }
  },
  {
    id: 'claude-3-haiku',
    provider: AIProvider.ANTHROPIC,
    name: 'claude-3-haiku-20240307',
    displayName: 'Claude 3 Haiku (Fast)',
    capabilities: [AICapability.TEXT_GENERATION],
    inputCostPer1M: 0.25,
    outputCostPer1M: 1.25,
    contextWindow: 200000,
    deprecated: false,
    releaseDate: new Date('2024-03-07'),
    metadata: {
      maxOutputTokens: 4096,
    }
  },

  // Google Models
  {
    id: 'gemini-1.5-pro',
    provider: AIProvider.GOOGLE,
    name: 'gemini-1.5-pro',
    displayName: 'Gemini 1.5 Pro',
    capabilities: [
      AICapability.TEXT_GENERATION,
      AICapability.IMAGE_ANALYSIS,
    ],
    inputCostPer1M: 3.50,
    outputCostPer1M: 10.50,
    contextWindow: 1000000, // 1M tokens!
    deprecated: false,
    releaseDate: new Date('2024-02-15'),
    metadata: {
      maxOutputTokens: 8192,
      supportsVision: true,
    }
  },

  // Image Generation
  {
    id: 'dall-e-3',
    provider: AIProvider.OPENAI,
    name: 'dall-e-3',
    displayName: 'DALL-E 3',
    capabilities: [AICapability.IMAGE_GENERATION],
    inputCostPer1M: 0, // Priced per image
    outputCostPer1M: 0,
    contextWindow: 4000,
    deprecated: false,
    releaseDate: new Date('2023-10-01'),
    metadata: {
      // $0.040 per image (1024x1024 standard)
      // $0.080 per image (1024x1024 HD)
    }
  },
  {
    id: 'stable-diffusion-xl',
    provider: AIProvider.STABILITY,
    name: 'stable-diffusion-xl-1024-v1-0',
    displayName: 'Stable Diffusion XL',
    capabilities: [AICapability.IMAGE_GENERATION],
    inputCostPer1M: 0,
    outputCostPer1M: 0,
    contextWindow: 0,
    deprecated: false,
    releaseDate: new Date('2023-07-26'),
    metadata: {
      // $0.008 per image
    }
  },

  // Video Generation
  {
    id: 'runway-gen3',
    provider: AIProvider.RUNWAYML,
    name: 'gen-3-alpha-turbo',
    displayName: 'Runway Gen-3 Alpha Turbo',
    capabilities: [AICapability.VIDEO_GENERATION],
    inputCostPer1M: 0,
    outputCostPer1M: 0,
    contextWindow: 0,
    deprecated: false,
    releaseDate: new Date('2024-09-01'),
    metadata: {
      // $0.05 per second of video
    }
  },

  // Voice Generation
  {
    id: 'elevenlabs-multilingual-v2',
    provider: AIProvider.ELEVENLABS,
    name: 'eleven_multilingual_v2',
    displayName: 'ElevenLabs Multilingual v2',
    capabilities: [AICapability.VOICE_GENERATION],
    inputCostPer1M: 0,
    outputCostPer1M: 0,
    contextWindow: 0,
    deprecated: false,
    releaseDate: new Date('2024-03-01'),
    metadata: {
      supportedLanguages: ['en', 'it', 'es', 'fr', 'de', 'pt', 'pl', 'ja', 'zh', 'ar'],
      // $0.30 per 1000 characters
    }
  },
]
```

### Unified AI Client Interface

```typescript
// svc-ai-providers/src/client.ts

export interface AIRequest {
  model: string
  provider?: AIProvider // Auto-detected from model if not specified
  messages?: Array<{ role: string; content: string }>
  prompt?: string
  temperature?: number
  maxTokens?: number
  stream?: boolean
  // Provider-specific options
  options?: Record<string, any>
}

export interface AIResponse {
  id: string
  model: string
  provider: AIProvider
  content: string
  usage: {
    inputTokens: number
    outputTokens: number
    totalTokens: number
  }
  cost: {
    inputCost: number // USD
    outputCost: number // USD
    totalCost: number // USD
  }
  metadata: {
    finishReason: string
    latency: number // milliseconds
    cached: boolean
  }
}

export class UnifiedAIClient {
  private providers: Map<AIProvider, any> = new Map()

  constructor() {
    // Initialize providers
    this.providers.set(AIProvider.OPENAI, new OpenAIAdapter())
    this.providers.set(AIProvider.ANTHROPIC, new AnthropicAdapter())
    this.providers.set(AIProvider.GOOGLE, new GoogleAdapter())
    // ... other providers
  }

  async complete(request: AIRequest): Promise<AIResponse> {
    // 1. Resolve model & provider
    const model = this.getModel(request.model)
    const provider = this.getProvider(model.provider)

    // 2. Get API key (platform or tenant BYOK)
    const apiKey = await this.getApiKey(model.provider, request.tenantId)

    // 3. Call provider
    const startTime = Date.now()
    const response = await provider.complete({
      ...request,
      apiKey,
      model: model.name,
    })
    const latency = Date.now() - startTime

    // 4. Calculate cost
    const cost = this.calculateCost(model, response.usage)

    // 5. Track usage
    await this.trackUsage({
      tenantId: request.tenantId,
      model: request.model,
      provider: model.provider,
      usage: response.usage,
      cost,
    })

    return {
      ...response,
      model: request.model,
      provider: model.provider,
      cost,
      metadata: {
        ...response.metadata,
        latency,
      },
    }
  }

  private calculateCost(model: AIModel, usage: { inputTokens: number; outputTokens: number }) {
    const inputCost = (usage.inputTokens / 1_000_000) * model.inputCostPer1M
    const outputCost = (usage.outputTokens / 1_000_000) * model.outputCostPer1M

    return {
      inputCost,
      outputCost,
      totalCost: inputCost + outputCost,
    }
  }

  private async getApiKey(provider: AIProvider, tenantId: string): Promise<string> {
    // Check if tenant has BYOK
    const tenantKey = await this.getTenantApiKey(tenantId, provider)
    if (tenantKey) {
      return tenantKey
    }

    // Fall back to platform key
    return this.getPlatformApiKey(provider)
  }
}
```

### Provider Adapters

```typescript
// svc-ai-providers/src/adapters/openai.ts
import OpenAI from 'openai'

export class OpenAIAdapter {
  async complete(request: AdapterRequest): Promise<AdapterResponse> {
    const client = new OpenAI({ apiKey: request.apiKey })

    const completion = await client.chat.completions.create({
      model: request.model,
      messages: request.messages,
      temperature: request.temperature,
      max_tokens: request.maxTokens,
      stream: request.stream,
    })

    return {
      id: completion.id,
      content: completion.choices[0].message.content,
      usage: {
        inputTokens: completion.usage.prompt_tokens,
        outputTokens: completion.usage.completion_tokens,
        totalTokens: completion.usage.total_tokens,
      },
      metadata: {
        finishReason: completion.choices[0].finish_reason,
        cached: false,
      },
    }
  }
}

// svc-ai-providers/src/adapters/anthropic.ts
import Anthropic from '@anthropic-ai/sdk'

export class AnthropicAdapter {
  async complete(request: AdapterRequest): Promise<AdapterResponse> {
    const client = new Anthropic({ apiKey: request.apiKey })

    const message = await client.messages.create({
      model: request.model,
      max_tokens: request.maxTokens || 4096,
      messages: request.messages,
      temperature: request.temperature,
    })

    return {
      id: message.id,
      content: message.content[0].text,
      usage: {
        inputTokens: message.usage.input_tokens,
        outputTokens: message.usage.output_tokens,
        totalTokens: message.usage.input_tokens + message.usage.output_tokens,
      },
      metadata: {
        finishReason: message.stop_reason,
        cached: false,
      },
    }
  }
}

// ... Similar adapters for Google, Mistral, etc.
```

---

## 2. BYOK (Bring Your Own Key) System

### Database Schema

```sql
-- Tenant API keys (encrypted)
CREATE TABLE tenant_api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.organizations(id),
  provider VARCHAR(50) NOT NULL, -- 'openai', 'anthropic', etc.

  -- Encrypted API key
  encrypted_key TEXT NOT NULL,
  key_hash TEXT NOT NULL, -- For validation without decrypting

  -- Metadata
  key_name VARCHAR(100), -- User-friendly name: "Production OpenAI"
  is_active BOOLEAN DEFAULT true,
  last_validated_at TIMESTAMPTZ,
  validation_status VARCHAR(20), -- 'valid', 'invalid', 'pending'

  -- Limits (optional)
  monthly_spend_limit DECIMAL(10,2), -- USD
  daily_request_limit INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, provider, key_name)
);

-- Usage tracking per BYOK key
CREATE TABLE tenant_api_key_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key_id UUID NOT NULL REFERENCES tenant_api_keys(id),
  tenant_id UUID NOT NULL,

  -- Usage metrics
  date DATE NOT NULL,
  requests_count INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  estimated_cost DECIMAL(10,4) DEFAULT 0, -- USD

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(api_key_id, date)
);

-- Index for fast lookups
CREATE INDEX idx_tenant_api_keys_tenant ON tenant_api_keys(tenant_id, provider);
CREATE INDEX idx_tenant_api_key_usage_date ON tenant_api_key_usage(api_key_id, date);
```

### API Key Encryption (Vault)

```typescript
// svc-ai-providers/src/vault.ts
import crypto from 'crypto'

const ENCRYPTION_KEY = process.env.API_KEY_ENCRYPTION_SECRET // 32-byte key
const ALGORITHM = 'aes-256-gcm'

export class APIKeyVault {
  // Encrypt API key
  encrypt(plaintext: string): { encrypted: string; hash: string } {
    const iv = crypto.randomBytes(16)
    const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY, 'hex'), iv)

    let encrypted = cipher.update(plaintext, 'utf8', 'hex')
    encrypted += cipher.final('hex')

    const authTag = cipher.getAuthTag()

    // Store: iv:authTag:encrypted
    const encryptedData = `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`

    // Create hash for validation (without decrypting)
    const hash = crypto.createHash('sha256').update(plaintext).digest('hex')

    return {
      encrypted: encryptedData,
      hash,
    }
  }

  // Decrypt API key
  decrypt(encryptedData: string): string {
    const [ivHex, authTagHex, encrypted] = encryptedData.split(':')

    const iv = Buffer.from(ivHex, 'hex')
    const authTag = Buffer.from(authTagHex, 'hex')
    const decipher = crypto.createDecipheriv(ALGORITHM, Buffer.from(ENCRYPTION_KEY, 'hex'), iv)

    decipher.setAuthTag(authTag)

    let decrypted = decipher.update(encrypted, 'hex', 'utf8')
    decrypted += decipher.final('utf8')

    return decrypted
  }

  // Validate key without decrypting
  validateHash(plaintext: string, hash: string): boolean {
    const computedHash = crypto.createHash('sha256').update(plaintext).digest('hex')
    return computedHash === hash
  }
}
```

### BYOK Management API

```typescript
// svc-ai-providers/src/routes/byok.ts
import { FastifyInstance } from 'fastify'
import { z } from 'zod'

const AddApiKeySchema = z.object({
  provider: z.enum(['openai', 'anthropic', 'google', 'mistral']),
  api_key: z.string().min(10),
  key_name: z.string().optional(),
  monthly_spend_limit: z.number().optional(),
})

export async function byokRoutes(app: FastifyInstance) {
  // Add API key
  app.post('/api/v1/ai-providers/keys', async (req, rep) => {
    const { tenant_id } = req.authContext
    const data = AddApiKeySchema.parse(req.body)

    // 1. Validate API key with provider
    const isValid = await validateProviderKey(data.provider, data.api_key)
    if (!isValid) {
      return rep.code(400).send({
        error: 'Invalid API key',
        message: 'Could not authenticate with provider. Please check your API key.',
      })
    }

    // 2. Encrypt API key
    const vault = new APIKeyVault()
    const { encrypted, hash } = vault.encrypt(data.api_key)

    // 3. Save to database
    const result = await db.query(
      `INSERT INTO tenant_api_keys (
        tenant_id, provider, encrypted_key, key_hash, key_name,
        monthly_spend_limit, validation_status, last_validated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, 'valid', NOW())
      RETURNING id, tenant_id, provider, key_name, validation_status`,
      [tenant_id, data.provider, encrypted, hash, data.key_name || `${data.provider} API`, data.monthly_spend_limit]
    )

    return rep.code(201).send({
      message: 'API key added successfully',
      key: result.rows[0],
    })
  })

  // List tenant's API keys
  app.get('/api/v1/ai-providers/keys', async (req, rep) => {
    const { tenant_id } = req.authContext

    const result = await db.query(
      `SELECT
        id, provider, key_name, is_active,
        validation_status, last_validated_at,
        monthly_spend_limit, created_at
       FROM tenant_api_keys
       WHERE tenant_id = $1
       ORDER BY created_at DESC`,
      [tenant_id]
    )

    // Get usage for each key
    const keys = await Promise.all(
      result.rows.map(async (key) => {
        const usage = await getKeyUsage(key.id)
        return { ...key, usage }
      })
    )

    return { keys }
  })

  // Delete API key
  app.delete('/api/v1/ai-providers/keys/:id', async (req, rep) => {
    const { id } = req.params
    const { tenant_id } = req.authContext

    await db.query(
      `DELETE FROM tenant_api_keys
       WHERE id = $1 AND tenant_id = $2`,
      [id, tenant_id]
    )

    return rep.code(204).send()
  })

  // Test API key
  app.post('/api/v1/ai-providers/keys/:id/test', async (req, rep) => {
    const { id } = req.params
    const { tenant_id } = req.authContext

    // Get key
    const keyResult = await db.query(
      `SELECT encrypted_key, provider FROM tenant_api_keys
       WHERE id = $1 AND tenant_id = $2`,
      [id, tenant_id]
    )

    if (keyResult.rows.length === 0) {
      return rep.code(404).send({ error: 'API key not found' })
    }

    const { encrypted_key, provider } = keyResult.rows[0]

    // Decrypt
    const vault = new APIKeyVault()
    const apiKey = vault.decrypt(encrypted_key)

    // Test with provider
    const isValid = await validateProviderKey(provider, apiKey)

    // Update validation status
    await db.query(
      `UPDATE tenant_api_keys
       SET validation_status = $1, last_validated_at = NOW()
       WHERE id = $2`,
      [isValid ? 'valid' : 'invalid', id]
    )

    return {
      valid: isValid,
      provider,
      tested_at: new Date(),
    }
  })
}

// Validate API key with provider
async function validateProviderKey(provider: string, apiKey: string): Promise<boolean> {
  try {
    if (provider === 'openai') {
      const openai = new OpenAI({ apiKey })
      await openai.models.list()
      return true
    }

    if (provider === 'anthropic') {
      const anthropic = new Anthropic({ apiKey })
      await anthropic.messages.create({
        model: 'claude-3-haiku-20240307',
        max_tokens: 10,
        messages: [{ role: 'user', content: 'Hi' }],
      })
      return true
    }

    // ... other providers

    return false
  } catch (error) {
    console.error('API key validation failed:', error)
    return false
  }
}
```

### BYOK UI (Admin Settings)

```tsx
// app-admin-console/pages/settings/ai-providers.tsx
export default function AIProvidersSettings() {
  const [apiKeys, setApiKeys] = useState<TenantAPIKey[]>([])
  const [showAddModal, setShowAddModal] = useState(false)

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">AI Provider Settings</h1>
          <p className="text-gray-600">
            Use your own API keys to reduce costs. We'll use your keys instead of ours.
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="bg-blue-500 text-white px-4 py-2 rounded-lg"
        >
          + Add API Key
        </button>
      </div>

      {/* Pricing Comparison */}
      <div className="bg-blue-50 p-6 rounded-lg mb-6">
        <h3 className="font-semibold mb-3">💰 Save with BYOK</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-sm text-gray-600">Platform Credits</p>
            <p className="text-2xl font-bold">€0.10/credit</p>
            <p className="text-xs text-gray-500">Includes markup</p>
          </div>
          <div>
            <p className="text-sm text-gray-600">Your Own API Key</p>
            <p className="text-2xl font-bold text-green-600">€0.05/credit</p>
            <p className="text-xs text-gray-500">Direct provider pricing + 50% discount</p>
          </div>
        </div>
      </div>

      {/* API Keys List */}
      <div className="space-y-4">
        {apiKeys.map(key => (
          <APIKeyCard
            key={key.id}
            apiKey={key}
            onTest={() => testApiKey(key.id)}
            onDelete={() => deleteApiKey(key.id)}
          />
        ))}

        {apiKeys.length === 0 && (
          <div className="text-center py-12 border-2 border-dashed rounded-lg">
            <p className="text-gray-500 mb-4">No API keys configured</p>
            <button
              onClick={() => setShowAddModal(true)}
              className="text-blue-600 hover:underline"
            >
              Add your first API key
            </button>
          </div>
        )}
      </div>

      {/* Add API Key Modal */}
      {showAddModal && (
        <AddAPIKeyModal
          onClose={() => setShowAddModal(false)}
          onSuccess={(key) => {
            setApiKeys([...apiKeys, key])
            setShowAddModal(false)
          }}
        />
      )}
    </div>
  )
}

function APIKeyCard({ apiKey, onTest, onDelete }: APIKeyCardProps) {
  return (
    <div className="border rounded-lg p-4">
      <div className="flex justify-between items-start mb-3">
        <div>
          <h3 className="font-semibold">{apiKey.key_name}</h3>
          <p className="text-sm text-gray-600">
            {PROVIDER_NAMES[apiKey.provider]}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <span
            className={`px-2 py-1 rounded text-xs ${
              apiKey.validation_status === 'valid'
                ? 'bg-green-100 text-green-800'
                : 'bg-red-100 text-red-800'
            }`}
          >
            {apiKey.validation_status === 'valid' ? '✓ Valid' : '✗ Invalid'}
          </span>

          <button
            onClick={onTest}
            className="text-xs text-blue-600 hover:underline"
          >
            Test
          </button>

          <button
            onClick={onDelete}
            className="text-xs text-red-600 hover:underline"
          >
            Delete
          </button>
        </div>
      </div>

      {/* Usage Stats */}
      <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t">
        <div>
          <p className="text-xs text-gray-500">This Month</p>
          <p className="text-lg font-semibold">
            {apiKey.usage.requests_count} requests
          </p>
        </div>
        <div>
          <p className="text-xs text-gray-500">Tokens</p>
          <p className="text-lg font-semibold">
            {formatNumber(apiKey.usage.total_tokens)}
          </p>
        </div>
        <div>
          <p className="text-xs text-gray-500">Est. Cost</p>
          <p className="text-lg font-semibold">
            ${apiKey.usage.estimated_cost.toFixed(2)}
          </p>
        </div>
      </div>

      {/* Spend Limit */}
      {apiKey.monthly_spend_limit && (
        <div className="mt-4">
          <div className="flex justify-between text-xs text-gray-600 mb-1">
            <span>Monthly Spend Limit</span>
            <span>
              ${apiKey.usage.estimated_cost.toFixed(2)} / ${apiKey.monthly_spend_limit}
            </span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-500 h-2 rounded-full"
              style={{
                width: `${Math.min(
                  (apiKey.usage.estimated_cost / apiKey.monthly_spend_limit) * 100,
                  100
                )}%`,
              }}
            />
          </div>
        </div>
      )}
    </div>
  )
}
```

---

## 3. Unified Credit System

### Credit Conversion Table

```typescript
// Credit Conversion: 1 Credit = $0.01 USD equivalent

export interface CreditConversion {
  provider: AIProvider
  model: string
  // How many credits per 1M tokens
  inputCreditsPerMToken: number
  outputCreditsPerMToken: number
}

// Conversion based on provider costs
export const CREDIT_CONVERSIONS: CreditConversion[] = [
  // OpenAI GPT-4o: $2.50/$10.00 per 1M tokens
  {
    provider: AIProvider.OPENAI,
    model: 'gpt-4o',
    inputCreditsPerMToken: 250, // $2.50 / $0.01 = 250 credits
    outputCreditsPerMToken: 1000, // $10.00 / $0.01 = 1000 credits
  },

  // OpenAI GPT-4 Turbo: $10/$30 per 1M tokens
  {
    provider: AIProvider.OPENAI,
    model: 'gpt-4-turbo',
    inputCreditsPerMToken: 1000,
    outputCreditsPerMToken: 3000,
  },

  // OpenAI GPT-3.5 Turbo: $0.50/$1.50 per 1M tokens
  {
    provider: AIProvider.OPENAI,
    model: 'gpt-3.5-turbo',
    inputCreditsPerMToken: 50,
    outputCreditsPerMToken: 150,
  },

  // Claude 3.5 Sonnet: $3.00/$15.00 per 1M tokens
  {
    provider: AIProvider.ANTHROPIC,
    model: 'claude-3-5-sonnet',
    inputCreditsPerMToken: 300,
    outputCreditsPerMToken: 1500,
  },

  // Claude 3 Haiku: $0.25/$1.25 per 1M tokens
  {
    provider: AIProvider.ANTHROPIC,
    model: 'claude-3-haiku',
    inputCreditsPerMToken: 25,
    outputCreditsPerMToken: 125,
  },

  // Image Generation (DALL-E 3): $0.040 per image
  {
    provider: AIProvider.OPENAI,
    model: 'dall-e-3',
    inputCreditsPerMToken: 4, // 4 credits per image (standard)
    outputCreditsPerMToken: 0,
  },

  // Video Generation (Runway): $0.05 per second
  {
    provider: AIProvider.RUNWAYML,
    model: 'runway-gen3',
    inputCreditsPerMToken: 5, // 5 credits per second of video
    outputCreditsPerMToken: 0,
  },
]

// Calculate credits for a request
export function calculateCredits(
  model: string,
  usage: { inputTokens: number; outputTokens: number }
): number {
  const conversion = CREDIT_CONVERSIONS.find(c => c.model === model)

  if (!conversion) {
    throw new Error(`No credit conversion for model: ${model}`)
  }

  const inputCredits = (usage.inputTokens / 1_000_000) * conversion.inputCreditsPerMToken
  const outputCredits = (usage.outputTokens / 1_000_000) * conversion.outputCreditsPerMToken

  return Math.ceil(inputCredits + outputCredits) // Round up to nearest credit
}
```

### Credit Wallet Schema

```sql
-- Credit wallet per tenant
CREATE TABLE credit_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL UNIQUE REFERENCES auth.organizations(id),

  -- Balance
  balance INTEGER DEFAULT 0, -- Credits (1 credit = $0.01)
  reserved INTEGER DEFAULT 0, -- Credits reserved for ongoing operations

  -- Limits
  low_balance_threshold INTEGER DEFAULT 1000, -- Alert when below
  auto_recharge_enabled BOOLEAN DEFAULT false,
  auto_recharge_amount INTEGER DEFAULT 10000, -- 10,000 credits = $100
  auto_recharge_threshold INTEGER DEFAULT 500,

  -- Stats
  total_earned INTEGER DEFAULT 0,
  total_spent INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credit transactions (ledger)
CREATE TABLE credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES credit_wallets(id),
  tenant_id UUID NOT NULL,

  -- Transaction details
  type VARCHAR(20) NOT NULL, -- 'purchase', 'usage', 'refund', 'bonus'
  amount INTEGER NOT NULL, -- Positive for credit, negative for debit
  balance_before INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,

  -- Related to
  ai_request_id UUID, -- If usage
  invoice_id UUID, -- If purchase

  -- Metadata
  description TEXT,
  metadata JSONB, -- { model, provider, tokens, used_byok, etc. }

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for tenant transaction history and logs
CREATE INDEX idx_credit_transactions_tenant ON credit_transactions(tenant_id, created_at DESC);

-- AI requests (for tracking)
CREATE TABLE ai_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  -- Request details
  provider VARCHAR(50) NOT NULL,
  model VARCHAR(100) NOT NULL,
  capability VARCHAR(50) NOT NULL, -- 'text_generation', 'image_generation', etc.

  -- Usage
  input_tokens INTEGER,
  output_tokens INTEGER,
  total_tokens INTEGER,

  -- Cost
  cost_usd DECIMAL(10,6), -- Actual provider cost
  credits_charged INTEGER, -- Credits deducted
  used_byok BOOLEAN DEFAULT false, -- Used tenant's own API key

  -- Metadata
  latency_ms INTEGER,
  status VARCHAR(20), -- 'success', 'error', 'timeout'
  error_message TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Additional indexes for queries
CREATE INDEX idx_credit_transactions_wallet ON credit_transactions(wallet_id, created_at DESC);
CREATE INDEX idx_ai_requests_tenant ON ai_requests(tenant_id, created_at DESC);
CREATE INDEX idx_ai_requests_model ON ai_requests(model, created_at);
CREATE INDEX idx_ai_requests_byok ON ai_requests(tenant_id, used_byok, created_at);
```

### Credit Wallet Service

```typescript
// svc-billing/src/services/credit-wallet.ts

export class CreditWalletService {
  // Get wallet balance
  async getBalance(tenantId: string): Promise<number> {
    const result = await db.query(
      'SELECT balance FROM credit_wallets WHERE tenant_id = $1',
      [tenantId]
    )

    if (result.rows.length === 0) {
      // Create wallet if doesn't exist
      await this.createWallet(tenantId)
      return 0
    }

    return result.rows[0].balance
  }

  // Deduct credits (for AI usage) - ONLY if not using BYOK
  async deduct(
    tenantId: string,
    credits: number,
    metadata: {
      model: string
      provider: string
      usage: { inputTokens: number; outputTokens: number }
      aiRequestId: string
      usedBYOK: boolean // NEW: flag to skip deduction if tenant used own API key
    }
  ): Promise<{ success: boolean; newBalance: number }> {
    // Skip credit deduction if tenant used their own API key
    if (metadata.usedBYOK) {
      return {
        success: true,
        newBalance: await this.getBalance(tenantId), // Balance unchanged
      }
    }
    // Start transaction
    const client = await db.pool.connect()

    try {
      await client.query('BEGIN')

      // Lock wallet row
      const wallet = await client.query(
        `SELECT balance FROM credit_wallets
         WHERE tenant_id = $1
         FOR UPDATE`,
        [tenantId]
      )

      const currentBalance = wallet.rows[0].balance

      // Check if sufficient balance
      if (currentBalance < credits) {
        await client.query('ROLLBACK')

        // Send low balance alert
        await this.sendLowBalanceAlert(tenantId, currentBalance)

        return {
          success: false,
          newBalance: currentBalance,
        }
      }

      // Deduct credits
      const newBalance = currentBalance - credits

      await client.query(
        `UPDATE credit_wallets
         SET balance = $1,
             total_spent = total_spent + $2,
             updated_at = NOW()
         WHERE tenant_id = $3`,
        [newBalance, credits, tenantId]
      )

      // Record transaction
      await client.query(
        `INSERT INTO credit_transactions (
          wallet_id, tenant_id, type, amount,
          balance_before, balance_after,
          ai_request_id, description, metadata
        ) VALUES (
          (SELECT id FROM credit_wallets WHERE tenant_id = $1),
          $1, 'usage', $2, $3, $4, $5, $6, $7
        )`,
        [
          tenantId,
          -credits, // Negative for debit
          currentBalance,
          newBalance,
          metadata.aiRequestId,
          `AI request: ${metadata.model}`,
          JSON.stringify(metadata),
        ]
      )

      await client.query('COMMIT')

      // Check if auto-recharge needed
      await this.checkAutoRecharge(tenantId, newBalance)

      return {
        success: true,
        newBalance,
      }
    } catch (error) {
      await client.query('ROLLBACK')
      throw error
    } finally {
      client.release()
    }
  }

  // Add credits (purchase/bonus)
  async addCredits(
    tenantId: string,
    credits: number,
    type: 'purchase' | 'bonus' | 'refund',
    metadata?: any
  ): Promise<{ newBalance: number }> {
    const client = await db.pool.connect()

    try {
      await client.query('BEGIN')

      // Lock wallet
      const wallet = await client.query(
        `SELECT balance FROM credit_wallets
         WHERE tenant_id = $1
         FOR UPDATE`,
        [tenantId]
      )

      const currentBalance = wallet.rows[0].balance
      const newBalance = currentBalance + credits

      // Update wallet
      await client.query(
        `UPDATE credit_wallets
         SET balance = $1,
             total_earned = total_earned + $2,
             updated_at = NOW()
         WHERE tenant_id = $3`,
        [newBalance, credits, tenantId]
      )

      // Record transaction
      await client.query(
        `INSERT INTO credit_transactions (
          wallet_id, tenant_id, type, amount,
          balance_before, balance_after,
          description, metadata
        ) VALUES (
          (SELECT id FROM credit_wallets WHERE tenant_id = $1),
          $1, $2, $3, $4, $5, $6, $7
        )`,
        [
          tenantId,
          type,
          credits,
          currentBalance,
          newBalance,
          `Credit ${type}: ${credits} credits`,
          JSON.stringify(metadata),
        ]
      )

      await client.query('COMMIT')

      return { newBalance }
    } catch (error) {
      await client.query('ROLLBACK')
      throw error
    } finally {
      client.release()
    }
  }

  // Check auto-recharge
  private async checkAutoRecharge(tenantId: string, currentBalance: number) {
    const wallet = await db.query(
      `SELECT auto_recharge_enabled, auto_recharge_threshold, auto_recharge_amount
       FROM credit_wallets
       WHERE tenant_id = $1`,
      [tenantId]
    )

    const { auto_recharge_enabled, auto_recharge_threshold, auto_recharge_amount } = wallet.rows[0]

    if (auto_recharge_enabled && currentBalance <= auto_recharge_threshold) {
      // Trigger auto-recharge
      await this.triggerAutoRecharge(tenantId, auto_recharge_amount)
    }
  }

  private async triggerAutoRecharge(tenantId: string, amount: number) {
    // Create Stripe payment intent or use saved payment method
    console.log(`Auto-recharging ${amount} credits for tenant ${tenantId}`)

    // Implementation: Create invoice, charge card, add credits
    // ... (Stripe integration)
  }

  // Get transaction history (with filters)
  async getTransactions(
    tenantId: string,
    options?: {
      type?: 'purchase' | 'usage' | 'refund' | 'bonus'
      from?: Date
      to?: Date
      limit?: number
      offset?: number
    }
  ): Promise<CreditTransaction[]> {
    let query = `
      SELECT
        ct.*,
        ar.model,
        ar.provider,
        ar.input_tokens,
        ar.output_tokens,
        ar.used_byok
      FROM credit_transactions ct
      LEFT JOIN ai_requests ar ON ct.ai_request_id = ar.id
      WHERE ct.tenant_id = $1
    `

    const params: any[] = [tenantId]
    let paramIndex = 2

    // Filter by type
    if (options?.type) {
      query += ` AND ct.type = $${paramIndex}`
      params.push(options.type)
      paramIndex++
    }

    // Filter by date range
    if (options?.from) {
      query += ` AND ct.created_at >= $${paramIndex}`
      params.push(options.from)
      paramIndex++
    }

    if (options?.to) {
      query += ` AND ct.created_at <= $${paramIndex}`
      params.push(options.to)
      paramIndex++
    }

    // Order and pagination
    query += ` ORDER BY ct.created_at DESC`

    if (options?.limit) {
      query += ` LIMIT $${paramIndex}`
      params.push(options.limit)
      paramIndex++
    }

    if (options?.offset) {
      query += ` OFFSET $${paramIndex}`
      params.push(options.offset)
      paramIndex++
    }

    const result = await db.query(query, params)

    // Enrich metadata with AI request details
    return result.rows.map(row => ({
      id: row.id,
      wallet_id: row.wallet_id,
      tenant_id: row.tenant_id,
      type: row.type,
      amount: row.amount,
      balance_before: row.balance_before,
      balance_after: row.balance_after,
      ai_request_id: row.ai_request_id,
      invoice_id: row.invoice_id,
      description: row.description,
      metadata: {
        ...JSON.parse(row.metadata || '{}'),
        // Add joined data from ai_requests
        model: row.model,
        provider: row.provider,
        usage: {
          inputTokens: row.input_tokens,
          outputTokens: row.output_tokens,
        },
        used_byok: row.used_byok,
      },
      created_at: row.created_at,
    }))
  }
}
```

### Transaction History API

```typescript
// svc-billing/src/routes/transactions.ts
import { FastifyInstance } from 'fastify'
import { z } from 'zod'

export async function transactionRoutes(app: FastifyInstance) {
  // GET /api/v1/credits/transactions - Get transaction history
  app.get('/api/v1/credits/transactions', async (req, rep) => {
    const { tenant_id } = req.authContext

    // Parse query params
    const schema = z.object({
      type: z.enum(['purchase', 'usage', 'refund', 'bonus']).optional(),
      from: z.string().datetime().optional(),
      to: z.string().datetime().optional(),
      limit: z.coerce.number().min(1).max(100).default(50),
      offset: z.coerce.number().min(0).default(0),
    })

    const query = schema.parse(req.query)

    // Fetch transactions
    const walletService = new CreditWalletService()
    const transactions = await walletService.getTransactions(tenant_id, {
      type: query.type,
      from: query.from ? new Date(query.from) : undefined,
      to: query.to ? new Date(query.to) : undefined,
      limit: query.limit,
      offset: query.offset,
    })

    // Get total count (for pagination)
    const totalResult = await db.query(
      `SELECT COUNT(*) as total
       FROM credit_transactions
       WHERE tenant_id = $1
       ${query.type ? `AND type = '${query.type}'` : ''}
       ${query.from ? `AND created_at >= '${query.from}'` : ''}
       ${query.to ? `AND created_at <= '${query.to}'` : ''}`,
      [tenant_id]
    )

    return {
      transactions,
      pagination: {
        total: parseInt(totalResult.rows[0].total),
        limit: query.limit,
        offset: query.offset,
        hasMore: transactions.length === query.limit,
      },
    }
  })

  // GET /api/v1/credits/transactions/export - Export to CSV
  app.get('/api/v1/credits/transactions/export', async (req, rep) => {
    const { tenant_id } = req.authContext

    const schema = z.object({
      type: z.enum(['purchase', 'usage', 'refund', 'bonus']).optional(),
      from: z.string().datetime().optional(),
      to: z.string().datetime().optional(),
    })

    const query = schema.parse(req.query)

    // Fetch ALL transactions (no limit)
    const walletService = new CreditWalletService()
    const transactions = await walletService.getTransactions(tenant_id, {
      type: query.type,
      from: query.from ? new Date(query.from) : undefined,
      to: query.to ? new Date(query.to) : undefined,
    })

    // Generate CSV
    const csv = generateCSV(transactions)

    // Set headers for file download
    rep.header('Content-Type', 'text/csv')
    rep.header('Content-Disposition', `attachment; filename="transactions_${Date.now()}.csv"`)

    return csv
  })
}

function generateCSV(transactions: CreditTransaction[]): string {
  const headers = [
    'Date',
    'Type',
    'Description',
    'Amount',
    'Balance After',
    'Model',
    'Provider',
    'Input Tokens',
    'Output Tokens',
    'Used BYOK',
    'Request ID',
  ]

  const rows = transactions.map(tx => [
    new Date(tx.created_at).toISOString(),
    tx.type,
    tx.description,
    tx.amount,
    tx.balance_after,
    tx.metadata?.model || '',
    tx.metadata?.provider || '',
    tx.metadata?.usage?.inputTokens || '',
    tx.metadata?.usage?.outputTokens || '',
    tx.metadata?.used_byok ? 'Yes' : 'No',
    tx.ai_request_id || '',
  ])

  return [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(',')),
  ].join('\n')
}
```

### Credit Usage Tracking

```typescript
// Middleware: Track AI usage and deduct credits
export async function trackAIUsage(
  tenantId: string,
  request: AIRequest,
  response: AIResponse
) {
  // 1. Calculate credits
  const credits = calculateCredits(response.model, response.usage)

  // 2. Check if tenant used BYOK (their own API key)
  const usedBYOK = await hasBYOK(tenantId, response.provider)

  // 3. Deduct credits ONLY if NOT using BYOK
  // If tenant uses their own API key, credits are NOT deducted
  const result = await creditWallet.deduct(tenantId, credits, {
    model: response.model,
    provider: response.provider,
    usage: response.usage,
    aiRequestId: response.id,
    usedBYOK, // Pass BYOK flag - if true, no deduction happens
  })

  const deductionSuccess = result.success

  // 4. Log AI request
  await db.query(
    `INSERT INTO ai_requests (
      id, tenant_id, user_id, provider, model, capability,
      input_tokens, output_tokens, total_tokens,
      cost_usd, credits_charged, used_byok,
      latency_ms, status
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
    [
      response.id,
      tenantId,
      request.userId,
      response.provider,
      response.model,
      request.capability || 'text_generation',
      response.usage.inputTokens,
      response.usage.outputTokens,
      response.usage.totalTokens,
      response.cost.totalCost,
      usedBYOK ? 0 : credits,
      usedBYOK,
      response.metadata.latency,
      deductionSuccess ? 'success' : 'insufficient_credits',
    ]
  )

  return { credits, deductionSuccess }
}
```

---

## 4. Credit Packages & Pricing

### Prepaid Packages

```typescript
export const CREDIT_PACKAGES = [
  {
    id: 'starter',
    name: 'Starter Pack',
    credits: 1000, // 1,000 credits
    price: 10, // €10
    pricePerCredit: 0.01, // €0.01 per credit
    bonus: 0,
  },
  {
    id: 'professional',
    name: 'Professional Pack',
    credits: 5000,
    price: 45, // €45 (10% discount)
    pricePerCredit: 0.009,
    bonus: 500, // +10% bonus credits
  },
  {
    id: 'business',
    name: 'Business Pack',
    credits: 25000,
    price: 200, // €200 (20% discount)
    pricePerCredit: 0.008,
    bonus: 5000, // +20% bonus credits
  },
  {
    id: 'enterprise',
    name: 'Enterprise Pack',
    credits: 100000,
    price: 700, // €700 (30% discount)
    pricePerCredit: 0.007,
    bonus: 30000, // +30% bonus credits
  },
]

// BYOK Pricing (50% discount)
export const BYOK_CREDIT_PRICING = {
  pricePerCredit: 0.005, // €0.005 (50% off)
  description: 'Bring Your Own Key discount - you provide API keys, we provide the platform',
}
```

### Purchase Credits UI

```tsx
// app-web-frontend/pages/settings/credits.tsx
export default function CreditsPage() {
  const wallet = useWallet()
  const transactions = useTransactions()

  return (
    <div className="p-8">
      {/* Balance Card */}
      <div className="bg-gradient-to-r from-blue-500 to-purple-600 text-white p-8 rounded-lg mb-8">
        <h2 className="text-xl mb-2">Credit Balance</h2>
        <div className="flex items-baseline gap-2">
          <span className="text-5xl font-bold">
            {wallet.balance.toLocaleString()}
          </span>
          <span className="text-xl opacity-80">credits</span>
        </div>

        <p className="mt-4 opacity-90">
          ≈ €{(wallet.balance * 0.01).toFixed(2)} worth of AI operations
        </p>

        {wallet.balance < wallet.low_balance_threshold && (
          <div className="mt-4 bg-yellow-500/20 border border-yellow-300 rounded p-3">
            ⚠️ Low balance! Consider purchasing more credits or enabling auto-recharge.
          </div>
        )}
      </div>

      {/* Credit Packages */}
      <h3 className="text-xl font-semibold mb-4">Purchase Credits</h3>
      <div className="grid grid-cols-4 gap-4 mb-8">
        {CREDIT_PACKAGES.map(pkg => (
          <CreditPackageCard
            key={pkg.id}
            package={pkg}
            onPurchase={() => purchasePackage(pkg.id)}
          />
        ))}
      </div>

      {/* BYOK Option */}
      <div className="bg-green-50 border border-green-200 rounded-lg p-6 mb-8">
        <h3 className="text-lg font-semibold mb-2">
          💡 Save 50% with BYOK (Bring Your Own Key)
        </h3>
        <p className="text-gray-700 mb-4">
          Use your own OpenAI, Anthropic, or Google API keys and pay only €0.005 per credit
          (50% discount). No markup, just platform fees.
        </p>
        <Link
          href="/settings/ai-providers"
          className="bg-green-600 text-white px-4 py-2 rounded-lg inline-block"
        >
          Configure BYOK →
        </Link>
      </div>

      {/* Auto-Recharge */}
      <div className="border rounded-lg p-6 mb-8">
        <h3 className="text-lg font-semibold mb-4">Auto-Recharge Settings</h3>

        <label className="flex items-center gap-3 mb-4">
          <input
            type="checkbox"
            checked={wallet.auto_recharge_enabled}
            onChange={(e) => updateAutoRecharge({ enabled: e.target.checked })}
          />
          <span>Enable auto-recharge when balance is low</span>
        </label>

        {wallet.auto_recharge_enabled && (
          <div className="space-y-3">
            <div>
              <label className="block text-sm mb-1">Recharge when balance falls below:</label>
              <input
                type="number"
                value={wallet.auto_recharge_threshold}
                onChange={(e) => updateAutoRecharge({ threshold: parseInt(e.target.value) })}
                className="border rounded px-3 py-2 w-32"
              />
              <span className="ml-2 text-gray-600">credits</span>
            </div>

            <div>
              <label className="block text-sm mb-1">Recharge amount:</label>
              <select
                value={wallet.auto_recharge_amount}
                onChange={(e) => updateAutoRecharge({ amount: parseInt(e.target.value) })}
                className="border rounded px-3 py-2"
              >
                <option value="1000">1,000 credits (€10)</option>
                <option value="5000">5,000 credits (€45)</option>
                <option value="10000">10,000 credits (€90)</option>
              </select>
            </div>
          </div>
        )}
      </div>

      {/* Transaction History */}
      <h3 className="text-xl font-semibold mb-4">Transaction History</h3>
      <TransactionHistory tenantId={wallet.tenant_id} />
    </div>
  )
}

function TransactionHistory({ tenantId }: { tenantId: string }) {
  const [transactions, setTransactions] = useState<CreditTransaction[]>([])
  const [filter, setFilter] = useState<'all' | 'purchase' | 'usage' | 'refund' | 'bonus'>('all')
  const [dateRange, setDateRange] = useState<{ from: Date; to: Date }>({
    from: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
    to: new Date(),
  })

  // Fetch transactions
  useEffect(() => {
    fetchTransactions()
  }, [filter, dateRange])

  const fetchTransactions = async () => {
    const response = await fetch(
      `/api/v1/credits/transactions?` +
      `tenant_id=${tenantId}&` +
      `type=${filter !== 'all' ? filter : ''}&` +
      `from=${dateRange.from.toISOString()}&` +
      `to=${dateRange.to.toISOString()}`
    )
    const data = await response.json()
    setTransactions(data.transactions)
  }

  return (
    <div>
      {/* Filters */}
      <div className="flex gap-4 mb-4">
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value as any)}
          className="border rounded px-3 py-2"
        >
          <option value="all">All Transactions</option>
          <option value="purchase">Purchases</option>
          <option value="usage">Usage (AI Calls)</option>
          <option value="refund">Refunds</option>
          <option value="bonus">Bonuses</option>
        </select>

        <DateRangePicker
          from={dateRange.from}
          to={dateRange.to}
          onChange={setDateRange}
        />

        <button
          onClick={() => exportTransactions(transactions)}
          className="border px-4 py-2 rounded hover:bg-gray-50"
        >
          📥 Export CSV
        </button>
      </div>

      {/* Transaction Table */}
      <div className="border rounded-lg overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-semibold">Date</th>
              <th className="px-4 py-3 text-left text-xs font-semibold">Type</th>
              <th className="px-4 py-3 text-left text-xs font-semibold">Description</th>
              <th className="px-4 py-3 text-right text-xs font-semibold">Amount</th>
              <th className="px-4 py-3 text-right text-xs font-semibold">Balance</th>
              <th className="px-4 py-3 text-center text-xs font-semibold">Details</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {transactions.map((tx) => (
              <TransactionRow key={tx.id} transaction={tx} />
            ))}
          </tbody>
        </table>

        {transactions.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            No transactions found for the selected filters
          </div>
        )}
      </div>

      {/* Pagination */}
      {transactions.length >= 50 && (
        <div className="flex justify-center gap-2 mt-4">
          <button className="border px-4 py-2 rounded">Previous</button>
          <button className="border px-4 py-2 rounded">Next</button>
        </div>
      )}
    </div>
  )
}

function TransactionRow({ transaction: tx }: { transaction: CreditTransaction }) {
  const [showDetails, setShowDetails] = useState(false)

  const typeColors = {
    purchase: 'bg-green-100 text-green-800',
    usage: 'bg-blue-100 text-blue-800',
    refund: 'bg-yellow-100 text-yellow-800',
    bonus: 'bg-purple-100 text-purple-800',
  }

  return (
    <>
      <tr className="hover:bg-gray-50">
        <td className="px-4 py-3 text-sm">
          {new Date(tx.created_at).toLocaleString('it-IT')}
        </td>
        <td className="px-4 py-3">
          <span className={`text-xs px-2 py-1 rounded ${typeColors[tx.type]}`}>
            {tx.type.toUpperCase()}
          </span>
        </td>
        <td className="px-4 py-3 text-sm">
          {tx.description}
          {tx.metadata?.used_byok && (
            <span className="ml-2 text-xs bg-green-100 text-green-700 px-1 py-0.5 rounded">
              BYOK
            </span>
          )}
        </td>
        <td className="px-4 py-3 text-sm text-right">
          <span className={tx.amount > 0 ? 'text-green-600 font-semibold' : 'text-red-600'}>
            {tx.amount > 0 ? '+' : ''}{tx.amount.toLocaleString()}
          </span>
        </td>
        <td className="px-4 py-3 text-sm text-right text-gray-600">
          {tx.balance_after.toLocaleString()}
        </td>
        <td className="px-4 py-3 text-center">
          {tx.metadata && (
            <button
              onClick={() => setShowDetails(!showDetails)}
              className="text-blue-600 text-xs hover:underline"
            >
              {showDetails ? 'Hide' : 'View'}
            </button>
          )}
        </td>
      </tr>

      {/* Expandable Details Row */}
      {showDetails && tx.metadata && (
        <tr className="bg-gray-50">
          <td colSpan={6} className="px-4 py-4">
            <div className="text-sm space-y-1">
              <h4 className="font-semibold mb-2">Transaction Details</h4>

              {/* AI Request Details (for usage type) */}
              {tx.type === 'usage' && (
                <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                  <div>
                    <span className="text-gray-600">Model:</span>{' '}
                    <span className="font-mono">{tx.metadata.model}</span>
                  </div>
                  <div>
                    <span className="text-gray-600">Provider:</span>{' '}
                    {tx.metadata.provider}
                  </div>
                  <div>
                    <span className="text-gray-600">Input Tokens:</span>{' '}
                    {tx.metadata.usage?.inputTokens?.toLocaleString()}
                  </div>
                  <div>
                    <span className="text-gray-600">Output Tokens:</span>{' '}
                    {tx.metadata.usage?.outputTokens?.toLocaleString()}
                  </div>
                  <div>
                    <span className="text-gray-600">Used BYOK:</span>{' '}
                    {tx.metadata.used_byok ? (
                      <span className="text-green-600">✓ Yes (No charge)</span>
                    ) : (
                      <span className="text-blue-600">No (Credits deducted)</span>
                    )}
                  </div>
                  {tx.ai_request_id && (
                    <div>
                      <span className="text-gray-600">Request ID:</span>{' '}
                      <code className="text-xs bg-gray-200 px-1 rounded">
                        {tx.ai_request_id.slice(0, 8)}...
                      </code>
                    </div>
                  )}
                </div>
              )}

              {/* Purchase Details */}
              {tx.type === 'purchase' && tx.invoice_id && (
                <div>
                  <span className="text-gray-600">Invoice ID:</span>{' '}
                  <a
                    href={`/invoices/${tx.invoice_id}`}
                    className="text-blue-600 hover:underline"
                  >
                    {tx.invoice_id.slice(0, 8)}...
                  </a>
                </div>
              )}

              {/* Raw Metadata (collapsed JSON) */}
              <details className="mt-2">
                <summary className="text-xs text-gray-500 cursor-pointer hover:text-gray-700">
                  View Raw JSON
                </summary>
                <pre className="mt-2 text-xs bg-white border rounded p-2 overflow-x-auto">
                  {JSON.stringify(tx.metadata, null, 2)}
                </pre>
              </details>
            </div>
          </td>
        </tr>
      )}
    </>
  )
}

function CreditPackageCard({ package: pkg, onPurchase }) {
  return (
    <div className="border rounded-lg p-6 hover:shadow-lg transition">
      <h4 className="font-semibold text-lg mb-2">{pkg.name}</h4>

      <div className="text-3xl font-bold mb-1">
        {pkg.credits.toLocaleString()}
        {pkg.bonus > 0 && (
          <span className="text-sm text-green-600 ml-2">
            +{pkg.bonus.toLocaleString()}
          </span>
        )}
      </div>
      <p className="text-sm text-gray-600 mb-4">credits</p>

      <div className="text-2xl font-bold text-blue-600 mb-1">
        €{pkg.price}
      </div>
      <p className="text-xs text-gray-500 mb-4">
        €{pkg.pricePerCredit.toFixed(3)} per credit
      </p>

      {pkg.bonus > 0 && (
        <div className="bg-green-100 text-green-800 text-xs px-2 py-1 rounded mb-4">
          +{Math.round((pkg.bonus / pkg.credits) * 100)}% bonus credits
        </div>
      )}

      <button
        onClick={onPurchase}
        className="w-full bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600"
      >
        Purchase
      </button>
    </div>
  )
}
```

---

## 💡 BYOK Credit Policy

### Come Funziona il Sistema Crediti con BYOK

**Regola Fondamentale:**
- **Se tenant usa propria API key (BYOK)** → **ZERO crediti scalati**
- **Se tenant usa API key della piattaforma** → **Crediti scalati normalmente**

### Esempio 1: Tenant con BYOK

```typescript
// Tenant ha configurato OpenAI API key propria
const tenant = {
  id: 'acme-corp',
  credit_balance: 10000, // 10k crediti
  byok_keys: {
    openai: 'sk-proj-...' // Propria API key
  }
}

// Chiamata AI
const response = await aiClient.complete({
  tenantId: 'acme-corp',
  model: 'gpt-4o',
  messages: [...]
})

// Risultato:
// ✅ Richiesta completata con successo
// ✅ Usata API key del tenant (BYOK)
// ✅ ZERO crediti scalati (balance: 10000 → 10000)
// ✅ Log salvato in ai_requests con used_byok=true
// ✅ NESSUNA transazione creata in credit_transactions
```

### Esempio 2: Tenant senza BYOK

```typescript
// Tenant NON ha configurato API key propria
const tenant = {
  id: 'startup-inc',
  credit_balance: 10000, // 10k crediti
  byok_keys: {} // Nessuna BYOK
}

// Chiamata AI
const response = await aiClient.complete({
  tenantId: 'startup-inc',
  model: 'gpt-4o',
  messages: [...]
})

// Risultato (es. 1000 input tokens, 500 output tokens):
// ✅ Richiesta completata con API key della piattaforma
// ✅ Costo: 250 input + 500 output = 750 crediti
// ❌ 750 crediti scalati (balance: 10000 → 9250)
// ✅ Log salvato in ai_requests con used_byok=false, credits_charged=750
// ✅ Transazione creata in credit_transactions (type='usage', amount=-750)
```

### Logging e Trasparenza

**IMPORTANTE:** Tutte le richieste AI sono sempre loggate in `ai_requests`, sia con BYOK che senza.

Differenza:
- **Con BYOK**: `used_byok=true`, `credits_charged=0`
- **Senza BYOK**: `used_byok=false`, `credits_charged=750`

Questo permette:
- ✅ Trasparenza totale sull'uso AI
- ✅ Analytics completi (usage by model, provider, feature)
- ✅ Audit trail completo
- ✅ Tenant può vedere quanto risparmia con BYOK

### Transaction History

**Con BYOK:**
```
┌────────────┬──────────┬───────────────────────┬────────┬────────┐
│ Date       │ Type     │ Description           │ Amount │ Balance│
├────────────┼──────────┼───────────────────────┼────────┼────────┤
│ 2025-10-04 │ USAGE    │ AI: gpt-4o [BYOK]     │    0   │ 10000  │
│ 2025-10-03 │ USAGE    │ AI: claude-3.5 [BYOK] │    0   │ 10000  │
└────────────┴──────────┴───────────────────────┴────────┴────────┘
```

**Senza BYOK:**
```
┌────────────┬──────────┬───────────────────────┬────────┬────────┐
│ Date       │ Type     │ Description           │ Amount │ Balance│
├────────────┼──────────┼───────────────────────┼────────┼────────┤
│ 2025-10-04 │ USAGE    │ AI: gpt-4o            │  -750  │  9250  │
│ 2025-10-03 │ USAGE    │ AI: claude-3.5        │  -300  │ 10000  │
└────────────┴──────────┴───────────────────────┴────────┴────────┘
```

### Vantaggi per Tenant

Con BYOK il tenant:
- **Risparmia 100%** sui costi AI (zero crediti scalati)
- Mantiene **piena visibilità** su tutte le chiamate AI
- Può **monitorare usage** tramite dashboard analytics
- Ottiene **report completi** con export CSV

---

## 5. Usage Analytics & Reporting

### Analytics Dashboard

```tsx
// app-web-frontend/pages/analytics/ai-usage.tsx
export default function AIUsageAnalytics() {
  const usage = useAIUsage()

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">AI Usage Analytics</h1>

      {/* Summary Cards */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <StatCard
          title="Credits Used (30d)"
          value={usage.creditsUsed.toLocaleString()}
          change="+12%"
        />
        <StatCard
          title="API Requests"
          value={usage.totalRequests.toLocaleString()}
          change="+8%"
        />
        <StatCard
          title="Avg. Cost per Request"
          value={`${usage.avgCreditsPerRequest} credits`}
        />
        <StatCard
          title="BYOK Savings"
          value={`€${usage.byokSavings.toFixed(2)}`}
          icon="💰"
        />
      </div>

      {/* Usage by Model */}
      <div className="mb-8">
        <h2 className="text-xl font-semibold mb-4">Usage by Model</h2>
        <BarChart
          data={usage.byModel}
          xKey="model"
          yKey="credits"
          labels={{ x: 'Model', y: 'Credits Used' }}
        />
      </div>

      {/* Usage by Feature */}
      <div className="mb-8">
        <h2 className="text-xl font-semibold mb-4">Usage by Feature</h2>
        <PieChart
          data={usage.byFeature}
          labelKey="feature"
          valueKey="credits"
        />
      </div>

      {/* Daily Trend */}
      <div className="mb-8">
        <h2 className="text-xl font-semibold mb-4">Daily Credit Usage (Last 30 Days)</h2>
        <LineChart
          data={usage.dailyTrend}
          xKey="date"
          yKey="credits"
        />
      </div>

      {/* Top Consumers */}
      <div>
        <h2 className="text-xl font-semibold mb-4">Top AI Consumers</h2>
        <Table
          columns={['User', 'Requests', 'Credits Used', 'Avg. per Request']}
          data={usage.topUsers}
        />
      </div>
    </div>
  )
}
```

---

## 📊 Implementation Summary

### New Services

1. **svc-ai-providers** (AI Provider Abstraction)
   - Unified AI client
   - Provider adapters (OpenAI, Anthropic, Google, etc.)
   - Model registry (auto-updating)
   - BYOK management
   - Usage tracking

2. **Enhanced svc-billing**
   - Credit wallet system
   - Transaction ledger
   - Package purchasing
   - Auto-recharge
   - Analytics

### Database Additions

- `tenant_api_keys` - BYOK encrypted keys
- `tenant_api_key_usage` - BYOK usage tracking
- `credit_wallets` - Credit balance per tenant
- `credit_transactions` - Transaction ledger (full history with filters)
- `ai_requests` - AI usage logs (always logged, with BYOK flag)

### Key Features

✅ **BYOK Zero-Cost Policy**: When tenant uses own API key, **zero credits deducted**
✅ **Full Transaction History**: Filterable log per tenant (type, date range, export CSV)
✅ **Complete Analytics**: Usage tracked regardless of BYOK, full visibility
✅ **Expandable Transaction Details**: Click to view model, tokens, BYOK status, request ID

### Timeline

| Phase | Duration | Deliverables |
|-------|----------|-------------|
| **Phase 1: Provider Abstraction** | 2 weeks | Unified AI client, adapters, model registry |
| **Phase 2: BYOK System** | 2 weeks | Encrypted storage, validation, admin UI |
| **Phase 3: Credit System** | 2 weeks | Wallet, transactions, deduction logic |
| **Phase 4: Billing Integration** | 1 week | Packages, Stripe, auto-recharge |
| **Phase 5: Analytics** | 1 week | Usage dashboard, reports |
| **TOTAL** | **8 weeks** | Full AI infrastructure |

### Cost Impact

**Current (without BYOK):**
- Platform pays all AI costs
- €500-1,000/month (100 tenants, moderate usage)

**With BYOK (50% adoption):**
- 50 tenants use BYOK (zero AI cost for us)
- 50 tenants use platform credits (with markup)
- €250-500/month AI costs
- **€3k-5k/month additional revenue** (credit sales)

**ROI:** Break-even in 2-3 months, then pure profit

---

**Maintainer:** Platform Team
**Effort:** 8 weeks
**Cost Savings:** 50-70% AI costs
**Revenue Potential:** €3k-5k/month
**Last Updated:** 2025-10-04

🚀 **Ready for implementation!**
