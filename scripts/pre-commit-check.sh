#!/bin/bash

# EWH Platform - Pre-Commit Documentation Check
# This script ensures agents update documentation before committing

set -e

echo "🔍 EWH Pre-Commit Check: Verifying documentation updates..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get list of changed files
CHANGED_FILES=$(git diff --cached --name-only)

# Check if any service code changed
SERVICE_CHANGED=false
CHANGED_SERVICE=""

for file in $CHANGED_FILES; do
  if [[ $file =~ ^(svc-|app-) ]]; then
    SERVICE_CHANGED=true
    # Extract service name
    CHANGED_SERVICE=$(echo $file | cut -d'/' -f1)
    break
  fi
done

# If service code changed, check if documentation updated
if [ "$SERVICE_CHANGED" = true ]; then
  echo "📦 Detected changes in: $CHANGED_SERVICE"

  # Check if PROJECT_STATUS.md was updated
  STATUS_UPDATED=false
  for file in $CHANGED_FILES; do
    if [[ $file == "PROJECT_STATUS.md" ]]; then
      STATUS_UPDATED=true
      break
    fi
  done

  # Check if service PROMPT.md was updated
  PROMPT_UPDATED=false
  for file in $CHANGED_FILES; do
    if [[ $file == "$CHANGED_SERVICE/PROMPT.md" ]]; then
      PROMPT_UPDATED=true
      break
    fi
  done

  # Report results
  echo ""
  echo "📋 Documentation Update Check:"

  if [ "$STATUS_UPDATED" = true ]; then
    echo -e "${GREEN}✓${NC} PROJECT_STATUS.md updated"
  else
    echo -e "${RED}✗${NC} PROJECT_STATUS.md NOT updated"
  fi

  if [ "$PROMPT_UPDATED" = true ]; then
    echo -e "${GREEN}✓${NC} $CHANGED_SERVICE/PROMPT.md updated"
  else
    echo -e "${YELLOW}⚠${NC} $CHANGED_SERVICE/PROMPT.md not updated (optional but recommended)"
  fi

  # Check if session-continuity.md was updated
  SESSION_UPDATED=false
  for file in $CHANGED_FILES; do
    if [[ $file == ".claude/session-continuity.md" ]]; then
      SESSION_UPDATED=true
      break
    fi
  done

  if [ "$SESSION_UPDATED" = true ]; then
    echo -e "${GREEN}✓${NC} .claude/session-continuity.md updated"
  else
    echo -e "${YELLOW}⚠${NC} .claude/session-continuity.md not updated (recommended for multi-session)"
  fi

  # BLOCK commit if PROJECT_STATUS.md not updated
  if [ "$STATUS_UPDATED" = false ]; then
    echo ""
    echo -e "${RED}❌ COMMIT BLOCKED${NC}"
    echo ""
    echo "You modified $CHANGED_SERVICE but didn't update PROJECT_STATUS.md"
    echo ""
    echo "Please update PROJECT_STATUS.md with:"
    echo "  1. Move features from 'Missing' to 'Implemented'"
    echo "  2. Update completion percentage"
    echo "  3. Document any new blockers"
    echo ""
    echo "Then stage the changes:"
    echo "  git add PROJECT_STATUS.md"
    echo ""
    echo "ALSO UPDATE (if multi-session task):"
    echo "  .claude/session-continuity.md"
    echo "  → Document current state and next steps"
    echo ""
    echo "To bypass this check (NOT recommended):"
    echo "  git commit --no-verify"
    echo ""
    exit 1
  fi

  # Warn if .ai/context.json not updated for major changes
  CONTEXT_UPDATED=false
  for file in $CHANGED_FILES; do
    if [[ $file == ".ai/context.json" ]]; then
      CONTEXT_UPDATED=true
      break
    fi
  done

  # Check if this is a completion (service moving from scaffolding to in_progress/complete)
  if git diff --cached PROJECT_STATUS.md | grep -q "scaffolding.*complete\|scaffolding.*in_progress"; then
    if [ "$CONTEXT_UPDATED" = false ]; then
      echo ""
      echo -e "${YELLOW}⚠ WARNING:${NC} Service status changed but .ai/context.json not updated"
      echo ""
      echo "Recommended: Update .ai/context.json to reflect new service status"
      echo "  1. Edit .ai/context.json"
      echo "  2. Move service from 'scaffolding' to 'in_progress' or 'complete'"
      echo "  3. git add .ai/context.json"
      echo ""
      echo "Continue anyway? (y/n)"
      read -r response
      if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
      fi
    fi
  fi
fi

# Check if ARCHITECTURE.md or core docs changed
CORE_DOCS_CHANGED=false
for file in $CHANGED_FILES; do
  if [[ $file =~ ^(ARCHITECTURE|GUARDRAILS|MASTER_PROMPT|CONTEXT_INDEX)\.md$ ]]; then
    CORE_DOCS_CHANGED=true
    break
  fi
done

if [ "$CORE_DOCS_CHANGED" = true ]; then
  echo ""
  echo -e "${YELLOW}⚠ INFO:${NC} Core documentation changed"
  echo "Make sure to update version number and 'last_updated' date"
  echo ""
fi

# Check for common mistakes
echo ""
echo "🔍 Checking for common mistakes..."

# Check for console.log in TypeScript files
CONSOLE_LOG_FOUND=false
for file in $CHANGED_FILES; do
  if [[ $file =~ \.ts$ || $file =~ \.tsx$ ]]; then
    if git diff --cached $file | grep -q "^+.*console\.log"; then
      CONSOLE_LOG_FOUND=true
      echo -e "${YELLOW}⚠${NC} console.log found in $file (use structured logging instead)"
    fi
  fi
done

# Check for missing tenant_id in SQL
MISSING_TENANT_ID=false
for file in $CHANGED_FILES; do
  if [[ $file =~ \.sql$ ]]; then
    if git diff --cached $file | grep -q "^+.*CREATE TABLE" && ! git diff --cached $file | grep -q "tenant_id"; then
      MISSING_TENANT_ID=true
      echo -e "${RED}✗${NC} Table without tenant_id found in $file (multi-tenancy violation!)"
    fi
  fi
done

# Check for TODO without tracking
TODO_WITHOUT_TRACKING=false
for file in $CHANGED_FILES; do
  if [[ $file =~ \.(ts|tsx|js|jsx)$ ]]; then
    if git diff --cached $file | grep -q "^+.*TODO" && ! git diff --cached $file | grep -q "TODO.*#\|TODO.*@"; then
      TODO_WITHOUT_TRACKING=true
      echo -e "${YELLOW}⚠${NC} TODO without tracking found in $file (add issue reference or @agent)"
    fi
  fi
done

# Block if critical issues found
if [ "$MISSING_TENANT_ID" = true ]; then
  echo ""
  echo -e "${RED}❌ COMMIT BLOCKED${NC}"
  echo "Multi-tenancy violation: Table without tenant_id"
  echo "Add tenant_id column to all tables"
  exit 1
fi

# Summary
echo ""
if [ "$SERVICE_CHANGED" = true ]; then
  echo -e "${GREEN}✓${NC} Documentation checks passed"
fi
echo -e "${GREEN}✓${NC} Pre-commit checks completed"
echo ""
echo "Proceeding with commit..."

exit 0
