# Box Designer - Upgrade Enterprise Plan

## Situazione Attuale

### Cosa Abbiamo
**App standalone**: `app-box-designer` (~5,633 righe di codice)
- Stack: React + Vite + Three.js + TypeScript
- Funzionalità core implementate (v1.3-1.4):
  - Design parametrico scatole (rettangolari, tronchi piramide)
  - Generazione fustelle FEFCO (0201 RSC, STE, RTE)
  - Visualizzatore 3D interattivo
  - Sistema nesting avanzato (Skyline Packing)
  - Database 8 macchine reali (Heidelberg, BOBST, HP Indigo, ecc.)
  - Gestione fibra carta (orizzontale/verticale/qualsiasi)
  - Export multi-formato (SVG, PDF, DXF, AI, PLT)
  - Calcoli volume, peso, area, costi
  - Sistema quotatura automatica

### Problemi Identificati

#### 1. **Architettura**
- ❌ **App standalone senza backend** - tutto lato client
- ❌ **Nessuna autenticazione/multi-tenancy** - non SaaS
- ❌ **Nessun database** - progetti non salvati persistentemente
- ❌ **Nessuna API** - impossibile integrare con altri sistemi
- ❌ **Frontend monolitico** - non scalabile

#### 2. **Funzionalità Mancanti Enterprise**
- ❌ **Libreria templates** - nessun catalogo scatole riutilizzabili
- ❌ **Versioning progetti** - nessuna cronologia modifiche
- ❌ **Collaborazione** - nessun lavoro multi-utente
- ❌ **Workflow approvazioni** - nessun processo review
- ❌ **Asset management** - nessuna integrazione DAM per artwork
- ❌ **Preventivazione avanzata** - calcoli base ma nessun pricing engine
- ❌ **Gestione clienti** - nessun CRM integration
- ❌ **Ordini e produzione** - nessun tracking ordini
- ❌ **Analytics** - nessuna metrica business

#### 3. **Integrazione Piattaforma**
- ❌ **Non integrato con EWH Platform** - isolato dal resto
- ❌ **Nessun SSO** - login separato
- ❌ **Nessun settings waterfall** - configurazione hardcoded
- ❌ **Nessun permissions system** - tutti possono tutto
- ❌ **Nessun webhook/eventi** - impossibile automazione

#### 4. **UX/UI Professionale**
- ⚠️ **UI basica** - funzionale ma non enterprise-grade
- ⚠️ **Nessun onboarding** - learning curve ripida
- ⚠️ **Nessun help contestuale** - documentazione esterna
- ⚠️ **Nessuna validazione avanzata** - errori non preventivi

#### 5. **Scalabilità e Deploy**
- ❌ **Nessun containerization** - no Docker/orchestration
- ❌ **Nessun CI/CD** - deploy manuale
- ❌ **Nessun monitoring** - impossibile tracciare errori
- ❌ **Nessuna cache strategy** - performance non ottimizzate

---

## Piano Upgrade Enterprise

### Fase 1: Architettura Backend (2-3 settimane)

#### 1.1 Creare Microservizio Backend
**Nuovo servizio**: `svc-box-designer` (o `svc-packaging`)

```
svc-box-designer/
├── src/
│   ├── controllers/
│   │   ├── projects.controller.ts        # CRUD progetti
│   │   ├── templates.controller.ts       # Libreria templates
│   │   ├── library.controller.ts         # Scatole salvate
│   │   ├── quotes.controller.ts          # Preventivazione
│   │   ├── orders.controller.ts          # Gestione ordini
│   │   └── exports.controller.ts         # Export asincroni
│   ├── services/
│   │   ├── geometry.service.ts           # Calcoli geometrici (dal frontend)
│   │   ├── dieline.service.ts            # Generazione fustelle
│   │   ├── nesting.service.ts            # Algoritmi nesting
│   │   ├── pricing.service.ts            # Engine pricing
│   │   ├── pdf.service.ts                # Generazione PDF server-side
│   │   └── export.service.ts             # Export multi-formato
│   ├── models/
│   │   ├── Project.ts
│   │   ├── Template.ts
│   │   ├── BoxDesign.ts
│   │   ├── Quote.ts
│   │   └── Order.ts
│   ├── routes/
│   └── migrations/
├── package.json
└── Dockerfile
```

**Database Schema** (PostgreSQL):
```sql
-- migrations/080_box_designer_system.sql

-- Progetti box design
CREATE TABLE box_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    created_by UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'draft', -- draft, review, approved, production
    box_config JSONB NOT NULL,          -- Configurazione completa scatola
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

-- Versioning progetti
CREATE TABLE box_project_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES box_projects(id),
    version_number INTEGER NOT NULL,
    box_config JSONB NOT NULL,
    changes_description TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Templates libreria
CREATE TABLE box_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID,                     -- NULL = template pubblico globale
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),              -- fefco_0201, tuck_end, custom, etc.
    fefco_code VARCHAR(20),
    thumbnail_url TEXT,
    box_config JSONB NOT NULL,
    tags TEXT[],
    is_public BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Preventivi
CREATE TABLE box_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    project_id UUID REFERENCES box_projects(id),
    quote_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID REFERENCES crm_contacts(id),
    quantity INTEGER NOT NULL,
    machine_id VARCHAR(100),            -- Riferimento al database macchine
    sheet_size VARCHAR(50),
    material VARCHAR(100),
    unit_cost DECIMAL(10,4),
    setup_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    production_time_hours DECIMAL(6,2),
    nesting_efficiency DECIMAL(5,2),
    valid_until DATE,
    status VARCHAR(50) DEFAULT 'draft', -- draft, sent, accepted, rejected, expired
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Ordini produzione
CREATE TABLE box_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    quote_id UUID REFERENCES box_quotes(id),
    project_id UUID NOT NULL REFERENCES box_projects(id),
    customer_id UUID REFERENCES crm_contacts(id),
    quantity INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, in_production, completed, shipped, cancelled
    priority VARCHAR(20) DEFAULT 'normal',
    due_date DATE,
    production_notes TEXT,
    assigned_to UUID REFERENCES users(id),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Export jobs (per gestione async)
CREATE TABLE box_export_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    project_id UUID NOT NULL REFERENCES box_projects(id),
    format VARCHAR(20) NOT NULL,        -- svg, pdf, dxf, ai, plt
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    file_url TEXT,
    error_message TEXT,
    requested_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Macchine produzione (migrazione da file TypeScript a DB)
CREATE TABLE box_machines (
    id VARCHAR(100) PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(id), -- NULL = macchine globali disponibili a tutti
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,          -- offset_press, digital_press, die_cutter, combined
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    max_sheet_width INTEGER NOT NULL,
    max_sheet_height INTEGER NOT NULL,
    min_sheet_width INTEGER,
    min_sheet_height INTEGER,
    gripper_margins JSONB NOT NULL,     -- {front, back, left, right}
    speed_sheets_per_hour INTEGER,
    cost_per_sheet DECIMAL(10,4),
    cost_per_hour DECIMAL(10,2),
    setup_time_minutes INTEGER,
    supported_materials JSONB,
    grain_preference VARCHAR(20),       -- horizontal, vertical, any
    capabilities JSONB,                 -- creasing, perforation, etc.
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Analytics e metrics
CREATE TABLE box_design_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    project_id UUID REFERENCES box_projects(id),
    event_type VARCHAR(100) NOT NULL,   -- project_created, quote_generated, export_completed, etc.
    event_data JSONB,
    user_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_box_projects_tenant ON box_projects(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_projects_status ON box_projects(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_box_templates_category ON box_templates(category);
CREATE INDEX idx_box_templates_public ON box_templates(is_public) WHERE is_public = true;
CREATE INDEX idx_box_quotes_tenant ON box_quotes(tenant_id);
CREATE INDEX idx_box_quotes_customer ON box_quotes(customer_id);
CREATE INDEX idx_box_orders_tenant ON box_orders(tenant_id);
CREATE INDEX idx_box_orders_status ON box_orders(status);
CREATE INDEX idx_box_machines_tenant ON box_machines(tenant_id);
CREATE INDEX idx_box_machines_type ON box_machines(type) WHERE is_active = true;
```

#### 1.2 API Endpoints

```typescript
// Projects
GET    /api/box/projects              - List progetti
GET    /api/box/projects/:id          - Get progetto
POST   /api/box/projects              - Create progetto
PUT    /api/box/projects/:id          - Update progetto
DELETE /api/box/projects/:id          - Delete (soft)
POST   /api/box/projects/:id/duplicate - Duplicate progetto
GET    /api/box/projects/:id/versions - List versioni
POST   /api/box/projects/:id/versions - Create nuova versione

// Templates
GET    /api/box/templates             - List templates (tenant + pubblici)
GET    /api/box/templates/:id         - Get template
POST   /api/box/templates             - Create template
PUT    /api/box/templates/:id         - Update template
DELETE /api/box/templates/:id         - Delete template
POST   /api/box/templates/:id/use     - Crea progetto da template
GET    /api/box/templates/categories  - List categorie

// Quotes
GET    /api/box/quotes                - List preventivi
GET    /api/box/quotes/:id            - Get preventivo
POST   /api/box/quotes                - Genera preventivo
PUT    /api/box/quotes/:id            - Update preventivo
DELETE /api/box/quotes/:id            - Delete preventivo
POST   /api/box/quotes/:id/send       - Invia a cliente
POST   /api/box/quotes/:id/accept     - Accetta preventivo
GET    /api/box/quotes/:id/pdf        - Export PDF preventivo

// Orders
GET    /api/box/orders                - List ordini
GET    /api/box/orders/:id            - Get ordine
POST   /api/box/orders                - Create ordine
PUT    /api/box/orders/:id            - Update ordine
PUT    /api/box/orders/:id/status     - Update status
DELETE /api/box/orders/:id            - Cancel ordine

// Export
POST   /api/box/export/:projectId/:format - Export progetto (async)
GET    /api/box/export/jobs/:id       - Status export job
GET    /api/box/export/jobs/:id/download - Download file

// Machines
GET    /api/box/machines              - List macchine disponibili
GET    /api/box/machines/:id          - Get macchina
POST   /api/box/machines              - Create macchina custom
PUT    /api/box/machines/:id          - Update macchina
DELETE /api/box/machines/:id          - Delete macchina

// Calculations (server-side per consistency)
POST   /api/box/calculate/geometry    - Calcoli geometrici
POST   /api/box/calculate/nesting     - Calcolo nesting
POST   /api/box/calculate/pricing     - Calcolo pricing

// Analytics
GET    /api/box/analytics/dashboard   - Metriche dashboard
GET    /api/box/analytics/projects    - Analytics progetti
GET    /api/box/analytics/quotes      - Analytics preventivi
```

---

### Fase 2: Refactoring Frontend (1-2 settimane)

#### 2.1 Trasformare in App Platform-Integrated

**Nuovo frontend**: `app-packaging-frontend` (rinominare da `app-box-designer`)

```typescript
// src/services/api.service.ts
import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:5850';

export const boxAPI = {
  // Projects
  getProjects: () => axios.get(`${API_BASE}/api/box/projects`),
  getProject: (id: string) => axios.get(`${API_BASE}/api/box/projects/${id}`),
  createProject: (data: BoxProjectInput) => axios.post(`${API_BASE}/api/box/projects`, data),
  updateProject: (id: string, data: Partial<BoxProjectInput>) =>
    axios.put(`${API_BASE}/api/box/projects/${id}`, data),

  // Templates
  getTemplates: (filters?: TemplateFilters) =>
    axios.get(`${API_BASE}/api/box/templates`, { params: filters }),

  // Quotes
  generateQuote: (projectId: string, quoteData: QuoteInput) =>
    axios.post(`${API_BASE}/api/box/quotes`, { projectId, ...quoteData }),

  // Export
  exportProject: (projectId: string, format: ExportFormat) =>
    axios.post(`${API_BASE}/api/box/export/${projectId}/${format}`),
};
```

#### 2.2 Integrare ShellAuthContext

```typescript
// src/App.tsx
import { useAuth } from '../../../shared/ShellAuthContext';

function App() {
  const { user, tenant } = useAuth();

  if (!user) {
    return <div>Please login via EWH Platform</div>;
  }

  return <BoxDesignerApp user={user} tenant={tenant} />;
}
```

#### 2.3 Aggiungere Gestione Progetti

```typescript
// src/pages/ProjectsListPage.tsx
export function ProjectsListPage() {
  const { data: projects } = useQuery(['box-projects'], () => boxAPI.getProjects());

  return (
    <div>
      <PageHeader
        title="Packaging Projects"
        actions={
          <Button onClick={createNewProject}>
            <Plus /> New Project
          </Button>
        }
      />

      <ProjectsGrid projects={projects} />
    </div>
  );
}
```

---

### Fase 3: Features Enterprise (3-4 settimane)

#### 3.1 Libreria Templates

```typescript
// src/pages/TemplatesLibraryPage.tsx
export function TemplatesLibraryPage() {
  const [category, setCategory] = useState<string | null>(null);
  const { data: templates } = useQuery(
    ['box-templates', category],
    () => boxAPI.getTemplates({ category })
  );

  return (
    <div>
      <TemplateCategoryFilter onChange={setCategory} />
      <TemplatesGrid
        templates={templates}
        onUseTemplate={handleUseTemplate}
      />
    </div>
  );
}
```

Templates pre-configurati:
- FEFCO 0201 - RSC (varie dimensioni)
- FEFCO 0421 - Tray with lid
- FEFCO 0427 - Crash lock bottom
- Tuck End Boxes (STE, RTE)
- Pillow Packs
- Gable Top Boxes
- Custom shapes

#### 3.2 Sistema Preventivazione Avanzata

```typescript
// src/services/pricing.service.ts
export class PricingEngine {
  calculateQuote(config: BoxConfig, quantity: number, machine: Machine): Quote {
    // 1. Calcola area materiale necessaria
    const materialArea = this.calculateMaterialArea(config);

    // 2. Calcola nesting efficiency
    const nesting = this.calculateNesting(config, machine);
    const sheetsNeeded = Math.ceil(quantity / nesting.itemsPerSheet);

    // 3. Costi materiale
    const materialCost = this.calculateMaterialCost(
      materialArea,
      sheetsNeeded,
      config.material
    );

    // 4. Costi produzione
    const productionTime = this.calculateProductionTime(sheetsNeeded, machine);
    const productionCost = productionTime * machine.costPerHour;

    // 5. Setup costs
    const setupCost = machine.setupTimeMinutes / 60 * machine.costPerHour;

    // 6. Markup e margini
    const totalCost = (materialCost + productionCost + setupCost) * (1 + MARKUP);

    return {
      quantity,
      unitCost: totalCost / quantity,
      setupCost,
      totalCost,
      productionTimeHours: productionTime,
      nestingEfficiency: nesting.efficiency,
      breakdown: {
        material: materialCost,
        production: productionCost,
        setup: setupCost,
      }
    };
  }
}
```

#### 3.3 Workflow Approvazioni

Integrazione con `svc-approvals`:

```typescript
// Quando un progetto è pronto per review
await approvalsAPI.createApprovalRequest({
  entityType: 'box_project',
  entityId: projectId,
  approvers: [supervisorId, clientId],
  metadata: {
    projectName: project.name,
    thumbnailUrl: project.thumbnailUrl,
  }
});

// Webhook listener per status changes
webhooks.on('approval.completed', async (event) => {
  if (event.entityType === 'box_project') {
    await boxAPI.updateProject(event.entityId, {
      status: event.approved ? 'approved' : 'rejected'
    });
  }
});
```

#### 3.4 Integrazione DAM per Artwork

```typescript
// src/components/ArtworkUploader.tsx
export function ArtworkUploader({ projectId }: Props) {
  const handleUpload = async (file: File) => {
    // Upload to DAM
    const asset = await damAPI.uploadAsset({
      file,
      category: 'packaging_artwork',
      metadata: {
        projectId,
        type: 'print_ready'
      }
    });

    // Link to project
    await boxAPI.updateProject(projectId, {
      artworkAssetId: asset.id
    });
  };

  return <DAMAssetPicker onSelect={handleUpload} />;
}
```

#### 3.5 Analytics Dashboard

```typescript
// src/pages/BoxAnalyticsDashboard.tsx
export function BoxAnalyticsDashboard() {
  const { data: metrics } = useQuery(['box-analytics'], () =>
    boxAPI.getAnalytics()
  );

  return (
    <div>
      <MetricCard
        title="Total Projects"
        value={metrics.totalProjects}
        trend={metrics.projectsGrowth}
      />
      <MetricCard
        title="Quotes Generated"
        value={metrics.quotesGenerated}
        trend={metrics.quotesGrowth}
      />
      <MetricCard
        title="Avg. Nesting Efficiency"
        value={`${metrics.avgNestingEfficiency}%`}
      />
      <MetricCard
        title="Total Revenue (Quotes)"
        value={formatCurrency(metrics.totalQuotedRevenue)}
      />

      <Chart
        type="line"
        data={metrics.projectsOverTime}
        title="Projects Created Over Time"
      />

      <Chart
        type="bar"
        data={metrics.templateUsage}
        title="Most Used Templates"
      />
    </div>
  );
}
```

---

### Fase 4: UX/UI Enterprise (1-2 settimane)

#### 4.1 Onboarding & Tutorial

```typescript
// src/components/OnboardingTour.tsx
import Joyride from 'react-joyride';

const TOUR_STEPS = [
  {
    target: '.template-library',
    content: 'Start by selecting a template or create from scratch',
  },
  {
    target: '.box-configurator',
    content: 'Configure your box dimensions and options here',
  },
  {
    target: '.3d-viewer',
    content: 'See your box in 3D and interact with it',
  },
  {
    target: '.dieline-viewer',
    content: 'View and export the die-cutting template',
  },
  {
    target: '.nesting-optimizer',
    content: 'Optimize material usage with our nesting algorithm',
  },
  {
    target: '.quote-generator',
    content: 'Generate professional quotes for your clients',
  }
];

export function OnboardingTour() {
  const [run, setRun] = useState(!localStorage.getItem('onboarding_completed'));

  return (
    <Joyride
      steps={TOUR_STEPS}
      run={run}
      continuous
      callback={(data) => {
        if (data.status === 'finished') {
          localStorage.setItem('onboarding_completed', 'true');
        }
      }}
    />
  );
}
```

#### 4.2 Help Contestuale

```typescript
// src/components/ContextualHelp.tsx
export function ContextualHelp({ topic }: Props) {
  const helpContent = {
    'grain_direction': {
      title: 'Grain Direction',
      content: 'Paper grain should run parallel to fold lines to prevent cracking...',
      videoUrl: 'https://help.ewh.com/videos/grain-direction.mp4'
    },
    'fefco_codes': {
      title: 'FEFCO Box Codes',
      content: 'FEFCO is the international standard for box classification...',
      linkUrl: 'https://www.fefco.org/code'
    }
  };

  return (
    <Popover>
      <PopoverTrigger>
        <HelpCircle className="text-muted" />
      </PopoverTrigger>
      <PopoverContent>
        <h4>{helpContent[topic].title}</h4>
        <p>{helpContent[topic].content}</p>
        {helpContent[topic].videoUrl && (
          <VideoPlayer src={helpContent[topic].videoUrl} />
        )}
      </PopoverContent>
    </Popover>
  );
}
```

#### 4.3 Validazione Avanzata

```typescript
// src/utils/validation.ts
export class BoxValidator {
  validateConfig(config: BoxConfig): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    // Validazioni dimensioni
    if (config.length <= 0 || config.width <= 0 || config.height <= 0) {
      errors.push({ field: 'dimensions', message: 'All dimensions must be positive' });
    }

    // Warn se proporzioni strane
    const aspectRatio = Math.max(config.length, config.width) /
                        Math.min(config.length, config.width);
    if (aspectRatio > 5) {
      warnings.push({
        field: 'dimensions',
        message: 'Unusual aspect ratio may affect structural integrity',
        severity: 'medium'
      });
    }

    // Validazione materiale vs dimensioni
    if (config.material === 'cardboard_300g' && config.height > 300) {
      warnings.push({
        field: 'material',
        message: 'Consider thicker material for boxes taller than 300mm',
        severity: 'high'
      });
    }

    // Validazione grain direction
    if (config.grainDirection !== 'any' && !this.isGrainDirectionOptimal(config)) {
      warnings.push({
        field: 'grainDirection',
        message: 'Current grain direction may cause folding issues',
        severity: 'medium',
        suggestion: 'Rotate box 90° or change grain preference'
      });
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }
}
```

---

### Fase 5: Integrazione Piattaforma (1 settimana)

#### 5.1 Settings Waterfall

```sql
-- migrations/080_box_designer_system.sql (aggiunta)

-- Settings box designer
INSERT INTO platform_settings (category, key, value_type, default_value, description, scope) VALUES
-- Global
('box_designer', 'enabled', 'boolean', 'true', 'Enable box designer module', 'global'),
('box_designer', 'default_units', 'string', 'mm', 'Default measurement units (mm/cm/in)', 'global'),
('box_designer', 'public_templates_enabled', 'boolean', 'true', 'Enable public template library', 'global'),

-- Tenant
('box_designer', 'max_projects', 'integer', '100', 'Max projects per tenant', 'tenant'),
('box_designer', 'custom_machines_enabled', 'boolean', 'true', 'Allow custom machine configs', 'tenant'),
('box_designer', 'export_formats', 'json', '["svg","pdf","dxf"]', 'Allowed export formats', 'tenant'),
('box_designer', 'pricing_markup', 'number', '1.3', 'Default pricing markup multiplier', 'tenant'),

-- User
('box_designer', 'auto_save_interval', 'integer', '30', 'Auto-save interval (seconds)', 'user'),
('box_designer', 'default_grain_direction', 'string', 'horizontal', 'Default grain direction', 'user'),
('box_designer', 'default_machine_id', 'string', null, 'Default machine for nesting', 'user');
```

#### 5.2 Permissions

```sql
-- migrations/080_box_designer_system.sql (aggiunta)

-- Permissions box designer
INSERT INTO permissions (name, description, category) VALUES
('box.projects.view', 'View box projects', 'box_designer'),
('box.projects.create', 'Create box projects', 'box_designer'),
('box.projects.edit', 'Edit box projects', 'box_designer'),
('box.projects.delete', 'Delete box projects', 'box_designer'),
('box.templates.view', 'View box templates', 'box_designer'),
('box.templates.create', 'Create box templates', 'box_designer'),
('box.templates.edit', 'Edit box templates', 'box_designer'),
('box.templates.publish', 'Publish public templates', 'box_designer'),
('box.quotes.view', 'View quotes', 'box_designer'),
('box.quotes.create', 'Create quotes', 'box_designer'),
('box.quotes.send', 'Send quotes to clients', 'box_designer'),
('box.orders.view', 'View orders', 'box_designer'),
('box.orders.create', 'Create orders', 'box_designer'),
('box.orders.manage', 'Manage production orders', 'box_designer'),
('box.machines.view', 'View machines', 'box_designer'),
('box.machines.manage', 'Manage custom machines', 'box_designer'),
('box.analytics.view', 'View analytics', 'box_designer');

-- Role presets
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'admin' AND p.category = 'box_designer';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'designer' AND p.name IN (
  'box.projects.view', 'box.projects.create', 'box.projects.edit',
  'box.templates.view', 'box.templates.create',
  'box.quotes.view', 'box.quotes.create'
);
```

#### 5.3 Webhook Events

```typescript
// svc-box-designer/src/services/webhook.service.ts
export const BOX_WEBHOOK_EVENTS = {
  PROJECT_CREATED: 'box.project.created',
  PROJECT_UPDATED: 'box.project.updated',
  PROJECT_APPROVED: 'box.project.approved',
  QUOTE_GENERATED: 'box.quote.generated',
  QUOTE_SENT: 'box.quote.sent',
  QUOTE_ACCEPTED: 'box.quote.accepted',
  ORDER_CREATED: 'box.order.created',
  ORDER_STATUS_CHANGED: 'box.order.status_changed',
  EXPORT_COMPLETED: 'box.export.completed',
};

// Trigger example
await webhookService.trigger({
  event: BOX_WEBHOOK_EVENTS.QUOTE_GENERATED,
  tenantId,
  data: {
    quoteId: quote.id,
    projectId: quote.projectId,
    totalCost: quote.totalCost,
    customerId: quote.customerId,
  }
});
```

#### 5.4 Admin Panel Integration

```typescript
// Aggiungi pagina al admin panel
// migrations/080_box_designer_system.sql (aggiunta)

INSERT INTO admin_pages (slug, title, icon, category, component_path, permissions_required, sort_order) VALUES
('box-designer-settings', 'Box Designer', 'Package', 'modules', '/admin/box-designer/settings', '["admin.settings.manage"]', 180);
```

---

### Fase 6: Deployment & DevOps (1 settimana)

#### 6.1 Containerizzazione

```dockerfile
# svc-box-designer/Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 5850

CMD ["npm", "start"]
```

```yaml
# compose/docker-compose.dev.yml (aggiunta)
services:
  svc-box-designer:
    build: ../svc-box-designer
    ports:
      - "5850:5850"
    environment:
      - NODE_ENV=development
      - DB_HOST=postgres
      - DB_NAME=ewh_platform
      - PORT=5850
      - DAM_SERVICE_URL=http://svc-dam:5100
      - CRM_SERVICE_URL=http://svc-crm-unified:6200
    volumes:
      - ../svc-box-designer:/app
      - /app/node_modules
    depends_on:
      - postgres

  app-packaging-frontend:
    build: ../app-packaging-frontend
    ports:
      - "5851:5851"
    environment:
      - VITE_API_URL=http://localhost:5850
      - VITE_SHELL_URL=http://localhost:3000
    volumes:
      - ../app-packaging-frontend:/app
      - /app/node_modules
```

#### 6.2 CI/CD Pipeline

```yaml
# .github/workflows/box-designer-ci.yml
name: Box Designer CI/CD

on:
  push:
    paths:
      - 'svc-box-designer/**'
      - 'app-packaging-frontend/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 20

      - name: Test Backend
        run: |
          cd svc-box-designer
          npm ci
          npm run test
          npm run lint

      - name: Test Frontend
        run: |
          cd app-packaging-frontend
          npm ci
          npm run test
          npm run lint

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Production
        run: |
          # Deploy logic here
```

#### 6.3 Monitoring

```typescript
// svc-box-designer/src/middleware/monitoring.ts
import { collectMetrics } from '@ewh/metrics-collector';

app.use(collectMetrics({
  service: 'svc-box-designer',
  metrics: [
    'http_requests_total',
    'http_request_duration_seconds',
    'box_projects_created_total',
    'box_quotes_generated_total',
    'box_export_jobs_total',
    'nesting_calculation_duration_seconds',
  ]
}));
```

---

## Confronto: Prima vs Dopo

### Prima (Attuale)
```
app-box-designer/
├── Standalone app
├── No backend
├── No persistence
├── No multi-user
├── No integrations
├── 5,633 LOC
└── Proof of concept quality
```

### Dopo (Enterprise)
```
svc-box-designer/          # Backend API
├── REST API completa
├── Database PostgreSQL
├── Multi-tenancy
├── Authentication/Authorization
├── Webhook system
└── ~8,000 LOC

app-packaging-frontend/    # Frontend integrato
├── Platform integration
├── SSO authentication
├── Projects management
├── Templates library
├── Quote generator
├── Analytics dashboard
└── ~10,000 LOC

Total: ~18,000 LOC enterprise-grade
```

---

## Effort Estimation

| Fase | Descrizione | Tempo | Complessità |
|------|-------------|-------|-------------|
| 1 | Backend Architecture | 2-3 settimane | Alta |
| 2 | Frontend Refactoring | 1-2 settimane | Media |
| 3 | Enterprise Features | 3-4 settimane | Alta |
| 4 | UX/UI Improvements | 1-2 settimane | Media |
| 5 | Platform Integration | 1 settimana | Media |
| 6 | Deployment & DevOps | 1 settimana | Bassa |
| **TOTALE** | **Fine-to-fine** | **9-13 settimane** | **~2-3 mesi** |

---

## ROI e Business Case

### Competitor Pricing (riferimento)
- **Packlane** (online box designer): $99-499/mese + % vendite
- **Boxshot** (3D mockup): $120/licenza perpetua (limitato)
- **Artios CAD** (Esko): $10,000+ licenza + manutenzione
- **Adobe Illustrator + plugins**: $54.99/mese (per designer, no automation)

### EWH Box Designer Enterprise Pricing Strategy
```
Tier 1 - Starter: $49/mese
  - 10 progetti attivi
  - Template pubblici
  - Export base (SVG, PDF)
  - 100 quote/mese

Tier 2 - Professional: $149/mese
  - 50 progetti attivi
  - Custom templates
  - Export avanzato (DXF, AI, PLT)
  - 500 quote/mese
  - API access
  - Custom machines

Tier 3 - Enterprise: $499/mese
  - Progetti illimitati
  - White label
  - Webhook automation
  - Advanced analytics
  - Dedicated support
  - Custom integrations
```

### Break-even Analysis
- 10 clienti Tier 1 = $490/mese = $5,880/anno
- 5 clienti Tier 2 = $745/mese = $8,940/anno
- 2 clienti Tier 3 = $998/mese = $11,976/anno

**Target first year**: 50 clienti mix → ~$60,000 ARR

**Development cost**: 2.5 mesi × $15,000/mese (developer) = $37,500
**Break-even**: ~7-8 mesi

---

## Competitive Advantages

### 1. **Unico sistema integrato**
- CRM integrato (clienti, preventivi, ordini)
- DAM integrato (artwork, assets)
- Workflow integrato (approvazioni, task)
- PM integrato (progetti, timeline)

### 2. **API-First Architecture**
- Possibilità di white-label per rivenditori
- Integrazione in e-commerce esistenti
- Automazione via webhook
- Ecosystem di plugin

### 3. **AI-Ready**
```typescript
// Future: AI suggestions
POST /api/box/ai/suggest-design
{
  "productDescription": "12 wine bottles gift box",
  "productDimensions": { length: 300, width: 250, height: 100 },
  "material": "corrugated_cardboard",
  "quantity": 1000
}

Response:
{
  "suggestedDesigns": [
    {
      "fefcoCode": "0421",
      "name": "Tray with Separate Lid",
      "boxConfig": { ... },
      "estimatedCost": 2.45,
      "nestingEfficiency": 82,
      "reasoning": "Best for gift boxes, allows reuse..."
    }
  ]
}
```

### 4. **Scalabilità**
- Multi-tenant architecture
- Cloud-native deployment
- Horizontal scaling
- CDN per assets

---

## Roadmap Post-MVP Enterprise

### Q1 2026 - Advanced Features
- [ ] Cilindri e forme custom
- [ ] Import/export 3D (STEP, IGES)
- [ ] Simulazione resistenza strutturale
- [ ] Color management (CMYK separations)

### Q2 2026 - Collaboration
- [ ] Real-time multi-user editing
- [ ] Comments & annotations
- [ ] Version compare visual diff
- [ ] Approval workflows UI

### Q3 2026 - AI Integration
- [ ] AI design suggestions
- [ ] Auto-optimization nesting (genetic algorithm)
- [ ] Image-to-box (foto prodotto → suggerimenti dimensioni)
- [ ] Chatbot assistente designer

### Q4 2026 - Marketplace
- [ ] Template marketplace
- [ ] Artwork marketplace (designer grafici)
- [ ] Machine profiles sharing
- [ ] Plugin ecosystem

---

## Conclusione

**Situazione attuale**: Hai un ottimo proof-of-concept tecnico (~5,600 LOC) con funzionalità core solide.

**Problema**: È un giochetto isolato, non un prodotto enterprise integrabile e scalabile.

**Soluzione**: 2-3 mesi di sviluppo strutturato per trasformarlo in:
- Sistema enterprise-grade
- Integrato nella piattaforma EWH
- Multi-tenant SaaS
- API-first per integrazioni
- Pricing strategy competitiva
- ROI positivo in <12 mesi

**Prossimo step**: Vuoi che inizi con la Fase 1 (Backend Architecture)?
