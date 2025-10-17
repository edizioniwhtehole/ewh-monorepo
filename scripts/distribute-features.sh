#!/bin/bash
# Script per distribuire FEATURES.md nei servizi
# Usage: ./scripts/distribute-features.sh [source-dir]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FEATURES_SOURCE="${1:-$PROJECT_ROOT/feature-lists}"

echo "🚀 EWH Platform - Feature Distribution Script"
echo "=============================================="
echo ""
echo "📂 Source directory: $FEATURES_SOURCE"
echo "🎯 Target: Services and Apps"
echo ""

if [ ! -d "$FEATURES_SOURCE" ]; then
    echo "❌ Error: Source directory not found: $FEATURES_SOURCE"
    echo ""
    echo "Usage: $0 [source-dir]"
    echo ""
    echo "Expected structure:"
    echo "  feature-lists/"
    echo "    ├── DAM_FEATURES.md"
    echo "    ├── CRM_FEATURES.md"
    echo "    ├── PM_FEATURES.md"
    echo "    └── ..."
    exit 1
fi

# Mapping: FEATURE_FILE -> SERVICE_DIR
declare -A SERVICE_MAP=(
    # Backend Services
    ["DAM_FEATURES.md"]="svc-dam"
    ["CRM_FEATURES.md"]="svc-crm"
    ["MRP_FEATURES.md"]="svc-mrp"
    ["PIM_FEATURES.md"]="svc-pim"
    ["CMS_FEATURES.md"]="svc-cms"
    ["PM_FEATURES.md"]="svc-pm"
    ["AUTH_FEATURES.md"]="svc-auth"
    ["BILLING_FEATURES.md"]="svc-billing"
    ["STORAGE_FEATURES.md"]="svc-storage"
    ["SEARCH_FEATURES.md"]="svc-search"
    ["AI_FEATURES.md"]="svc-ai-engine"
    ["ANALYTICS_FEATURES.md"]="svc-analytics"
    ["COMM_FEATURES.md"]="svc-comm"
    ["CONTACTS_FEATURES.md"]="svc-contacts"
    ["TRANSLATION_FEATURES.md"]="svc-translation"
    ["FORMS_FEATURES.md"]="svc-forms"
    ["AUDIT_FEATURES.md"]="svc-audit"
    ["WORKFLOW_FEATURES.md"]="svc-workflow-engine"
    ["APPROVALS_FEATURES.md"]="svc-approvals"
    ["WEBHOOKS_FEATURES.md"]="svc-webhooks"

    # Add more services as needed...
)

# Mapping: FEATURE_FILE -> FRONTEND_DIR
declare -A FRONTEND_MAP=(
    ["DAM_FEATURES_UI.md"]="app-dam"
    ["CRM_FEATURES_UI.md"]="app-crm-frontend"
    ["PM_FEATURES_UI.md"]="app-pm-frontend"
    ["CMS_FEATURES_UI.md"]="app-cms-frontend"
    ["ADMIN_FEATURES_UI.md"]="app-admin-frontend"

    # Add more frontends as needed...
)

distributed=0
skipped=0
errors=0

echo "📦 DISTRIBUTING BACKEND FEATURES..."
echo ""

for feature_file in "${!SERVICE_MAP[@]}"; do
    service_dir="${SERVICE_MAP[$feature_file]}"
    source_file="$FEATURES_SOURCE/$feature_file"
    target_file="$PROJECT_ROOT/$service_dir/FEATURES.md"

    if [ ! -f "$source_file" ]; then
        echo "  ⏭️  Skipped: $feature_file (file not found)"
        ((skipped++))
        continue
    fi

    if [ ! -d "$PROJECT_ROOT/$service_dir" ]; then
        echo "  ⚠️  Warning: Service directory not found: $service_dir"
        ((errors++))
        continue
    fi

    # Copy file
    cp "$source_file" "$target_file"
    echo "  ✅ $service_dir/FEATURES.md"
    ((distributed++))
done

echo ""
echo "📦 DISTRIBUTING FRONTEND FEATURES..."
echo ""

for feature_file in "${!FRONTEND_MAP[@]}"; do
    frontend_dir="${FRONTEND_MAP[$feature_file]}"
    source_file="$FEATURES_SOURCE/$feature_file"
    target_file="$PROJECT_ROOT/$frontend_dir/FEATURES.md"

    if [ ! -f "$source_file" ]; then
        echo "  ⏭️  Skipped: $feature_file (file not found)"
        ((skipped++))
        continue
    fi

    if [ ! -d "$PROJECT_ROOT/$frontend_dir" ]; then
        echo "  ⚠️  Warning: Frontend directory not found: $frontend_dir"
        ((errors++))
        continue
    fi

    # Copy file
    cp "$source_file" "$target_file"
    echo "  ✅ $frontend_dir/FEATURES.md"
    ((distributed++))
done

echo ""
echo "=============================================="
echo "📊 SUMMARY"
echo "=============================================="
echo "  ✅ Distributed: $distributed files"
echo "  ⏭️  Skipped:     $skipped files"
echo "  ⚠️  Errors:      $errors files"
echo ""

if [ $errors -gt 0 ]; then
    echo "⚠️  Some errors occurred. Check logs above."
    exit 1
fi

echo "✅ Distribution completed successfully!"
echo ""
echo "🎯 NEXT STEPS:"
echo "  1. Review FEATURES.md in each service"
echo "  2. Ensure agents read FEATURES.md before developing"
echo "  3. Follow AGENT_WORKFLOW.md for development"
echo ""
