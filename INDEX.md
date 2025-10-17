# 🗺️ EWH Platform - Documentation Index

> **Single Source of Truth**
> Documentazione organizzata e pulita - Da 111 file a 15 nella root!

---

## ⭐ START HERE

Nuovo al progetto? Leggi in questo ordine:

1. **[MASTER_PROMPT.md](MASTER_PROMPT.md)** - 🆕 **INIZIA QUI!** Single source of truth
2. **[README.md](README.md)** - Panoramica generale del progetto
3. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architettura generale
4. **[DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md)** - Strategia database
5. **[docs/sessions/SESSION_SUMMARY_2025_01_17.md](docs/sessions/SESSION_SUMMARY_2025_01_17.md)** - Ultimo lavoro svolto

---

## 📁 STRUTTURA DOCUMENTAZIONE

### 📄 Root (File Essenziali)
- **[README.md](README.md)** - Entry point del progetto
- **[MASTER_PROMPT.md](MASTER_PROMPT.md)** - Documento master (90 servizi, 77+ app)
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architettura generale
- **[DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md)** - Database strategy
- **[INDEX.md](INDEX.md)** - Questo file

### 📚 docs/ - Tutta la Documentazione

#### docs/setup/ - Guide di Setup
- [QUICK_START.md](docs/setup/QUICK_START.md) - Quick start
- [SETUP_DEVELOPMENT.md](docs/setup/SETUP_DEVELOPMENT.md) - Setup ambiente dev
- [SETUP_MAC_STUDIO.md](docs/setup/SETUP_MAC_STUDIO.md) - Setup Mac Studio
- [SETUP_REMOTE_DEVELOPMENT.md](docs/setup/SETUP_REMOTE_DEVELOPMENT.md) - Sviluppo remoto
- [SETUP_VSCODE_REMOTE.md](docs/setup/SETUP_VSCODE_REMOTE.md) - VSCode remote
- [GUIDE_AUTO_START.md](docs/setup/GUIDE_AUTO_START.md) - Auto-start servizi
- [GUIDE_MEMORY_OPTIMIZATION.md](docs/setup/GUIDE_MEMORY_OPTIMIZATION.md) - Ottimizzazione memoria
- [GUIDE_REMOTE_DEVELOPMENT.md](docs/setup/GUIDE_REMOTE_DEVELOPMENT.md) - Guida completa remote dev
- [GUIDE_REMOTE_QUICK.md](docs/setup/GUIDE_REMOTE_QUICK.md) - Quick guide remote dev

#### docs/deployment/ - Deploy e Produzione
- [MAC_STUDIO_ARCHITECTURE.md](docs/deployment/MAC_STUDIO_ARCHITECTURE.md) - Architettura Mac Studio
- [SCALINGO_*.md](docs/deployment/) - Guide Scalingo PaaS (6 file)

#### docs/security/ - Sicurezza
- [SECURITY_LAYERS_SERVICES.md](docs/security/SECURITY_LAYERS_SERVICES.md) - Layer di sicurezza
- [SQL_INJECTION_ANALYSIS.md](docs/security/SQL_INJECTION_ANALYSIS.md) - Analisi SQL injection
- [IP_WHITELISTING_STRATEGIES.md](docs/security/IP_WHITELISTING_STRATEGIES.md) - Strategie IP whitelisting

#### docs/supabase/ - Supabase
- [SUPABASE_ANALYSIS.md](docs/supabase/SUPABASE_ANALYSIS.md) - Analisi Supabase
- [SUPABASE_AUTH_ANALYSIS.md](docs/supabase/SUPABASE_AUTH_ANALYSIS.md) - Auth con Supabase
- [SUPABASE_COPY_PASTE_SETUP.md](docs/supabase/SUPABASE_COPY_PASTE_SETUP.md) - Setup rapido
- [SUPABASE_COSTS_MVP.md](docs/supabase/SUPABASE_COSTS_MVP.md) - Analisi costi
- [SUPABASE_HYBRID_DEPLOYMENT.md](docs/supabase/SUPABASE_HYBRID_DEPLOYMENT.md) - Deploy ibrido

#### docs/infrastructure/ - Infrastruttura
- [INFRASTRUCTURE_MAP.md](docs/infrastructure/INFRASTRUCTURE_MAP.md) - Mappa infrastruttura
- [INFRASTRUCTURE_REGISTRY.json](docs/infrastructure/INFRASTRUCTURE_REGISTRY.json) - Registro servizi
- [PLATFORM_SPECS_2025.md](docs/infrastructure/PLATFORM_SPECS_2025.md) - Specifiche complete piattaforma
- [PLATFORM_STANDARDS.md](docs/infrastructure/PLATFORM_STANDARDS.md) - Standard architetturali
- [CONFIG_OVERRIDE_SYSTEM.md](docs/infrastructure/CONFIG_OVERRIDE_SYSTEM.md) - Sistema config

#### docs/api/ - API Design
- [API_FIRST_ARCHITECTURE.md](docs/api/API_FIRST_ARCHITECTURE.md) - API-first design
- [ENABLE_API_SCHEMAS.md](docs/api/ENABLE_API_SCHEMAS.md) - OpenAPI schemas
- [APPROVED_REGISTRY.md](docs/api/APPROVED_REGISTRY.md) - Registro API approvate

#### docs/features/ - Feature Lists
- [FEATURE_LIST_DAM.md](docs/features/FEATURE_LIST_DAM.md) - Feature list completa (DAM+CRM+MRP+PIM+CMS)

#### docs/development/ - Sviluppo
- [DEVELOPMENT.md](docs/development/DEVELOPMENT.md) - Guida sviluppo
- [AGENT_WORKFLOW.md](docs/development/AGENT_WORKFLOW.md) - Workflow AI agents
- [SERVICE_FEATURE_MAPPING.md](docs/development/SERVICE_FEATURE_MAPPING.md) - Mappatura servizi condivisi
- [GIT_REPOS_CHECKLIST.md](docs/development/GIT_REPOS_CHECKLIST.md) - Checklist git repos

#### docs/sessions/ - Session Summaries
- [SESSION_SUMMARY_2025_01_17.md](docs/sessions/SESSION_SUMMARY_2025_01_17.md) - Sessione 17 Gen 2025

### 🔧 scripts/ - Script Organizzati

#### scripts/mac-studio/ - Mac Studio Operations
- master-startup-macstudio.sh - Startup completo
- auto-startup-macstudio.sh - Auto-start
- auto-healing-macstudio.sh - Auto-healing
- optimize-memory-macstudio.sh - Ottimizzazione memoria
- status-mac-studio.sh - Status check
- stop-mac-studio-dev.sh - Stop dev server
- migrate-db-to-macstudio.sh - Migrazione DB
- setup-postgres-macstudio.sh - Setup PostgreSQL
- start-mac-studio.sh - Launcher
- COMANDI_RAPIDI.sh - Menu comandi rapidi

#### scripts/deployment/ - Deployment
- deploy-to-mac-studio.sh - Deploy Mac Studio
- deploy-to-remote.sh - Deploy remoto
- deploy-railway-auto.sh - Railway auto-deploy
- deploy-by-priority.sh - Deploy per priorità
- setup-remote-docker.sh - Setup Docker remoto

#### scripts/sync/ - Sincronizzazione
- watch-and-sync-mac-studio.sh - Watch & sync Mac Studio
- watch-and-sync.sh - Watch & sync generico
- remote-shell.sh - Shell remota

#### scripts/services/ - Gestione Servizi
- start-additional-frontends.sh - Start frontend extra
- start-communications-suite.sh - Start suite comunicazioni
- start-dam-services.sh - Start DAM
- pm-restart.sh - Restart PM
- manage-frontends.sh - Gestione frontend
- cleanup-services.sh - Pulizia servizi

#### scripts/database/ - Database
- run-migration.cjs - Esegui migrazioni
- create-sample-projects.sh - Dati di esempio
- populate-pm-realistic-data.sh - Popola dati realistici

#### scripts/platform/ - Platform Management
- platform-setup-master.sh - Setup master
- audit-platform-readiness.sh - Audit readiness
- audit-all-services.sh - Audit servizi
- validate-app.sh - Valida app
- validate-service.sh - Valida servizio
- install-sso-helper.sh - Install SSO helper
- test-n8n-flow.sh - Test n8n
- clone_all.sh - Clone tutti i repo

#### scripts/monitoring/ - Monitoring
- monitor-services.sh - Monitor servizi
- monitor-resources.sh - Monitor risorse

#### scripts/generators/ - Generatori
- generate-agent-folders.sh - Genera cartelle agents/
- generate-roadmaps.sh - Genera ROADMAP.md
- generate-complete-services-config.sh - Config servizi
- generate-railway-config.sh - Config Railway
- create-missing-backends.sh - Crea backend mancanti
- audit-and-create-backends.sh - Audit e crea backend
- distribute-features.sh - Distribuisci features
- map-admin-panels.sh - Mappa admin panels

### ⚙️ config/ - Configurazioni
- ecosystem.macstudio.config.cjs - PM2 config Mac Studio
- dashboard-layout.json - Layout dashboard
- service-registry.json - Registro servizi

### 📦 archive/ - Storico
- archive/migrations/ - 23 migrazioni vecchie
- archive/services/ - 6 servizi obsoleti
- archive/backups/ - 6 backup directory
- archive/scripts/ - Script one-off già eseguiti
- archive/docs/ - Documentazione obsoleta

---

## 🎯 QUICK LINKS BY USE CASE

### "Voglio iniziare a sviluppare"
1. [MASTER_PROMPT.md](MASTER_PROMPT.md)
2. [docs/setup/QUICK_START.md](docs/setup/QUICK_START.md)
3. [docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md)

### "Voglio capire l'architettura"
1. [ARCHITECTURE.md](ARCHITECTURE.md)
2. [DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md)
3. [docs/infrastructure/PLATFORM_SPECS_2025.md](docs/infrastructure/PLATFORM_SPECS_2025.md)

### "Voglio deployare su Mac Studio"
1. [docs/setup/SETUP_MAC_STUDIO.md](docs/setup/SETUP_MAC_STUDIO.md)
2. [docs/deployment/MAC_STUDIO_ARCHITECTURE.md](docs/deployment/MAC_STUDIO_ARCHITECTURE.md)
3. [scripts/mac-studio/](scripts/mac-studio/)

### "Voglio sviluppare in remoto"
1. [docs/setup/GUIDE_REMOTE_QUICK.md](docs/setup/GUIDE_REMOTE_QUICK.md)
2. [docs/setup/SETUP_REMOTE_DEVELOPMENT.md](docs/setup/SETUP_REMOTE_DEVELOPMENT.md)
3. [docs/setup/SETUP_VSCODE_REMOTE.md](docs/setup/SETUP_VSCODE_REMOTE.md)

### "Voglio capire il database"
1. [DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md)
2. [docs/supabase/](docs/supabase/)

### "Voglio usare gli AI agents"
1. [MASTER_PROMPT.md](MASTER_PROMPT.md)
2. [docs/development/AGENT_WORKFLOW.md](docs/development/AGENT_WORKFLOW.md)
3. Ogni servizio ha `agents/CONTEXT.md`

---

## 📊 STATISTICHE PULIZIA

**Prima della pulizia:**
- Root: 111 file (.md, .sh, .js, .py, .json)
- Documentazione sparsa
- Nessuna organizzazione

**Dopo la pulizia:**
- Root: **15 file** (solo essenziali)
- docs/: ben organizzato per tema (9 categorie)
- scripts/: organizzato per funzione (8 categorie)
- config/: configurazioni centralizzate
- archive/: storico preservato

**Risultato: 86% riduzione nella root!** 🎉

---

## 🚀 COSA LEGGERE PER RUOLO

### 👨‍💻 Developer (Backend)
1. [docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md)
2. [ARCHITECTURE.md](ARCHITECTURE.md)
3. [DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md)
4. [docs/api/API_FIRST_ARCHITECTURE.md](docs/api/API_FIRST_ARCHITECTURE.md)

### 🎨 Developer (Frontend)
1. [docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md)
2. [ARCHITECTURE.md](ARCHITECTURE.md)
3. [docs/infrastructure/PLATFORM_SPECS_2025.md](docs/infrastructure/PLATFORM_SPECS_2025.md)

### 🏗️ DevOps / SRE
1. [docs/infrastructure/INFRASTRUCTURE_MAP.md](docs/infrastructure/INFRASTRUCTURE_MAP.md)
2. [docs/setup/SETUP_MAC_STUDIO.md](docs/setup/SETUP_MAC_STUDIO.md)
3. [docs/deployment/](docs/deployment/)
4. [scripts/mac-studio/](scripts/mac-studio/)

### 📐 Architect
1. [ARCHITECTURE.md](ARCHITECTURE.md)
2. [docs/infrastructure/PLATFORM_SPECS_2025.md](docs/infrastructure/PLATFORM_SPECS_2025.md)
3. [DATABASE_ARCHITECTURE.md](DATABASE_ARCHITECTURE.md)
4. [docs/infrastructure/PLATFORM_STANDARDS.md](docs/infrastructure/PLATFORM_STANDARDS.md)

### 🤖 AI Agent
1. [MASTER_PROMPT.md](MASTER_PROMPT.md)
2. [docs/development/SERVICE_FEATURE_MAPPING.md](docs/development/SERVICE_FEATURE_MAPPING.md)
3. Ogni servizio: `agents/CONTEXT.md`

---

## 🔄 MAINTENANCE

**Come mantenere organizzato:**

1. **Documentazione core** → Root (max 5 file .md)
2. **Guide setup** → docs/setup/
3. **Guide deployment** → docs/deployment/
4. **Features** → docs/features/
5. **Script utility** → scripts/ (in sottocartelle appropriate)
6. **Config** → config/
7. **Storico** → archive/

**Regola d'oro**: Se non è essenziale, non va nella root!

---

## 📞 SUPPORTO

- **Issues**: GitHub Issues
- **Docs mancante**: Cerca in `/archive/`
- **Nuovo documento**: Metti nella giusta sottocartella di docs/

---

**Ultima pulizia**: 17 Gennaio 2025
**Prossima revisione**: Trimestrale o su richiesta

---

> 💡 **Tip**: Usa Cmd+F / Ctrl+F per cercare rapidamente in questa pagina!
