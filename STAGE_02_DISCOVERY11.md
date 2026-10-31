# Fase 2 — DISCOVERY11 — aantal koteletten in een bewezen doeljaar

## Bewezen vertrekpunt
- Tak `Clojure+Nederlands`; ouder-HEAD `1f66a29bb3bb4badd2400e65adddbd7ca175fcb9`.
- DISCOVERY10: run 41193579365 Native 51 tests/4983 assertions/0 failures/0 errors; verify completed SUCCESS.
- De onafhankelijke norm staat in `test/pastafari/normative_oracle.clj`: `find-target-year`, `sauce` en `choose-cutlet-count`. Productie laadt deze namespace niet.
- Fase 2 als geheel en de vijf uiteindelijke datumcomponenten blijven onvoltooid.

## Invoer en uitvoer
- Productie `pastafari.koteletaantal/kies-aantal(lijn, berekeningsdag, doeldag[, budget])`.
- `lijn` heeft maximaal poortstraal 128 (257 poorten); dagen zijn exacte gehele getallen; `budget` is 0..128, standaard 128.
- Bepaal uitsluitend met `doeljaar/vind-doeljaar` het bewezen doeljaar met jaarinterval `open < doeldag <= close`.
- Het tussentijdse resultaat heeft precies `{:year bewezen-jaar :cutlet-count gekozen-aantal :candidate-count kandidaten-aantal}`; dit is niet de vijfdelige datum.
- `kandidaat-aantallen(p)` geeft de strikt oplopende lijst `[6,7,...,min(17,p)]`, waarbij `p = close-gate-index - open-gate-index`; geldige poortgatargumenten zijn gehele 0..256. `p<6` heeft geen kandidaat.

## Algoritmisch contract
1. Hergebruik de begrensde zoekactie voor het jaar; geen onbegrensde scan of stilzwijgende extrapolatie.
2. De structurele dag is exact `open-gate-day+1`, ongeacht waar de doeldag binnen dat jaar ligt. Bereken onafhankelijk in productie `werk-tellingen(berekeningsdag, structurele-dag)`, verborgen en zichtbare druppels, zes sauskommen.
3. Vraag **kom 2, zegel 20** op met `keuzestroom/vraag-kom`.
4. Bepaal 1-based keuzerang met `keuzestroom/kies-rang(stroom, aantal-kandidaten)`, en selecteer uit de oplopende lijst.
5. Geen oracle-code/fixtures in productie; deze fase kiest uitsluitend de cardinaliteit, geen partitie of namen.

## Fouten en budget
- Ongeldige p: `:invalid-gate-gap-count`; p < 6: `:no-cutlet-candidates`.
- Ongeldige dagen/poortlijn, ontbrekend jaarbewijs en overschreden stappenbudget behouden bestaande foutcodes van `doeljaar`.
- Poortstraal <=128, <=128 jaarovergangen; kandidaatlijst <=12 en 6..17. Exacte BigInt-dagen mogelijk; geen loops buiten reeds begrensde bouwstenen.

## Acceptatietoetsen
- Drie berekeningsdagen rond stichtingsdag (-157, 0, +413), drie doeljaren (vorig, 5000, volgend), eigen normatieve gate-state en saus voor elk doel; vergelijk jaar en koteletaantal.
- Directe versus incrementeel uitgebreide poortlijn; onafhankelijk resultaat; bewijs van 6..min(17,p).
- Exacte open/close-dag en nulbudget. Kandidaatvolgorde bij 6,17,256 gaten en foutsituaties 0,5,-1,257,2.5,nil,10^101.
- Bij geïsoleerde selectie: kom=2, zegel=20, eerste en laatste rang; geen afhankelijkheid van de normatieve implementatie in productie.
- Fouten: negatief/te groot/niet-geheel/nil budget, niet-gehele dagen, ongeldige poortlijn, onbewezen venster en 10^101 doeldag.
- Statische balans, readback en lease op HEAD vóór Native; alleen completed SUCCESS voor Native `clojure -M:test` plus `verify` op dezelfde SHA en ruwe assertions-log staan deelacceptatie toe. Queued/in_progress is geen PASS.

## NEXT na bewijs
DISCOVERY12: onderzoek de exacte partitie van het bewezen aantal koteletten over de poortgaten met verplichte interne poortgrens waar vereist, zegel 21 en onafhankelijke compositie-oracle. Formuleer een eindig budget en afzonderlijk acceptatiecontract; geen main/merge en geen volledige datumclaim.
