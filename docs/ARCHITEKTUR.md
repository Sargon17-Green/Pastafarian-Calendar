# Bootstrap-Architektur

## Ziel

Stage 1 errichtet nur neutrale Infrastruktur. Sie enthält keine historische Fehlannahme und keinen Code eines Patches 01–26.

## Zustandsklassen

Der Bootstrap trennt zwei Klassen strikt:

1. **Semantischer Zustand** — Eingabetage, normativ berechnete Zwischenwerte und später freizugebende Ergebnisse. Änderungen folgen dem Muster Snapshot → Berechnung → Validierung → Commit.
2. **Beobachtungszustand** — Protokolle, Metriken und Diagnoseeinträge. Diese Daten dürfen geschrieben, aber niemals in eine normative Entscheidung zurückgelesen werden.

Jeder Aufruf erhält einen eigenen Kontext. Der Bootstrap besitzt keinen globalen veränderlichen semantischen Aufrufzustand.

## Neutrale Schichten

Stage 1 enthält ausschließlich:

- einen Basiskontext;
- einen Basis-Dispatcher;
- eine Basisvalidierung;
- eine deterministische Fehlerhülle;
- eine Metrik-/Protokollhülle ohne semantische Rückwirkung.

Es gibt noch keine Legacy-Adapter, keine Kompatibilitätsflags und keinen Patch-Dispatcher.

## Oracle-Grenze

Die Datei `normative_oracle.apl` ist ausschließlich Testreferenz. Die neutrale Produktionshülle ruft sie nicht auf. Spätere Produktionspfade dürfen auch nicht auf Oracle-Ausgaben zurückfallen.

## Kataloggrenze

Intern werden Namen als `canonicalIndex` geführt. Erst die Ergebnis-/Präsentationsschicht darf einen Index in den deutschen Quelltext auflösen. Dadurch können zukünftige Übersetzungen weder Rangfolgen noch Cache-Schlüssel noch Auswahlräume verändern.
