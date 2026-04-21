#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ADORA — Injection Sentry + Cloudflare Web Analytics
# Compatible macOS (BSD sed)
# Usage : ./inject-monitoring.sh [répertoire]
#
# AVANT D'EXÉCUTER : remplacer les 2 valeurs ci-dessous
# ═══════════════════════════════════════════════════════════

# ⚠️ REMPLACER PAR TES VALEURS (voir guide setup)
SENTRY_DSN="https://14b68c10a24c3da4127332e14fd20359@o4511253060976640.ingest.de.sentry.io/4511253075132496"
CF_BEACON="<!-- Cloudflare Web Analytics --><script defer src='https://static.cloudflareinsights.com/beacon.min.js' data-cf-beacon='{"token": "3f8ca9a1113f413a990a17c08ab83442"}'></script><!-- End Cloudflare Web Analytics -->"

# ═══════════════════════════════════════════════════════════

DIR="${1:-.}"
COUNT=0
SKIP=0

if [ "$SENTRY_DSN" = 'https://XXXXXX@o0000.ingest.sentry.io/0000000' ]; then
  echo ""
  echo "   ERREUR : tu dois d'abord remplacer SENTRY_DSN et CF_BEACON"
  echo "   dans ce script avant de l'executer."
  echo "   Ouvre inject-monitoring.sh dans un editeur et modifie les 2 valeurs."
  echo ""
  exit 1
fi

echo ""
echo "   ADORA — Injection Sentry + Cloudflare Web Analytics"
echo "   Repertoire : $DIR"
echo "   -----------------------------------------"

# Snippet Sentry (avant </head>)
SENTRY_SNIPPET='<script src="https://browser.sentry-cdn.com/8.0.0/bundle.tracing.min.js" crossorigin="anonymous"><\/script>\
    <script>Sentry.init({dsn:"'"$SENTRY_DSN"'",tracesSampleRate:0,replaysSessionSampleRate:0});<\/script>'

# Snippet Cloudflare Web Analytics (avant </body>)
CF_SNIPPET='<script defer src="https:\/\/static.cloudflareinsights.com\/beacon.min.js" data-cf-beacon='\''{"token":"'"$CF_BEACON"'"}'\''><\/script>'

for file in "$DIR"/*.html; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")

  # Vérifier si déjà injecté
  if grep -q 'sentry-cdn.com' "$file"; then
    echo "   skip $filename (deja present)"
    SKIP=$((SKIP + 1))
    continue
  fi

  # Injecter Sentry avant </head>
  sed -i '' '/<\/head>/i\
    '"$SENTRY_SNIPPET"'
' "$file"

  # Injecter CF Web Analytics avant </body>
  sed -i '' '/<\/body>/i\
    '"$CF_SNIPPET"'
' "$file"

  if grep -q 'sentry-cdn.com' "$file" && grep -q 'cloudflareinsights' "$file"; then
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
