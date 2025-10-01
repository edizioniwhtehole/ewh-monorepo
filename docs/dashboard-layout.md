# Dashboard Layout Overview

## Goals
- Unified shell for tenant admin and app-specific dashboards
- Support multi-app assignments per user with clear navigation cues
- Provide placeholders/mockups for each app until real data arrives

## Layout Architecture
1. **Top Bar**
   - Left: tenant logo + name, tenant switcher (if multiple)
   - Center: global search, quick-create actions
   - Right: notifications, user menu, help

2. **Primary Tabs (Horizontal)**
   - Represent the available apps/modules (DAM, Projects, Orders, Support, etc.)
   - Tabs filter based on user scopes and assignments
   - Scrollable with overflow indicator

3. **Side Navigation (Vertical, collapsible)**
   - Context-aware: shows functions for the selected app
   - Supports icon-only collapsed mode (64px) and expanded mode (~240px)
   - Optionally group items (e.g., “Library”, “Upload”, “Approvals” under DAM)

4. **Optional Secondary Panel**
   - Appears to the left of main content (beside side nav) for filters/pinned lists
   - Collapsible; default closed on smaller screens

5. **Main Content Area**
   - Responsive grid for cards/widgets
   - Each app exposes quick actions, status summaries, and deep links

6. **Footer / Status Bar (optional)**
   - Environment indicator (dev/staging/prod)
   - Tenant usage stats, storage/quota when relevant

## App Mock Sections (tenant-facing)
### DAM (Digital Asset Management)
- Cards: “Recent Uploads”, “Pinned Collections”, “Jobs in Progress”
- Actions: Upload, Create Collection, Request Approval
- Table placeholder for Assets with mock rows

### Projects
- Timeline widget (upcoming milestones)
- “My Tasks” list with sample tasks
- Kanban preview (mock columns with static tickets)

### Orders / Production
- KPI cards (Orders in production, Late jobs)
- Table placeholder of recent orders
- Shortcut to create new order/job

### Support / Collaboration
- Recent tickets list
- Knowledge base highlights
- Invite external collaborator button

### Reports / BI (if enabled)
- Charts placeholders (bar chart, line chart)
- Export buttons (disabled state until backend ready)

### Settings / People
- Two-pane layout: Users list, Roles & Permissions detail, Audit log placeholder
- Buttons for “Invite user”, “Generate guest link”

## Interaction Notes
- All widgets should include `aria` labels and respect keyboard navigation
- Use consistent card heights to avoid layout jitter
- Skeleton loaders for initial fetch
- Store side nav collapse state in localStorage

## Next Steps
- Implement shared `AppShell` component
- Define mock data modules under `src/mock/`
- Build individual dashboard pages consuming the shell
- Replace mocks with real queries as services become available

