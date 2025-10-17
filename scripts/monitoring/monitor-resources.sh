#!/bin/bash

# Monitora l'uso di risorse dei servizi EWH

echo "🔍 Monitoraggio Risorse EWH"
echo "======================================"
echo ""

# Controlla PM2
if command -v pm2 &> /dev/null; then
  echo "📊 Servizi PM2:"
  npx pm2 list
  echo ""

  echo "💾 Memoria per servizio:"
  npx pm2 jlist | jq -r '.[] | "\(.name): \(.monit.memory / 1024 / 1024 | floor)MB CPU: \(.monit.cpu)%"' 2>/dev/null || echo "Installa jq per dettagli: brew install jq"
  echo ""
fi

# Controlla Docker
if command -v docker &> /dev/null; then
  CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null)
  if [ ! -z "$CONTAINERS" ]; then
    echo "🐳 Container Docker:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null
    echo ""
  fi
fi

# Uso totale sistema
echo "💻 Sistema:"
echo "CPU Load: $(sysctl -n vm.loadavg 2>/dev/null || uptime | awk '{print $(NF-2), $(NF-1), $NF}')"
echo "Memory: $(vm_stat 2>/dev/null | awk '/Pages free/ {free=$3} /Pages active/ {active=$3} /Pages inactive/ {inactive=$3} /Pages wired/ {wired=$4} END {total=(free+active+inactive+wired)*4096/1024/1024/1024; used=(active+wired)*4096/1024/1024/1024; printf "%.1fGB used / %.1fGB total (%.0f%%)\n", used, total, (used/total)*100}' || echo "N/A")"

echo ""
echo "💡 Suggerimenti:"

# Controlla se ci sono troppi processi Node
NODE_PROCESSES=$(pgrep -c node)
if [ $NODE_PROCESSES -gt 20 ]; then
  echo "⚠️  Hai $NODE_PROCESSES processi Node attivi!"
  echo "   Considera di usare: ./start-profiles.sh <profile>"
fi

# Controlla memoria disponibile
if command -v vm_stat &> /dev/null; then
  FREE_MEMORY=$(vm_stat | awk '/Pages free/ {print $3}' | sed 's/\.//')
  FREE_GB=$((FREE_MEMORY * 4096 / 1024 / 1024 / 1024))

  if [ $FREE_GB -lt 2 ]; then
    echo "⚠️  Memoria libera bassa (${FREE_GB}GB)"
    echo "   Ferma servizi non necessari: npx pm2 stop <nome>"
  fi
fi

echo ""
echo "📖 Per ottimizzare:"
echo "   ./start-profiles.sh <profile>  - Avvia solo servizi necessari"
echo "   npx pm2 stop all              - Ferma tutto PM2"
echo "   docker compose down           - Ferma tutto Docker"
