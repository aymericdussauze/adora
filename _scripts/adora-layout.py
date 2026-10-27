#!/usr/bin/env python3
"""ADORA : applique le menu, le pied de page et le fil d'Ariane communs.

Usage : python3 apply_layout.py <repo>
Idempotent : les blocs sont encadrés par des marqueurs et remplacés à chaque passage.
"""
import html
import json
import re
import sys
from pathlib import Path

CAL = "https://cal.com/aymeric-adora/decouverte"
SITE = "https://adora-economie.fr/"

MENU = [
    ("part", "Particuliers", [
        ("estimateur.html", "Estimer mes travaux", "Estimation tous corps d'état en 3 minutes, gratuite", False),
        ("simulateur.html", "Simulateur d'aides 2026", "Les aides à la rénovation en quelques clics", False),
        ("audit-avant-achat.html", "Audit avant achat", "Le coût réel des travaux avant de signer", False),
        ("sur-mesure.html", "Accompagnement sur mesure", "Assistance à maîtrise d'ouvrage, du projet à la réception", False),
    ]),
    ("pro", "Professionnels", [
        ("professionnels.html", "Offre professionnels", "Estimations, métrés, CCTP, DPGF, analyse des offres", False),
        ("benchmark-honoraires.html", "Benchmark des honoraires", "4 472 marchés publics analysés", True),
        ("partenaires.html#devenir-partenaire", "Devenir partenaire", "Architectes et professionnels du bâtiment", False),
    ]),
    ("adora", "ADORA", [
        ("a-propos.html", "À propos", "Parcours, méthode et références", False),
        ("partenaires.html", "Partenaires", "Le réseau de professionnels qui m'entoure", False),
        ("contact.html", "Contact", "Un échange découverte de 15 minutes", False),
    ]),
    ("pub", "Publications", "blog.html"),
]

ARTICLES_PART = {
    "prix-renovation-m2-2026.html": "Prix de la rénovation au m²",
    "maprimerenov-2026-bareme.html": "MaPrimeRénov' 2026",
    "audit-avant-achat-immobilier.html": "Audit avant achat immobilier",
    "pieges-devis-artisans.html": "Pièges des devis d'artisans",
    "15-lots-tce-expliques-particulier.html": "Les 15 lots TCE",
    "choisir-sa-gamme-renovation.html": "Choisir sa gamme",
    "diagnostic-parasitaire-negociation.html": "Diagnostic parasitaire",
}
ARTICLES_PRO = {
    "dpgf-comparable-consultation.html": "DPGF comparable",
    "erreur-quantitatif-dce.html": "Erreur de quantitatif au DCE",
    "rapport-analyse-offres-mapa.html": "Analyse des offres en MAPA",
    "honoraires-economiste-mission-moe.html": "Honoraires d'économiste",
}

SECTION = {}
for f in ["estimateur.html", "estimateur-outil.html", "simulateur.html", "audit-avant-achat.html",
          "audit-formulaire.html", "sur-mesure.html", "paiement-reussi.html"]:
    SECTION[f] = "part"
for f in ["professionnels.html", "benchmark-honoraires.html", "paiement-reussi-benchmark.html"]:
    SECTION[f] = "pro"
for f in ["a-propos.html", "contact.html", "partenaires.html"]:
    SECTION[f] = "adora"
for f in ["blog.html", *ARTICLES_PART, *ARTICLES_PRO]:
    SECTION[f] = "pub"

# Page dont le lien du menu doit être marqué « page courante »
CURRENT = {
    "estimateur-outil.html": "estimateur.html",
    "audit-formulaire.html": "audit-avant-achat.html",
    "paiement-reussi-benchmark.html": "benchmark-honoraires.html",
}

CTA_DEFAULT = ("Estimer mes travaux", "estimateur-outil.html", False)
CTA_CALL = ("Réserver un appel", CAL, True)
CTA = {f: CTA_CALL for f in ["professionnels.html", "paiement-reussi-benchmark.html", "estimateur-outil.html", *ARTICLES_PRO]}
CTA["benchmark-honoraires.html"] = ("Précommander", "#offre", False)

BREADCRUMB = {}
for f, name in ARTICLES_PART.items():
    BREADCRUMB[f] = [("Accueil", "./"), ("Publications", "blog.html"), ("Particuliers", "blog.html#particuliers"), (name, None)]
for f, name in ARTICLES_PRO.items():
    BREADCRUMB[f] = [("Accueil", "./"), ("Publications", "blog.html"), ("Professionnels", "blog.html#professionnels"), (name, None)]
BREADCRUMB["benchmark-honoraires.html"] = [("Accueil", "./"), ("Professionnels", "professionnels.html"), ("Benchmark des honoraires", None)]

SKIP = {"mon-rapport.html"}
CHEVRON = '<svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6 6-6"/></svg>'
E = html.escape


def nav_html(page):
    section = SECTION.get(page, "")
    current = CURRENT.get(page, page)
    label, href, external = CTA.get(page, CTA_DEFAULT)
    ext = ' target="_blank" rel="noopener"' if external else ""
    out = ['<!-- ADORA NAV -->',
           f'<nav class="anav" aria-label="Navigation principale"{f" data-section={chr(34)}{section}{chr(34)}" if section else ""}>',
           '<div class="anav-inner">',
           '  <a href="./" class="anav-logo"><img src="assets/img/adora-logo-blanc.svg" alt="ADORA, accueil" width="122" height="26"></a>',
           '  <button type="button" class="anav-burger" aria-expanded="false" aria-controls="anav-menu" aria-label="Ouvrir le menu"><span></span><span></span><span></span></button>',
           '  <div class="anav-menu" id="anav-menu">',
           '    <ul class="anav-list">']
    for entry in MENU:
        key, title = entry[0], entry[1]
        if isinstance(entry[2], str):
            cur = ' aria-current="page"' if entry[2] == current else ""
            out.append(f'      <li class="anav-item" data-key="{key}"><a href="{entry[2]}" class="anav-trigger"{cur}>{E(title)}</a></li>')
            continue
        out.append(f'      <li class="anav-item" data-key="{key}">')
        out.append(f'        <button type="button" class="anav-trigger" aria-expanded="false" aria-controls="anav-{key}">{E(title)}{CHEVRON}</button>')
        out.append(f'        <div class="anav-drop" id="anav-{key}"><div class="anav-drop-card">')
        for lhref, ltitle, ldesc, new in entry[2]:
            cur = ' aria-current="page"' if lhref == current else ""
            badge = ' <span class="anav-new">Nouveau</span>' if new else ""
            out.append(f'          <a href="{lhref}" class="anav-link"{cur}><span class="t">{E(ltitle)}{badge}</span><span class="d">{E(ldesc)}</span></a>')
        out.append('        </div></div>')
        out.append('      </li>')
    out += ['    </ul>',
            f'    <a href="{href}" class="anav-cta"{ext}>{E(label)}</a>',
            '  </div>',
            '</div>',
            '</nav>',
            '<!-- /ADORA NAV -->']
    return "\n".join(out)


FOOTER = f"""<!-- ADORA FOOTER -->
<footer class="afoot">
<div class="afoot-inner">
  <div class="afoot-brand">
    <img src="assets/img/adora-logo-blanc.svg" alt="ADORA" width="113" height="24" loading="lazy">
    <p>Économiste de la construction<br>Normandie &amp; Île-de-France</p>
  </div>
  <div class="afoot-col">
    <p class="afoot-title">Particuliers</p>
    <a href="estimateur.html">Estimer mes travaux</a>
    <a href="simulateur.html">Simulateur d'aides</a>
    <a href="audit-avant-achat.html">Audit avant achat</a>
    <a href="sur-mesure.html">Accompagnement sur mesure</a>
  </div>
  <div class="afoot-col">
    <p class="afoot-title">Professionnels</p>
    <a href="professionnels.html">Offre professionnels</a>
    <a href="benchmark-honoraires.html">Benchmark des honoraires</a>
    <a href="partenaires.html#devenir-partenaire">Devenir partenaire</a>
  </div>
  <div class="afoot-col">
    <p class="afoot-title">ADORA</p>
    <a href="a-propos.html">À propos</a>
    <a href="partenaires.html">Partenaires</a>
    <a href="blog.html">Publications</a>
    <a href="contact.html">Contact</a>
  </div>
  <div class="afoot-col">
    <p class="afoot-title">Contact</p>
    <a href="tel:+33672010767">06 72 01 07 67</a>
    <a href="mailto:contact@adora-economie.fr">contact@adora-economie.fr</a>
    <a href="{CAL}" target="_blank" rel="noopener">Réserver un appel</a>
  </div>
</div>
<div class="afoot-legal">© 2026 ADORA · EI · SIRET 532 886 918 00020 · TVA non applicable, art. 293 B du CGI<br><a href="mentions-legales.html">Mentions légales</a> · <a href="politique-confidentialite.html">Confidentialité</a> · <a href="cgv.html">CGV</a> · <button type="button" class="adora-cmp-footer-link" onclick="if(window.adoraConsent)window.adoraConsent.show()">Gérer mes cookies</button></div>
</footer>
<!-- /ADORA FOOTER -->"""

HEAD = ('<!-- ADORA LAYOUT -->\n<link rel="stylesheet" href="assets/css/adora-layout.css">\n'
        '<script src="assets/js/adora-layout.js" defer></script>\n<!-- /ADORA LAYOUT -->\n')


def breadcrumb(page):
    items = BREADCRUMB[page]
    lis = []
    for name, href in items:
        if href:
            lis.append(f'<li><a href="{href}">{E(name)}</a></li>')
        else:
            lis.append(f'<li><span aria-current="page">{E(name)}</span></li>')
    visual = ('<!-- ADORA BREADCRUMB -->\n<nav class="abc" aria-label="Fil d\'Ariane"><ol>'
              + "".join(lis) + '</ol></nav>\n<!-- /ADORA BREADCRUMB -->')
    elements = []
    for i, (name, href) in enumerate(items, 1):
        url = SITE + page if href is None else (SITE if href == "./" else SITE + href)
        elements.append({"@type": "ListItem", "position": i, "name": name, "item": url})
    schema = ('<!-- ADORA BREADCRUMB SCHEMA -->\n<script type="application/ld+json" data-adora-schema="breadcrumb">\n'
              + json.dumps({"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": elements},
                           ensure_ascii=False, indent=2)
              + '\n</script>\n<!-- /ADORA BREADCRUMB SCHEMA -->\n')
    return visual, schema


def replace_block(s, marker, pattern, new):
    """Remplace le bloc marqué s'il existe, sinon le premier motif d'origine."""
    marked = re.compile(rf"<!-- {marker} -->.*?<!-- /{marker} -->", re.S)
    if marked.search(s):
        return marked.sub(lambda m: new, s, count=1), True
    m = re.search(pattern, s, re.S)
    if not m:
        return s, False
    return s[:m.start()] + new + s[m.end():], True


def insert_head(s, block, marker):
    marked = re.compile(rf"<!-- {marker} -->.*?<!-- /{marker} -->\n?", re.S)
    s = marked.sub("", s)
    anchor = "<!-- ADORA CMP -->"
    if anchor in s:
        return s.replace(anchor, block + anchor, 1)
    return s.replace("</head>", block + "</head>", 1)


def main():
    repo = Path(sys.argv[1])
    report = []
    for path in sorted(repo.glob("*.html")):
        page = path.name
        if page in SKIP or page.startswith("google"):
            continue
        s = path.read_text(encoding="utf-8")
        s, nav_ok = replace_block(s, "ADORA NAV", r'<nav class="nav">.*?</nav>', nav_html(page))
        s, foot_ok = replace_block(s, "ADORA FOOTER", r'<footer class="footer">.*?</footer>', FOOTER)
        s = insert_head(s, HEAD, "ADORA LAYOUT")
        bc = "-"
        if page in BREADCRUMB:
            visual, schema = breadcrumb(page)
            s = re.sub(r"<!-- ADORA BREADCRUMB -->.*?<!-- /ADORA BREADCRUMB -->\n?", "", s, flags=re.S)
            if 'class="article-hero"' in s:
                s, n = re.subn(r'(<section class="article-hero">\s*<div class="container">)', lambda m: m.group(1) + "\n" + visual, s, count=1)
            else:
                s, n = re.subn(r'(<section class="bm-hero">\s*<div class="container bm-hero-grid">\s*<div>)', lambda m: m.group(1) + "\n" + visual, s, count=1)
            s = insert_head(s, schema, "ADORA BREADCRUMB SCHEMA")
            bc = "ok" if n else "ÉCHEC"
        path.write_text(s, encoding="utf-8")
        report.append(f"{page:42s} menu={'ok' if nav_ok else 'ÉCHEC'}  footer={'ok' if foot_ok else 'ÉCHEC'}  ariane={bc}  section={SECTION.get(page, '-')}")
    print("\n".join(report))


if __name__ == "__main__":
    main()
