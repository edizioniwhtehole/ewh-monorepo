# @ewh/shared-widgets

Unified widget system for the EWH platform. Single widgets that work everywhere:
- 🎨 **Page Builder** (GrapesJS drag & drop)
- 📊 **Admin Dashboard** (live data monitoring)
- 🌐 **Public Pages** (server-side rendered)

## Features

- ✅ **Mode Switching**: Preview mode (mock data) vs Live mode (real API)
- ✅ **Central Registry**: All widgets registered in one place
- ✅ **Type Safety**: Full TypeScript support
- ✅ **JSON Schema**: Configuration validation
- ✅ **Auto-refresh**: Configurable polling intervals
- ✅ **Error Handling**: Graceful fallbacks
- ✅ **Adapter Pattern**: Works with any framework

## Architecture

```
Widget Component
  ↓
useWidgetData Hook (mode-aware)
  ↓
API Client (Gateway integration)
  ↓
Backend API or Mock Data
```

## Usage

### In Page Builder

```typescript
import { widgetRegistry } from '@ewh/shared-widgets';

const widget = widgetRegistry.get('metrics-cards');
<widget.Component
  config={widget.metadata.defaultConfig}
  mode="preview"
/>
```

### In Dashboard

```typescript
import { MetricsCardsWidget } from '@ewh/shared-widgets';

<MetricsCardsWidget
  config={{
    dataEndpoint: '/api/admin/stats',
    refreshInterval: 30000
  }}
  mode="live"
  context={{ tenantId, userId, userRole }}
/>
```

## Widget Structure

```
widgets/MyWidget/
├── index.tsx              # Component
├── metadata.json          # Widget info
├── default.config.json    # Default configuration
├── config.schema.json     # JSON Schema
└── register.ts            # Auto-registration
```

## Development

```bash
# Install dependencies
cd shared/widgets
npm install

# Build
npm run build

# Watch mode
npm run dev
```

## Migration Status

**Phase 1 ✅ COMPLETED**:
- ✅ MetricsCardsWidget
- ✅ ServiceStatusWidget
- ✅ RecentActivityWidget

**Total**: 3/31 widgets migrated (9.7%)
