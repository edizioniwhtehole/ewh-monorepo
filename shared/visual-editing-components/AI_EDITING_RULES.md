# AI Editing Rules for Visual Editing Components

## 🚫 STRICT POLICY: DO NOT EDIT

This library contains component configurations managed by the **Visual Editing System**.

### Rules for AI Agents:

1. **DO NOT modify** any file with `AI_EDITING_BLOCKED: true` comment
2. **DO NOT change** hardcoded default values in component configs
3. **DO NOT alter** editable field definitions
4. **DO NOT add/remove** fields from component configurations
5. **DO NOT modify** styling, colors, spacing, or any visual properties

### What AI Agents CAN Do:

✅ **Read** component configurations to understand structure
✅ **Reference** types and interfaces from this library
✅ **Import** and use component configs in application code
✅ **Document** how to use components (without changing them)
✅ **Report bugs** in component definitions (but don't fix them directly)

### Why This Policy Exists:

- Component properties are managed through the database
- Users customize components via the visual editor UI
- Code changes would be overridden by database values
- Breaking changes could affect all tenants
- Audit trail requires changes to go through the proper API

### How to Make Changes:

If a component needs modification:

1. **For end-users**: Use the visual editor UI (Edit Mode toggle)
2. **For developers**: Update the database via API endpoints
3. **For new components**: Create new configs following the existing pattern
4. **For bugs**: Report to the development team for manual review

### Detection Markers:

Files in this library contain one or more of these markers:

```typescript
// AI_EDITING_BLOCKED: true
```

```typescript
/**
 * AI_EDITING_BLOCKED: true
 */
```

```typescript
export type AI_EDITING_BLOCKED = true;
```

When you encounter these markers, **stop and do not edit the file**.

### Example - What NOT to do:

❌ **Wrong:**
```typescript
// User asked to change topbar color to blue
export const TOPBAR_DEFAULTS = {
  backgroundColor: '#0000ff', // Changed by AI - WRONG!
  // ...
}
```

✅ **Correct:**
```typescript
// Tell user to use the visual editor:
"To change the topbar color to blue:
1. Click 'Edit Mode' in the footer
2. Hover over the topbar and click the pencil icon
3. Change 'Background Color' to #0000ff
4. Save your changes"
```

### Component Registry:

Currently protected components:
- `EditableTopBar` (Shell.TopBar)
- `EditableSidebar` (Shell.Sidebar)
- `EditableBottomBar` (Shell.BottomBar)

### For Questions:

If unsure whether a file should be edited, check for:
1. The `AI_EDITING_BLOCKED` marker
2. Location in `/shared/visual-editing-components/`
3. Comment warnings about visual editor management

**When in doubt, don't edit.**
