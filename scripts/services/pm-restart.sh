#!/bin/bash

echo "🧹 Cleaning up old processes..."
lsof -ti:5500 | xargs kill -9 2>/dev/null
lsof -ti:5400 | xargs kill -9 2>/dev/null
lsof -ti:5401 | xargs kill -9 2>/dev/null

echo ""
echo "🚀 Starting PM Backend..."
cd /Users/andromeda/dev/ewh/svc-pm
npm run dev > /tmp/pm-backend.log 2>&1 &
BACKEND_PID=$!
sleep 2

# Check backend started
if curl -s http://localhost:5500/health > /dev/null 2>&1; then
  echo "✅ Backend running on http://localhost:5500 (PID: $BACKEND_PID)"
else
  echo "❌ Backend failed to start. Check /tmp/pm-backend.log"
  exit 1
fi

echo ""
echo "🚀 Starting PM Frontend..."
cd /Users/andromeda/dev/ewh/app-pm-frontend
npm run dev > /tmp/pm-frontend.log 2>&1 &
FRONTEND_PID=$!
sleep 3

# Check frontend started
if curl -s http://localhost:5400 > /dev/null 2>&1; then
  echo "✅ Frontend running on http://localhost:5400 (PID: $FRONTEND_PID)"
else
  echo "❌ Frontend failed to start. Check /tmp/pm-frontend.log"
  exit 1
fi

echo ""
echo "🧪 Testing API proxy..."
if curl -s "http://localhost:5400/api/pm/templates?tenant_id=00000000-0000-0000-0000-000000000001" | grep -q "success"; then
  echo "✅ API proxy working"
else
  echo "⚠️  API proxy may have issues"
fi

echo ""
echo "🎉 PM System is ready!"
echo ""
echo "📍 Backend:  http://localhost:5500"
echo "📍 Frontend: http://localhost:5400"
echo "📍 API:      http://localhost:5400/api/pm/*"
echo ""
echo "📄 Logs:"
echo "   Backend:  tail -f /tmp/pm-backend.log"
echo "   Frontend: tail -f /tmp/pm-frontend.log"
echo ""
echo "🛑 To stop: pkill -f 'tsx watch'; pkill -f 'vite'"
