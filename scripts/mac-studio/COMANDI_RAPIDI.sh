#!/bin/bash

# Comandi Rapidi - Sistema Auto-Avvio EWH

echo "╔════════════════════════════════════════════════╗"
echo "║     COMANDI RAPIDI - Sistema Auto-Avvio        ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

show_menu() {
    echo "Scegli un'opzione:"
    echo ""
    echo "  1) Avvia sistema completo"
    echo "  2) Ferma tutti i servizi"
    echo "  3) Riavvia tutti i servizi"
    echo "  4) Vedi stato servizi"
    echo "  5) Vedi service registry"
    echo "  6) Libera porte bloccate"
    echo "  7) Installa dipendenze"
    echo "  8) Apri dashboard"
    echo "  0) Esci"
    echo ""
    read -p "Opzione: " choice

    case $choice in
        1) start_system ;;
        2) stop_services ;;
        3) restart_services ;;
        4) show_status ;;
        5) show_registry ;;
        6) free_ports ;;
        7) install_deps ;;
        8) open_dashboard ;;
        0) exit 0 ;;
        *) echo "Opzione non valida"; show_menu ;;
    esac
}

start_system() {
    echo ""
    echo "🚀 Avvio sistema completo..."
    echo ""
    cd /Users/andromeda/dev/ewh
    pnpm start
}

stop_services() {
    echo ""
    echo "⏹️  Fermando tutti i servizi..."
    echo ""

    # Trova tutti i processi pnpm run dev
    pids=$(pgrep -f "pnpm run dev")

    if [ -z "$pids" ]; then
        echo "✅ Nessun servizio in esecuzione"
    else
        echo "Fermando processi: $pids"
        echo "$pids" | xargs kill -SIGTERM
        sleep 2
        echo "✅ Servizi fermati"
    fi

    echo ""
    read -p "Premi ENTER per continuare..."
    show_menu
}

restart_services() {
    echo ""
    echo "🔄 Riavvio servizi..."
    echo ""
    stop_services
    sleep 2
    start_system
}

show_status() {
    echo ""
    echo "📊 Stato servizi:"
    echo ""

    # Mostra processi node
    echo "Processi Node.js:"
    ps aux | grep -E "node|pnpm" | grep -v grep | head -20

    echo ""
    echo "Porte in ascolto:"
    lsof -iTCP -sTCP:LISTEN | grep node | head -20

    echo ""
    read -p "Premi ENTER per continuare..."
    show_menu
}

show_registry() {
    echo ""
    echo "📋 Service Registry:"
    echo ""

    if [ -f "/Users/andromeda/dev/ewh/service-registry.json" ]; then
        if command -v jq &> /dev/null; then
            cat /Users/andromeda/dev/ewh/service-registry.json | jq
        else
            cat /Users/andromeda/dev/ewh/service-registry.json
        fi
    else
        echo "❌ service-registry.json non trovato"
        echo "   Avvia l'orchestratore per generarlo"
    fi

    echo ""
    read -p "Premi ENTER per continuare..."
    show_menu
}

free_ports() {
    echo ""
    echo "🔓 Liberazione porte..."
    echo ""

    read -p "Quale porta vuoi liberare? (es. 3000): " port

    if [ -z "$port" ]; then
        echo "❌ Porta non specificata"
    else
        pid=$(lsof -ti:$port)
        if [ -z "$pid" ]; then
            echo "✅ Porta $port già libera"
        else
            echo "Uccidendo processo $pid sulla porta $port..."
            lsof -ti:$port | xargs kill -9
            echo "✅ Porta $port liberata"
        fi
    fi

    echo ""
    read -p "Premi ENTER per continuare..."
    show_menu
}

install_deps() {
    echo ""
    echo "📦 Installazione dipendenze..."
    echo ""

    cd /Users/andromeda/dev/ewh

    echo "Installando dipendenze root..."
    pnpm install

    echo ""
    echo "✅ Dipendenze installate"
    echo ""
    read -p "Premi ENTER per continuare..."
    show_menu
}

open_dashboard() {
    echo ""
    echo "🌐 Apertura dashboard..."
    echo ""

    # Apri browser
    open http://localhost:3000/services 2>/dev/null || \
    xdg-open http://localhost:3000/services 2>/dev/null || \
    echo "Apri manualmente: http://localhost:3000/services"

    echo ""
    read -p "Premi ENTER per continuare..."
    show_menu
}

# Menu principale
show_menu
