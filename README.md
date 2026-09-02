# Pastafarianischer Kalender — APL + Deutsch

Dieses Arbeitsverzeichnis ist die unabhängige Bootstrap-Linie für die Kombination **APL + Deutsch**. Es wurde ohne Quellcode, Tests, Fixtures, Hashwerte oder Ausgaben einer anderen Implementierung angelegt.

## Verbindlicher Stand

Der aktuelle Entwicklungsschritt ist Stage 1 von 55. In diesem Schritt werden ausschließlich die neutrale Grundarchitektur, der deutschsprachige `SourceLanguageCatalog`, die testinterne normative Referenz und das APL-Testgerüst angelegt. Historische Legacy-Fehler und spätere Patches gehören ausdrücklich noch nicht in diesen Stand.

## APL-Dialekt und Ganzzahlarithmetik

Die Referenz ist für **NARS2000 APL** geschrieben. Der Grund ist ausschließlich semantisch: rationale Ganzzahlen des Interpreters besitzen beliebige Genauigkeit und werden durch das Suffix `x` erzeugt. Dadurch bleiben `M = 2^127 - 1`, kombinatorische Zähler, Ränge und Zwischenwerte exakt. Es wird kein Fremdsprachen-Binding und keine Fremdlaufzeit als Rechenhilfe verwendet.

Normative Rechnungen dürfen niemals über Gleitkommazahlen laufen. `⎕CT` wird für die Tests auf Null gesetzt.

## Quellsprachkatalog

`src/source_language_catalog.apl` enthält 17 Schnitzel-Namen und 47 Monatsnamen. Die semantische Ordnung ist ausschließlich der feste `canonicalIndex`. Texte werden niemals sortiert oder als Rangschlüssel verwendet.

Für bedeutungstragende Wörter wird die Bedeutung ins Deutsche übersetzt. Für etablierte mesopotamische Ortsnamen werden die üblichen deutschen Formen verwendet (`Lagasch`, `Akkad`, `Eridu`, `Uruk`, `Ninive`, `Babylon`). Für erfundene Lautfolgen ohne lexikalische Bedeutung gilt eine feste deutsche Umschrift: insbesondere `ש -> sch`; dadurch werden die beiden Kunstnamen als `Palgurasch` und `Karschumab` gespeichert.

## Verzeichnisstruktur

- `src/source_language_catalog.apl` — eingefrorener Quellsprachkatalog.
- `src/normative_oracle.apl` — saubere, testinterne normative Referenz.
- `src/monster_bootstrap.apl` — neutrale Monster-Grundstruktur ohne spätere Patchlogik.
- `test/stage01_tests.apl` — APL-Testgerüst und Bootstrap-Regressions.
- `DEVELOPMENT_STAGE.md` — formaler Entwicklungsstatus.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md` — nur die tatsächlich entstandene Geschichte.
- `docs/ARCHITEKTUR.md` — Zustands- und Verantwortungsregeln des Bootstrap.
- `audit_evidence/` — lokale Laufnachweise, sobald eine NARS2000-Laufzeit verfügbar ist.

## Testaufruf

Die Quelldateien werden in einer leeren NARS2000-Workspace in der oben genannten Reihenfolge eingelesen; anschließend wird `RunStage01Tests` ausgeführt. Der erwartete Abschluss lautet `STAGE01 PASS`.

In der gegenwärtigen Ausführungsumgebung des Erstellers war keine NARS2000-Laufzeit vorhanden. Deshalb wird Stage 1 in diesem Handoff noch nicht als abgeschlossen oder grün behauptet; der Laufnachweis muss mit genau diesen APL-Dateien nachgeholt werden.
