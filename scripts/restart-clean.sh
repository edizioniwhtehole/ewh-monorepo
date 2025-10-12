#!/bin/bash
echo "🧹 Pulizia totale processi..."
killall -9 node pnpm 2>/dev/null
sleep 3

echo "🚀 Avvio frontend admin..."
cd /Users/andromeda/dev/ewh
PORT=3200 pnpm --filter app-admin-frontend dev
