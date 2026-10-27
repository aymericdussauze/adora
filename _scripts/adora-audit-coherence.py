#!/usr/bin/env python3
"""ADORA : contrôles de cohérence du site (liens, ancres, métadonnées, contacts, prix)."""
import html as H
import re
import sys
from collections import defaultdict
from pathlib import Path

repo = Path(sys.argv[1])
pages = {p.name: p.read_text(encoding="utf-8") for p in sorted(repo.glob("*.html")) if not p.name.startswith("google")}
UTILITY = {"mon-rapport.html", "paiement-reussi.html", "paiement-reussi-benchmark.html", "unsubscribe.html", "audit-formulaire.html"}
issues = defaultdict(list)


def strip(s):
    s = re.sub(r"<script.*?</script>|<style.*?</style>|<!--.*?-->", " ", s, flags=re.S)
    return H.unescape(re.sub(r"<[^>]+>", " ", s))


ids = {name: set(re.findall(r'\bid="([^"]+)"', s)) for name, s in pages.items()}

for name, s in pages.items():
    body = re.sub(r"<script.*?</script>|<!--.*?-->", " ", s, flags=re.S)
    # Liens internes et ancres
    for href in set(re.findall(r'href="([^"]+)"', body)):
        if re.match(r"^(https?:|mailto:|tel:|javascript:|data:)", href):
            continue
        target, _, anchor = href.partition("#")
        target = target.split("?")[0]
        if target in ("", "./"):
            target = name if target == "" else "index.html"
        if not (repo / target).exists():
            issues["Lien interne cassé"].append(f"{name} → {href}")
            continue
        if anchor and target in ids and anchor not in ids[target]:
            issues["Ancre introuvable"].append(f"{name} → {href}")
    # Ressources locales
    for src in set(re.findall(r'(?:src|href)="((?:assets|img)/[^"?#]+)"', body)):
        if not (repo / src).exists():
            issues["Ressource locale absente"].append(f"{name} → {src}")
    # Métadonnées
    if name in UTILITY:
        continue
    title = re.search(r"<title>(.*?)</title>", s, re.S)
    desc = re.search(r'<meta name="description" content="([^"]*)"', s)
    canon = re.search(r'<link rel="canonical" href="([^"]+)"', s)
    if not title:
        issues["Titre absent"].append(name)
    if not desc:
        issues["Meta description absente"].append(name)
    expected = "https://adora-economie.fr/" + ("" if name == "index.html" else name)
    if not canon:
        issues["Canonical absent"].append(name)
    elif canon.group(1) != expected:
        issues["Canonical incohérent"].append(f"{name} → {canon.group(1)}")
    og = re.search(r'<meta property="og:image" content="https://adora-economie.fr/([^"]+)"', s)
    if og and not (repo / og.group(1)).exists():
        issues["Image de partage absente"].append(f"{name} → {og.group(1)}")
    h1 = len(re.findall(r"<h1\b", s))
    if h1 != 1:
        issues["Nombre de H1 ≠ 1"].append(f"{name} ({h1})")
    if 'class="anav"' not in s:
        issues["Menu commun absent"].append(name)
    if 'class="afoot"' not in s:
        issues["Pied de page commun absent"].append(name)

# Doublons de titres et descriptions
for kind, rx in (("Titre en double", r"<title>(.*?)</title>"), ("Description en double", r'<meta name="description" content="([^"]*)"')):
    seen = defaultdict(list)
    for name, s in pages.items():
        m = re.search(rx, s, re.S)
        if m and name not in UTILITY:
            seen[m.group(1).strip()].append(name)
    for v, names in seen.items():
        if len(names) > 1:
            issues[kind].append(f"{', '.join(names)} : {v[:70]}")

# Contacts
for name, s in pages.items():
    txt = strip(s)
    for tel in set(re.findall(r"0[67](?:[ .]?\d{2}){4}", txt)):
        if re.sub(r"\D", "", tel) != "0672010767":
            issues["Téléphone différent"].append(f"{name} : {tel}")
    for mail in set(re.findall(r"[\w.+-]+@[\w-]+\.[\w.]+", txt)):
        if mail not in ("contact@adora-economie.fr", "votre@email.com", "email@exemple.fr"):
            issues["Adresse e-mail différente"].append(f"{name} : {mail}")
    for cal in set(re.findall(r"cal\.com/[\w/-]+", s)):
        if cal not in ("cal.com/aymeric-adora/decouverte", "cal.com/aymeric-adora/cafe-prescripteur"):
            issues["Lien Cal.com inattendu"].append(f"{name} : {cal}")
    for siret in set(re.findall(r"\b\d{3} ?\d{3} ?\d{3} ?\d{5}\b", txt)):
        if re.sub(r"\D", "", siret) != "53288691800020":
            issues["SIRET différent"].append(f"{name} : {siret}")

# Prix des offres (contexte autour du montant)
OFFERS = {
    "rapport PDF 49 €": r"\b49\s?(?:€|euros)",
    "audit 499 €": r"\b499\s?(?:€|euros)",
    "audit sur site 790 €": r"\b790\s?(?:€|euros)",
    "estimation 990 €": r"\b990\s?(?:€|euros)",
    "pack 2 200 €": r"\b2[\s  ]?200\s?(?:€|euros)",
    "pack 3 900 €": r"\b3[\s  ]?900\s?(?:€|euros)",
    "benchmark 79 €": r"\b79\s?(?:€|euros)",
}
price_pages = defaultdict(list)
for name, s in pages.items():
    txt = strip(s)
    for label, rx in OFFERS.items():
        if re.search(rx, txt):
            price_pages[label].append(name)

print("═" * 70)
if not issues:
    print("Aucune anomalie détectée.")
for kind, lst in issues.items():
    print(f"\n■ {kind} ({len(lst)})")
    for x in sorted(set(lst)):
        print("   -", x)
print("\n■ Pages citant chaque prix")
for label, names in price_pages.items():
    print(f"   {label:22s} {len(names):2d} : {', '.join(n.replace('.html', '') for n in names)}")
