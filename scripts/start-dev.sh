#!/bin/bash
# EWH Development Environment Startup Script
# Usage: ./scripts/start-dev.sh [profile]
# Profiles: minimal, admin, full (default: minimal)

set -e

PROFILE="${1:-minimal}"
COMPOSE_FILE="compose/docker-compose.dev.yml"
PROJECT_NAME="ewh"

echo "🚀 Starting EWH Development Environment"
echo "📋 Profile: $PROFILE"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Starting Docker Desktop..."
    open -a Docker
    echo "⏳ Waiting for Docker to start..."

    # Wait up to 60 seconds for Docker to be ready
    for i in {1..30}; do
        if docker info > /dev/null 2>&1; then
            echo "✅ Docker is ready"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""

    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker failed to start. Please start Docker Desktop manually."
        exit 1
    fi
fi

# Determine which services to start based on profile
case "$PROFILE" in
    minimal)
        SERVICES="postgres redis minio"
        echo "🔧 Starting minimal infrastructure (databases only)"
        ;;
    admin)
        SERVICES="postgres redis minio app-admin-frontend svc-api-gateway svc-auth"
        echo "🔧 Starting admin panel with core services"
        ;;
    full)
        echo "🔧 Starting full development stack"
        SERVICES=""
        ;;
    *)
        echo "❌ Unknown profile: $PROFILE"
        echo "Available profiles: minimal, admin, full"
        exit 1
        ;;
esac

# Stop any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down --remove-orphans 2>/dev/null || true

# Start services
echo "🏗️  Starting services..."
if [ -z "$SERVICES" ]; then
    # Start all services with default profile
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
else
    # Start specific services
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d $SERVICES
fi

# Wait for health checks
echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps

# Display connection info
echo ""
echo "✅ Development environment is ready!"
echo ""
echo "📍 Service URLs:"
echo "   PostgreSQL:     localhost:5432"
echo "   Redis:          localhost:6379"
echo "   MinIO:          http://localhost:9000 (Console: http://localhost:9001)"

if [[ "$PROFILE" == "admin" ]] || [[ "$PROFILE" == "full" ]]; then
    echo "   Admin Panel:    http://localhost:3200"
    echo "   API Gateway:    http://localhost:4000"
    echo "   Auth Service:   http://localhost:4001"
fi

if [[ "$PROFILE" == "full" ]]; then
    echo "   Web Frontend:   http://localhost:3100"
    echo "   n8n:            http://localhost:5678"
fi

echo ""
echo "🔍 View logs:       docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f [service_name]"
echo "🛑 Stop services:   docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down"
echo ""
