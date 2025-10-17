#!/bin/bash
# Migrazione database dal MacBook al Mac Studio
# Da eseguire SUL MACBOOK dopo aver installato PostgreSQL sul Mac Studio

set -e

echo "🔄 Migrazione Database MacBook → Mac Studio"
echo "==========================================="
echo ""

# Dump del database locale
echo "📦 Creazione dump del database locale..."
pg_dump -h localhost -p 5432 -U ewh -d ewh_master -F c -f /tmp/ewh_master_dump.backup

echo "✅ Dump creato: /tmp/ewh_master_dump.backup"

# Copia dump sul Mac Studio
echo ""
echo "📤 Copia dump sul Mac Studio..."
scp /tmp/ewh_master_dump.backup fabio@192.168.1.47:/tmp/

echo "✅ Dump copiato"

# Restore sul Mac Studio
echo ""
echo "📥 Restore database sul Mac Studio..."
ssh fabio@192.168.1.47 'pg_restore -h localhost -p 5432 -U ewh -d ewh_master -c /tmp/ewh_master_dump.backup'

echo "✅ Database migrato con successo!"
echo ""
echo "🔧 Prossimi passi:"
echo "  1. Verifica che i dati siano presenti sul Mac Studio"
echo "  2. Rimuovi il reverse tunnel SSH:"
echo "     ps aux | grep 'ssh.*-R 5432' | grep -v grep | awk '{print \$2}' | xargs kill"
echo "  3. Riavvia svc-media sul Mac Studio:"
echo "     ssh fabio@192.168.1.47 'npx pm2 restart svc-media'"
echo ""
