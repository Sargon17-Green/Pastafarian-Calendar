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


## DIAG02 — bewezen onmogelijkheid en echte budgetveilige profielzoekactie
- Vastgestelde ruwe run 41618280369, exact SHA 01a844177c2597c67f4f4108409a86a69bcc4bd3: verify en native completed SUCCESS; 108 tests, 42650 assertions, 0 failures en 0 errors. Werkelijke :bewezen=0, :geweigerd=7 bij 100000N: **DISCOVERY24 NIET GEACCEPTEERD**.
- Mathematische uitsluiting: bij N>=252 en m>=3 is de bestaande bovengrens N*m*(1+(m+1)*(N+1)) minstens 765828, dus **geen enkele geldige datum** kan onder 100000N als voldoende bewezen worden.
- Nieuw: maximaal 48 echte berekeningsdagen op stichtingsdag + 97*(k-24), k=0..47; echte jaar-/maandlengtekeuze, geen with-redefs; bereken bestaande veilige-celgrens op werkelijke lengtes. Log werkelijk onderzochte aantal, veilig aantal, minimumgrens en echt bewezen aantal.
- Alleen ALS de berekende bovengrens voor een bepaald profiel <=5000000N, roep de echte vijfveldige productie aan op berekeningsdag plus eerste/midden/laatste dag van het werkelijke jaar. Vergelijk elk geaccepteerd geval met de **onafhankelijke** canonical oracle; controleer alle vijf integers en de gerapporteerde celbovengrens. Dit verhoogt de *eerder ingestelde productieplafond* niet en omzeilt de productiebudgetpoort niet. Stop na de eerste succesvolle reeks.
- Verwacht resultaat van een groene diagnose met nul echte bewijzen: alleen een meetresultaat, **geen** acceptatie van DISCOVERY24 of Stage 2. Positief vereist minstens 1 echt geaccepteerd en oracle-identiek paar plus beide completed CI jobs op dezelfde SHA. Bij nul: gebruik gemeten minimum/jaar-/maandlengtes voor een afgebakende volgende algoritmische stap; geen blinde budgetverhoging.
- Native workflow heeft een absolute tijdgrens van 20 minuten. Geen main, merge, publicatie of algemene datumclaim.


## DIAG03 — exacte eerste-jaardag zonder volledig maandwoord
- Geinspecteerde run 41712627360, SHA 9c6c5678d45b1e055ff2e263c7663f6d0e5f8b7f: native+verify completed SUCCESS, 110 tests / 42749 assertions / 0 failures / 0 errors. 48 echte profielen, 0 budgetveilig, 0 bewezen, minimale bovengrens 9883881900N; bestaande E2E 0 bewezen / 7 geweigerd. DISCOVERY24 NIET GEACCEPTEERD.
- Wiskundig: elk geldig maandwoord opent maand 1 als eerste letter. Op de eerste jaardag is de maand-ID daarom 1 en dag-in-maand 1, ongeacht de dure volledige weving.
- Een aparte opt-in kies-eerste-dag-zonder-weving kiest een echt bewezen jaar, de eerste kotelet en de eerste maandnaam. Invoer is poortlijn, berekeningsdag, doeldag, zoekbudget; doel moet eerste jaardag zijn of expliciete weigering. Uitvoer: precies vijf integers, :date-proof-scope :first-day-only, :month-weaving-computed? false. Productie wevingrang, budgetpoort en bestaande algemene kies-bewezen-datum blijven ongewijzigd.
- Independent oracle in tests berekent het doeljaar, de koteletten, de maandlengtes en maandnamen langs de normatieve route zonder het volledige woord. Test: kleine lexicografische families, drie echte berekeningsdagen, gelijkheid van vijf getallen, fout op tweede jaardag, geen maandwoord.
- Dit bewijst alleen een beperkte subdomeinprojectie, NIET automatisch de volledige canonieke end-to-end-gate, volledige Stage 2 of universele datum. Native+verify op de nieuwe SHA vereist voordat DIAG03 aanvaard kan worden. Geen main/merge/publicatie of willekeurige begrotingsverhoging.
