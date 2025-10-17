# 🧪 Widget Permissions System - Test Guide

## Quick Test Checklist

### ✅ Backend Tests

#### 1. Database Check
```bash
# Connect to database
psql -h localhost -U ewh -d ewh_master

# Check widgets
SELECT COUNT(*) FROM cms.widget_registry;
# Expected: 107

# Check by category
SELECT category, COUNT(*) FROM cms.widget_registry GROUP BY category;
# Expected: ecommerce=51, marketing=13, analytics=12, crm=12, social=7, etc.

# Check owner permissions
SELECT COUNT(*) FROM cms.owner_widget_permissions;
# Expected: 107

# Check permission tables exist
\dt cms.*permission*
# Expected: owner_widget_permissions, tenant_widget_permissions, user_widget_preferences, etc.
```

#### 2. API Tests
```bash
# Test health
curl http://localhost:5200/health
# Expected: {"status":"ok","service":"svc-cms"}

# Test widgets endpoint
curl http://localhost:5200/api/permissions/widgets | jq 'length'
# Expected: 107

# Test permission check
curl -X POST http://localhost:5200/api/permissions/widgets/check \
  -H "Content-Type: application/json" \
  -d '{
    "widgetSlug": "product-grid",
    "context": {
      "userId": "00000000-0000-0000-0000-000000000001",
      "tenantId": "00000000-0000-0000-0000-000000000002",
      "userRole": "USER",
      "pageContext": "public"
    }
  }'
# Expected: {"allowed":true,"config":{},"locked":false}

# Test available widgets
curl -X POST http://localhost:5200/api/permissions/widgets/available \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "userId": "00000000-0000-0000-0000-000000000001",
      "tenantId": "00000000-0000-0000-0000-000000000002",
      "userRole": "USER",
      "pageContext": "public"
    }
  }' | jq 'length'
# Expected: 107
```

### ✅ Frontend Tests

#### 1. Access God Mode Index
```
URL: http://localhost:3200/admin/god-mode
Expected:
- Dashboard with 10 feature cards
- "Widget Permissions" card visible with "107 widgets" badge
- Stats showing 107 total widgets
- Quick actions at bottom
```

#### 2. Access Widget Permissions Page
```
URL: http://localhost:3200/admin/god-mode/widget-permissions
Expected:
- Page title: "Widget Permissions"
- Stats cards: Total=107, Enabled=107, Disabled=0, System=107
- Search box
- Category filter dropdown
- Table with all 107 widgets
- Toggle switches for each widget
- Configure buttons
```

#### 3. Test Widget Permissions Features
```
1. Search:
   - Type "product" in search
   - Should filter to e-commerce widgets

2. Category Filter:
   - Select "ecommerce"
   - Should show 51 widgets

3. Toggle Enable/Disable:
   - Click toggle on any widget
   - Should call API and update state

4. View Widget Details:
   - Check widget has thumbnail/icon
   - Check category badge
   - Check enabled status indicator
```

### ✅ Integration Tests

#### 1. Permission Flow Test
```typescript
// Test complete permission resolution

// Step 1: Owner enables widget
PUT /api/permissions/owner/widgets/product-grid
{
  "enabled_globally": true,
  "allowed_contexts": ["public", "tenant"]
}

// Step 2: Check permission for user
POST /api/permissions/widgets/check
{
  "widgetSlug": "product-grid",
  "context": {
    "userId": "test-user-uuid",
    "tenantId": "test-tenant-uuid",
    "userRole": "USER",
    "pageContext": "public"
  }
}

// Expected: allowed=true

// Step 3: Owner disables widget
PUT /api/permissions/owner/widgets/product-grid
{
  "enabled_globally": false
}

// Step 4: Check permission again
// Expected: allowed=false, reason="Widget disabled by platform owner"
```

#### 2. Tenant Permission Test
```typescript
// Step 1: Get tenant permissions
GET /api/permissions/tenant/{tenantId}/widgets

// Expected: List of widgets with tenant settings

// Step 2: Update tenant permission
PUT /api/permissions/tenant/{tenantId}/widgets/product-grid
{
  "enabled_for_tenant": true,
  "allowed_roles": ["ADMIN", "MANAGER"],
  "config_locked": true
}

// Step 3: Check permission as USER
// Expected: allowed=false, reason="Role USER not allowed"

// Step 4: Check permission as ADMIN
// Expected: allowed=true, locked=true
```

### ✅ React Hooks Test

```typescript
// Test in a React component

import { useAvailableWidgets } from '@ewh/shared-hooks';

function TestComponent() {
  const { widgets, loading, error } = useAvailableWidgets({
    userId: 'test-user',
    tenantId: 'test-tenant',
    userRole: 'USER',
    pageContext: 'public'
  });

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      <h1>Available Widgets: {widgets.length}</h1>
      {widgets.map(w => (
        <div key={w.widgetSlug}>
          {w.widgetName} - {w.category}
        </div>
      ))}
    </div>
  );
}
```

### ✅ ElementorBuilder Integration Test

```typescript
// Test ElementorBuilder with permissions

import { ElementorBuilderWithPermissions } from '@ewh/page-builder';

function PageEditor() {
  const context = {
    userId: 'test-user',
    tenantId: 'test-tenant',
    userRole: 'USER',
    pageContext: 'public'
  };

  return (
    <ElementorBuilderWithPermissions
      page={testPage}
      onSave={handleSave}
      context="public"
      permissionContext={context}
    />
  );
}

// Expected:
// - Builder loads with permission filtering
// - Only allowed widgets appear in sidebar
// - Drag & drop works
// - Config is pre-populated
```

## 🐛 Troubleshooting

### Backend Issues

**Problem:** API returns 0 widgets
```bash
# Solution: Check svc-cms is running
curl http://localhost:5200/health

# If not running, restart:
cd /Users/andromeda/dev/ewh/svc-cms
npm run dev
```

**Problem:** Permission check fails
```bash
# Solution: Check function exists in database
psql -h localhost -U ewh -d ewh_master -c "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'cms' AND routine_name LIKE '%permission%';"

# Expected: check_widget_permission, get_available_widgets
```

**Problem:** UUIDs cause errors
```bash
# Solution: Use valid UUID format
00000000-0000-0000-0000-000000000001

# Not: "test-user" or "user-123"
```

### Frontend Issues

**Problem:** Page not found (404)
```bash
# Solution: Check file exists
ls -la /Users/andromeda/dev/ewh/app-admin-frontend/pages/admin/god-mode/widget-permissions.tsx

# Restart Next.js dev server
cd /Users/andromeda/dev/ewh/app-admin-frontend
npm run dev
```

**Problem:** No data loading
```bash
# Solution: Check CORS and API URL
# Verify in browser console:
# - API calls going to http://localhost:5200
# - CORS headers present
# - No 403/401 errors
```

**Problem:** Hooks not working
```bash
# Solution: Check hooks are installed
cd /Users/andromeda/dev/ewh/shared/hooks
npm install

# Link to app
cd /Users/andromeda/dev/ewh/app-admin-frontend
npm link ../shared/hooks
```

## 📊 Expected Results

After all tests pass, you should have:

✅ **Database**
- 107 widgets in cms.widget_registry
- 107 owner permissions in cms.owner_widget_permissions
- All permission tables created and indexed

✅ **Backend**
- svc-cms running on port 5200
- 11 API endpoints responding
- Permission checks working correctly
- Configuration merging functional

✅ **Frontend**
- God Mode index page with 10 features
- Widget Permissions page with full functionality
- Search, filter, and toggle working
- Stats dashboard showing correct counts

✅ **Integration**
- Permission resolution working (owner → tenant → user)
- React hooks returning correct data
- ElementorBuilder filtering widgets by permissions
- Configuration locking functional

## 🎯 Success Criteria

The system is working correctly if:

1. ✅ You can access http://localhost:3200/admin/god-mode
2. ✅ Widget Permissions page shows 107 widgets
3. ✅ API endpoint returns widget list
4. ✅ Permission check returns correct allowed/denied
5. ✅ Toggling widget updates database
6. ✅ Filters work (search, category, status)
7. ✅ Stats are accurate
8. ✅ No console errors in browser
9. ✅ No API errors (check Network tab)
10. ✅ Database queries execute successfully

## 🚀 Quick Verification

Run this one-liner to verify everything:

```bash
# Full system check
echo "=== Database ===" && \
psql -h localhost -U ewh -d ewh_master -c "SELECT COUNT(*) as widgets FROM cms.widget_registry;" && \
echo "=== Backend ===" && \
curl -s http://localhost:5200/health && echo && \
echo "=== API Test ===" && \
curl -s http://localhost:5200/api/permissions/widgets | python3 -c "import sys, json; print(f'Widgets: {len(json.load(sys.stdin))}')" && \
echo "=== Files ===" && \
ls -l /Users/andromeda/dev/ewh/app-admin-frontend/pages/admin/god-mode/widget-permissions.tsx && \
echo "✅ All checks passed!"
```

If all checks pass, the system is ready! 🎉
