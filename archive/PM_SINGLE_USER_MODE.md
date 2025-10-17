# 🧑 PM System - Single User Mode

**Data**: 2025-10-12
**Target**: Freelancer, piccole aziende, self-hosted
**Filosofia**: Zero-config, massima semplicità

---

## 🎯 Caso d'Uso

### Chi è il target?
- **Freelancer** che gestisce 5-10 progetti personali
- **Piccole agenzie** (1-3 persone) senza budget per SaaS
- **Self-hosted** su proprio server/VPS
- **Privacy-first** che vogliono dati on-premise
- **Offline-first** che lavorano senza internet stabile

### Cosa vogliono?
- ✅ **Zero configurazione** - funziona subito dopo install
- ✅ **Nessun login** - avvia e lavora
- ✅ **Veloce** - nessun overhead di multi-tenant
- ✅ **Semplice** - UI minimale senza complessità enterprise
- ✅ **Local storage** - SQLite invece di PostgreSQL (opzionale)
- ✅ **Portable** - database in un singolo file

---

## 🏗️ Architettura: 3 Modalità di Deploy

### Mode 1: **Single User** (Nuovo!)
```
┌─────────────────────────────────────────┐
│  PM System - Single User Edition       │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Frontend (localhost:5400)        │ │
│  │  • No login screen                │ │
│  │  • Auto-login as "Me"             │ │
│  │  • Simplified UI (no tenants)     │ │
│  └───────────────────────────────────┘ │
│             ▼                           │
│  ┌───────────────────────────────────┐ │
│  │  Backend (localhost:5500)         │ │
│  │  • Single tenant hardcoded        │ │
│  │  • Single user auto-created       │ │
│  │  • No auth middleware             │ │
│  └───────────────────────────────────┘ │
│             ▼                           │
│  ┌───────────────────────────────────┐ │
│  │  Database                         │ │
│  │  • PostgreSQL (simple)            │ │
│  │  OR                               │ │
│  │  • SQLite (file-based)            │ │
│  │    ~/pm-data/projects.db          │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Features**:
- ✅ No login required
- ✅ No tenant selection
- ✅ No user management
- ✅ Simplified UI
- ✅ Single database file (SQLite)
- ✅ Portable (copy folder = backup)

### Mode 2: **Multi-User (Team)**
```
┌─────────────────────────────────────────┐
│  PM System - Team Edition               │
│  (2-10 persone nello stesso ufficio)    │
│                                         │
│  Frontend + Backend + PostgreSQL        │
│  • Login con email/password             │
│  • Single tenant                        │
│  • Multiple users con ruoli base        │
│  • Shared projects                      │
└─────────────────────────────────────────┘
```

**Features**:
- ✅ Simple login
- ✅ User management (admin adds users)
- ✅ Basic RBAC (admin, member, viewer)
- ✅ Shared database

### Mode 3: **Multi-Tenant (SaaS)**
```
┌─────────────────────────────────────────┐
│  PM System - Enterprise SaaS            │
│  (100+ aziende, cloud-hosted)           │
│                                         │
│  Full enterprise stack                  │
│  • Row-Level Security                   │
│  • Advanced RBAC                        │
│  • Audit logs                           │
│  • High Availability                    │
└─────────────────────────────────────────┘
```

**Features**:
- ✅ Tutto enterprise (vedi roadmap precedente)

---

## 🚀 Implementation: Single User Mode

### 1. Environment Variable
```bash
# .env
DEPLOYMENT_MODE=single-user  # single-user | team | saas
```

### 2. Backend: Mode Detection
```typescript
// svc-pm/src/config.ts

export type DeploymentMode = 'single-user' | 'team' | 'saas'

export const config = {
  mode: (process.env.DEPLOYMENT_MODE || 'single-user') as DeploymentMode,

  // Single user config
  singleUser: {
    tenantId: '00000000-0000-0000-0000-000000000001',
    userId: '00000000-0000-0000-0000-000000000001',
    userName: 'Me',
    userEmail: 'user@localhost'
  },

  // Database config (auto-detect)
  database: {
    type: process.env.DATABASE_URL?.includes('sqlite') ? 'sqlite' : 'postgres',
    url: process.env.DATABASE_URL || 'sqlite:./pm-data/projects.db'
  }
}

// Helper functions
export function isSingleUserMode(): boolean {
  return config.mode === 'single-user'
}

export function isTeamMode(): boolean {
  return config.mode === 'team'
}

export function isSaaSMode(): boolean {
  return config.mode === 'saas'
}
```

### 3. Backend: Conditional Middleware
```typescript
// svc-pm/src/index.ts

import { isSingleUserMode, config } from './config'

// Authentication middleware (only for team/saas modes)
if (!isSingleUserMode()) {
  fastify.addHook('preHandler', authMiddleware)
}

// Tenant middleware (only for saas mode)
if (isSaaSMode()) {
  fastify.addHook('preHandler', tenantMiddleware)
}

// Single user middleware (auto-inject user context)
if (isSingleUserMode()) {
  fastify.addHook('preHandler', async (req, rep) => {
    // Auto-inject single user context
    req.tenantId = config.singleUser.tenantId
    req.userId = config.singleUser.userId
    req.user = {
      id: config.singleUser.userId,
      email: config.singleUser.userEmail,
      name: config.singleUser.userName,
      role: 'ADMIN'
    }

    // Set database context
    if (config.database.type === 'postgres') {
      await db.query('SELECT set_tenant_context($1)', [req.tenantId])
    }
  })
}

// Health endpoint shows mode
fastify.get('/health', async () => ({
  status: 'ok',
  mode: config.mode,
  database: config.database.type,
  version: process.env.APP_VERSION || '1.0.0'
}))
```

### 4. Frontend: Auto-Login
```typescript
// app-pm-frontend/src/App.tsx

import { useEffect, useState } from 'react'
import { config } from './config'

function App() {
  const [mode, setMode] = useState<string>()
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    detectMode()
  }, [])

  async function detectMode() {
    try {
      // Check backend mode
      const res = await fetch('/api/pm/health')
      const data = await res.json()
      setMode(data.mode)

      // Auto-login for single-user mode
      if (data.mode === 'single-user') {
        // No login needed, just set user context
        localStorage.setItem('user', JSON.stringify({
          id: '00000000-0000-0000-0000-000000000001',
          name: 'Me',
          email: 'user@localhost'
        }))
      }
    } catch (error) {
      console.error('Failed to detect mode:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <LoadingScreen />
  }

  // Single-user mode: skip login, show simplified UI
  if (mode === 'single-user') {
    return (
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<TemplateSelector />} />
          <Route path="/projects" element={<ProjectsList />} />
          <Route path="/projects/:id" element={<ProjectDetail />} />
          {/* No user management, no settings */}
        </Routes>
      </BrowserRouter>
    )
  }

  // Team/SaaS mode: normal flow with login
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        {/* ... */}
      </Routes>
    </BrowserRouter>
  )
}
```

### 5. Simplified UI for Single-User
```tsx
// app-pm-frontend/src/components/SimplifiedHeader.tsx

export function SimplifiedHeader() {
  const mode = useMode()

  if (mode === 'single-user') {
    return (
      <header style={{
        padding: '16px 24px',
        background: 'white',
        borderBottom: '1px solid #e0e0e0',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
          <h1 style={{ fontSize: '20px', fontWeight: '600' }}>Project Manager</h1>

          <nav style={{ display: 'flex', gap: '16px' }}>
            <NavLink to="/">Templates</NavLink>
            <NavLink to="/projects">Projects</NavLink>
          </nav>
        </div>

        {/* No user dropdown, no tenant selector */}
        <div style={{ fontSize: '14px', color: '#666' }}>
          Single User Mode
        </div>
      </header>
    )
  }

  // Full header for team/saas modes
  return <FullHeader />
}
```

---

## 🗄️ SQLite Support (Optional)

### Why SQLite for Single-User?
- ✅ **Zero config** - no PostgreSQL install needed
- ✅ **Single file** - easy backup (copy file)
- ✅ **Portable** - move to different computer
- ✅ **Fast** - local disk, no network
- ✅ **Lightweight** - 600KB library

### Implementation
```typescript
// svc-pm/src/database/index.ts

import { config } from '../config'
import postgres from 'postgres'
import Database from 'better-sqlite3'

let db: any

if (config.database.type === 'sqlite') {
  // SQLite connection
  const sqlite = new Database(config.database.url.replace('sqlite:', ''), {
    verbose: console.log
  })

  // Enable foreign keys
  sqlite.pragma('foreign_keys = ON')

  db = {
    query: (sql: string, params: any[]) => {
      // Convert PostgreSQL syntax to SQLite
      const sqliteSql = sql
        .replace(/\$(\d+)/g, '?')  // $1 → ?
        .replace(/RETURNING \*/g, '')  // Remove RETURNING (use lastInsertRowid)

      const stmt = sqlite.prepare(sqliteSql)
      const result = stmt.run(...params)

      return {
        rows: [{ id: result.lastInsertRowid }],
        rowCount: result.changes
      }
    }
  }
} else {
  // PostgreSQL connection (existing)
  db = postgres(config.database.url)
}

export { db }
```

### SQLite Migration Schema
```sql
-- migrations/sqlite/001_init.sql

CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  tenant_id TEXT NOT NULL,
  project_code TEXT NOT NULL,
  project_name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'planning',
  priority TEXT DEFAULT 'medium',
  start_date DATE,
  end_date DATE,
  completion_percentage INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL,
  task_name TEXT NOT NULL,
  description TEXT,
  task_category TEXT,
  status TEXT DEFAULT 'todo',
  priority TEXT DEFAULT 'medium',
  assigned_to TEXT,
  estimated_hours REAL,
  actual_hours REAL DEFAULT 0,
  start_date DATE,
  due_date DATE,
  completed_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Indexes
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_status ON tasks(status);
```

---

## 📦 Quick Setup Script

```bash
#!/bin/bash
# scripts/setup-single-user.sh

echo "🚀 Setting up PM System - Single User Mode"
echo ""

# 1. Create data directory
mkdir -p pm-data
echo "✅ Created data directory: pm-data/"

# 2. Create .env file
cat > .env << EOF
# Deployment mode
DEPLOYMENT_MODE=single-user

# Database (choose one)
# PostgreSQL
DATABASE_URL=postgresql://ewh:password@localhost:5432/ewh_pm
# OR SQLite (recommended for single-user)
# DATABASE_URL=sqlite:./pm-data/projects.db

# Server config
PORT=5500
NODE_ENV=development

# Single user config
SINGLE_USER_NAME=Me
SINGLE_USER_EMAIL=user@localhost
EOF
echo "✅ Created .env file"

# 3. Install dependencies
echo ""
echo "📦 Installing dependencies..."
cd svc-pm && npm install
cd ../app-pm-frontend && npm install
cd ..
echo "✅ Dependencies installed"

# 4. Run migrations
echo ""
echo "🗄️  Setting up database..."
if grep -q "sqlite" .env; then
  echo "Using SQLite..."
  node svc-pm/scripts/migrate-sqlite.js
else
  echo "Using PostgreSQL..."
  psql -h localhost -U ewh -d ewh_master -f migrations/028_pm_core_generic.sql
fi
echo "✅ Database ready"

# 5. Start servers
echo ""
echo "🎬 Starting servers..."
echo ""

# Backend
cd svc-pm
npm run dev > ../pm-data/backend.log 2>&1 &
BACKEND_PID=$!
echo "✅ Backend started (PID: $BACKEND_PID)"

# Wait for backend
sleep 3

# Frontend
cd ../app-pm-frontend
npm run dev > ../pm-data/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "✅ Frontend started (PID: $FRONTEND_PID)"

# Wait for frontend
sleep 3

echo ""
echo "🎉 PM System is ready!"
echo ""
echo "📍 Open in browser: http://localhost:5400"
echo ""
echo "📄 Logs:"
echo "   Backend:  tail -f pm-data/backend.log"
echo "   Frontend: tail -f pm-data/frontend.log"
echo ""
echo "🛑 To stop:"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo ""
```

Make it executable:
```bash
chmod +x scripts/setup-single-user.sh
./scripts/setup-single-user.sh
```

---

## 🎨 UI Differences by Mode

### Single User Mode UI
```tsx
// Simplified UI - No complexity
<Layout>
  <SimpleHeader />  {/* No user dropdown */}

  <MainContent>
    <ProjectsList />  {/* No filters by user */}
  </MainContent>

  {/* No footer with user count, no settings */}
</Layout>
```

**Hidden features**:
- ❌ User management
- ❌ Tenant selector
- ❌ Permissions UI
- ❌ Billing
- ❌ Team invite
- ❌ Admin console

**Visible features**:
- ✅ Projects (my projects)
- ✅ Tasks (my tasks)
- ✅ Templates
- ✅ Basic settings (name, language)

### Team Mode UI
```tsx
// Add user management
<Layout>
  <Header>
    <UserDropdown /> {/* Show current user */}
  </Header>

  <Sidebar>
    <Nav>
      <NavItem to="/projects">Projects</NavItem>
      <NavItem to="/team">Team</NavItem>  {/* New */}
    </Nav>
  </Sidebar>

  <MainContent>
    <ProjectsList>
      <Filters>
        <UserFilter /> {/* Filter by team member */}
      </Filters>
    </ProjectsList>
  </MainContent>
</Layout>
```

### SaaS Mode UI
```tsx
// Full enterprise UI
<Layout>
  <Header>
    <TenantSelector />  {/* For super admins */}
    <UserDropdown />
  </Header>

  <Sidebar>
    <Nav>
      <NavItem to="/dashboard">Dashboard</NavItem>
      <NavItem to="/projects">Projects</NavItem>
      <NavItem to="/team">Team</NavItem>
      <NavItem to="/settings">Settings</NavItem>
      <NavItem to="/admin">Admin</NavItem>  {/* New */}
      <NavItem to="/billing">Billing</NavItem>  {/* New */}
    </Nav>
  </Sidebar>
</Layout>
```

---

## 🚢 Distribution Packages

### Package 1: Single User (Desktop App)
```
pm-single-user-v1.0.0-macos.dmg
pm-single-user-v1.0.0-windows.exe
pm-single-user-v1.0.0-linux.AppImage

Contents:
- Electron wrapper
- Backend embedded
- Frontend embedded
- SQLite embedded
- No external dependencies

Install:
1. Download
2. Double-click
3. Start using (no setup!)
```

### Package 2: Self-Hosted (Docker)
```bash
# docker-compose.single-user.yml
version: '3.8'

services:
  pm-single-user:
    image: ewh/pm-system:single-user
    environment:
      DEPLOYMENT_MODE: single-user
      DATABASE_URL: sqlite:/data/projects.db
    ports:
      - "5400:5400"
      - "5500:5500"
    volumes:
      - ./pm-data:/data
    restart: unless-stopped

# Usage:
docker-compose -f docker-compose.single-user.yml up -d
```

### Package 3: Cloud SaaS
```
https://pm.polosaas.it

Auto-detects mode based on:
- User count (1 = single-user, 2-10 = team, 10+ = saas)
- Can upgrade seamlessly
```

---

## 🔄 Migration Path

### From Single-User to Team
```typescript
// scripts/upgrade-to-team.ts

async function upgradeToTeam() {
  console.log('🔄 Upgrading from Single User to Team mode...')

  // 1. Create admin user (from single user)
  const adminUser = await db.query(`
    INSERT INTO users (id, email, name, role)
    VALUES ($1, $2, $3, 'ADMIN')
    ON CONFLICT (id) DO UPDATE SET role = 'ADMIN'
    RETURNING *
  `, [
    config.singleUser.userId,
    config.singleUser.userEmail,
    config.singleUser.userName
  ])

  console.log('✅ Admin user created')

  // 2. Update .env
  fs.writeFileSync('.env', `
DEPLOYMENT_MODE=team
DATABASE_URL=${process.env.DATABASE_URL}
JWT_SECRET=${generateRandomSecret()}
  `)

  console.log('✅ Config updated')

  // 3. Restart required
  console.log('⚠️  Please restart the server')
  console.log('   pm-restart.sh')
}
```

### From Team to SaaS
```typescript
// scripts/upgrade-to-saas.ts

async function upgradeToSaaS() {
  console.log('🔄 Upgrading from Team to SaaS mode...')

  // 1. Enable Row-Level Security
  await db.query('ALTER TABLE projects ENABLE ROW LEVEL SECURITY')
  await db.query('ALTER TABLE tasks ENABLE ROW LEVEL SECURITY')
  // ... (vedi migration 100_enable_rls.sql)

  // 2. Create first tenant from existing data
  const tenant = await db.query(`
    INSERT INTO tenants (name, subdomain, plan)
    VALUES ('My Company', 'mycompany', 'professional')
    RETURNING *
  `)

  // 3. Link existing users to tenant
  await db.query(`
    INSERT INTO user_tenants (user_id, tenant_id, role)
    SELECT id, $1, role FROM users
  `, [tenant.rows[0].id])

  // 4. Update .env
  fs.writeFileSync('.env', `
DEPLOYMENT_MODE=saas
DATABASE_URL=${process.env.DATABASE_URL}
JWT_SECRET=${process.env.JWT_SECRET}
  `)

  console.log('✅ Upgraded to SaaS mode')
  console.log('⚠️  Please restart the server')
}
```

---

## 📊 Comparison Table

| Feature | Single User | Team | SaaS |
|---------|------------|------|------|
| **Users** | 1 (you) | 2-10 | Unlimited |
| **Login** | ❌ Auto | ✅ Required | ✅ Required |
| **Database** | SQLite or PG | PostgreSQL | PostgreSQL |
| **Auth** | ❌ None | ✅ Basic | ✅ Advanced (SSO) |
| **RBAC** | ❌ None | ✅ Basic | ✅ Advanced |
| **Tenants** | ❌ None | ❌ Single | ✅ Multi |
| **Audit Logs** | ❌ Optional | ⚠️ Basic | ✅ Full |
| **Backup** | Manual copy | Auto + manual | Auto + HA |
| **Cost** | Free/One-time | €49/mo | €199-999/mo |
| **Target** | Freelancer | Small team | Enterprise |

---

## 🎯 Implementation Plan

### Phase 1: Core Single-User Mode (Week 1)
- [ ] Add mode detection (config.ts)
- [ ] Conditional middleware (skip auth in single-user)
- [ ] Auto-inject user context
- [ ] Simplified frontend (no login)
- [ ] Test end-to-end

**Deliverable**: Single-user mode working

### Phase 2: SQLite Support (Week 2)
- [ ] SQLite adapter (database/sqlite.ts)
- [ ] SQLite migrations
- [ ] Query syntax converter (PostgreSQL → SQLite)
- [ ] Test with SQLite database

**Deliverable**: SQLite as alternative to PostgreSQL

### Phase 3: Quick Setup (Week 3)
- [ ] Setup script (setup-single-user.sh)
- [ ] Docker image (single-user variant)
- [ ] Electron wrapper (optional)
- [ ] Documentation

**Deliverable**: One-click setup experience

### Phase 4: Migration Tools (Week 4)
- [ ] Upgrade to team script
- [ ] Upgrade to SaaS script
- [ ] Data export/import
- [ ] Testing

**Deliverable**: Seamless upgrade path

---

## 🚀 Quick Start (Single User)

```bash
# 1. Clone repo
git clone https://github.com/yourorg/pm-system
cd pm-system

# 2. Run setup script
./scripts/setup-single-user.sh

# 3. Open browser
open http://localhost:5400

# That's it! No login, start creating projects immediately.
```

---

## 📦 Packaging for Distribution

### Electron App (Desktop)
```javascript
// electron/main.js
const { app, BrowserWindow } = require('electron')
const { spawn } = require('child_process')
const path = require('path')

let backend, frontend

app.on('ready', () => {
  // Start backend
  backend = spawn('node', ['backend/index.js'], {
    cwd: path.join(__dirname, '..'),
    env: {
      ...process.env,
      DEPLOYMENT_MODE: 'single-user',
      DATABASE_URL: `sqlite:${app.getPath('userData')}/projects.db`
    }
  })

  // Wait for backend to be ready
  setTimeout(() => {
    // Create window
    const win = new BrowserWindow({
      width: 1200,
      height: 800,
      webPreferences: {
        nodeIntegration: false
      }
    })

    win.loadURL('http://localhost:5400')
  }, 2000)
})

app.on('quit', () => {
  backend.kill()
})
```

Build script:
```bash
# package.json
{
  "scripts": {
    "build:electron": "electron-builder --mac --windows --linux"
  },
  "build": {
    "appId": "com.ewh.pm-system",
    "productName": "PM System",
    "files": [
      "electron/**/*",
      "backend/**/*",
      "frontend/**/*"
    ]
  }
}
```

---

**Status**: 🎯 **Single-User Mode Design Complete**
**Next**: Implement mode detection and conditional middleware
**Timeline**: 1 settimana per single-user mode funzionante
