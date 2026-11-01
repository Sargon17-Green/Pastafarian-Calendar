# Fase 2 — DISCOVERY19 — exact lexicografisch unranking met celbegroting

## Vorige poort
- Branch Clojure+Nederlands, DISCOVERY18 HEAD d9fc9904ad387d6863897a7470db8adc059b7b8f.
- GitHub Actions run 41283025367 op exact branch en SHA: Native job 124778641522 completed SUCCESS, ruwe log 88 tests / 39036 assertions / 0 failures / 0 errors; verify job 124778641649 completed SUCCESS.
- Alleen de grote telling van DISCOVERY18 is aanvaard, niet Stage 2 of de vijfdelige datum.

## Invoer/uitvoer
- Nieuwe gescheiden namespace pastafari.maandrang, functie weving-op-rang-groot(lengtes,rang[,begroting]).
- Familie volgens DISCOVERY18: 1..47 maanden, 4..123 dagen per maand, som <=5778.
- Rang is exact geheel getal 1..aantal-wevingen-groot(lengtes), resultaat lexicografisch geordende maand-ID-vector met oplopende eerste en laatste verschijningen.
- Standaardbegroting 5000000 geraamde suffix-DP-cellen. Optionele begroting 1..5000000. Overschrijding: :weaving-unrank-budget-exceeded, nooit een gedeeltelijke kalenderdatum.
- Fouten: eerdere :invalid-weaving-family en :weaving-bound-exceeded; nieuwe :invalid-weaving-rank en :invalid-weaving-budget. De datumkiezer kies-maandweving en de bestaande weving-op-rang behouden hun 5/32-grens.

## Onafhankelijke wiskundige onderbouwing
- Na een geldig voorvoegsel zijn maanden 1..o geopend en 1..c gesloten. De resterende actieve maanden c+1..o hebben geen first-hit beperking meer; hun laatste voorkomens moeten wel oplopend zijn.
- Voor actieve resterende aantallen a_1..a_q en S_i=sum(a_1..a_i) is het aantal last-hit-geordende basiswoorden B=product(i=2..q) C(S_i-1,a_i-1).
- Bewijs: keer een multisetpermutatie om, zodat last-hit-order een reverse first-hit-order wordt. De kans op deze first-hit-order is product(i=q..2) a_i/S_i; vermenigvuldig met multinomiale telling en telescopiseer.
- Voeg de eerste ongeopende maand toe in gaten u=0..T, omdat alle eerdere eerste voorkomens al in het voorvoegsel liggen. Voor volgende ongeopende maanden moet u>=p (vorige eerste positie). Laatste nieuwe letter ligt na laatste oude letter.
- Het exacte aantal b-letter-invoegingen bij eerste gat u is C(b+T-u-2,T-u); frequenties worden via prefixsommen opgebouwd. Een suffixberekening is O(m*N) BigInt-operaties en O(N) BigInt-geheugen.
- Unranking trekt suffixblokken in lexicografische maandvolgorde af; het budget telt conservatief 1+(m-o+1)*(N+1) per kandidaat. Dit begrenst geraamde cellen, NIET de volledige CPU-tijd of BigInt-bitcomplexiteit; de maximale 47/5778-variant hoeft niet onder dit budget te passen.

## Bewezen voorwerk en onafhankelijke QA
- Los Python-referentiemodel met exhaustief enumererende multisetwoorden: [4] 1/1, [4,4] 20/20, [4,5] 35/35, [4,4,4] 1301/1301, [4,4,5] 5/5 geselecteerde rangen; totaal 1362/1362. Zes maanden [4]*6: referentietelling 14760468600, laatste rang leverde 24 posities.
- Native testoracle genereert alle multisetpermutaties zonder productiepruning, filtert first/last en sorteert lexicografisch; vergelijkt kleine families, extreme rangen, 6/8-maandsgevallen en foutcodes.
- Lokale Clojure CLI niet beschikbaar: statische bron- en testschemacontrole is geen Native PASS.
- Definitieve acceptatie pas na nieuwe SHA, blob-/branch-readback, Native clojure -M:test en verify beide completed SUCCESS, plus ruwe test-/assertionaantallen zonder failures/errors.

## NEXT
Na Native-acceptatie DISCOVERY20: resourceprofilering bij adversariële rangen en bewijs van veilige selectiedomeinen; datumselectie pas na afzonderlijk bewijs en autorisatie binnen de projectregels. Geen main/merge.
