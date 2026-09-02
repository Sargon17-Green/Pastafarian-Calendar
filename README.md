# Pastafarianischer Kalender — APL + Deutsch

Dieses Arbeitsverzeichnis ist die unabhängige Bootstrap-Linie für die Kombination **APL + Deutsch**. Es wurde ohne Quellcode, Tests, Prüfdatensätze, Hashwerte oder Ausgaben einer anderen Implementierung angelegt.

## Verbindlicher Stand

Der aktuelle Entwicklungsschritt ist Stufe 1 von 55. In diesem Schritt werden ausschließlich die neutrale Grundarchitektur, der deutschsprachige `SourceLanguageCatalog`, die testinterne normative Referenz und das APL-Testgerüst angelegt. Historische Altfehler und spätere Korrekturen gehören ausdrücklich noch nicht in diesen Stand.

## APL-Dialekt und Ganzzahlarithmetik

Die Referenz ist für **NARS2000 APL** geschrieben. Der Grund ist ausschließlich semantisch: rationale Ganzzahlen des Interpreters besitzen beliebige Genauigkeit und werden durch das Suffix `x` erzeugt. Dadurch bleiben `M = 2^127 - 1`, kombinatorische Zähler, Ränge und Zwischenwerte exakt. Es wird kein Fremdsprachen-Anbindung und keine Fremdlaufzeit als Rechenhilfe verwendet.

Normative Rechnungen dürfen niemals über Gleitkommazahlen laufen. `⎕CT` wird für die Tests auf Null gesetzt.

## Quellsprachkatalog

`src/source_language_catalog.apl` enthält 17 Schnitzel-Namen und 47 Monatsnamen. Die semantische Ordnung ist ausschließlich der feste `canonicalIndex`. Texte werden niemals sortiert oder als Rangschlüssel verwendet.

Für bedeutungstragende Wörter wird die Bedeutung ins Deutsche übersetzt. Für etablierte mesopotamische Ortsnamen werden die üblichen deutschen Formen verwendet (`Lagasch`, `Akkad`, `Eridu`, `Uruk`, `Ninive`, `Babylon`). Für erfundene Lautfolgen ohne lexikalische Bedeutung gilt eine feste deutsche Umschrift: insbesondere der entsprechende Sch-Laut wird dabei mit `sch` wiedergegeben; dadurch werden die beiden Kunstnamen als `Palgurasch` und `Karschumav` gespeichert.

## Verzeichnisstruktur

- `src/source_language_catalog.apl` — eingefrorener Quellsprachkatalog.
- `src/normative_oracle.apl` — saubere, testinterne normative Referenz.
- `src/monster_bootstrap.apl` — neutrale Monster-Grundstruktur ohne spätere Patchlogik.
- `test/stage01_fixtures.apl` — feste APL-Prüfdatensätze und Erwartungswerte.
- `test/stage01_tests.apl` — APL-Testgerüst und Bootstrap-Regressionen.
- `DEVELOPMENT_STAGE.md` — formaler Entwicklungsstatus.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md` — nur die tatsächlich entstandene Geschichte.
- `docs/ARCHITEKTUR.md` — Zustands- und Verantwortungsregeln des Bootstrap.
- `audit_evidence/` — lokale Laufnachweise, sobald eine NARS2000-Laufzeit verfügbar ist.
- `audit_evidence/STAGE01_STATIC_AUDIT.md` — abgeschlossene statische Prüfung von Dialekt, Exaktheit, Zustandsbesitz und Stufenreinheit.

## Testaufruf

Die drei Quelldateien unter `src/` werden in einen leeren NARS2000-Arbeitsbereich eingelesen; danach folgen `test/stage01_fixtures.apl` und `test/stage01_tests.apl`. Anschließend wird `RunStage01Tests` ausgeführt. Der erwartete Abschluss lautet `STAGE01 PASS`.

In der gegenwärtigen Ausführungsumgebung des Erstellers war keine NARS2000-Laufzeit vorhanden. Die Implementierungs- und Besitzprüfung ist statisch abgeschlossen; deshalb ist die native Ausführung von `RunStage01Tests` der einzige noch ausstehende Schritt. Stufe 1 wird bis zu diesem tatsächlichen Lauf dennoch nicht als abgeschlossen oder grün behauptet.
