#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ADORA_Site_Patch_Privacy_CMP_v1_20260428.sh
# ═══════════════════════════════════════════════════════════════════════════
# Met à jour /politique-confidentialite.html avec :
#   • Mention du CMP custom ADORA
#   • Tableau exhaustif des cookies par catégorie
#   • Durée de conservation (13 mois CNIL)
#   • Lien vers le bouton "Gérer mes cookies"
#
# Ce script remplace une zone marqueur dans la page existante OU insère
# le bloc avant la section "Droits des utilisateurs" si déjà présente.
#
# Auteur : ADORA — Aymeric Dussauze
# Date : 28/04/2026
# ═══════════════════════════════════════════════════════════════════════════

set -e

FILE="politique-confidentialite.html"

if [ ! -f "$FILE" ]; then
    echo "❌ Fichier $FILE absent. Lance ce script depuis la racine du repo adora."
    exit 1
fi

if grep -q 'data-adora-cookies-block="v1"' "$FILE"; then
    echo "→ Section cookies CMP déjà présente. Utilise grep pour vérifier le contenu."
    grep -A 3 'data-adora-cookies-block' "$FILE" | head -10
    echo ""
    echo "Pour ré-injecter, supprime d'abord le bloc existant manuellement."
    exit 0
fi

# ─── Bloc HTML à insérer ─────────────────────────────────────────────────
read -r -d '' COOKIES_BLOCK << 'EOF' || true

<!-- ADORA CMP — bloc cookies (v1, 28/04/2026) -->
<section data-adora-cookies-block="v1">
  <h2>Cookies et traceurs</h2>

  <p>
    Le site adora-economie.fr utilise des cookies pour assurer son fonctionnement
    et, avec votre accord explicite, mesurer son audience. Vos préférences sont
    enregistrées pour une durée maximale de <strong>13 mois</strong>, conformément
    aux recommandations de la CNIL.
  </p>

  <p>
    La collecte du consentement est gérée par un outil développé en interne par ADORA,
    qui s'exécute uniquement dans votre navigateur (aucune donnée transmise à un tiers
    pour cette finalité).
  </p>

  <h3>1. Cookies strictement nécessaires <em>(toujours actifs)</em></h3>

  <p>Ces cookies sont indispensables au fonctionnement du site. Aucun consentement
    n'est requis (article 82 de la loi Informatique et Libertés).</p>

  <ul>
    <li><strong>Cloudflare</strong> — protection contre les attaques, mise en cache
      (cookies <code>__cf_bm</code>, <code>cf_clearance</code>, durée 30 minutes à 1 an
      selon la fonction).</li>
    <li><strong>Formspree</strong> — protection anti-bot des formulaires de contact
      (cookie session, supprimé à la fermeture du navigateur).</li>
    <li><strong>ADORA CMP</strong> — mémorisation de vos préférences cookies
      (clé <code>adora_consent_v1</code> en localStorage, durée 13 mois).</li>
  </ul>

  <h3>2. Cookies de mesure d'audience <em>(opt-in requis)</em></h3>

  <p>Ces cookies sont déposés <strong>uniquement après consentement explicite</strong>
    via le bandeau de gestion des cookies. Vous pouvez les refuser sans incidence sur
    votre navigation.</p>

  <ul>
    <li><strong>Google Analytics 4</strong> (identifiant <code>G-M0LENY960B</code>)
      — comprendre l'usage du site et ses pages les plus consultées.
      Cookies <code>_ga</code>, <code>_ga_*</code> (durée 13 mois maximum).
      Conservation des données par Google : 14 mois maximum.
      Anonymisation IP activée. Consent Mode v2 activé.
    </li>
    <li><strong>Sentry</strong> — détection des erreurs JavaScript pour corriger
      les bugs. Aucun cookie persistant — données limitées à la trace technique
      de l'erreur (URL, message, navigateur). Service hébergé par Functional
      Software Inc. (USA), encadré par les Clauses Contractuelles Types.
    </li>
  </ul>

  <p>
    <strong>Cloudflare Web Analytics</strong> est également utilisé pour les
    statistiques agrégées du site. Cet outil est <em>cookieless</em> et anonyme :
    aucun consentement n'est requis (avis CNIL du 27 juillet 2020).
  </p>

  <h3>3. Aucune publicité ni profilage</h3>

  <p>
    ADORA n'utilise <strong>aucun cookie publicitaire</strong>, aucun outil de
    profilage marketing, aucun pixel de réseau social, aucun retargeting.
    Vos données ne sont jamais transmises à des partenaires commerciaux.
  </p>

  <h3>4. Modifier ou retirer votre consentement</h3>

  <p>
    Vous pouvez à tout moment modifier vos préférences en cliquant sur le bouton
    <button type="button" class="adora-cmp-footer-link" onclick="window.adoraConsent &amp;&amp; window.adoraConsent.show()" style="display:inline">🍪 Gérer mes cookies</button>
    présent en bas de chaque page.
  </p>

  <p>
    Vous pouvez également configurer votre navigateur pour bloquer ou supprimer
    les cookies déjà déposés :
    <a href="https://support.google.com/chrome/answer/95647" rel="noopener" target="_blank">Chrome</a>,
    <a href="https://support.mozilla.org/fr/kb/protection-renforcee-contre-pistage-firefox-ordinateur" rel="noopener" target="_blank">Firefox</a>,
    <a href="https://support.apple.com/fr-fr/guide/safari/sfri11471/mac" rel="noopener" target="_blank">Safari</a>,
    <a href="https://support.microsoft.com/fr-fr/microsoft-edge/supprimer-les-cookies-dans-microsoft-edge-63947406-40ac-c3b8-57b9-2a946a29ae09" rel="noopener" target="_blank">Edge</a>.
  </p>
</section>
<!-- /ADORA CMP — bloc cookies -->

EOF

# ─── Insertion ───────────────────────────────────────────────────────────
# Stratégie : insérer juste avant la section "Droits des utilisateurs" si elle
# existe, sinon avant </main> ou avant </body>
echo "🔧 Patch de $FILE..."

export COOKIES_BLOCK_VAR="$COOKIES_BLOCK"

# Cas 1 : on trouve un h2 "Droits des utilisateurs" → insertion juste avant
if grep -qiE '<h2[^>]*>.*droits.*utilisateur' "$FILE"; then
    perl -i -0777 -pe 's|(<h2[^>]*>\s*[0-9]*[\.\s]*Droits\s+des\s+utilisateurs)|$ENV{COOKIES_BLOCK_VAR}\n$1|i' "$FILE"
    echo "  ✓ Bloc inséré avant section 'Droits des utilisateurs'"
# Cas 2 : on trouve "Cookies" en h2 → on remplace toute la section par notre bloc
elif grep -qiE '<h2[^>]*>.*cookies' "$FILE"; then
    # Supprimer ancien bloc cookies existant (h2 Cookies → fin de la section)
    # Puis insérer le nouveau juste avant le h2 suivant ou avant </main>
    echo "  ⚠️  Section 'Cookies' déjà présente — insertion en complément (à nettoyer manuellement après vérif)"
    perl -i -0777 -pe 's|</main>|$ENV{COOKIES_BLOCK_VAR}\n</main>|' "$FILE" || \
    perl -i -0777 -pe 's|</body>|$ENV{COOKIES_BLOCK_VAR}\n</body>|' "$FILE"
    echo "  ✓ Bloc inséré avant </main>"
# Cas 3 : sinon avant </main>
elif grep -q '</main>' "$FILE"; then
    perl -i -0777 -pe 's|</main>|$ENV{COOKIES_BLOCK_VAR}\n</main>|' "$FILE"
    echo "  ✓ Bloc inséré avant </main>"
else
    perl -i -0777 -pe 's|</body>|$ENV{COOKIES_BLOCK_VAR}\n</body>|' "$FILE"
    echo "  ✓ Bloc inséré avant </body>"
fi

echo ""
echo "📋 Vérification :"
if grep -q 'data-adora-cookies-block="v1"' "$FILE"; then
    echo "  ✓ Marqueur trouvé"
    NB_LINES=$(grep -c "" "$FILE")
    echo "  ✓ Fichier : $NB_LINES lignes"
else
    echo "  ❌ Marqueur introuvable, l'insertion a échoué"
    exit 1
fi

echo ""
echo "🚀 Étapes suivantes :"
echo "   1. Ouvrir politique-confidentialite.html dans Chrome pour vérifier le rendu"
echo "   2. SI une ancienne section 'Cookies' (h2) existait, la supprimer manuellement"
echo "      → grep -n '<h2.*[Cc]ookies' politique-confidentialite.html"
echo "   3. Commit + push avec le reste du pack CMP"
echo ""
