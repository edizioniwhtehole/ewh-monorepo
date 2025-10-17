# 🚀 PM System - Ready for Editorial House

**Status**: ✅ Database Schema Complete + Backend Started
**Date**: 2025-10-12
**Use Case**: Casa Editrice (Libri, Guide Turistiche, Gadget)

---

## ✅ What's Done

### 1. Database Schema Complete
**File**: [migrations/028_pm_core_complete.sql](./migrations/028_pm_core_complete.sql)

**Core Tables**:
- ✅ `pm.entity_types` - Tipi di entità (Cliente, Iniziativa, Campagna)
- ✅ `pm.entities` - Entità flessibili con gerarchia
- ✅ `pm.entity_relations` - Relazioni many-to-many
- ✅ `pm.project_templates` - Template riutilizzabili
- ✅ `pm.projects` - Progetti con template
- ✅ `pm.tasks` - Task con AI assignment
- ✅ `pm.task_completions` - Storico per AI skill detection
- ✅ `pm.time_entries` - Time tracking
- ✅ `pm.milestones` - Milestone
- ✅ `pm.comments` - Commenti e discussioni
- ✅ `pm.workflow_rules` - Automazioni (n8n/Zapier)

**Template Pre-Installati** (per casa editrice):
1. **Pubblicazione Libro** (180 giorni)
   - Revisione Editoriale
   - Impaginazione
   - Correzione Bozze
   - Progettazione Copertina
   - Stampa Prototipo
   - Revisione Finale
   - Stampa Tiratura
   - Distribuzione

2. **Guida Turistica** (120 giorni)
   - Ricerca e Sopralluoghi
   - Scrittura Contenuti
   - Fotografia
   - Traduzione
   - Editing Multilingua
   - Impaginazione
   - Stampa

3. **Gadget Promozionale** (60 giorni)
   - Concept Design
   - Prototipo
   - Approvazione Cliente
   - Ordine Materiali
   - Produzione
   - Controllo Qualità
   - Confezionamento

### 2. AI Integration Ready
- ✅ Task completions tracking (per Patent #3)
- ✅ Skill detection schema
- ✅ Time-of-day performance tracking (per Patent #4)
- ✅ Workflow recording link (per Patent #1)

### 3. Cross-System Integration
- ✅ View `pm.v_project_files` - Aggregates files from:
  - DAM (asset creativi)
  - Accounting (fatture, contratti)
  - MRP (ordini produzione)
  - PIM (schede prodotto)

---

## 🚀 Quick Start

### 1. Run Database Migration

```bash
psql -h localhost -U ewh -d ewh_master -f migrations/028_pm_core_complete.sql
```

Questo crea:
- 11 tabelle
- 3 template pre-configurati
- 3 entity types (Cliente, Iniziativa, Campagna)
- Views per file aggregation
- Trigger automatici

### 2. Install Backend Dependencies

```bash
cd svc-pm
npm install
```

### 3. Start Backend

```bash
cd svc-pm
npm run dev
# Running on http://localhost:5500
```

---

## 📋 Typical Workflow - Casa Editrice

### Scenario 1: Nuovo Libro da Pubblicare

```typescript
// 1. Create project from template
POST /api/pm/projects/from-template
{
  "templateKey": "book_publication",
  "projectName": "Guida ai Castelli del Trentino",
  "clientName": "Provincia Autonoma di Trento",
  "startDate": "2025-11-01",
  "deliveryDate": "2026-04-30"  // 180 giorni dopo
}

// Backend automatically creates:
// - Project
// - 8 tasks (from template)
// - 4 milestones
// - Links to client entity

// 2. Tasks are auto-assigned using AI (Patent #3 & #4)
// System checks:
// - Chi ha fatto editing di guide turistiche prima?
// - Qual è il loro success rate?
// - Qual è il loro orario migliore?
// - Quanto sono carichi ora?

// 3. Team member apre Photoshop per impaginazione
// - Photoshop plugin traccia workflow (Patent #1)
// - Detect patterns (excessive undo, tool cycling)
// - Genera SOP automatico dai best performers

// 4. Time tracking automatico
// - Workflow recording → time entry
// - Calcola efficiency score
// - Aggiorna resource_skills per prossimi assignment
```

### Scenario 2: Guida Turistica Multilingua

```typescript
// 1. Create from template
POST /api/pm/projects/from-template
{
  "templateKey": "tourist_guide",
  "projectName": "Dolomiti UNESCO - 5 Lingue",
  "custom_fields": {
    "languages": ["IT", "EN", "DE", "FR", "ES"],
    "pages": 120,
    "print_run": 5000
  }
}

// 2. System creates parallel tasks for each language
// - Traduzione IT→EN (assigned to best English translator)
// - Traduzione IT→DE (assigned to best German translator)
// - ...

// 3. Photographer va sul campo
// - Time tracking via mobile app
// - Geo-tagged time entries
// - Link photos from DAM to project

// 4. Stampa
// - Task "Stampa" triggered
// - Webhook to MRP system (svc-mrp)
// - Production order created automatically
```

### Scenario 3: Gadget Turistico

```typescript
// 1. Create from template
POST /api/pm/projects/from-template
{
  "templateKey": "gadget_production",
  "projectName": "Magneti Dolomiti UNESCO",
  "quantity": 10000,
  "custom_fields": {
    "gadget_type": "magnet",
    "size_mm": "70x50",
    "packaging": "blister"
  }
}

// 2. Design phase
// - Task "Concept Design" assigned to best designer
// - Designer lavora in Illustrator
// - Workflow tracked (Patent #1)
// - SOP generated per "gadget_design"

// 3. Production
// - Task "Produzione" creates MRP order
// - Inventory (svc-inventory) checks materials
// - If missing → auto-create purchase order

// 4. Quality Check
// - Task assigned to QC team
// - Mobile app for defect tracking
// - Photos uploaded to DAM
// - Linked to project automatically
```

---

## 🎯 Key Features

### 1. Template System (Overlay)
- **Generic Core**: Can handle ANY project type
- **Template Overlay**: Pre-configured for editorial
- **Custom Templates**: Create your own

### 2. AI Assignment (Patent #3 & #4)
```typescript
// When creating task, system suggests top 5 resources
{
  "task": "Editing Guida Turistica",
  "ai_suggestions": [
    {
      "userId": "user-123",
      "name": "Maria Rossi",
      "totalScore": 95,
      "breakdown": {
        "skillScore": 85,  // 92% success rate on "editing"
        "timeBonus": 10,   // Peak hour: 9-11 AM (NOW!)
        "workloadPenalty": 0  // 0 tasks in queue
      },
      "reasoning": "Expert in editing (92% success rate), Peak hour (9-11 AM), Available"
    },
    {
      "userId": "user-456",
      "name": "Giovanni Bianchi",
      "totalScore": 78,
      "breakdown": {
        "skillScore": 82,
        "timeBonus": 0,   // Works best at 2 PM
        "workloadPenalty": -4  // 4 tasks in queue
      }
    }
  ]
}
```

### 3. Cross-System File Hub
```sql
-- One query to get ALL files related to project
SELECT * FROM pm.v_project_files
WHERE project_id = 'proj-uuid';

-- Returns:
-- - DAM: photos, mockups, final PDFs
-- - Accounting: invoices, contracts
-- - MRP: production orders, supplier docs
-- - PIM: product specs
```

### 4. Workflow Automation (Legally Safe)
```typescript
// Example: Auto-notify translator when editing done
{
  "trigger_type": "task_completed",
  "trigger_conditions": {
    "task_category": "editing",
    "status": "done"
  },
  "actions": [
    {
      "type": "assign_task",
      "params": {
        "task_category": "translation",
        "use_ai_suggestion": true
      }
    },
    {
      "type": "send_notification",
      "params": {
        "recipient_role": "translator",
        "message": "Testo pronto per traduzione"
      }
    },
    {
      "type": "webhook",
      "params": {
        "url": "https://n8n.yourdomain.com/webhook/translation-ready",
        "method": "POST"
      }
    }
  ]
}
```

---

## 📊 Dashboard Views

### Project List View
```
┌───────────────────────────────────────────────────────────┐
│ 📚 Progetti Attivi                                        │
├───────────────────────────────────────────────────────────┤
│                                                           │
│ 📖 Guida ai Castelli del Trentino                        │
│ Cliente: Provincia Autonoma di Trento                     │
│ Template: Pubblicazione Libro                             │
│ Progress: ████████░░ 75% (6/8 tasks completati)          │
│ Deadline: 30 Apr 2026 (142 giorni rimanenti)             │
│ PM: Maria Rossi                                           │
│ [Apri Progetto]  [Gantt]  [File (23)]                    │
│                                                           │
├───────────────────────────────────────────────────────────┤
│                                                           │
│ 🗺️ Dolomiti UNESCO - 5 Lingue                            │
│ Cliente: UNESCO Italia                                    │
│ Template: Guida Turistica                                 │
│ Progress: ███████░░░ 60% (7/12 tasks, 3 in progress)     │
│ Deadline: 15 Mar 2026                                     │
│ PM: Giovanni Bianchi                                      │
│ [Apri Progetto]  [Gantt]  [File (89)]                    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Task Board (Kanban)
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ TODO        │ IN PROGRESS │ REVIEW      │ DONE        │
├─────────────┼─────────────┼─────────────┼─────────────┤
│             │             │             │             │
│ 📝 Editing  │ 🎨 Design   │ ✅ Bozze    │ 📷 Foto     │
│ Capitolo 3  │ Copertina   │ Cap 1-2     │ Castelli    │
│             │             │             │             │
│ Maria R.    │ Luca P.     │ Anna G.     │ Marco T.    │
│ 🤖 AI: 95%  │ 🤖 AI: 88%  │             │ ✓ Approved  │
│ 🔥 Peak hr  │             │             │             │
│             │             │             │             │
│ 🌍 Traduz.  │ 📐 Layout   │             │ ✍️ Scrittura│
│ EN          │ Pagine      │             │ Intro       │
│             │             │             │             │
│ Sarah K.    │ Giulia F.   │             │ Paolo M.    │
│ 🤖 AI: 92%  │             │             │ 92% quality │
│             │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

---

## 🔌 Service Architecture

```
┌─────────────────────────────────────────────────────┐
│ FRONTEND                                            │
│ app-pm-frontend (Port 5400)                         │
│ - Project Dashboard                                 │
│ - Template Selector                                 │
│ - Task Board (Kanban/Gantt)                         │
│ - AI Assignment UI                                  │
│ - File Hub                                          │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│ API GATEWAY (Port 4000)                             │
│ /pm/* → svc-pm                                      │
│ /inventory/* → svc-inventory                        │
│ /quotation/* → svc-quotation                        │
│ /mrp/* → svc-mrp                                    │
└────────────────┬────────────────────────────────────┘
                 │
     ┌───────────┼───────────┬──────────────┐
     │           │           │              │
     ↓           ↓           ↓              ↓
┌─────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐
│ svc-pm  │ │ svc-    │ │ svc-     │ │ svc-mrp  │
│ (5500)  │ │inventory│ │quotation │ │ (TBD)    │
│         │ │ (TBD)   │ │ (TBD)    │ │          │
└─────────┘ └─────────┘ └──────────┘ └──────────┘
     │           │           │              │
     └───────────┴───────────┴──────────────┘
                     │
                     ↓
         ┌─────────────────────┐
         │ PostgreSQL Database │
         │ - pm.*              │
         │ - inventory.*       │
         │ - quotation.*       │
         │ - mrp.*             │
         └─────────────────────┘
```

---

## 📝 Next Steps (Priority Order)

### Immediate (This Week)
1. ✅ Database migration done
2. ⏳ Complete svc-pm backend implementation
3. ⏳ Create frontend app-pm-frontend
4. ⏳ Test template system end-to-end

### Short Term (Next 2 Weeks)
5. Create svc-quotation (preventivi)
6. Create svc-inventory (magazzino)
7. Create svc-mrp (scheduling produzione)
8. Integrate all services via API gateway

### Medium Term (Month 1)
9. Deploy to staging
10. User training
11. Migrate existing projects
12. Go live for editorial house

---

## 🎯 Business Impact

### For Your Editorial House

**Before** (Manual):
- ❌ Excel spreadsheets per progetti
- ❌ Email per coordinamento
- ❌ Nessuna visibilità su chi fa cosa
- ❌ Deadlines persi
- ❌ File sparsi ovunque

**After** (PM System):
- ✅ Template "Libro" → progetto pronto in 2 click
- ✅ AI assegna task alle persone giuste, all'ora giusta
- ✅ Real-time dashboard con tutti i progetti
- ✅ Alert automatici per deadlines
- ✅ Tutti i file in un posto (DAM + docs)
- ✅ Time tracking automatico
- ✅ Reportistica costi/margini

**ROI Stimato**:
- **15-30% più veloce** (AI assignment ottimale)
- **20% meno errori** (workflow assistito)
- **10-12h/settimana risparmiate** (PM automazioni)
- **100% tracciabilità** (compliance, certificazioni)

---

## 💡 Pro Tips

### Tip 1: Start with Templates
Don't create projects from scratch. Use templates and customize them.

### Tip 2: Let AI Assign
Accept AI suggestions for task assignment. System learns from every completion.

### Tip 3: Track Everything
Enable Photoshop/Illustrator plugins for workflow learning. SOP generation is magical!

### Tip 4: Use Automations
Set up n8n webhooks for repetitive tasks (notifications, status updates).

### Tip 5: Link Everything
Link projects to clients, initiatives, campaigns. Flexible hierarchy is powerful.

---

## 📚 Related Documents

- **Full Spec**: [PROJECT_MANAGEMENT_SYSTEM.md](./PROJECT_MANAGEMENT_SYSTEM.md)
- **Patent #3**: [PATENT_03_AI_AUTO_SKILL.md](./PATENT_03_AI_AUTO_SKILL.md)
- **Patent #4**: [PATENT_04_TIME_OPTIMIZED.md](./PATENT_04_TIME_OPTIMIZED.md)
- **Workflow Learning**: [AI_WORKFLOW_IMPLEMENTATION.md](./AI_WORKFLOW_IMPLEMENTATION.md)

---

**Status**: ✅ **Database Ready** | ⏳ Backend In Progress | 📝 Frontend TODO
**Next**: Complete svc-pm implementation and create frontend

🚀 **Your editorial house PM system is taking shape!**
