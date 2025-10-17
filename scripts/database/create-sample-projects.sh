#!/bin/bash

API_URL="http://localhost:5500/api/pm"
TENANT_ID="00000000-0000-0000-0000-000000000001"
USER_ID="00000000-0000-0000-0000-000000000001"

echo "Creating sample projects..."

# Project 1: Italian Cookbook
PROJECT1=$(curl -s -X POST "$API_URL/projects/from-template" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenantId\": \"$TENANT_ID\",
    \"templateKey\": \"book_publication\",
    \"projectName\": \"Italian Cookbook - Pasta & Risotto\",
    \"startDate\": \"2025-09-15\",
    \"endDate\": \"2026-03-15\",
    \"projectManagerId\": \"$USER_ID\"
  }")

PROJECT1_ID=$(echo $PROJECT1 | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "✅ Created: Italian Cookbook ($PROJECT1_ID)"

# Project 2: Venice Guide
PROJECT2=$(curl -s -X POST "$API_URL/projects/from-template" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenantId\": \"$TENANT_ID\",
    \"templateKey\": \"tourist_guide\",
    \"projectName\": \"Venice Hidden Gems Guide\",
    \"startDate\": \"2025-10-01\",
    \"endDate\": \"2026-02-01\",
    \"projectManagerId\": \"$USER_ID\"
  }")

PROJECT2_ID=$(echo $PROJECT2 | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "✅ Created: Venice Guide ($PROJECT2_ID)"

# Project 3: Bookmarks
PROJECT3=$(curl -s -X POST "$API_URL/projects/from-template" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenantId\": \"$TENANT_ID\",
    \"templateKey\": \"gadget_production\",
    \"projectName\": \"Venice Landmarks Bookmarks\",
    \"startDate\": \"2025-10-20\",
    \"endDate\": \"2025-12-20\",
    \"projectManagerId\": \"$USER_ID\"
  }")

PROJECT3_ID=$(echo $PROJECT3 | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "✅ Created: Bookmarks ($PROJECT3_ID)"

# Update some tasks to make them more interesting
if [ -n "$PROJECT1_ID" ]; then
  # Get first 2 tasks and mark as done
  TASKS=$(curl -s "$API_URL/projects/$PROJECT1_ID/tasks")
  TASK1_ID=$(echo $TASKS | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  TASK2_ID=$(echo $TASKS | grep -o '"id":"[^"]*"' | head -2 | tail -1 | cut -d'"' -f4)

  if [ -n "$TASK1_ID" ]; then
    curl -s -X PATCH "$API_URL/tasks/$TASK1_ID" \
      -H "Content-Type: application/json" \
      -d "{\"status\":\"done\",\"actualHours\":75,\"assignedTo\":\"$USER_ID\"}" > /dev/null
    echo "  ✓ Task 1 marked as done"
  fi

  if [ -n "$TASK2_ID" ]; then
    curl -s -X PATCH "$API_URL/tasks/$TASK2_ID" \
      -H "Content-Type: application/json" \
      -d "{\"status\":\"in_progress\",\"actualHours\":15,\"assignedTo\":\"$USER_ID\"}" > /dev/null
    echo "  ✓ Task 2 in progress"
  fi
fi

echo ""
echo "🎉 Sample projects created successfully!"
echo "   - Italian Cookbook (2 tasks started)"
echo "   - Venice Guide (fresh)"
echo "   - Bookmarks (fresh)"
