#!/bin/bash
set -e

echo "🐳 EWH Platform - Docker Swarm Multi-Node Setup"
echo "================================================"
echo ""
echo "Questo script configura un cluster Docker Swarm a 3 nodi"
echo "per alta disponibilità distribuita."
echo ""

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per stampare in verde
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Funzione per stampare in giallo
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Funzione per stampare in rosso
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "Configurazione richiesta:"
echo "========================="
echo ""
echo "Avrai bisogno di 3 VPS (Hetzner CPX21 o simili):"
echo "  - VPS 1 (Manager): IP pubblico"
echo "  - VPS 2 (Worker):  IP pubblico"
echo "  - VPS 3 (Worker):  IP pubblico"
echo ""

read -p "IP del VPS 1 (Manager): " MANAGER_IP
read -p "IP del VPS 2 (Worker):  " WORKER1_IP
read -p "IP del VPS 3 (Worker):  " WORKER2_IP

echo ""
echo "📝 Riepilogo:"
echo "  Manager: $MANAGER_IP"
echo "  Worker1: $WORKER1_IP"
echo "  Worker2: $WORKER2_IP"
echo ""

read -p "Procedo con il setup? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# ============================================
# STEP 1: Setup Manager Node
# ============================================
echo ""
echo "🔧 STEP 1/5: Configurazione Manager Node ($MANAGER_IP)"
echo "========================================================"

ssh root@$MANAGER_IP << 'EOF'
# Installa Docker
if ! command -v docker &> /dev/null; then
    echo "→ Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Inizializza Swarm
if ! docker info | grep -q "Swarm: active"; then
    echo "→ Initializing Swarm..."
    docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
fi

# Ottieni join token
docker swarm join-token worker -q > /tmp/swarm-token.txt
echo "→ Swarm initialized!"
EOF

print_success "Manager node configured"

# Ottieni il token
SWARM_TOKEN=$(ssh root@$MANAGER_IP 'cat /tmp/swarm-token.txt')

# ============================================
# STEP 2: Setup Worker Nodes
# ============================================
echo ""
echo "🔧 STEP 2/5: Configurazione Worker Nodes"
echo "========================================="

for WORKER_IP in $WORKER1_IP $WORKER2_IP; do
    echo "→ Configuring $WORKER_IP..."

    ssh root@$WORKER_IP << EOF
# Installa Docker
if ! command -v docker &> /dev/null; then
    echo "  → Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Join Swarm
if ! docker info | grep -q "Swarm: active"; then
    echo "  → Joining Swarm..."
    docker swarm join --token $SWARM_TOKEN $MANAGER_IP:2377
fi
EOF

    print_success "Worker $WORKER_IP joined cluster"
done

# ============================================
# STEP 3: Setup Networks
# ============================================
echo ""
echo "🌐 STEP 3/5: Creazione Network Overlay"
echo "======================================="

ssh root@$MANAGER_IP << 'EOF'
# Crea overlay network per i servizi
if ! docker network ls | grep -q "ewh_overlay"; then
    docker network create --driver overlay --attachable ewh_overlay
    echo "→ Network 'ewh_overlay' created"
fi
EOF

print_success "Overlay network created"

# ============================================
# STEP 4: Deploy Stack
# ============================================
echo ""
echo "📦 STEP 4/5: Deploy Stack EWH"
echo "=============================="

# Copia docker-compose sul manager
scp -r ../compose/docker-compose.swarm.yml root@$MANAGER_IP:/root/

ssh root@$MANAGER_IP << 'EOF'
cd /root

# Deploy stack
if docker stack ls | grep -q "ewh"; then
    echo "→ Updating existing stack..."
    docker stack deploy -c docker-compose.swarm.yml ewh --prune
else
    echo "→ Deploying new stack..."
    docker stack deploy -c docker-compose.swarm.yml ewh
fi

echo "→ Waiting for services to start..."
sleep 10

echo "→ Service status:"
docker stack services ewh
EOF

print_success "Stack deployed"

# ============================================
# STEP 5: Verify Cluster
# ============================================
echo ""
echo "🔍 STEP 5/5: Verifica Cluster"
echo "=============================="

ssh root@$MANAGER_IP << 'EOF'
echo "→ Nodes:"
docker node ls

echo ""
echo "→ Services:"
docker service ls

echo ""
echo "→ Networks:"
docker network ls | grep overlay
EOF

echo ""
print_success "Cluster setup complete!"
echo ""
echo "📊 Gestione Cluster:"
echo "===================="
echo ""
echo "SSH nel manager:"
echo "  ssh root@$MANAGER_IP"
echo ""
echo "Comandi utili:"
echo "  docker node ls                    # Lista nodi"
echo "  docker service ls                 # Lista servizi"
echo "  docker service logs ewh_svc-auth  # Logs servizio"
echo "  docker service scale ewh_svc-auth=3  # Scala servizio"
echo "  docker node update --availability drain <node>  # Drain node"
echo ""
echo "Dashboard:"
echo "  docker run -d -p 9000:9000 portainer/portainer-ce"
echo "  Accedi: http://$MANAGER_IP:9000"
echo ""
print_success "All done! 🎉"
