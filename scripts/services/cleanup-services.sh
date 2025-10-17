#!/bin/bash
echo "🧹 Cleaning up all Node/npm processes..."
pkill -9 node 2>/dev/null
pkill -9 tsx 2>/dev/null
sleep 2

echo "🔍 Checking ports 3300 and 4003..."
lsof -ti:3300 | xargs kill -9 2>/dev/null
lsof -ti:4003 | xargs kill -9 2>/dev/null
sleep 1

echo "✅ Cleanup complete"
ps aux | grep -E "npm|tsx|node" | grep -v grep || echo "No processes found"
