#!/bin/bash
# Remote Shell Wrapper - Esegue comandi sul Mac Studio in modo trasparente
# Claude Code può usare questo per eseguire comandi remoti

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"

# Se chiamato senza argomenti, mostra help
if [ $# -eq 0 ]; then
    cat << 'EOF'
🎯 Remote Shell - Esegui comandi sul Mac Studio

Usage:
  ./remote-shell.sh <command>              Run command on Mac Studio
  ./remote-shell.sh pm2 list               PM2 status
  ./remote-shell.sh npm run dev            Start dev server
  ./remote-shell.sh "cd app-pm && npm install"  Multiple commands

Examples:
  ./remote-shell.sh pm2 list
  ./remote-shell.sh pm2 restart app-pm-frontend
  ./remote-shell.sh npm --prefix app-pm-frontend run dev
  ./remote-shell.sh lsof -i :5400

Environment variables:
  REMOTE_HOST=$REMOTE_HOST
  REMOTE_PATH=$REMOTE_PATH
EOF
    exit 0
fi

# Esegui il comando sul Mac Studio
ssh -t $REMOTE_HOST "export PATH=/usr/local/bin:\$PATH && cd $REMOTE_PATH && $*"
