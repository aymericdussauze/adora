#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ADORA_Site_Patch_Schema_JSONLD_v1_20260428.sh
# ═══════════════════════════════════════════════════════════════════════════
# Pack SEO schema JSON-LD complet :
#   1. Remplace LocalBusiness par ProfessionalService sur index.html
#   2. Insère Service+Offer 499€ sur audit-avant-achat.html
#   3. Insère Service+Offer 990€ sur sur-mesure.html
#   4. Insère Service B2B sur professionnels.html
#   5. Insère WebApplication sur estimateur-outil.html
#   6. Insère WebApplication sur simulateur.html
#   7. Insère Blog sur blog.html
#   8. Ajoute champ "image" dans Article schema sur 7 articles
#
# Source : page Notion "Patch SEO complet adora-economie.fr"
# Décisions actées 28/04/2026 :
#   • email = contact@adora-economie.fr (déjà patché)
#   • posture AI bots = hybride (cf. robots.txt fourni séparément)
#
# IMPORTANT : ce script attend que les images OG par article existent
# dans /img/articles/ — sinon Google ignorera silencieusement le champ image.
# Si tu n'as pas encore les images, lance quand même : tu pourras créer
# les visuels après et tout sera prêt.
#
# Idempotent : ré-exécutable sans risque (utilise marqueur unique
# data-adora-schema="..." pour détecter présence existante).
#
# Auteur : ADORA — Aymeric Dussauze
# Date : 28/04/2026
# ═══════════════════════════════════════════════════════════════════════════

set -e

# ─── Vérifier on est dans un repo git ────────────────────────────────────
if [ ! -d ".git" ]; then
    echo "❌ Erreur : ce script doit être lancé à la racine d'un repo git."
    echo "   Fais d'abord : cd ~/Documents/GitHub/adora"
    exit 1
fi

REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
echo "📁 Repo : $REPO_NAME"
echo ""

# ─── Vérifier les fichiers cibles ────────────────────────────────────────
REQUIRED_FILES=(
    "index.html"
    "audit-avant-achat.html"
    "sur-mesure.html"
    "professionnels.html"
    "estimateur-outil.html"
    "simulateur.html"
    "blog.html"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Fichier manquant : $file"
        exit 1
    fi
done

ARTICLE_FILES=(
    "prix-renovation-m2-2026.html"
    "audit-avant-achat-immobilier.html"
    "maprimerenov-2026-bareme.html"
    "pieges-devis-artisans.html"
    "15-lots-tce-expliques-particulier.html"
    "choisir-sa-gamme-renovation.html"
    "diagnostic-parasitaire-negociation.html"
)

for file in "${ARTICLE_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  Article manquant (sera ignoré) : $file"
    fi
done

echo "🔍 Aperçu du patch :"
echo ""
echo "   1. index.html : LocalBusiness → ProfessionalService"
echo "   2. audit-avant-achat.html : + Service/Offer 499€"
echo "   3. sur-mesure.html : + Service/Offer 990€"
echo "   4. professionnels.html : + Service B2B"
echo "   5. estimateur-outil.html : + WebApplication"
echo "   6. simulateur.html : + WebApplication"
echo "   7. blog.html : + Blog"
echo "   8. 7 articles : + champ 'image' dans Article schema"
echo ""
echo "Continuer ? (yes/NO)"
read -r confirm
if [ "$confirm" != "yes" ]; then
    echo "Abandon."
    exit 0
fi

# ─── Helper : insérer un bloc schema avant </head> si pas déjà présent ──
insert_schema() {
    local file=$1
    local marker=$2
    local schema=$3

    if grep -q "data-adora-schema=\"$marker\"" "$file"; then
        echo "  → $file : déjà patché ($marker), skip"
        return
    fi

    # Insertion via perl avec ENV pour éviter problèmes de quoting
    export SCHEMA_BLOCK="$schema"
    perl -i -pe 'BEGIN{undef $/;} s|</head>|$ENV{SCHEMA_BLOCK}\n</head>|' "$file"
    echo "  ✓ $file ($marker)"
}

echo ""
echo "🔧 Application des schemas..."
echo ""

# ─── 1. INDEX.HTML : remplacer LocalBusiness par ProfessionalService ─────
echo "── [1/8] index.html : LocalBusiness → ProfessionalService"
HOME_SCHEMA='<script type="application/ld+json" data-adora-schema="professional-service">
{
  "@context": "https://schema.org",
  "@type": "ProfessionalService",
  "@id": "https://adora-economie.fr/#business",
  "name": "ADORA — Économiste de la construction",
  "alternateName": "ADORA",
  "description": "Cabinet indépendant d'\''économie de la construction. Estimations TCE, CCTP/DPGF, AMO pour particuliers et professionnels.",
  "url": "https://adora-economie.fr/",
  "logo": "https://adora-economie.fr/logo.svg",
  "image": "https://adora-economie.fr/og-default.jpg",
  "telephone": "+33672010767",
  "email": "contact@adora-economie.fr",
  "address": {
    "@type": "PostalAddress",
    "addressLocality": "Louviers",
    "postalCode": "27400",
    "addressRegion": "Normandie",
    "addressCountry": "FR"
  },
  "areaServed": [
    { "@type": "AdministrativeArea", "name": "Eure (27)" },
    { "@type": "AdministrativeArea", "name": "Seine-Maritime (76)" },
    { "@type": "AdministrativeArea", "name": "Île-de-France" }
  ],
  "founder": {
    "@type": "Person",
    "@id": "https://adora-economie.fr/a-propos.html#aymeric",
    "name": "Aymeric Dussauze",
    "jobTitle": "Économiste de la construction",
    "sameAs": "https://www.linkedin.com/in/aymericdussauze/"
  },
  "sameAs": [
    "https://www.linkedin.com/in/aymericdussauze/"
  ],
  "knowsAbout": [
    "économie de la construction",
    "estimation tous corps d'\''état",
    "CCTP",
    "DPGF",
    "MaPrimeRénov'\''",
    "audit avant achat immobilier",
    "AMO"
  ]
}
</script>'

# Suppression de l'ancien LocalBusiness (idempotent : si déjà fait, perl ne match rien)
# On cible le bloc <script type="application/ld+json"> qui contient "LocalBusiness"
# et qui n'a pas notre marker data-adora-schema
if grep -q '"@type":\s*"LocalBusiness"' index.html && ! grep -q 'data-adora-schema="professional-service"' index.html; then
    perl -i -0777 -pe 's|<script[^>]*type="application/ld\+json"[^>]*>\s*\{[^<]*?"LocalBusiness"[^<]*?\}\s*</script>||s' index.html
    echo "  → ancien LocalBusiness supprimé"
fi

insert_schema "index.html" "professional-service" "$HOME_SCHEMA"

# ─── 2. AUDIT-AVANT-ACHAT.HTML : Service + Offer 499€ ────────────────────
echo "── [2/8] audit-avant-achat.html : Service + Offer 499€"
AUDIT_SCHEMA='<script type="application/ld+json" data-adora-schema="service-audit">
{
  "@context": "https://schema.org",
  "@type": "Service",
  "serviceType": "Audit avant achat immobilier",
  "name": "Audit avant achat immobilier par économiste de la construction",
  "description": "Analyse économiste indépendante avant signature d'\''un compromis. DDT, DPE, estimation des travaux nécessaires, identification des coûts cachés et arguments de négociation.",
  "provider": {
    "@type": "ProfessionalService",
    "@id": "https://adora-economie.fr/#business",
    "name": "ADORA",
    "url": "https://adora-economie.fr/"
  },
  "areaServed": [
    { "@type": "AdministrativeArea", "name": "Eure (27)" },
    { "@type": "AdministrativeArea", "name": "Seine-Maritime (76)" },
    { "@type": "AdministrativeArea", "name": "Île-de-France" }
  ],
  "audience": {
    "@type": "Audience",
    "audienceType": "Acquéreurs particuliers"
  },
  "offers": {
    "@type": "Offer",
    "name": "Audit avant achat",
    "price": "499",
    "priceCurrency": "EUR",
    "availability": "https://schema.org/InStock",
    "url": "https://adora-economie.fr/audit-avant-achat.html"
  }
}
</script>'
insert_schema "audit-avant-achat.html" "service-audit" "$AUDIT_SCHEMA"

# ─── 3. SUR-MESURE.HTML : Service + Offer 990€ ───────────────────────────
echo "── [3/8] sur-mesure.html : Service + Offer 990€"
SURMESURE_SCHEMA='<script type="application/ld+json" data-adora-schema="service-amo">
{
  "@context": "https://schema.org",
  "@type": "Service",
  "serviceType": "Accompagnement maîtrise d'\''ouvrage (AMO)",
  "name": "Accompagnement sur mesure d'\''un économiste de la construction",
  "description": "Estimation détaillée TCE, rédaction CCTP/DPGF, analyse des devis, suivi de chantier. Mission adaptée à chaque projet de rénovation ou construction.",
  "provider": {
    "@type": "ProfessionalService",
    "@id": "https://adora-economie.fr/#business",
    "name": "ADORA",
    "url": "https://adora-economie.fr/"
  },
  "areaServed": [
    { "@type": "AdministrativeArea", "name": "Eure (27)" },
    { "@type": "AdministrativeArea", "name": "Seine-Maritime (76)" },
    { "@type": "AdministrativeArea", "name": "Île-de-France" }
  ],
  "offers": {
    "@type": "Offer",
    "name": "Accompagnement sur mesure",
    "price": "990",
    "priceCurrency": "EUR",
    "priceSpecification": {
      "@type": "PriceSpecification",
      "price": "990",
      "priceCurrency": "EUR",
      "valueAddedTaxIncluded": false,
      "description": "À partir de 990 € HT, devis personnalisé selon périmètre"
    },
    "availability": "https://schema.org/InStock",
    "url": "https://adora-economie.fr/sur-mesure.html"
  }
}
</script>'
insert_schema "sur-mesure.html" "service-amo" "$SURMESURE_SCHEMA"

# ─── 4. PROFESSIONNELS.HTML : Service B2B ────────────────────────────────
echo "── [4/8] professionnels.html : Service B2B"
PRO_SCHEMA='<script type="application/ld+json" data-adora-schema="service-b2b">
{
  "@context": "https://schema.org",
  "@type": "Service",
  "serviceType": "Économiste de la construction en sous-traitance",
  "name": "Économiste de la construction en renfort d'\''équipe",
  "description": "Renfort économiste pour architectes, bureaux d'\''études et maîtres d'\''ouvrage : estimation TCE, DPGF, CCTP, AMO, suivi financier de chantier.",
  "provider": {
    "@type": "ProfessionalService",
    "@id": "https://adora-economie.fr/#business",
    "name": "ADORA",
    "url": "https://adora-economie.fr/"
  },
  "audience": {
    "@type": "BusinessAudience",
    "audienceType": "Architectes, bureaux d'\''études techniques, maîtres d'\''ouvrage"
  },
  "areaServed": "FR"
}
</script>'
insert_schema "professionnels.html" "service-b2b" "$PRO_SCHEMA"

# ─── 5. ESTIMATEUR-OUTIL.HTML : WebApplication ───────────────────────────
echo "── [5/8] estimateur-outil.html : WebApplication"
ESTIMATEUR_SCHEMA='<script type="application/ld+json" data-adora-schema="webapp-estimateur">
{
  "@context": "https://schema.org",
  "@type": "WebApplication",
  "name": "Estimateur de travaux ADORA",
  "url": "https://adora-economie.fr/estimateur-outil.html",
  "description": "Estimateur en ligne gratuit qui chiffre un projet de rénovation poste par poste (15 lots TCE) à partir de la surface, du niveau de gamme et de la zone géographique. Rapport PDF détaillé disponible pour 49 €.",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "browserRequirements": "Requires JavaScript",
  "inLanguage": "fr-FR",
  "isAccessibleForFree": true,
  "offers": {
    "@type": "Offer",
    "name": "Rapport PDF complet",
    "price": "49",
    "priceCurrency": "EUR"
  },
  "creator": {
    "@type": "ProfessionalService",
    "@id": "https://adora-economie.fr/#business",
    "name": "ADORA",
    "url": "https://adora-economie.fr/"
  }
}
</script>'
insert_schema "estimateur-outil.html" "webapp-estimateur" "$ESTIMATEUR_SCHEMA"

# ─── 6. SIMULATEUR.HTML : WebApplication ─────────────────────────────────
echo "── [6/8] simulateur.html : WebApplication"
SIMULATEUR_SCHEMA='<script type="application/ld+json" data-adora-schema="webapp-simulateur">
{
  "@context": "https://schema.org",
  "@type": "WebApplication",
  "name": "Simulateur d'\''aides à la rénovation énergétique",
  "url": "https://adora-economie.fr/simulateur.html",
  "description": "Simulateur en ligne gratuit qui calcule les aides à la rénovation énergétique : MaPrimeRénov'\'' 2026, CEE (Coup de pouce), éco-PTZ, TVA réduite 5,5 %. Selon revenu fiscal, type de logement et travaux envisagés.",
  "applicationCategory": "FinanceApplication",
  "operatingSystem": "Web",
  "browserRequirements": "Requires JavaScript",
  "inLanguage": "fr-FR",
  "isAccessibleForFree": true,
  "creator": {
    "@type": "ProfessionalService",
    "@id": "https://adora-economie.fr/#business",
    "name": "ADORA",
    "url": "https://adora-economie.fr/"
  }
}
</script>'
insert_schema "simulateur.html" "webapp-simulateur" "$SIMULATEUR_SCHEMA"

# ─── 7. BLOG.HTML : Blog ─────────────────────────────────────────────────
echo "── [7/8] blog.html : Blog"
BLOG_SCHEMA='<script type="application/ld+json" data-adora-schema="blog">
{
  "@context": "https://schema.org",
  "@type": "Blog",
  "name": "Blog ADORA — Rénovation, aides, chiffres",
  "url": "https://adora-economie.fr/blog.html",
  "description": "Articles et guides d'\''un économiste de la construction sur la rénovation, les aides MaPrimeRénov'\'' 2026, les pièges des devis d'\''artisans et la maîtrise des coûts.",
  "author": {
    "@type": "Person",
    "@id": "https://adora-economie.fr/a-propos.html#aymeric",
    "name": "Aymeric Dussauze",
    "url": "https://adora-economie.fr/a-propos.html"
  },
  "publisher": {
    "@type": "ProfessionalService",
    "@id": "https://adora-economie.fr/#business",
    "name": "ADORA",
    "url": "https://adora-economie.fr/"
  },
  "inLanguage": "fr-FR"
}
</script>'
insert_schema "blog.html" "blog" "$BLOG_SCHEMA"

# ─── 8. ARTICLES : ajout du champ "image" dans Article schema ───────────
echo "── [8/8] Ajout champ image dans 7 articles"
echo ""
for article in "${ARTICLE_FILES[@]}"; do
    if [ ! -f "$article" ]; then
        continue
    fi

    # Slug = nom fichier sans .html
    slug="${article%.html}"
    image_url="https://adora-economie.fr/img/articles/${slug}.jpg"

    # Vérifier que le schema Article existe et n'a pas déjà "image"
    if ! grep -q '"@type":\s*"Article"' "$article"; then
        echo "  → $article : pas de schema Article, skip"
        continue
    fi

    if grep -q 'data-adora-image-added="true"' "$article"; then
        echo "  → $article : déjà patché, skip"
        continue
    fi

    # Insérer le champ image juste après "@type": "Article"
    # Pattern : trouve "@type": "Article", et ajoute la ligne "image" derrière
    # IMPORTANT : \@ pour échapper le @ qui sinon est interprété par perl
    # comme array variable (même bug que sur substitution email)
    export IMAGE_URL="$image_url"
    perl -i -0777 -pe 's|("\@type":\s*"Article",)|$1\n  "image": {\n    "\@type": "ImageObject",\n    "url": "$ENV{IMAGE_URL}",\n    "width": 1200,\n    "height": 630\n  },|s' "$article"

    # Marquer le fichier comme patché (commentaire HTML invisible)
    perl -i -pe 's|</head>|<!-- data-adora-image-added="true" -->\n</head>|' "$article"

    echo "  ✓ $article (image: $image_url)"
done

# ─── Vérification finale ─────────────────────────────────────────────────
echo ""
echo "🔍 Vérification finale :"
echo ""
echo "Schemas data-adora-schema détectés :"
grep -rh 'data-adora-schema' --include="*.html" . | grep -oE 'data-adora-schema="[^"]+"' | sort | uniq -c
echo ""

# ─── Git status ──────────────────────────────────────────────────────────
echo "📋 git status :"
echo "─────────────────────────────────────────"
git status --short
echo "─────────────────────────────────────────"
echo ""
echo "✅ Patch terminé."
echo ""
echo "🚀 Étapes suivantes :"
echo "   1. Validation Schema avant push :"
echo "      → https://search.google.com/test/rich-results"
echo "      → coller le HTML d'index.html, audit-avant-achat.html, sur-mesure.html"
echo "   2. GitHub Desktop → vérifier le diff"
echo "   3. Commit : 'ADORA: pack schema JSON-LD complet (7 pages + 7 articles)'"
echo "   4. Push vers main"
echo "   5. Purger cache Cloudflare"
echo "   6. Relancer Search Console : Inspect URL → Request Indexing sur les 8 pages"
echo ""
echo "⚠️  RAPPEL : les images d'articles /img/articles/<slug>.jpg doivent être"
echo "   créées (1200×630) sinon Google ignorera le champ image silencieusement."
echo ""
