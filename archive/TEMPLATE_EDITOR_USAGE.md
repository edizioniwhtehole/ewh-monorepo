# 📝 Template Editor - User Guide

**Status**: ✅ **FULLY FUNCTIONAL**
**URL**: http://localhost:5400/templates

---

## 🎯 Overview

Il **Template Editor** permette di creare e gestire template di workflow visualmente, senza dover scrivere SQL o JSON manualmente.

---

## 📋 Features

### 1. **Template List** (`/templates`)

Visualizza tutti i template disponibili con:

- **Nome e descrizione** del template
- **Categoria** (editorial, software, construction, ecc.)
- **Template key** (identificativo univoco)
- **Statistiche**:
  - Numero di task
  - Durata stimata (giorni)
  - Numero di utilizzi
- **Preview task**: mostra i primi 3 task con nome e ore stimate
- **Filtri per categoria**: clicca su una categoria per filtrare

**Actions**:
- ✏️ **Edit** - Modifica il template
- 📋 **Clone** - Duplica il template
- 🗑️ **Delete** - Elimina (solo se non usato)
- ➕ **New Template** - Crea nuovo

---

### 2. **Template Editor** (`/templates/new` o `/templates/:id/edit`)

Editor visuale completo con 3 sezioni:

#### A. **Basic Information**

| Campo | Descrizione | Obbligatorio |
|-------|-------------|--------------|
| Template Key | Identificativo univoco (es: `book_publication`) | ✅ Sì |
| Template Name | Nome human-readable (es: "Pubblicazione Libro") | ✅ Sì |
| Category | Settore (editorial, software, construction, ecc.) | No |
| Estimated Duration | Durata prevista in giorni | No |
| Description | Descrizione del workflow | No |

#### B. **Tasks Builder**

- ➕ **Add Task**: aggiungi un nuovo task
- Ogni task ha:
  - **Name**: nome del task (es: "Revisione Editoriale")
  - **Category**: categoria (es: "editing", "layout", "testing")
  - **Estimated Hours**: ore previste
- **Riordina**: usa le frecce ⬆️⬇️ per cambiare l'ordine
- 🗑️ **Delete**: rimuovi task

#### C. **Milestones Builder**

- ➕ **Add Milestone**: aggiungi milestone
- Ogni milestone ha:
  - **Name**: nome milestone (es: "Bozza Approvata")
  - **Due Days**: giorni dall'inizio progetto (es: 60)
- 🗑️ **Delete**: rimuovi milestone

#### D. **Actions**

- 💾 **Save Template**: salva modifiche
- ↩️ **Cancel**: annulla e torna alla lista

---

## 🚀 Quick Start

### Esempio 1: Crea Template "Website Development"

1. Vai su http://localhost:5400/templates
2. Click **"New Template"**
3. Compila:
   ```
   Template Key: website_development
   Template Name: Website Development
   Category: software
   Duration: 60 days
   Description: Full website development workflow
   ```
4. **Add Tasks**:
   ```
   Task 1: Design Mockups     | Category: design    | Hours: 40
   Task 2: Frontend Dev       | Category: frontend  | Hours: 80
   Task 3: Backend API        | Category: backend   | Hours: 100
   Task 4: Testing            | Category: qa        | Hours: 40
   Task 5: Deploy             | Category: devops    | Hours: 8
   ```
5. **Add Milestones**:
   ```
   Milestone 1: Design Complete   | Days: 15
   Milestone 2: MVP Ready         | Days: 40
   Milestone 3: Go Live           | Days: 60
   ```
6. Click **"Save Template"**

✅ Template creato! Ora appare nella lista.

---

### Esempio 2: Modifica Template Esistente

1. Nella lista templates, trova "Pubblicazione Libro"
2. Click **"Edit"**
3. Modifica:
   - Aggiungi task "Marketing Pre-Launch" (category: marketing, 16h)
   - Riordina task con frecce ⬆️⬇️
   - Cambia durata da 180 a 200 giorni
4. Click **"Save Template"**

✅ Modifiche salvate!

---

### Esempio 3: Clona Template

1. Trova template "Tourist Guide"
2. Click **"Clone"**
3. Insert:
   ```
   New Name: Travel Blog Post
   New Key: travel_blog_post
   ```
4. Click OK

✅ Template duplicato! Ora puoi modificarlo indipendentemente.

---

## 🎨 UI Features

### Template Card (nella lista)

```
┌──────────────────────────────────────────┐
│ 📖 Pubblicazione Libro       [editorial] │
│ book_publication                          │
│                                           │
│ Workflow completo per pubblicazione...   │
│                                           │
│ ────────────────────────────────────────  │
│ 📋 8 tasks   📅 180 days                 │
│                                           │
│ Tasks:                                    │
│ • Revisione Editoriale (80h)             │
│ • Impaginazione (40h)                    │
│ • Correzione Bozze (24h)                 │
│ +5 more tasks                             │
│                                           │
│ Used 0 times                              │
│ ────────────────────────────────────────  │
│ [Edit]  [Clone]  [🗑️]                    │
└──────────────────────────────────────────┘
```

### Task Editor (nella pagina di edit)

```
┌────────────────────────────────────────────────────────────┐
│ ⬆️⬇️ | Task Name        | Category | Hours | [🗑️]        │
├────────────────────────────────────────────────────────────┤
│ ⬆️⬇️ | Revisione Edit.. | editing  | 80    | [🗑️]        │
│ ⬆️⬇️ | Impaginazione    | layout   | 40    | [🗑️]        │
│ ⬆️⬇️ | Correzione Bozze | editing  | 24    | [🗑️]        │
└────────────────────────────────────────────────────────────┘
                     [+ Add Task]
```

---

## 🔒 Safety Features

### 1. **Delete Protection**
❌ Cannot delete template if used by projects
```
Error: Cannot delete template: it is used by existing projects
```

### 2. **Unique Template Key**
❌ Cannot create template with duplicate key
```
Error: Template key already exists
```

### 3. **Required Fields Validation**
❌ Cannot save without Template Key and Name
```
Alert: Template key and name are required
```

---

## 📊 Template Structure (Technical)

### JSON Structure

```json
{
  "id": "uuid",
  "templateKey": "book_publication",
  "templateName": "Pubblicazione Libro",
  "category": "editorial",
  "description": "Workflow completo...",
  "estimatedDurationDays": 180,
  "taskTemplates": [
    {
      "name": "Revisione Editoriale",
      "category": "editing",
      "estimated_hours": 80,
      "order": 1
    }
  ],
  "milestoneTemplates": [
    {
      "name": "Bozza Approvata",
      "due_days": 60
    }
  ],
  "usageCount": 0
}
```

---

## 🎯 Use Cases

### Publishing House (Casa Editrice)
Templates per:
- Libro classico
- Guida turistica
- Catalogo prodotti
- Gadget promozionali

### Software Agency
Templates per:
- API Development
- Mobile App
- Website
- Bug Fix
- CI/CD Setup

### Construction Company
Templates per:
- Residential Building
- Renovation
- Commercial Build-out
- Inspection & Permits

### Marketing Agency
Templates per:
- Campaign Launch
- Social Media Strategy
- Video Production
- Event Planning

---

## 🚀 Advanced Tips

### 1. **Naming Convention**
```
✅ Good:  book_publication, api_feature, building_permit
❌ Bad:   Book Publication, API-Feature, building.permit
```

### 2. **Task Categories**
Usa categorie consistenti per AI learning:
```
editorial:      editing, layout, printing, distribution
software:       frontend, backend, testing, devops
construction:   framing, electrical, plumbing, inspection
```

### 3. **Task Ordering**
L'ordine dei task è importante:
- Task sequenziali → ordine logico (1, 2, 3...)
- Task paralleli → stesso ordine va bene

### 4. **Milestone Planning**
```
✅ Good spacing:
  - Milestone 1: 30 days (early checkpoint)
  - Milestone 2: 90 days (mid-project)
  - Milestone 3: 180 days (completion)

❌ Bad spacing:
  - Milestone 1: 170 days
  - Milestone 2: 175 days
  - Milestone 3: 180 days
```

---

## 🔗 Integration

### Create Project from Template (API)

```bash
curl -X POST http://localhost:5500/api/pm/projects/from-template \
  -H "Content-Type: application/json" \
  -d '{
    "tenantId": "00000000-0000-0000-0000-000000000001",
    "templateKey": "book_publication",
    "projectName": "Il Mio Primo Libro",
    "startDate": "2025-11-01"
  }'
```

### Response
```json
{
  "success": true,
  "data": {
    "id": "project-uuid",
    "projectCode": "PRJ-2025-0001",
    "projectName": "Il Mio Primo Libro",
    "status": "planning",
    "tasks": [...8 tasks auto-created]
  }
}
```

---

## 🐛 Troubleshooting

### Template not showing in list
1. Check browser console (F12)
2. Verify API: `curl http://localhost:5500/api/pm/templates?tenant_id=...`
3. Check category filter

### Can't delete template
- **Reason**: Template is used by existing projects
- **Solution**: Archive/delete projects first, or keep template

### Tasks not appearing
- Check browser console for transformation errors
- Verify `taskTemplates` field exists in API response

---

## 📈 Metrics

Il sistema traccia automaticamente:
- **Usage Count**: quante volte il template è stato usato
- **Category Distribution**: quanti template per categoria
- **Task Complexity**: numero medio di task per template

---

## ✅ Checklist: Create Good Template

- [ ] Template key è lowercase_with_underscores
- [ ] Nome descrittivo e chiaro
- [ ] Categoria appropriata
- [ ] Durata realistica
- [ ] Almeno 3-5 task
- [ ] Task ordinati logicamente
- [ ] Ore stimate realistiche
- [ ] Almeno 2 milestone
- [ ] Milestone distribuite nel tempo

---

**Status**: 🎉 **READY TO USE**

Apri http://localhost:5400/templates e inizia a creare i tuoi workflow!
