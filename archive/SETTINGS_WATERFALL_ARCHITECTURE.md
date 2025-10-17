# ⚙️ Settings Waterfall Architecture

## Sistema Gerarchico Impostazioni a Cascata

---

## 🌊 WATERFALL PRINCIPLE

```
ADMIN (Owner)
    ↓ (can lock/force)
TENANT (Organization)
    ↓ (can lock/force)
USER (Individual)
    ↓ (can customize)
LOCAL (Session/Context)
```

**Principio**: Ogni livello eredita dal superiore e può override se non locked.

---

## 📋 4-TIER SETTINGS SYSTEM

### Tier 1: Admin Settings (Platform Owner)
**Path:** `/admin/settings`
**Frontend:** `app-admin-frontend` / `web-admin-frontend`
**Access:** Owner only
**Scope:** Platform-wide

**Capabilities:**
- Configure platform defaults
- Set tenant quotas/limits
- Enable/disable features globally
- Lock settings to prevent tenant override
- Manage billing & subscriptions
- View system health
- Configure webhooks
- Manage API keys

**Example Settings:**
```json
{
  "platform": {
    "max_users_per_tenant": 50,
    "max_projects_per_tenant": 1000,
    "features_enabled": ["pm", "crm", "inventory"],
    "features_locked": true  // tenants cannot disable
  },
  "defaults": {
    "language": "it",
    "timezone": "Europe/Rome",
    "currency": "EUR",
    "date_format": "DD/MM/YYYY"
  },
  "branding": {
    "platform_name": "EWH Platform",
    "logo_url": "https://...",
    "primary_color": "#1f6feb",
    "allow_tenant_branding": true,
    "tenant_branding_locked": false
  },
  "security": {
    "require_2fa": false,
    "password_min_length": 8,
    "session_timeout_minutes": 60,
    "settings_locked": true  // tenants cannot change
  }
}
```

### Tier 2: Tenant Settings (Organization)
**Path:** `/settings`
**Frontend:** `app-*-frontend` (ogni app)
**Access:** Tenant admin/owner
**Scope:** Organization-wide

**Capabilities:**
- Customize organization settings
- Set user defaults
- Enable/disable features (if not locked by admin)
- Configure workflows
- Manage team members (if team mode)
- Lock settings to prevent user override
- Configure integrations

**Example Settings:**
```json
{
  "tenant": {
    "id": "uuid",
    "company_name": "Acme Corp",
    "logo_url": "https://...",
    "primary_color": "#ff6b35"  // override se allow_tenant_branding=true
  },
  "defaults": {
    "language": "en",  // override platform default
    "timezone": "America/New_York",
    "currency": "USD",
    "settings_locked": false  // users can override
  },
  "features": {
    "pm_enabled": true,
    "crm_enabled": true,
    "inventory_enabled": false,  // disabled for this tenant
    "allow_user_override": false
  },
  "workflows": {
    "project_approval_required": true,
    "task_auto_assignment": true,
    "time_tracking_mandatory": true,
    "users_can_customize": false  // locked
  },
  "notifications": {
    "email_notifications": true,
    "slack_webhook": "https://hooks.slack.com/...",
    "notification_defaults": {
      "task_assigned": true,
      "task_completed": true,
      "users_can_override": true  // users can customize
    }
  }
}
```

### Tier 3: User Settings (Individual)
**Path:** `/user/settings`
**Frontend:** Ogni app, profilo utente
**Access:** Logged-in user
**Scope:** User-specific

**Capabilities:**
- Personal preferences
- Override tenant defaults (if not locked)
- Custom views/layouts
- Notification preferences
- Keyboard shortcuts
- Theme (light/dark)
- Create local presets

**Example Settings:**
```json
{
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@acme.com",
    "avatar_url": "https://..."
  },
  "preferences": {
    "language": "fr",  // override tenant default se settings_locked=false
    "timezone": "Europe/Paris",
    "theme": "dark",
    "date_format": "DD/MM/YYYY"
  },
  "notifications": {
    "email_notifications": false,  // override se users_can_override=true
    "task_assigned": true,
    "task_completed": false,
    "push_notifications": true
  },
  "views": {
    "default_pm_view": "kanban",  // vs gantt/list
    "sidebar_collapsed": false,
    "compact_mode": true
  },
  "keyboard_shortcuts": {
    "quick_task": "Ctrl+K",
    "search": "Ctrl+P",
    "custom_shortcuts": [...]
  }
}
```

### Tier 4: Local Settings (Session/Context)
**Path:** LocalStorage / SessionStorage / Context
**Frontend:** Runtime state
**Access:** Current session
**Scope:** Temporary, not persisted to DB

**Capabilities:**
- Current view state
- Filters applied
- Sorting preferences
- Column visibility
- Sidebar state
- Modal states
- Form drafts (auto-save)

**Example Settings:**
```json
{
  "session": {
    "current_project_filter": "active",
    "task_sort_by": "due_date",
    "task_sort_order": "asc",
    "columns_visible": ["title", "assignee", "due_date"],
    "sidebar_expanded": true
  },
  "drafts": {
    "new_project_form": {
      "title": "Draft project...",
      "description": "..."
    }
  }
}
```

---

## 🔒 LOCKING MECHANISM

### Lock Types:

1. **Hard Lock** (cannot override)
```json
{
  "feature_x": {
    "enabled": true,
    "locked": true  // users/tenants CANNOT change
  }
}
```

2. **Soft Lock** (can override with warning)
```json
{
  "feature_x": {
    "enabled": true,
    "locked": "soft",  // warning shown, but can override
    "lock_message": "Recommended by admin"
  }
}
```

3. **Unlocked** (free override)
```json
{
  "feature_x": {
    "enabled": true,
    "locked": false  // complete freedom
  }
}
```

---

## 🏗️ DATABASE SCHEMA

### Platform-wide Settings (Admin)
```sql
CREATE TABLE platform_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key VARCHAR(255) UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  value_type VARCHAR(50),  -- 'string', 'number', 'boolean', 'object'
  is_locked BOOLEAN DEFAULT false,
  lock_type VARCHAR(20) DEFAULT 'none',  -- 'none', 'hard', 'soft'
  lock_message TEXT,
  category VARCHAR(100),  -- 'security', 'features', 'branding', etc.
  description TEXT,
  updated_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_platform_settings_key ON platform_settings(setting_key);
CREATE INDEX idx_platform_settings_category ON platform_settings(category);
```

### Tenant Settings
```sql
CREATE TABLE tenant_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  inherits_from VARCHAR(50) DEFAULT 'platform',  -- 'platform', 'none'
  override_platform BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,  -- lock for users
  lock_type VARCHAR(20) DEFAULT 'none',
  lock_message TEXT,
  category VARCHAR(100),
  updated_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, setting_key)
);

CREATE INDEX idx_tenant_settings_tenant ON tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_key ON tenant_settings(setting_key);
```

### User Settings
```sql
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  inherits_from VARCHAR(50) DEFAULT 'tenant',  -- 'tenant', 'platform', 'none'
  override_tenant BOOLEAN DEFAULT false,
  override_platform BOOLEAN DEFAULT false,
  category VARCHAR(100),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tenant_id, setting_key)
);

CREATE INDEX idx_user_settings_user ON user_settings(user_id);
CREATE INDEX idx_user_settings_tenant ON user_settings(tenant_id);
```

---

## 🔍 SETTINGS RESOLUTION ALGORITHM

```typescript
function resolveSettings(
  key: string,
  userId?: string,
  tenantId?: string
): SettingValue {
  // Step 1: Get platform default
  const platformSetting = await getPlatformSetting(key);
  let value = platformSetting.value;
  let isLocked = platformSetting.is_locked;

  // Step 2: Apply tenant override (if not locked)
  if (tenantId && !isLocked) {
    const tenantSetting = await getTenantSetting(tenantId, key);
    if (tenantSetting && tenantSetting.override_platform) {
      value = tenantSetting.value;
      isLocked = tenantSetting.is_locked;
    }
  }

  // Step 3: Apply user override (if not locked)
  if (userId && !isLocked) {
    const userSetting = await getUserSetting(userId, key);
    if (userSetting && userSetting.override_tenant) {
      value = userSetting.value;
    }
  }

  return {
    value,
    source: isLocked ? 'locked' : 'inherited',
    can_override: !isLocked
  };
}
```

---

## 📄 STANDARD PAGES FOR EVERY APP

### 1. `/admin/dev` - Technical Documentation
**Access:** Owner only (via `x-platform-role: owner`)
**Purpose:** API endpoints, webhooks, technical docs

**Content:**
- Service name, version, status
- All API endpoints with examples
- Webhook events and payloads
- cURL examples
- OpenAPI spec link
- Health check status

**Template:**
```typescript
// Every service: src/routes/admin-dev.ts
fastify.get('/admin/dev', requireOwner, async (req, reply) => {
  reply.html(generateDevPage({
    service: 'svc-pm',
    endpoints: [...],
    webhooks: [...]
  }));
});
```

### 2. `/settings` - Tenant Settings
**Access:** Tenant admin
**Purpose:** Organization-wide configuration

**Sections:**
```
/settings/general        → Company info, branding
/settings/features       → Enable/disable modules
/settings/users          → Team management (if team mode)
/settings/integrations   → Webhooks, API keys, external services
/settings/notifications  → Email, Slack defaults
/settings/workflows      → Custom workflows
/settings/billing        → Subscription, usage (if SaaS)
```

**Template:**
```typescript
// app-*/src/pages/settings/index.tsx
export default function TenantSettings() {
  const { tenant } = useTenant();
  const { settings, updateSetting } = useTenantSettings();

  return (
    <SettingsLayout>
      <Section title="General">
        <Input
          label="Company Name"
          value={settings.company_name}
          onChange={(v) => updateSetting('company_name', v)}
          locked={settings.company_name_locked}
        />
      </Section>
    </SettingsLayout>
  );
}
```

### 3. `/admin/settings` - Platform Admin Settings
**Access:** Owner only
**Frontend:** `web-admin-frontend`
**Purpose:** Platform-wide configuration

**Sections:**
```
/admin/settings/platform     → Platform defaults
/admin/settings/tenants      → Tenant management, quotas
/admin/settings/security     → Security policies
/admin/settings/features     → Feature flags
/admin/settings/billing      → Billing configuration
/admin/settings/services     → Service registry, health
```

### 4. `/user/settings` - User Preferences
**Access:** Any logged-in user
**Purpose:** Personal preferences

**Sections:**
```
/user/settings/profile       → Name, avatar, email
/user/settings/preferences   → Language, theme, timezone
/user/settings/notifications → Personal notification preferences
/user/settings/shortcuts     → Keyboard shortcuts
/user/settings/views         → Default views, layouts
```

---

## 🔌 API ENDPOINTS

### Admin Settings API
```
GET    /api/admin/settings                    # List all platform settings
GET    /api/admin/settings/:key               # Get specific setting
PUT    /api/admin/settings/:key               # Update setting
DELETE /api/admin/settings/:key               # Delete setting (reset to default)
POST   /api/admin/settings/:key/lock          # Lock setting
POST   /api/admin/settings/:key/unlock        # Unlock setting
```

### Tenant Settings API
```
GET    /api/settings                          # List tenant settings
GET    /api/settings/:key                     # Get specific setting
PUT    /api/settings/:key                     # Update setting
POST   /api/settings/:key/reset               # Reset to platform default
GET    /api/settings/:key/effective           # Get resolved value (with inheritance)
```

### User Settings API
```
GET    /api/user/settings                     # List user settings
GET    /api/user/settings/:key                # Get specific setting
PUT    /api/user/settings/:key                # Update setting
POST   /api/user/settings/:key/reset          # Reset to tenant default
```

---

## 🎨 UI COMPONENTS

### Lock Indicator
```tsx
function SettingField({ setting, value, onChange }) {
  const isLocked = setting.locked;
  const canOverride = !isLocked || setting.lock_type === 'soft';

  return (
    <div className="setting-field">
      <label>{setting.label}</label>
      {isLocked && (
        <Badge variant="locked">
          🔒 {setting.lock_type === 'hard' ? 'Locked by Admin' : 'Recommended'}
        </Badge>
      )}
      <Input
        value={value}
        onChange={onChange}
        disabled={isLocked && setting.lock_type === 'hard'}
      />
      {canOverride && setting.lock_message && (
        <Alert variant="warning">{setting.lock_message}</Alert>
      )}
    </div>
  );
}
```

### Inheritance Indicator
```tsx
function SettingInheritance({ setting, value, source }) {
  return (
    <div className="setting-inheritance">
      <div className="value">{value}</div>
      <div className="source">
        {source === 'platform' && '← From Platform Default'}
        {source === 'tenant' && '← From Organization'}
        {source === 'user' && '✓ Your Custom Value'}
      </div>
      {source !== 'user' && (
        <Button onClick={overrideValue}>Override</Button>
      )}
    </div>
  );
}
```

---

## 📦 IMPLEMENTATION CHECKLIST

### For EVERY Service:

- [ ] Create `/admin/dev` route (owner only)
- [ ] Create `/admin/dev/api` endpoint (service registry)
- [ ] Create dev documentation page
- [ ] List all endpoints with examples
- [ ] List all webhooks with payloads
- [ ] Add health check endpoint
- [ ] Create settings tables in DB
- [ ] Create `/api/settings` endpoints
- [ ] Implement settings resolution algorithm
- [ ] Add lock/unlock functionality
- [ ] Add inheritance tracking

### For EVERY Frontend:

- [ ] Create `/settings` page (tenant)
- [ ] Create `/user/settings` page
- [ ] Create settings context/provider
- [ ] Implement lock indicator UI
- [ ] Implement inheritance indicator
- [ ] Add reset to default button
- [ ] Add override functionality
- [ ] Show effective values
- [ ] Add validation
- [ ] Add confirmation dialogs

### For web-admin-frontend:

- [ ] Create `/admin/settings` section
- [ ] Create `/admin/services` dashboard
- [ ] List all services with status
- [ ] Link to each service's `/admin/dev`
- [ ] Show service health
- [ ] Platform-wide settings editor
- [ ] Lock/unlock controls
- [ ] Tenant quota management

---

## 🚀 MIGRATION PLAN

### Phase 1: Add to Existing Services
1. svc-pm → add all 4 tiers
2. svc-procurement → add all 4 tiers
3. svc-quotations → add all 4 tiers
4. app-pm-frontend → add settings pages
5. app-procurement-frontend → add settings pages
6. app-quotations-frontend → add settings pages

### Phase 2: New Services Start With This
All new services (inventory, orders, pricelists, AI, MRP) will be created with:
- Settings tables
- 4-tier system
- Lock mechanism
- All 4 standard pages

### Phase 3: Admin Frontend
1. Create `/admin/settings` in web-admin-frontend
2. Create `/admin/services` dashboard
3. Aggregate all service registries
4. Show platform health
5. Manage global locks

---

## 📖 EXAMPLE: Complete Flow

### Scenario: Project Approval Workflow

**Admin (Platform) sets:**
```json
{
  "workflow.project_approval_required": {
    "value": false,
    "locked": false,
    "description": "Platform default: no approval needed"
  }
}
```

**Tenant (Acme Corp) overrides:**
```json
{
  "workflow.project_approval_required": {
    "value": true,  // override to true
    "locked": true,  // lock for users
    "lock_message": "Company policy requires approval"
  }
}
```

**User (John) tries to override:**
```
❌ Cannot override - locked by organization
💡 Shows lock message: "Company policy requires approval"
```

**Result:**
- John MUST get approval for all projects
- Cannot disable it
- Clear reason shown

---

## ✅ BENEFITS

1. **Flexibility**: Each level can customize
2. **Control**: Admin can enforce policies
3. **Transparency**: Users see why settings are locked
4. **Scalability**: Easy to add new settings
5. **Consistency**: Same pattern across all apps
6. **Compliance**: Enforce security/legal requirements
7. **User Experience**: Personal customization where allowed

---

*This architecture will be gradually implemented in all existing and future services.*
