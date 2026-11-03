# Fase 2 — DISCOVERY24 — gecontroleerde echte end-to-end-datumdifferential

## Bewezen uitgangspunt
- Branch: Clojure+Nederlands. Parent HEAD: 694ecfe3aeab6eb42e17246eb4ca5c72703082cf.
- DISCOVERY23: GitHub run 41537641476, native job 125593457712 en verify 125593457389 completed SUCCESS op dezelfde commit. Ruwe native log: 106 tests, 42639 assertions, 0 failures, 0 errors.
- Stage 2 is OPEN. Geen universele vijfveldige datumclaim.

## Afgebakende onderzoeksvraag
Draait de huidige echte opt-in-keten zonder test-stubs voor een eindige selectie rond de eerste drie doeljaren, en komen de vijf numerieke velden overeen met de zelfstandige normatieve kalenderberekening wanneer de bewezen celbegroting dit toelaat?

## Invoer en meetbaar resultaat
- Eén echte, bewezen poortlijn: bouw-poortlijn(128N). Rekendag: stichtingsdag en +/-17/23 dagen.
- Zeven gerichte paren: eerste/middelste/laatste dag van jaar 5000, laatste dag 4999, eerste dag 5001, en twee nabije rekendag/doeldag-paren.
- De bestaande productiefunctie kies-bewezen-datum wordt zonder with-redefs aangeroepen met zoekbudget 128N en celbudget 100000N; geen nieuwe productielogica en geen rekenbudgetverhoging zonder bewijs.
- Voor elk werkelijk geaccepteerd paar: precies vijf gehele velden, celgrens <=100000N en gelijkheid met normative-oracle/calendar-date-canonical op dezelfde twee echte dagen (ook de oracle gebruikt geen stubs).
- Voor weigering: expliciete :weaving-unrank-budget-unproven. Daarnaast budget=1N met een echte poortlijn als afzonderlijke fail-closed-proef.
- De test logt aantallen :bewezen en :geweigerd. **Een groene test met nul :bewezen is diagnostiek, geen acceptatie van echte E2E-differential**.

## Grenzen en gates
- Native testtijd wordt begrensd door de bestaande workflow (20 minuten); geen onbeperkte scan van jaren of kalenderdagen.
- Eerste gate: syntactische balans voor test/runner, GitHub commit en 5/5 blob-readback, branch HEAD-lease.
- Tweede gate: één push-gestarte CI, completed SUCCESS van native + verify op precies dezelfde SHA en ruwe aantallen.
- Derde gate: minimaal één daadwerkelijk :bewezen geval met onafhankelijke oracle-gelijkheid. Bij nul successen: vergroot niet blindelings het budget, maar bepaal welk jaar-/maandprofiel binnen het bewezen DP-budget valt en vervolg als DISCOVERY24-diagnose.
- Alleen bij alle gates DISCOVERY24 accepteren. Geen claim op Stage 2 / publieke universele API.
- Geen main, merge of externe publicatie.

## NEXT
Inspecteer de ruwe CI-log van DISCOVERY24. Als een geval faalt: herstel de aantoonbare oorzaak in deze tak. Bij nul werkelijk bewezen paren: diagnoseer een eindig, reproduceerbaar budgetveilig profiel en voer echte E2E-differential uit voordat DISCOVERY24 wordt geaccepteerd. Bij groen Native en >=1 bewezen differential: breid de bewezen randgevallen gecontroleerd uit.
