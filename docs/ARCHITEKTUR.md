# Bootstrap-Architektur

## Ziel

Stufe 1 errichtet ausschließlich neutrale Infrastruktur. Sie enthält keine historische Fehlannahme und keinen Code der späteren Korrekturen 01–26.

## Zustandsklassen

Der Bootstrap trennt zwei Klassen strikt:

1. **Semantischer Zustand** — Eingabetage, der letzte bestätigte Zustand, ein noch nicht bestätigter Kandidat und ein Rollback-Snapshot. Änderungen folgen ausschließlich dem Muster Snapshot → Berechnung → Validierung → Commit.
2. **Beobachtungszustand** — Protokolle, Metriken, Trace-Einträge und Wiederherstellungszähler. Diese Daten dürfen geschrieben, aber niemals in eine normative Entscheidung zurückgelesen werden.

Jeder Aufruf erhält einen eigenen 18-Felder-Kontext. Es existiert kein globaler veränderlicher semantischer Aufrufzustand. Die globalen Namen in `monster_bootstrap.apl` bezeichnen ausschließlich feste Feldpositionen und die feste Feldanzahl.

## Besitzregel

Der Besitzer jedes veränderlichen semantischen Werts ist genau ein Aufrufskontext. `CTX_COMMITTED`, `CTX_PENDING` und `CTX_ROLLBACK` gehören niemals einem Registry-Objekt und werden nicht zwischen Aufrufen geteilt.

Eine neutrale Transaktion arbeitet wie folgt:

1. Kopie von `committed` nach `rollback`;
2. deterministische Kandidatenberechnung ausschließlich aus den beiden unveränderlichen Eingabetagen;
3. Ablage in `pending`;
4. unabhängige Validierung des Kandidaten;
5. entweder atomarer Commit nach `committed` oder exakte Wiederherstellung aus `rollback`;
6. Leeren von `pending` und `rollback` vor jeder Rückkehr.

Ein Wiederholungsversuch verwendet denselben Eingang und denselben Algorithmus. Retry-Zähler, Metriken, Protokolle und Trace-Einträge werden nicht in die Kandidatenberechnung eingelesen. Bei erschöpftem Budget bleibt der letzte bestätigte Zustand unverändert; es gibt keine Ersatzantwort.

## Eigentumsregressionen

`RunStage01OwnershipTests` prüft getrennt:

- A→B und B→A liefern für A beziehungsweise B denselben semantischen Zustand;
- wiederholte Ausführung desselben Eingangs ist semantisch identisch;
- erneute Ausführung eines bereits erfolgreichen Kontexts bleibt semantisch identisch;
- 0, 1 und 2 deterministisch injizierte wiederherstellbare Fehler enden mit demselben erfolgreichen semantischen Zustand;
- eine dritte Injektion überschreitet das feste Retry-Budget, liefert keine Ersatzantwort und stellt den letzten Commit exakt wieder her;
- `pending` und `rollback` sind nach Erfolg und nach Erschöpfung leer;
- vorbefüllte Metriken und Protokolle ändern das semantische Ergebnis nicht;
- die Ausführung eines Kontexts verändert keinen anderen Kontext.

## Neutrale Schichten

Stufe 1 enthält ausschließlich:

- einen Basiskontext;
- einen Basis-Dispatcher;
- eine Basisvalidierung;
- eine deterministische Fehlerhülle;
- eine neutrale Snapshot-/Commit-/Rollback-Transaktion;
- eine Metrik-/Protokollhülle ohne semantische Rückwirkung.

Es gibt noch keine Legacy-Adapter, keine Kompatibilitätsflags und keinen Korrektur-Dispatcher.

## Grenze der normativen Referenz

Die Datei `normative_oracle.apl` ist ausschließlich Testreferenz. Die neutrale Produktionshülle ruft sie nicht auf. Spätere Produktionspfade dürfen ebenfalls nicht auf Referenzausgaben zurückfallen.

Die vollständige Referenz setzt ihren Gate-Arbeitszustand zu Beginn jedes vollständigen `CalendarDate`-Aufrufs zurück. Dadurch ist Cache-Historie kein semantischer Eingang. Die DP-Memos für Schnitzelpartition und Monatswebung werden an ihren jeweiligen öffentlichen Einstiegen ebenfalls neu initialisiert.

Der Gate-Arbeitszustand ist ein abgeleiteter, indexgeschützter Cache: Ein fehlender Index darf einmal aus seinem deterministischen Vorgänger und der normativen Gate-Frage erzeugt werden. Existiert der Index bereits, ist nur derselbe Tageswert zulässig; ein widersprüchlicher Schreibversuch wird als Invariantenfehler abgewiesen. Für die Ankerjahresauswahl werden aus einem eventuell weiter gewachsenen Cache nur Gates innerhalb `calculationDay ± 5778` betrachtet. Da jedes gültige Kandidatenjahr den Berechnungstag enthält und höchstens 5778 Tage lang ist, kann kein gültiger Kandidat dadurch entfernt werden.

Die statische Besitzprüfung klassifiziert sämtliche globalen Referenzwerte ausdrücklich als unveränderliche Konstanten, deterministisch abgeleiteten Gate-Cache oder pro öffentlichem DP-Einstieg zurückgesetzten Arbeitsspeicher. Es gibt in Stufe 1 keinen Callback-, Coexpression- oder Parallelpfad, der zwei unabhängige DP-Eigentümer gleichzeitig in denselben Arbeitsspeicher führen könnte.

## Exakte Ganzzahlen

Sowohl die Produktionsgrundlage als auch die Referenz weisen Gleitkomma-Tageswerte und gebrochene Rationalwerte zurück. Zulässige 64-Bit-Ganzzahlen werden vor weiterer Verarbeitung in rationale Ganzzahlen des NARS2000-APL-Interpreters umgewandelt. Rationale Ganzzahlen werden nur akzeptiert, wenn ihr Nenner genau eins ist.

## Kataloggrenze

Intern werden Namen als `canonicalIndex` geführt. Erst die Ergebnis-/Präsentationsschicht darf einen Index in den deutschen Quelltext auflösen. Der Katalog besitzt zusätzlich eine Laufzeitvalidierung gegen seine fest eingebettete Version-1-Definition; eine Veränderung wird als Fehler erkannt und darf nicht still in die Semantik einfließen.
