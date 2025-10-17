# 🚀 EWH Auto-Start - Quick Reference

## Setup Iniziale (PRIMA VOLTA)

```bash
# 1. Installa dipendenze (PostgreSQL, Redis, PM2)
./scripts/setup-mac-studio-dependencies.sh

# 2. Verifica setup
./scripts/verify-autostart-setup.sh

# 3. Installa auto-start
./scripts/install-autostart-macstudio.sh
```

## Avvio Sistema

```bash
./scripts/master-startup-macstudio.sh
```

## Comandi Essenziali

```bash
# Status servizi
ssh fabio@192.168.1.47 'pm2 list'

# Logs real-time
ssh fabio@192.168.1.47 'pm2 logs'

# Restart tutto
ssh fabio@192.168.1.47 'pm2 restart all'

# Stop tutto
ssh fabio@192.168.1.47 'pm2 stop all'
```

## Debugging

```bash
# Log startup
ssh fabio@192.168.1.47 'tail -50 /Users/fabio/dev/ewh/logs/startup-*.log'

# Log auto-healing
ssh fabio@192.168.1.47 'tail -f /tmp/ewh-autohealing-*.log'

# Check database
ssh fabio@192.168.1.47 'PGPASSWORD=ewhpass psql -h localhost -U ewh -d ewh_master'
```

## URLs Servizi

| Servizio | URL |
|----------|-----|
| API Gateway | http://192.168.1.47:4000 |
| Admin Panel | http://192.168.1.47:3200 |
| PM Frontend | http://192.168.1.47:3300 |
| DAM | http://192.168.1.47:3400 |

## Auto-Start Management

```bash
# Disabilita auto-start
ssh fabio@192.168.1.47 'launchctl unload ~/Library/LaunchAgents/com.ewh.startup.plist'

# Riabilita auto-start
ssh fabio@192.168.1.47 'launchctl load ~/Library/LaunchAgents/com.ewh.startup.plist'
```

## Emergency

```bash
# Kill tutto e riparte da zero
ssh fabio@192.168.1.47 'pm2 delete all'
./scripts/master-startup-macstudio.sh
```

---

📖 Documentazione completa: [AUTO_START_GUIDE.md](AUTO_START_GUIDE.md)
