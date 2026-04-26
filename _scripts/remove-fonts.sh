#!/usr/bin/env bash
# ============================================================================
# ADORA — remove-fonts.sh (ROLLBACK)
# Restaure les fichiers HTML depuis les backups .bak.fonts créés par inject-fonts.sh
#
# Usage : depuis la racine du repo aymericdussauze/adora
#   bash _scripts/remove-fonts.sh
# ============================================================================

set -e
REPO_ROOT="$(pwd)"

if [ ! -f "$REPO_ROOT/index.html" ]; then
  echo "❌ Erreur : ce script doit être lancé depuis la racine du repo."
  exit 1
fi

echo "════════════════════════════════════════════════════════════════"
echo "  ADORA — Rollback fonts (restauration depuis .bak.fonts)"
echo "════════════════════════════════════════════════════════════════"
echo ""

RESTORED=0

for backup in "$REPO_ROOT"/*.html.bak.fonts; do
  [ -f "$backup" ] || continue
  original="${backup%.bak.fonts}"
  filename=$(basename "$original")

  mv "$backup" "$original"
  echo "  🔄  $filename  restauré"
  RESTORED=$((RESTORED+1))
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ✅  $RESTORED fichiers restaurés"
echo "════════════════════════════════════════════════════════════════"
