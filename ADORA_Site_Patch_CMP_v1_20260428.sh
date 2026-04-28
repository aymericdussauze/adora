#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ADORA_Site_Patch_CMP_v1_20260428.sh
# ═══════════════════════════════════════════════════════════════════════════
# Déploiement complet du CMP custom :
#
#   1. Copie adora-cmp.js dans /assets/js/
#   2. Copie adora-cmp.css dans /assets/css/
#   3. Sur chaque page HTML :
#      a) Insère <link> CSS et <script> JS en <head>
#      b) Convertit le bloc GA4 inline en <script type="text/plain"
#         data-adora-consent="analytics"> (différé jusqu'au consentement)
#      c) Ajoute le bouton "Gérer mes cookies" dans le footer
#
# Pré-requis dans le repo :
#   • adora-cmp.js (à copier dans /assets/js/)
#   • adora-cmp.css (à copier dans /assets/css/)
#
# Idempotent : ré-exécutable sans risque (vérifie présence avant insertion).
# Auteur : ADORA — Aymeric Dussauze
# Date : 28/04/2026
# ═══════════════════════════════════════════════════════════════════════════

set -e

# ─── Vérifier on est dans un repo git ────────────────────────────────────
if [ ! -d ".git" ]; then
    echo "❌ Erreur : ce script doit être lancé à la racine du repo adora."
    echo "   Fais d'abord : cd ~/Documents/GitHub/adora"
    exit 1
fi

REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
echo "📁 Repo : $REPO_NAME"
echo ""

# ─── Vérifier présence des fichiers source ───────────────────────────────
if [ ! -f "adora-cmp.js" ] || [ ! -f "adora-cmp.css" ]; then
    echo "❌ Erreur : adora-cmp.js ou adora-cmp.css manquants à la racine du repo."
    echo "   Télécharge-les d'abord et place-les ici avant de lancer ce script."
    exit 1
fi

# ─── Préparer la structure /assets ───────────────────────────────────────
mkdir -p assets/js assets/css

# ─── Liste des pages HTML à patcher ──────────────────────────────────────
HTML_PAGES=$(find . -maxdepth 1 -name "*.html" -type f -not -path "*/email-templates/*" | sort)

echo "🔍 Pages détectées :"
echo "$HTML_PAGES" | sed 's|^./|  |'
NB_PAGES=$(echo "$HTML_PAGES" | wc -l | tr -d ' ')
echo ""
echo "📊 Total : $NB_PAGES page(s) HTML"
echo ""
echo "Actions prévues :"
echo "  1. Copier adora-cmp.js → assets/js/"
echo "  2. Copier adora-cmp.css → assets/css/"
echo "  3. Sur chaque page :"
echo "     • Insérer <link> CSS et <script> JS en <head>"
echo "     • Différer GA4 (type=\"text/plain\" data-adora-consent=\"analytics\")"
echo "     • Ajouter bouton 'Gérer mes cookies' dans le footer"
echo ""
echo "Continuer ? (yes/NO)"
read -r confirm
if [ "$confirm" != "yes" ]; then
    echo "Abandon."
    exit 0
fi

# ─── Étape 1+2 : copier les assets ───────────────────────────────────────
echo ""
echo "🔧 Copie des assets..."
cp adora-cmp.js assets/js/adora-cmp.js
cp adora-cmp.css assets/css/adora-cmp.css
echo "  ✓ assets/js/adora-cmp.js"
echo "  ✓ assets/css/adora-cmp.css"

# ─── Étape 3 : patcher chaque HTML ───────────────────────────────────────
echo ""
echo "🔧 Patch des pages HTML..."

# Variables d'environnement pour perl (évite bug @gmail / @type)
export CMP_HEAD='<!-- ADORA CMP -->
  <link rel="stylesheet" href="/assets/css/adora-cmp.css">
  <script src="/assets/js/adora-cmp.js"></script>
  <!-- /ADORA CMP -->'

export FOOTER_LINK='<button type="button" class="adora-cmp-footer-link" onclick="window.adoraConsent &amp;&amp; window.adoraConsent.show()">🍪 Gérer mes cookies</button>'

for file in $HTML_PAGES; do
    file_short=$(basename "$file")
    echo ""
    echo "── $file_short"

    # ─── 3a. Insérer CMP head si pas déjà là ────────────────────────
    if ! grep -q "ADORA CMP" "$file"; then
        # Insertion juste avant </head> via perl multi-line
        perl -i -0777 -pe 's|</head>|$ENV{CMP_HEAD}\n</head>|' "$file"
        echo "  ✓ <head> patché (CSS + JS CMP)"
    else
        echo "  → <head> déjà patché, skip"
    fi

    # ─── 3b. Différer GA4 (gtag inline) ─────────────────────────────
    # Pattern : <script async src="...gtag/js?id=G-...">  +  <script>...gtag('config'...)</script>
    # On les transforme en type="text/plain" data-adora-consent="analytics"

    if grep -q 'googletagmanager.com/gtag/js' "$file" && ! grep -q 'data-adora-consent="analytics"' "$file"; then
        # Transformer la balise async <script async src="...gtag/js?id=...">
        perl -i -pe 's|<script\s+async\s+src="(https://www\.googletagmanager\.com/gtag/js[^"]*)"\s*></script>|<script type="text/plain" data-adora-consent="analytics" src="$1"></script>|g' "$file"

        # Transformer le bloc inline gtag('config', 'G-...')
        # Pattern simple et robuste : tout <script> qui contient "gtag('config'"
        perl -i -0777 -pe 's|<script>([^<]*?gtag\(.config.[^<]*?)</script>|<script type="text/plain" data-adora-consent="analytics">$1</script>|gs' "$file"

        echo "  ✓ GA4 différé"
    elif grep -q 'data-adora-consent="analytics"' "$file"; then
        echo "  → GA4 déjà différé, skip"
    else
        echo "  → pas de GA4 trouvé sur cette page"
    fi

    # ─── 3c. Différer Sentry si présent ─────────────────────────────
    # Sentry est typiquement chargé via <script src="...browser.sentry-cdn.com/.../bundle.min.js"
    if grep -q 'sentry-cdn.com' "$file" && ! grep -B1 'sentry-cdn' "$file" | grep -q 'data-adora-consent'; then
        perl -i -pe 's|<script\s+src="(https://[^"]*sentry-cdn\.com[^"]*)"|<script type="text/plain" data-adora-consent="analytics" src="$1"|g' "$file"
        # Différer aussi le Sentry.init() inline
        perl -i -0777 -pe 's|<script>\s*(Sentry\.init\(.*?\);?\s*)</script>|<script type="text/plain" data-adora-consent="analytics">$1</script>|gs' "$file"
        echo "  ✓ Sentry différé"
    elif grep -q 'sentry-cdn.com' "$file"; then
        echo "  → Sentry déjà différé ou absent, skip"
    fi

    # ─── 3d. Ajouter le bouton "Gérer mes cookies" dans le footer ──
    if ! grep -q "adora-cmp-footer-link" "$file"; then
        # On cherche le footer et on ajoute le bouton avant </footer>
        # Pattern flexible : juste avant </footer>
        if grep -q '</footer>' "$file"; then
            perl -i -0777 -pe 's|</footer>|<div style="margin-top:12px;font-size:13px;opacity:0.8"><button type="button" class="adora-cmp-footer-link" onclick="if(window.adoraConsent)window.adoraConsent.show()">🍪 Gérer mes cookies</button></div>\n</footer>|' "$file"
            echo "  ✓ Bouton 'Gérer mes cookies' ajouté"
        else
            echo "  ⚠️  pas de </footer>, bouton non ajouté"
        fi
    else
        echo "  → bouton footer déjà présent, skip"
    fi
done

# ─── Vérification ────────────────────────────────────────────────────────
echo ""
echo "🔍 Vérification globale :"
NB_HEAD=$(grep -l "ADORA CMP" $HTML_PAGES 2>/dev/null | wc -l | tr -d ' ')
NB_GA4_DEFERRED=$(grep -l 'data-adora-consent="analytics"' $HTML_PAGES 2>/dev/null | wc -l | tr -d ' ')
NB_FOOTER=$(grep -l "adora-cmp-footer-link" $HTML_PAGES 2>/dev/null | wc -l | tr -d ' ')

echo "  CMP head injecté        : $NB_HEAD / $NB_PAGES"
echo "  GA4/Sentry différés     : $NB_GA4_DEFERRED pages"
echo "  Bouton footer ajouté    : $NB_FOOTER / $NB_PAGES"

# ─── Git status ──────────────────────────────────────────────────────────
echo ""
echo "📋 git status :"
echo "─────────────────────────────────────────"
git status --short
echo "─────────────────────────────────────────"
echo ""
echo "✅ Patch CMP terminé."
echo ""
echo "🚀 Étapes suivantes :"
echo "   1. Vérifier le diff dans GitHub Desktop"
echo "   2. TEST EN LOCAL avant push :"
echo "      open index.html  (ouverture dans Chrome)"
echo "      → Tu dois voir la carte CMP en bas à gauche après ~800ms"
echo "      → Cmd+Shift+I → Network → Refresh : GA4 ne doit PAS charger"
echo "      → Click 'Tout accepter' → GA4 doit charger maintenant"
echo "      → Click 'Gérer mes cookies' (footer) → carte se ré-ouvre"
echo "   3. Commit : 'ADORA: CMP custom Indigo Aurora — RGPD CNIL conforme'"
echo "   4. Push vers main"
echo "   5. Purger cache Cloudflare"
echo "   6. Test prod : https://adora-economie.fr en navigation privée"
echo ""
echo "💡 Reset consent en console pour re-tester :"
echo "   window.adoraConsent.reset(); location.reload();"
echo ""
echo "⚠️  Reste à mettre à jour /politique-confidentialite.html (livré séparément)"
echo ""
