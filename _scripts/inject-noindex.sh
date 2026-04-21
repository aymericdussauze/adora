#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ADORA — Injection meta noindex sur toutes les pages staging
# Compatible macOS (BSD sed) + Linux (GNU sed)
# Usage : ./inject-noindex.sh [répertoire]
# ═══════════════════════════════════════════════════════════

DIR="${1:-.}"
COUNT=0
SKIP=0
FAIL=0

echo ""
echo "   ADORA — Injection meta noindex/nofollow"
echo "   Repertoire : $DIR"
echo "   -----------------------------------------"

for file in "$DIR"/*.html; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")

  # Verifier si la balise existe deja
  if grep -q 'name="robots"' "$file"; then
    echo "   skip $filename (deja present)"
    SKIP=$((SKIP + 1))
    continue
  fi

  # Injection compatible macOS BSD sed :
  # sed -i '' (extension vide = pas de fichier backup)
  # Nouvelle ligne litterale dans le remplacement (pas \n)
  if grep -q '<head>' "$file"; then
    sed -i '' '/<head>/a\
    <meta name="robots" content="noindex, nofollow">
' "$file"

    # Verifier que ca a marche
    if grep -q 'name="robots"' "$file"; then
      echo "   ok   $filename"
      COUNT=$((COUNT + 1))
    else
      echo "   FAIL $filename"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "   WARN $filename (pas de <head>)"
    FAIL=$((FAIL + 1))
  fi
done

echo "   -----------------------------------------"
echo "   $COUNT fichiers modifies"
echo "   $SKIP deja a jour"
if [ $FAIL -gt 0 ]; then
  echo "   $FAIL echecs"
fi
echo ""
TOTAL=$(grep -rl 'name="robots"' "$DIR"/*.html 2>/dev/null | wc -l | tr -d ' ')
echo "   Verification : $TOTAL fichiers contiennent noindex"
echo ""
