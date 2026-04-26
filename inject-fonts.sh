#!/usr/bin/env bash
# ============================================================================
# ADORA — inject-fonts.sh
# Remplace les <link> Google Fonts par le CSS auto-hébergé /assets/fonts/adora-fonts.css
# Patche les 22 fichiers HTML à la racine du repo en une passe.
#
# Usage : depuis la racine du repo aymericdussauze/adora
#   bash _scripts/inject-fonts.sh
#
# Backups : crée un fichier .bak.fonts à côté de chaque HTML modifié.
# Idempotent : si déjà patché, le script saute le fichier.
# ============================================================================

set -e

REPO_ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Vérification : on doit être à la racine du repo
if [ ! -f "$REPO_ROOT/index.html" ]; then
  echo "❌ Erreur : ce script doit être lancé depuis la racine du repo (où index.html existe)."
  echo "   Tu es ici : $REPO_ROOT"
  exit 1
fi

# Vérification : le CSS local doit être présent
if [ ! -f "$REPO_ROOT/assets/fonts/adora-fonts.css" ]; then
  echo "❌ Erreur : /assets/fonts/adora-fonts.css introuvable."
  echo "   Vérifie que tu as bien copié le dossier assets/fonts/ avec ses 14 woff2 + adora-fonts.css"
  exit 1
fi

echo "════════════════════════════════════════════════════════════════"
echo "  ADORA — Injection fonts auto-hébergées"
echo "  Repo  : $REPO_ROOT"
echo "  Date  : $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════════"
echo ""

PATCHED=0
SKIPPED=0
ALREADY=0

for html in "$REPO_ROOT"/*.html; do
  [ -f "$html" ] || continue
  filename=$(basename "$html")

  # Idempotence : si déjà patché, skip
  if grep -q "adora-fonts.css" "$html"; then
    echo "  ⏭️   $filename  (déjà patché)"
    ALREADY=$((ALREADY+1))
    continue
  fi

  # Détection : le fichier utilise-t-il Google Fonts ?
  if ! grep -q "fonts.googleapis.com\|fonts.gstatic.com" "$html"; then
    echo "  ⏭️   $filename  (pas de Google Fonts détecté)"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  # Backup avant modification
  cp "$html" "${html}.bak.fonts"

  # Patch via Python (plus fiable que sed pour ce genre de manip multi-lignes)
  python3 - "$html" << 'PYEOF'
import sys, re

html_path = sys.argv[1]
with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 1) Supprimer les <link rel="preconnect" href="https://fonts.googleapis.com"...>
content = re.sub(
    r'\s*<link\s+rel=["\']preconnect["\']\s+href=["\']https://fonts\.googleapis\.com["\'][^>]*?/?>\s*',
    '\n    ',
    content
)

# 2) Supprimer les <link rel="preconnect" href="https://fonts.gstatic.com"...>
content = re.sub(
    r'\s*<link\s+rel=["\']preconnect["\']\s+href=["\']https://fonts\.gstatic\.com["\'][^>]*?/?>\s*',
    '\n    ',
    content
)

# 3) Remplacer le <link href="https://fonts.googleapis.com/css2?..."> par le CSS local
content = re.sub(
    r'<link\s+href=["\']https://fonts\.googleapis\.com/css2[^"\']*["\']\s+rel=["\']stylesheet["\'][^>]*?/?>',
    '<link rel="stylesheet" href="/assets/fonts/adora-fonts.css">',
    content
)

# Variante : <link rel="stylesheet" href="https://fonts.googleapis.com/...">
content = re.sub(
    r'<link\s+rel=["\']stylesheet["\']\s+href=["\']https://fonts\.googleapis\.com/css2[^"\']*["\'][^>]*?/?>',
    '<link rel="stylesheet" href="/assets/fonts/adora-fonts.css">',
    content
)

# Nettoyage : compresser les triples lignes vides éventuelles
content = re.sub(r'\n{3,}', '\n\n', content)

if content == original:
    print("⚠️  Aucun changement appliqué — patterns non matchés", file=sys.stderr)
    sys.exit(2)

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

  if [ $? -eq 0 ]; then
    echo "  ✅  $filename  patché"
    PATCHED=$((PATCHED+1))
  else
    echo "  ⚠️   $filename  patterns non matchés — backup gardé"
    mv "${html}.bak.fonts" "$html"
  fi
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Bilan"
echo "════════════════════════════════════════════════════════════════"
echo "  ✅  Patchés         : $PATCHED"
echo "  ⏭️   Déjà à jour    : $ALREADY"
echo "  ⏭️   Sans Fonts     : $SKIPPED"
echo ""
echo "  Backups disponibles : *.html.bak.fonts (à côté de chaque fichier patché)"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ⚠️  Étapes suivantes (à faire MANUELLEMENT)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  1. Vérifier visuellement 1-2 fichiers patchés :"
echo "     grep -A2 'adora-fonts.css' index.html"
echo ""
echo "  2. Tester en local en ouvrant index.html dans le navigateur."
echo "     Les fonts doivent rester identiques visuellement."
echo ""
echo "  3. Commit + push via GitHub Desktop :"
echo "     - Vérifier la liste des fichiers modifiés (22 HTML + 15 fichiers /assets/fonts/)"
echo "     - Ne PAS commit les .bak.fonts (les ajouter à .gitignore si besoin)"
echo "     - Commit message : 'Auto-hébergement Google Fonts (RGPD + perf)'"
echo "     - Push origin"
echo ""
echo "  4. ⚠️  IMPORTANT — Mettre à jour le CSP Cloudflare :"
echo "     Cloudflare → Rules → ADORA Sec-6 CSP-ReportOnly → Edit"
echo "     Retirer : https://fonts.googleapis.com et https://fonts.gstatic.com"
echo "     (de style-src et font-src)"
echo ""
echo "  5. Une fois en prod : tester https://adora-economie.fr"
echo "     Network tab DevTools → vérifier que les .woff2 sont servis"
echo "     depuis /assets/fonts/ (pas fonts.gstatic.com)"
echo ""
echo "════════════════════════════════════════════════════════════════"
