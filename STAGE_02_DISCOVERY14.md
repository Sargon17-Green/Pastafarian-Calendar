# Fase 2 — DISCOVERY14 — bewezen koteletgrenzen

## Voorganger en scope
- Tak Clojure+Nederlands; ouder-HEAD 4cfb4485b180a0a807a0b28d65b13ad665bac90c.
- DISCOVERY13 geaccepteerd: run 41212294736, Native 66 tests / 8797 assertions / 0 failures / 0 errors; verify SUCCESS.
- Nog geen vijfdelige datum of volledige Stage2-PASS.

## Eindig input-/outputcontract
- materialiseer-koteletten neemt een bewezen eindige poortlijn en een bestaand DISCOVERY13-resultaat: :year, :partition, :cutlet-count, :name-indices en optionele :required-boundary.
- Retourneer alle oorspronkelijke velden en :cutlets, een vector in deelvolgorde. Elk deel bevat exact :name-index, :open-gate-index, :close-gate-index, :first-day en :last-day.
- Grenzen van deel j zijn de cumulatieve som van de voorgaande positieve poortgaten vanaf de jaar-open-index, en die som plus partition[j]; de daggrenzen zijn P(open)+1 en P(close).
- Alle poortindices moeten aanwezig zijn in dezelfde geverifieerde lijn, met exacte gelijkheid van jaar-open/close-dagen; geen extrapolatie of nieuwe poorten.
- kies-koteletten(lijn,berekeningsdag,doeldag[,budget]) roept eerst DISCOVERY13 aan en materialiseert. Geen normatieve orakelcode in productie.

## Onafhankelijk orakel en testbare grenzen
- Het vooraf bestaande onafhankelijke normative-oracle/materialize-cutlets materialiseert iteratief vanuit een apart poortwoordenboek; niet via de productiecode.
- Alle kleine positieve composities met 6..9 poortgaten en 6..min(8,gaten) delen worden op een synthetische lijn met 17 bekende poorten vergeleken met dat orakel; controleer behoud van invoer, eerste/laatste dag en naadloze aansluiting.
- Drie rekenmomenten x drie doeljaren: vergelijking van normatief jaar, partitie, namen en elk materialiseerd deel; vergelijk direct opgebouwde poortlijn met verlengde poortlijn.
- :invalid-cutlet-materialization voor ongeldige structuur/som; :invalid-cutlet-name-indices voor verkeerde namen; :invalid-cutlet-required-boundary voor ontbrekende verplichte interne grens; :invalid-proven-year voor afwijkende jaargrens. Fouten :invalid-gate-line en :gate-index-outside-window en upstream errors blijven gelden.
- Exacte gehele getallen, 6..17 delen en maximaal 256 poortgaten; geen open zoeklus.

## Acceptatie
- Eerst structurele Clojure delimiters en blob/source readback plus branch lease.
- Nieuwe SHA alleen aanvaarden na GitHub Actions Native clojure -M:test én verify, beide completed SUCCESS op dezelfde SHA, met ruwe test-/assertionaantallen en nul failures/errors.
- queued/in_progress betekent geen PASS, maar is geen blokkade. Geen main/merge of publicatie.

## NEXT
Na DISCOVERY14-acceptatie: DISCOVERY15 met eindig contract voor het aantal maanden uit de bewezen jaarduur (3..47 maanden, maandlengte 4..123 dagen), aparte sauskeuze en onafhankelijk normatief orakel. Geen volledige kalenderdatum.
