# @ewh/shared-widgets

Shared widget components used across multiple EWH frontends.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        EWH Platform                              │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┐                    ┌──────────────────────┐
│  app-admin-frontend  │                    │  app-web-frontend    │
│  Port: 3200          │                    │  Port: 3100          │
│                      │                    │                      │
│  ┌────────────────┐  │                    │  ┌────────────────┐  │
│  │ Admin Pages    │  │                    │  │ Tenant Pages   │  │
│  │                │  │                    │  │                │  │
│  │ Uses widgets   │  │                    │  │ Uses widgets   │  │
│  │ in ADMIN       │  │                    │  │ in TENANT/USER │  │
│  │ context        │  │                    │  │ context        │  │
│  └───────┬────────┘  │                    │  └───────┬────────┘  │
└──────────┼───────────┘                    └──────────┼───────────┘
           │                                           │
           │ import { Widget } from '@ewh/shared-widgets'
           │                                           │
           └───────────────┬───────────────────────────┘
                           │
         ┌─────────────────▼──────────────────┐
         │  @ewh/shared-widgets               │
         │  (This package)                    │
         │                                    │
         │  ├── ConnectedUsersWidget.tsx      │
         │  ├── types.ts                      │
         │  ├── WidgetRegistry.ts             │
         │  └── index.ts                      │
         └────────────────────────────────────┘
```

## Installation

This package is already installed via pnpm workspace. Both frontends have it in their `package.json`:

```json
{
  "dependencies": {
    "@ewh/shared-widgets": "workspace:*"
  }
}
```

## Usage

### Import in Admin Frontend

```tsx
// app-admin-frontend/pages/admin/monitoring/users.tsx
import { ConnectedUsersWidget } from '@ewh/shared-widgets';

export default function Page() {
  return (
    <ConnectedUsersWidget
      context={{ context: 'admin' }}
      config={{
        maxUsers: 20,
        showAvatar: true,
        sortBy: 'lastActive'
      }}
    />
  );
}
```

### Import in Web Frontend

```tsx
// app-web-frontend/pages/dashboard/team.tsx
import { ConnectedUsersWidget } from '@ewh/shared-widgets';

export default function Page() {
  const { tenantId } = useAuth(); // Your auth hook

  return (
    <ConnectedUsersWidget
      context={{
        context: 'tenant',
        tenantId: tenantId
      }}
      config={{
        maxUsers: 15,
        customTitle: 'Team Members',
        brandColor: '#10b981'
      }}
    />
  );
}
```

## Widget Context

All widgets support three execution contexts:

### 1. Admin Context

Shows data from ALL tenants. Used in admin-frontend.

```tsx
<ConnectedUsersWidget
  context={{ context: 'admin' }}
  config={{ ... }}
/>
```

### 2. Tenant Context

Shows data from CURRENT tenant only. Used in tenant dashboards.

```tsx
<ConnectedUsersWidget
  context={{
    context: 'tenant',
    tenantId: 'acme-corp'
  }}
  config={{ ... }}
/>
```

### 3. User Context

Shows data scoped to current user's team. Used in personal dashboards.

```tsx
<ConnectedUsersWidget
  context={{
    context: 'user',
    tenantId: 'acme-corp',
    userId: 'user-123'
  }}
  config={{ ... }}
/>
```

## 3-Level Configuration

Widgets support configuration at 3 levels:

1. **System (Level 1)**: Default configuration for all instances
2. **Tenant (Level 2)**: Tenant-specific overrides (e.g., brand colors)
3. **User (Level 3)**: User preferences (e.g., compact view)

Configuration is merged: Level 1 → Level 2 → Level 3 → Instance props

## Available Widgets

### ConnectedUsersWidget

Shows currently connected users based on context.

**Config:**

```typescript
{
  // System-level
  showAvatar: boolean;
  maxUsers: number;
  refreshInterval: number;
  showStatus: boolean;
  sortBy: 'name' | 'lastActive';

  // Tenant-level
  brandColor?: string;
  customTitle?: string;

  // User-level
  compactView?: boolean;
}
```

**Example:**

```tsx
<ConnectedUsersWidget
  context={{ context: 'tenant', tenantId: 'acme' }}
  config={{
    showAvatar: true,
    maxUsers: 10,
    refreshInterval: 30000,
    customTitle: 'Team Online',
    brandColor: '#10b981'
  }}
/>
```

## Widget Registry

For dynamic widget loading:

```typescript
import WidgetRegistry from '@ewh/shared-widgets';

// Register widgets at app startup
WidgetRegistry.register(definition, Component);

// Get widget by ID
const Widget = WidgetRegistry.getComponent('connected-users');
<Widget context={...} config={...} />

// Get all widgets for a context
const adminWidgets = WidgetRegistry.getByContext('admin');
```

## Creating New Widgets

1. Create widget file in `src/`:

```tsx
// src/MyWidget.tsx
import { WidgetProps } from './types';

export interface MyWidgetConfig {
  // Your config fields
}

export function MyWidget({ context, config }: WidgetProps<MyWidgetConfig>) {
  // Implementation
}
```

2. Export in `src/index.ts`:

```typescript
export * from './MyWidget';
```

3. Use in frontends:

```tsx
import { MyWidget } from '@ewh/shared-widgets';
```

## API Integration

Widgets fetch data from context-aware API endpoints:

```typescript
// Widget calls API with context params
fetch(`/api/endpoint?context=${context.context}&tenantId=${context.tenantId}`);

// API filters data based on context
switch (context) {
  case 'admin':
    // Return all data
  case 'tenant':
    // Return only tenant's data
  case 'user':
    // Return only user's data
}
```

## TypeScript Support

Full TypeScript support with type inference:

```typescript
import type { WidgetContext, WidgetProps } from '@ewh/shared-widgets';

// Type-safe props
const props: WidgetProps<MyWidgetConfig> = {
  context: { context: 'tenant', tenantId: 'acme' },
  config: { ... }
};
```

## Development

```bash
# Install dependencies
pnpm install

# Watch mode (optional)
pnpm dev

# Build
pnpm build
```

## Hot Module Replacement

During development, changes to widgets are automatically reflected in both frontends via HMR.

## License

Private - Internal use only
