#!/bin/bash

# ============================================================================
# EWH PLATFORM - SUPABASE SETUP WITH CLI
# ============================================================================
# This script uses Supabase CLI to configure all 3 environments
# ============================================================================

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "============================================================================"
echo "🏗️  EWH PLATFORM - SUPABASE SETUP"
echo "============================================================================"
echo -e "${NC}"

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found${NC}"
    echo "Install with: brew install supabase/tap/supabase"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}\n"

# Environment credentials
DEV_URL="https://ezbwpkqcxdlixngvkpjl.supabase.co"
DEV_PROJECT_REF="ezbwpkqcxdlixngvkpjl"
DEV_DB_PASSWORD="" # Will be prompted

STAGING_URL="https://pqcbzzxlpiozofqovrix.supabase.co"
STAGING_PROJECT_REF="pqcbzzxlpiozofqovrix"
STAGING_DB_PASSWORD=""

PROD_URL="https://qubhjidkgpxlyruwkfkb.supabase.co"
PROD_PROJECT_REF="qubhjidkgpxlyruwkfkb"
PROD_DB_PASSWORD=""

# SQL setup file
SQL_FILE="./scripts/setup-supabase-complete.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ SQL file not found: $SQL_FILE${NC}"
    exit 1
fi

# Function to setup one environment
setup_environment() {
    local ENV_NAME=$1
    local PROJECT_REF=$2
    local DB_PASSWORD=$3

    echo -e "\n${BLUE}============================================================================"
    echo "🚀 Setting up ${ENV_NAME} environment"
    echo "============================================================================${NC}\n"

    # Link project
    echo -e "${YELLOW}📡 Linking to Supabase project...${NC}"
    supabase link --project-ref "$PROJECT_REF" --password "$DB_PASSWORD" 2>/dev/null || echo "Already linked"

    # Apply SQL migrations
    echo -e "${YELLOW}📋 Applying SQL setup...${NC}"
    supabase db execute --file "$SQL_FILE" --linked

    echo -e "${GREEN}✅ SQL setup completed for ${ENV_NAME}${NC}"

    # Create demo tenants
    echo -e "${YELLOW}👥 Creating demo tenants...${NC}"

    if [ "$ENV_NAME" = "DEV" ]; then
        # Create ACME and TEST tenants
        supabase db execute --sql "SELECT core.create_tenant('acme', 'ACME Corporation', 'free', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);" --linked
        supabase db execute --sql "SELECT core.create_tenant('test', 'Test Company', 'free', ARRAY['pm', 'crm', 'dam']);" --linked

        # Insert demo data for ACME
        echo -e "${YELLOW}📝 Inserting demo data...${NC}"
        supabase db execute --sql "
          INSERT INTO tenant_acme.pm_projects (name, description, status, priority) VALUES
            ('Website Redesign', 'Complete redesign of company website', 'active', 'high'),
            ('Mobile App Development', 'New mobile app for customers', 'active', 'urgent'),
            ('Infrastructure Upgrade', 'Server infrastructure modernization', 'on_hold', 'medium');

          INSERT INTO tenant_acme.crm_customers (company_name, contact_name, email, status) VALUES
            ('Tech Innovations Inc', 'John Smith', 'john@techinnovations.com', 'active'),
            ('Design Masters Studio', 'Jane Doe', 'jane@designmasters.com', 'active'),
            ('Global Marketing Ltd', 'Bob Wilson', 'bob@globalmarketing.com', 'prospect');

          INSERT INTO tenant_acme.inventory_products (sku, name, unit_price, quantity_on_hand) VALUES
            ('WID-PREM-001', 'Premium Widget', 99.99, 50),
            ('WID-STD-002', 'Standard Widget', 49.99, 120),
            ('WID-BAS-003', 'Basic Widget', 19.99, 200);
        " --linked

    elif [ "$ENV_NAME" = "STAGING" ]; then
        # Create ACME and DEMO tenants
        supabase db execute --sql "SELECT core.create_tenant('acme', 'ACME Corporation', 'standard', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);" --linked
        supabase db execute --sql "SELECT core.create_tenant('demo', 'Demo Company', 'free', ARRAY['pm', 'crm', 'dam']);" --linked

        # Insert demo data
        supabase db execute --sql "
          INSERT INTO tenant_acme.pm_projects (name, description, status, priority) VALUES
            ('Website Redesign', 'Complete redesign of company website', 'active', 'high'),
            ('Mobile App Development', 'New mobile app for customers', 'active', 'urgent');

          INSERT INTO tenant_acme.crm_customers (company_name, contact_name, email, status) VALUES
            ('Tech Innovations Inc', 'John Smith', 'john@techinnovations.com', 'active'),
            ('Design Masters Studio', 'Jane Doe', 'jane@designmasters.com', 'active');
        " --linked

    elif [ "$ENV_NAME" = "PROD" ]; then
        # Create only ACME tenant (no demo data)
        supabase db execute --sql "SELECT core.create_tenant('acme', 'ACME Corporation', 'enterprise', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);" --linked
        echo -e "${YELLOW}⚠️  No demo data inserted in PROD (production environment)${NC}"
    fi

    echo -e "${GREEN}✅ Tenants created for ${ENV_NAME}${NC}"

    # Verify setup
    echo -e "${YELLOW}🔍 Verifying setup...${NC}"
    supabase db execute --sql "SELECT slug, name, tier FROM core.tenants;" --linked

    echo -e "${GREEN}✅ ${ENV_NAME} environment setup complete!${NC}"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "This script will configure all 3 Supabase environments:"
echo "  - DEV (ezbwpkqcxdlixngvkpjl)"
echo "  - STAGING (pqcbzzxlpiozofqovrix)"
echo "  - PROD (qubhjidkgpxlyruwkfkb)"
echo ""
echo "You will need the database passwords for each environment."
echo "Find them in Supabase Dashboard → Settings → Database → Connection string"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Get passwords
echo -e "\n${YELLOW}📝 Please enter database passwords:${NC}\n"

echo -n "DEV database password: "
read -s DEV_DB_PASSWORD
echo ""

echo -n "STAGING database password: "
read -s STAGING_DB_PASSWORD
echo ""

echo -n "PROD database password: "
read -s PROD_DB_PASSWORD
echo ""

# Setup each environment
setup_environment "DEV" "$DEV_PROJECT_REF" "$DEV_DB_PASSWORD"

echo -e "\n${YELLOW}⏳ Waiting 5 seconds before next environment...${NC}"
sleep 5

setup_environment "STAGING" "$STAGING_PROJECT_REF" "$STAGING_DB_PASSWORD"

echo -e "\n${YELLOW}⏳ Waiting 5 seconds before next environment...${NC}"
sleep 5

setup_environment "PROD" "$PROD_PROJECT_REF" "$PROD_DB_PASSWORD"

# ============================================================================
# COMPLETION
# ============================================================================

echo -e "\n${BLUE}============================================================================"
echo "🎉 ALL ENVIRONMENTS CONFIGURED SUCCESSFULLY!"
echo "============================================================================${NC}\n"

echo -e "${GREEN}✅ DEV:     $DEV_URL${NC}"
echo -e "${GREEN}✅ STAGING: $STAGING_URL${NC}"
echo -e "${GREEN}✅ PROD:    $PROD_URL${NC}\n"

echo "📝 Next steps:"
echo "  1. Update your .env files (see .env.example)"
echo "  2. Test connection: supabase db execute --sql 'SELECT * FROM core.tenants;' --linked"
echo "  3. Start developing services!"
echo ""

echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "  supabase db execute --sql 'YOUR_SQL' --linked"
echo "  supabase db pull"
echo "  supabase db push"
echo "  supabase db reset"
echo ""
