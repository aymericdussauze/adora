# ADORA

**Environnement de staging** pour le site [adora-economie.fr](https://adora-economie.fr)

Preview : [aymericdussauze.github.io/adora-staging](https://aymericdussauze.github.io/adora-staging/)

---

## À propos

Site vitrine et outils en ligne d'**ADORA — Économiste de la construction**, cabinet indépendant en Normandie (27/76) et Île-de-France.

Tunnel de conversion PropTech : Gratuit (lead) → 49 € (rapport PDF) → 499 € (audit) → AMO sur mesure (2 200–3 900 €)

## Pages (22 fichiers HTML)

### Pages principales (12)

| Fichier | Page | Conversion |
|---|---|---|
| `index.html` | Homepage | → outils |
| `simulateur.html` | Simulateur aides rénovation | Lead magnet (email → PDF) |
| `estimateur.html` | Estimateur (landing) | → outil |
| `estimateur-outil.html` | Estimateur (formulaire Typeform) | Paywall Stripe 49 € |
| `paiement-reussi.html` | Confirmation post-Stripe | → rapport email |
| `mon-rapport.html` | Récupération rapport post-paiement | noindex |
| `audit-avant-achat.html` | Audit achat (landing) | → formulaire |
| `audit-formulaire.html` | Audit achat (formulaire Typeform) | Lead qualifié 499 € |
| `sur-mesure.html` | Packs AMO + estimation détaillée | → contact direct |
| `a-propos.html` | Parcours, philosophie, références | Crédibilité |
| `professionnels.html` | Offre B2B + TJM affichés | → contact |
| `partenaires.html` | Réseau partenaires (archi intérieur) | Crédibilité |
| `contact.html` | Contact direct | Conversion |

### Blog (4)

| Fichier | Article | SEO |
|---|---|---|
| `blog.html` | Index blog | Hub |
| `prix-renovation-m2-2026.html` | Prix rénovation au m² 2026 | Trafic |
| `maprimerenov-2026-bareme.html` | MaPrimeRénov' 2026 barèmes | Trafic |
| `audit-avant-achat-immobilier.html` | Guide audit avant achat | Conversion |
| `pieges-devis-artisans.html` | 7 pièges des devis d'artisans | Trafic |

### Pages légales & utilitaires (5)

| Fichier | Contenu |
|---|---|
| `mentions-legales.html` | Mentions légales (EI, SIRET, hébergeur) |
| `politique-confidentialite.html` | RGPD, cookies, prestataires |
| `cgv.html` | Conditions générales de vente |
| `unsubscribe.html` | Désabonnement emails (RGPD Resend) |
| `paiement-reussi.html` | Confirmation post-Stripe (noindex) |

### SEO structuré (Schema.org)

| Fichier | Type |
|---|---|
| `estimateur.html` | FAQPage (3 questions) |
| `prix-renovation-m2-2026.html` | Article + FAQPage (3 questions) |
| `audit-avant-achat-immobilier.html` | Article + FAQPage (5 questions) |
| `maprimerenov-2026-bareme.html` | Article + FAQPage (5 questions) |

## Navigation

### Nav (sticky, identique sur toutes les pages)

```
[Logo ADORA]   Simulateur   Estimateur   Audit achat   Sur mesure   [Estimer mes travaux →]
```

CTA → `estimateur-outil.html` · Lien actif surligné (`.active`)

### Footer (4 colonnes, identique partout)

| Marque | Outils | ADORA | Contact |
|---|---|---|---|
| ADORA · Éco construction · Normandie & IDF | Simulateur · Estimateur · Audit · Sur mesure | À propos · Professionnels · Partenaires · Blog · Contact | Tél · Email · Site |

Ligne légale : © 2026 ADORA · EI · SIRET 532 886 918 00020 · TVA art. 293B · Mentions · Confidentialité · CGV

## SEO Staging

Le staging est protégé contre l'indexation Google (évite le duplicate content avec la prod) :

- `robots.txt` → `Disallow: /`
- `<meta name="robots" content="noindex, nofollow">` sur les 22 pages
- `sitemap.xml` présent (URLs prod `adora-economie.fr`, prêt pour migration)

## Monitoring

| Outil | Rôle | Statut |
|---|---|---|
| **Sentry** | Erreurs JS frontend | Actif (script injecté 22 pages) |
| **Cloudflare Web Analytics** | Core Web Vitals RUM sans cookie | Actif (beacon injecté 22 pages) |
| **UptimeRobot** | Uptime + SSL expiry | Actif (4 monitors staging) |
| **GA4** | Analytics | Actif (`G-M0LENY960B`) |
| **Lighthouse CI** | Perf auto à chaque push | À déployer (`.github/workflows/`) |

## Stack technique

| Service | Rôle |
|---|---|
| GitHub Pages | Hébergement statique |
| OVH | DNS `adora-economie.fr` |
| Stripe | Paiements (49 € estimateur, 499 € audit) |
| Resend | Email transactionnel + automations (5 séquences, 25 emails) |
| Formspree | Formulaires site (`xzdjopya` prod / `maqaewbn` staging) |
| Cal.com | Prise de RDV |
| Cloudflare | Workers (Stripe→Qonto) + Web Analytics |
| Notion | CRM + projets + pilotage |
| Qonto | Banque + facturation DGFIP |

Coût total stack : ~75,50 €/mois

## Déploiement (GitHub Desktop macOS)

1. **Repository → Show in Finder** (⌘⇧F)
2. Copier/coller les fichiers à la **racine** (pas dans un sous-dossier)
3. GitHub Desktop → onglet **Changes** → vérifier la liste
4. Message de commit → **"Commit to main"**
5. **"Push origin"** (en haut)
6. Build GitHub Pages automatique (1-2 min)

## Migration prod (Phase 4)

1. Exécuter `remove-noindex.sh` (Terminal macOS)
2. Renommer `robots_PROD.txt` → `robots.txt`
3. Remplacer Formspree ID `maqaewbn` → `xzdjopya` dans `audit-formulaire.html`
4. Configurer GitHub Pages custom domain `adora-economie.fr`
5. Soumettre `sitemap.xml` à Google Search Console + Bing Webmaster

## Contact

**ADORA** — Aymeric Dussauze
Économiste de la construction · EI · SIRET 532 886 918 00020
TVA non applicable, art. 293B du CGI
06 60 21 55 09 · contact@adora-economie.fr
