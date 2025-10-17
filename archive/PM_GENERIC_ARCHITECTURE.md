# PM System - Generic Architecture

**Status**: ✅ Universal, Industry-Agnostic
**Philosophy**: Core system is 100% generic. Industry-specific logic goes into **templates**.

---

## 🎯 Design Philosophy

### Core Principle
The PM system is **completely generic** and can handle projects from **any industry**:
- Software development
- Construction
- Publishing (casa editrice)
- Marketing campaigns
- Event planning
- Manufacturing
- Healthcare
- Education
- Legal case management
- ...literally ANY project-based work

### How It Works
1. **Core System** = Generic tables & logic (projects, tasks, milestones)
2. **Templates** = Industry-specific workflows (inserted as data, not hardcoded)
3. **Custom Fields** = Flexible JSONB for industry-specific metadata

---

## 📦 Database Structure

### Core Tables (100% Generic)

#### `pm.projects`
Generic project container. Works for:
- Book publication (casa editrice)
- Website development (software)
- Building construction (edilizia)
- Marketing campaign
- Product launch
- Legal case
- ...anything!

**Key Fields**:
- `project_name` - Works for any project
- `status` - User-defined (planning, active, done, etc.)
- `custom_fields` JSONB - Industry-specific data goes here
- `template_id` - Optional link to template

#### `pm.tasks`
Generic task/activity. Works for:
- "Editing chapter 3" (publishing)
- "Write API endpoint" (software)
- "Pour concrete foundation" (construction)
- "Design billboard" (marketing)

**Key Fields**:
- `task_category` - User-defined categories
- `assigned_to` - AI assignment ready
- `custom_fields` JSONB - Task-specific metadata

#### `pm.project_templates`
User-defined workflow templates.

**Structure**:
```json
{
  "template_key": "book_publication",  // or "api_feature", "building_permit"
  "template_name": "Pubblicazione Libro",  // or anything
  "category": "editorial",  // user-defined
  "task_templates": [
    {"name": "Editing", "category": "editing", "estimated_hours": 80},
    // ...any tasks for any industry
  ],
  "milestone_templates": [
    {"name": "Draft Complete", "due_days": 60}
  ]
}
```

---

## 🏗️ Template System

Templates are **data**, not code. Anyone can create templates for their industry.

### Example: Publishing House (Casa Editrice)

**Migration**: `029_pm_editorial_templates.sql`

Templates:
1. **Book Publication** (Pubblicazione Libro)
   - Tasks: Editing, Layout, Printing, Distribution
   - Duration: 180 days

2. **Tourist Guide** (Guida Turistica)
   - Tasks: Research, Writing, Photography, Translation
   - Duration: 120 days

3. **Gadget Production**
   - Tasks: Design, Prototype, Manufacturing, QA
   - Duration: 60 days

### Example: Software Development

**Migration**: `030_pm_software_templates.sql` (you create this)

Templates:
1. **API Feature**
   - Tasks: Design API, Write Code, Write Tests, Code Review, Deploy
   - Duration: 14 days

2. **Bug Fix**
   - Tasks: Reproduce, Fix, Test, Deploy
   - Duration: 3 days

3. **Mobile App**
   - Tasks: UI Design, Frontend, Backend, QA, App Store Submit
   - Duration: 90 days

### Example: Construction

**Migration**: `031_pm_construction_templates.sql` (you create this)

Templates:
1. **Residential Building**
   - Tasks: Permits, Foundation, Framing, Roofing, Electrical, Plumbing, Finishing
   - Duration: 365 days

2. **Renovation**
   - Tasks: Demolition, Rebuild, Inspection
   - Duration: 60 days

---

## 💡 Custom Fields

Each industry can store specific metadata in `custom_fields` JSONB.

### Publishing (Casa Editrice)
```json
{
  "isbn": "978-88-123-4567-8",
  "author": "Mario Rossi",
  "pages": 240,
  "print_run": 5000,
  "languages": ["IT", "EN", "DE"]
}
```

### Software Development
```json
{
  "github_repo": "owner/repo",
  "tech_stack": ["React", "Node.js", "PostgreSQL"],
  "jira_ticket": "PROJ-123",
  "environment": "production"
}
```

### Construction
```json
{
  "building_permit": "BP-2025-001",
  "square_meters": 450,
  "floors": 3,
  "contractor_license": "LIC-123456"
}
```

---

## 🤖 AI Features (Industry-Agnostic)

### Patent #3: AI Skill Detection
The AI learns which users are best at which **task categories**.

**Works for any industry**:
- Publishing: "editing", "layout", "translation"
- Software: "backend", "frontend", "devops"
- Construction: "electrical", "plumbing", "framing"

The system tracks:
- Who completes tasks in category X
- Their success rate (approved first time?)
- Their speed (actual vs estimated hours)

### Patent #4: Time-Optimized Assignment
The AI learns when each user performs best.

**Example**:
- Maria is 20% faster at editing in the morning (9-11 AM)
- Giovanni is best at design in the afternoon (2-4 PM)
- System auto-suggests tasks at optimal times

**Industry agnostic** - works for any task type.

---

## 📊 How to Add Your Industry

### Step 1: Create Template Migration

```sql
-- migrations/030_pm_YOUR_INDUSTRY_templates.sql

INSERT INTO pm.project_templates (
    tenant_id,
    template_key,
    template_name,
    category,
    description,
    estimated_duration_days,
    task_templates,
    milestone_templates
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'your_workflow_key',
    'Your Workflow Name',
    'your_industry',  -- 'legal', 'healthcare', 'events', etc.
    'Description of this workflow',
    30,  -- estimated days
    '[
        {"name": "Task 1", "category": "category1", "estimated_hours": 10, "order": 1},
        {"name": "Task 2", "category": "category2", "estimated_hours": 20, "order": 2}
    ]'::jsonb,
    '[
        {"name": "Milestone 1", "due_days": 15},
        {"name": "Milestone 2", "due_days": 30}
    ]'::jsonb
);
```

### Step 2: Run Migration

```bash
psql -h localhost -U ewh -d ewh_master -f migrations/030_pm_YOUR_INDUSTRY_templates.sql
```

### Step 3: Use Template

```bash
curl -X POST http://localhost:5500/api/pm/projects/from-template \
  -H "Content-Type: application/json" \
  -d '{
    "tenantId": "00000000-0000-0000-0000-000000000001",
    "templateKey": "your_workflow_key",
    "projectName": "My First Project",
    "customFields": {
      "industry_specific_field": "value"
    }
  }'
```

Done! 🎉

---

## 🎯 Real-World Examples

### Publishing House
- Creates projects from "Book Publication" template
- Custom fields: ISBN, author, pages, print run
- Task categories: editing, layout, printing, distribution
- AI learns: who's best at editing romantic novels vs technical manuals

### Software Agency
- Creates projects from "API Feature" template
- Custom fields: GitHub repo, Jira ticket, tech stack
- Task categories: backend, frontend, testing, devops
- AI learns: who's fastest at React components vs Node.js APIs

### Construction Company
- Creates projects from "Residential Building" template
- Custom fields: building permit, square meters, floors
- Task categories: foundation, framing, electrical, plumbing
- AI learns: which electrician is fastest, which plumber has best quality

### Marketing Agency
- Creates projects from "Campaign Launch" template
- Custom fields: client, budget, channels, target audience
- Task categories: strategy, design, copywriting, media_buying
- AI learns: which designer is best for luxury brands vs tech startups

---

## 🔑 Key Advantages

### 1. Zero Lock-In
Not tied to any industry. Switch industries? Just change templates.

### 2. Multi-Industry Support
Same tenant can run:
- Book publishing projects
- Software development projects
- Marketing campaigns
- Construction jobs
...all in the same system!

### 3. AI Learns Per Industry
The AI skill detection works independently for each `task_category`.
- User A: expert at "editing" (publishing)
- User A: novice at "backend" (software)
- System knows the difference!

### 4. Future-Proof
New industries emerge? Just add templates. No code changes needed.

---

## 📝 Summary

| Component | Generic? | Industry-Specific? |
|-----------|----------|-------------------|
| Database schema | ✅ Yes | ❌ No |
| Backend API | ✅ Yes | ❌ No |
| Frontend UI | ✅ Yes | ❌ No |
| AI assignment | ✅ Yes | ❌ No |
| Templates | ❌ No | ✅ Yes (data-driven) |
| Custom fields | ✅ Yes (JSONB) | ✅ Yes (per project) |

**Bottom Line**: Core is 100% generic. Industry logic lives in templates (which are just data).

---

## 🚀 Getting Started

1. **Install Core** (generic):
   ```bash
   psql -f migrations/028_pm_core_generic.sql
   ```

2. **Install Templates** (optional, per industry):
   ```bash
   # Publishing
   psql -f migrations/029_pm_editorial_templates.sql

   # Software (create your own)
   psql -f migrations/030_pm_software_templates.sql

   # Construction (create your own)
   psql -f migrations/031_pm_construction_templates.sql
   ```

3. **Use It**:
   ```bash
   # List available templates
   curl "http://localhost:5500/api/pm/templates?tenant_id=YOUR_TENANT"

   # Create project from any template
   curl -X POST http://localhost:5500/api/pm/projects/from-template \
     -d '{"templateKey": "book_publication", ...}'
   ```

That's it! 🎉
