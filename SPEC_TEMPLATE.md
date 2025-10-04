# {SYSTEM_NAME}

> **One-line description of what this system does**

**Version:** 1.0.0
**Target:** {Target audience: developers, end-users, admins, etc.}
**Last revision:** YYYY-MM-DD
**Roadmap Stage:** {MVP / Production / Scaling / Enterprise}

---

## 🎯 Objectives

**Primary Goals:**
- Main objective 1
- Main objective 2
- Main objective 3

**Success Criteria:**
- Measurable metric 1
- Measurable metric 2
- User satisfaction threshold

**Out of Scope (Not in v1.0):**
- Explicitly list what is NOT included
- Prevents scope creep

---

## 🏗️ Architecture Overview

### System Components

```
┌─────────────────────────────────────────────┐
│                                             │
│  [Component Diagram - Optional ASCII]       │
│                                             │
└─────────────────────────────────────────────┘
```

**Core Components:**
1. **Component A**: Brief description
2. **Component B**: Brief description
3. **Component C**: Brief description

### Tech Stack

**Backend:** (refer to MASTER_PROMPT.md for standards)
- Framework: Fastify 4.28+
- Language: TypeScript 5.6+
- Database: PostgreSQL 15+ (if needed)
- Validation: Zod

**Frontend:** (if applicable)
- Framework: Next.js 14.2 (App Router)
- UI Library: React 18
- Styling: TailwindCSS

**External Services/APIs:**
- Service 1: {Purpose}
- Service 2: {Purpose}

---

## 📋 Features

### 🟢 TIER 1: MVP (Essential)

**Timeframe:** X-Y weeks

**Core Features:**
- ✅ Feature 1: {Brief description}
- ✅ Feature 2: {Brief description}
- ✅ Feature 3: {Brief description}

**Acceptance Criteria:**
- Criteria 1
- Criteria 2

### 🟡 TIER 2: Production Ready (Nice-to-Have)

**Timeframe:** +X weeks after MVP

**Enhanced Features:**
- ⚠️ Feature 4: {Brief description}
- ⚠️ Feature 5: {Brief description}

### 🔵 TIER 3: Scaling (Future)

**Timeframe:** Future phases

**Advanced Features:**
- 🔮 Feature 6: {Brief description}
- 🔮 Feature 7: {Brief description}

### 🟣 TIER 4: Enterprise (Long-term)

**Optional - only if relevant**

---

## 🔗 Dependencies

### Internal Services

| Service | Status | Purpose | Required For |
|---------|--------|---------|--------------|
| svc-auth | ✅ Complete | Authentication | All endpoints |
| svc-{name} | ❌ Missing | {Purpose} | {Feature} |
| svc-{name} | 🚧 Partial | {Purpose} | {Feature} |

### External APIs/Services

| Service | Purpose | Fallback |
|---------|---------|----------|
| {API name} | {Purpose} | {What if unavailable} |

**Blockers:**
- Missing service X blocks feature Y
- Missing integration Z blocks tier 2

**Workarounds:**
- Mock data for X until service ready
- Stub implementation for Z

---

## 📊 Database Schema

**Tables:** (if applicable)

### Table: `{table_name}`

```sql
CREATE TABLE {table_name} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES organizations(id),
  -- Multi-tenancy MANDATORY

  {field_name} VARCHAR(255) NOT NULL,
  {field_name} JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT {constraint_name} ...
);

-- Indexes
CREATE INDEX idx_{table}_tenant ON {table_name}(tenant_id);
CREATE INDEX idx_{table}_field ON {table_name}({field});
```

### Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;

-- Policy (to be enabled in production)
CREATE POLICY tenant_isolation ON {table_name}
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
```

---

## 🔌 API Endpoints

### Authentication

**All endpoints require:**
- Header: `Authorization: Bearer {jwt_token}`
- JWT contains: `tenant_id`, `user_id`, `scopes`

### Endpoints List

#### `POST /api/v1/{resource}`

**Description:** Create new {resource}

**Request:**
```typescript
{
  field1: string;
  field2: number;
  // Validation via Zod schema
}
```

**Response:**
```typescript
{
  id: string;
  field1: string;
  created_at: string;
}
```

**Status Codes:**
- `201 Created`: Success
- `400 Bad Request`: Validation error
- `401 Unauthorized`: Missing/invalid token
- `409 Conflict`: Duplicate resource

**Validation Schema (Zod):**
```typescript
const CreateSchema = z.object({
  field1: z.string().min(1).max(255),
  field2: z.number().int().positive(),
});
```

#### `GET /api/v1/{resource}`

**Description:** List {resources} with pagination

**Query Params:**
- `page` (default: 1)
- `limit` (default: 20, max: 100)
- `sort` (optional)
- `filter` (optional)

**Response:**
```typescript
{
  data: Array<{...}>;
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  }
}
```

#### `GET /api/v1/{resource}/:id`

**Description:** Get single {resource} by ID

#### `PATCH /api/v1/{resource}/:id`

**Description:** Update {resource}

#### `DELETE /api/v1/{resource}/:id`

**Description:** Delete {resource}

---

## 🚀 Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Database schema creation
- [ ] Base API structure (Fastify setup)
- [ ] Authentication middleware
- [ ] Zod validation schemas

### Phase 2: Core Features (Week 3-4)
- [ ] Feature 1 implementation
- [ ] Feature 2 implementation
- [ ] Feature 3 implementation

### Phase 3: Testing & Polish (Week 5-6)
- [ ] Unit tests (60% coverage minimum)
- [ ] Integration tests
- [ ] API documentation
- [ ] Error handling refinement

### Phase 4: Production Ready (Week 7-8)
- [ ] Performance optimization
- [ ] Monitoring & logging
- [ ] Documentation completion
- [ ] Deployment preparation

---

## 🧪 Testing Strategy

### Unit Tests

**Coverage Target:** Minimum 60%

**Focus Areas:**
- Business logic functions
- Validation schemas
- Utility functions

**Tools:** Vitest

```typescript
describe('ResourceService', () => {
  it('should create resource with valid data', async () => {
    // Test implementation
  });
});
```

### Integration Tests

**Focus Areas:**
- API endpoints
- Database operations
- Service interactions

### E2E Tests (Optional for MVP)

**Tools:** Playwright (frontend), Supertest (API)

---

## 📈 Metrics & Monitoring

### Key Metrics

**Performance:**
- API response time (p95 < 200ms)
- Database query time (p95 < 50ms)
- Error rate (< 1%)

**Business:**
- Daily active users
- Feature usage rate
- Conversion rate (if applicable)

### Logging

**Structured Logging (Pino):**
```typescript
logger.info({
  tenant_id: req.tenantId,
  correlation_id: req.correlationId,
  action: 'resource.created',
  resource_id: resource.id
}, 'Resource created successfully');
```

### Alerts

**Setup alerts for:**
- Error rate > 5%
- Response time p95 > 500ms
- Database connection failures

---

## 🔒 Security Considerations

### Multi-Tenancy

**MANDATORY:**
- ALL tables have `tenant_id` column
- ALL queries filter by `tenant_id`
- RLS policies defined (enabled in production)

### Input Validation

- Zod schemas for all inputs
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitization)

### Rate Limiting

- Per-tenant rate limits
- Per-endpoint rate limits
- Implement in svc-api-gateway

---

## 🐛 Known Issues & Limitations

### Current Limitations

1. **Limitation 1:** Description and impact
2. **Limitation 2:** Description and impact

### Known Bugs

- Bug 1: {description} - **Status:** {Open/In Progress/Fixed}
- Bug 2: {description} - **Status:** {Open/In Progress/Fixed}

### Technical Debt

- Debt 1: {description} - **Priority:** {High/Medium/Low}
- Debt 2: {description} - **Priority:** {High/Medium/Low}

---

## 📚 Related Documentation

**Internal:**
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall system architecture
- [MASTER_PROMPT.md](MASTER_PROMPT.md) - Coding standards
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - Implementation status
- [GUARDRAILS.md](GUARDRAILS.md) - Coordination rules

**External:**
- [Fastify Docs](https://fastify.dev)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Zod Docs](https://zod.dev)

**Similar Systems:** (for reference)
- {SIMILAR_SPEC_1.md} - If pattern reuse
- {SIMILAR_SPEC_2.md} - If architecture similar

---

## 🔄 Change Log

### Version 1.0.0 (YYYY-MM-DD)
- Initial specification
- Core features defined
- Architecture outlined

---

**Document Status:** Draft / Under Review / Approved / Implemented
**Next Review:** YYYY-MM-DD
**Owner:** {Team/Person responsible}

---

## 📝 Template Usage Notes

**When using this template:**
1. Replace all `{PLACEHOLDERS}` with actual values
2. Remove sections marked "Optional" if not applicable
3. Keep structure consistent across all specs
4. Target spec size: 30-80 KB (split if >120 KB)
5. Focus on MVP first, tier 2+ can be brief

**DO:**
- ✅ Be specific and measurable
- ✅ Include diagrams where helpful
- ✅ List dependencies explicitly
- ✅ Define clear success criteria

**DON'T:**
- ❌ Mix multiple systems in one spec
- ❌ Include implementation code (use examples only)
- ❌ Duplicate info from MASTER_PROMPT.md
- ❌ Write >120 KB specs (split instead)
