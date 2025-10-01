#!/usr/bin/env bash
for f in ~/dev/ewh/scripts/*.sh; do
  /bin/chmod +x "$f"
done
echo "✅ Tutti gli script resi eseguibili"