#!/bin/bash

# Setup Docker remoto per sviluppo distribuito
# Esegui questo sulla macchina REMOTA

set -e

echo "🐳 Setup Docker Remote per EWH Platform"
echo "========================================"
echo ""

# Verifica se Docker è installato
if ! command -v docker &> /dev/null; then
    echo "📦 Installazione Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installato"
else
    echo "✅ Docker già installato"
fi

# Verifica se Docker Compose è installato
if ! command -v docker compose &> /dev/null; then
    echo "📦 Installazione Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installato"
else
    echo "✅ Docker Compose già installato"
fi

echo ""
echo "🔧 Configurazione Docker per accesso remoto..."

# Abilita Docker API su TCP (ATTENZIONE: solo in rete fidata!)
sudo mkdir -p /etc/systemd/system/docker.service.d

sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
EOF

echo "✅ Configurazione Docker API creata"

# Reload systemd e restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "✅ Docker riavviato"
echo ""

# Mostra IP del server
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📡 IP di questo server: $SERVER_IP"
echo ""

echo "⚠️  IMPORTANTE - SICUREZZA!"
echo "======================================"
echo "Docker API è ora esposto su porta 2375."
echo ""
echo "OPZIONE 1 - Firewall (RACCOMANDATO):"
echo "  # Sulla tua macchina locale, trova il tuo IP:"
echo "  ifconfig | grep inet"
echo ""
echo "  # Poi su questo server, permetti solo il tuo IP:"
echo "  sudo ufw allow from TUO_IP_LOCALE to any port 2375"
echo "  sudo ufw enable"
echo ""
echo "OPZIONE 2 - SSH Tunnel (PIÙ SICURO):"
echo "  # Dalla tua macchina locale:"
echo "  ssh -N -L 2375:localhost:2375 $(whoami)@$SERVER_IP &"
echo "  docker context create remote-dev --docker 'host=tcp://localhost:2375'"
echo ""
echo "======================================"
echo ""

echo "🚀 Setup completato!"
echo ""
echo "PROSSIMI PASSI (dalla tua macchina locale):"
echo ""
echo "1. Crea context Docker remoto:"
echo "   docker context create ewh-remote --docker 'host=tcp://$SERVER_IP:2375'"
echo ""
echo "2. Usa il context remoto:"
echo "   docker context use ewh-remote"
echo ""
echo "3. Verifica connessione:"
echo "   docker ps"
echo ""
echo "4. Torna al context locale quando vuoi:"
echo "   docker context use default"
echo ""
