# Ontwikkelingsgeschiedenis van het spaghettimonster

## Fase 1 — Bootstrap

### Wat is gebouwd

De implementatielijn is vanaf een lege projectboom gestart. Er is een bevroren Nederlandse brontaalcatalogus aangelegd. Daarnaast zijn alleen algemene infrastructuurlagen toegevoegd: een per-aanroepcontext, een dispatcher, invoervalidatie, foutomslag en niet-semantische metriekopslag.

Het normatieve testorakel is als afzonderlijke testnamespace rechtstreeks uit de ingebedde referentie opgebouwd. De productielaag kan het orakel niet aanroepen.

### Monsterlaag

De eerste monsterlaag is bewust neutraal. Zij maakt de latere historische groei mogelijk zonder een toekomstige fout, patch, compatibiliteitsvlag of legacyroute vooruit te lopen. De context bezit alleen algemene levenscyclus-, semantische-transactie- en observatievelden.

### Semantische veiligheid

De observatievelden worden niet teruggelezen voor normatieve beslissingen. De context wordt per aanroep opnieuw gemaakt. Er is in deze fase nog geen gedeelde veranderlijke semantische toestand.

### Historische patches

Nog geen. Geen van de zesentwintig legacyfouten of patches is in fase 1 aanwezig.
