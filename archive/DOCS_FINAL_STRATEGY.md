# Documentation Strategy - Final Decision

## 🎯 Strategia Finale: Ibrida

**Keep nel Monorepo:** File per agenti AI + essenziali
**Move to ewh-docs:** Documentazione features/roadmap/brainstorming

---

## 📁 Cosa Tenere nel Monorepo

### ✅ File per Agenti AI (KEEP nel root)

```
ewh/
├── MASTER_PROMPT.md              ← Istruzioni universali agenti
├── AGENTS.md                     ← Coordinamento agenti
├── GUARDRAILS.md                 ← Regole coordinamento
├── CONTEXT_INDEX.md              ← Indice rapido contesto
├── PROJECT_STATUS.md             ← Stato progetto
├── .ai/                          ← Config AI
│   └── context.json
└── .claude/                      ← Claude-specific
    └── commands/
```

**Motivo:** Agenti devono accedere senza submodule update

### ✅ Documentazione Essenziale (KEEP nel root)

```
ewh/
├── README.md                     ← Overview progetto
├── ARCHITECTURE.md               ← Architecture overview (breve)
├── DEVELOPMENT.md                ← Setup & workflow
├── CONTRIBUTING.md               ← Guidelines contribuzione
└── CHANGELOG.md                  ← Changelog progetto
```

### ✅ Scripts & Tools (KEEP)

```
ewh/
└── scripts/
    ├── create-final-repos.sh
    ├── generate-scalingo-manifests.sh
    ├── audit-env-vars.sh
    └── setup-docs-repo.sh
```

---

## 📦 Cosa Spostare in ewh-docs

### ❌ Features Documentation (MOVE)

Tutta la documentazione dettagliata features:

```
DAM_*.md                    → ewh-docs/features/dam/
CMS_*.md                    → ewh-docs/features/cms/
PAGE_BUILDER_*.md           → ewh-docs/features/page-builder/
IMAGE_EDITOR_*.md           → ewh-docs/features/image-editor/
PHOTOEDITING_*.md           → ewh-docs/features/image-editor/
DESKTOP_PUBLISHING_*.md     → ewh-docs/features/desktop-publishing/
EMAIL_*.md                  → ewh-docs/features/email/
TEXT_EDITING_*.md           → ewh-docs/features/text-editor/
```

### ❌ Deployment/Enterprise Docs (MOVE)

```
PRODUCTION_READINESS_AUDIT.md  → ewh-docs/deployment/
QUICK_START_PRODUCTION.md      → ewh-docs/deployment/
ENTERPRISE_*.md                → ewh-docs/deployment/
MONITORING_*.md                → ewh-docs/deployment/
```

### ❌ Architecture Details (MOVE)

```
DATABASE_*.md               → ewh-docs/architecture/
MULTI_*.md                  → ewh-docs/architecture/
SHARDED_*.md                → ewh-docs/architecture/
```

### ❌ Brainstorming/Status Files (MOVE)

```
*_COMPLETE.md               → ewh-docs/brainstorming/2025-10/
*_STATUS.md                 → ewh-docs/brainstorming/2025-10/
*_SUMMARY.md                → ewh-docs/brainstorming/2025-10/
*_ANALYSIS.md               → ewh-docs/brainstorming/2025-10/
```

### ❌ Patents (MOVE)

```
PATENT_*.md                 → ewh-docs/patents/
IDEE_DA_BREVETTARE.md       → ewh-docs/patents/
```

---

## 🤖 Supporto Agenti AI

### Per Agenti nel Monorepo

Gli agenti vedranno:
```
ewh/
├── MASTER_PROMPT.md        ← Leggi questo per istruzioni
├── AGENTS.md               ← Coordinamento
├── ARCHITECTURE.md         ← Overview + link a docs/
├── docs/                   ← Submodule (se serve dettagli)
```

### Link in ARCHITECTURE.md

```markdown
# Architecture Overview

[Breve overview qui - 200 righe max]

## Detailed Documentation

For in-depth architecture docs:
- [Full Architecture Guide](docs/architecture/overview.md)
- [Database Strategy](docs/architecture/database-strategy.md)
- [Multi-tenant Isolation](docs/architecture/multi-tenant.md)

Clone with docs: `git clone --recursive ...`
```

### Link in DEVELOPMENT.md

```markdown
# Development Guide

[Essential info qui - 300 righe max]

## Feature Guides

For feature-specific development:
- [DAM System](docs/features/dam/development.md)
- [CMS System](docs/features/cms/development.md)
- [Page Builder](docs/features/page-builder/development.md)

Clone with docs: `git submodule update --init`
```

---

## 📊 Risultato Finale

### Monorepo Root (Pulito, Agenti-Ready)

```
ewh/
├── .ai/                     ← AI config
├── .claude/                 ← Claude commands
├── MASTER_PROMPT.md         ← 50 KB
├── AGENTS.md                ← 20 KB
├── ARCHITECTURE.md          ← 100 KB (overview + links)
├── DEVELOPMENT.md           ← 80 KB (essentials + links)
├── README.md                ← 20 KB
├── CONTRIBUTING.md          ← 10 KB
├── CHANGELOG.md             ← 30 KB
├── docs/                    ← Submodule → ewh-docs
├── scripts/                 ← Helper scripts
├── svc-*/                   ← 52 submodules
└── app-*/                   ← 18 submodules (dopo creazione)

Total root .md files: ~310 KB (instead of 5+ MB)
```

### ewh-docs Repository (Documentazione Completa)

```
ewh-docs/
├── architecture/            ← 2 MB docs dettagliate
├── deployment/              ← 1 MB production guides
├── features/                ← 10 MB feature specs
│   ├── dam/
│   ├── cms/
│   ├── page-builder/
│   └── ...
├── brainstorming/           ← 5 MB work-in-progress
└── patents/                 ← 500 KB patents

Total: ~18 MB documentazione
```

---

## 🚀 Script Aggiornato

```bash
#!/bin/bash
# setup-docs-repo-ai-aware.sh

# Files to KEEP in monorepo (for AI agents)
KEEP_FILES=(
  "MASTER_PROMPT.md"
  "AGENTS.md"
  "GUARDRAILS.md"
  "CONTEXT_INDEX.md"
  "PROJECT_STATUS.md"
  "README.md"
  "ARCHITECTURE.md"
  "DEVELOPMENT.md"
  "CONTRIBUTING.md"
  "CHANGELOG.md"
)

# Create ewh-docs repo
# ... (same as before)

# Move files EXCEPT those in KEEP_FILES
for file in *.md; do
  if [[ ! " ${KEEP_FILES[@]} " =~ " ${file} " ]]; then
    # Move to ewh-docs based on pattern
    if [[ $file == DAM_* ]]; then
      mv "$file" "$DOCS_REPO_PATH/features/dam/"
    elif [[ $file == CMS_* ]]; then
      mv "$file" "$DOCS_REPO_PATH/features/cms/"
    # ... etc
    fi
  fi
done

echo "✅ Kept AI agent files in monorepo"
echo "✅ Moved detailed docs to ewh-docs"
```

---

## ✅ Vantaggi Soluzione Ibrida

1. **Agenti AI Funzionano Subito**
   - MASTER_PROMPT.md accessibile
   - Nessun submodule update richiesto
   - Context completo nel monorepo

2. **Monorepo Pulito**
   - Solo ~310 KB .md nel root
   - Invece di 5+ MB
   - Clone veloce

3. **Docs Complete Separate**
   - 18 MB in ewh-docs
   - Organizzate gerarchicamente
   - GitHub Pages ready

4. **Flessibilità**
   - Dev basic → clone monorepo solo
   - Dev full → clone con --recursive
   - Docs team → clone ewh-docs

---

## 🎯 Decisione Finale

**SI alla repo separata ewh-docs**
**MA con file essenziali + AI nel monorepo**

Esegui:
```bash
./scripts/setup-docs-repo.sh
```

Lo script:
1. ✅ Crea ewh-docs repo
2. ✅ Move 150+ docs files
3. ✅ KEEP file per agenti AI nel monorepo
4. ✅ Add ewh-docs come submodule
5. ✅ Update ARCHITECTURE.md con links

**Risultato:**
- Monorepo: ~310 KB docs (essenziali + AI)
- ewh-docs: ~18 MB docs (complete)
- Agenti: Funzionano senza problemi

---

**Procediamo?** 🚀
