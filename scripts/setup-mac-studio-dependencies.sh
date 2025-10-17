#!/bin/bash

# 📦 Setup Mac Studio Dependencies
# Installa tutte le dipendenze necessarie per EWH

set -e

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  EWH Dependencies Setup               ║"
echo "║  Mac Studio Edition                    ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Questo script installerà sul Mac Studio:"
echo "  • Homebrew (se non presente)"
echo "  • PostgreSQL 16"
echo "  • Redis"
echo "  • Node.js e npm"
echo "  • PM2 (process manager)"
echo ""
read -p "Continua? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annullato."
    exit 0
fi

echo ""
echo "► Connessione a Mac Studio..."

# Test connection
if ! ssh -o ConnectTimeout=5 $REMOTE_HOST "echo 'OK'" &>/dev/null; then
    echo "✗ Mac Studio non raggiungibile!"
    exit 1
fi

echo "✓ Connesso"
echo ""

# Install script
ssh $REMOTE_HOST 'bash -s' << 'ENDSSH'
set -e

echo "► Verifica Homebrew..."
if ! command -v brew &>/dev/null; then
    echo "  Homebrew non trovato, installoHuman: brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH
    if [ -d "/opt/homebrew" ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "✓ Homebrew già installato"
fi

echo ""
echo "► Installazione PostgreSQL..."
if ! command -v psql &>/dev/null; then
    brew install postgresql@16
    brew services start postgresql@16

    # Wait for PostgreSQL to start
    echo "  Attendo che PostgreSQL si avvii..."
    sleep 5

    # Create database and user
    createuser -s ewh 2>/dev/null || echo "  User ewh già esistente"
    createdb ewh_master -O ewh 2>/dev/null || echo "  Database ewh_master già esistente"

    # Set password
    psql -U ewh -d postgres -c "ALTER USER ewh WITH PASSWORD 'ewhpass';" 2>/dev/null || true

    echo "✓ PostgreSQL installato e configurato"
else
    echo "✓ PostgreSQL già installato"

    # Ensure it's running
    brew services start postgresql@16 2>/dev/null || true

    # Ensure database exists
    createdb ewh_master -O ewh 2>/dev/null || echo "  Database ewh_master già esistente"
fi

echo ""
echo "► Installazione Redis..."
if ! command -v redis-cli &>/dev/null; then
    brew install redis
    brew services start redis
    echo "✓ Redis installato e avviato"
else
    echo "✓ Redis già installato"
    brew services start redis 2>/dev/null || true
fi

echo ""
echo "► Verifica Node.js..."
if ! command -v node &>/dev/null; then
    brew install node
    echo "✓ Node.js installato"
else
    echo "✓ Node.js già installato ($(node --version))"
fi

echo ""
echo "► Installazione PM2..."
if ! command -v pm2 &>/dev/null; then
    npm install -g pm2
    pm2 startup
    echo "✓ PM2 installato"
else
    echo "✓ PM2 già installato ($(pm2 --version))"
fi

echo ""
echo "► Configurazione directories..."
mkdir -p /Users/fabio/dev/ewh/logs
echo "✓ Directory logs creata"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  INSTALLAZIONE COMPLETATA              ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Servizi installati:"
echo "  • PostgreSQL: $(psql --version | head -1)"
echo "  • Redis: $(redis-cli --version)"
echo "  • Node.js: $(node --version)"
echo "  • npm: $(npm --version)"
echo "  • PM2: $(pm2 --version)"
echo ""
echo "Database configurato:"
echo "  • Host: localhost"
echo "  • Port: 5432"
echo "  • Database: ewh_master"
echo "  • User: ewh"
echo "  • Password: ewhpass"
echo ""

ENDSSH

echo ""
echo "✓ Setup completato!"
echo ""
echo "Prossimi passi:"
echo "  1. Verifica setup: ./scripts/verify-autostart-setup.sh"
echo "  2. Avvia sistema: ./scripts/master-startup-macstudio.sh"
echo "  3. Installa auto-start: ./scripts/install-autostart-macstudio.sh"
echo ""
