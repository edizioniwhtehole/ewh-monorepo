# 🔌 Shell Service Integration - Complete Architecture
## Architettura Completa Integrazione Servizi nella Shell

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Obiettivo

**Problema Attuale**:
- Frontend ha lista hardcoded di servizi in `services.config.ts`
- Backend ha `service_registry` table nel database
- **NON SONO SINCRONIZZATI** ❌

**Soluzione**:
- Frontend carica servizi dinamicamente da API backend
- Backend legge da `service_registry` (ewh_master)
- Tenant può abilitare/disabilitare servizi
- Auto-discovery di nuovi servizi

---

## 📊 Database Schema (ewh_master)

### service_registry (Già Definito)

```sql
-- Registry of all available services in the platform
CREATE TABLE service_registry (
  id SERIAL PRIMARY KEY,
  service_id VARCHAR(100) NOT NULL UNIQUE, -- 'app-pm-frontend', 'svc-pm', etc.
  service_name VARCHAR(255) NOT NULL,
  service_type VARCHAR(50) NOT NULL, -- 'frontend', 'backend'
  category VARCHAR(100), -- 'projects', 'content', 'media', 'workflow', 'design', 'business', 'communications', 'admin'
  icon VARCHAR(50), -- Lucide icon name
  url_pattern VARCHAR(500), -- 'http://localhost:{PORT}' or 'http://localhost:5400'
  description TEXT,
  port INTEGER,
  health_check_url VARCHAR(500),
  documentation_url VARCHAR(500),
  is_core BOOLEAN DEFAULT false, -- Core services can't be disabled
  default_enabled BOOLEAN DEFAULT true,
  requires_auth BOOLEAN DEFAULT true,
  default_roles JSONB, -- ["TENANT_ADMIN", "USER"]
  settings_url VARCHAR(500), -- URL to service-specific settings panel
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_service_registry_category ON service_registry(category);
CREATE INDEX idx_service_registry_type ON service_registry(service_type);
CREATE INDEX idx_service_registry_enabled ON service_registry(default_enabled);
```

### service_categories (Nuovo)

```sql
-- Service categories for organization
CREATE TABLE service_categories (
  id VARCHAR(50) PRIMARY KEY, -- 'projects', 'content', etc.
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(50) NOT NULL, -- Lucide icon name
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default categories
INSERT INTO service_categories (id, name, icon, description, sort_order) VALUES
  ('projects', 'Projects', 'Kanban', 'Project Management & Collaboration', 10),
  ('content', 'Content', 'FileText', 'Content Management & Publishing', 20),
  ('media', 'Media', 'Image', 'Digital Asset Management', 30),
  ('workflow', 'Workflow', 'GitBranch', 'Approvals & Collaboration', 40),
  ('design', 'Design', 'Palette', 'Visual Design Tools', 50),
  ('business', 'Business', 'Briefcase', 'Orders, Inventory & Operations', 60),
  ('communications', 'Communications', 'MessageSquare', 'Voice, Email, Messaging & CRM', 70),
  ('admin', 'Admin', 'Settings', 'Platform & Tenant Administration', 80);
```

### tenant_services (Già Definito)

```sql
-- Tenant-level service enablement
CREATE TABLE tenant_services (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  service_id INTEGER NOT NULL REFERENCES service_registry(id),
  is_enabled BOOLEAN DEFAULT true,
  configuration JSONB, -- Service-specific config
  custom_url VARCHAR(500), -- Override default URL if needed
  custom_icon VARCHAR(50), -- Override icon
  custom_label VARCHAR(255), -- Override display name
  enabled_at TIMESTAMPTZ,
  enabled_by INTEGER REFERENCES users(id),
  disabled_at TIMESTAMPTZ,
  disabled_by INTEGER REFERENCES users(id),
  UNIQUE(tenant_id, service_id)
);

CREATE INDEX idx_tenant_services_tenant ON tenant_services(tenant_id);
CREATE INDEX idx_tenant_services_enabled ON tenant_services(is_enabled);
```

### user_service_preferences (Già Definito)

```sql
-- User-level service preferences (pinning, custom labels, etc.)
CREATE TABLE user_service_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_id INTEGER NOT NULL REFERENCES service_registry(id),
  is_pinned BOOLEAN DEFAULT false,
  is_favorite BOOLEAN DEFAULT false,
  custom_label VARCHAR(255),
  sort_order INTEGER,
  recent_used_at TIMESTAMPTZ,
  usage_count INTEGER DEFAULT 0,
  UNIQUE(user_id, service_id)
);

CREATE INDEX idx_user_service_prefs_user ON user_service_preferences(user_id);
CREATE INDEX idx_user_service_prefs_pinned ON user_service_preferences(is_pinned);
CREATE INDEX idx_user_service_prefs_recent ON user_service_preferences(recent_used_at DESC);
```

---

## 🔌 Backend API (svc-service-registry)

### New Service: svc-service-registry

**Port**: 5960
**Database**: ewh_master
**Purpose**: Manage service registry and provide APIs for shell

### API Endpoints

#### 1. Get Services for Shell

```http
GET /api/v1/services
Authorization: Bearer {token}
X-Tenant-ID: {tenantId}
```

**Query Params**:
- `type` (optional): 'frontend' | 'backend'
- `category` (optional): category ID
- `enabled_only` (optional): boolean (default: true)

**Response**:
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": "projects",
        "name": "Projects",
        "icon": "Kanban",
        "description": "Project Management & Collaboration",
        "sortOrder": 10
      },
      {
        "id": "content",
        "name": "Content",
        "icon": "FileText",
        "description": "Content Management & Publishing",
        "sortOrder": 20
      }
    ],
    "services": [
      {
        "id": "app-pm-frontend",
        "name": "Project Management",
        "icon": "LayoutDashboard",
        "url": "http://localhost:5400",
        "description": "Project overview and analytics",
        "category": "projects",
        "type": "frontend",
        "requiresAuth": true,
        "roles": ["TENANT_ADMIN", "USER"],
        "isEnabled": true,
        "isPinned": false,
        "isFavorite": false,
        "settingsUrl": "http://localhost:5400/settings",
        "apps": [
          {
            "id": "pm-dashboard",
            "name": "Dashboard",
            "icon": "LayoutDashboard",
            "url": "http://localhost:5400",
            "description": "Project overview"
          },
          {
            "id": "pm-projects",
            "name": "Projects",
            "icon": "FolderKanban",
            "url": "http://localhost:5400/projects",
            "description": "All project boards"
          }
        ]
      }
    ]
  }
}
```

#### 2. Get Service by ID

```http
GET /api/v1/services/:serviceId
Authorization: Bearer {token}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "app-pm-frontend",
    "name": "Project Management",
    "icon": "LayoutDashboard",
    "url": "http://localhost:5400",
    "description": "Complete project management suite",
    "category": "projects",
    "type": "frontend",
    "port": 5400,
    "healthCheckUrl": "http://localhost:5400/health",
    "documentationUrl": "/docs/pm",
    "isCore": false,
    "isEnabled": true,
    "requiresAuth": true,
    "roles": ["TENANT_ADMIN", "USER"],
    "configuration": {
      "maxProjects": 100,
      "features": ["kanban", "gantt", "calendar"]
    }
  }
}
```

#### 3. Enable/Disable Service (Tenant Admin)

```http
POST /api/v1/services/:serviceId/toggle
Authorization: Bearer {token}
X-Tenant-ID: {tenantId}
Content-Type: application/json

{
  "isEnabled": true,
  "configuration": {
    "maxProjects": 200
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "serviceId": "app-pm-frontend",
    "isEnabled": true,
    "enabledAt": "2025-10-15T10:30:00Z",
    "enabledBy": "Admin User"
  }
}
```

#### 4. Update User Preferences

```http
PUT /api/v1/services/:serviceId/preferences
Authorization: Bearer {token}
Content-Type: application/json

{
  "isPinned": true,
  "isFavorite": true,
  "customLabel": "My PM"
}
```

#### 5. Register New Service (Platform Admin)

```http
POST /api/v1/admin/services
Authorization: Bearer {token}
X-User-Role: PLATFORM_ADMIN
Content-Type: application/json

{
  "serviceId": "app-new-service",
  "serviceName": "New Service",
  "serviceType": "frontend",
  "category": "business",
  "icon": "Package",
  "urlPattern": "http://localhost:6500",
  "description": "Description of service",
  "port": 6500,
  "healthCheckUrl": "http://localhost:6500/health",
  "isCore": false,
  "defaultEnabled": true,
  "requiresAuth": true,
  "defaultRoles": ["USER"]
}
```

#### 6. Service Health Check

```http
GET /api/v1/services/health
Authorization: Bearer {token}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "total": 25,
    "healthy": 23,
    "unhealthy": 2,
    "services": [
      {
        "id": "app-pm-frontend",
        "name": "Project Management",
        "status": "healthy",
        "responseTime": 45,
        "lastChecked": "2025-10-15T10:35:00Z"
      },
      {
        "id": "svc-inventory",
        "name": "Inventory Service",
        "status": "unhealthy",
        "error": "Connection timeout",
        "lastChecked": "2025-10-15T10:35:00Z"
      }
    ]
  }
}
```

---

## 🎨 Frontend Integration (app-shell-frontend)

### 1. API Client

```typescript
// src/api/services.ts

import { apiClient } from '@ewh/api-client';

export interface ServiceCategory {
  id: string;
  name: string;
  icon: string;
  description: string;
  sortOrder: number;
}

export interface ServiceApp {
  id: string;
  name: string;
  icon: string;
  url: string;
  description: string;
  category: string;
  type: 'frontend' | 'backend';
  requiresAuth: boolean;
  roles?: string[];
  isEnabled: boolean;
  isPinned: boolean;
  isFavorite: boolean;
  settingsUrl?: string;
  apps?: SubApp[];
}

export interface SubApp {
  id: string;
  name: string;
  icon: string;
  url: string;
  description: string;
}

/**
 * Get all services available for current tenant and user
 */
export async function getServices(params?: {
  type?: 'frontend' | 'backend';
  category?: string;
  enabledOnly?: boolean;
}) {
  return apiClient.get<{
    categories: ServiceCategory[];
    services: ServiceApp[];
  }>('/api/v1/services', params);
}

/**
 * Get service by ID
 */
export async function getServiceById(serviceId: string) {
  return apiClient.get<ServiceApp>(`/api/v1/services/${serviceId}`);
}

/**
 * Toggle service enabled/disabled (Tenant Admin only)
 */
export async function toggleService(serviceId: string, isEnabled: boolean, configuration?: any) {
  return apiClient.post(`/api/v1/services/${serviceId}/toggle`, {
    isEnabled,
    configuration,
  });
}

/**
 * Update user preferences for service
 */
export async function updateServicePreferences(
  serviceId: string,
  preferences: {
    isPinned?: boolean;
    isFavorite?: boolean;
    customLabel?: string;
  }
) {
  return apiClient.put(`/api/v1/services/${serviceId}/preferences`, preferences);
}

/**
 * Get service health status
 */
export async function getServicesHealth() {
  return apiClient.get('/api/v1/services/health');
}
```

### 2. React Hooks

```typescript
// src/hooks/useServices.ts

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getServices, updateServicePreferences } from '@/api/services';

/**
 * Hook to fetch services
 */
export function useServices(params?: { type?: string; category?: string }) {
  return useQuery({
    queryKey: ['services', params],
    queryFn: () => getServices(params),
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchOnWindowFocus: false,
  });
}

/**
 * Hook to update service preferences (pin, favorite, etc.)
 */
export function useUpdateServicePreferences() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      serviceId,
      preferences,
    }: {
      serviceId: string;
      preferences: { isPinned?: boolean; isFavorite?: boolean };
    }) => updateServicePreferences(serviceId, preferences),
    onSuccess: () => {
      // Invalidate services cache
      queryClient.invalidateQueries({ queryKey: ['services'] });
    },
  });
}
```

### 3. Shell Components Update

```typescript
// src/components/Shell/ServiceMenu.tsx

import { useServices } from '@/hooks/useServices';
import { Loader2 } from 'lucide-react';

export function ServiceMenu() {
  const { data, isLoading, error } = useServices({ type: 'frontend', enabledOnly: true });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-4">
        <Loader2 className="h-6 w-6 animate-spin" />
        <span className="ml-2">Loading services...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-4 text-red-600">
        Error loading services. Please refresh the page.
      </div>
    );
  }

  const { categories, services } = data?.data || { categories: [], services: [] };

  return (
    <div className="space-y-4">
      {/* Top Bar - Categories */}
      <div className="flex space-x-2 overflow-x-auto">
        {categories.map((category) => (
          <button
            key={category.id}
            className="flex items-center space-x-2 px-4 py-2 rounded-lg hover:bg-gray-100"
          >
            <Icon name={category.icon} />
            <span>{category.name}</span>
          </button>
        ))}
      </div>

      {/* Sidebar - Services */}
      <div className="space-y-1">
        {services.map((service) => (
          <ServiceItem key={service.id} service={service} />
        ))}
      </div>
    </div>
  );
}

function ServiceItem({ service }: { service: ServiceApp }) {
  const updatePreferences = useUpdateServicePreferences();

  const handlePin = () => {
    updatePreferences.mutate({
      serviceId: service.id,
      preferences: { isPinned: !service.isPinned },
    });
  };

  return (
    <div className="group flex items-center justify-between p-2 rounded hover:bg-gray-100">
      <a
        href={service.url}
        target="_blank"
        rel="noopener noreferrer"
        className="flex items-center space-x-3 flex-1"
      >
        <Icon name={service.icon} className="h-5 w-5" />
        <div className="flex-1">
          <div className="font-medium">{service.name}</div>
          <div className="text-xs text-gray-500">{service.description}</div>
        </div>
      </a>

      {/* Actions */}
      <div className="flex items-center space-x-2 opacity-0 group-hover:opacity-100 transition-opacity">
        <button
          onClick={handlePin}
          className={`p-1 rounded hover:bg-gray-200 ${service.isPinned ? 'text-blue-600' : ''}`}
          title={service.isPinned ? 'Unpin' : 'Pin'}
        >
          <Pin className="h-4 w-4" />
        </button>

        {service.settingsUrl && (
          <a
            href={service.settingsUrl}
            target="_blank"
            className="p-1 rounded hover:bg-gray-200"
            title="Settings"
          >
            <Settings className="h-4 w-4" />
          </a>
        )}
      </div>
    </div>
  );
}
```

### 4. Migration Strategy

```typescript
// src/lib/services.config.ts (DEPRECATED)

// ⚠️ This file is DEPRECATED
// Services are now loaded dynamically from API: GET /api/v1/services
// This file is kept only for backward compatibility during migration

// TODO: Remove this file after all services are migrated to service_registry

export { SERVICE_CATEGORIES, SERVICE_APPS } from './services.config.legacy';
```

---

## 🔄 Auto-Discovery System

### Service Self-Registration

Ogni servizio può auto-registrarsi al primo avvio:

```typescript
// svc-pm/src/index.ts

import { registerService } from '@ewh/service-discovery';

const SERVICE_CONFIG = {
  serviceId: 'app-pm-frontend',
  serviceName: 'Project Management',
  serviceType: 'frontend',
  category: 'projects',
  icon: 'Kanban',
  urlPattern: `http://localhost:${PORT}`,
  description: 'Complete project management suite',
  port: PORT,
  healthCheckUrl: `http://localhost:${PORT}/health`,
  documentationUrl: '/docs/pm',
  isCore: false,
  defaultEnabled: true,
  requiresAuth: true,
  defaultRoles: ['TENANT_ADMIN', 'USER'],
};

async function bootstrap() {
  const app = createApp();

  // Start server
  await app.listen(PORT);

  // Register with service registry
  try {
    await registerService(SERVICE_CONFIG);
    console.log(`✅ Service registered: ${SERVICE_CONFIG.serviceId}`);
  } catch (error) {
    console.error('❌ Failed to register service:', error);
    // Continue anyway - registration failure should not prevent service from running
  }
}

bootstrap();
```

### @ewh/service-discovery Package

```typescript
// shared/packages/service-discovery/src/index.ts

import axios from 'axios';

const SERVICE_REGISTRY_URL = process.env.SERVICE_REGISTRY_URL || 'http://localhost:5960';
const PLATFORM_ADMIN_TOKEN = process.env.PLATFORM_ADMIN_TOKEN;

export interface ServiceConfig {
  serviceId: string;
  serviceName: string;
  serviceType: 'frontend' | 'backend';
  category: string;
  icon: string;
  urlPattern: string;
  description: string;
  port: number;
  healthCheckUrl: string;
  documentationUrl?: string;
  isCore?: boolean;
  defaultEnabled?: boolean;
  requiresAuth?: boolean;
  defaultRoles?: string[];
}

/**
 * Register service with the service registry
 */
export async function registerService(config: ServiceConfig): Promise<void> {
  if (!PLATFORM_ADMIN_TOKEN) {
    console.warn('⚠️  PLATFORM_ADMIN_TOKEN not set - skipping service registration');
    return;
  }

  try {
    const response = await axios.post(
      `${SERVICE_REGISTRY_URL}/api/v1/admin/services`,
      config,
      {
        headers: {
          Authorization: `Bearer ${PLATFORM_ADMIN_TOKEN}`,
        },
      }
    );

    console.log(`✅ Service registered: ${config.serviceId}`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 409) {
      // Service already registered - update it
      await updateService(config);
    } else {
      throw error;
    }
  }
}

/**
 * Update existing service registration
 */
export async function updateService(config: ServiceConfig): Promise<void> {
  const response = await axios.put(
    `${SERVICE_REGISTRY_URL}/api/v1/admin/services/${config.serviceId}`,
    config,
    {
      headers: {
        Authorization: `Bearer ${PLATFORM_ADMIN_TOKEN}`,
      },
    }
  );

  console.log(`✅ Service updated: ${config.serviceId}`);
  return response.data;
}

/**
 * Heartbeat - keep service alive in registry
 */
export async function sendHeartbeat(serviceId: string): Promise<void> {
  await axios.post(
    `${SERVICE_REGISTRY_URL}/api/v1/admin/services/${serviceId}/heartbeat`,
    {},
    {
      headers: {
        Authorization: `Bearer ${PLATFORM_ADMIN_TOKEN}`,
      },
    }
  );
}

/**
 * Start heartbeat interval
 */
export function startHeartbeat(serviceId: string, intervalMs: number = 60000): NodeJS.Timer {
  return setInterval(() => {
    sendHeartbeat(serviceId).catch((error) => {
      console.error('❌ Heartbeat failed:', error.message);
    });
  }, intervalMs);
}
```

---

## 📋 Migration Checklist

### Phase 1: Backend Setup (Week 1)

- [ ] Create `svc-service-registry` service
- [ ] Implement database schema (service_registry, service_categories, etc.)
- [ ] Implement API endpoints
- [ ] Create `@ewh/service-discovery` shared package
- [ ] Write migration script to populate `service_registry` from `services.config.ts`

### Phase 2: Frontend Migration (Week 2)

- [ ] Update `app-shell-frontend` to use API
- [ ] Create React hooks (`useServices`, etc.)
- [ ] Update Shell components to load services dynamically
- [ ] Keep `services.config.ts` as fallback during migration
- [ ] Test with existing services

### Phase 3: Service Self-Registration (Week 3)

- [ ] Add `registerService()` call to all services
- [ ] Test auto-discovery
- [ ] Add health check endpoints to all services
- [ ] Implement heartbeat system

### Phase 4: Cleanup (Week 4)

- [ ] Remove `services.config.ts` hardcoded file
- [ ] Verify all services registered
- [ ] Documentation complete
- [ ] Admin UI for service management

---

## 🎓 Benefits

### For Developers

- ✅ **No more hardcoded lists** - Add service once in DB
- ✅ **Auto-discovery** - Services self-register
- ✅ **Hot reload** - Add service without redeploying shell
- ✅ **Type-safe** - TypeScript interfaces from @ewh packages

### For Tenants

- ✅ **Enable/Disable services** - Control what users see
- ✅ **Custom configuration** - Per-tenant service config
- ✅ **Usage analytics** - Track service usage

### For Users

- ✅ **Pin favorites** - Customize sidebar
- ✅ **Recent services** - Quick access to frequently used
- ✅ **Search services** - Find what you need fast

---

## 🔗 Integration con Documentazione Esistente

### Update AGENTS.md

Aggiungere sezione:

```markdown
### Pattern: Add New Service to Shell

**Steps**:
1. Create service (backend or frontend)
2. Add `registerService()` call in bootstrap
3. Service appears automatically in shell
4. No need to update `services.config.ts` (deprecated)
```

### Update MASTER_PROMPT.md

Aggiungere principio:

```markdown
### Principio 6: "Dynamic Service Discovery"

// ❌ MALE: Hardcoded service lists
export const SERVICES = [/* 50+ services */];

// ✅ BENE: Dynamic loading from API
const { data: services } = useServices();

// ✅ Ancora meglio: Auto-registration
await registerService(SERVICE_CONFIG);
```

---

**Questo documento è MANDATORIO per integrare servizi nella shell.**

**Non aggiungere servizi senza seguire questa architettura.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
