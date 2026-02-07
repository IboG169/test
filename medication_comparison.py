#!/usr/bin/env python3
"""
Medikamenten-Problem-Vergleichstool
====================================
Vergleicht Medikamente und Probleme/Erkrankungen, um bessere
Behandlungsansätze zu identifizieren.

Funktionen:
- Medikamente mit Wirksamkeit, Nebenwirkungen und Kosten erfassen
- Probleme/Erkrankungen mit Symptomen definieren
- Medikamente Problemen zuordnen und bewerten
- Vergleichsanalysen und Empfehlungen generieren
- Daten als JSON speichern und laden
"""

import json
import os
from dataclasses import dataclass, field, asdict
from typing import Optional


# ---------------------------------------------------------------------------
# Datenmodelle
# ---------------------------------------------------------------------------

@dataclass
class Medikament:
    name: str
    wirkstoff: str
    kategorie: str  # z.B. "Analgetikum", "Antibiotikum"
    nebenwirkungen: list[str] = field(default_factory=list)
    kosten_pro_einheit: float = 0.0  # EUR
    verschreibungspflichtig: bool = False
    notizen: str = ""


@dataclass
class Problem:
    name: str
    beschreibung: str
    symptome: list[str] = field(default_factory=list)
    schweregrad: int = 1  # 1-5
    notizen: str = ""


@dataclass
class Zuordnung:
    """Verknüpft ein Medikament mit einem Problem und bewertet es."""
    medikament_name: str
    problem_name: str
    wirksamkeit: int = 0       # 1-10
    vertraeglichkeit: int = 0  # 1-10
    evidenzgrad: str = ""      # z.B. "hoch", "mittel", "niedrig"
    anmerkungen: str = ""

    @property
    def gesamtscore(self) -> float:
        return (self.wirksamkeit * 0.6) + (self.vertraeglichkeit * 0.4)


# ---------------------------------------------------------------------------
# Datenbank (JSON-basiert)
# ---------------------------------------------------------------------------

class Datenbank:
    def __init__(self, pfad: str = "medikamente_db.json"):
        self.pfad = pfad
        self.medikamente: dict[str, Medikament] = {}
        self.probleme: dict[str, Problem] = {}
        self.zuordnungen: list[Zuordnung] = []
        self._laden()

    # --- Persistenz ---

    def _laden(self):
        if not os.path.exists(self.pfad):
            return
        with open(self.pfad, "r", encoding="utf-8") as f:
            daten = json.load(f)
        for m in daten.get("medikamente", []):
            med = Medikament(**m)
            self.medikamente[med.name] = med
        for p in daten.get("probleme", []):
            prob = Problem(**p)
            self.probleme[prob.name] = prob
        for z in daten.get("zuordnungen", []):
            self.zuordnungen.append(Zuordnung(**z))

    def speichern(self):
        daten = {
            "medikamente": [asdict(m) for m in self.medikamente.values()],
            "probleme": [asdict(p) for p in self.probleme.values()],
            "zuordnungen": [asdict(z) for z in self.zuordnungen],
        }
        with open(self.pfad, "w", encoding="utf-8") as f:
            json.dump(daten, f, ensure_ascii=False, indent=2)

    # --- Medikamente ---

    def medikament_hinzufuegen(self, med: Medikament):
        self.medikamente[med.name] = med
        self.speichern()

    def medikament_entfernen(self, name: str):
        self.medikamente.pop(name, None)
        self.zuordnungen = [z for z in self.zuordnungen if z.medikament_name != name]
        self.speichern()

    # --- Probleme ---

    def problem_hinzufuegen(self, prob: Problem):
        self.probleme[prob.name] = prob
        self.speichern()

    def problem_entfernen(self, name: str):
        self.probleme.pop(name, None)
        self.zuordnungen = [z for z in self.zuordnungen if z.problem_name != name]
        self.speichern()

    # --- Zuordnungen ---

    def zuordnung_hinzufuegen(self, zuordnung: Zuordnung):
        self.zuordnungen.append(zuordnung)
        self.speichern()

    def zuordnungen_fuer_problem(self, problem_name: str) -> list[Zuordnung]:
        return [z for z in self.zuordnungen if z.problem_name == problem_name]

    def zuordnungen_fuer_medikament(self, med_name: str) -> list[Zuordnung]:
        return [z for z in self.zuordnungen if z.medikament_name == med_name]


# ---------------------------------------------------------------------------
# Vergleichs-Engine
# ---------------------------------------------------------------------------

class VergleichsEngine:
    def __init__(self, db: Datenbank):
        self.db = db

    def ranking_fuer_problem(self, problem_name: str) -> list[dict]:
        """Gibt Medikamente sortiert nach Gesamtscore für ein Problem zurück."""
        zuordnungen = self.db.zuordnungen_fuer_problem(problem_name)
        ergebnis = []
        for z in zuordnungen:
            med = self.db.medikamente.get(z.medikament_name)
            if not med:
                continue
            ergebnis.append({
                "medikament": med.name,
                "wirkstoff": med.wirkstoff,
                "wirksamkeit": z.wirksamkeit,
                "vertraeglichkeit": z.vertraeglichkeit,
                "gesamtscore": round(z.gesamtscore, 2),
                "evidenzgrad": z.evidenzgrad,
                "kosten": med.kosten_pro_einheit,
                "nebenwirkungen": med.nebenwirkungen,
                "anmerkungen": z.anmerkungen,
            })
        ergebnis.sort(key=lambda x: x["gesamtscore"], reverse=True)
        return ergebnis

    def medikament_profil(self, med_name: str) -> dict:
        """Erstellt ein Profil eines Medikaments über alle Probleme hinweg."""
        med = self.db.medikamente.get(med_name)
        if not med:
            return {}
        zuordnungen = self.db.zuordnungen_fuer_medikament(med_name)
        probleme_info = []
        for z in zuordnungen:
            probleme_info.append({
                "problem": z.problem_name,
                "wirksamkeit": z.wirksamkeit,
                "vertraeglichkeit": z.vertraeglichkeit,
                "gesamtscore": round(z.gesamtscore, 2),
            })
        avg_score = 0.0
        if probleme_info:
            avg_score = round(
                sum(p["gesamtscore"] for p in probleme_info) / len(probleme_info), 2
            )
        return {
            "name": med.name,
            "wirkstoff": med.wirkstoff,
            "kategorie": med.kategorie,
            "kosten": med.kosten_pro_einheit,
            "nebenwirkungen": med.nebenwirkungen,
            "durchschnittsscore": avg_score,
            "einsatzgebiete": probleme_info,
        }

    def vergleich_zweier_medikamente(self, name_a: str, name_b: str) -> dict:
        """Direktvergleich zweier Medikamente über alle gemeinsamen Probleme."""
        zuordnungen_a = {z.problem_name: z for z in self.db.zuordnungen_fuer_medikament(name_a)}
        zuordnungen_b = {z.problem_name: z for z in self.db.zuordnungen_fuer_medikament(name_b)}
        gemeinsame = set(zuordnungen_a.keys()) & set(zuordnungen_b.keys())
        vergleiche = []
        for prob in sorted(gemeinsame):
            za = zuordnungen_a[prob]
            zb = zuordnungen_b[prob]
            vergleiche.append({
                "problem": prob,
                name_a: {"wirksamkeit": za.wirksamkeit, "vertraeglichkeit": za.vertraeglichkeit, "score": round(za.gesamtscore, 2)},
                name_b: {"wirksamkeit": zb.wirksamkeit, "vertraeglichkeit": zb.vertraeglichkeit, "score": round(zb.gesamtscore, 2)},
                "besser": name_a if za.gesamtscore >= zb.gesamtscore else name_b,
            })
        med_a = self.db.medikamente.get(name_a)
        med_b = self.db.medikamente.get(name_b)
        return {
            "medikament_a": name_a,
            "medikament_b": name_b,
            "kosten_a": med_a.kosten_pro_einheit if med_a else None,
            "kosten_b": med_b.kosten_pro_einheit if med_b else None,
            "gemeinsame_probleme": len(vergleiche),
            "vergleiche": vergleiche,
        }

    def lueckenanalyse(self) -> dict:
        """Findet Probleme ohne Zuordnung oder mit nur schwachen Medikamenten."""
        ohne_zuordnung = []
        schwache_abdeckung = []
        for name, prob in self.db.probleme.items():
            zuordnungen = self.db.zuordnungen_fuer_problem(name)
            if not zuordnungen:
                ohne_zuordnung.append(name)
            else:
                best = max(z.gesamtscore for z in zuordnungen)
                if best < 5.0:
                    schwache_abdeckung.append({"problem": name, "bester_score": round(best, 2)})
        return {
            "ohne_zuordnung": ohne_zuordnung,
            "schwache_abdeckung": schwache_abdeckung,
        }


# ---------------------------------------------------------------------------
# CLI-Formatierung
# ---------------------------------------------------------------------------

def trennlinie(zeichen: str = "─", laenge: int = 60):
    print(zeichen * laenge)


def tabelle_ausgeben(zeilen: list[dict], spalten: list[str], header: Optional[list[str]] = None):
    """Gibt eine einfache ASCII-Tabelle aus."""
    if not zeilen:
        print("  (keine Daten)")
        return
    if header is None:
        header = spalten
    breiten = []
    for i, sp in enumerate(spalten):
        max_b = len(header[i])
        for z in zeilen:
            val = str(z.get(sp, ""))
            if len(val) > max_b:
                max_b = len(val)
        breiten.append(min(max_b, 30))

    def zeile_fmt(werte):
        teile = []
        for v, b in zip(werte, breiten):
            s = str(v)[:b]
            teile.append(s.ljust(b))
        return " │ ".join(teile)

    print("  " + zeile_fmt(header))
    print("  " + "─┼─".join("─" * b for b in breiten))
    for z in zeilen:
        werte = [z.get(sp, "") for sp in spalten]
        print("  " + zeile_fmt(werte))


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def eingabe_int(prompt: str, min_val: int, max_val: int) -> int:
    while True:
        try:
            wert = int(input(prompt))
            if min_val <= wert <= max_val:
                return wert
            print(f"  Bitte Wert zwischen {min_val} und {max_val} eingeben.")
        except ValueError:
            print("  Bitte eine ganze Zahl eingeben.")


def eingabe_float(prompt: str) -> float:
    while True:
        try:
            return float(input(prompt).replace(",", "."))
        except ValueError:
            print("  Bitte eine Zahl eingeben.")


def eingabe_liste(prompt: str) -> list[str]:
    raw = input(prompt).strip()
    if not raw:
        return []
    return [s.strip() for s in raw.split(",")]


class CLI:
    def __init__(self, db_pfad: str = "medikamente_db.json"):
        self.db = Datenbank(db_pfad)
        self.engine = VergleichsEngine(self.db)

    def hauptmenue(self):
        while True:
            print()
            trennlinie("═")
            print("  MEDIKAMENTEN-PROBLEM-VERGLEICHSTOOL")
            trennlinie("═")
            print()
            print("  [1] Medikamente verwalten")
            print("  [2] Probleme/Erkrankungen verwalten")
            print("  [3] Zuordnungen verwalten")
            print("  [4] Analyse & Vergleich")
            print("  [5] Beispieldaten laden")
            print("  [0] Beenden")
            print()
            wahl = input("  Auswahl: ").strip()
            if wahl == "1":
                self.menue_medikamente()
            elif wahl == "2":
                self.menue_probleme()
            elif wahl == "3":
                self.menue_zuordnungen()
            elif wahl == "4":
                self.menue_analyse()
            elif wahl == "5":
                self.beispieldaten_laden()
            elif wahl == "0":
                print("\n  Auf Wiedersehen!\n")
                break
            else:
                print("  Ungültige Auswahl.")

    # --- Medikamente ---

    def menue_medikamente(self):
        while True:
            print()
            trennlinie()
            print("  MEDIKAMENTE")
            trennlinie()
            print("  [1] Alle anzeigen")
            print("  [2] Neues Medikament hinzufügen")
            print("  [3] Medikament entfernen")
            print("  [0] Zurück")
            print()
            wahl = input("  Auswahl: ").strip()
            if wahl == "1":
                self.medikamente_anzeigen()
            elif wahl == "2":
                self.medikament_hinzufuegen()
            elif wahl == "3":
                self.medikament_entfernen()
            elif wahl == "0":
                break

    def medikamente_anzeigen(self):
        print()
        if not self.db.medikamente:
            print("  Keine Medikamente vorhanden.")
            return
        zeilen = []
        for m in self.db.medikamente.values():
            zeilen.append({
                "name": m.name,
                "wirkstoff": m.wirkstoff,
                "kategorie": m.kategorie,
                "kosten": f"{m.kosten_pro_einheit:.2f}€",
                "rx": "Ja" if m.verschreibungspflichtig else "Nein",
            })
        tabelle_ausgeben(
            zeilen,
            ["name", "wirkstoff", "kategorie", "kosten", "rx"],
            ["Name", "Wirkstoff", "Kategorie", "Kosten", "Rx"],
        )

    def medikament_hinzufuegen(self):
        print()
        name = input("  Name: ").strip()
        if not name:
            return
        wirkstoff = input("  Wirkstoff: ").strip()
        kategorie = input("  Kategorie (z.B. Analgetikum): ").strip()
        nw = eingabe_liste("  Nebenwirkungen (kommagetrennt): ")
        kosten = eingabe_float("  Kosten pro Einheit (EUR): ")
        rx = input("  Verschreibungspflichtig? (j/n): ").strip().lower() == "j"
        notizen = input("  Notizen: ").strip()
        med = Medikament(
            name=name, wirkstoff=wirkstoff, kategorie=kategorie,
            nebenwirkungen=nw, kosten_pro_einheit=kosten,
            verschreibungspflichtig=rx, notizen=notizen,
        )
        self.db.medikament_hinzufuegen(med)
        print(f"  '{name}' hinzugefügt.")

    def medikament_entfernen(self):
        name = input("  Name des Medikaments: ").strip()
        if name in self.db.medikamente:
            self.db.medikament_entfernen(name)
            print(f"  '{name}' entfernt.")
        else:
            print("  Nicht gefunden.")

    # --- Probleme ---

    def menue_probleme(self):
        while True:
            print()
            trennlinie()
            print("  PROBLEME / ERKRANKUNGEN")
            trennlinie()
            print("  [1] Alle anzeigen")
            print("  [2] Neues Problem hinzufügen")
            print("  [3] Problem entfernen")
            print("  [0] Zurück")
            print()
            wahl = input("  Auswahl: ").strip()
            if wahl == "1":
                self.probleme_anzeigen()
            elif wahl == "2":
                self.problem_hinzufuegen()
            elif wahl == "3":
                self.problem_entfernen()
            elif wahl == "0":
                break

    def probleme_anzeigen(self):
        print()
        if not self.db.probleme:
            print("  Keine Probleme vorhanden.")
            return
        zeilen = []
        for p in self.db.probleme.values():
            zeilen.append({
                "name": p.name,
                "schwere": f"{p.schweregrad}/5",
                "symptome": ", ".join(p.symptome[:3]),
            })
        tabelle_ausgeben(
            zeilen,
            ["name", "schwere", "symptome"],
            ["Name", "Schwere", "Symptome"],
        )

    def problem_hinzufuegen(self):
        print()
        name = input("  Name: ").strip()
        if not name:
            return
        beschreibung = input("  Beschreibung: ").strip()
        symptome = eingabe_liste("  Symptome (kommagetrennt): ")
        schwere = eingabe_int("  Schweregrad (1-5): ", 1, 5)
        notizen = input("  Notizen: ").strip()
        prob = Problem(
            name=name, beschreibung=beschreibung, symptome=symptome,
            schweregrad=schwere, notizen=notizen,
        )
        self.db.problem_hinzufuegen(prob)
        print(f"  '{name}' hinzugefügt.")

    def problem_entfernen(self):
        name = input("  Name des Problems: ").strip()
        if name in self.db.probleme:
            self.db.problem_entfernen(name)
            print(f"  '{name}' entfernt.")
        else:
            print("  Nicht gefunden.")

    # --- Zuordnungen ---

    def menue_zuordnungen(self):
        while True:
            print()
            trennlinie()
            print("  ZUORDNUNGEN (Medikament ↔ Problem)")
            trennlinie()
            print("  [1] Alle anzeigen")
            print("  [2] Neue Zuordnung erstellen")
            print("  [0] Zurück")
            print()
            wahl = input("  Auswahl: ").strip()
            if wahl == "1":
                self.zuordnungen_anzeigen()
            elif wahl == "2":
                self.zuordnung_erstellen()
            elif wahl == "0":
                break

    def zuordnungen_anzeigen(self):
        print()
        if not self.db.zuordnungen:
            print("  Keine Zuordnungen vorhanden.")
            return
        zeilen = []
        for z in self.db.zuordnungen:
            zeilen.append({
                "medikament": z.medikament_name,
                "problem": z.problem_name,
                "wirksamkeit": f"{z.wirksamkeit}/10",
                "vertraeglichkeit": f"{z.vertraeglichkeit}/10",
                "score": f"{z.gesamtscore:.1f}",
                "evidenz": z.evidenzgrad,
            })
        tabelle_ausgeben(
            zeilen,
            ["medikament", "problem", "wirksamkeit", "vertraeglichkeit", "score", "evidenz"],
            ["Medikament", "Problem", "Wirks.", "Vertr.", "Score", "Evidenz"],
        )

    def zuordnung_erstellen(self):
        print()
        med_name = input("  Medikament-Name: ").strip()
        if med_name not in self.db.medikamente:
            print("  Medikament nicht gefunden.")
            return
        prob_name = input("  Problem-Name: ").strip()
        if prob_name not in self.db.probleme:
            print("  Problem nicht gefunden.")
            return
        wirksamkeit = eingabe_int("  Wirksamkeit (1-10): ", 1, 10)
        vertraeglichkeit = eingabe_int("  Verträglichkeit (1-10): ", 1, 10)
        evidenz = input("  Evidenzgrad (hoch/mittel/niedrig): ").strip()
        anmerkungen = input("  Anmerkungen: ").strip()
        z = Zuordnung(
            medikament_name=med_name, problem_name=prob_name,
            wirksamkeit=wirksamkeit, vertraeglichkeit=vertraeglichkeit,
            evidenzgrad=evidenz, anmerkungen=anmerkungen,
        )
        self.db.zuordnung_hinzufuegen(z)
        print(f"  Zuordnung erstellt (Score: {z.gesamtscore:.1f}).")

    # --- Analyse ---

    def menue_analyse(self):
        while True:
            print()
            trennlinie()
            print("  ANALYSE & VERGLEICH")
            trennlinie()
            print("  [1] Ranking: Beste Medikamente für ein Problem")
            print("  [2] Medikamenten-Profil anzeigen")
            print("  [3] Zwei Medikamente direkt vergleichen")
            print("  [4] Lückenanalyse (unbehandelte Probleme)")
            print("  [0] Zurück")
            print()
            wahl = input("  Auswahl: ").strip()
            if wahl == "1":
                self.ranking_anzeigen()
            elif wahl == "2":
                self.profil_anzeigen()
            elif wahl == "3":
                self.direktvergleich()
            elif wahl == "4":
                self.lueckenanalyse_anzeigen()
            elif wahl == "0":
                break

    def ranking_anzeigen(self):
        print()
        prob_name = input("  Problem-Name: ").strip()
        if prob_name not in self.db.probleme:
            print("  Problem nicht gefunden.")
            return
        ergebnis = self.engine.ranking_fuer_problem(prob_name)
        if not ergebnis:
            print("  Keine Medikamente für dieses Problem zugeordnet.")
            return
        print(f"\n  Ranking für: {prob_name}")
        trennlinie()
        for i, e in enumerate(ergebnis, 1):
            balken = "█" * int(e["gesamtscore"])
            print(f"  #{i}  {e['medikament']}")
            print(f"       Wirkstoff:        {e['wirkstoff']}")
            print(f"       Wirksamkeit:      {e['wirksamkeit']}/10")
            print(f"       Verträglichkeit:  {e['vertraeglichkeit']}/10")
            print(f"       Gesamtscore:      {e['gesamtscore']:.1f}  {balken}")
            print(f"       Evidenz:          {e['evidenzgrad']}")
            print(f"       Kosten:           {e['kosten']:.2f}€")
            if e["nebenwirkungen"]:
                print(f"       Nebenwirkungen:   {', '.join(e['nebenwirkungen'])}")
            if e["anmerkungen"]:
                print(f"       Anmerkungen:      {e['anmerkungen']}")
            print()

    def profil_anzeigen(self):
        print()
        med_name = input("  Medikament-Name: ").strip()
        profil = self.engine.medikament_profil(med_name)
        if not profil:
            print("  Medikament nicht gefunden.")
            return
        print(f"\n  Profil: {profil['name']}")
        trennlinie()
        print(f"  Wirkstoff:          {profil['wirkstoff']}")
        print(f"  Kategorie:          {profil['kategorie']}")
        print(f"  Kosten:             {profil['kosten']:.2f}€")
        print(f"  Nebenwirkungen:     {', '.join(profil['nebenwirkungen']) or '-'}")
        print(f"  Durchschnittsscore: {profil['durchschnittsscore']:.1f}")
        print()
        if profil["einsatzgebiete"]:
            tabelle_ausgeben(
                profil["einsatzgebiete"],
                ["problem", "wirksamkeit", "vertraeglichkeit", "gesamtscore"],
                ["Problem", "Wirks.", "Vertr.", "Score"],
            )

    def direktvergleich(self):
        print()
        name_a = input("  Medikament A: ").strip()
        name_b = input("  Medikament B: ").strip()
        if name_a not in self.db.medikamente or name_b not in self.db.medikamente:
            print("  Eines oder beide Medikamente nicht gefunden.")
            return
        ergebnis = self.engine.vergleich_zweier_medikamente(name_a, name_b)
        print(f"\n  Direktvergleich: {name_a} vs. {name_b}")
        trennlinie()
        print(f"  Kosten: {name_a} = {ergebnis['kosten_a']:.2f}€  |  {name_b} = {ergebnis['kosten_b']:.2f}€")
        print(f"  Gemeinsame Probleme: {ergebnis['gemeinsame_probleme']}")
        print()
        if not ergebnis["vergleiche"]:
            print("  Keine gemeinsamen Probleme zum Vergleichen.")
            return
        for v in ergebnis["vergleiche"]:
            da = v[name_a]
            db_ = v[name_b]
            marker_a = " ◄" if v["besser"] == name_a else ""
            marker_b = " ◄" if v["besser"] == name_b else ""
            print(f"  Problem: {v['problem']}")
            print(f"    {name_a}: Score {da['score']:.1f} (W:{da['wirksamkeit']} V:{da['vertraeglichkeit']}){marker_a}")
            print(f"    {name_b}: Score {db_['score']:.1f} (W:{db_['wirksamkeit']} V:{db_['vertraeglichkeit']}){marker_b}")
            print()

    def lueckenanalyse_anzeigen(self):
        print()
        ergebnis = self.engine.lueckenanalyse()
        print("  LÜCKENANALYSE")
        trennlinie()
        if ergebnis["ohne_zuordnung"]:
            print("\n  Probleme OHNE Medikamenten-Zuordnung:")
            for p in ergebnis["ohne_zuordnung"]:
                print(f"    ⚠  {p}")
        else:
            print("\n  Alle Probleme haben mindestens eine Zuordnung.")

        if ergebnis["schwache_abdeckung"]:
            print("\n  Probleme mit SCHWACHER Abdeckung (Score < 5.0):")
            for s in ergebnis["schwache_abdeckung"]:
                print(f"    ⚠  {s['problem']} (bester Score: {s['bester_score']})")
        else:
            print("\n  Keine Probleme mit schwacher Abdeckung.")
        print()

    # --- Beispieldaten ---

    def beispieldaten_laden(self):
        medikamente = [
            Medikament("Ibuprofen", "Ibuprofen", "NSAID",
                        ["Magenbeschwerden", "Übelkeit", "Schwindel"], 0.15, False),
            Medikament("Paracetamol", "Paracetamol", "Analgetikum",
                        ["Leberschäden (Überdosis)", "Hautausschlag"], 0.08, False),
            Medikament("Amoxicillin", "Amoxicillin", "Antibiotikum",
                        ["Durchfall", "Hautausschlag", "Übelkeit"], 0.45, True),
            Medikament("Omeprazol", "Omeprazol", "Protonenpumpenhemmer",
                        ["Kopfschmerzen", "Durchfall"], 0.30, True),
            Medikament("Diclofenac", "Diclofenac", "NSAID",
                        ["Magenbeschwerden", "Kopfschmerzen", "Ödeme"], 0.20, True),
            Medikament("Aspirin", "Acetylsalicylsäure", "NSAID",
                        ["Magenblutung", "Tinnitus"], 0.10, False),
            Medikament("Metformin", "Metformin", "Antidiabetikum",
                        ["Durchfall", "Übelkeit", "Laktatazidose"], 0.25, True),
            Medikament("Lisinopril", "Lisinopril", "ACE-Hemmer",
                        ["Reizhusten", "Schwindel", "Hyperkaliämie"], 0.35, True),
        ]
        probleme = [
            Problem("Kopfschmerzen", "Akute oder chronische Kopfschmerzen",
                    ["Schmerz", "Druckgefühl", "Lichtempfindlichkeit"], 2),
            Problem("Rückenschmerzen", "Schmerzen im Lendenwirbelbereich",
                    ["Schmerz", "Bewegungseinschränkung", "Muskelverspannung"], 3),
            Problem("Bakterielle Infektion", "Infektion durch Bakterien",
                    ["Fieber", "Entzündung", "Schwellung"], 4),
            Problem("Sodbrennen", "Gastroösophagealer Reflux",
                    ["Brennen", "Aufstoßen", "Brustschmerz"], 2),
            Problem("Diabetes Typ 2", "Chronische Stoffwechselerkrankung",
                    ["Durst", "Müdigkeit", "häufiges Wasserlassen"], 4),
            Problem("Bluthochdruck", "Chronisch erhöhter Blutdruck",
                    ["Kopfschmerzen", "Schwindel", "Nasenbluten"], 3),
        ]
        zuordnungen = [
            Zuordnung("Ibuprofen", "Kopfschmerzen", 8, 7, "hoch", "Standardmittel"),
            Zuordnung("Paracetamol", "Kopfschmerzen", 7, 9, "hoch", "Gut verträglich"),
            Zuordnung("Aspirin", "Kopfschmerzen", 7, 6, "hoch", "Nicht bei Kindern"),
            Zuordnung("Diclofenac", "Kopfschmerzen", 6, 5, "mittel", "Eher bei starken Schmerzen"),
            Zuordnung("Ibuprofen", "Rückenschmerzen", 7, 6, "hoch", "Entzündungshemmend"),
            Zuordnung("Diclofenac", "Rückenschmerzen", 8, 5, "hoch", "Stark wirksam"),
            Zuordnung("Paracetamol", "Rückenschmerzen", 5, 8, "mittel", "Schwächer wirksam"),
            Zuordnung("Amoxicillin", "Bakterielle Infektion", 8, 7, "hoch", "Breitspektrum"),
            Zuordnung("Omeprazol", "Sodbrennen", 9, 8, "hoch", "Goldstandard"),
            Zuordnung("Metformin", "Diabetes Typ 2", 9, 7, "hoch", "Erstlinientherapie"),
            Zuordnung("Lisinopril", "Bluthochdruck", 8, 7, "hoch", "Erstlinientherapie"),
            Zuordnung("Aspirin", "Bluthochdruck", 3, 5, "niedrig", "Nur ergänzend"),
        ]

        for m in medikamente:
            self.db.medikament_hinzufuegen(m)
        for p in probleme:
            self.db.problem_hinzufuegen(p)
        for z in zuordnungen:
            self.db.zuordnung_hinzufuegen(z)

        print(f"\n  Beispieldaten geladen:")
        print(f"    {len(medikamente)} Medikamente")
        print(f"    {len(probleme)} Probleme")
        print(f"    {len(zuordnungen)} Zuordnungen")


# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import sys
    db_pfad = sys.argv[1] if len(sys.argv) > 1 else "medikamente_db.json"
    app = CLI(db_pfad)
    app.hauptmenue()
