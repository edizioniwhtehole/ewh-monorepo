#!/bin/bash

# ============================================================================
# EWH PLATFORM - SUPABASE SETUP WITH PSQL
# ============================================================================
# Fastest way: uses psql to execute SQL directly
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "============================================================================"
echo "🏗️  EWH PLATFORM - SUPABASE SETUP"
echo "============================================================================"
echo -e "${NC}"

SQL_FILE="./scripts/setup-supabase-complete.sql"

# Supabase connection strings (you need to fill in the passwords)
# Format: postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

echo -e "${YELLOW}Get your database passwords from:${NC}"
echo "Supabase Dashboard → Settings → Database → Connection string"
echo ""

echo -n "Enter DEV database password: "
read -s DEV_PASSWORD
echo ""

echo -n "Enter STAGING database password: "
read -s STAGING_PASSWORD
echo ""

echo -n "Enter PROD database password: "
read -s PROD_PASSWORD
echo ""

DEV_CONN="postgresql://postgres:${DEV_PASSWORD}@db.ezbwpkqcxdlixngvkpjl.supabase.co:5432/postgres"
STAGING_CONN="postgresql://postgres:${STAGING_PASSWORD}@db.pqcbzzxlpiozofqovrix.supabase.co:5432/postgres"
PROD_CONN="postgresql://postgres:${PROD_PASSWORD}@db.qubhjidkgpxlyruwkfkb.supabase.co:5432/postgres"

setup_env() {
    local env_name=$1
    local conn_string=$2

    echo -e "\n${BLUE}============================================================================"
    echo "🚀 Setting up ${env_name}"
    echo "============================================================================${NC}\n"

    echo -e "${YELLOW}📋 Applying SQL schema...${NC}"
    psql "$conn_string" -f "$SQL_FILE" -q

    echo -e "${GREEN}✅ Schema applied${NC}\n"

    echo -e "${YELLOW}👥 Creating tenants...${NC}"

    if [ "$env_name" = "DEV" ]; then
        psql "$conn_string" -c "SELECT core.create_tenant('acme', 'ACME Corporation', 'free', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);" -q
        psql "$conn_string" -c "SELECT core.create_tenant('test', 'Test Company', 'free', ARRAY['pm', 'crm', 'dam']);" -q

        echo -e "${YELLOW}📝 Inserting demo data...${NC}"
        psql "$conn_string" << 'EOF' -q
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
EOF

    elif [ "$env_name" = "STAGING" ]; then
        psql "$conn_string" -c "SELECT core.create_tenant('acme', 'ACME Corporation', 'standard', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);" -q
        psql "$conn_string" -c "SELECT core.create_tenant('demo', 'Demo Company', 'free', ARRAY['pm', 'crm', 'dam']);" -q

        psql "$conn_string" << 'EOF' -q
INSERT INTO tenant_acme.pm_projects (name, description, status, priority) VALUES
  ('Website Redesign', 'Complete redesign of company website', 'active', 'high'),
  ('Mobile App Development', 'New mobile app for customers', 'active', 'urgent');

INSERT INTO tenant_acme.crm_customers (company_name, contact_name, email, status) VALUES
  ('Tech Innovations Inc', 'John Smith', 'john@techinnovations.com', 'active');
EOF

    elif [ "$env_name" = "PROD" ]; then
        psql "$conn_string" -c "SELECT core.create_tenant('acme', 'ACME Corporation', 'enterprise', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);" -q
        echo -e "${YELLOW}⚠️  No demo data in PROD${NC}"
    fi

    echo -e "${GREEN}✅ Tenants created${NC}\n"

    echo -e "${YELLOW}🔍 Verifying...${NC}"
    psql "$conn_string" -c "SELECT slug, name, tier FROM core.tenants;"

    echo -e "${GREEN}✅ ${env_name} complete!${NC}"
}

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ psql not found. Install with: brew install postgresql${NC}"
    exit 1
fi

# Setup all environments
setup_env "DEV" "$DEV_CONN"
sleep 3

setup_env "STAGING" "$STAGING_CONN"
sleep 3

setup_env "PROD" "$PROD_CONN"

echo -e "\n${BLUE}============================================================================"
echo "🎉 ALL ENVIRONMENTS CONFIGURED!"
echo "============================================================================${NC}\n"

echo -e "${GREEN}✅ DEV:     https://ezbwpkqcxdlixngvkpjl.supabase.co${NC}"
echo -e "${GREEN}✅ STAGING: https://pqcbzzxlpiozofqovrix.supabase.co${NC}"
echo -e "${GREEN}✅ PROD:    https://qubhjidkgpxlyruwkfkb.supabase.co${NC}\n"
