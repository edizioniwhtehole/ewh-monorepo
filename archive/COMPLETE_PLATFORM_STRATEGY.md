# EWH Platform - Complete Integration Strategy

**Goal**: Full platform integration with all apps visible, authenticated, and configured

## Current Status

### ✅ Completed
- Platform audit done
- Templates created (frontend + backend)
- Auth service running (svc-auth on 4001)
- Shell running (app-shell-frontend on 3150)
- User management page exists
- Previz fully working
- PORT_ALLOCATION.md created

### 📊 Inventory
- **27 Frontend Apps** discovered
- **60+ Backend Services** exist
- **13 Apps** currently in services.config.ts
- **14 Apps** missing from shell configuration

## Phase 1: Shell Integration (CURRENT)

### Task: Add all 27 frontend apps to services.config.ts

**Apps to Add:**
1. app-photoediting (5850) - Design
2. app-raster-editor (5860) - Design
3. app-video-editor (5870) - Design
4. app-cms-frontend (5310) - Content
5. app-web-frontend (5320) - Content
6. app-layout-editor (5330) - Design
7. app-workflow-editor (5880) - Workflow
8. app-workflow-insights (5885) - Workflow
9. app-orchestrator-frontend (5890) - Workflow
10. app-settings-frontend (3650) - Admin
11. app-admin-console (3650) - Admin
12. app-crm-frontend (3310) - Communications ✅ ADDED

**Port Allocation Strategy:**
- Admin apps: 3000-3999
- Core services: 4000-4999
- Domain apps: 5000-5999
- Business apps: 6000-6999
- Extended apps: 7000-7999

### Implementation Steps:

1. **Update services.config.ts** with all missing apps
2. **Verify port conflicts** - some apps share ports
3. **Test shell navigation** - ensure all apps load in iframe
4. **Add settingsUrl** for each app

## Phase 2: Backend Services

### Task: Ensure all backends exist and respond with health endpoint

**Strategy:**
1. List all svc-* directories
2. For each directory:
   - If has content → Verify health endpoint exists
   - If empty → Apply template with "Hello World" message
   - Ensure port allocated in PORT_ALLOCATION.md

**Backend Categories:**
- Core: auth, api-gateway, search, billing
- Business: pm, inventory, procurement, orders, quotations
- Media: media, dam, image-orchestrator, video-orchestrator
- Content: cms, site-builder, site-publisher
- Communications: communications, voice, crm
- Workflow: approvals, workflow-tracker, orchestrator

## Phase 3: Authentication Integration

### Task: Add auth middleware to all backend services

**Auth Middleware Template:**
```typescript
import jwt from 'jsonwebtoken';

export function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    req.tenantId = decoded.tenantId;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
}
```

**Implementation:**
1. Add JWT verification to each service
2. Extract user + tenant from token
3. Add to request context
4. Protect all routes except /health and /

## Phase 4: Tenant Settings Pages

### Task: Create settings page for each app

**Template Structure:**
```
app-NAME/src/pages/settings/
  ├── index.tsx          (main settings page)
  ├── general.tsx        (general settings)
  ├── permissions.tsx    (user permissions)
  └── integrations.tsx   (API integrations)
```

**Settings Page Template:**
- Left sidebar: Categories (General, Permissions, Integrations, Advanced)
- Right content: Settings forms per category
- Save button: POST to backend /api/settings
- Tenant-scoped: All settings saved with tenant_id

**Backend Settings API:**
```
POST   /api/settings           - Save settings
GET    /api/settings           - Get settings
GET    /api/settings/schema    - Get settings schema
```

## Phase 5: Shell Settings Integration

### Task: Create unified settings view in shell

**Location:** app-shell-frontend/src/pages/settings.tsx

**Layout:**
```
┌─────────────────────────────────────────┐
│ Shell TopBar                            │
├──────────────┬──────────────────────────┤
│              │                          │
│  Sidebar     │  Settings Content        │
│              │                          │
│  [Projects]  │  ┌────────────────────┐ │
│  - PM        │  │ PM Settings        │ │
│  - Tasks     │  │                    │ │
│              │  │ General            │ │
│  [Media]     │  │ - Workspace name   │ │
│  - DAM       │  │ - Default view     │ │
│  - Upload    │  │                    │ │
│              │  │ Permissions        │ │
│  [Design]    │  │ - Admin users      │ │
│  - Previz    │  │ - Member access    │ │
│  - Box       │  │                    │ │
│              │  └────────────────────┘ │
└──────────────┴──────────────────────────┘
```

**Navigation:**
- Left sidebar: Apps grouped by category
- Click app → Load its settings page in iframe OR render inline
- URL: /settings/:category/:app

## Phase 6: Platform Admin Settings

### Task: Create owner/admin settings in app-admin-frontend

**Location:** app-admin-frontend/pages/admin/

**Pages Needed:**
1. **Platform Configuration**
   - Database settings
   - Redis/cache settings
   - Email/SMTP settings
   - Storage settings (S3, etc)

2. **Services Management**
   - Enable/disable services
   - Service health dashboard
   - Service logs viewer
   - API rate limits

3. **User Management** ✅ EXISTS
   - List users
   - Create/edit users
   - Assign roles
   - Manage memberships

4. **Organization Management**
   - List organizations
   - Create organizations
   - Feature packs assignment
   - Billing integration

5. **Security & Audit**
   - Audit logs viewer
   - Security settings
   - MFA enforcement
   - OAuth providers

6. **System Monitoring**
   - Resource usage
   - API metrics
   - Error tracking
   - Performance monitoring

**Layout:**
```
┌────────────────────────────────────────────┐
│ Admin TopBar                               │
├───────────────┬────────────────────────────┤
│               │                            │
│  Categories   │  Content                   │
│               │                            │
│  Platform     │  [Active Page Content]     │
│  - Config     │                            │
│  - Services   │                            │
│               │                            │
│  Users        │                            │
│  - Users      │                            │
│  - Orgs       │                            │
│               │                            │
│  Security     │                            │
│  - Audit      │                            │
│  - Settings   │                            │
│               │                            │
│  System       │                            │
│  - Monitor    │                            │
│  - Logs       │                            │
└───────────────┴────────────────────────────┘
```

## Implementation Order

### Week 1: Foundation
- [x] Day 1-2: Platform audit ✅
- [x] Day 3: Templates creation ✅
- [ ] Day 4-5: Phase 1 - Add all apps to shell
- [ ] Day 6-7: Phase 2 - Create/fix all backends

### Week 2: Integration
- [ ] Day 1-2: Phase 3 - Add auth to all services
- [ ] Day 3-4: Test all app → backend connections
- [ ] Day 5: Fix any integration issues
- [ ] Day 6-7: Phase 4 - Create settings pages (templates)

### Week 3: Settings & Admin
- [ ] Day 1-3: Phase 5 - Shell settings integration
- [ ] Day 4-6: Phase 6 - Admin platform settings
- [ ] Day 7: Testing & documentation

### Week 4: Polish & Deploy
- [ ] Day 1-2: End-to-end testing
- [ ] Day 3-4: Performance optimization
- [ ] Day 5: Security audit
- [ ] Day 6-7: Production deployment prep

## Success Metrics

- ✅ All 27 frontend apps visible in shell
- ✅ All apps authenticated via svc-auth
- ✅ All backends responding with health endpoint
- ✅ Each app has settings page
- ✅ Shell settings integration complete
- ✅ Admin platform settings complete
- ✅ All services can be started with one command
- ✅ Complete documentation

## Next Immediate Actions

1. **Now**: Update services.config.ts with missing 14 apps
2. **Next**: Create script to start all frontend apps
3. **Then**: Audit all svc-* directories for content
4. **After**: Apply templates to empty services
5. **Finally**: Add auth middleware script

---

**Current Phase**: Phase 1 - Shell Integration
**Status**: In Progress
**Completion**: 13/27 apps (48%)
