# 🤖 AI Provider Pricing Strategy - Reseller Model

**Version**: 1.0.0
**Last Updated**: 2025-10-11
**Status**: ✅ Complete Specification

---

## 🎯 Overview

Strategia di rivendita AI con margine di profitto, volume discount, e multiple provider.

**Business Model**:
```
OpenAI → BlogMaster (volume discount) → Tenant (markup) → End User
  $0.025/1K      Paghi $0.025           Vendi $0.035      (40% markup)
```

---

## 💰 Provider Pricing (Real 2025)

### OpenAI

| Model | List Price | Volume Discount | Your Cost | Your Price | Margin |
|-------|------------|-----------------|-----------|------------|--------|
| GPT-4 Turbo | $0.03/1K tokens | $0.025/1K | $0.025 | $0.035 | 40% |
| GPT-4o | $0.015/1K tokens | $0.012/1K | $0.012 | $0.018 | 50% |
| GPT-3.5 | $0.001/1K tokens | $0.0008/1K | $0.0008 | $0.0015 | 87% |
| DALL-E 3 | $0.04/image | $0.035/image | $0.035 | $0.055 | 57% |
| Whisper | $0.006/min | $0.005/min | $0.005 | $0.008 | 60% |

**Volume Tiers**:
- $0-10K/month: List price
- $10K-50K/month: 10% discount
- $50K-200K/month: 15% discount
- $200K+/month: 17% discount (negotiable)

---

### Anthropic (Claude)

| Model | List Price | Volume Discount | Your Cost | Your Price | Margin |
|-------|------------|-----------------|-----------|------------|--------|
| Claude 3 Opus | $0.015/1K tokens | $0.0125/1K | $0.0125 | $0.020 | 60% |
| Claude 3 Sonnet | $0.003/1K tokens | $0.0025/1K | $0.0025 | $0.004 | 60% |
| Claude 3 Haiku | $0.0003/1K tokens | $0.00025/1K | $0.00025 | $0.0005 | 100% |

**Volume Tiers**:
- $0-25K/month: List price
- $25K-100K/month: 12% discount
- $100K+/month: 17% discount

---

### Google (Gemini)

| Model | List Price | Volume Discount | Your Cost | Your Price | Margin |
|-------|------------|-----------------|-----------|------------|--------|
| Gemini 1.5 Pro | $0.007/1K tokens | $0.006/1K | $0.006 | $0.010 | 67% |
| Gemini 1.5 Flash | $0.0002/1K tokens | $0.00015/1K | $0.00015 | $0.0003 | 100% |

**Volume Tiers**:
- $0-50K/month: List price
- $50K+/month: 15% discount

---

### Stability AI (Images)

| Model | List Price | Volume Discount | Your Cost | Your Price | Margin |
|-------|------------|-----------------|-----------|------------|--------|
| SDXL 1.0 | $0.002/image | $0.0015/image | $0.0015 | $0.003 | 100% |
| SD 3.0 | $0.005/image | $0.004/image | $0.004 | $0.007 | 75% |

---

### ElevenLabs (Voice)

| Model | List Price | Volume Discount | Your Cost | Your Price | Margin |
|-------|------------|-----------------|-----------|------------|--------|
| Multilingual v2 | $0.30/1K chars | $0.25/1K | $0.25 | $0.40 | 60% |
| Turbo v2 | $0.15/1K chars | $0.12/1K | $0.12 | $0.20 | 67% |

---

## 📊 Credit System

### How It Works

```
Tenant buys: 1,000,000 credits for €100

1 credit = $0.00001 (1 cent per 1000 credits)

Examples:
- GPT-4 Turbo: 35 credits per 1K tokens
- GPT-3.5: 1.5 credits per 1K tokens
- DALL-E 3: 5,500 credits per image
- Claude Opus: 20 credits per 1K tokens
```

### Credit Packages

| Package | Credits | Price (EUR) | Price per 1M | Bonus |
|---------|---------|-------------|--------------|-------|
| Starter | 100,000 | €10 | €100/M | - |
| Pro | 1,000,000 | €90 | €90/M | 10% bonus |
| Business | 10,000,000 | €800 | €80/M | 20% bonus |
| Enterprise | Custom | Custom | €70/M | 30% bonus |

### Credit Pricing Table

```typescript
// Database: db_blogmaster_platform

CREATE TABLE credit_prices (
  model_provider VARCHAR(50) NOT NULL,
  model_name VARCHAR(100) NOT NULL,
  unit VARCHAR(20) NOT NULL, -- 'tokens', 'images', 'characters', 'minutes'
  credits_per_unit INT NOT NULL,
  cost_usd_per_unit NUMERIC(10, 8) NOT NULL,

  PRIMARY KEY (model_provider, model_name)
);

-- Seed data
INSERT INTO credit_prices (model_provider, model_name, unit, credits_per_unit, cost_usd_per_unit) VALUES
  ('openai', 'gpt-4-turbo', 'tokens', 35, 0.00035),
  ('openai', 'gpt-4o', 'tokens', 18, 0.00018),
  ('openai', 'gpt-3.5-turbo', 'tokens', 1.5, 0.000015),
  ('openai', 'dall-e-3', 'images', 5500, 0.055),
  ('openai', 'whisper', 'minutes', 800, 0.008),
  ('anthropic', 'claude-3-opus', 'tokens', 20, 0.0002),
  ('anthropic', 'claude-3-sonnet', 'tokens', 4, 0.00004),
  ('anthropic', 'claude-3-haiku', 'tokens', 0.5, 0.000005),
  ('google', 'gemini-1.5-pro', 'tokens', 10, 0.0001),
  ('google', 'gemini-1.5-flash', 'tokens', 0.3, 0.000003),
  ('stability', 'sdxl-1.0', 'images', 300, 0.003),
  ('elevenlabs', 'multilingual-v2', 'characters', 400, 0.004);
```

---

## 🔧 Implementation

### Credit Purchase

```typescript
// POST /api/billing/credits/purchase

export async function purchaseCredits(req, res) {
  const { packageId, paymentMethod } = req.body;

  const packages = {
    starter: { credits: 100000, price_eur: 10 },
    pro: { credits: 1000000, price_eur: 90, bonus: 0.10 },
    business: { credits: 10000000, price_eur: 800, bonus: 0.20 },
  };

  const pkg = packages[packageId];
  if (!pkg) {
    return res.status(400).json({ error: 'Invalid package' });
  }

  // Calculate credits with bonus
  const totalCredits = Math.floor(pkg.credits * (1 + (pkg.bonus || 0)));

  // Create Stripe payment
  const payment = await stripe.paymentIntents.create({
    amount: pkg.price_eur * 100, // cents
    currency: 'eur',
    customer: req.tenant.stripe_customer_id,
    metadata: {
      tenant_id: req.tenant.id,
      package_id: packageId,
      credits: totalCredits
    }
  });

  // Add credits to tenant balance (after payment confirmation)
  await tenantCoreDB.query(`
    UPDATE tenant_config
    SET value = jsonb_set(value, '{credits_balance}', to_jsonb((value->>'credits_balance')::int + $1))
    WHERE key = 'billing'
  `, [totalCredits]);

  // Log transaction
  await platformDB.query(`
    INSERT INTO credit_transactions (tenant_id, amount_eur, credits, type, status)
    VALUES ($1, $2, $3, 'purchase', 'completed')
  `, [req.tenant.id, pkg.price_eur, totalCredits]);

  res.json({
    success: true,
    credits_added: totalCredits,
    new_balance: await getCreditBalance(req.tenant.id)
  });
}
```

---

### Credit Deduction

```typescript
// packages/core/ai/src/credit-manager.ts

export class CreditManager {
  /**
   * Deduct credits for AI usage
   */
  async deductCredits(
    tenantId: string,
    userId: string,
    provider: string,
    model: string,
    units: number
  ): Promise<{ success: boolean; balance: number }> {
    // Get credit price
    const pricing = await platformDB.query(`
      SELECT credits_per_unit, cost_usd_per_unit
      FROM credit_prices
      WHERE model_provider = $1 AND model_name = $2
    `, [provider, model]);

    if (!pricing.rows[0]) {
      throw new Error('Model pricing not found');
    }

    const creditsPerUnit = pricing.rows[0].credits_per_unit;
    const totalCredits = Math.ceil((units / 1000) * creditsPerUnit);

    // Check balance
    const balance = await this.getCreditBalance(tenantId);

    if (balance < totalCredits) {
      return { success: false, balance, error: 'Insufficient credits' };
    }

    // Deduct credits
    await tenantCoreDB.query(`
      UPDATE tenant_config
      SET value = jsonb_set(value, '{credits_balance}', to_jsonb((value->>'credits_balance')::int - $1))
      WHERE key = 'billing'
    `, [totalCredits]);

    // Log usage
    await tenantCoreDB.query(`
      INSERT INTO ai_usage (tenant_id, user_id, provider, model, units, credits_used)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [tenantId, userId, provider, model, units, totalCredits]);

    return {
      success: true,
      balance: balance - totalCredits
    };
  }

  /**
   * Get current credit balance
   */
  async getCreditBalance(tenantId: string): Promise<number> {
    const result = await tenantCoreDB.query(`
      SELECT value->>'credits_balance' as balance
      FROM tenant_config
      WHERE key = 'billing'
    `);

    return parseInt(result.rows[0]?.balance || '0');
  }

  /**
   * Estimate cost before execution
   */
  async estimateCost(provider: string, model: string, units: number): Promise<{
    credits: number;
    usd: number;
    eur: number;
  }> {
    const pricing = await platformDB.query(`
      SELECT credits_per_unit, cost_usd_per_unit
      FROM credit_prices
      WHERE model_provider = $1 AND model_name = $2
    `, [provider, model]);

    const creditsPerUnit = pricing.rows[0].credits_per_unit;
    const costPerUnit = pricing.rows[0].cost_usd_per_unit;

    const totalCredits = Math.ceil((units / 1000) * creditsPerUnit);
    const totalUSD = (units / 1000) * costPerUnit;
    const totalEUR = totalUSD * 0.92; // Approximate EUR conversion

    return {
      credits: totalCredits,
      usd: totalUSD,
      eur: totalEUR
    };
  }
}

export const creditManager = new CreditManager();
```

---

### AI API Integration with Credits

```typescript
// packages/core/ai/src/ai-service.ts

export class AIService {
  /**
   * Generate text with credit deduction
   */
  async generateText(tenantId: string, userId: string, options: {
    provider: 'openai' | 'anthropic' | 'google';
    model: string;
    prompt: string;
    maxTokens?: number;
  }) {
    // Estimate cost
    const estimate = await creditManager.estimateCost(
      options.provider,
      options.model,
      options.maxTokens || 1000
    );

    // Check balance
    const balance = await creditManager.getCreditBalance(tenantId);

    if (balance < estimate.credits) {
      throw new Error(`Insufficient credits. Need ${estimate.credits}, have ${balance}`);
    }

    // Call AI API
    let response;
    switch (options.provider) {
      case 'openai':
        response = await openai.chat.completions.create({
          model: options.model,
          messages: [{ role: 'user', content: options.prompt }],
          max_tokens: options.maxTokens
        });
        break;

      case 'anthropic':
        response = await anthropic.messages.create({
          model: options.model,
          messages: [{ role: 'user', content: options.prompt }],
          max_tokens: options.maxTokens
        });
        break;

      case 'google':
        response = await gemini.generateContent({
          model: options.model,
          prompt: options.prompt
        });
        break;
    }

    // Calculate actual usage
    const actualTokens = response.usage.total_tokens;

    // Deduct credits
    const deduction = await creditManager.deductCredits(
      tenantId,
      userId,
      options.provider,
      options.model,
      actualTokens
    );

    return {
      text: response.choices[0].message.content,
      usage: {
        tokens: actualTokens,
        credits: estimate.credits,
        balance: deduction.balance
      }
    };
  }
}
```

---

## 📊 Volume Discount Negotiation

### How to Get Volume Discounts

**OpenAI**:
1. Sign up for Enterprise plan: https://openai.com/enterprise
2. Contact sales when you reach $10K/month
3. Negotiate tiered pricing based on commitment

**Anthropic**:
1. Fill enterprise form: https://www.anthropic.com/enterprise
2. Minimum $25K/month commitment for discount
3. Custom pricing for $100K+/month

**Google**:
1. Apply for Vertex AI: https://cloud.google.com/vertex-ai
2. Committed use discounts available
3. Enterprise agreements for large volume

---

## 🎯 Reseller Agreement Template

```
AI RESELLER AGREEMENT

Provider: OpenAI
Reseller: BlogMaster SRL
Date: 2025-10-11

TERMS:
1. Reseller purchases API credits in bulk
2. Volume discount: 17% off list price
3. Monthly commitment: $10,000 USD minimum
4. Payment terms: Net 30
5. Reseller can markup and resell to end customers
6. Reseller responsible for customer support
7. Provider SLA: 99.9% uptime
8. Contract term: 12 months, auto-renew

PRICING:
- GPT-4 Turbo: $0.025 per 1K tokens (list: $0.03)
- GPT-4o: $0.012 per 1K tokens (list: $0.015)
- GPT-3.5: $0.0008 per 1K tokens (list: $0.001)
```

---

## 💡 Revenue Projections

### Scenario 1: 100 Tenants

**Assumptions**:
- Average tenant uses 1M credits/month
- Average credit price: €90 per 1M credits

**Monthly Revenue**: 100 × €90 = €9,000
**Monthly Cost** (to providers): €6,000 (67% of revenue)
**Gross Margin**: €3,000 (33%)

---

### Scenario 2: 1000 Tenants

**Monthly Revenue**: 1,000 × €90 = €90,000
**Monthly Cost**: €60,000
**Gross Margin**: €30,000 (33%)

**With Volume Discount** (17% off):
**Monthly Cost**: €50,000
**Gross Margin**: €40,000 (44%)

---

### Scenario 3: Enterprise Customers

**Single customer**: 100M credits/month = €7,000
**Your Cost**: €4,600 (with discount)
**Margin**: €2,400 (34%)

---

## ✅ Summary

**Reseller Model**:
- ✅ Buy AI credits in bulk (volume discount)
- ✅ Sell to tenants with markup (35-60% margin)
- ✅ Credit-based billing (simple for customers)
- ✅ Multiple providers (OpenAI, Anthropic, Google, etc.)

**Volume Discounts**:
- ✅ OpenAI: 17% off at $200K+/month
- ✅ Anthropic: 17% off at $100K+/month
- ✅ Google: 15% off at $50K+/month

**Revenue Potential**:
- ✅ 100 tenants: €3,000/month margin
- ✅ 1,000 tenants: €40,000/month margin (with discount)
- ✅ Scalable business model

**Next Steps**:
1. Sign up for provider enterprise plans
2. Negotiate volume discounts
3. Implement credit system in platform
4. Market AI features to tenants
5. Scale usage to hit discount tiers

---

**Next**: WEBHOOK_RETRY_STRATEGY.md 🚀
