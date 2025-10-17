# Alpha Shell Integration Strategy

**Obiettivo**: Integrare tutte le 19 app nella shell in modalità alpha, standardizzare via GitHub Actions overnight, deploy in staging "non funzionante ma visibile", poi iterare app-per-app verso beta.

**Data**: 13 Ottobre 2025
**Timeline**: 7 giorni per alpha completa, poi iterazione continua verso beta

---

## 🎯 Strategia: "Visual First, Function Later"

```
Day 1-2: ALPHA INTEGRATION
├─ Tutte le 19 app integrate nella shell (anche se skeleton)
├─ UI completa e navigabile
├─ Routing funzionante
└─ "Visual prototype" dell'intero sistema

Day 3: OVERNIGHT AUTOMATION
├─ GitHub Actions standardizza stili
├─ Standardizza webhook patterns
├─ Genera API contracts
└─ Crea documentation automatica

Day 4-5: STAGING DEPLOY
├─ Deploy alpha in staging
├─ Tutto visibile e navigabile
├─ Features non implementate (mock data)
└─ User testing del flow

Day 6+: ITERAZIONE BETA
├─ App-per-app implementation
├─ Feature-per-feature rollout
└─ Continuous deployment in beta
```

---

## 📱 Le 19 App da Integrare

### ✅ Live (6 app)
| App | Port | Status | Integration |
|-----|------|--------|-------------|
| app-shell-frontend | 3150 | ✅ Live | Base orchestrator |
| app-admin-frontend | 3200 | ✅ Live | Admin panel |
| app-pm-frontend | 5400 | ✅ Live | Project Management |
| app-dam (media-frontend) | 5500 | ✅ Live | Digital Assets |
| app-approvals-frontend | 5600 | ✅ Live | Approval system |
| app-page-builder | 5700 | ✅ Live | Page builder |

### 🟡 Partial (5 app)
| App | Port | Status | Integration |
|-----|------|--------|-------------|
| app-cms-frontend | 5300 | 🟡 Partial | CMS manager |
| app-web-frontend | 3000 | 🟡 Partial | Public website |
| app-admin-console | TBD | 🟡 Partial | System admin |
| app-workflow-insights | TBD | 🟡 Partial | Analytics |
| app-procurement-frontend | TBD | 🟡 Partial | Procurement |

### ❌ To Build (8 app)
| App | Port | Status | Integration |
|-----|------|--------|-------------|
| app-layout-editor | 5800 | ❌ Skeleton | Layout design |
| app-raster-editor | 5900 | ❌ Skeleton | Image editing |
| app-photoediting | 6000 | ❌ Skeleton | Photo editor |
| app-video-editor | 6100 | ❌ Skeleton | Video editing |
| app-crm-frontend | 6200 | ❌ To create | CRM system |
| app-ecommerce-frontend | 6300 | ❌ To create | E-commerce |
| app-forum-frontend | 6400 | ❌ To create | Forum/Community |
| app-support-frontend | 6500 | ❌ To create | Help desk |

---

## 🏗️ Phase 1: Alpha Integration (Days 1-2)

### Obiettivo
Tutte le 19 app visibili e navigabili nella shell, anche se con mock data.

### Step 1.1: Shell Service Registry Update

**File**: `app-shell-frontend/src/lib/services.config.ts`

```typescript
export const SERVICES = [
  // ✅ LIVE SERVICES
  {
    id: 'admin',
    name: 'Admin Console',
    icon: 'Settings',
    url: 'http://localhost:3200',
    description: 'System administration',
    requiresAuth: true,
    category: 'system',
    roles: ['SUPER_ADMIN'],
    status: 'live',
    version: '1.0.0'
  },
  {
    id: 'pm',
    name: 'Project Management',
    icon: 'Trello',
    url: 'http://localhost:5400',
    description: 'Projects & tasks',
    requiresAuth: true,
    category: 'productivity',
    status: 'live',
    version: '1.0.0'
  },
  {
    id: 'dam',
    name: 'Digital Assets',
    icon: 'Image',
    url: 'http://localhost:5500',
    description: 'Media library',
    requiresAuth: true,
    category: 'content',
    status: 'live',
    version: '1.0.0'
  },
  {
    id: 'approvals',
    name: 'Approvals',
    icon: 'CheckCircle',
    url: 'http://localhost:5600',
    description: 'Approval workflows',
    requiresAuth: true,
    category: 'workflow',
    status: 'live',
    version: '1.0.0'
  },
  {
    id: 'page-builder',
    name: 'Page Builder',
    icon: 'Layout',
    url: 'http://localhost:5700',
    description: 'Visual page editor',
    requiresAuth: true,
    category: 'content',
    status: 'live',
    version: '1.0.0'
  },
  {
    id: 'cms',
    name: 'CMS Manager',
    icon: 'FileText',
    url: 'http://localhost:5300',
    description: 'Content management',
    requiresAuth: true,
    category: 'content',
    status: 'partial',
    version: '0.5.0'
  },

  // 🟡 PARTIAL SERVICES
  {
    id: 'web',
    name: 'Website',
    icon: 'Globe',
    url: 'http://localhost:3000',
    description: 'Public website',
    requiresAuth: false,
    category: 'public',
    status: 'partial',
    version: '0.5.0'
  },
  {
    id: 'procurement',
    name: 'Procurement',
    icon: 'ShoppingCart',
    url: 'http://localhost:6700',
    description: 'Purchase management',
    requiresAuth: true,
    category: 'business',
    status: 'partial',
    version: '0.3.0'
  },
  {
    id: 'workflow-insights',
    name: 'Analytics',
    icon: 'BarChart',
    url: 'http://localhost:6800',
    description: 'Workflow analytics',
    requiresAuth: true,
    category: 'analytics',
    status: 'partial',
    version: '0.3.0'
  },

  // ❌ ALPHA SERVICES (Skeleton/Mock)
  {
    id: 'layout-editor',
    name: 'Layout Editor',
    icon: 'Grid',
    url: 'http://localhost:5800',
    description: 'Layout design tool',
    requiresAuth: true,
    category: 'creative',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'raster-editor',
    name: 'Image Editor',
    icon: 'Edit',
    url: 'http://localhost:5900',
    description: 'Raster image editing',
    requiresAuth: true,
    category: 'creative',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'photo-editor',
    name: 'Photo Editor',
    icon: 'Camera',
    url: 'http://localhost:6000',
    description: 'Advanced photo editing',
    requiresAuth: true,
    category: 'creative',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'video-editor',
    name: 'Video Editor',
    icon: 'Video',
    url: 'http://localhost:6100',
    description: 'Video editing suite',
    requiresAuth: true,
    category: 'creative',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'crm',
    name: 'CRM',
    icon: 'Users',
    url: 'http://localhost:6200',
    description: 'Customer relationship',
    requiresAuth: true,
    category: 'business',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'ecommerce',
    name: 'E-Commerce',
    icon: 'ShoppingBag',
    url: 'http://localhost:6300',
    description: 'Online store',
    requiresAuth: true,
    category: 'business',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'forum',
    name: 'Community',
    icon: 'MessageSquare',
    url: 'http://localhost:6400',
    description: 'Forum & discussions',
    requiresAuth: true,
    category: 'community',
    status: 'alpha',
    version: '0.1.0'
  },
  {
    id: 'support',
    name: 'Help Desk',
    icon: 'LifeBuoy',
    url: 'http://localhost:6500',
    description: 'Support tickets',
    requiresAuth: true,
    category: 'support',
    status: 'alpha',
    version: '0.1.0'
  },
]
```

### Step 1.2: Create Skeleton Apps (Template)

**Template**: `scripts/create-alpha-skeleton.sh`

```bash
#!/bin/bash
# Usage: ./scripts/create-alpha-skeleton.sh app-name port

APP_NAME=$1
PORT=$2

mkdir -p $APP_NAME

# Create package.json
cat > $APP_NAME/package.json <<EOF
{
  "name": "$APP_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p $PORT",
    "build": "next build",
    "start": "next start -p $PORT"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "lucide-react": "^0.294.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "typescript": "^5.0.0",
    "tailwindcss": "^3.3.5"
  }
}
EOF

# Create Next.js config
cat > $APP_NAME/next.config.js <<EOF
module.exports = {
  reactStrictMode: true,
  transpilePackages: ['@ewh/shared-widgets'],
}
EOF

# Create tsconfig
cat > $APP_NAME/tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

# Create Tailwind config
cat > $APP_NAME/tailwind.config.js <<EOF
module.exports = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Create src structure
mkdir -p $APP_NAME/src/{app,components,lib}

# Create main page
cat > $APP_NAME/src/app/page.tsx <<EOF
'use client'
import { useEffect, useState } from 'react'

export default function HomePage() {
  const [authContext, setAuthContext] = useState<any>(null)

  useEffect(() => {
    // Listen for auth context from shell
    const handleMessage = (event: MessageEvent) => {
      if (event.data.type === 'AUTH_CONTEXT') {
        setAuthContext(event.data)
      }
    }

    window.addEventListener('message', handleMessage)

    // Notify shell that iframe is ready
    if (window.parent !== window) {
      window.parent.postMessage({ type: 'IFRAME_READY' }, '*')
    }

    return () => window.removeEventListener('message', handleMessage)
  }, [])

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            $APP_NAME
          </h1>
          <p className="text-gray-600">
            Alpha Version - Coming Soon
          </p>
        </div>

        {authContext && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <h2 className="font-semibold text-blue-900 mb-2">
              🔗 Connected to Shell
            </h2>
            <div className="text-sm text-blue-700">
              <p>Tenant: {authContext.tenant?.name}</p>
              <p>User: {authContext.user?.email}</p>
            </div>
          </div>
        )}

        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold mb-4">Planned Features</h2>
          <ul className="space-y-2 text-gray-600">
            <li>• Feature 1 (Coming Soon)</li>
            <li>• Feature 2 (Coming Soon)</li>
            <li>• Feature 3 (Coming Soon)</li>
          </ul>
        </div>

        <div className="mt-6 text-center text-sm text-gray-500">
          This is an alpha preview. Full functionality will be implemented soon.
        </div>
      </div>
    </div>
  )
}
EOF

# Create globals.css
mkdir -p $APP_NAME/src/app
cat > $APP_NAME/src/app/globals.css <<EOF
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Create layout
cat > $APP_NAME/src/app/layout.tsx <<EOF
import './globals.css'

export const metadata = {
  title: '$APP_NAME',
  description: 'EWH Alpha Application',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
EOF

echo "✅ Created alpha skeleton for $APP_NAME on port $PORT"
EOF

chmod +x scripts/create-alpha-skeleton.sh
```

### Step 1.3: Generate All Skeleton Apps

```bash
# Create remaining skeleton apps
./scripts/create-alpha-skeleton.sh app-layout-editor 5800
./scripts/create-alpha-skeleton.sh app-raster-editor 5900
./scripts/create-alpha-skeleton.sh app-video-editor 6100
./scripts/create-alpha-skeleton.sh app-crm-frontend 6200
./scripts/create-alpha-skeleton.sh app-ecommerce-frontend 6300
./scripts/create-alpha-skeleton.sh app-forum-frontend 6400
./scripts/create-alpha-skeleton.sh app-support-frontend 6500
```

### Step 1.4: Update Shell UI

**Visual Status Badges** in sidebar:

```typescript
// app-shell-frontend/src/components/ServiceList.tsx

const StatusBadge = ({ status }: { status: string }) => {
  const styles = {
    live: 'bg-green-100 text-green-800 border-green-200',
    partial: 'bg-yellow-100 text-yellow-800 border-yellow-200',
    alpha: 'bg-gray-100 text-gray-600 border-gray-200',
  }

  return (
    <span className={`text-xs px-2 py-0.5 rounded border ${styles[status]}`}>
      {status.toUpperCase()}
    </span>
  )
}
```

---

## 🤖 Phase 2: Overnight Automation (Day 3)

### GitHub Actions Workflow

**File**: `.github/workflows/overnight-standardization.yml`

```yaml
name: Overnight Standardization

on:
  workflow_dispatch:
  schedule:
    - cron: '0 2 * * *'  # Run at 2 AM daily

jobs:
  standardize-styles:
    name: Standardize Tailwind Configs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Run style standardization
        run: |
          node scripts/standardize-tailwind.js

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions Bot"
          git config user.email "actions@github.com"
          git add .
          git diff --quiet && git diff --staged --quiet || \
            git commit -m "chore: standardize Tailwind configs [skip ci]"
          git push

  standardize-webhooks:
    name: Standardize Webhook Endpoints
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run webhook standardization
        run: |
          node scripts/standardize-webhooks.js

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions Bot"
          git config user.email "actions@github.com"
          git add .
          git diff --quiet && git diff --staged --quiet || \
            git commit -m "chore: standardize webhook endpoints [skip ci]"
          git push

  generate-api-contracts:
    name: Generate API Contracts
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Generate OpenAPI specs
        run: |
          node scripts/generate-api-contracts.js

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions Bot"
          git config user.email "actions@github.com"
          git add docs/api/
          git diff --quiet && git diff --staged --quiet || \
            git commit -m "docs: update API contracts [skip ci]"
          git push

  update-documentation:
    name: Update Documentation
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Generate app documentation
        run: |
          node scripts/generate-docs.js

      - name: Commit changes
        run: |
          git config user.name "GitHub Actions Bot"
          git config user.email "actions@github.com"
          git add docs/
          git diff --quiet && git diff --staged --quiet || \
            git commit -m "docs: update app documentation [skip ci]"
          git push
```

### Standardization Scripts

#### 1. Tailwind Standardization

**File**: `scripts/standardize-tailwind.js`

```javascript
const fs = require('fs')
const path = require('path')
const glob = require('glob')

const MASTER_TAILWIND_CONFIG = {
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        },
        // ... other colors
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['Fira Code', 'monospace'],
      },
      spacing: {
        // Custom spacing
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}

// Find all tailwind.config.js files
const configFiles = glob.sync('app-*/tailwind.config.js')

configFiles.forEach(file => {
  console.log(`Standardizing: ${file}`)

  const config = `module.exports = ${JSON.stringify(MASTER_TAILWIND_CONFIG, null, 2)}\n`

  fs.writeFileSync(file, config)
})

console.log(`✅ Standardized ${configFiles.length} Tailwind configs`)
```

#### 2. Webhook Standardization

**File**: `scripts/standardize-webhooks.js`

```javascript
const fs = require('fs')
const glob = require('glob')

const WEBHOOK_PATTERNS = {
  // Standard webhook endpoints format
  incoming: '/api/webhooks/:service/:action',
  outgoing: '/webhooks/send',

  // Standard headers
  headers: {
    'X-Webhook-Signature': 'HMAC-SHA256',
    'X-Webhook-ID': 'UUID',
    'X-Webhook-Timestamp': 'ISO8601',
  },

  // Standard payload format
  payload: {
    event: 'event.type',
    timestamp: 'ISO8601',
    tenant_id: 'UUID',
    data: {},
  },
}

// Generate webhook documentation for each service
const services = glob.sync('svc-*/README.md')

services.forEach(readme => {
  const serviceName = readme.split('/')[0].replace('svc-', '')

  const webhookDocs = `
## Webhook Endpoints

### Incoming Webhooks
\`\`\`
POST /api/webhooks/${serviceName}/:action
\`\`\`

### Outgoing Webhooks
This service can send webhooks to:
- Task completion events
- Status changes
- Error notifications

### Webhook Format
\`\`\`json
${JSON.stringify(WEBHOOK_PATTERNS.payload, null, 2)}
\`\`\`
  `

  // Append to README if not already present
  const content = fs.readFileSync(readme, 'utf-8')
  if (!content.includes('Webhook Endpoints')) {
    fs.appendFileSync(readme, webhookDocs)
    console.log(`✅ Added webhook docs to ${readme}`)
  }
})
```

#### 3. API Contract Generation

**File**: `scripts/generate-api-contracts.js`

```javascript
const fs = require('fs')
const path = require('path')
const glob = require('glob')

// Scan all svc-*/src/routes/*.ts files
// Generate OpenAPI specs automatically

const generateOpenAPISpec = (serviceName, routes) => {
  return {
    openapi: '3.0.0',
    info: {
      title: `${serviceName} API`,
      version: '1.0.0',
    },
    servers: [
      {
        url: `http://localhost:${getServicePort(serviceName)}`,
      },
    ],
    paths: routes,
  }
}

// Implementation...
// Generates docs/api/${service}.openapi.json for each service
```

---

## 🚢 Phase 3: Staging Deploy (Days 4-5)

### Docker Compose for Alpha Staging

**File**: `compose/docker-compose.alpha.yml`

```yaml
version: '3.8'

services:
  # All 19 apps + all services

  shell-frontend:
    build: ./app-shell-frontend
    ports:
      - "3150:3150"
    environment:
      - NODE_ENV=staging
      - NEXT_PUBLIC_AUTH_SERVICE_URL=http://svc-auth:4001
    depends_on:
      - svc-auth

  # ... all other apps

  # Services
  svc-auth:
    build: ./svc-auth
    ports:
      - "4001:4001"
    environment:
      - NODE_ENV=staging
      - DATABASE_URL=postgresql://ewh:password@postgres:5432/ewh_master

  # ... all other services

  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: ewh_master
      POSTGRES_USER: ewh
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Deploy Script

```bash
#!/bin/bash
# scripts/deploy-alpha-staging.sh

echo "🚀 Deploying Alpha to Staging..."

# Build all apps
docker-compose -f compose/docker-compose.alpha.yml build

# Run migrations
docker-compose -f compose/docker-compose.alpha.yml run --rm postgres-migrations

# Start all services
docker-compose -f compose/docker-compose.alpha.yml up -d

# Health check
./scripts/health-check-alpha.sh

echo "✅ Alpha deployed to staging!"
echo "Visit: http://staging.ewh.internal:3150"
```

---

## 🔄 Phase 4: Beta Iteration (Day 6+)

### App-by-App Implementation Priority

```
Week 1 (Days 6-12):
├─ Priority 1: DAM (Adobe plugins) - CRITICAL
├─ Priority 2: PM (workflow automation)
└─ Priority 3: Approvals (enterprise features)

Week 2 (Days 13-19):
├─ CMS Manager (full CRUD)
├─ Page Builder (visual editor)
└─ Layout Editor (template system)

Week 3 (Days 20-26):
├─ Photo Editor (basic filters)
├─ Raster Editor (advanced editing)
└─ Video Editor (timeline)

Week 4 (Days 27-33):
├─ CRM (contacts & deals)
├─ E-Commerce (products & orders)
└─ Forum (discussions)

Week 5+ (Day 34+):
├─ Support (ticketing)
├─ Procurement (purchase orders)
└─ Analytics (reporting)
```

### Continuous Deployment Strategy

```yaml
# .github/workflows/deploy-beta.yml

name: Deploy to Beta

on:
  push:
    branches:
      - main
    paths:
      - 'app-*/**'
      - 'svc-*/**'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed_apps: ${{ steps.changes.outputs.apps }}
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 2

      - name: Detect changed apps
        id: changes
        run: |
          CHANGED=$(git diff --name-only HEAD^ HEAD | grep -E '^app-' | cut -d/ -f1 | sort -u)
          echo "apps=$CHANGED" >> $GITHUB_OUTPUT

  deploy-apps:
    needs: detect-changes
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: ${{ fromJson(needs.detect-changes.outputs.changed_apps) }}
    steps:
      - name: Deploy ${{ matrix.app }}
        run: |
          docker build -t ${{ matrix.app }}:beta ./${{ matrix.app }}
          docker push registry.ewh.internal/${{ matrix.app }}:beta
          kubectl set image deployment/${{ matrix.app }} app=${{ matrix.app }}:beta
```

---

## 📊 Success Metrics

### Alpha Phase (Day 7)
- ✅ 19 apps visibili nella shell
- ✅ Tutte le app raggiungibili via routing
- ✅ Authentication flow funzionante
- ✅ Tenant switching attivo
- ✅ Mock data displayed correttamente

### Staging Phase (Day 10)
- ✅ Deploy completo in staging
- ✅ Tutti i servizi health check OK
- ✅ User flow testabile end-to-end
- ✅ Performance baseline stabilita

### Beta Phase (Day 30)
- ✅ 12+ app fully functional
- ✅ Core workflows implementati
- ✅ Real data in tutte le app
- ✅ User acceptance testing completato

---

## 🎯 Execution Plan per AI

### Parallel Track Assignment

**Claude Sonnet 4.5 Instance #1**: Shell Integration
```
Task: Integrate all 19 apps in shell service registry
- Update services.config.ts
- Create status badges UI
- Test navigation flow
Duration: 6h autonomous
```

**Claude Sonnet 4.5 Instance #2**: Skeleton Generation
```
Task: Generate 8 skeleton apps using template
- Run creation script for each app
- Test each app starts correctly
- Verify iframe communication
Duration: 8h autonomous
```

**GPT-5 Codex Instance #1**: Automation Scripts
```
Task: Create overnight standardization scripts
- Tailwind config standardization
- Webhook pattern enforcement
- API contract generation
Duration: 10h autonomous
```

**GPT-5 Codex Instance #2**: Docker Compose
```
Task: Create alpha staging docker-compose
- Define all 19 app services
- Configure networking
- Setup volumes and dependencies
Duration: 8h autonomous
```

### Overnight Run (Tonight)
```
23:00 - Launch all 4 instances in parallel
02:00 - Check progress via GitHub commits
08:00 - Review results, debug if needed
```

**Estimated completion**: 48h (with 15x velocity = ~3-4 calendar days)

---

## 📈 Timeline Projection

```
Day 1 (Oggi): Strategy complete ✅
Day 2-3: Shell integration + skeleton generation
Day 4: Overnight automation setup
Day 5-6: Alpha staging deploy
Day 7: Alpha COMPLETE ✅

Week 2: Iterate 4 priority apps to beta
Week 3: Iterate 4 more apps to beta
Week 4: Remaining 4 apps to beta
Week 5: Polish, testing, bug fixes

Day 35: BETA COMPLETE (12+ apps fully functional) ✅
```

**Target**: 15 Nov (Beta) → Achieved by ~10 Nov (5 days early)

---

## 🚀 Next Immediate Actions

1. **Execute skeleton script creation** (30 min)
2. **Generate 8 skeleton apps** (2h)
3. **Update shell service registry** (1h)
4. **Test local integration** (1h)
5. **Launch overnight automation setup** (tonight)

**Ready to execute?**

Commands to run:
```bash
# Create the skeleton script
# Generate all apps
# Start testing local integration
```

Vuoi che proceda con l'esecuzione?
