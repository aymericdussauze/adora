# ADORA — Pack auto-hébergement Google Fonts (26/04/2026)

## Contenu

```
assets/fonts/
├── adora-fonts.css                       (CSS @font-face local)
├── PlusJakartaSans-{400,500,600,700}-{latin,latin-ext}.woff2  (8 fichiers)
└── Montserrat-{700,800,900}-{latin,latin-ext}.woff2           (6 fichiers)

_scripts/
├── inject-fonts.sh                       (patche les 22 HTML)
└── remove-fonts.sh                       (rollback)
```

## Installation (5 min)

1. **Décompresser** ce pack dans le repo `aymericdussauze/adora` (à la racine)
2. **Vérifier** que les chemins sont corrects :
   - `assets/fonts/*.woff2` (15 fichiers)
   - `_scripts/inject-fonts.sh`
3. **Lancer le script** depuis la racine du repo :
   ```bash
   cd ~/Documents/GitHub/adora
   bash _scripts/inject-fonts.sh
   ```
4. **Vérifier** le bilan affiché (doit afficher "Patchés : 22")
5. **Tester en local** : ouvrir `index.html` dans le navigateur, les fonts doivent rester identiques visuellement
6. **Commit + push** via GitHub Desktop :
   - Message : `Auto-hébergement Google Fonts (RGPD + perf)`
   - ⚠️ Ne PAS commit les fichiers `.html.bak.fonts` (backups)

## Mise à jour CSP Cloudflare (à faire APRÈS le push)

Dans Cloudflare → Rules → `ADORA Sec-6 CSP-ReportOnly` → Edit :

**Retirer** :
- `https://fonts.googleapis.com` (de `style-src`)
- `https://fonts.gstatic.com` (de `font-src`)

Le nouveau CSP devient :
```
default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://browser.sentry-cdn.com https://static.cloudflareinsights.com https://*.ingest.de.sentry.io https://js.stripe.com https://buy.stripe.com; style-src 'self' 'unsafe-inline'; font-src 'self' data:; img-src 'self' data: https:; connect-src 'self' https://*.ingest.de.sentry.io https://www.google-analytics.com https://analytics.google.com https://*.stripe.com https://formspree.io; frame-src https://js.stripe.com https://hooks.stripe.com https://buy.stripe.com; frame-ancestors 'self'; base-uri 'self'; form-action 'self' https://formspree.io; upgrade-insecure-requests
```

## Rollback

Si quelque chose a mal tourné :
```bash
bash _scripts/remove-fonts.sh
```

## Vérification post-déploiement

Une fois en prod :
1. Ouvrir https://adora-economie.fr dans Chrome
2. F12 → Network tab → recharger la page
3. Filtrer par "woff2"
4. Les requêtes doivent être servies depuis `/assets/fonts/` (pas `fonts.gstatic.com`)

## Gain attendu

- 🇪🇺 Conformité CNIL (plus de transfert d'IP visiteur vers Google)
- ⚡ +200ms de gain LCP (1 seul connect au lieu de 3 sur Google)
- 💪 Plus de dépendance externe (résilience renforcée)
