#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ADORA_Site_Patch_Email_Substitution_v1_20260428.sh
# ═══════════════════════════════════════════════════════════════════════════
# Substitue toutes les occurrences de aymericdussauze@gmail.com
# par contact@adora-economie.fr sur l'ensemble du repo.
#
# Périmètre :
#   • Tous les fichiers .html (footer, mailto, JSON-LD schema, contenu)
#   • security.txt (RFC 9116, alignement décidé 28/04/2026)
#   • Tout autre .txt / .xml / .json / .md du repo
#
# Garde-fous :
#   • Vérifie qu'on est dans un repo git
#   • Vérifie que le nom du repo contient "adora"
#   • Dry-run preview + confirmation avant patch
#   • Vérification post-patch (0 occurrence restante)
#   • Affichage du git status final
#
# Idempotent : ré-exécutable sans risque.
# Auteur : ADORA — Aymeric Dussauze
# Date : 28/04/2026
# Convention : ADORA_Sujet_vN_Dateaaaammjj
# ═══════════════════════════════════════════════════════════════════════════

set -e

OLD_EMAIL="aymericdussauze@gmail.com"
NEW_EMAIL="contact@adora-economie.fr"
EXPECTED_REPO_PATTERN="adora"

# ─── 1. Vérifier on est dans un repo git ──────────────────────────────────
if [ ! -d ".git" ]; then
    echo "❌ Erreur : ce script doit être exécuté à la racine d'un repo git."
    echo "   Ouvre Terminal, fais 'cd' vers le dossier du repo cloné, puis relance."
    exit 1
fi

# ─── 2. Vérifier le nom du repo ───────────────────────────────────────────
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
echo "📁 Repo détecté : $REPO_NAME"
echo ""

if [[ "$REPO_NAME" != *"$EXPECTED_REPO_PATTERN"* ]]; then
    echo "⚠️  Le nom du repo ne contient pas '$EXPECTED_REPO_PATTERN'."
    echo "   Es-tu sûr d'être dans le bon repo ? Continuer ? (yes/NO)"
    read -r confirm
    if [ "$confirm" != "yes" ]; then
        echo "Abandon."
        exit 0
    fi
fi

# ─── 3. Recherche des occurrences (dry-run) ──────────────────────────────
echo "🔍 Recherche des occurrences de '$OLD_EMAIL'..."
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
    . 2>/dev/null || true)

if [ -z "$MATCHES" ]; then
    echo "✅ Aucune occurrence trouvée. Repo déjà patché — rien à faire."
    exit 0
fi

NB_FILES=$(echo "$MATCHES" | wc -l | tr -d ' ')
TOTAL_COUNT=$(grep -ron "$OLD_EMAIL" \
    --include="*.html" \
    --include="*.txt" \
    --include="*.xml" \
    --include="*.json" \
    --include="*.md" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir="_scripts" \
    . 2>/dev/null | wc -l | tr -d ' ')

echo "📊 $TOTAL_COUNT occurrence(s) dans $NB_FILES fichier(s)"
echo ""
echo "Fichiers concernés :"
echo "─────────────────────────────────────────"
echo "$MATCHES"
echo "─────────────────────────────────────────"
echo ""
echo "Aperçu (premières 30 lignes) :"
echo "─────────────────────────────────────────"
grep -rn "$OLD_EMAIL" \
    --include="*.html" \
    --include="*.txt" \
    --include="*.xml" \
    --include="*.json" \
    --include="*.md" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir="_scripts" \
    . 2>/dev/null | head -30
echo "─────────────────────────────────────────"
echo ""
echo "📝 Substitution prévue :"
echo "   $OLD_EMAIL"
echo "       ↓"
echo "   $NEW_EMAIL"
echo ""
echo "Continuer la substitution ? (yes/NO)"
read -r confirm
if [ "$confirm" != "yes" ]; then
    echo "Abandon."
    exit 0
fi

# ─── 4. Application du patch ──────────────────────────────────────────────
echo ""
echo "🔧 Application de la substitution..."
echo "$MATCHES" | while IFS= read -r file; do
    if [ -f "$file" ]; then
        # \Q...\E désactive les métacaractères regex (le . est traité littéralement)
        perl -i -pe "s|\Q$OLD_EMAIL\E|$NEW_EMAIL|g" "$file"
        echo "  ✓ $file"
    fi
done

# ─── 5. Vérification post-patch ───────────────────────────────────────────
echo ""
echo "🔍 Vérification post-patch..."
REMAINING=$(grep -ron "$OLD_EMAIL" \
    --include="*.html" \
    --include="*.txt" \
    --include="*.xml" \
    --include="*.json" \
    --include="*.md" \
    --exclude-dir=".git" \
    --exclude-dir="node_modules" \
    --exclude-dir="_scripts" \
    . 2>/dev/null | wc -l | tr -d ' ')

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ Substitution complète. 0 occurrence de '$OLD_EMAIL' restante."
else
    echo "⚠️  $REMAINING occurrence(s) restante(s). À vérifier manuellement :"
    grep -rn "$OLD_EMAIL" \
        --include="*.html" \
        --include="*.txt" \
        --include="*.xml" \
        --include="*.json" \
        --include="*.md" \
        --exclude-dir=".git" \
        --exclude-dir="node_modules" \
        --exclude-dir="_scripts" \
        . 2>/dev/null
fi

# ─── 6. Récap git status ──────────────────────────────────────────────────
echo ""
echo "📋 Fichiers modifiés (git status) :"
echo "─────────────────────────────────────────"
git status --short
echo "─────────────────────────────────────────"
echo ""
echo "✅ Patch terminé."
echo ""
echo "🚀 Prochaines étapes :"
echo "   1. Ouvrir GitHub Desktop pour vérifier le diff"
echo "   2. Commit message suggéré :"
echo "      ADORA: unification email gmail → contact@adora-economie.fr"
echo "   3. Push vers main"
echo "   4. (Optionnel) Purger le cache Cloudflare pour propagation immédiate :"
echo "      Cloudflare > Caching > Configuration > Purge Everything"
echo "   5. Vérifier en prod : view-source d'une page → 0 occurrence Gmail"
echo ""
