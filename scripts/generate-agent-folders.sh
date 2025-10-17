#!/bin/bash

# Generate agents/ folders for all apps and services
# Based on template from app-dam/agents/

set -e

echo "🤖 Generating agents/ folders for all services..."

# List of all services and apps from architecture canvas
SERVICES=(
  # AUTOMATION CORE
  "svc-workflow-engine:4900:Automation:Node-based automation engine"
  "svc-approvals:4409:Automation:Multi-level approval system"
  "svc-webhooks:4910:Automation:Webhook orchestration"

  # SHARED SERVICES
  "svc-contacts:4600:Shared:Universal contact management"
  "svc-comm:4700:Shared:Email, SMS, Push, In-app messaging"
  "svc-analytics:4710:Shared:BI and metrics"
  "svc-search:4720:Shared:Full-text + semantic search"
  "svc-ai-engine:4730:Shared:GPT, image gen, OCR"
  "svc-storage:4740:Shared:File storage abstraction"
  "svc-translation:4750:Shared:Translation management"
  "svc-forms:4760:Shared:Form builder and submissions"
  "svc-audit:4770:Shared:Audit trail"
  "svc-visual-db:4850:Shared:Visual DB editor"
  "svc-dashboard-builder:4860:Shared:Dashboard composer"
  "svc-page-builder-backend:4870:Shared:Page builder backend"

  # CREATIVE SUITE
  "svc-image-editor:4920:Creative:Photoshop-like editor"
  "svc-raw-editor:5505:Creative:Lightroom-like RAW editor"
  "svc-video-editor:4930:Creative:Video editor cloud"
  "svc-canvas:4940:Creative:Canva-like design"
  "svc-mockup-generator:4950:Creative:Product mockups"
  "svc-prepress:4960:Creative:Pre-press validation"
  "svc-dtp:4830:Creative:Desktop publishing"

  # COMMUNICATION SUITE
  "svc-email-server:4970:Communication:SMTP + IMAP"
  "svc-cold-email:4980:Communication:Cold email campaigns"
  "svc-newsletter:4990:Communication:Newsletter platform"
  "svc-scraping:5000:Communication:Web scraping + enrichment"
  "svc-voip:5080:Communication:VoIP + SIP server"

  # CONTENT SUITE
  "svc-text-editor:5010:Content:AI-enhanced text editor"
  "svc-multi-site:5020:Content:Multi-site publishing"
  "svc-cms:4200:Content:Headless CMS"

  # BUSINESS OPS
  "svc-shipping:5030:BusinessOps:Carrier integration"
  "svc-fleet:5040:BusinessOps:Fleet management"
  "svc-hr:5050:BusinessOps:HR complete"
  "svc-invoicing:5060:BusinessOps:Invoicing"
  "svc-accounting:5070:BusinessOps:Accounting"
  "svc-billing:4004:BusinessOps:Stripe subscriptions"
  "svc-warehouse-advanced:5255:BusinessOps:Advanced WMS"
  "svc-multi-location:5250:BusinessOps:Multi-location management"
  "svc-inventory-multi:5260:BusinessOps:Multi-warehouse inventory"
  "svc-quotes-out:5265:BusinessOps:Sales quotation"
  "svc-quotes-in:5270:BusinessOps:Purchase quotation/RFQ"

  # DOMAIN SERVICES
  "svc-dam:4100:Domain:Digital Asset Management"
  "svc-crm:4800:Domain:Customer Relationship Management"
  "svc-mrp:4810:Domain:Material Resource Planning"
  "svc-pim:4820:Domain:Product Information Management"
  "svc-pm:4400:Domain:Project Management"
  "svc-wysiwyg:4840:Domain:Page editor engine"
  "svc-call-center:5090:Domain:Call center software"
  "svc-booking:5100:Domain:Booking system"
)

# Function to create agents folder
create_agents_folder() {
  local service_info=$1
  IFS=':' read -r service_name port category description <<< "$service_info"

  # Skip if already exists
  if [ -d "$service_name/agents" ]; then
    echo "  ⏭️  $service_name/agents (already exists)"
    return
  fi

  # Skip if service directory doesn't exist
  if [ ! -d "$service_name" ]; then
    echo "  ⚠️  $service_name (directory not found, skipping)"
    return
  fi

  echo "  ✅ Creating $service_name/agents/"
  mkdir -p "$service_name/agents"

  # Create CHECKLIST.md
  cat > "$service_name/agents/CHECKLIST.md" <<EOF
# ${service_name} Development Checklist

> Development checklist for ${description}

## 🗄️ Database Layer

### Core Tables
- [ ] Define core tables based on SPECS.md
- [ ] Add RLS policies for tenant isolation
- [ ] Add indexes for performance
- [ ] Create migration files

### Advanced Tables
- [ ] Define advanced/optional tables
- [ ] Add full-text search indexes if needed
- [ ] Add vector columns if AI features needed

### Sample Data
- [ ] Create seed script for test data
- [ ] Document data model

---

## 🔌 Backend API

### Core CRUD Endpoints
- [ ] Define and implement core endpoints
- [ ] Add validation (Zod schemas)
- [ ] Add authentication/authorization
- [ ] Write unit tests

### Advanced Features
- [ ] Implement advanced features from SPECS.md
- [ ] Add integration with shared services
- [ ] Write integration tests

### References to Shared Services
- [ ] Integration with \`svc-comm\` (if notifications needed)
- [ ] Integration with \`svc-search\` (if search needed)
- [ ] Integration with \`svc-auth\` (for permissions)
- [ ] Integration with \`svc-storage\` (if file operations needed)
- [ ] Other shared services as needed

---

## 🎨 Frontend UI (if applicable)

### Core Views
- [ ] Define main views based on SPECS.md
- [ ] Implement components
- [ ] Add routing

### Components
- [ ] Create reusable components
- [ ] Add to \`@ewh/ui-components\` if generic

---

## 🧪 Testing

### Unit Tests
- [ ] Database model tests
- [ ] API endpoint tests
- [ ] Business logic tests

### Integration Tests
- [ ] End-to-end flow tests
- [ ] Shared service integration tests

### E2E Tests (if frontend)
- [ ] Key user workflows

---

## 📚 Documentation

- [ ] API documentation (OpenAPI/Swagger)
- [ ] Database schema diagram
- [ ] User guide (if applicable)
- [ ] Integration guide

---

## 🚀 Deployment

- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] Service deployed
- [ ] Monitoring setup
- [ ] Error tracking (Sentry)

---

## ✅ Definition of Done

- [ ] All database tables created with RLS
- [ ] All API endpoints implemented and tested
- [ ] All UI views completed (if applicable)
- [ ] Integration with shared services working
- [ ] Tests passing (unit + integration)
- [ ] Documentation complete
- [ ] Deployment successful

---

**Last Updated:** 2025-01-17
**Status:** 🔴 Not Started
**Priority:** TBD
**Owner:** TBD
EOF

  # Create CONTEXT.md
  cat > "$service_name/agents/CONTEXT.md" <<EOF
# ${service_name} Agent Context

> Context file for AI agents working on ${description}

## 🎯 Service Overview

**Name:** ${description}
**Code:** \`${service_name}\`
**Port:** ${port}
**Type:** ${category} Service
**Suite:** ${category} Suite

**Purpose:** ${description}

---

## 📋 Specifications

**Location:** [${service_name}/SPECS.md](../SPECS.md)

**Key Features:**
- See SPECS.md for complete feature list

**NOT Included (Shared Services):**
- Email notifications → \`svc-comm\`
- File storage → \`svc-storage\`
- Search → \`svc-search\`
- Auth/permissions → \`svc-auth\`

---

## 🗄️ Database Architecture

**Database:** \`ewh_tenant\` (multi-schema) or \`ewh_core_${service_name}\`
**Schema:** \`tenant_{org_id}\` or service-specific

**Core Tables:**
\`\`\`sql
-- Define based on SPECS.md
\`\`\`

**RLS Strategy:** Tenant isolation via \`org_id\` column + role-based policies

**See:** [DATABASE_ARCHITECTURE.md](../../DATABASE_ARCHITECTURE.md)

---

## 🔌 Dependencies

### Shared Services (API calls)

**svc-comm** (Communication) - If needed
\`\`\`typescript
POST /api/comm/send-email
POST /api/comm/send-notification
\`\`\`

**svc-auth** (Authentication) - Always needed
\`\`\`typescript
GET /api/auth/verify-token
GET /api/auth/permissions/:user_id
\`\`\`

See SPECS.md for full dependency list.

---

## 🏗️ Tech Stack

**Backend:**
- Runtime: Node.js 20+
- Framework: Fastify
- Language: TypeScript
- ORM: Drizzle (or raw SQL)
- Validation: Zod

**Frontend (if applicable):**
- Framework: React 18 + Next.js 14
- Language: TypeScript
- State: Zustand
- UI: @ewh/ui-components

**Database:**
- PostgreSQL 15 (Supabase)
- RLS enabled

---

## 📁 Project Structure

\`\`\`
${service_name}/
├── src/
│   ├── routes/          # API endpoints
│   ├── services/        # Business logic
│   ├── models/          # Database models
│   ├── schemas/         # Zod validation schemas
│   ├── utils/           # Helpers
│   └── index.ts         # Entry point
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── agents/              # 👈 You are here
│   ├── CHECKLIST.md
│   ├── CONTEXT.md
│   └── TASKS.md
├── SPECS.md             # Feature specifications
├── ROADMAP.md           # Development roadmap
├── .env.example
└── package.json
\`\`\`

---

## 🔑 Environment Variables

\`\`\`bash
# Backend
PORT=${port}
DATABASE_URL=postgresql://...
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...

# Shared Service URLs
SVC_COMM_URL=http://localhost:4700
SVC_AUTH_URL=http://localhost:4500
# Add other services as needed
\`\`\`

---

## 🚀 Quick Start

\`\`\`bash
npm install
npm run migrate
npm run dev
npm test
\`\`\`

---

## 📝 Coding Guidelines

**TypeScript:**
- Strict mode enabled
- No \`any\` types
- Use Zod for runtime validation

**API Design:**
- RESTful endpoints
- JWT authentication
- Consistent error responses
- Pagination for lists (limit/offset)

**Database:**
- Use prepared statements
- Enable RLS on all tables
- Index foreign keys
- Use transactions for multi-table operations

---

## 📚 Resources

- [SPECS.md](../SPECS.md) - Full feature list
- [ROADMAP.md](../ROADMAP.md) - Development plan
- [SERVICE_FEATURE_MAPPING.md](../../SERVICE_FEATURE_MAPPING.md) - Service boundaries
- [MASTER_PROMPT.md](../../MASTER_PROMPT.md) - Platform overview

---

**Last Updated:** 2025-01-17
**Agent Version:** 1.0
EOF

  # Create TASKS.md
  cat > "$service_name/agents/TASKS.md" <<EOF
# ${service_name} Development Tasks

> Detailed task breakdown for ${description}

## Phase 1: Database Schema

### Task 1.1: Core Tables
**Priority:** Critical
**Estimated:** 8h

- [ ] Define core tables based on SPECS.md
- [ ] Add RLS policies for tenant isolation
- [ ] Add indexes for performance
- [ ] Write migration file

**Acceptance:**
- All tables created
- RLS enabled and tested
- Migration runs successfully

---

### Task 1.2: Sample Data
**Priority:** Medium
**Estimated:** 4h

- [ ] Create seed script for test data
- [ ] Document data model

**Acceptance:**
- Seed script working
- Data model documented

---

## Phase 2: Backend API

### Task 2.1: Core Endpoints
**Priority:** Critical
**Estimated:** 12h

- [ ] Define API endpoints from SPECS.md
- [ ] Implement CRUD operations
- [ ] Add validation (Zod)
- [ ] Add authentication/authorization
- [ ] Write unit tests
- [ ] Write integration tests

**Acceptance:**
- All endpoints working
- Permissions enforced
- Tests passing

---

### Task 2.2: Integration with Shared Services
**Priority:** High
**Estimated:** 8h

- [ ] Integrate with \`svc-auth\` for authentication
- [ ] Integrate with \`svc-comm\` (if needed)
- [ ] Integrate with other shared services
- [ ] Handle errors gracefully
- [ ] Write integration tests

**Acceptance:**
- Shared service calls working
- Error handling robust
- Tests passing

---

## Phase 3: Frontend UI (if applicable)

### Task 3.1: Core Views
**Priority:** Critical
**Estimated:** 12h

- [ ] Implement main views from SPECS.md
- [ ] Add components
- [ ] Add routing
- [ ] Responsive design

**Acceptance:**
- Views working
- Responsive on mobile
- Accessible (WCAG AA)

---

## Phase 4: Testing & Documentation

### Task 4.1: Testing
**Priority:** High
**Estimated:** 12h

- [ ] Unit tests (>80% coverage)
- [ ] Integration tests
- [ ] E2E tests (if frontend)

**Acceptance:**
- All tests passing
- Coverage >80%

---

### Task 4.2: Documentation
**Priority:** Medium
**Estimated:** 8h

- [ ] API documentation (OpenAPI)
- [ ] User guide (if applicable)
- [ ] Developer guide

**Acceptance:**
- Docs complete
- Examples provided

---

## Phase 5: Deployment

### Task 5.1: Deployment
**Priority:** Critical
**Estimated:** 6h

- [ ] Configure environment variables
- [ ] Run migrations
- [ ] Deploy service
- [ ] Setup monitoring
- [ ] Test in production

**Acceptance:**
- Deployment successful
- Service healthy
- No critical errors

---

## Summary

**Total Estimated Hours:** TBD
**Status:** 🔴 Not Started
**Next Task:** Phase 1, Task 1.1

---

**Last Updated:** 2025-01-17
EOF
}

# Process all services
for service_info in "${SERVICES[@]}"; do
  create_agents_folder "$service_info"
done

echo ""
echo "✅ Agents folders generation complete!"
echo ""
echo "📊 Summary:"
echo "  - Total services: ${#SERVICES[@]}"
echo "  - Check each service's agents/ folder for:"
echo "    • CHECKLIST.md - Development checklist"
echo "    • CONTEXT.md - Agent context and guidelines"
echo "    • TASKS.md - Detailed task breakdown"
echo ""
echo "💡 Next: Review and customize each service's agents/ files based on SPECS.md"
