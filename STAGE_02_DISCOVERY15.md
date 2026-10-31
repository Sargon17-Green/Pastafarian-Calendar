# Fase 2 — DISCOVERY15 — bewezen jaarduur en maandaantal

## Voorganger en grens
- Branch Clojure+Nederlands, ouder-HEAD bdbbd4c719300b6a529e5935cf372ad129677a25. DISCOVERY14 run 41222410431 Native 70 tests, 9631 assertions, 0 failures, 0 errors; verify SUCCESS.
- Geen vijfdelige datum, geen Stage2-PASS.

## Eindig contract
- mogelijke-maandaantallen(jaar) vereist twee gehele jaarpoortdagen met duur 252..5778.
- Resultaat is de stijgende vector van alle m met 3 <= m <= 47, 4m <= duur <= 123m. Zo bestaan er m maandlengtes van elk 4..123 die samen precies duur opleveren.
- Productie gebruikt een begrensde filter over de gehele familie 3..47, niet de normatieve ceil/floor-implementatie.
- kies-maandaantal(lijn,berekeningsdag,doeldag[,budget]) roept eerst de bewezen DISCOVERY14-grenzen aan. Structurele saus is op de eerste dag na de open-jaarpoort; keuze via kom 3, zegel 30, eengebaseerde rang.
- Retourneer alle eerdere velden onveranderd plus :month-count en :month-count-options. Nog geen maandlengtes, weving of namen.

## Onafhankelijke toets
- Normatieve formule: ondergrens ceil(duur/123), bovengrens min(47,floor(duur/4)); de bewezen jaarduur verzekert een minimum van drie.
- Vergelijk alle 5527 jaarduren (252..5778); controleer niet-lege familie en alle elementgrenzen, start 3..47 bij 252 en enige 47 bij 5778.
- Test via twee geregelde rangen op kom 3/zegel 30; drie rekenmomenten maal drie doeljaren, onafhankelijke normatieve saus, directe en verlengde poortlijn, behoud van de cutlets.
- Foutcode :invalid-year-duration bij verkeerde duur of niet-integer; eerdere foutcodes onveranderd. Geen onbegrensde iteratie.

## Acceptatiepoort
- Static Clojure preflight, onafhankelijke formule-ankercontrole, GitHub six-file atomic commit en blob/readback.
- Native clojure -M:test en verify op dezelfde commit beide completed SUCCESS, ruwe aantallen tests/assertions en nul fouten. Queued/in_progress is geen PASS.
- Geen main/merge of kalender-PASS.

## NEXT
Na DISCOVERY15-acceptatie: DISCOVERY16 — exact rangschikken van maandlengtecomposities (4..123 dagen) met normatieve onafhankelijke oracle; binnen bewezen jaar en zonder volledige kalenderdatum.
