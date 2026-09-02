#!/bin/bash
# ============================================================================
# ADORA — Patch dates schema Article (format ISO 8601 complet)
# Fichier : ADORA_Site_Patch_Dates_Schema_v2_20260902.sh
# Cible   : repo prod "adora" — 7 articles de blog
# Objet   : "2026-04-19" -> "2026-04-19T09:00:00+02:00"
#           sur datePublished et dateModified des schemas Article.
#           Corrige les alertes Rich Results Test :
#             - Invalid datetime value
#             - Datetime property is missing a timezone
# Usage   : cd ~/chemin/vers/adora && chmod +x ADORA_..._20260902.sh && ./ADORA_..._20260902.sh
# ============================================================================

set -u

HEURE="T09:00:00+02:00"

ARTICLES=(
  "prix-renovation-m2-2026.html"
  "maprimerenov-2026-bareme.html"
  "audit-avant-achat-immobilier.html"
  "pieges-devis-artisans.html"
  "15-lots-tce-expliques-particulier.html"
  "diagnostic-parasitaire-negociation.html"
  "choisir-sa-gamme-renovation.html"
)

echo ""
echo "=========================================================="
echo " ADORA — Patch dates schema Article"
echo "=========================================================="
echo ""

# ---------- Garde-fou 1 : bon repo ----------
DOSSIER=$(basename "$PWD")
if [ "$DOSSIER" != "adora" ]; then
  echo "ARRET : le dossier courant s'appelle '$DOSSIER', or ce patch cible le repo 'adora'."
  echo "        Place-toi a la racine du repo prod puis relance."
  exit 1
fi

if [ ! -f "index.html" ] || [ ! -f "sitemap.xml" ]; then
  echo "ARRET : index.html ou sitemap.xml introuvable a la racine."
  echo "        Tu n'es probablement pas a la racine du repo."
  exit 1
fi
echo "[OK] Repo 'adora' confirme : $PWD"
echo ""

# ---------- Garde-fou 2 : fichiers presents ----------
MANQUANTS=0
for f in "${ARTICLES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "  MANQUANT : $f"
    MANQUANTS=$((MANQUANTS + 1))
  fi
done
if [ "$MANQUANTS" -gt 0 ]; then
  echo ""
  echo "ARRET : $MANQUANTS fichier(s) introuvable(s)."
  exit 1
fi
echo "[OK] Les 7 articles sont presents"
echo ""

# ---------- Dry-run : etat AVANT ----------
echo "----------------------------------------------------------"
echo " AVANT — dates detectees"
echo "----------------------------------------------------------"
TOTAL_AVANT=0
for f in "${ARTICLES[@]}"; do
  N=$(grep -c -E '"date(Published|Modified)": *"[0-9]{4}-[0-9]{2}-[0-9]{2}"' "$f" || true)
  TOTAL_AVANT=$((TOTAL_AVANT + N))
  printf "  %-42s %s champ(s) au format court\n" "$f" "$N"
  grep -o -E '"date(Published|Modified)": *"[0-9]{4}-[0-9]{2}-[0-9]{2}"' "$f" | sed 's/^/      /'
done
echo ""
echo "  Total a corriger : $TOTAL_AVANT champ(s)"
echo ""

if [ "$TOTAL_AVANT" -eq 0 ]; then
  echo "Rien a faire : toutes les dates sont deja au format complet."
  exit 0
fi

echo "  Transformation : \"2026-04-19\"  ->  \"2026-04-19${HEURE}\""
echo ""

# ---------- Confirmation ----------
printf "Appliquer le patch ? (oui/non) : "
read -r REPONSE
if [ "$REPONSE" != "oui" ]; then
  echo "Annule. Aucun fichier modifie."
  exit 0
fi
echo ""

# ---------- Sauvegarde ----------
BACKUP="_backup_dates_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP"
for f in "${ARTICLES[@]}"; do
  cp "$f" "$BACKUP/$f"
done
echo "[OK] Sauvegarde dans ./$BACKUP/"
echo ""

# ---------- Patch ----------
export HEURE
for f in "${ARTICLES[@]}"; do
  perl -0777 -pi -e '
    s/("date(?:Published|Modified)":\s*")(\d{4}-\d{2}-\d{2})(")/$1$2$ENV{HEURE}$3/g
  ' "$f"
  echo "  patche : $f"
done
echo ""

# ---------- Verification APRES ----------
echo "----------------------------------------------------------"
echo " APRES — verification"
echo "----------------------------------------------------------"
RESTE=0
COMPLETES=0
for f in "${ARTICLES[@]}"; do
  R=$(grep -c -E '"date(Published|Modified)": *"[0-9]{4}-[0-9]{2}-[0-9]{2}"' "$f" || true)
  C=$(grep -c -E '"date(Published|Modified)": *"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+02:00"' "$f" || true)
  RESTE=$((RESTE + R))
  COMPLETES=$((COMPLETES + C))
  printf "  %-42s %s complete(s), %s restante(s)\n" "$f" "$C" "$R"
done
echo ""

# ---------- Validation JSON-LD ----------
echo "----------------------------------------------------------"
echo " Validation JSON-LD"
echo "----------------------------------------------------------"
python3 - "${ARTICLES[@]}" <<'PYEOF'
import json, re, sys
ko = 0
for f in sys.argv[1:]:
    s = open(f, encoding='utf-8').read()
    blocs = re.findall(r'<script type="application/ld\+json"[^>]*>(.*?)</script>', s, re.S)
    for i, b in enumerate(blocs, 1):
        try:
            json.loads(b)
        except Exception as e:
            ko += 1
            print("  JSON INVALIDE : %s bloc %d — %s" % (f, i, e))
    print("  %-42s %d bloc(s) JSON-LD valide(s)" % (f, len(blocs)))
sys.exit(1 if ko else 0)
PYEOF
VALID=$?
echo ""

echo "=========================================================="
if [ "$RESTE" -eq 0 ] && [ "$COMPLETES" -eq "$TOTAL_AVANT" ] && [ "$VALID" -eq 0 ]; then
  echo " RESULTAT : OK — $COMPLETES champ(s) corriges, JSON-LD valide"
  echo ""
  echo " Suite :"
  echo "  1. GitHub Desktop -> onglet Changes : 7 fichiers modifies"
  echo "  2. Supprimer le dossier $BACKUP AVANT de commiter"
  echo "     (il ne doit pas partir dans le repo)"
  echo "  3. Commit : 'Schema Article — dates ISO 8601 completes (7 articles)'"
  echo "  4. Push origin, puis purge Cloudflare sur les 7 URL"
  echo "  5. Verifier 1 article au Rich Results Test"
else
  echo " RESULTAT : ANOMALIE — verifie manuellement"
  echo "  attendus : $TOTAL_AVANT completes / 0 restantes / JSON valide"
  echo "  obtenus  : $COMPLETES completes / $RESTE restantes / code JSON $VALID"
  echo ""
  echo " Restauration : cp $BACKUP/*.html ."
fi
echo "=========================================================="
echo ""
