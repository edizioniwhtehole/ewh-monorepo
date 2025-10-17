#!/bin/bash
# Setup PostgreSQL sul Mac Studio
# Da eseguire MANUALMENTE sul Mac Studio

set -e

echo "🚀 Installazione PostgreSQL sul Mac Studio"
echo "==========================================="
echo ""

# Verifica Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Installazione Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Aggiungi Homebrew al PATH
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew già installato"
fi

# Installa PostgreSQL
echo ""
echo "📦 Installazione PostgreSQL 16..."
brew install postgresql@16

# Avvia PostgreSQL
echo ""
echo "🚀 Avvio PostgreSQL..."
brew services start postgresql@16

# Attendi che PostgreSQL sia pronto
echo "⏳ Attesa avvio PostgreSQL..."
sleep 5

# Crea database e utente
echo ""
echo "🗄️  Creazione database ewh_master..."
createdb ewh_master

# Crea utente ewh
echo "👤 Creazione utente ewh..."
psql -d ewh_master -c "CREATE USER ewh WITH PASSWORD 'ewhpass';"
psql -d ewh_master -c "GRANT ALL PRIVILEGES ON DATABASE ewh_master TO ewh;"
psql -d ewh_master -c "ALTER USER ewh WITH SUPERUSER;"

echo ""
echo "✅ PostgreSQL installato e configurato!"
echo ""
echo "📋 Informazioni connessione:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: ewh_master"
echo "  User: ewh"
echo "  Password: ewhpass"
echo ""
echo "🔍 Verifica connessione:"
echo "  psql -U ewh -d ewh_master -h localhost"
echo ""
