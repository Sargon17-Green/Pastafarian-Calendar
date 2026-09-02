# Spaghetti-Entwicklungsgeschichte

## Stufe 1 — Bootstrap

### Was zu diesem Zeitpunkt existiert

Die Implementierung beginnt in einem leeren Projekt. Es existiert nur die neutrale Grundstruktur: Basiskontext, Dispatcher, Validierung, Fehlerhülle sowie nicht-semantische Metrik- und Protokollfelder. Die normative Referenz wird testintern neu in APL aus dem eingebetteten Regelwerk formuliert.

### Sprachkatalog

Der deutsche `SourceLanguageCatalog` wird mit festen `canonicalIndex`-Werten eingefroren. Bedeutungen werden übersetzt; etablierte Eigennamen erhalten ihre deutsche Form; die erfundenen Lautfolgen werden deterministisch umgeschrieben. Textsortierung darf die normative Reihenfolge nicht beeinflussen.

### Historische Fehler

Noch keiner. Die 26 vorgeschriebenen Fehlannahmen werden nicht vorweggenommen. Ihre Geschichte beginnt erst mit den jeweiligen Entdeckungsstufen.

### Monster-Schicht dieses Schritts

Nur die neutrale Verwaltungsgrundlage. Sie ist semantisch inert und besitzt noch keinen Alt- oder Korrekturpfad.

### Zustandsbesitz

Vor dem nativen Lauf wurde die neutrale Zustandsgrenze vollständig geprüft. Produktionszustand gehört immer genau einem Aufrufskontext und durchläuft `committed` → `pending` → Validierung → Commit beziehungsweise exakte Wiederherstellung. Der testinterne Gate-Cache ist ausschließlich aus dem Gate-Index ableitbar, widersprüchliche Überschreibungen sind verboten, und vollständige Kalenderaufrufe setzen ihn zurück. Die beiden DP-Arbeitsspeicher werden an jedem öffentlichen Familienaufruf neu aufgebaut. Fehler-, Metrik- und Protokollzustand ist nicht semantisch.
