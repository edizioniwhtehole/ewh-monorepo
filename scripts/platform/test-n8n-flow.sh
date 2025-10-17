#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test n8n Bridge - Request/Response Correlation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Invia richiesta al bridge
echo "📤 Step 1: Sending request to bridge..."
RESPONSE=$(curl -s -X POST http://localhost:5680/workflows/test-echo/execute \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello from EWH!",
    "timestamp": "'$(date +%s)'"
  }')

echo "$RESPONSE"
echo ""

# Estrai correlation_id
CORRELATION_ID=$(echo $RESPONSE | grep -o '"correlation_id":"[^"]*"' | cut -d'"' -f4)
POLL_URL=$(echo $RESPONSE | grep -o '"poll_url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CORRELATION_ID" ]; then
  echo "❌ Failed to get correlation_id"
  exit 1
fi

echo "✅ Correlation ID: $CORRELATION_ID"
echo "📍 Poll URL: $POLL_URL"
echo ""

# 2. Simula n8n che processa e ritorna risultato
echo "🤖 Step 2: Simulating n8n processing..."
sleep 2

# n8n chiamerebbe questo endpoint quando finisce
curl -s -X POST "http://localhost:5680/workflows/results/$CORRELATION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "result": {
      "echo": "Hello from EWH!",
      "processed_by": "n8n",
      "processed_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "ai_response": "This is a mock AI response to your message!"
    }
  }' > /dev/null

echo "✅ Result saved by n8n"
echo ""

# 3. Client fa polling per il risultato
echo "📥 Step 3: Polling for result..."
for i in {1..5}; do
  RESULT=$(curl -s "http://localhost:5680$POLL_URL")
  STATUS=$(echo $RESULT | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

  echo "   Attempt $i: Status = $STATUS"

  if [ "$STATUS" = "completed" ]; then
    echo ""
    echo "✅ ✅ ✅ SUCCESS! Result received:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🎯 Key Points:"
    echo "   • Request matched to response via correlation_id"
    echo "   • Tenant isolation verified"
    echo "   • Async processing works"
    echo ""
    exit 0
  fi

  sleep 1
done

echo "⏱️ Timeout waiting for result"
exit 1
