#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ADORA — Injection favicon sur toutes les pages
# Compatible macOS (BSD sed)
# Usage : ./inject-favicon.sh [répertoire]
# ═══════════════════════════════════════════════════════════

DIR="${1:-.}"
COUNT=0
SKIP=0

echo ""
echo "   ADORA — Injection favicon"
echo "   Repertoire : $DIR"
echo "   -----------------------------------------"

FAVICON_TAGS='    <link rel="icon" type="image/x-icon" href="favicon.ico">\
    <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">\
    <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">\
    <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">'

for file in "$DIR"/*.html; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")

  # Vérifier si déjà présent
  if grep -q 'rel="icon"' "$file"; then
    echo "   skip $filename (deja present)"
    SKIP=$((SKIP + 1))
    continue
  fi

  # Injecter après <meta charset
  sed -i '' '/<meta charset/a\
    <link rel="icon" type="image/x-icon" href="favicon.ico">\
    <link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">\
    <link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">\
    <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
' "$file"

  if grep -q 'rel="icon"' "$file"; then
    echo "   ok   $filename"
    COUNT=$((COUNT + 1))
  else
    echo "   FAIL $filename"
  fi
done

echo "   -----------------------------------------"
echo "   $COUNT fichiers modifies"
echo "   $SKIP deja a jour"
echo ""
