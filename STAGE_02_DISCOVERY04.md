# Fase 2 — DISCOVERY04 — 46 zichtbare druppels

Status: implementatie en tests gecommit; Native + verify op het nieuwe commit zijn vereist.

## Gecontroleerde poort

- DISCOVERY03: commit 3889ea6cf534f765dfc272e8b08b6b000ad06a78.
- GitHub Actions run 41091986909: Native 22 tests / 723 assertions / 0 failures / 0 errors; verify success.
- Een vorige PASS bewijst niet dat deze wijziging slaagt.

## Productiecontract

1. Exacte positieve werk-tellingen voor action, target, distance en connection; direction is 1, 2 of 3.
2. Verborgen index 0 staat op tijdlijn 0, index 1 op -1, ..., index 6 op -6.
3. Voor i=1..46: prev1=timeline[i-1], prev3=timeline[i-3], prev7=timeline[i-7]. De drie voorgangers worden gedurende alle elf maalbeurten niet bijgewerkt.
4. Met steen[i]=[tarwe,gerst,zout,bitter,rood], beginwaarde:
   SAVE(tarwe*action + gerst*target + zout*distance + bitter*connection + rood*direction + prev1 + 3*prev3 + 5*prev7 + i).
5. Elf exacte maalregels [a,b,c,d,soort]: [3,5,7,11,tarwe], [5,7,11,13,gerst], [7,11,13,17,zout], [11,13,17,19,bitter], [13,17,19,23,rood], [17,19,23,29,tarwe], [19,23,29,31,gerst], [23,29,31,37,zout], [29,31,37,41,bitter], [31,37,41,43,rood], [37,41,43,47,tarwe].
6. Per maalbeurt: x=SAVE(x*x + a*x + b*prev1 + c*prev3 + d*prev7 + steen[i][soort]).
7. Na elf beurten wordt de waarde aan de tijdlijn toegevoegd, als zichtbare druppel i. Alles blijft in [1,M] voor M=2^127-1.
8. Geen productie-import van het normatieve testorakel.

## QA en afsluitgrenzen

- Twee vaste inputparen met onafhankelijk berekende eerste drie, laatste twee en sommodulusankers.
- 49 dagparen rond de stichtingsdag maal 46 druppels: 2254 differentiële asserties.
- Grenscontrole en ongeldige input; extreme gehele getallen en omgekeerde chronologie.
- De vier bestaande testsuites blijven behouden.
- Native en verify zijn alleen PASS na de echte CI-log op de nieuwe SHA.
- Deze discovery bewijst niet de saus, poorten, jaren, maanden of een vijfcomponentendatum.

## NEXT

Na Native + verify op deze commit: DISCOVERY05 binnen Stage 2. Contracteer zes sauskommen,
46 mengronden, permutatie van de volgorde en 12 nabewerkingen met eigen productiecode
en afgebakende differentiële tests. Geen Stage 3; geen merge naar main.
