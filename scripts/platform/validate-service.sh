#!/bin/bash
# Script di Validazione per Backend Services
# Usage: ./scripts/validate-service.sh svc-example

set -e

SERVICE_NAME=$1
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$SERVICE_NAME" ]; then
  echo -e "${RED}❌ Error: Service name required${NC}"
  echo "Usage: ./scripts/validate-service.sh svc-example"
  exit 1
fi

echo "============================================"
echo "  Validating Backend Service: $SERVICE_NAME"
echo "============================================"
echo ""

ERRORS=0
WARNINGS=0

# Check service directory exists
if [ ! -d "$SERVICE_NAME" ]; then
  echo -e "${RED}❌ Service directory not found: $SERVICE_NAME${NC}"
  exit 1
fi

cd "$SERVICE_NAME"

echo "📁 Checking directory structure..."

# Check mandatory files
MANDATORY_FILES=(
  "src/index.ts"
  "package.json"
  "tsconfig.json"
  ".env.example"
  "README.md"
)

for file in "${MANDATORY_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "  ${GREEN}✓${NC} $file"
  else
    echo -e "  ${RED}✗${NC} $file ${RED}MISSING${NC}"
    ((ERRORS++))
  fi
done

echo ""
echo "📦 Checking package.json..."

# Check package.json scripts
if [ -f "package.json" ]; then
  if grep -q '"dev"' package.json && grep -q '"build"' package.json; then
    echo -e "  ${GREEN}✓${NC} Required scripts present"
  else
    echo -e "  ${RED}✗${NC} Missing required scripts (dev, build)"
    ((ERRORS++))
  fi

  # Check dependencies
  if grep -q '"express"' package.json || grep -q '"fastify"' package.json; then
    echo -e "  ${GREEN}✓${NC} Web framework present"
  else
    echo -e "  ${YELLOW}⚠${NC} No web framework found (express/fastify)"
    ((WARNINGS++))
  fi

  if grep -q '"tsx"' package.json; then
    echo -e "  ${GREEN}✓${NC} tsx for development"
  else
    echo -e "  ${YELLOW}⚠${NC} tsx not found in devDependencies"
    ((WARNINGS++))
  fi
fi

echo ""
echo "🏥 Checking health check endpoint..."

# Check if health check is implemented
if [ -f "src/index.ts" ]; then
  if grep -q '/health' src/index.ts; then
    echo -e "  ${GREEN}✓${NC} Health check endpoint found in code"

    # Try to check if service is running
    PORT=$(grep -o "PORT.*=.*[0-9]\{4,5\}" src/index.ts | grep -o "[0-9]\{4,5\}" | head -1)
    if [ ! -z "$PORT" ]; then
      echo "  📍 Detected port: $PORT"
      if curl -s -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Service responding on port $PORT"
      else
        echo -e "  ${YELLOW}⚠${NC} Service not responding (may not be running)"
      fi
    fi
  else
    echo -e "  ${RED}✗${NC} No health check endpoint found in src/index.ts"
    ((ERRORS++))
  fi
fi

echo ""
echo "🔧 Checking PM2 configuration..."

# Check if service is in ecosystem config
if grep -q "name: '$SERVICE_NAME'" ../ecosystem.macstudio.config.cjs; then
  echo -e "  ${GREEN}✓${NC} Service found in ecosystem.macstudio.config.cjs"

  # Check memory limits
  if grep -A 20 "name: '$SERVICE_NAME'" ../ecosystem.macstudio.config.cjs | grep -q "max_memory_restart"; then
    echo -e "  ${GREEN}✓${NC} Memory limits configured"
  else
    echo -e "  ${YELLOW}⚠${NC} Memory limits not configured"
    ((WARNINGS++))
  fi

  # Check health check settings
  if grep -A 20 "name: '$SERVICE_NAME'" ../ecosystem.macstudio.config.cjs | grep -q "wait_ready"; then
    echo -e "  ${GREEN}✓${NC} Health check integration configured"
  else
    echo -e "  ${YELLOW}⚠${NC} PM2 health check not configured (wait_ready)"
    ((WARNINGS++))
  fi
else
  echo -e "  ${RED}✗${NC} Service NOT found in ecosystem.macstudio.config.cjs"
  ((ERRORS++))
fi

echo ""
echo "🔐 Checking environment variables..."

if [ -f ".env.example" ]; then
  # Check mandatory vars
  MANDATORY_VARS=("PORT" "NODE_ENV" "SERVICE_NAME")

  for var in "${MANDATORY_VARS[@]}"; do
    if grep -q "^$var=" .env.example; then
      echo -e "  ${GREEN}✓${NC} $var documented"
    else
      echo -e "  ${YELLOW}⚠${NC} $var not documented in .env.example"
      ((WARNINGS++))
    fi
  done
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
fi

echo ""
echo "🔍 Checking code quality..."

if [ -f "src/index.ts" ]; then
  # Check for graceful shutdown
  if grep -q "SIGINT" src/index.ts; then
    echo -e "  ${GREEN}✓${NC} Graceful shutdown implemented"
  else
    echo -e "  ${RED}✗${NC} No graceful shutdown (SIGINT handler)"
    ((ERRORS++))
  fi

  # Check for PM2 ready signal
  if grep -q "process.send.*ready" src/index.ts; then
    echo -e "  ${GREEN}✓${NC} PM2 ready signal implemented"
  else
    echo -e "  ${YELLOW}⚠${NC} PM2 ready signal not found (process.send('ready'))"
    ((WARNINGS++))
  fi

  # Check for request logging
  if grep -q "req.*res.*next" src/index.ts && (grep -q "console.log" src/index.ts || grep -q "logger" src/index.ts); then
    echo -e "  ${GREEN}✓${NC} Request logging implemented"
  else
    echo -e "  ${YELLOW}⚠${NC} Request logging may be missing"
    ((WARNINGS++))
  fi
fi

echo ""
echo "============================================"
echo "  Validation Summary"
echo "============================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed! Service is compliant.${NC}"
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