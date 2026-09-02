# Statische Prüfung der Stufe 1

## Umfang

Diese Prüfung betrifft ausschließlich den unabhängigen Bootstrap der Linie APL + Deutsch. Sie ersetzt den noch ausstehenden nativen NARS2000-Lauf nicht, schließt aber die statische Implementierungs- und Besitzprüfung vor diesem Lauf ab.

## Semantischer Zustandsbesitz

Der Produktions-Bootstrap besitzt keinen globalen veränderlichen semantischen Aufrufzustand. Jeder Aufruf trägt Eingaben, bestätigten Zustand, ausstehenden Zustand und Wiederherstellungskopie ausschließlich in seinem eigenen `MonsterContext`. Kandidaten werden aus den unveränderlichen Eingabetagen berechnet, vor dem Commit validiert und bei einem injizierten wiederherstellbaren Fehler exakt auf den letzten bestätigten Zustand zurückgesetzt. Beobachtungsdaten werden nicht in die Kandidatenberechnung eingelesen.

Die testinterne Referenz besitzt drei ausdrücklich klassifizierte globale Zustandsarten:

1. unveränderliche Konstanten und die vollständig aufgebaute Steintabelle;
2. den abgeleiteten Gate-Zwischenspeicher, der bei jedem vollständigen `CalendarDate`-Aufruf zurückgesetzt wird und einen vorhandenen Index niemals mit einem abweichenden Wert überschreiben darf;
3. DP-Arbeitsspeicher für Schnitzelpartitionen und Monatswebungen, die an jedem öffentlichen Familienaufruf neu initialisiert werden und niemals als Eingabe eines späteren unabhängigen Aufrufs dienen.

Für keine dieser Zustandsarten gibt es einen Rückkanal von Protokollen, Metriken, Fehlermeldungen oder Laufhistorie in eine normative Entscheidung.

## Reihenfolge, Wiederholung und Fehler

Das APL-Testgerüst enthält Regressionen für A→B→A, B→A→B, wiederholte identische Aufrufe, zwei getrennte Kontexte, vorbefüllte Beobachtungsdaten, null bis zwei wiederherstellbare Fehlerinjektionen sowie Erschöpfung des festen Wiederholungsbudgets. Nach Erschöpfung wird eine Fehlermeldung signalisiert; es wird keine Ersatzantwort zurückgegeben.

Für die testinterne Referenz werden außerdem die Reihenfolge der positiven und negativen Gate-Erzeugung, ein fehlgeschlagener Gate-Lesezugriff, ein abgewiesener widersprüchlicher Gate-Schreibversuch, Fehler und Folgeaufruf der beiden DP-Familien sowie Sauce-A→B→A geprüft. Eine zusätzliche Gate-Cache-Erweiterung darf die erneute Auswahl des Ankerjahres 5000 nicht verändern.

## Exakte Arithmetik

Normative Tageswerte werden nur als skalare exakte Ganzzahlen akzeptiert. 64-Bit-Ganzzahlen werden vor normativer Weiterverarbeitung in rationale Ganzzahlen umgewandelt; rationale Werte werden nur bei Nenner eins akzeptiert. Gleitkommawerte und gebrochene rationale Tageswerte werden abgewiesen. Die Monatsgrenzen wandeln auch direkt übergebene kleine Ganzzahlen vor der Division ausdrücklich in rationale Ganzzahlen um.

Alle gemischten arithmetischen Formeln wurden wegen der Rechts-nach-links-Auswertung von APL auf notwendige Klammerung geprüft. Die Steinfolge läuft ausdrücklich über die Zeilen 2 bis 46. Die Mehrfachzuweisung der vier Koeffizienten verwendet die von NARS2000 verlangte geklammerte Strand-Zuweisung.

## Katalog

Der deutsche Quellsprachkatalog enthält genau 17 Schnitzelnamen und 47 Monatsnamen. Seine Reihenfolge wird ausschließlich durch `canonicalIndex` bestimmt. Die Laufzeitvalidierung vergleicht Version, Frozen-Markierung, Indexvektoren und die vollständigen deutschen Namenslisten mit der eingebetteten Version-1-Definition. Die Negativprüfung verändert nur eine lokale Snapshot-Kopie. Alle 64 Indizes werden im Test einzeln über die Präsentationsauflösung geprüft.

## Keine Vorwegnahme späterer Stufen

Im Produktions-Bootstrap befinden sich keine Legacy-Adapter, keine späteren Patch-Konstanten, keine historischen Fehlfunktionen und kein Aufruf der testinternen Referenz. Die statische Suche nach den vorgeschriebenen späteren Narbenbezeichnern ergab keinen Treffer. Im Projekt befinden sich keine ausführbaren Hilfsprogramme in einer anderen Programmiersprache.

## Verbleibender Nachweis

Die statische Prüfung ist abgeschlossen. Noch ausstehend ist ausschließlich die native Ausführung der vorhandenen APL-Dateien in NARS2000. Erst ein grüner Lauf von `RunStage01Tests` erlaubt die Änderung von `LAST_COMPLETED_STAGE` von 0 auf 1.
