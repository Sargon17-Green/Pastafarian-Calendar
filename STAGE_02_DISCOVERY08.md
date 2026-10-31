# Fase 2 — DISCOVERY08 — eindige poortvensters, uitbreiding en grensdagen

## Basis en reikwijdte
- Tak: Clojure+Nederlands; oudercommit 33b6b0e5ad372ce5c139dafed5cfafdf01e78781.
- DISCOVERY07 geaccepteerd via run 41179735037: native + verify completed SUCCESS; 40 tests / 4344 assertions / 0 failures / 0 errors.
- Deze discovery onderzoekt alleen bewezen poortdagen en intervallen tussen opeenvolgende poorten. Een interval is geen kalenderjaar; selectie van kalenderjaren en de vijf datumcomponenten blijven buiten scope.
- Keuzestroom, saus en afstandsformules zijn onveranderd; productieroutines importeren geen testoracle.

## Invoer, uitvoer, grenzen
- bouw-poortlijn(r): r is exact geheel in [0,128]; resultaat 2r+1 strikt stijgende dagen P(-r)..P(r), P(0)=-15055671. Vorige grens 64 is expliciet verhoogd.
- verleng-poortlijn(lijn,nieuwe-straal): structureel geldige lijn, exact geheel r' in [r,128]. Behoudt alle bestaande poorten, voegt alleen ontbrekende negatieve en positieve uiteinden toe. O(r'-r) poortafstandberekeningen, O(r') structurele controle/geheugen. Krimpen -> :cannot-shrink-gate-line; buiten [r,128] -> :invalid-gate-radius; ongeldige lijn -> :invalid-gate-line.
- poortinterval(lijn,dag): gehele dag in [P(-r),P(r)) levert {:index k :begin P(k) :eind P(k+1) :lengte P(k+1)-P(k) :positie dag-P(k)}. Links gesloten, rechts open, 42<=lengte<=963, 0<=positie<lengte. Dag P(r) heeft wel een bewezen poortpositie maar niet een bewezen sluitpoort: :gate-interval-not-proven. Buiten lijn: :day-outside-gate-window. Niet-gehele dag: :invalid-day.
- Geen onbeperkte zoekactie of impliciete extrapolatie, BigInt zonder afronding.

## Twee onafhankelijke paden
- Productie: behoud bestaande gesorteerde lijn, bereken uitsluitend nieuwe staarten met poortafstanden van DISCOVERY06; zoek grens via binaire voorganger uit DISCOVERY07.
- Oracle: normative-oracle/ensure-gate-index! bouwt eigen mutable poortstaat met apart normatief saus-/keuzepad. Alle 257 indices -128..128 differentieel vergeleken. Directe bouw voor r=128 tegen stapsgewijze uitbreiding 64->65->128. Prefixbehoud van oude 129 poorten, nulvenster->1 en idempotentie.
- Tien grensindices (-128,-127,-65,-64,-1,0,63,64,65,127): controleer het halfopen interval op begin en eind-1, lengte 42..963, oorsprong en gesloten/open grenzen.
- Afwijzing bij 129, fracties, krimpen, ongeldige lijn, ontbrekende eindpoort, buiten-vensterdagen en +/-10^101.
- Native, stage1/stage2 regressie en verify vormen de acceptatiepoort: pas na completed SUCCESS van beide jobs en uitlezing ruwe log op dezelfde commit. Geen claim voor de volledige kalender.

## NEXT
Na CI-acceptatie: DISCOVERY09 — afzonderlijk normatief contract voor kandidaat-jaaropeningen en -sluitingen, met expliciete kandidaatgrenzen, selectie en tie-breakers volgens de onafhankelijke brontekst; niet afleiden dat een poortinterval een jaar is. Geen main/merge.
