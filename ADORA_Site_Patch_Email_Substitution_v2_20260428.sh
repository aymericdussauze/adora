#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ADORA_Site_Patch_Email_Substitution_v2_20260428.sh
# ═══════════════════════════════════════════════════════════════════════════
# v2 : ajout exclusion email-templates/ (Reply-To Gmail intentionnel)
#
# Substitue toutes les occurrences de aymericdussauze@gmail.com
# par contact@adora-economie.fr sur l'ensemble du repo SAUF email-templates/
#
# Idempotent : ré-exécutable sans risque.
# Auteur : ADORA — Aymeric Dussauze
# Date : 28/04/2026
# ═══════════════════════════════════════════════════════════════════════════

set -e

OLD_EMAIL="aymericdussauze@gmail.com"
NEW_EMAIL="contact@adora-economie.fr"

# ─── Vérifier on est dans un repo git ────────────────────────────────────
if [ ! -d ".git" ]; then
    echo "❌ Erreur : ce script doit être lancé à la racine d'un repo git."
    echo "   Fais d'abord : cd ~/Documents/GitHub/adora"
    exit 1
fi

REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
echo "📁 Repo : $REPO_NAME"
echo ""

# ─── Recherche des occurrences ───────────────────────────────────────────
echo "🔍 Recherche de '$OLD_EMAIL'..."
echo ""

MATCHES=$(grep -rln "$OLD_EMAIL" \
    --include="*.html" \
    --include="*.txt" \
    --include="*.xml" \
    --include="*.json" \
    --include="*.md" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir="_scripts" \
    --exclude-dir="email-templates" \
    . 2>/dev/null || true)

if [ -z "$MATCHES" ]; then
    echo "✅ Aucune occurrence trouvée. Repo déjà patché."
    exit 0
fi

NB_FILES=$(echo "$MATCHES" | wc -l | tr -d ' ')
echo "📊 $NB_FILES fichier(s) à patcher :"
echo "─────────────────────────────────────────"
echo "$MATCHES"
echo "─────────────────────────────────────────"
echo ""
echo "📝 Substitution : $OLD_EMAIL → $NEW_EMAIL"
echo ""
echo "⚠️  email-templates/ est EXCLU (Reply-To Gmail intentionnel)"
echo ""
echo "Continuer ? (yes/NO)"
read -r confirm
if [ "$confirm" != "yes" ]; then
    echo "Abandon."
    exit 0
fi

# ─── Application du patch ────────────────────────────────────────────────
echo ""
echo "🔧 Patch en cours..."
echo "$MATCHES" | while IFS= read -r file; do
    if [ -f "$file" ]; then
        perl -i -pe "s|\Q${OLD_EMAIL}\E|${NEW_EMAIL}|g" "$file"
        echo "  ✓ $file"
    fi
done

# ─── Vérification ────────────────────────────────────────────────────────
echo ""
echo "🔍 Vérification..."
REMAINING=$(grep -rln "$OLD_EMAIL" \
    --include="*.html" \
    --include="*.txt" \
    --include="*.xml" \
    --include="*.json" \
    --include="*.md" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir="_scripts" \
    --exclude-dir="email-templates" \
    . 2>/dev/null || true)

if [ -z "$REMAINING" ]; then
    echo "✅ Substitution complète. 0 occurrence restante (hors email-templates/)."
else
    echo "⚠️  Occurrences restantes :"
    echo "$REMAINING"
fi

echo ""
echo "📋 git status :"
echo "─────────────────────────────────────────"
git status --short
echo "─────────────────────────────────────────"
echo ""
echo "🚀 Étapes suivantes :"
echo "   1. Ouvrir GitHub Desktop, vérifier le diff"
echo "   2. Commit : 'ADORA: unification email gmail → contact@adora-economie.fr'"
echo "   3. Push vers main"
echo "   4. Purger cache Cloudflare (Caching > Purge Everything)"
echo ""
