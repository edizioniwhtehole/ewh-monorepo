#!/bin/bash
# Script per mappare i pannelli admin esistenti nei servizi

echo "📋 MAPPATURA PANNELLI ADMIN PER SERVIZI"
echo "========================================"
echo ""

# Contatori
TOTAL=0
WITH_ADMIN=0
WITHOUT_ADMIN=0

# File output
OUTPUT_FILE="ADMIN_PANELS_MAP.md"

cat > "$OUTPUT_FILE" << 'EOF'
# Mappa Pannelli Admin per Servizi
*Generato automaticamente*

## Servizi con Pannelli Admin Esistenti

EOF

echo "## Con pannelli admin:"
echo ""

for dir in svc-*/; do
  if [ ! -d "$dir" ]; then continue; fi

  service=$(basename "$dir")
  TOTAL=$((TOTAL + 1))

  # Cerca file admin nel servizio
  admin_files=""

  if [ -d "$dir/src/routes" ]; then
    admin_files=$(find "$dir/src/routes" -type f \( -name "*admin*.ts" -o -name "*dev*.ts" -o -name "*settings*.ts" \) 2>/dev/null)
  fi

  if [ -n "$admin_files" ]; then
    WITH_ADMIN=$((WITH_ADMIN + 1))
    echo "✓ $service"

    # Aggiungi al markdown
    echo "### $service" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "**Files trovati:**" >> "$OUTPUT_FILE"

    while IFS= read -r file; do
      filename=$(basename "$file")
      echo "  - $filename"
      echo "- \`$filename\`" >> "$OUTPUT_FILE"
    done <<< "$admin_files"

    echo "" >> "$OUTPUT_FILE"
  fi
done

echo ""
echo "## Senza pannelli admin:"
echo ""

cat >> "$OUTPUT_FILE" << 'EOF'

## Servizi Senza Pannelli Admin (da creare)

EOF

for dir in svc-*/; do
  if [ ! -d "$dir" ]; then continue; fi

  service=$(basename "$dir")

  # Cerca file admin
  admin_files=""
  if [ -d "$dir/src/routes" ]; then
    admin_files=$(find "$dir/src/routes" -type f \( -name "*admin*.ts" -o -name "*dev*.ts" -o -name "*settings*.ts" \) 2>/dev/null)
  fi

  if [ -z "$admin_files" ]; then
    WITHOUT_ADMIN=$((WITHOUT_ADMIN + 1))
    echo "✗ $service"
    echo "- $service" >> "$OUTPUT_FILE"
  fi
done

echo ""
echo "========================================"
echo "📊 STATISTICHE"
echo "========================================"
echo "Totale servizi: $TOTAL"
echo "Con pannelli admin: $WITH_ADMIN"
echo "Senza pannelli admin: $WITHOUT_ADMIN"
echo ""
echo "Report salvato in: $OUTPUT_FILE"

# Aggiungi statistiche al file
cat >> "$OUTPUT_FILE" << EOF

---

## Statistiche

- **Totale servizi**: $TOTAL
- **Con pannelli admin**: $WITH_ADMIN ($((WITH_ADMIN * 100 / TOTAL))%)
- **Senza pannelli admin**: $WITHOUT_ADMIN ($((WITHOUT_ADMIN * 100 / TOTAL))%)

EOF
