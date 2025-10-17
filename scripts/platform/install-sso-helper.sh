#!/bin/bash

# Install Shell SSO Helper to all frontend apps
# This script copies the shared SSO helper files to each frontend app

set -e

echo "🔐 Installing Shell SSO Helper to all frontend apps..."

# Source files
SSO_HELPER="/Users/andromeda/dev/ewh/shared/shell-sso-helper.ts"
AUTH_CONTEXT="/Users/andromeda/dev/ewh/shared/ShellAuthContext.template.tsx"

# Frontend apps
FRONTEND_APPS=(
  "app-pm-frontend"
  "app-dam"
  "app-approvals-frontend"
  "app-inventory-frontend"
  "app-procurement-frontend"
  "app-quotations-frontend"
  "app-orders-purchase-frontend"
  "app-orders-sales-frontend"
  "app-settings-frontend"
  "app-cms-frontend"
  "app-media-frontend"
  "app-page-builder"
)

INSTALLED=0
SKIPPED=0
FAILED=0

for app in "${FRONTEND_APPS[@]}"; do
  APP_DIR="/Users/andromeda/dev/ewh/$app"

  if [ ! -d "$APP_DIR" ]; then
    echo "⏭️  Skipping $app (directory not found)"
    ((SKIPPED++))
    continue
  fi

  echo ""
  echo "📦 Processing $app..."

  # Create directories if needed
  mkdir -p "$APP_DIR/src/lib"
  mkdir -p "$APP_DIR/src/context"

  # Copy shell-sso helper
  if cp "$SSO_HELPER" "$APP_DIR/src/lib/shell-sso.ts"; then
    echo "  ✅ Copied shell-sso.ts to $app/src/lib/"
  else
    echo "  ❌ Failed to copy shell-sso.ts to $app"
    ((FAILED++))
    continue
  fi

  # Copy auth context (rename from .template.tsx to .tsx)
  if cp "$AUTH_CONTEXT" "$APP_DIR/src/context/ShellAuthContext.tsx"; then
    echo "  ✅ Copied ShellAuthContext.tsx to $app/src/context/"
  else
    echo "  ❌ Failed to copy ShellAuthContext.tsx to $app"
    ((FAILED++))
    continue
  fi

  ((INSTALLED++))
  echo "  ✅ $app configured for Shell SSO"
done

echo ""
echo "================================================"
echo "📊 Summary:"
echo "  ✅ Installed: $INSTALLED apps"
echo "  ⏭️  Skipped: $SKIPPED apps"
echo "  ❌ Failed: $FAILED apps"
echo "================================================"

if [ $INSTALLED -gt 0 ]; then
  echo ""
  echo "⚠️  Next Steps:"
  echo "1. Update _app.tsx in each frontend to use ShellAuthProvider"
  echo "2. Use useShellAuth() hook in pages to access token"
  echo "3. Update API calls to include Authorization header"
  echo ""
  echo "See SHELL_SSO_INTEGRATION.md for detailed instructions"
fi
