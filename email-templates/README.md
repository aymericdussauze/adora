# Email Templates — ADORA

Ce dossier contient les **24 templates HTML** des séquences emails ADORA, en version v4 (logos auto-hébergés HTTPS, pas de base64 inline).

## Arborescence

```
email-templates/
├── a/  — Séquence A : Estimateur (6 mails, A1-A6)
├── b/  — Séquence B : Post-achat rapport 49€ (5 mails, B1-B5)
├── c/  — Séquence C : Audit avant achat 499€ (4 mails, C1-C4)
├── d/  — Séquence D : Ex-clients 12 mois (4 mails, D1-D4)
└── e/  — Séquence E : Prescripteurs 6 mois (5 mails, E1-E5)
```

## Pattern URL

Chaque template est accessible via :
```
https://adora-economie.fr/email-templates/{sequence}/{mailId}.html
```

Exemples :
- `https://adora-economie.fr/email-templates/a/A1.html`
- `https://adora-economie.fr/email-templates/b/B3.html`
- `https://adora-economie.fr/email-templates/e/E5.html`

## Variables Mustache à substituer

Les templates contiennent des variables `{{xxx}}` qui doivent être substituées au runtime par le Worker Cloudflare avant envoi via API Resend `/emails`.

### Variables business (16)

| Variable | Séquences | Description |
|---|---|---|
| `firstName` | A, B, C, D | Prénom destinataire |
| `propertyAddress` | A1, B1, C1-C4 | Adresse projet/bien |
| `propertySurface` | A1 | Surface SHAB en m² |
| `estimateAmount` | A1 | Budget estimé (formaté FR) |
| `rapportLink` | B1 | URL téléchargement rapport 49€ |
| `essentielLink` | B2, B3 | URL Pack Essentiel 2 200€ |
| `devisAMOLink` | B4 | URL devis AMO |
| `auditStripeLink` | C2 | Stripe Payment Link audit 499€ |
| `lastMissionType` | D1, D2, D4 | Type mission précédente |
| `lastMissionDate` | D2, D4 | Date mission précédente (FR) |
| `googleReviewLink` | D1 | URL Google Business Profile |
| `prescripteurName` | E1-E5 | Nom prescripteur |
| `prescripteurType` | E1 | Type prescripteur |
| `plaquettePDFLink` | E1 | URL plaquette ADORA |
| `blogArticleLink` | E2 | URL article blog |
| `calLink` | E4 | URL Cal.com café prescripteur |

### Variable native Resend

`{{{RESEND_UNSUBSCRIBE_URL}}}` (triple accolades) — automatiquement injectée par Resend pour le lien de désabonnement.

⚠️ Cette variable n'est pas à substituer côté Worker — elle reste telle quelle dans le HTML envoyé à Resend.

## Subjects par mail

| Mail | Subject |
|---|---|
| A1 | Votre estimation travaux est prête — ADORA |
| A2 | Aymeric d'ADORA — derrière l'estimateur — ADORA |
| A3 | Ce que votre estimation gratuite ne dit pas — ADORA |
| A4 | Les 3 pièges des devis d'artisans — ADORA |
| A5 | Votre projet avance ? Je peux faire plus — ADORA |
| A6 | On reste en contact ? — ADORA |
| B1 | Votre rapport ADORA — mode d'emploi |
| B2 | Besoin d'aide face aux artisans ? — ADORA |
| B3 | Les 3 devis que vous allez recevoir — ADORA |
| B4 | Vos 49 € sont déductibles du Pack AMO — ADORA |
| B5 | Où en êtes-vous de votre projet ? — ADORA |
| C1 | Votre demande d'audit avant achat est bien arrivée — ADORA |
| C2 | Votre lien pour finaliser l'audit — ADORA |
| C3 | Une question avant de finaliser ? — ADORA |
| C4 | Votre compromis approche ? — ADORA |
| D1 | Tout s'est bien passé ? Votre avis compte — ADORA |
| D2 | Des nouvelles de votre projet ? — ADORA |
| D3 | Je me permets de vous solliciter — ADORA |
| D4 | Un an déjà ! Nouveau projet en vue ? — ADORA |
| E1 | Une ressource pour vos clients acheteurs — ADORA |
| E2 | MaPrimeRénov' 2026 — ce qui compte pour vos clients — ADORA |
| E3 | 3 cas où l'audit a changé la négociation — ADORA |
| E4 | Un café pour en parler ? — ADORA |
| E5 | Invitation — petit-déjeuner « Sécuriser l'achat immo » — ADORA |

## Versioning

Les templates sont versionnés via Git. La version actuelle est **v4** (déployée le 26/04/2026).

Pour une future v5, créer un dossier `email-templates-v5/` (ne pas remplacer cette v4 sans migration progressive du Worker).

## Conventions

- **HTML inline-styles** uniquement (pas de classes CSS externes)
- **Logos HTTPS** : `/assets/logo-email-{header,footer}.png`
- **Stripe Payment Link 49€** : `https://buy.stripe.com/5kQdRbcdj5VAgxQ82F4Rq01`
- **Largeur container** : 600px (responsive < 600px)
- **Charset** : UTF-8

## Références

- Source de production v4 : 26/04/2026
- Voie de production : Worker Cloudflare → API Resend `/emails`
- Pas d'UI Resend dans le pipeline (UI Templates incompatible avec HTML email complexe)
