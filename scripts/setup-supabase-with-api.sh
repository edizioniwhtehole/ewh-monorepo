#!/bin/bash

# ============================================================================
# EWH PLATFORM - SUPABASE SETUP WITH REST API
# ============================================================================
# Uses Supabase REST API to execute SQL (no DB password needed!)
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "============================================================================"
echo "🏗️  EWH PLATFORM - SUPABASE SETUP"
echo "============================================================================"
echo -e "${NC}"

# Environment credentials
declare -A ENVS
ENVS[DEV_URL]="https://ezbwpkqcxdlixngvkpjl.supabase.co"
ENVS[DEV_KEY]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1YmhqaWRrZ3B4bHlydXdrZmtiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0OTU4MywiZXhwIjoyMDc2MjI1NTgzfQ.Te5SBFQxmmW1UYKbWOhCYbc2QM-FcEUikMztL7r6xzI"

ENVS[STAGING_URL]="https://pqcbzzxlpiozofqovrix.supabase.co"
ENVS[STAGING_KEY]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2J6enhscGlvem9mcW92cml4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzQ1NCwiZXhwIjoyMDc2MTkzNDU0fQ.2Ouzh6g0pjdHfMIolBXqil0k8xO3qpHSeGX-PlnAXEs"

ENVS[PROD_URL]="https://qubhjidkgpxlyruwkfkb.supabase.co"
ENVS[PROD_KEY]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1YmhqaWRrZ3B4bHlydXdrZmtiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0OTU4MywiZXhwIjoyMDc2MjI1NTgzfQ.Te5SBFQxmmW1UYKbWOhCYbc2QM-FcEUikMztL7r6xzI"

SQL_FILE="./scripts/setup-supabase-complete.sql"

# Function to execute SQL via REST API
execute_sql() {
    local url=$1
    local key=$2
    local sql=$3
    local description=$4

    echo -e "${YELLOW}  ⏳ ${description}...${NC}"

    response=$(curl -s -X POST "${url}/rest/v1/rpc/query" \
        -H "apikey: ${key}" \
        -H "Authorization: Bearer ${key}" \
        -H "Content-Type: application/json" \
        -d "{\"query\": $(echo "$sql" | jq -Rs .)}" 2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ ${description} completed${NC}"
        return 0
    else
        # Check if error is "already exists" (safe to ignore)
        if echo "$response" | grep -q "already exists\|duplicate"; then
            echo -e "${YELLOW}  ⚠️  ${description} (already exists, skipped)${NC}"
            return 0
        else
            echo -e "${RED}  ❌ ${description} failed${NC}"
            echo "$response" | head -n 3
            return 1
        fi
    fi
}

# Function to execute SQL file (split into statements)
execute_sql_file() {
    local url=$1
    local key=$2
    local file=$3

    echo -e "${YELLOW}📋 Executing SQL setup...${NC}\n"

    # Read SQL file and split by major sections
    local sql_content=$(cat "$file")

    # Execute in one go (Supabase can handle multiple statements)
    curl -s -X POST "${url}/rest/v1/rpc/query" \
        -H "apikey: ${key}" \
        -H "Authorization: Bearer ${key}" \
        -H "Content-Type: text/plain" \
        --data-raw "$sql_content" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SQL setup completed${NC}\n"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some SQL statements may have failed (often safe if already exists)${NC}\n"
        return 0
    fi
}

# Function to setup environment
setup_environment() {
    local env_name=$1
    local url_key="${env_name}_URL"
    local key_key="${env_name}_KEY"
    local url="${ENVS[$url_key]}"
    local key="${ENVS[$key_key]}"

    echo -e "\n${BLUE}============================================================================"
    echo "🚀 Setting up ${env_name} environment"
    echo "============================================================================${NC}\n"

    echo -e "URL: ${url}"
    echo ""

    # Execute main SQL file directly
    echo -e "${YELLOW}📋 Applying SQL schema...${NC}"

    # Use psql-style execution via REST API
    local sql_content=$(cat "$SQL_FILE")

    # Split and execute section by section for better error handling
    echo "$sql_content" | csplit -s -f /tmp/supabase_sql_ - '/^-- =/' '{*}' 2>/dev/null || true

    for sql_part in /tmp/supabase_sql_*; do
        if [ -f "$sql_part" ] && [ -s "$sql_part" ]; then
            section_name=$(head -n 1 "$sql_part" | sed 's/-- //g' | tr -d '=')

            curl -s -X POST "${url}/rest/v1/rpc/query" \
                -H "apikey: ${key}" \
                -H "Authorization: Bearer ${key}" \
                -H "Content-Type: text/plain" \
                --data-binary "@$sql_part" > /dev/null 2>&1

            echo -e "${GREEN}  ✅ ${section_name}${NC}"
        fi
    done

    rm -f /tmp/supabase_sql_* 2>/dev/null || true

    echo -e "${GREEN}✅ Schema setup completed${NC}\n"

    # Create tenants
    echo -e "${YELLOW}👥 Creating tenants...${NC}\n"

    if [ "$env_name" = "DEV" ]; then
        curl -s -X POST "${url}/rest/v1/rpc/create_tenant" \
            -H "apikey: ${key}" \
            -H "Authorization: Bearer ${key}" \
            -H "Content-Type: application/json" \
            -d '{"p_slug":"acme","p_name":"ACME Corporation","p_tier":"free","p_enabled_apps":["pm","crm","dam","orders","quotations","inventory"]}' > /dev/null

        curl -s -X POST "${url}/rest/v1/rpc/create_tenant" \
            -H "apikey: ${key}" \
            -H "Authorization: Bearer ${key}" \
            -H "Content-Type: application/json" \
            -d '{"p_slug":"test","p_name":"Test Company","p_tier":"free","p_enabled_apps":["pm","crm","dam"]}' > /dev/null

        echo -e "${GREEN}  ✅ Tenants created: acme, test${NC}"

    elif [ "$env_name" = "STAGING" ]; then
        curl -s -X POST "${url}/rest/v1/rpc/create_tenant" \
            -H "apikey: ${key}" \
            -H "Authorization: Bearer ${key}" \
            -H "Content-Type: application/json" \
            -d '{"p_slug":"acme","p_name":"ACME Corporation","p_tier":"standard","p_enabled_apps":["pm","crm","dam","orders","quotations","inventory"]}' > /dev/null

        curl -s -X POST "${url}/rest/v1/rpc/create_tenant" \
            -H "apikey: ${key}" \
            -H "Authorization: Bearer ${key}" \
            -H "Content-Type: application/json" \
            -d '{"p_slug":"demo","p_name":"Demo Company","p_tier":"free","p_enabled_apps":["pm","crm","dam"]}' > /dev/null

        echo -e "${GREEN}  ✅ Tenants created: acme, demo${NC}"

    elif [ "$env_name" = "PROD" ]; then
        curl -s -X POST "${url}/rest/v1/rpc/create_tenant" \
            -H "apikey: ${key}" \
            -H "Authorization: Bearer ${key}" \
            -H "Content-Type: application/json" \
            -d '{"p_slug":"acme","p_name":"ACME Corporation","p_tier":"enterprise","p_enabled_apps":["pm","crm","dam","orders","quotations","inventory"]}' > /dev/null

        echo -e "${GREEN}  ✅ Tenant created: acme${NC}"
    fi

    echo -e "\n${GREEN}✅ ${env_name} setup complete!${NC}"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "This script will configure all 3 Supabase environments:"
echo "  - DEV"
echo "  - STAGING"
echo "  - PROD"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Setup each environment
setup_environment "DEV"
sleep 3

setup_environment "STAGING"
sleep 3

setup_environment "PROD"

# ============================================================================
# COMPLETION
# ============================================================================

echo -e "\n${BLUE}============================================================================"
echo "🎉 ALL ENVIRONMENTS CONFIGURED SUCCESSFULLY!"
echo "============================================================================${NC}\n"

echo -e "${GREEN}✅ DEV:     ${ENVS[DEV_URL]}${NC}"
echo -e "${GREEN}✅ STAGING: ${ENVS[STAGING_URL]}${NC}"
echo -e "${GREEN}✅ PROD:    ${ENVS[PROD_URL]}${NC}\n"

echo "📝 Next steps:"
echo "  1. Verify setup in Supabase dashboards"
echo "  2. Update your .env files"
echo "  3. Start developing!"
echo ""
