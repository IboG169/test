#!/usr/bin/env python3
"""
Demo-Website-Generator
Erzeugt eine fertige Demo-Seite für ein lokales Unternehmen und speichert
den Prospect in Supabase.

Verwendung:
  python generate.py --name "Café Bella" --branche restaurant \
                     --city Berlin --phone "030 123456" \
                     --email "info@cafebella.de" --address "Musterstr. 1, 10115 Berlin"
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# ── BRANCHENCONFIG ─────────────────────────────────────────────────────────────

BRANCHENCONFIG = {
    "restaurant": {
        "template": "restaurant.html",
        "color_primary": "#c8963e",
        "color_bg_dark": "#1a0d00",
        "higgsfield_prompt": "cozy upscale restaurant interior, candlelight, warm golden atmosphere, cinematic, slow motion, empty tables beautifully set",
        "system_prompt": """Du bist ein professioneller Web-Texter für Gastronomie-Websites.
Erstelle authentische, appetitanregende Texte auf Deutsch.
Antworte NUR mit einem JSON-Objekt, ohne Markdown-Code-Blöcke.""",
        "user_prompt_template": """Erstelle Website-Texte für das Restaurant "{name}" in {city}.
Gib ein JSON mit diesen Feldern zurück:
{{
  "TAGLINE": "Einzeiliger Slogan (max 8 Wörter)",
  "YEAR": "Gründungsjahr (erfinde realistisches: zwischen 1985 und 2015)",
  "ABOUT_TEXT": "2-3 Sätze über das Restaurant, warm und persönlich",
  "DISH_1_NAME": "Name Hauptgericht 1",
  "DISH_1_DESC": "kurze Beschreibung",
  "DISH_1_PRICE": "z.B. 18,50 €",
  "DISH_2_NAME": "Name Hauptgericht 2",
  "DISH_2_DESC": "kurze Beschreibung",
  "DISH_2_PRICE": "z.B. 22,00 €",
  "DISH_3_NAME": "Name Dessert oder Vorspeise",
  "DISH_3_DESC": "kurze Beschreibung",
  "DISH_3_PRICE": "z.B. 9,50 €",
  "STAT_1_NUM": "eine Zahl (z.B. 15+)",
  "STAT_1_LABEL": "was die Zahl bedeutet",
  "STAT_2_NUM": "eine Zahl",
  "STAT_2_LABEL": "was die Zahl bedeutet",
  "STAT_3_NUM": "eine Zahl",
  "STAT_3_LABEL": "was die Zahl bedeutet",
  "HOURS": "Öffnungszeiten (z.B. 11–23 Uhr)"
}}"""
    },
    "handwerk": {
        "template": "handwerk.html",
        "color_primary": "#e85d04",
        "color_bg_dark": "#0d1117",
        "higgsfield_prompt": "professional tradesman working, power tools, construction site, dramatic lighting, cinematic quality, slow motion, sparks flying",
        "system_prompt": """Du bist ein professioneller Web-Texter für Handwerksbetriebe.
Erstelle kraftvolle, vertrauenswürdige Texte auf Deutsch.
Antworte NUR mit einem JSON-Objekt, ohne Markdown-Code-Blöcke.""",
        "user_prompt_template": """Erstelle Website-Texte für den Handwerksbetrieb "{name}" in {city}.
Gewerk/Branche: {extra}
Gib ein JSON mit diesen Feldern zurück:
{{
  "SHORT_NAME": "Kurzname (1-2 Wörter, z.B. Nachname oder Firmenname)",
  "GEWERK": "Handwerksbezeichnung (z.B. Elektriker, Klempner)",
  "HEADLINE_1": "1. Zeile der Hauptüberschrift (3-4 Wörter, großgeschrieben)",
  "HEADLINE_2": "2. Zeile der Hauptüberschrift (3-4 Wörter, großgeschrieben)",
  "TAGLINE": "Slogan in einem Satz",
  "SERVICE_1_ICON": "passendes Emoji",
  "SERVICE_1_NAME": "Leistung 1",
  "SERVICE_1_DESC": "1-2 Sätze Beschreibung",
  "SERVICE_2_ICON": "passendes Emoji",
  "SERVICE_2_NAME": "Leistung 2",
  "SERVICE_2_DESC": "1-2 Sätze Beschreibung",
  "SERVICE_3_ICON": "passendes Emoji",
  "SERVICE_3_NAME": "Leistung 3",
  "SERVICE_3_DESC": "1-2 Sätze Beschreibung",
  "SERVICE_4_ICON": "passendes Emoji",
  "SERVICE_4_NAME": "Notdienst / Sonderleistung",
  "SERVICE_4_DESC": "1-2 Sätze Beschreibung",
  "POINT_1": "USP 1 (ein Satz)",
  "POINT_2": "USP 2 (ein Satz)",
  "POINT_3": "USP 3 (ein Satz)",
  "POINT_4": "USP 4 (ein Satz)",
  "STAT_1": "Zahl (z.B. 500+)",
  "STAT_1_LABEL": "Label",
  "STAT_2": "Zahl",
  "STAT_2_LABEL": "Label",
  "STAT_3": "Zahl",
  "STAT_3_LABEL": "Label",
  "HOURS": "Erreichbarkeit (z.B. Mo–Fr 7–18 Uhr)"
}}"""
    },
    "shop": {
        "template": "shop.html",
        "color_primary": "#2d2d2d",
        "color_bg": "#f5f3ef",
        "higgsfield_prompt": "elegant boutique interior, soft natural light, fashion items on display, cinematic slow motion, minimalist aesthetic, luxury feel",
        "system_prompt": """Du bist ein professioneller Web-Texter für Einzelhandel und Boutiquen.
Erstelle elegante, einladende Texte auf Deutsch.
Antworte NUR mit einem JSON-Objekt, ohne Markdown-Code-Blöcke.""",
        "user_prompt_template": """Erstelle Website-Texte für den Shop "{name}" in {city}.
Kategorie/Art: {extra}
Gib ein JSON mit diesen Feldern zurück:
{{
  "CATEGORY": "Kategorie (z.B. Mode, Kosmetik, Schmuck)",
  "HEADLINE_1": "1. Zeile Headline (2-3 Wörter)",
  "HEADLINE_2": "2. Zeile Headline, Akzent-Wort (1-2 Wörter)",
  "TAGLINE": "Einzeiliger Slogan",
  "PRODUCT_1_NAME": "Produktname 1",
  "PRODUCT_1_SUB": "Kurze Beschreibung",
  "PRODUCT_1_PRICE": "Preis (z.B. 89,00 €)",
  "PRODUCT_2_NAME": "Produktname 2",
  "PRODUCT_2_SUB": "Kurze Beschreibung",
  "PRODUCT_2_PRICE": "Preis",
  "PRODUCT_3_NAME": "Produktname 3",
  "PRODUCT_3_SUB": "Kurze Beschreibung",
  "PRODUCT_3_PRICE": "Preis",
  "ABOUT_HEADLINE": "Headline für Über-uns-Sektion (5-7 Wörter)",
  "ABOUT_TEXT_1": "Absatz 1 über den Shop (2-3 Sätze)",
  "ABOUT_TEXT_2": "Absatz 2 über Philosophie (2-3 Sätze)",
  "VISIT_TEXT": "Einladender Text zum Besuch (1-2 Sätze)",
  "HOURS": "Öffnungszeiten"
}}"""
    },
    "kanzlei": {
        "template": "kanzlei.html",
        "color_primary": "#1a2744",
        "color_secondary": "#243254",
        "higgsfield_prompt": "modern law office interior, books, professional atmosphere, cinematic, calm and authoritative, natural light through large windows",
        "system_prompt": """Du bist ein professioneller Web-Texter für Rechtsanwaltskanzleien und Freie Berufe.
Erstelle seriöse, vertrauenswürdige Texte auf Deutsch.
Antworte NUR mit einem JSON-Objekt, ohne Markdown-Code-Blöcke.""",
        "user_prompt_template": """Erstelle Website-Texte für die Kanzlei/das Büro "{name}" in {city}.
Fachgebiet: {extra}
Gib ein JSON mit diesen Feldern zurück:
{{
  "INITIALS": "Initialen (2 Buchstaben, z.B. MB)",
  "FACHGEBIET": "Fachgebiet (z.B. Familienrecht, Steuerberatung)",
  "TAGLINE": "Vertrauenswürdiger Slogan in einem Satz",
  "AREA_1_NAME": "Fachbereich 1",
  "AREA_1_DESC": "1-2 Sätze Beschreibung",
  "AREA_2_NAME": "Fachbereich 2",
  "AREA_2_DESC": "1-2 Sätze Beschreibung",
  "AREA_3_NAME": "Fachbereich 3",
  "AREA_3_DESC": "1-2 Sätze Beschreibung",
  "AREA_4_NAME": "Fachbereich 4",
  "AREA_4_DESC": "1-2 Sätze Beschreibung",
  "ABOUT_HEADLINE": "Headline für Über-uns (5-8 Wörter)",
  "ABOUT_TEXT_1": "Erster Absatz (2-3 Sätze, seriös und kompetent)",
  "ABOUT_TEXT_2": "Zweiter Absatz über Mandantenbetreuung",
  "CREDENTIAL_1": "Qualifikation/Auszeichnung 1",
  "CREDENTIAL_2": "Qualifikation/Auszeichnung 2",
  "CREDENTIAL_3": "Qualifikation/Auszeichnung 3",
  "HOURS": "Sprechzeiten (z.B. Mo–Fr 9–17 Uhr)"
}}"""
    }
}


# ── CLAUDE API ──────────────────────────────────────────────────────────────────

def generate_content_with_claude(name: str, branche: str, city: str, extra: str = "") -> dict:
    """Ruft Claude API auf um Inhalte zu generieren."""
    try:
        import anthropic
    except ImportError:
        print("⚠️  anthropic-Paket fehlt. Installiere mit: pip install anthropic")
        return get_placeholder_content(branche)

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("⚠️  ANTHROPIC_API_KEY nicht gesetzt. Nutze Platzhalter-Inhalte.")
        return get_placeholder_content(branche)

    config = BRANCHENCONFIG[branche]
    client = anthropic.Anthropic(api_key=api_key)

    user_prompt = config["user_prompt_template"].format(
        name=name, city=city, extra=extra or branche
    )

    print(f"  🤖 Generiere Inhalte mit Claude für '{name}'...")
    message = client.messages.create(
        model="claude-opus-4-8",
        max_tokens=1500,
        system=config["system_prompt"],
        messages=[{"role": "user", "content": user_prompt}]
    )

    raw = message.content[0].text.strip()
    # JSON aus der Antwort extrahieren
    json_match = re.search(r'\{.*\}', raw, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())
    return json.loads(raw)


def get_placeholder_content(branche: str) -> dict:
    """Fallback-Inhalte wenn kein API-Key vorhanden."""
    defaults = {
        "restaurant": {
            "TAGLINE": "Authentische Küche mit Herz und Seele",
            "YEAR": "2008",
            "ABOUT_TEXT": "Seit über 15 Jahren verwöhnen wir unsere Gäste mit frischen, saisonalen Gerichten. Jedes Gericht wird mit Liebe und den besten Zutaten aus der Region zubereitet.",
            "DISH_1_NAME": "Signature Pasta", "DISH_1_DESC": "Hausgemachte Nudeln, Trüffelsauce", "DISH_1_PRICE": "19,50 €",
            "DISH_2_NAME": "Gegrillter Lachs", "DISH_2_DESC": "Mit Kräuterbutter und Saisongemüse", "DISH_2_PRICE": "24,00 €",
            "DISH_3_NAME": "Tiramisu", "DISH_3_DESC": "Nach originalem Hausrezept", "DISH_3_PRICE": "8,50 €",
            "STAT_1_NUM": "15+", "STAT_1_LABEL": "Jahre Erfahrung",
            "STAT_2_NUM": "500+", "STAT_2_LABEL": "Zufriedene Gäste pro Woche",
            "STAT_3_NUM": "98%", "STAT_3_LABEL": "Positive Bewertungen",
            "HOURS": "Di–So 11:30–23:00 Uhr"
        },
        "handwerk": {
            "SHORT_NAME": "Meister", "GEWERK": "Elektriker",
            "HEADLINE_1": "SCHNELL. SICHER.", "HEADLINE_2": "ZUVERLÄSSIG.",
            "TAGLINE": "Ihr Fachbetrieb für alle elektrischen Arbeiten — von der Steckdose bis zur Gesamtinstallation.",
            "SERVICE_1_ICON": "⚡", "SERVICE_1_NAME": "Elektroinstallation", "SERVICE_1_DESC": "Neuinstallation und Modernisierung elektrischer Anlagen nach modernsten Standards.",
            "SERVICE_2_ICON": "🔧", "SERVICE_2_NAME": "Reparatur & Wartung", "SERVICE_2_DESC": "Schnelle und zuverlässige Reparatur aller elektrischen Geräte und Anlagen.",
            "SERVICE_3_ICON": "💡", "SERVICE_3_NAME": "Smart Home", "SERVICE_3_DESC": "Intelligente Gebäudeautomation für mehr Komfort und Energieeffizienz.",
            "SERVICE_4_ICON": "🚨", "SERVICE_4_NAME": "24h Notdienst", "SERVICE_4_DESC": "Bei Stromausfall oder elektrischen Notfällen sind wir rund um die Uhr erreichbar.",
            "POINT_1": "Über 20 Jahre Erfahrung im Elektrohandwerk",
            "POINT_2": "Festpreise — keine versteckten Kosten",
            "POINT_3": "Zertifizierter Meisterbetrieb",
            "POINT_4": "Antwort innerhalb von 2 Stunden garantiert",
            "STAT_1": "20+", "STAT_1_LABEL": "Jahre Erfahrung",
            "STAT_2": "1.200+", "STAT_2_LABEL": "Abgeschlossene Projekte",
            "STAT_3": "24/7", "STAT_3_LABEL": "Notdienst",
            "HOURS": "Mo–Fr 7–18 Uhr"
        },
        "shop": {
            "CATEGORY": "Mode & Lifestyle",
            "HEADLINE_1": "Zeitloser", "HEADLINE_2": "Stil",
            "TAGLINE": "Kuratierte Mode und Accessoires für Menschen mit Geschmack.",
            "PRODUCT_1_NAME": "Premium Ledertasche", "PRODUCT_1_SUB": "Handgefertigt in Italien", "PRODUCT_1_PRICE": "249,00 €",
            "PRODUCT_2_NAME": "Seidenschal", "PRODUCT_2_SUB": "Limitierte Edition", "PRODUCT_2_PRICE": "89,00 €",
            "PRODUCT_3_NAME": "Lederarmband", "PRODUCT_3_SUB": "Klassisches Design", "PRODUCT_3_PRICE": "45,00 €",
            "ABOUT_HEADLINE": "Qualität, die man spürt",
            "ABOUT_TEXT_1": "Seit Jahren wählen wir mit größter Sorgfalt die schönsten Stücke aus aller Welt aus. Jedes Produkt in unserem Sortiment wurde persönlich ausgewählt.",
            "ABOUT_TEXT_2": "Unser Anspruch ist es, Mode zu bieten, die zeitlos ist und bleibt — Stücke, die Sie jahrelang begleiten.",
            "VISIT_TEXT": "Entdecken Sie unsere aktuelle Kollektion in unserem Geschäft. Wir beraten Sie gerne persönlich.",
            "HOURS": "Mo–Sa 10–19 Uhr"
        },
        "kanzlei": {
            "INITIALS": "MB",
            "FACHGEBIET": "Familienrecht & Erbrecht",
            "TAGLINE": "Wir vertreten Ihre Interessen mit Kompetenz, Klarheit und persönlichem Engagement.",
            "AREA_1_NAME": "Familienrecht", "AREA_1_DESC": "Scheidung, Sorgerecht, Unterhalt — wir begleiten Sie durch schwierige Zeiten mit Fingerspitzengefühl.",
            "AREA_2_NAME": "Erbrecht", "AREA_2_DESC": "Testamente, Erbschaftsstreitigkeiten und Nachlassplanung: Wir sichern, was Sie aufgebaut haben.",
            "AREA_3_NAME": "Vertragsrecht", "AREA_3_DESC": "Prüfung, Gestaltung und Verhandlung von Verträgen jeder Art für Privatpersonen und Unternehmen.",
            "AREA_4_NAME": "Arbeitsrecht", "AREA_4_DESC": "Kündigung, Abfindung, Arbeitszeugnis — Ihre Rechte als Arbeitnehmer oder Arbeitgeber.",
            "ABOUT_HEADLINE": "Recht. Klar. Persönlich.",
            "ABOUT_TEXT_1": "Als inhabergeführte Kanzlei legen wir größten Wert auf persönliche Betreuung. Sie haben einen festen Ansprechpartner, der Ihre Geschichte kennt.",
            "ABOUT_TEXT_2": "Wir glauben, dass gute Rechtsberatung verständlich sein muss. Deshalb erklären wir komplexe Sachverhalte in klarer Sprache.",
            "CREDENTIAL_1": "Fachanwalt für Familienrecht",
            "CREDENTIAL_2": "Mitglied im Deutschen Anwaltverein",
            "CREDENTIAL_3": "Über 500 erfolgreich abgeschlossene Mandate",
            "HOURS": "Mo–Fr 9–17 Uhr, nach Vereinbarung"
        }
    }
    return defaults.get(branche, {})


# ── TEMPLATE-BEFÜLLUNG ──────────────────────────────────────────────────────────

def fill_template(template_path: Path, variables: dict) -> str:
    """Ersetzt {{PLATZHALTER}} im Template durch echte Werte."""
    content = template_path.read_text(encoding="utf-8")
    for key, value in variables.items():
        content = content.replace(f"{{{{{key}}}}}", str(value))
    return content


def build_video_tag(video_path: str | None) -> str:
    if video_path and Path(video_path).exists():
        return f'<video autoplay muted loop playsinline src="{video_path}"></video>'
    return '<div class="hero-fallback"></div>'


# ── SUPABASE CRM ────────────────────────────────────────────────────────────────

def save_prospect_to_supabase(data: dict) -> bool:
    """Speichert Prospect in Supabase via REST API."""
    supabase_url = os.environ.get("SUPABASE_URL", "https://fddxttzodwajymcyooot.supabase.co")
    supabase_key = os.environ.get("SUPABASE_ANON_KEY")
    if not supabase_key:
        print("  ⚠️  SUPABASE_ANON_KEY nicht gesetzt — Prospect nicht gespeichert.")
        return False

    try:
        import urllib.request, urllib.error
        payload = json.dumps(data).encode()
        req = urllib.request.Request(
            f"{supabase_url}/rest/v1/prospects",
            data=payload,
            headers={
                "Content-Type": "application/json",
                "apikey": supabase_key,
                "Authorization": f"Bearer {supabase_key}",
                "Prefer": "return=representation"
            },
            method="POST"
        )
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            print(f"  ✅ Prospect in Supabase gespeichert: ID {result[0].get('id', '?')}")
            return True
    except Exception as e:
        print(f"  ⚠️  Supabase-Fehler: {e}")
        return False


# ── VERCEL DEPLOY ───────────────────────────────────────────────────────────────

def deploy_to_vercel(demo_dir: Path, project_name: str) -> str | None:
    """Deployed die Demo-Seite via Vercel CLI."""
    vercel = shutil.which("vercel")
    if not vercel:
        print("  ⚠️  Vercel CLI nicht gefunden. Überspringe Deploy.")
        print(f"  📂 Demo liegt unter: {demo_dir}/index.html")
        return None

    print("  🚀 Deploye zu Vercel...")
    slug = re.sub(r'[^a-z0-9-]', '-', project_name.lower())[:50]
    try:
        result = subprocess.run(
            [vercel, "--yes", "--prod", "--name", f"demo-{slug}"],
            cwd=demo_dir,
            capture_output=True,
            text=True,
            timeout=120
        )
        url_match = re.search(r'https://[^\s]+\.vercel\.app', result.stdout)
        if url_match:
            url = url_match.group()
            print(f"  ✅ Live unter: {url}")
            return url
        print(f"  ⚠️  Vercel-Output: {result.stdout[-200:]}")
    except Exception as e:
        print(f"  ⚠️  Vercel-Fehler: {e}")
    return None


# ── HAUPTFUNKTION ───────────────────────────────────────────────────────────────

def generate_demo(name: str, branche: str, city: str, phone: str,
                  email: str, address: str, extra: str = "",
                  higgsfield_video: str | None = None,
                  deploy: bool = False) -> Path:

    print(f"\n🏗️  Generiere Demo für '{name}' ({branche}, {city})")

    config = BRANCHENCONFIG[branche]
    templates_dir = Path(__file__).parent.parent / "templates"
    demos_dir = Path(__file__).parent.parent / "demos"

    # Ausgabeordner
    slug = re.sub(r'[^a-z0-9-]', '-', name.lower())[:40]
    output_dir = demos_dir / slug
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Inhalte generieren
    content = generate_content_with_claude(name, branche, city, extra)

    # 2. Alle Template-Variablen zusammenstellen
    year = datetime.now().year
    variables = {
        "BUSINESS_NAME": name,
        "CITY": city,
        "PHONE": phone,
        "EMAIL": email,
        "ADDRESS": address,
        "YEAR": str(year),
        "COLOR_PRIMARY": config["color_primary"],
        "COLOR_BG_DARK": config.get("color_bg_dark", "#0d1117"),
        "COLOR_SECONDARY": config.get("color_secondary", config["color_primary"]),
        "COLOR_BG": config.get("color_bg", "#f8f7f4"),
        "VIDEO_TAG": build_video_tag(higgsfield_video),
        "VIDEO_TAG_OR_IMG": build_video_tag(higgsfield_video),
        **content
    }

    # 3. Template befüllen
    template_path = templates_dir / config["template"]
    html = fill_template(template_path, variables)

    # 4. HTML schreiben
    output_file = output_dir / "index.html"
    output_file.write_text(html, encoding="utf-8")
    print(f"  📄 HTML generiert: {output_file}")

    # 5. Video kopieren falls vorhanden
    if higgsfield_video and Path(higgsfield_video).exists():
        shutil.copy(higgsfield_video, output_dir / "hero.mp4")

    # 6. In Supabase speichern
    demo_url = None
    if deploy:
        demo_url = deploy_to_vercel(output_dir, name)

    save_prospect_to_supabase({
        "name": name,
        "branche": branche,
        "adresse": address,
        "telefon": phone,
        "email": email,
        "website_vorhanden": False,
        "demo_url": demo_url,
        "status": "neu",
        "notizen": f"Demo generiert am {datetime.now().strftime('%d.%m.%Y')}"
    })

    # 7. Higgsfield-Prompt ausgeben für manuellen Aufruf
    print(f"\n  🎬 Higgsfield-Prompt für Video:")
    print(f"  '{config['higgsfield_prompt']}'")
    print(f"\n  📁 Demo-Ordner: {output_dir}")
    print(f"  🌐 Im Browser öffnen: file://{output_file}")
    if demo_url:
        print(f"  🔗 Live-URL: {demo_url}")

    return output_dir


# ── CLI ─────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Demo-Website-Generator")
    parser.add_argument("--name", required=True, help="Name des Unternehmens")
    parser.add_argument("--branche", required=True,
                        choices=["restaurant", "handwerk", "shop", "kanzlei"])
    parser.add_argument("--city", required=True, help="Stadt")
    parser.add_argument("--phone", default="", help="Telefonnummer")
    parser.add_argument("--email", default="", help="E-Mail-Adresse")
    parser.add_argument("--address", default="", help="Adresse")
    parser.add_argument("--extra", default="",
                        help="Zusatzinfo (Gewerk, Fachgebiet, Kategorie)")
    parser.add_argument("--video", default=None, help="Pfad zu Higgsfield-Video (.mp4)")
    parser.add_argument("--deploy", action="store_true",
                        help="Automatisch zu Vercel deployen")
    args = parser.parse_args()

    generate_demo(
        name=args.name,
        branche=args.branche,
        city=args.city,
        phone=args.phone,
        email=args.email,
        address=args.address,
        extra=args.extra,
        higgsfield_video=args.video,
        deploy=args.deploy
    )


if __name__ == "__main__":
    main()
