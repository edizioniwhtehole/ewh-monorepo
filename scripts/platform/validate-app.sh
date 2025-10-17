#!/bin/bash
# Script di Validazione per Frontend Applications
# Usage: ./scripts/validate-app.sh app-example-frontend

set -e

APP_NAME=$1
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$APP_NAME" ]; then
  echo -e "${RED}❌ Error: App name required${NC}"
  echo "Usage: ./scripts/validate-app.sh app-example-frontend"
  exit 1
fi

echo "============================================"
echo "  Validating Frontend App: $APP_NAME"
echo "============================================"
echo ""

ERRORS=0
WARNINGS=0

# Check app directory exists
if [ ! -d "$APP_NAME" ]; then
  echo -e "${RED}❌ App directory not found: $APP_NAME${NC}"
  exit 1
fi

cd "$APP_NAME"

echo "📁 Checking directory structure..."

# Detect framework
IS_NEXTJS=false
IS_VITE=false

if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
  IS_NEXTJS=true
  echo "  🔍 Detected: Next.js application"
elif [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
  IS_VITE=true
  echo "  🔍 Detected: Vite application"
else
  echo -e "  ${RED}✗${NC} Unknown framework (no Next.js or Vite config)"
  ((ERRORS++))
fi

# Check mandatory files
MANDATORY_FILES=(
  "package.json"
  ".env.example"
  "README.md"
)

if [ "$IS_NEXTJS" = true ]; then
  MANDATORY_FILES+=("next.config.js" "next.config.mjs")
fi

if [ "$IS_VITE" = true ]; then
  MANDATORY_FILES+=("vite.config.ts")
fi

for file in "${MANDATORY_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "  ${GREEN}✓${NC} $file"
  else
    # Skip alternative configs
    if [[ "$file" == "next.config.js" ]] && [ -f "next.config.mjs" ]; then
      continue
    fi
    if [[ "$file" == "next.config.mjs" ]] && [ -f "next.config.js" ]; then
      continue
    fi

    echo -e "  ${YELLOW}⚠${NC} $file not found"
    ((WARNINGS++))
  fi
done

echo ""
echo "📦 Checking package.json..."

if [ -f "package.json" ]; then
  # Check scripts
  if grep -q '"dev"' package.json && grep -q '"build"' package.json; then
    echo -e "  ${GREEN}✓${NC} Required scripts present"
  else
    echo -e "  ${RED}✗${NC} Missing required scripts (dev, build)"
    ((ERRORS++))
  fi

  # Check dependencies
  if grep -q '"react"' package.json; then
    echo -e "  ${GREEN}✓${NC} React dependency present"
  else
    echo -e "  ${RED}✗${NC} React dependency missing"
    ((ERRORS++))
  fi
fi

echo ""
echo "⚙️  Checking framework configuration..."

# Check Vite config
if [ "$IS_VITE" = true ] && [ -f "vite.config.ts" ]; then
  if grep -q "port:" vite.config.ts; then
    PORT=$(grep -o "port: [0-9]\{4,5\}" vite.config.ts | grep -o "[0-9]\{4,5\}")
    echo -e "  ${GREEN}✓${NC} Port configured: $PORT"
  else
    echo -e "  ${YELLOW}⚠${NC} Port not explicitly configured in vite.config.ts"
    ((WARNINGS++))
  fi

  if grep -q "host: '0.0.0.0'" vite.config.ts || grep -q 'host: "0.0.0.0"' vite.config.ts; then
    echo -e "  ${GREEN}✓${NC} Host configured for remote access (0.0.0.0)"
  else
    echo -e "  ${YELLOW}⚠${NC} Host not set to 0.0.0.0 (required for remote access)"
    ((WARNINGS++))
  fi

  if grep -q "sourcemap: true" vite.config.ts; then
    echo -e "  ${GREEN}✓${NC} Sourcemaps enabled"
  else
    echo -e "  ${YELLOW}⚠${NC} Sourcemaps not enabled (recommended for debugging)"
    ((WARNINGS++))
  fi
fi

# Check Next.js config
if [ "$IS_NEXTJS" = true ]; then
  CONFIG_FILE=""
  if [ -f "next.config.js" ]; then
    CONFIG_FILE="next.config.js"
  elif [ -f "next.config.mjs" ]; then
    CONFIG_FILE="next.config.mjs"
  fi

  if [ ! -z "$CONFIG_FILE" ]; then
    if grep -q "reactStrictMode" "$CONFIG_FILE"; then
      echo -e "  ${GREEN}✓${NC} React Strict Mode configured"
    else
      echo -e "  ${YELLOW}⚠${NC} React Strict Mode not enabled"
      ((WARNINGS++))
    fi
  fi

  # Check for port in package.json
  if grep -q '"dev".*-p [0-9]' package.json; then
    PORT=$(grep -o '\-p [0-9]\{4,5\}' package.json | grep -o '[0-9]\{4,5\}' | head -1)
    echo -e "  ${GREEN}✓${NC} Port configured in dev script: $PORT"
  else
    echo -e "  ${YELLOW}⚠${NC} Port not explicitly set in dev script"
    ((WARNINGS++))
  fi
fi

echo ""
echo "🔧 Checking PM2 configuration..."

# Check if app is in ecosystem config
if grep -q "name: '$APP_NAME'" ../ecosystem.macstudio.config.cjs; then
  echo -e "  ${GREEN}✓${NC} App found in ecosystem.macstudio.config.cjs"

  # Check memory limits
  if grep -A 20 "name: '$APP_NAME'" ../ecosystem.macstudio.config.cjs | grep -q "max_memory_restart"; then
    echo -e "  ${GREEN}✓${NC} Memory limits configured"
  else
    echo -e "  ${YELLOW}⚠${NC} Memory limits not configured"
    ((WARNINGS++))
  fi
else
  echo -e "  ${RED}✗${NC} App NOT found in ecosystem.macstudio.config.cjs"
  ((ERRORS++))
fi

echo ""
echo "🗺️  Checking Shell integration..."

# Check if app is registered in services.config.ts
if grep -q "$APP_NAME\|$(echo $APP_NAME | sed 's/app-//' | sed 's/-frontend//')" ../app-shell-frontend/src/lib/services.config.ts; then
  echo -e "  ${GREEN}✓${NC} App registered in Shell services.config.ts"

  # Try to find the app entry
  if grep -B 5 -A 5 "$PORT" ../app-shell-frontend/src/lib/services.config.ts | grep -q "name:"; then
    echo -e "  ${GREEN}✓${NC} App configuration looks complete"
  fi
else
  echo -e "  ${RED}✗${NC} App NOT registered in Shell services.config.ts"
  echo -e "  ${YELLOW}➜${NC} Add app to app-shell-frontend/src/lib/services.config.ts"
  ((ERRORS++))
fi

echo ""
echo "🔐 Checking environment variables..."

if [ -f ".env.example" ]; then
  # Check for appropriate prefix
  if [ "$IS_VITE" = true ]; then
    if grep -q "^VITE_" .env.example; then
      echo -e "  ${GREEN}✓${NC} VITE_ prefix used for environment variables"
    else
      echo -e "  ${YELLOW}⚠${NC} No VITE_ prefixed variables (may be intentional)"
      ((WARNINGS++))
    fi
  fi

  if [ "$IS_NEXTJS" = true ]; then
    if grep -q "^NEXT_PUBLIC_" .env.example; then
      echo -e "  ${GREEN}✓${NC} NEXT_PUBLIC_ prefix used for environment variables"
    else
      echo -e "  ${YELLOW}⚠${NC} No NEXT_PUBLIC_ prefixed variables (may be intentional)"
      ((WARNINGS++))
    fi
  fi
else
  echo -e "  ${YELLOW}⚠${NC} No .env.example file"
  ((WARNINGS++))
fi

echo ""
echo "📖 Checking README.md..."

if [ -f "README.md" ]; then
  # Check for mandatory sections
  MANDATORY_SECTIONS=("Descrizione" "Porte" "Environment" "Avviare")

  for section in "${MANDATORY_SECTIONS[@]}"; do
    if grep -qi "$section" README.md; then
      echo -e "  ${GREEN}✓${NC} Section present: $section"
    else
      echo -e "  ${YELLOW}⚠${NC} Section missing or incomplete: $section"
      ((WARNINGS++))
    fi
  done
else
  echo -e "  ${YELLOW}⚠${NC} README.md not found"
  ((WARNINGS++))
fi

echo ""
echo "🔍 Checking if app is running..."

if [ ! -z "$PORT" ]; then
  if lsof -i :$PORT > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} App is running on port $PORT"

    # Try to fetch the app
    if curl -s -f "http://localhost:$PORT" > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} App responding to HTTP requests"
    else
      echo -e "  ${YELLOW}⚠${NC} App running but not responding (may be starting)"
    fi
  else
    echo -e "  ${YELLOW}⚠${NC} App not currently running on port $PORT"
  fi
fi

echo ""
echo "============================================"
echo "  Validation Summary"
echo "============================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed! App is compliant.${NC}"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠ Passed with $WARNINGS warnings${NC}"
  echo -e "${YELLOW}Please review and fix warnings for best practices.${NC}"
  exit 0
else
  echo -e "${RED}✗ Validation failed with $ERRORS errors and $WARNINGS warnings${NC}"
  echo -e "${RED}Please fix errors before deployment.${NC}"
  exit 1
fi