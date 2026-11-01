# Fase 2 — DISCOVERY20 — conservatief resourceprofiel en vijandige rangen

## Vorige acceptatie
- Branch Clojure+Nederlands, SHA eb4e03efba442054b563f0fce77354afa92206ff.
- Run 41350778305 exact deze branch/SHA: verify job 124980244941 SUCCESS, Native job 124980245227 SUCCESS.
- Ruwe Native-log: 91 tests, 39139 assertions, 0 failures, 0 errors. Alleen DISCOVERY19 aanvaard; Stage 2 en de vijfdelige datum niet aanvaard.

## Contract
- Nieuwe geïsoleerde namespace pastafari.maandprofiel, functie veilige-celgrens(lengtes[,begroting]).
- Invoer: 1..47 maandlengtes 4..123, totale dagen <=5778, begroting 1..5000000, standaard 5000000.
- Uitvoer: maanden, dagen, celbovengrens (exact BigInt), begroting, budgetveilig? en looptijd-bewezen? altijd false.
- Fouten: :invalid-weaving-family, :weaving-bound-exceeded, :invalid-weaving-budget.
- De functie voert GEEN unranking uit, maakt GEEN datum en vergroot GEEN domein van de bestaande datumkiezer.
- Het veilig-predicaat is voldoende, niet noodzakelijk: false betekent onbekend, niet dat unranking onmogelijk is.

## Bewijs
Voor m maanden en N dagen (N <= 5778) evalueert de bestaande rangkiezer voor elk van de N uitvoerposities ten hoogste m kandidaatmaanden.
De kandidaatkost is 1+(m-o+1)*(R+1), met o reeds geopende maanden en R resterende dagen.
Daarom is iedere kandidaatkost <= 1+(m+1)*(N+1).
Conservatieve bovengrens C=N*m*(1+(m+1)*(N+1)). Indien C<=begroting kan de bestaande kandidaatkostboekhouding voor GEEN geldige rang het budget overschrijden.
Dit is NIET een looptijd- of BigInt-geheugengrens: aantal bitoperaties en lengte van getallen zijn niet afgeleid.

## QA en meetplan
- Onafhankelijke expliciete som over positie/kandidaat tegen gesloten bovengrens.
- Vijf adversariële lexicografische rangen (1, 2, midden, voorlaatst, laatst) op vier kleine families; onafhankelijke bounded bottom-up DP uit DISCOVERY17 dient als oracle.
- Grotere families met 6 en 8 maanden, eerste/midden/laatste rang; controle van exact maandmultipliciteiten en first-/last-hit-volgorde.
- Meet System/nanoTime per rang in GitHub Native-log, uitsluitend diagnostisch; geen tijdsdrempel of benchmarkclaim.
- Maximum 47x123 dagen moet buiten conservatieve budget-envelop vallen, zonder proberen de volledige unrank uit te voeren.
- Negatieve tests voor familie, 47/5778 grens en budget.
- Clojure Native tests, assertions en verify alleen ACCEPTED na completed/SUCCESS op de nieuwe commit.

## NEXT
Na DISCOVERY20 acceptance: DISCOVERY21 onderzoekt selectiedomein op echte binaire kostboekhouding en levert een gecontroleerde, expliciet bewezen koppeling naar de vijfdelige datum, zonder bestaande grenzen stilzwijgend te vergroten. Geen main/merge/publicatie.
