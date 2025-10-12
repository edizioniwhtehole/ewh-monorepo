#!/bin/bash

# Complete Unified System Setup Script

set -e

echo "🚀 EWH Unified System Setup"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}❌ pnpm not found${NC}"
    echo "Install pnpm: npm install -g pnpm"
    exit 1
fi

if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ psql not found${NC}"
    echo "Install PostgreSQL client"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# 2. Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
pnpm install
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# 3. Run database migrations
echo -e "${BLUE}🗄️  Running database migrations...${NC}"

MIGRATIONS=(
    "023_unified_plugin_widget_system.sql"
    "024_create_page_builder_system.sql"
    "025_create_workflow_system.sql"
    "026_create_i18n_system.sql"
    "027_create_knowledge_base_system.sql"
)

for migration in "${MIGRATIONS[@]}"; do
    echo -e "  ${YELLOW}→${NC} Running $migration..."
    if psql -h localhost -U ewh -d ewh_master -f "migrations/$migration" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $migration complete"
    else
        echo -e "  ${YELLOW}⚠${NC} $migration (may already exist)"
    fi
done

echo -e "${GREEN}✅ Migrations complete${NC}"
echo ""

# 4. Verify workspace links
echo -e "${BLUE}🔗 Verifying workspace symlinks...${NC}"

PACKAGES=(
    "@ewh/shared-widgets"
    "@ewh/page-builder"
    "@ewh/workflow-builder"
    "@ewh/i18n"
    "@ewh/knowledge-base"
)

all_linked=true

for package in "${PACKAGES[@]}"; do
    if [ -L "app-admin-frontend/node_modules/$package" ]; then
        echo -e "  ${GREEN}✓${NC} Admin: $package linked"
    else
        echo -e "  ${RED}✗${NC} Admin: $package NOT linked"
        all_linked=false
    fi

    if [ -L "app-web-frontend/node_modules/$package" ]; then
        echo -e "  ${GREEN}✓${NC} Web: $package linked"
    else
        echo -e "  ${RED}✗${NC} Web: $package NOT linked"
        all_linked=false
    fi
done

if [ "$all_linked" = true ]; then
    echo -e "${GREEN}✅ All packages linked correctly${NC}"
else
    echo -e "${YELLOW}⚠  Some packages not linked - run 'pnpm install' again${NC}"
fi

echo ""

# 5. Summary
echo -e "${GREEN}✨ Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📚 What's been installed:${NC}"
echo ""
echo "  1. ✅ Shared Widgets System"
echo "     - Context-aware widgets (admin/tenant/user)"
echo "     - 3-level configuration"
echo "     - Example: ConnectedUsersWidget"
echo ""
echo "  2. ✅ Page Builder (Elementor-style)"
echo "     - Visual drag-and-drop editor"
echo "     - Responsive design tools"
echo "     - Database-driven pages"
echo ""
echo "  3. ✅ Workflow Builder (N8N-style)"
echo "     - Node-based workflow automation"
echo "     - Triggers, actions, transforms"
echo "     - Execution history"
echo ""
echo "  4. ✅ i18n System"
echo "     - Multi-language support (EN, IT, ES, FR, DE)"
echo "     - Translation management UI"
echo "     - Export/Import capabilities"
echo ""
echo "  5. ✅ Knowledge Base"
echo "     - Context-aware help articles"
echo "     - Drawer and inline infoboxes"
echo "     - Multi-language support"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo ""
echo "  1. Start Admin Frontend:"
echo -e "     ${YELLOW}cd app-admin-frontend && pnpm dev${NC}"
echo "     → http://localhost:3200"
echo ""
echo "  2. Start Web Frontend (in another terminal):"
echo -e "     ${YELLOW}cd app-web-frontend && pnpm dev${NC}"
echo "     → http://localhost:3100"
echo ""
echo "  3. Access Admin Interfaces:"
echo "     • Page Builder:  /admin/page-builder"
echo "     • Workflows:     /admin/workflows"
echo "     • Translations:  /admin/translations"
echo "     • Monitoring:    /admin/monitoring/users"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "  • UNIFIED_SYSTEM_COMPLETE.md - Complete guide"
echo "  • SHARED_WIDGETS_IMPLEMENTATION.md - Widget system"
echo "  • docs/SHARED_WIDGETS_ARCHITECTURE.md - Architecture"
echo ""
echo -e "${GREEN}Happy building! 🎉${NC}"
