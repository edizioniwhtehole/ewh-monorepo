#!/bin/bash
# Script per aprire browser automaticamente
# Usage: ./scripts/open-browser.sh [PORT] [delay_seconds]

PORT=${1:-3000}
DELAY=${2:-5}
URL="http://localhost:${PORT}"

echo "🌐 Opening browser in ${DELAY} seconds..."
echo "   URL: ${URL}"
echo ""

# Aspetta che il server sia pronto
sleep ${DELAY}

# Apri browser in base all'OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "${URL}"
    echo "✅ Browser opened (macOS)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v xdg-open &> /dev/null; then
        xdg-open "${URL}"
        echo "✅ Browser opened (Linux)"
    else
        echo "⚠️  xdg-open not found. Please open manually: ${URL}"
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows
    start "${URL}"
    echo "✅ Browser opened (Windows)"
else
    echo "⚠️  Unknown OS. Please open manually: ${URL}"
fi
