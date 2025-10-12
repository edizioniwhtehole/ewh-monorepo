#!/bin/bash

# Script di verifica sistema AI Context
# Controlla che tutti i file referenziati in .ai/context.json siano presenti

set -e

cd "$(dirname "$0")/.."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 EWH AI Context System - Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verifica che esista .ai/context.json
if [ ! -f ".ai/context.json" ]; then
  echo "❌ ERROR: .ai/context.json not found!"
  exit 1
fi

echo "📋 Checking primary documentation files..."
echo ""

# Estrai e verifica primary documentation
primary_missing=0
while IFS= read -r file; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (MISSING)"
    primary_missing=$((primary_missing + 1))
  fi
done < <(jq -r '.documentation.primary[].file' .ai/context.json)

echo ""
echo "📚 Checking feature-specific documentation files..."
echo ""

# Estrai e verifica feature-specific documentation
feature_missing=0
while IFS= read -r file; do
  # Salta file in submodule app-web-frontend (hanno path relativo)
  if [[ $file == app-web-frontend/* ]]; then
    if [ -f "$file" ]; then
      echo "  ✅ $file (in submodule)"
    else
      echo "  ⚠️  $file (submodule not initialized or missing)"
    fi
    continue
  fi

  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (MISSING)"
    feature_missing=$((feature_missing + 1))
  fi
done < <(jq -r '.documentation.feature_specific[].file' .ai/context.json)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

total_missing=$((primary_missing + feature_missing))

if [ $total_missing -eq 0 ]; then
  echo "✅ AI Context System: ALL FILES PRESENT"
  echo ""
  echo "Primary files: OK"
  echo "Feature files: OK"
  echo ""
  echo "Agents can function correctly! 🎉"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "❌ AI Context System: MISSING FILES DETECTED"
  echo ""
  echo "Primary files missing: $primary_missing"
  echo "Feature files missing: $feature_missing"
  echo "Total missing: $total_missing"
  echo ""
  echo "⚠️  Agents may not function correctly!"
  echo ""
  echo "To fix:"
  echo "1. Check if files were moved to docs/ (ewh-docs submodule)"
  echo "2. Copy them back to monorepo root"
  echo "3. Update ewh-docs to remove duplicates"
  echo "4. See AI_CONTEXT_SYSTEM_FIXED.md for details"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
