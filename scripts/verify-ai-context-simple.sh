#!/bin/bash

# Script di verifica sistema AI Context (versione semplice senza jq)
# Controlla che tutti i file referenziati in .ai/context.json siano presenti

set -e

cd "$(dirname "$0")/.."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 EWH AI Context System - Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# File che devono essere presenti (da .ai/context.json)
PRIMARY_FILES=(
  "CONTEXT_INDEX.md"
  "PROJECT_STATUS.md"
  "MASTER_PROMPT.md"
  "GUARDRAILS.md"
  "ARCHITECTURE.md"
)

FEATURE_FILES=(
  "DAM_APPROVAL_CHANGELOG.md"
  "HR_SYSTEM_COMPLETE.md"
  "ACTIVITY_TRACKING_INTEGRATION.md"
  "EMAIL_CLIENT_SYSTEM.md"
  "EMAIL_QUICK_REPLY_UI.md"
  "IMAGE_EDITOR_SYSTEM.md"
  "DESKTOP_PUBLISHING_SYSTEM.md"
  "I18N_SYSTEM.md"
  "AI_PROVIDER_SYSTEM.md"
  "INFRASTRUCTURE_MAP.md"
  "TENANT_MIGRATION.md"
  "ENTERPRISE_READINESS.md"
  "CONTEXTUAL_HELP_SYSTEM.md"
)

echo "📋 Checking primary documentation files..."
echo ""

primary_missing=0
for file in "${PRIMARY_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (MISSING)"
    primary_missing=$((primary_missing + 1))
  fi
done

echo ""
echo "📚 Checking feature-specific documentation files..."
echo ""

feature_missing=0
for file in "${FEATURE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (MISSING)"
    feature_missing=$((feature_missing + 1))
  fi
done

# Check submodule files (optional)
echo ""
echo "📦 Checking submodule documentation files (optional)..."
echo ""

SUBMODULE_FILES=(
  "app-web-frontend/DAM_PERMISSIONS_SPECS.md"
  "app-web-frontend/DAM_ENTERPRISE_SPECS.md"
  "app-web-frontend/APP_CONTEXT.md"
  "app-web-frontend/CODEBASE_REFERENCE.md"
  "app-web-frontend/ADMIN_PANEL_QUICKSTART.md"
)

submodule_present=0
for file in "${SUBMODULE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
    submodule_present=$((submodule_present + 1))
  else
    echo "  ⚠️  $file (submodule not initialized)"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

total_missing=$((primary_missing + feature_missing))

if [ $total_missing -eq 0 ]; then
  echo "✅ AI Context System: ALL REQUIRED FILES PRESENT"
  echo ""
  echo "Primary files: ${#PRIMARY_FILES[@]}/${#PRIMARY_FILES[@]} ✅"
  echo "Feature files: ${#FEATURE_FILES[@]}/${#FEATURE_FILES[@]} ✅"
  if [ $submodule_present -gt 0 ]; then
    echo "Submodule files: $submodule_present/${#SUBMODULE_FILES[@]} present"
  fi
  echo ""
  echo "Agents can function correctly! 🎉"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "❌ AI Context System: MISSING FILES DETECTED"
  echo ""
  echo "Primary files missing: $primary_missing/${#PRIMARY_FILES[@]}"
  echo "Feature files missing: $feature_missing/${#FEATURE_FILES[@]}"
  echo "Total missing: $total_missing"
  echo ""
  echo "⚠️  Agents may not function correctly!"
  echo ""
  echo "To fix:"
  echo "1. Check if files were moved to docs/ (ewh-docs submodule)"
  echo "2. Copy them back to monorepo root:"
  echo "   cp docs/path/to/file.md ."
  echo "3. Update ewh-docs to remove duplicates"
  echo "4. See AI_CONTEXT_SYSTEM_FIXED.md for details"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
