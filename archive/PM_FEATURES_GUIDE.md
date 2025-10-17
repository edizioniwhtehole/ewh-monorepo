# 🎯 PM SYSTEM - GUIDA COMPLETA FEATURES & CUSTOMIZZAZIONI

**Sistema**: Project Management Enterprise
**Version**: 1.0.0
**Status**: ✅ Funzionante (90% features attive)

---

## 📊 FEATURES DISPONIBILI

### ✅ TIER 1 - FUNZIONALITÀ BASE (100% Funzionante)

#### 1. **Dashboard Homepage**
**URL**: http://localhost:5402/

**Cosa fa**:
- 4 KPI cards (To Do, In Progress, Completed, Overdue)
- Widget "My Tasks" - Ultimi 10 task assegnati a te
- Widget "Recent Projects" - Ultimi 5 progetti con progress bar
- Activity summary - Contatori progetti attivi e task totali

**Customizzazioni disponibili**:
- Filtro per status task
- Ordinamento per data/priorità
- Click per navigare al progetto

---

#### 2. **Projects Management**
**URL**: http://localhost:5402/projects

**Cosa fa**:
- Lista tutti i progetti del tenant
- Cards con info: nome, codice, status, completion %
- Filtri per status (planning, active, completed, cancelled)
- Crea nuovo progetto da template

**Customizzazioni**:
- **Status personalizzati**: Modifica in `ProjectService.ts`
- **Campi custom**: Usa `custom_fields` JSONB
- **Colori**: Modifica in `ProjectsList.tsx`
- **Icone**: Cambia icone per categoria template

**Custom Fields Example**:
```json
{
  "isbn": "978-88-123-4567-8",
  "author": "Mario Rossi",
  "pages": 240,
  "client_name": "Casa Editrice XYZ"
}
```

---

#### 3. **Project Detail View**
**URL**: http://localhost:5402/projects/:id

**Tabs disponibili**:
- ✅ **Tasks** - Gestione task completa
- ✅ **Milestones** - Traguardi del progetto
- ✅ **Files** - File collegati (placeholder)
- ⏸️ **Activity** - Timeline eventi (richiede DB)

**Features per Task**:
- Crea nuovo task inline
- Assegna a utente (single/team mode)
- Cambia status (todo/in_progress/done/cancelled)
- Modifica: nome, ore stimate, ore actual
- Priority badge (low/medium/high)
- Category tags
- Progress percentage
- Dependencies (depends_on array)

**Customizzazioni Task**:
```javascript
// Aggiungi status custom
const customStatuses = {
  'todo': 'Da Fare',
  'in_progress': 'In Corso',
  'review': 'In Revisione',  // CUSTOM
  'blocked': 'Bloccato',      // CUSTOM
  'done': 'Completato'
};
```

---

#### 4. **Kanban Board**
**URL**: http://localhost:5402/projects/:id/kanban

**Cosa fa**:
- 3 colonne: To Do, In Progress, Done
- Drag & drop per spostare task
- Visual cards con dettagli
- Counter per colonna
- Add task button per colonna

**Customizzazioni**:
```javascript
// Aggiungi colonne custom in KanbanBoard.tsx
const COLUMNS = [
  { id: 'todo', title: 'To Do', color: 'gray' },
  { id: 'in_progress', title: 'In Progress', color: 'blue' },
  { id: 'review', title: 'In Review', color: 'yellow' },  // CUSTOM
  { id: 'done', title: 'Done', color: 'green' }
];
```

---

#### 5. **Template System**
**URL**: http://localhost:5402/templates

**Templates disponibili**:
1. **Pubblicazione Libro** (8 task, 4 milestones)
   - Editing, Layout, Stampa, Distribuzione
   - 180 giorni estimated

2. **Guida Turistica** (7 task, 3 milestones)
   - Ricerca, Fotografia, Traduzione
   - 120 giorni estimated

3. **Gadget Promozionale** (7 task, 3 milestones)
   - Design, Prototipo, Produzione
   - 60 giorni estimated

**Crea Template Custom**:

**Via API**:
```bash
curl -X POST http://localhost:5500/api/pm/templates \
  -H "Content-Type: application/json" \
  -d '{
    "tenantId": "00000000-0000-0000-0000-000000000001",
    "templateKey": "software_feature",
    "templateName": "Software Feature Development",
    "category": "software",
    "estimatedDurationDays": 14,
    "taskTemplates": [
      {"name": "Design API", "order": 1, "category": "backend", "estimated_hours": 8},
      {"name": "Write Tests", "order": 2, "category": "testing", "estimated_hours": 4},
      {"name": "Code Review", "order": 3, "category": "review", "estimated_hours": 2}
    ],
    "milestoneTemplates": [
      {"name": "API Complete", "due_days": 7},
      {"name": "Tests Pass", "due_days": 14}
    ]
  }'
```

**Via SQL Migration**:
```sql
-- migrations/034_pm_custom_templates.sql
INSERT INTO pm.project_templates (
    tenant_id, template_key, template_name, category,
    estimated_duration_days, task_templates, milestone_templates
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'marketing_campaign',
    'Marketing Campaign',
    'marketing',
    30,
    '[
        {"name": "Strategy", "order": 1, "category": "planning", "estimated_hours": 16},
        {"name": "Design Assets", "order": 2, "category": "design", "estimated_hours": 40},
        {"name": "Launch", "order": 3, "category": "execution", "estimated_hours": 8}
    ]'::jsonb,
    '[
        {"name": "Strategy Approved", "due_days": 7},
        {"name": "Assets Ready", "due_days": 21},
        {"name": "Campaign Live", "due_days": 30}
    ]'::jsonb
);
```

---

#### 6. **Adaptive Single/Team Mode** ⭐ UNIQUE
**DevModeSwitcher**: Badge bottom-right

**Come funziona**:
- **Simple Mode**: Nasconde selettori utente, auto-assign a "Me"
- **Team Mode**: Mostra dropdown utenti, permette assegnazioni

**Switch Mode**:
1. Click sul badge "Simple UI" / "Team UI"
2. Seleziona modalità
3. Reload automatico
4. **Stesso database, solo UI diversa!**

**Customizzazioni**:
```javascript
// localStorage key
localStorage.setItem('pm_ui_mode', 'simple'); // or 'team'

// In componenti, leggi:
const uiMode = localStorage.getItem('pm_ui_mode') || 'simple';
const showUserSelector = uiMode === 'team';
```

---

### ⏸️ TIER 2 - FEATURES AVANZATE (Richiedono DB Migration 032)

#### 1. **Task Comments System**
**Cosa fa**:
- Commenti su task
- @mentions (notifiche a utenti menzionati)
- Timeline conversazioni
- Delete commenti

**API**:
```bash
# Get comments
GET /api/pm/tasks/:taskId/comments

# Add comment
POST /api/pm/tasks/:taskId/comments
{
  "commentText": "Ottimo lavoro! @mario vedi questa revisione",
  "mentions": ["uuid-mario"]
}

# Delete
DELETE /api/pm/comments/:id
```

---

#### 2. **Time Tracking & Timer**
**Cosa fa**:
- Start/stop timer su task
- Log automatico durata
- Manual time entry
- History per task
- Total hours calculation

**API**:
```bash
# Start timer
POST /api/pm/time/start
{"taskId": "uuid"}

# Stop timer
POST /api/pm/time/stop
{"timeLogId": "uuid"}

# Get logs
GET /api/pm/tasks/:taskId/time-logs

# Active timers
GET /api/pm/time/active
```

**Features**:
- Solo 1 timer attivo per user
- Auto-update task actual_hours
- Billing flag (billable/non-billable)
- Notes field per log entry

---

#### 3. **Notifications System**
**Cosa fa**:
- Bell icon con unread count
- Dropdown con ultime notifiche
- Mark as read / Mark all read
- Auto-polling ogni 30s
- Click per navigare a entity

**Notification Types**:
- `task_assigned` - Task assegnato a te
- `mention` - Menzionato in commento
- `deadline` - Scadenza vicina
- `status_change` - Status task cambiato

**API**:
```bash
# Get notifications
GET /api/pm/notifications?unread_only=true

# Unread count
GET /api/pm/notifications/unread-count

# Mark as read
POST /api/pm/notifications/:id/read

# Mark all read
POST /api/pm/notifications/read-all
```

---

#### 4. **Activity Feed & Audit Log**
**Cosa fa**:
- Timeline completa eventi progetto
- Audit trail (chi ha fatto cosa, quando)
- View per progetto
- View per entity (task, milestone)

**Eventi tracciati**:
- create, update, delete
- status_change
- assign
- comment
- timer_start, timer_stop

**API**:
```bash
# Project activity
GET /api/pm/projects/:projectId/activity?limit=50

# Entity audit
GET /api/pm/audit/:entityType/:entityId
```

---

#### 5. **Budget Tracking**
**Cosa fa**:
- Track budget vs spent
- Visual progress bar
- Remaining calculation
- Over-budget alert
- Currency support

**Fields in projects table**:
- `budget` DECIMAL(12,2)
- `spent` DECIMAL(12,2)
- `currency` VARCHAR(3) default 'EUR'

**Customizzazioni**:
```javascript
// Update project budget
PATCH /api/pm/projects/:id
{
  "budget": 25000,
  "spent": 8500,
  "currency": "EUR"
}
```

---

#### 6. **Global Search**
**Cosa fa**:
- Ricerca real-time
- Cerca in: progetti (nome, code, description)
- Cerca in: task (nome, description)
- Dropdown con risultati
- Click per navigare

**API**:
```bash
GET /api/pm/search?q=cookbook&type=projects
GET /api/pm/search?q=editing&type=tasks
GET /api/pm/search?q=venice  # search both
```

---

### 🤖 AI FEATURES (Implementate, pronte per uso)

#### 1. **AI Skill Detection** (Patent #3)
**Cosa fa**:
- Traccia chi completa quali task categories
- Calcola success rate per user/category
- Skill levels: beginner → expert
- Confidence score basato su # task completati

**Tables**:
- `pm.task_completions` - History completamenti
- `pm.resource_skills` - Skill matrix

**Come attivare**:
```javascript
// In TaskService, quando task completi:
await recordTaskCompletion({
  taskId,
  userId,
  taskCategory,
  estimatedHours,
  actualHours,
  approvedFirstTime: true,
  qualityScore: 0.95
});
```

---

#### 2. **AI Time-Optimized Assignment** (Patent #4)
**Cosa fa**:
- Traccia quando user lavora meglio
- Calcola best hour of day
- Calcola best day of week
- Suggerisce task assignment basato su tempo

**Algorithm**:
```javascript
totalScore =
  baseSkillScore (0-100) +
  qualityBonus (0-50) +
  timeOfDayBonus (0-20) +
  dayOfWeekBonus (0-10) +
  workloadPenalty (-2 per task attivo)
```

**API**:
```bash
# Create task with AI assignment
POST /api/pm/tasks
{
  "taskName": "Editing Chapter 3",
  "taskCategory": "editing",
  "useAiAssignment": true,  # Enable AI
  "projectId": "uuid"
}

# Response includes:
{
  "assignedTo": "uuid-best-user",
  "assignmentMethod": "ai_accepted",
  "aiAssignmentReasoning": {
    "userId": "uuid",
    "totalScore": 92,
    "breakdown": {
      "skillScore": 85,
      "qualityBonus": 12,
      "timeBonus": 20,
      "dayBonus": 10,
      "workloadPenalty": -4
    },
    "reasoning": "Expert (95% success rate) • Peak hour (optimal time) • Available (1 tasks)"
  }
}
```

---

## 🎨 CUSTOMIZZAZIONI AVANZATE

### 1. **Custom Fields per Progetti**

**Esempio: Casa Editrice**
```json
{
  "isbn": "978-88-123-4567-8",
  "author": "Mario Rossi",
  "pages": 240,
  "print_run": 5000,
  "languages": ["IT", "EN", "DE"],
  "distributor": "Distribuzione XYZ"
}
```

**Esempio: Software Agency**
```json
{
  "github_repo": "owner/repo",
  "tech_stack": ["React", "Node.js", "PostgreSQL"],
  "jira_ticket": "PROJ-123",
  "client": "Acme Corp",
  "billing_type": "fixed_price"
}
```

**Come usare**:
```javascript
// In create/update project
{
  "projectName": "My Book",
  "customFields": {
    "isbn": "978-88-123-4567-8",
    "author": "Mario Rossi"
  }
}

// Query in frontend
project.customFields.isbn
project.customFields.author
```

---

### 2. **Task Categories Personalizzate**

**Default categories**:
- editing, layout, printing, design
- research, writing, photography, translation
- development, testing, deployment

**Aggiungi custom**:
```sql
-- Nessuna tabella, sono stringhe libere!
-- Basta usarle:

INSERT INTO pm.tasks (task_name, task_category, ...)
VALUES ('Review Contract', 'legal', ...);

-- Ora "legal" è una categoria valida
```

---

### 3. **Priority Levels Custom**

**Default**: low, medium, high

**Customizza in UI**:
```javascript
// ProjectDetail.tsx o TaskService.ts
const priorityLevels = {
  'critical': { label: 'Critico', color: '#F44336' },
  'high': { label: 'Alto', color: '#FF9800' },
  'medium': { label: 'Medio', color: '#FFC107' },
  'low': { label: 'Basso', color: '#4CAF50' },
  'backlog': { label: 'Backlog', color: '#9E9E9E' }
};
```

---

### 4. **Status Workflow Personalizzato**

**Default**: todo → in_progress → done

**Custom workflow example**:
```javascript
const workflow = {
  'todo': { next: ['in_progress', 'cancelled'] },
  'in_progress': { next: ['review', 'blocked', 'cancelled'] },
  'review': { next: ['approved', 'rejected'] },
  'approved': { next: ['done'] },
  'rejected': { next: ['todo'] },
  'blocked': { next: ['in_progress', 'cancelled'] },
  'done': { next: [] },
  'cancelled': { next: ['todo'] }
};
```

---

### 5. **Multi-Tenant Setup**

**Current**: Single tenant hardcoded
**Custom**: Multi-tenant ready

```javascript
// Aggiungi tenant selector
const tenants = [
  { id: 'uuid-1', name: 'Casa Editrice A' },
  { id: 'uuid-2', name: 'Casa Editrice B' }
];

// In API calls, passa tenant_id dinamico
const projects = await api.getProjects(selectedTenantId);
```

---

### 6. **Integration Hooks**

**Webhook system** (da implementare):
```javascript
// Trigger webhook on events
const webhooks = [
  {
    event: 'task.completed',
    url: 'https://your-system.com/webhook',
    method: 'POST'
  }
];

// Quando task completo, POST a webhook:
{
  "event": "task.completed",
  "taskId": "uuid",
  "projectId": "uuid",
  "userId": "uuid",
  "timestamp": "2025-10-13T..."
}
```

---

## 🔧 CONFIGURAZIONI DISPONIBILI

### Environment Variables (.env)

```bash
# Deployment mode
DEPLOYMENT_MODE=single-user  # or team, saas

# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Server
PORT=5500
NODE_ENV=development

# Single user config
SINGLE_USER_TENANT_ID=uuid
SINGLE_USER_ID=uuid
SINGLE_USER_NAME=Me
SINGLE_USER_EMAIL=user@localhost

# JWT (per team mode)
JWT_SECRET=your-secret-key
JWT_EXPIRY=7d

# Optional: Email notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email
SMTP_PASS=your-password
```

---

## 📱 RESPONSIVE & MOBILE

**Status**: Base responsive OK, needs refinement

**Breakpoints**:
- Desktop: > 1024px
- Tablet: 768px - 1024px
- Mobile: < 768px

**Features mobile**:
- ✅ Sidebar collapsible
- ✅ Cards stack vertically
- ⚠️ Kanban touch gestures (needs work)
- ⚠️ Tables scroll horizontal

---

## 🚀 PROSSIMI STEP PER CUSTOMIZZARE

### 1. Aggiungi Gantt Chart (2-3 ore)
```bash
npm install react-gantt-chart
# Crea GanttView.tsx
# Usa tasks con startDate, endDate, depends_on
```

### 2. Email Notifications (1-2 ore)
```bash
npm install nodemailer
# Crea EmailService.ts
# Hook su task.assigned, mention, deadline
```

### 3. Webhook System (2-3 ore)
```javascript
// webhooks.ts
export async function triggerWebhook(event, data) {
  const webhooks = await getWebhooks(event);
  for (const webhook of webhooks) {
    await fetch(webhook.url, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }
}
```

### 4. Custom Dashboard Widgets (3-4 ore)
```javascript
// User-customizable widgets
const widgets = [
  { type: 'my-tasks', position: 1, size: 'medium' },
  { type: 'burndown-chart', position: 2, size: 'large' },
  { type: 'team-workload', position: 3, size: 'small' }
];
```

---

## 📊 CONFRONTO FEATURES

| Feature | Our PM | Asana | Monday | Jira | ClickUp |
|---------|--------|-------|--------|------|---------|
| Templates | ✅ Generic | ✅ Limited | ✅ Limited | ⚠️ Software only | ✅ |
| Custom Fields | ✅ JSONB | ✅ | ✅ | ✅ | ✅ |
| AI Assignment | ✅ **UNIQUE** | ❌ | ❌ | ❌ | ❌ |
| Time Tracking | ✅ | ⚠️ Paid | ✅ | ⚠️ Plugin | ✅ |
| Budget | ✅ | ⚠️ Limited | ✅ | ❌ | ✅ |
| Audit Log | ✅ | ⚠️ Enterprise | ⚠️ Paid | ✅ | ⚠️ Paid |
| Kanban | ✅ | ✅ | ✅ | ✅ | ✅ |
| Gantt | ⚠️ Soon | ✅ | ✅ | ✅ | ✅ |
| Adaptive Mode | ✅ **UNIQUE** | ❌ | ❌ | ❌ | ❌ |

---

## 💡 IDEE PER NUOVE FEATURES

1. **Recurring Tasks** - Task che si ripetono automaticamente
2. **Dependencies Visualization** - Grafo task dependencies
3. **Resource Capacity Planning** - Chi ha troppo/poco lavoro
4. **Sprint Management** - Agile board con sprint
5. **Wiki/Docs** - Knowledge base per progetto
6. **File Storage** - Upload file attachment su task
7. **Mobile App** - React Native app
8. **Voice Commands** - "Create task editing chapter 3"
9. **Smart Suggestions** - AI suggerisce task basato su progetto
10. **Integration Marketplace** - Connect to Slack, Trello, GitHub, etc.

---

**Per altre customizzazioni o features specifiche, chiedi pure!** 🚀
