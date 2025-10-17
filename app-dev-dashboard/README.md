# Development Dashboard

> Real-time development progress tracking for the EWH platform

## Overview

The Development Dashboard provides a visual overview of development progress across all 90 services and 77+ frontend applications in the EWH platform.

## Features

- **Service Overview** - List of all apps/services with completion %
- **Color-coded Status** - Visual status indicators
  - ⚪ Grey: Not started (0%)
  - 🟢 Dark Green: Complete (100%)
  - 🟢 Medium Green: High progress (75-99%)
  - 🟢 Light Green: Good progress (50-74%)
  - 🟡 Yellow: In progress (25-49%)
  - 🔴 Red: Started but low progress (1-24%)
- **Auto-update** - Syncs with database when features are added
- **Owner-only Access** - Restricted to platform owners
- **Drill-down** - Click service to see detailed task list
- **Filter & Search** - Filter by status, suite, or search by name

## Tech Stack

- **Frontend:** Next.js 14 + React 18
- **State:** Zustand
- **Database:** Supabase (admin schema)
- **UI:** Tailwind CSS + Lucide Icons
- **Port:** 3700

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env.local

# Run development server
npm run dev
```

Navigate to http://localhost:3700

## Environment Variables

```bash
NEXT_PUBLIC_SUPABASE_URL=https://qubhjidkgpxlyruwkfkb.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
```

## Data Source

The dashboard reads from the `admin.apps_development` and `admin.tasks_checklist` tables created by migration `100_admin_roadmap_checklist.sql`.

## Access Control

Only users with `platform_role = 'owner'` can access this dashboard.

## Development Progress Calculation

```typescript
completion % = (completed_tasks / total_tasks) * 100
```

Status colors:
- Grey: 0%
- Red: 1-24%
- Yellow: 25-49%
- Light Green: 50-74%
- Medium Green: 75-99%
- Dark Green: 100%

## Structure

```
app-dev-dashboard/
├── src/
│   ├── app/
│   │   ├── page.tsx              # Main dashboard
│   │   ├── service/[id]/page.tsx # Service detail
│   │   └── layout.tsx            # Root layout
│   ├── components/
│   │   ├── ServiceCard.tsx       # Service card component
│   │   ├── ServiceDetail.tsx     # Service detail view
│   │   ├── TaskList.tsx          # Task list component
│   │   └── ProgressBar.tsx       # Progress bar
│   ├── lib/
│   │   ├── supabase.ts           # Supabase client
│   │   └── types.ts              # TypeScript types
│   └── styles/
│       └── globals.css           # Global styles
├── public/
├── package.json
├── tsconfig.json
├── tailwind.config.js
└── README.md
```

## Features Roadmap

- [x] Service overview with completion %
- [x] Color-coded status indicators
- [x] Service detail view
- [x] Task list by phase
- [ ] Real-time updates (WebSocket)
- [ ] Export to CSV/PDF
- [ ] Timeline view
- [ ] Gantt chart view
- [ ] Team member assignment
- [ ] Time tracking integration

## License

Private - EWH Platform Internal Tool
