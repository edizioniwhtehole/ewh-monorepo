#!/bin/bash

# Generate ROADMAP.md files for all services that have SPECS.md

set -e

echo "🗺️  Generating ROADMAP.md files for services with SPECS..."

# Find all SPECS.md files
specs_files=$(find . -maxdepth 2 -name "SPECS.md" -not -path "./node_modules/*" -not -path "./.git/*")

count=0
for spec_file in $specs_files; do
  # Get directory
  dir=$(dirname "$spec_file")
  service=$(basename "$dir")

  # Skip if ROADMAP.md already exists
  if [ -f "$dir/ROADMAP.md" ]; then
    echo "  ⏭️  $service (ROADMAP.md already exists)"
    continue
  fi

  echo "  ✅ Creating $service/ROADMAP.md"

  # Extract service type and description from CONTEXT.md if exists
  desc="Development roadmap"
  if [ -f "$dir/agents/CONTEXT.md" ]; then
    desc=$(grep "^**Purpose:**" "$dir/agents/CONTEXT.md" | sed 's/\*\*Purpose:\*\* //' || echo "Development roadmap")
  fi

  # Create ROADMAP.md
  cat > "$dir/ROADMAP.md" <<EOF
# $service Development Roadmap

> Color-coded development roadmap for $service

**Legend:**
- ✅ Verde (Completed)
- 🟡 Giallo (In Progress)
- 🔴 Rosso (To Do)
- ⚫ Nero (Blocked/Impossible)

---

## 📊 Progress Overview

**Overall Completion:** 0% (0/25 tasks estimated)

| Phase | Tasks | Completed | In Progress | To Do | Blocked |
|-------|-------|-----------|-------------|-------|---------|
| Phase 1: Database | 3 | 0 | 0 | 3 | 0 |
| Phase 2: Backend API | 7 | 0 | 0 | 7 | 0 |
| Phase 3: Frontend UI | 6 | 0 | 0 | 6 | 0 |
| Phase 4: Testing | 5 | 0 | 0 | 5 | 0 |
| Phase 5: Deployment | 4 | 0 | 0 | 4 | 0 |
| **TOTAL** | **25** | **0** | **0** | **25** | **0** |

---

## Phase 1: Database Schema

### 🔴 Task 1.1: Core Tables
**Status:** To Do
**Priority:** Critical
**Estimated:** 8h
**Owner:** TBD

**Description:**
Create core database tables based on SPECS.md.

**Subtasks:**
- [ ] Define core tables from SPECS.md
- [ ] Add RLS policies for tenant isolation
- [ ] Add indexes for performance
- [ ] Write migration file

**Acceptance Criteria:**
- All tables created
- RLS enabled and tested
- Migration runs successfully

**Dependencies:**
- None

---

### 🔴 Task 1.2: Advanced Tables
**Status:** To Do
**Priority:** High
**Estimated:** 6h
**Owner:** TBD

**Description:**
Create advanced/optional tables for extended features.

**Subtasks:**
- [ ] Define advanced tables from SPECS.md
- [ ] Add full-text search indexes (if needed)
- [ ] Add vector columns (if AI features)
- [ ] Write migration file

**Acceptance Criteria:**
- Advanced tables created
- Indexes optimized
- Migration runs successfully

**Dependencies:**
- Task 1.1 (Core Tables)

---

### 🔴 Task 1.3: Sample Data
**Status:** To Do
**Priority:** Medium
**Estimated:** 4h
**Owner:** TBD

**Description:**
Create seed scripts and sample data for testing.

**Subtasks:**
- [ ] Create seed script
- [ ] Add representative sample data
- [ ] Document data model

**Acceptance Criteria:**
- Seed script working
- Sample data covers key scenarios
- Data model documented

**Dependencies:**
- Task 1.2 (Advanced Tables)

---

## Phase 2: Backend API

### 🔴 Task 2.1: Core CRUD Endpoints
**Status:** To Do
**Priority:** Critical
**Estimated:** 12h
**Owner:** TBD

**Description:**
Implement core CRUD API endpoints based on SPECS.md.

**Subtasks:**
- [ ] Define API endpoints from SPECS.md
- [ ] Implement CRUD operations
- [ ] Add validation (Zod schemas)
- [ ] Add authentication/authorization
- [ ] Write unit tests
- [ ] Write integration tests

**Acceptance Criteria:**
- All endpoints working
- Validation robust
- Permissions enforced
- Tests passing

**Dependencies:**
- Task 1.1 (Core Tables)

---

### 🔴 Task 2.2: Advanced Features
**Status:** To Do
**Priority:** High
**Estimated:** 10h
**Owner:** TBD

**Description:**
Implement advanced features from SPECS.md.

**Subtasks:**
- [ ] Implement feature 1 (from SPECS.md)
- [ ] Implement feature 2 (from SPECS.md)
- [ ] Implement feature 3 (from SPECS.md)
- [ ] Error handling
- [ ] Write tests

**Acceptance Criteria:**
- All advanced features working
- Error handling robust
- Tests passing

**Dependencies:**
- Task 2.1 (Core CRUD)

---

### 🔴 Task 2.3: Shared Service Integration
**Status:** To Do
**Priority:** High
**Estimated:** 8h
**Owner:** TBD

**Description:**
Integrate with required shared services.

**Subtasks:**
- [ ] Integrate with \`svc-auth\` for authentication
- [ ] Integrate with \`svc-comm\` (if needed)
- [ ] Integrate with other shared services
- [ ] Handle errors gracefully
- [ ] Write integration tests

**Acceptance Criteria:**
- Shared service calls working
- Error handling robust
- Tests passing

**Dependencies:**
- Task 2.1 (Core CRUD)
- Shared services must be implemented

---

### 🔴 Task 2.4: Search & Filtering
**Status:** To Do
**Priority:** Medium
**Estimated:** 8h
**Owner:** TBD

**Description:**
Implement search and filtering functionality.

**Subtasks:**
- [ ] Add search endpoints
- [ ] Add filtering logic
- [ ] Add sorting options
- [ ] Integrate with \`svc-search\` (if needed)
- [ ] Write tests

**Acceptance Criteria:**
- Search working and fast
- Filters accurate
- Tests passing

**Dependencies:**
- Task 2.1 (Core CRUD)

---

### 🔴 Task 2.5: Bulk Operations
**Status:** To Do
**Priority:** Low
**Estimated:** 6h
**Owner:** TBD

**Description:**
Implement bulk operations for efficiency.

**Subtasks:**
- [ ] Bulk create endpoint
- [ ] Bulk update endpoint
- [ ] Bulk delete endpoint
- [ ] Transaction handling
- [ ] Write tests

**Acceptance Criteria:**
- Bulk operations working
- Transactions atomic
- Tests passing

**Dependencies:**
- Task 2.1 (Core CRUD)

---

### 🔴 Task 2.6: Analytics & Reporting
**Status:** To Do
**Priority:** Low
**Estimated:** 6h
**Owner:** TBD

**Description:**
Add analytics and reporting endpoints.

**Subtasks:**
- [ ] Define analytics requirements
- [ ] Implement analytics queries
- [ ] Integrate with \`svc-analytics\` (if needed)
- [ ] Add caching
- [ ] Write tests

**Acceptance Criteria:**
- Analytics accurate
- Performance good
- Tests passing

**Dependencies:**
- Task 2.1 (Core CRUD)

---

### 🔴 Task 2.7: Webhooks & Events
**Status:** To Do
**Priority:** Low
**Estimated:** 4h
**Owner:** TBD

**Description:**
Add webhook support for events.

**Subtasks:**
- [ ] Define event types
- [ ] Implement event emitter
- [ ] Integrate with \`svc-webhooks\`
- [ ] Add retry logic
- [ ] Write tests

**Acceptance Criteria:**
- Events firing correctly
- Webhooks delivered
- Tests passing

**Dependencies:**
- Task 2.1 (Core CRUD)

---

## Phase 3: Frontend UI (if applicable)

### 🔴 Task 3.1: Main View
**Status:** To Do
**Priority:** Critical
**Estimated:** 12h
**Owner:** TBD

**Description:**
Build main view/dashboard for the service.

**Subtasks:**
- [ ] Design UI layout
- [ ] Implement components
- [ ] Add routing
- [ ] Add loading states
- [ ] Add error states
- [ ] Responsive design

**Acceptance Criteria:**
- Main view functional
- Responsive on mobile
- Accessible (WCAG AA)

**Dependencies:**
- Task 2.1 (Core API)

---

### 🔴 Task 3.2: Create/Edit Forms
**Status:** To Do
**Priority:** Critical
**Estimated:** 10h
**Owner:** TBD

**Description:**
Build forms for creating and editing entities.

**Subtasks:**
- [ ] Create form component
- [ ] Add validation (Zod)
- [ ] Add success/error handling
- [ ] Edit mode
- [ ] Auto-save (optional)

**Acceptance Criteria:**
- Forms working
- Validation robust
- UX smooth

**Dependencies:**
- Task 2.1 (Core API)

---

### 🔴 Task 3.3: List/Table View
**Status:** To Do
**Priority:** High
**Estimated:** 8h
**Owner:** TBD

**Description:**
Build list/table view with pagination and filtering.

**Subtasks:**
- [ ] Table component
- [ ] Pagination
- [ ] Sorting
- [ ] Filtering UI
- [ ] Bulk actions

**Acceptance Criteria:**
- Table functional
- Performance good (60fps)
- Filters working

**Dependencies:**
- Task 2.1 (Core API)

---

### 🔴 Task 3.4: Detail View
**Status:** To Do
**Priority:** High
**Estimated:** 6h
**Owner:** TBD

**Description:**
Build detail view for individual entities.

**Subtasks:**
- [ ] Detail page layout
- [ ] Display all fields
- [ ] Edit inline (optional)
- [ ] Related entities
- [ ] Actions (delete, etc.)

**Acceptance Criteria:**
- Detail view complete
- All data displayed
- Actions working

**Dependencies:**
- Task 2.1 (Core API)

---

### 🔴 Task 3.5: Search & Filter UI
**Status:** To Do
**Priority:** Medium
**Estimated:** 8h
**Owner:** TBD

**Description:**
Build search and filter interface.

**Subtasks:**
- [ ] Search bar
- [ ] Filter sidebar
- [ ] Advanced filters
- [ ] Saved searches (optional)
- [ ] Clear filters

**Acceptance Criteria:**
- Search instant
- Filters working
- UX smooth

**Dependencies:**
- Task 2.4 (Search API)

---

### 🔴 Task 3.6: Settings/Config UI
**Status:** To Do
**Priority:** Low
**Estimated:** 4h
**Owner:** TBD

**Description:**
Build settings/configuration interface.

**Subtasks:**
- [ ] Settings page
- [ ] Form for config
- [ ] Save functionality
- [ ] Validation

**Acceptance Criteria:**
- Settings saveable
- Validation working
- UI polished

**Dependencies:**
- Task 2.1 (Core API)

---

## Phase 4: Testing & Polish

### 🔴 Task 4.1: Unit Tests
**Status:** To Do
**Priority:** High
**Estimated:** 12h
**Owner:** TBD

**Description:**
Write comprehensive unit tests.

**Subtasks:**
- [ ] Test all services
- [ ] Test all utilities
- [ ] Test validation schemas
- [ ] Achieve >80% coverage

**Acceptance Criteria:**
- All tests passing
- Coverage >80%

**Dependencies:**
- All Phase 2 tasks

---

### 🔴 Task 4.2: Integration Tests
**Status:** To Do
**Priority:** High
**Estimated:** 8h
**Owner:** TBD

**Description:**
Write integration tests for key flows.

**Subtasks:**
- [ ] Test main workflows
- [ ] Test shared service integration
- [ ] Test error scenarios
- [ ] Mock external services

**Acceptance Criteria:**
- Integration tests passing
- Key flows covered

**Dependencies:**
- All Phase 2 tasks

---

### 🔴 Task 4.3: E2E Tests (if frontend)
**Status:** To Do
**Priority:** Medium
**Estimated:** 10h
**Owner:** TBD

**Description:**
Write end-to-end tests for user workflows.

**Subtasks:**
- [ ] Test create flow
- [ ] Test edit flow
- [ ] Test delete flow
- [ ] Test search/filter

**Acceptance Criteria:**
- E2E tests passing
- Key flows covered

**Dependencies:**
- All Phase 3 tasks

---

### 🔴 Task 4.4: Performance Optimization
**Status:** To Do
**Priority:** High
**Estimated:** 8h
**Owner:** TBD

**Description:**
Optimize for production performance.

**Subtasks:**
- [ ] Optimize database queries
- [ ] Add caching (Redis)
- [ ] Code splitting (frontend)
- [ ] Bundle optimization (frontend)
- [ ] Load testing

**Acceptance Criteria:**
- API response <200ms
- Frontend FCP <1s (if applicable)
- Load test passing

**Dependencies:**
- All Phase 2 & 3 tasks

---

### 🔴 Task 4.5: Documentation
**Status:** To Do
**Priority:** Medium
**Estimated:** 8h
**Owner:** TBD

**Description:**
Write comprehensive documentation.

**Subtasks:**
- [ ] API documentation (OpenAPI)
- [ ] User guide (if applicable)
- [ ] Developer guide
- [ ] Examples and tutorials

**Acceptance Criteria:**
- Docs complete
- Examples working
- Screenshots included (if applicable)

**Dependencies:**
- All Phase 2 & 3 tasks

---

## Phase 5: Deployment

### 🔴 Task 5.1: Environment Setup
**Status:** To Do
**Priority:** Critical
**Estimated:** 6h
**Owner:** TBD

**Description:**
Configure production environment.

**Subtasks:**
- [ ] Configure environment variables
- [ ] Setup secrets management
- [ ] Setup monitoring
- [ ] Setup error tracking (Sentry)
- [ ] Setup logging

**Acceptance Criteria:**
- Environment configured
- Monitoring working
- Errors tracked

**Dependencies:**
- All Phase 4 tasks

---

### 🔴 Task 5.2: Database Deployment
**Status:** To Do
**Priority:** Critical
**Estimated:** 4h
**Owner:** TBD

**Description:**
Deploy database to production.

**Subtasks:**
- [ ] Run migrations on staging
- [ ] Test in staging
- [ ] Run migrations on production
- [ ] Verify data integrity

**Acceptance Criteria:**
- Migrations successful
- No data loss
- Performance good

**Dependencies:**
- Task 5.1 (Environment Setup)

---

### 🔴 Task 5.3: Service Deployment
**Status:** To Do
**Priority:** Critical
**Estimated:** 6h
**Owner:** TBD

**Description:**
Deploy service to production.

**Subtasks:**
- [ ] Build production bundles
- [ ] Deploy to Railway/Vercel
- [ ] Configure DNS (if applicable)
- [ ] Test in production
- [ ] Monitor for errors

**Acceptance Criteria:**
- Deployment successful
- Service healthy
- No critical errors

**Dependencies:**
- Task 5.2 (Database Deployment)

---

### 🔴 Task 5.4: User Acceptance Testing
**Status:** To Do
**Priority:** High
**Estimated:** 8h
**Owner:** TBD

**Description:**
Conduct UAT with real users.

**Subtasks:**
- [ ] Define UAT scenarios
- [ ] Test with real users
- [ ] Collect feedback
- [ ] Fix critical issues
- [ ] Re-test

**Acceptance Criteria:**
- UAT passed
- Critical issues fixed
- Users satisfied

**Dependencies:**
- Task 5.3 (Service Deployment)

---

## 🚧 Blocked Tasks

None currently.

**Note:** If a task becomes blocked, move it here with explanation:
- ⚫ **Task Name** - Reason: [explanation] - Blocker: [what needs to happen]

---

## 📝 Notes

**Critical Path:**
1. Database schema (Tasks 1.1-1.3)
2. Core API endpoints (Task 2.1)
3. Main UI (Task 3.1, if applicable)
4. Testing (Tasks 4.1-4.3)
5. Deployment (Tasks 5.1-5.4)

**Shared Service Dependencies:**
- Check SPECS.md for required shared services
- Ensure they are implemented before dependent tasks

**Risk Items:**
- Document any known risks or challenges here

---

**Last Updated:** 2025-01-17
**Total Estimated Hours:** ~160h
**Target Completion:** TBD
**Current Status:** 🔴 Not Started (0% complete)
EOF

  ((count++))
done

echo ""
echo "✅ ROADMAP generation complete!"
echo "📊 Created $count ROADMAP.md files"
echo ""
echo "💡 Next: Review each ROADMAP.md and customize based on service complexity"
