# Korrektur kanonischer Namen — APL + Deutsch

Datum: 13. September 2026

Diese Korrektur gleicht den deutschen Quellsprachkatalog an die verbindliche hebräische Scroll-Semantik an. Sie ändert ausschließlich sprachliche Bezeichnungen; `canonicalIndex`, Reihenfolge, Kalenderarithmetik und Entwicklungsstufe bleiben unverändert.

## Verbindliche Namen an den betroffenen Indizes

### Schnitzel

- `canonicalIndex 6` — `Vier Teile von Neun`
- `canonicalIndex 8` — `Papyrusstaude`
- `canonicalIndex 9` — `Cluster`
- `canonicalIndex 17` — `Das leere Gefäß`

### Monate

- `canonicalIndex 7` — `Drei Teile von Fünf`
- `canonicalIndex 30` — `Pech`
- `canonicalIndex 31` — `Lampe`
- `canonicalIndex 36` — `Susa`

Bewusst unverändert bleiben insbesondere `Karschumav` (`canonicalIndex 8` der Monate), `Leopard` (`canonicalIndex 9`) und `Nebel` (`canonicalIndex 11`).

Die eingebettete Katalogvalidierung sowie die zugehörigen Stage-1-Fixtures und Tests werden gemeinsam aktualisiert. Der Aktualisierungslauf prüft anschließend die Kataloggrößen 17/47, die festen Indexvektoren, die Zielnamen an ihren Indizes, eine Negativsuche nach den ersetzten aktuellen Formen und `git diff --check`.

Ein nativer NARS2000-Lauf wird durch diese Datei nicht vorgetäuscht: Falls keine automatisierbare NARS2000-Testumgebung vorhanden ist, bleibt `RunStage01Tests` als nativer Laufnachweis separat auszuführen.
