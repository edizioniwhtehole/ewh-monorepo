#!/bin/bash

# 🧹 Ottimizzazione Memoria Mac Studio
# Riduce il footprint dei servizi Node.js

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"

echo ""
echo "🧹 Ottimizzazione Memoria Mac Studio"
echo "========================================"
echo ""

# 1. Analisi memoria attuale
echo "📊 Analisi uso memoria..."
echo ""

ssh $REMOTE_HOST '
echo "RAM Fisica:"
sysctl hw.memsize | awk "{print \$2/1024/1024/1024 \" GB\"}"

echo ""
echo "Uso attuale:"
vm_stat | perl -ne "/page size of (\d+)/ and \$size=\$1; /Pages\\s+([^:]+)[^\\d]+(\\d+)/ and printf(\"%-16s % 16.2f MB\\n\", \"\$1:\", \$2 * \$size / 1048576);"

echo ""
echo "Top 10 processi per memoria:"
ps aux | sort -k4 -rn | head -10 | awk "{printf \"%-8s %-8s %-8s %s\\n\", \$2, \$3\"%\", \$4\"%\", \$11}"

echo ""
echo "Processi Node.js:"
ps aux | grep -E "node|npm|tsx" | grep -v grep | awk "{printf \"PID: %-8s MEM: %-6s %s\\n\", \$2, \$4\"%\", \$11}"
'

echo ""
echo "🔧 Opzioni di ottimizzazione:"
echo ""
echo "1. Limita memoria Node.js (consigliato)"
echo "2. Riavvia servizi con memory limit"
echo "3. Disabilita servizi non essenziali"
echo "4. Pulisci cache e processi zombie"
echo "5. Setup profili di avvio leggeri"
echo ""
read -p "Scegli opzione (1-5, 0=esci): " choice

case $choice in
    1)
        echo ""
        echo "⚙️  Configurazione memory limits..."

        ssh $REMOTE_HOST "
        cd $REMOTE_PATH

        # Crea file .env per ogni servizio con memory limit
        for service in svc-auth svc-api-gateway svc-pm svc-db; do
            if [ -d \$service ]; then
                echo 'NODE_OPTIONS=--max-old-space-size=512' > \$service/.env.local
                echo '✅ Memory limit 512MB per' \$service
            fi
        done

        # Frontend più generosi
        for app in app-pm-frontend app-media-frontend app-shell-frontend; do
            if [ -d \$app ]; then
                echo 'NODE_OPTIONS=--max-old-space-size=1024' > \$app/.env.local
                echo '✅ Memory limit 1GB per' \$app
            fi
        done
        "

        echo ""
        echo "✅ Configurazione completata!"
        echo "   Riavvia i servizi per applicare: pm2 restart all"
        ;;

    2)
        echo ""
        echo "🔄 Riavvio servizi con memory limit..."

        ssh $REMOTE_HOST "
        export PATH=/usr/local/bin:\$PATH
        cd $REMOTE_PATH

        # Stop tutto
        pm2 delete all 2>/dev/null || true

        # Riavvia con memory limit
        cd svc-auth && NODE_OPTIONS='--max-old-space-size=512' pm2 start npm --name svc-auth -- run dev
        cd ../svc-api-gateway && NODE_OPTIONS='--max-old-space-size=512' pm2 start npm --name svc-api-gateway -- run dev
        cd ../svc-pm && NODE_OPTIONS='--max-old-space-size=512' pm2 start npm --name svc-pm -- run dev
        cd ../app-pm-frontend && NODE_OPTIONS='--max-old-space-size=1024' pm2 start npm --name app-pm-frontend -- run dev

        pm2 save
        "

        echo ""
        echo "✅ Servizi riavviati con memory limit!"
        ;;

    3)
        echo ""
        echo "🎯 Servizi attivi:"
        ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list'

        echo ""
        echo "Quale servizio vuoi disabilitare?"
        read -p "Nome servizio (o 'all' per fermare tutto): " service_name

        if [ "$service_name" = "all" ]; then
            ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 stop all'
            echo "✅ Tutti i servizi fermati"
        else
            ssh $REMOTE_HOST "export PATH=/usr/local/bin:\$PATH && pm2 stop $service_name"
            echo "✅ $service_name fermato"
        fi
        ;;

    4)
        echo ""
        echo "🧹 Pulizia cache e processi..."

        ssh $REMOTE_HOST "
        # Kill processi zombie node
        pkill -9 -f 'node.*zombie' 2>/dev/null || true

        # Pulisci cache pm2
        export PATH=/usr/local/bin:\$PATH
        pm2 flush

        # Pulisci cache Node.js
        rm -rf ~/.npm/_cacache 2>/dev/null || true

        # Pulisci build cache
        find $REMOTE_PATH -type d -name '.next' -exec rm -rf {} + 2>/dev/null || true
        find $REMOTE_PATH -type d -name 'dist' -exec rm -rf {} + 2>/dev/null || true
        find $REMOTE_PATH -type d -name '.vite' -exec rm -rf {} + 2>/dev/null || true

        echo '✅ Cache pulita'
        "

        echo ""
        echo "✅ Pulizia completata!"
        ;;

    5)
        echo ""
        echo "📝 Creazione profili di avvio leggeri..."

        # Crea ecosystem.config.js ottimizzato
        ssh $REMOTE_HOST "cat > $REMOTE_PATH/ecosystem.light.config.js << 'EOF'
module.exports = {
  apps: [
    // Solo servizi essenziali
    {
      name: 'svc-auth',
      cwd: '$REMOTE_PATH/svc-auth',
      script: 'npm',
      args: 'run dev',
      max_memory_restart: '512M',
      node_args: '--max-old-space-size=512'
    },
    {
      name: 'svc-api-gateway',
      cwd: '$REMOTE_PATH/svc-api-gateway',
      script: 'npm',
      args: 'run dev',
      max_memory_restart: '512M',
      node_args: '--max-old-space-size=512'
    }
  ]
}
EOF
"

        echo "✅ Profilo leggero creato!"
        echo ""
        echo "Per usarlo:"
        echo "  ssh $REMOTE_HOST 'cd $REMOTE_PATH && pm2 start ecosystem.light.config.js'"
        ;;

    0)
        echo "Uscita."
        exit 0
        ;;

    *)
        echo "Opzione non valida."
        exit 1
        ;;
esac

echo ""
echo "🎉 Fatto!"
echo ""
