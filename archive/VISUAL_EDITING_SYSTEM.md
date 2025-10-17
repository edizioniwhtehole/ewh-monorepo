# Visual Editing System

## Overview

The Visual Editing System allows tenants and administrators to customize the appearance and behavior of UI components without modifying code. It uses a **multi-level override cascade** to determine which customizations apply to a component.

## Architecture

### Database Schema

The system consists of three main tables:

1. **`cms.visual_editing_permissions`** - Controls who can edit what
2. **`cms.component_overrides`** - Stores component customizations
3. **`cms.component_override_history`** - Audit trail of changes

### Override Cascade (Precedence Order)

The system applies overrides in the following order (highest to lowest priority):

```
Installation > Tenant > Tenant Group > Global > Hardcoded Default
```

This means:
- **Hardcoded Default**: Values in the component code (baseline)
- **Global**: Applies to all tenants
- **Tenant Group**: Applies to a group of tenants
- **Tenant**: Applies to a specific tenant only
- **Installation**: Applies to on-premise installations (highest priority)

### Tenant Isolation

**Critical**: Changes made at the tenant level only affect that specific tenant. Other tenants remain unaffected.

Example:
- Tenant A customizes the topbar color to red
- Tenant B sees the default (or their own customization)
- Global admins can customize at the global level to affect all tenants

## API Endpoints

### GET /api/visual-editing/permissions
Get visual editing permissions for the current user.

**Response:**
```json
{
  "permissions": [{
    "id": "uuid",
    "user_id": "uuid",
    "tenant_id": "uuid",
    "scope": "tenant",
    "can_edit_components": true,
    "can_edit_layouts": true,
    "can_edit_themes": true,
    "can_edit_branding": false
  }]
}
```

### GET /api/visual-editing/component-overrides/:component_key
Get resolved props for a component (with cascade applied).

**Response:**
```json
{
  "component_key": "ShellLayout.TopBar",
  "props": {
    "backgroundColor": "#ffffff",
    "borderColor": "#e5e7eb",
    "height": 64,
    "logoText": "Custom Logo"
  }
}
```

### POST /api/visual-editing/component-overrides
Create or update a component override.

**Request:**
```json
{
  "component_key": "ShellLayout.TopBar",
  "override_scope": "tenant",
  "override_data": {
    "backgroundColor": "#000000",
    "logoText": "My Company"
  }
}
```

**Response:**
```json
{
  "override": {
    "id": "uuid",
    "component_key": "ShellLayout.TopBar",
    "override_scope": "tenant",
    "tenant_id": "uuid",
    "override_data": { ... },
    "version": 1
  }
}
```

## Frontend Usage

### 1. Enable Visual Editing Context

Wrap your app with `VisualEditingProvider`:

```tsx
// pages/_app.tsx
import { VisualEditingProvider } from '../context/VisualEditingContext';

export default function App({ Component, pageProps }) {
  return (
    <ShellProvider>
      <VisualEditingProvider>
        <Component {...pageProps} />
      </VisualEditingProvider>
    </ShellProvider>
  );
}
```

### 2. Add Edit Mode Toggle

Add the toggle button to your UI (typically in the topbar):

```tsx
import { EditModeToggle } from './EditModeToggle';

// In your component:
<EditModeToggle />
```

### 3. Make Components Editable

Wrap any component with `EditableComponent`:

```tsx
import { EditableComponent, EditableField } from './EditableComponent';

const hardcodedProps = {
  backgroundColor: '#ffffff',
  textColor: '#000000',
  fontSize: 16,
};

const editableFields: EditableField[] = [
  { key: 'backgroundColor', label: 'Background Color', type: 'color' },
  { key: 'textColor', label: 'Text Color', type: 'color' },
  { key: 'fontSize', label: 'Font Size', type: 'number', min: 12, max: 24 },
];

export function MyComponent() {
  return (
    <EditableComponent
      componentKey="MyApp.MyComponent"
      category="components"
      hardcodedProps={hardcodedProps}
      editableFields={editableFields}
    >
      {(props) => (
        <div style={{ backgroundColor: props.backgroundColor, color: props.textColor }}>
          <p style={{ fontSize: `${props.fontSize}px` }}>Hello World</p>
        </div>
      )}
    </EditableComponent>
  );
}
```

### 4. Field Types

Available field types for editing:

- **`text`**: Text input
- **`number`**: Number input (supports min, max, step)
- **`color`**: Color picker
- **`select`**: Dropdown (requires options array)
- **`boolean`**: Checkbox
- **`spacing`**: Number input for spacing values (px)

Example:
```tsx
const editableFields: EditableField[] = [
  { key: 'title', label: 'Title', type: 'text' },
  { key: 'padding', label: 'Padding', type: 'spacing', step: 4 },
  { key: 'theme', label: 'Theme', type: 'select', options: [
    { label: 'Light', value: 'light' },
    { label: 'Dark', value: 'dark' }
  ]},
  { key: 'enabled', label: 'Enabled', type: 'boolean' },
];
```

## Edit Mode Behavior

When edit mode is active:

1. **Editable components** show a dashed blue border
2. **On hover**, the border becomes solid and a pencil icon appears
3. **Clicking the pencil** opens a modal editor
4. **Users without permission** don't see edit indicators
5. **Components render** with merged props (hardcoded + DB overrides)

## Permission System

### Permission Scopes

- **`tenant`**: User can edit for their tenant only
- **`tenant_group`**: User can edit for multiple tenants in a group
- **`global`**: User can edit globally (all tenants)
- **`installation`**: User can edit for on-premise installations

### Granular Permissions

Each user can have different permissions:

- `can_edit_components`: General UI components
- `can_edit_layouts`: Layout components (topbar, sidebar, etc.)
- `can_edit_themes`: Theme and branding
- `can_edit_branding`: Logos, colors, brand identity

## Example: Customizing TopBar

The TopBar component demonstrates the visual editing system:

```tsx
// components/TopBar.tsx
const defaultProps = {
  backgroundColor: '#ffffff',
  borderColor: '#e5e7eb',
  height: 64,
  logoText: 'EWH',
  brandText: 'Enterprise Workspace',
};

export function TopBar() {
  return (
    <EditableComponent
      componentKey="ShellLayout.TopBar"
      category="layouts"
      hardcodedProps={defaultProps}
      editableFields={[...]}
    >
      {(props) => (
        <header style={{ backgroundColor: props.backgroundColor, height: props.height }}>
          {/* Component JSX using props */}
        </header>
      )}
    </EditableComponent>
  );
}
```

**To customize:**
1. Click "Edit Mode" button in topbar
2. Hover over the topbar
3. Click the pencil icon
4. Modify colors, text, sizing, etc.
5. Choose scope: "Current Tenant Only" or "All Tenants (Global)"
6. Click "Save Changes"

## Database Functions

### `cms.get_component_props(component_key, installation_id, tenant_id)`

Returns merged component props by applying cascade logic.

```sql
SELECT cms.get_component_props('ShellLayout.TopBar', NULL, 'tenant-uuid');
```

Returns JSONB with all applicable overrides merged in precedence order.

## Security Considerations

1. **Permission checks** are enforced in the API
2. **Tenant isolation** is guaranteed by filtering queries
3. **Audit trail** records all changes with user attribution
4. **Version tracking** allows rollback capabilities
5. **Inactive overrides** can be soft-deleted instead of removed

## Migration

The visual editing system was added in migration `028_visual_editing_system.sql`.

To apply:
```bash
psql -h localhost -U ewh -d ewh_master -f migrations/028_visual_editing_system.sql
```

## Testing

### Grant Permissions

```sql
INSERT INTO cms.visual_editing_permissions (
  tenant_id, user_id, scope,
  can_edit_components, can_edit_layouts
) VALUES (
  'tenant-uuid', 'user-uuid', 'tenant',
  true, true
);
```

### Create Override

```bash
curl -X POST http://localhost:4000/cms/visual-editing/component-overrides \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "component_key": "ShellLayout.TopBar",
    "override_scope": "tenant",
    "override_data": {
      "backgroundColor": "#1e293b",
      "textColor": "#ffffff"
    }
  }'
```

### Get Component Props

```bash
curl http://localhost:4000/cms/visual-editing/component-overrides/ShellLayout.TopBar \
  -H "Authorization: Bearer <token>"
```

## Next Steps

1. ✅ Database schema created
2. ✅ Backend API implemented
3. ✅ React hooks and components created
4. ✅ TopBar example implemented
5. ⏳ Add more editable components (Sidebar, BottomBar, etc.)
6. ⏳ Implement tenant group management UI
7. ⏳ Add rollback functionality
8. ⏳ Create visual theme presets

## Architecture Benefits

- **No code changes** required for customization
- **Tenant isolation** guarantees security
- **Multi-level control** for different admin types
- **Audit trail** for compliance
- **Progressive enhancement** with hardcoded fallbacks
- **Flexible field types** for different UI needs
