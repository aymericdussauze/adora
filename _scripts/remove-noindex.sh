#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ADORA — Retrait meta noindex (migration prod - Phase 4)
# Usage : ./remove-noindex.sh [répertoire]
# Défaut : répertoire courant
#
# ATTENTION : conserve le noindex sur les pages utilitaires
# (paiement-reussi, mon-rapport, unsubscribe)
# ═══════════════════════════════════════════════════════════

DIR="${1:-.}"
COUNT=0
KEEP=0

# Pages qui DOIVENT rester en noindex même en prod
NOINDEX_PAGES="paiement-reussi.html mon-rapport.html unsubscribe.html"

echo "🚀 ADORA — Retrait meta noindex (migration prod)"
echo "   Répertoire : $DIR"
echo "   Pages protégées : $NOINDEX_PAGES"
echo "   ─────────────────────────────────────────"

for file in "$DIR"/*.html; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")

  # Vérifier si c'est une page à garder en noindex
  PROTECTED=false
  for kept in $NOINDEX_PAGES; do
    if [ "$filename" = "$kept" ]; then
      PROTECTED=true
      break
    fi
  done

  if $PROTECTED; then
    echo "   🔒 $filename (noindex conservé — page utilitaire)"
    KEEP=$((KEEP + 1))
    continue
  fi

  # Vérifier si la balise existe
  if ! grep -q 'name="robots"' "$file"; then
    continue
  fi

  # Supprimer la ligne meta robots
  sed -i '/<meta name="robots" content="noindex, nofollow">/d' "$file"
  echo "   ✅ $filename (noindex retiré)"
  COUNT=$((COUNT + 1))
done

echo "   ─────────────────────────────────────────"
echo "   ✅ $COUNT fichiers débloqués | 🔒 $KEEP pages utilitaires protégées"
echo ""
echo "   Étapes suivantes :"
echo "   1. Remplacer robots.txt par robots_PROD.txt"
echo "   2. Le sitemap.xml est déjà en version prod"
echo "   3. Configurer GitHub Pages avec custom domain adora-economie.fr"
echo "   4. Soumettre sitemap à Google Search Console + Bing Webmaster"
