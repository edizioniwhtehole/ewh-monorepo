#!/bin/bash

# 📦 Installer Auto-Start System per Mac Studio
# Configura il Mac Studio per avviare EWH automaticamente all'accensione

set -e

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  EWH Auto-Start Installer             ║"
echo "║  Mac Studio Edition                    ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Questo script configurerà il Mac Studio per:"
echo "  1. Avviare PostgreSQL all'accensione"
echo "  2. Avviare Redis all'accensione"
echo "  3. Avviare tutti i servizi EWH"
echo "  4. Avviare il sistema di auto-healing"
echo ""
read -p "Continua? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annullato."
    exit 0
fi

echo ""
echo "► Configurazione auto-start su Mac Studio..."
echo ""

# 1. Crea directory logs su Mac Studio
echo "1. Creazione directory logs..."
ssh $REMOTE_HOST "mkdir -p $REMOTE_PATH/logs"

# 2. Configura PostgreSQL auto-start
echo "2. Configurazione PostgreSQL auto-start..."
ssh $REMOTE_HOST "brew services start postgresql@16" || echo "PostgreSQL già configurato"

# 3. Configura Redis auto-start
echo "3. Configurazione Redis auto-start..."
ssh $REMOTE_HOST "brew services start redis" || echo "Redis già configurato"

# 4. Crea script startup locale su Mac Studio
echo "4. Creazione script startup locale..."

ssh $REMOTE_HOST "cat > $REMOTE_PATH/startup-local.sh << 'EOFSCRIPT'
#!/bin/bash

# Auto-generated startup script for EWH
# Runs on Mac Studio at boot

set -e

LOG_FILE=\"$REMOTE_PATH/logs/startup-\$(date +%Y%m%d-%H%M%S).log\"
exec 1> >(tee -a \"\$LOG_FILE\")
exec 2>&1

echo \"\"
echo \"[EWH Auto-Startup] \$(date)\"
echo \"\"

# Wait for network
echo \"[1/5] Waiting for network...\"
for i in {1..30}; do
    if ping -c 1 8.8.8.8 &>/dev/null; then
        echo \"✓ Network ready\"
        break
    fi
    sleep 2
done

# Wait for databases
echo \"[2/5] Waiting for databases...\"
for i in {1..30}; do
    if PGPASSWORD=ewhpass psql -h localhost -U ewh -d ewh_master -c 'SELECT 1' &>/dev/null; then
        echo \"✓ PostgreSQL ready\"
        break
    fi
    sleep 2
done

for i in {1..30}; do
    if redis-cli ping &>/dev/null; then
        echo \"✓ Redis ready\"
        break
    fi
    sleep 2
done

# Start PM2 services
echo \"[3/5] Starting PM2 services...\"
export PATH=/usr/local/bin:\$PATH

# Load ecosystem config
cd $REMOTE_PATH

# Start essential services first
pm2 start ecosystem.macstudio.config.cjs --only svc-auth
sleep 5

pm2 start ecosystem.macstudio.config.cjs --only svc-media
sleep 5

pm2 start ecosystem.macstudio.config.cjs --only svc-api-gateway
sleep 5

pm2 start ecosystem.macstudio.config.cjs --only svc-pm
sleep 5

# Start frontend apps
pm2 start ecosystem.macstudio.config.cjs --only app-admin-frontend
pm2 start ecosystem.macstudio.config.cjs --only app-pm-frontend
pm2 start ecosystem.macstudio.config.cjs --only app-dam
pm2 start ecosystem.macstudio.config.cjs --only app-inventory-frontend

# Save PM2 state
pm2 save

echo \"[4/5] Services started\"

# Start auto-healing
echo \"[5/5] Starting auto-healing monitor...\"
nohup $REMOTE_PATH/auto-healing-macstudio.sh > $REMOTE_PATH/logs/autohealing-bg.log 2>&1 &
echo \$! > /tmp/ewh-autohealing.pid

echo \"\"
echo \"✓ EWH Startup completed at \$(date)\"
echo \"\"
EOFSCRIPT
"

# Rendi eseguibile
ssh $REMOTE_HOST "chmod +x $REMOTE_PATH/startup-local.sh"

# 5. Crea LaunchAgent per auto-start
echo "5. Configurazione LaunchAgent..."

ssh $REMOTE_HOST "cat > ~/Library/LaunchAgents/com.ewh.startup.plist << 'EOFPLIST'
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>com.ewh.startup</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$REMOTE_PATH/startup-local.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <false/>

    <key>StandardOutPath</key>
    <string>$REMOTE_PATH/logs/launchagent-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>$REMOTE_PATH/logs/launchagent-stderr.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>

    <key>WorkingDirectory</key>
    <string>$REMOTE_PATH</string>

    <key>StartInterval</key>
    <integer>0</integer>
</dict>
</plist>
EOFPLIST
"

# 6. Carica LaunchAgent
echo "6. Caricamento LaunchAgent..."
ssh $REMOTE_HOST "launchctl unload ~/Library/LaunchAgents/com.ewh.startup.plist 2>/dev/null || true"
ssh $REMOTE_HOST "launchctl load ~/Library/LaunchAgents/com.ewh.startup.plist"

# 7. Configura PM2 startup
echo "7. Configurazione PM2 startup..."
ssh $REMOTE_HOST "export PATH=/usr/local/bin:\$PATH && pm2 startup" || echo "PM2 startup già configurato"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  INSTALLAZIONE COMPLETATA              ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "✓ Auto-start configurato con successo!"
echo ""
echo "Cosa succederà ora:"
echo "  1. All'accensione del Mac Studio:"
echo "     → PostgreSQL si avvia automaticamente"
echo "     → Redis si avvia automaticamente"
echo "     → Tutti i servizi EWH partono in sequenza"
echo "     → Auto-healing monitor si attiva"
echo ""
echo "  2. In caso di crash:"
echo "     → PM2 riavvia automaticamente il servizio"
echo "     → Auto-healing rileva e reagisce in 30s"
echo ""
echo "  3. In caso di riavvio Mac Studio:"
echo "     → Tutto riparte automaticamente"
echo ""
echo "Comandi utili:"
echo "  • Testa startup ora:"
echo "    ssh $REMOTE_HOST '$REMOTE_PATH/startup-local.sh'"
echo ""
echo "  • Disabilita auto-start:"
echo "    ssh $REMOTE_HOST 'launchctl unload ~/Library/LaunchAgents/com.ewh.startup.plist'"
echo ""
echo "  • Riabilita auto-start:"
echo "    ssh $REMOTE_HOST 'launchctl load ~/Library/LaunchAgents/com.ewh.startup.plist'"
echo ""
echo "  • Visualizza log:"
echo "    ssh $REMOTE_HOST 'tail -f $REMOTE_PATH/logs/startup-*.log'"
echo ""

echo "Vuoi testare lo startup ora? (y/n): "
read -p "" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "► Test startup in corso..."
    echo ""
    ssh $REMOTE_HOST "$REMOTE_PATH/startup-local.sh"
    echo ""
    echo "✓ Test completato!"
    echo ""
    echo "Verifica servizi:"
    ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list'
fi

echo ""
echo "🎉 Sistema auto-start pronto!"
echo ""
