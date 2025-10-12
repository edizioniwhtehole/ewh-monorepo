#!/bin/bash
# Setup ewh-docs repository
# Usage: ./scripts/setup-docs-repo.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE - No changes will be made"
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

MONOREPO_PATH="/Users/andromeda/dev/ewh"
DOCS_REPO_PATH="/tmp/ewh-docs-setup"
GITHUB_ORG="edizioniwhtehole"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EWH Docs Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 Would create: https://github.com/$GITHUB_ORG/ewh-docs"
  echo "🔍 Would organize 150+ docs files"
  echo "🔍 Would add as submodule to monorepo"
  exit 0
fi

# Step 1: Create GitHub repository
echo "1️⃣  Creating GitHub repository..."
if gh repo create "$GITHUB_ORG/ewh-docs" \
    --public \
    --description "EWH Platform - Complete Documentation (Architecture, Deployment, Features, Runbooks)" \
    --add-readme=false; then
  echo -e "${GREEN}✅ Repository created${NC}"
else
  echo -e "${YELLOW}⚠️  Repository may already exist${NC}"
fi

# Step 2: Setup local docs repo
echo "2️⃣  Setting up local documentation repository..."
rm -rf "$DOCS_REPO_PATH"
mkdir -p "$DOCS_REPO_PATH"
cd "$DOCS_REPO_PATH"

git init
git branch -M main
git remote add origin "https://github.com/$GITHUB_ORG/ewh-docs.git"

# Step 3: Create directory structure
echo "3️⃣  Creating directory structure..."
mkdir -p {architecture,deployment,features,brainstorming/2025-10,patents,runbooks}
mkdir -p features/{dam,cms,page-builder,image-editor,desktop-publishing,email,text-editor}

# Step 4: Move files from monorepo
echo "4️⃣  Moving documentation files..."
cd "$MONOREPO_PATH"

# Deployment docs
echo "   Moving deployment docs..."
[ -f "PRODUCTION_READINESS_AUDIT.md" ] && mv PRODUCTION_READINESS_AUDIT.md "$DOCS_REPO_PATH/deployment/production-readiness-audit.md"
[ -f "QUICK_START_PRODUCTION.md" ] && mv QUICK_START_PRODUCTION.md "$DOCS_REPO_PATH/deployment/quick-start-production.md"
[ -f "SERVICES_REVIEW.md" ] && mv SERVICES_REVIEW.md "$DOCS_REPO_PATH/deployment/services-review.md"
[ -f "FINAL_DECISION.md" ] && mv FINAL_DECISION.md "$DOCS_REPO_PATH/deployment/git-repos-decision.md"

# Architecture docs
echo "   Moving architecture docs..."
mv DATABASE_*.md "$DOCS_REPO_PATH/architecture/" 2>/dev/null || true
mv MULTI_*.md "$DOCS_REPO_PATH/architecture/" 2>/dev/null || true
mv SHARDED_*.md "$DOCS_REPO_PATH/architecture/" 2>/dev/null || true

# Features - DAM
echo "   Moving DAM documentation..."
mv DAM_*.md "$DOCS_REPO_PATH/features/dam/" 2>/dev/null || true
mv APP_DAM_*.md "$DOCS_REPO_PATH/features/dam/" 2>/dev/null || true

# Features - CMS
echo "   Moving CMS documentation..."
mv CMS_*.md "$DOCS_REPO_PATH/features/cms/" 2>/dev/null || true

# Features - Page Builder
echo "   Moving Page Builder documentation..."
mv PAGE_BUILDER_*.md "$DOCS_REPO_PATH/features/page-builder/" 2>/dev/null || true

# Features - Image Editor
echo "   Moving Image Editor documentation..."
mv IMAGE_EDITOR_*.md "$DOCS_REPO_PATH/features/image-editor/" 2>/dev/null || true
mv PHOTOEDITING_*.md "$DOCS_REPO_PATH/features/image-editor/" 2>/dev/null || true
mv PHOTOSHOP_*.md "$DOCS_REPO_PATH/features/image-editor/" 2>/dev/null || true

# Features - Desktop Publishing
echo "   Moving Desktop Publishing documentation..."
mv DESKTOP_PUBLISHING_*.md "$DOCS_REPO_PATH/features/desktop-publishing/" 2>/dev/null || true

# Features - Email
echo "   Moving Email documentation..."
mv EMAIL_*.md "$DOCS_REPO_PATH/features/email/" 2>/dev/null || true

# Features - Text Editor
echo "   Moving Text Editor documentation..."
mv TEXT_EDITING_*.md "$DOCS_REPO_PATH/features/text-editor/" 2>/dev/null || true
mv REALTIME_WRITING_*.md "$DOCS_REPO_PATH/features/text-editor/" 2>/dev/null || true

# Enterprise & Monitoring
echo "   Moving Enterprise documentation..."
mv ENTERPRISE_*.md "$DOCS_REPO_PATH/deployment/" 2>/dev/null || true
mv MONITORING_*.md "$DOCS_REPO_PATH/deployment/" 2>/dev/null || true

# Patents
echo "   Moving Patents documentation..."
mv PATENT_*.md "$DOCS_REPO_PATH/patents/" 2>/dev/null || true
mv IDEE_DA_BREVETTARE.md "$DOCS_REPO_PATH/patents/" 2>/dev/null || true

# Brainstorming (all *_COMPLETE, *_STATUS, *_SUMMARY files)
echo "   Moving brainstorming files..."
mv *_COMPLETE.md "$DOCS_REPO_PATH/brainstorming/2025-10/" 2>/dev/null || true
mv *_STATUS.md "$DOCS_REPO_PATH/brainstorming/2025-10/" 2>/dev/null || true
mv *_SUMMARY.md "$DOCS_REPO_PATH/brainstorming/2025-10/" 2>/dev/null || true
mv *_ANALYSIS.md "$DOCS_REPO_PATH/brainstorming/2025-10/" 2>/dev/null || true
mv *_ROADMAP.md "$DOCS_REPO_PATH/brainstorming/2025-10/" 2>/dev/null || true

# Step 5: Create README for ewh-docs
echo "5️⃣  Creating README..."
cd "$DOCS_REPO_PATH"

cat > README.md << 'EOF'
# EWH Platform - Documentation

> Complete documentation for the EWH SaaS Platform

## 📚 Documentation Structure

### [Architecture](architecture/)
System architecture, database strategies, microservices design

### [Deployment](deployment/)
Production readiness, deployment guides, CI/CD, operations

- [Production Readiness Audit](deployment/production-readiness-audit.md)
- [Quick Start: Production Deployment](deployment/quick-start-production.md)
- [Services Review](deployment/services-review.md)

### [Features](features/)
Feature-specific documentation:

- **[DAM - Digital Asset Management](features/dam/)** - Complete DAM system
- **[CMS - Content Management](features/cms/)** - Headless CMS with plugin system
- **[Page Builder](features/page-builder/)** - Visual page builder (Elementor-like)
- **[Image Editor](features/image-editor/)** - Photoshop clone
- **[Desktop Publishing](features/desktop-publishing/)** - InDesign clone
- **[Email System](features/email/)** - Enterprise email management
- **[Text Editors](features/text-editor/)** - 4 specialized text editors

### [Runbooks](runbooks/)
Operational procedures:
- Incident response
- Troubleshooting
- Deployment procedures

### [Patents](patents/)
Innovative features and patent strategies

### [Brainstorming](brainstorming/)
Work-in-progress notes and planning documents

---

## 🚀 Quick Start

1. **For Developers:**
   ```bash
   # Clone monorepo with docs
   git clone --recursive https://github.com/edizioniwhtehole/ewh.git
   cd ewh/docs  # ewh-docs is here as submodule
   ```

2. **For Documentation Only:**
   ```bash
   # Clone just the docs
   git clone https://github.com/edizioniwhtehole/ewh-docs.git
   ```

---

## 📖 Key Documents

- [System Architecture](architecture/)
- [Production Deployment](deployment/production-readiness-audit.md)
- [Feature Specifications](features/)

---

## 🤝 Contributing

To update documentation:

1. Clone this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Repository:** https://github.com/edizioniwhtehole/ewh-docs
**Main Project:** https://github.com/edizioniwhtehole/ewh
**Last Updated:** 2025-10-12
**Maintainer:** EWH Platform Team
EOF

# Step 6: Commit and push
echo "6️⃣  Committing and pushing to GitHub..."
git add .
git commit -m "docs: initial documentation repository

Organized documentation structure:

Architecture:
- System design and microservices
- Database strategies
- Multi-tenant isolation

Deployment:
- Production readiness audit (43.5/100 score)
- Quick start guide (6-week plan)
- Services review and git repos decision

Features:
- DAM (Digital Asset Management)
- CMS (Content Management System)
- Page Builder (Elementor-like)
- Image Editor (Photoshop clone)
- Desktop Publishing (InDesign clone)
- Email System
- Text Editors (4 specialized)

Runbooks:
- Operational procedures
- Troubleshooting guides

Patents:
- Innovative features documentation

Brainstorming:
- Work-in-progress notes (2025-10)

Total: 150+ documents migrated from monorepo
Enables: Cleaner monorepo, independent docs versioning

Generated: $(date '+%Y-%m-%d %H:%M:%S')"

git push -u origin main

echo -e "${GREEN}✅ ewh-docs repository created and pushed${NC}"

# Step 7: Add as submodule to monorepo
echo "7️⃣  Adding as submodule to monorepo..."
cd "$MONOREPO_PATH"

# Remove old docs directory if exists
[ -d "docs" ] && rm -rf docs

# Add as submodule
git submodule add https://github.com/$GITHUB_ORG/ewh-docs.git docs

# Commit
git add .gitmodules docs
git commit -m "docs: add ewh-docs as submodule

Moved all documentation to separate repository:
- 150+ documents organized hierarchically
- Cleaner monorepo (only code + submodule refs)
- Independent docs versioning

Repository: https://github.com/$GITHUB_ORG/ewh-docs
Access: git submodule update --init docs

Benefits:
- Faster monorepo clone
- Separate docs workflow
- GitHub Pages ready"

echo -e "${GREEN}✅ Submodule added to monorepo${NC}"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ ewh-docs repository created${NC}"
echo "   URL: https://github.com/$GITHUB_ORG/ewh-docs"
echo ""
echo -e "${GREEN}✅ Documentation organized${NC}"
echo "   Files: 150+ documents"
echo "   Structure: architecture/, deployment/, features/, etc."
echo ""
echo -e "${GREEN}✅ Added as submodule to monorepo${NC}"
echo "   Path: ewh/docs/"
echo ""
echo "📋 Next steps:"
echo "  1. cd $MONOREPO_PATH"
echo "  2. git push origin main"
echo "  3. ./scripts/create-final-repos.sh (create 18 service repos)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
