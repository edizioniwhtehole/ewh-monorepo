# Documentation Cleanup Plan

## 🎯 Strategia Raccomandata

**Problema:** 150+ file .md nel root, la maggior parte work-in-progress o obsoleti

**Soluzione:** Struttura organizzata

```
ewh/
├── docs/                          ← Documentazione UFFICIALE
│   ├── architecture/
│   │   ├── README.md
│   │   ├── microservices.md
│   │   └── database-strategy.md
│   ├── deployment/
│   │   ├── README.md
│   │   ├── production-readiness.md  ← Il tuo audit
│   │   └── quick-start.md
│   ├── features/
│   │   ├── dam-system.md
│   │   ├── cms-system.md
│   │   └── page-builder.md
│   └── runbooks/
│       ├── troubleshooting.md
│       └── incident-response.md
│
├── .archive/                      ← File storici (gitignored)
│   └── brainstorming-2025-10/
│       ├── CMS_*.md
│       ├── DAM_*.md
│       └── ...
│
├── ARCHITECTURE.md                ← Solo file TOP-LEVEL essenziali
├── DEVELOPMENT.md
├── PRODUCTION_READINESS_AUDIT.md
└── QUICK_START_PRODUCTION.md
```

## 📋 Cosa Committare

### ✅ KEEP in Git (Essenziali)

**Root Level (max 10 file):**
- `README.md` - Overview progetto
- `ARCHITECTURE.md` - Architettura sistema
- `DEVELOPMENT.md` - Guida sviluppo
- `PRODUCTION_READINESS_AUDIT.md` - Audit produzione
- `QUICK_START_PRODUCTION.md` - Deployment rapido
- `CONTRIBUTING.md` - Guidelines contribuzione
- `CHANGELOG.md` - Changelog progetto

**docs/ Directory:**
- Documentazione feature consolidata (1 file per feature)
- Runbooks operativi
- API documentation

**scripts/ Directory:**
- Script già presenti ✅

### ❌ NON Committare (Archive o Delete)

**Work in Progress / Brainstorming:**
```
CMS_ANALISI_MANCANZE.md
CMS_API_DOCUMENTATION.md
CMS_COMPLETE_IMPLEMENTATION.md
CMS_FRONTEND_DEFINITIVO.md
CMS_IMPLEMENTAZIONE_COMPLETA_RIEPILOGO.md
... (tutti i file CMS_*.md)

DAM_ACTUAL_STATUS_COMPLETE.md
DAM_APPROVAL_WORKFLOWS.md
DAM_DEVELOPMENT_GUIDE.md
... (tutti i file DAM_*.md)

... e tutti i file *_COMPLETE.md, *_STATUS.md, *_SUMMARY.md
```

**Motivo:**
- Sono snapshots temporali
- Molti obsoleti
- Informazioni consolidate in file ufficiali

### ⚠️ CONSOLIDARE (Merge in file ufficiali)

Prendere informazioni utili da:
- `DAM_SYSTEM.md` → merge in `docs/features/dam-system.md`
- `CMS_PLUGIN_SYSTEM_ARCHITECTURE.md` → merge in `docs/features/cms-system.md`
- `IMAGE_EDITOR_SYSTEM.md` → merge in `docs/features/image-editor.md`

Poi eliminare gli originali.

---

## 🔧 Script di Pulizia

```bash
#!/bin/bash
# cleanup-docs.sh

# 1. Create archive directory
mkdir -p .archive/brainstorming-2025-10

# 2. Move work-in-progress files
mv *_COMPLETE.md .archive/brainstorming-2025-10/ 2>/dev/null
mv *_STATUS.md .archive/brainstorming-2025-10/ 2>/dev/null
mv *_SUMMARY.md .archive/brainstorming-2025-10/ 2>/dev/null
mv CMS_*.md .archive/brainstorming-2025-10/ 2>/dev/null
mv DAM_*.md .archive/brainstorming-2025-10/ 2>/dev/null
mv ENTERPRISE_*.md .archive/brainstorming-2025-10/ 2>/dev/null
mv PATENT_*.md .archive/brainstorming-2025-10/ 2>/dev/null

# Exceptions: keep important ones
git mv .archive/brainstorming-2025-10/DAM_SYSTEM.md docs/features/ 2>/dev/null

# 3. Add .archive to .gitignore
echo ".archive/" >> .gitignore

# 4. Organize docs
mkdir -p docs/{architecture,deployment,features,runbooks}

# Move key docs
git mv PRODUCTION_READINESS_AUDIT.md docs/deployment/
git mv QUICK_START_PRODUCTION.md docs/deployment/

echo "✅ Cleanup complete"
```

---

## 📊 Risultato Finale

**Prima:**
```
ewh/
├── 150+ file .md nel root (caos)
├── docs/ (pochi file)
└── scripts/
```

**Dopo:**
```
ewh/
├── 7 file .md essenziali nel root
├── docs/
│   ├── architecture/ (3-4 file)
│   ├── deployment/ (2-3 file)
│   ├── features/ (10-15 file consolidati)
│   └── runbooks/ (5 file)
├── scripts/ (invariato)
└── .archive/ (gitignored, backup locale)
```

**Vantaggi:**
- ✅ Repository pulito
- ✅ Facile navigazione
- ✅ Documentazione curata
- ✅ History git leggibile
- ✅ Non perdi nulla (archive locale)

---

## 🎯 Raccomandazione per Te

**Opzione A - Cleanup Adesso (Raccomandato):**
```bash
# 1. Crea archive locale (backup)
mkdir -p .archive/pre-cleanup-backup
cp *.md .archive/pre-cleanup-backup/

# 2. Commit SOLO file essenziali
git add PRODUCTION_READINESS_AUDIT.md \
        QUICK_START_PRODUCTION.md \
        scripts/create-final-repos.sh \
        scripts/generate-scalingo-manifests.sh \
        scripts/audit-env-vars.sh

git commit -m "docs: add production deployment tools and audit"

# 3. Pulisci dopo (manualmente o con script)
```

**Opzione B - Commit Tutto Ora, Cleanup Dopo:**
```bash
# 1. Commit tutto (veloce ma sporco)
git add *.md docs/ scripts/
git commit -m "docs: add all documentation (to cleanup)"

# 2. Cleanup in PR separata (dopo)
```

**Opzione C - Ignora Tutto (Non Raccomandato):**
```bash
# Aggiungi a .gitignore
echo "*.md" >> .gitignore
echo "!README.md" >> .gitignore
echo "!ARCHITECTURE.md" >> .gitignore
# ... etc
```

---

## ✅ La Mia Raccomandazione Finale

**Fai così:**

1. **Oggi:** Commit SOLO i file essenziali creati oggi (5 file)
2. **Domani/Settimana prossima:** Cleanup e riorganizzazione docs
3. **Vantaggio:** Procedi con creazione repos senza bloccarti su cleanup docs

```bash
# Quick commit essenziali
git add PRODUCTION_READINESS_AUDIT.md \
        QUICK_START_PRODUCTION.md \
        FINAL_DECISION.md \
        scripts/*.sh \
        .github/workflows/ci-template.yml

git commit -m "docs: add production readiness audit and deployment automation

Key additions:
- Production readiness audit (43.5/100 score, 6-week plan)
- Quick start production guide
- Automated scripts for 18 new git repos
- Scalingo deployment manifests generator
- CI/CD template

Enables: Deployment to staging/production with automated workflow"

git push origin main
```

**I 150 file .md nel root?**
- Lascia untracked per ora
- Cleanup in PR separata quando hai tempo
- Non blocca il lavoro sui repos

---

**Cosa ne pensi? Quale opzione preferisci?**
