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


## DIAG04 — exact einde van het jaar, zonder volledige maandweving
- DIAG03 accepted only within first-day scope: run 41776373647, SHA 608a1dbbb410cc244c798195aff34c58fe4a6b59, both native/verify completed SUCCESS, raw native 112 tests/42778 assertions/0 failures/0 errors, 3/3 real first-day equalities. Full E2E 0 proven/7 rejected; DISCOVERY24 and Stage 2 remain OPEN.
- The normative last-occurrence constraint closes month IDs in increasing order. Thus every valid weaving ends with ID m, and its final day-in-month is length[m]. This fact is independent of the lexicographic rank and avoids generating the full weaving.
- A separate opt-in production kies-laatste-dag-zonder-weving computes the exact five numeric fields for the final year day from real proven year/cutlets/month-lengths and independently selected month names. Its target MUST equal :close-gate-day, otherwise :target-not-last-day-of-year. Output is labeled :date-proof-scope :last-day-only, :month-weaving-computed? false.
- Production does not modify kies-bewezen-datum, existing budget gate or rank algorithm. No universal claim, no skipping the general budget refusal.
- Independent normative test covers five actual year-end dates (years 4999, 5000, 5001 and two shifted calculation days), full five-field equality, second-to-last-day refusal, the absence of full weaving, plus small independent legal weaving ranks. A separate exhaustive JS finite-state model checks first/last month ID and final last-month occurrence counts for small families; this is MODEL QA only.
- Native acceptance requires both jobs completed SUCCESS on the new SHA and raw assertion counts. Even after accepting DIAG04, full canonical E2E and Stage 2 remain open. No main/merge/publish.


## DIAG05 — de tweede jaardag via een geteld lexicografisch prefix
- DIAG04 LIMITED ACCEPTED: run 41790902114 on SHA 7331866caf75736ed9ff1e2a82b02cf2b5ffb279, both Native+verify completed SUCCESS, 114 tests / 42837 assertions / 0 failures / 0 errors; five real independent last-day comparisons equal. General E2E 0 proven / 7 refused. DISCOVERY24 and Stage 2 OPEN.
- The mandatory first ID is 1; the second ID is necessarily 1 or 2. Exact count of words prefixed [1,1] is the lexicographic boundary. A rank at/below that boundary yields second ID 1 (day-in-month 2); a rank above yields ID 2 (day-in-month 1). No full weaving is needed.
- A separate opt-in in maandrang uses the already established exact remaining-state counter on state after prefix [1,1]. The local upper bound is checked BEFORE the block is counted, with the existing ceiling of 5000000 cells. This is NOT a global full-unrank guarantee, nor a runtime/memory bound.
- A separate opt-in in datumprojectie chooses real proven year/cutlets/lengths, genuine rank from bowl 4/seal 32, the two-letter prefix, and independent month names from bowl 5/seal 33. It emits five integers only for the second year day, plus explicit scope, budget and non-weaving metadata; other days and insufficient local budgets are rejected. Existing generic API and its budget refusal remain unchanged.
- Independent oracle tests use complete small legal words for four families with boundary ranks. Three genuine calculation days test structurally valid five fields, bounded partial rank, no full weaving and refusal for day three. The full normative E2E oracle is NOT run on the genuine second-day examples; therefore a green job is limited-scope DIAG05, not full canonical E2E proof.
- Acceptance: verify balanced Clojure delimiters, GitHub commit/blob readback, then BOTH completed SUCCESS jobs on the same new SHA plus raw native counts and expected test outputs. No main, merge or publishing. Do not claim full DISCOVERY24 or Stage 2 PASS until at least one complete budget-safe canonical E2E differential is demonstrated.


## DIAG05 — beperkt geaccepteerd; DIAG06 — nieuwe prefixdiagnose
- Exacte CI 41870752854, SHA 98189653a25df413db384d026f3831f56649e4b4: native en verify completed SUCCESS. Ruwe native log: 117 tests, 43009 assertions, 0 failures, 0 errors. Drie echte tweede jaardagen gaven prefix [1,2] en begrensde kosten 190936N, 117745N en 151660N. De generieke E2E-gate blijft **0 bewezen / 7 geweigerd**. Alleen DIAG05 is binnen zijn beperkte domein geaccepteerd.
- DIAG06 ontwikkelt afzonderlijk een exacte eerste-drie-tekens-lexicografische maandprefixfunctie, met **gecumuleerde** bestaande bovengrens 5000000N vóór iedere suffix-telling. Geen volledig maandwoord, geen wijziging van de algemene datum-API, geen begrotingsverhoging.
- Invoer: geldige maandlengten 4..123, twee of meer maanden; een 1-gebaseerde rang binnen het exacte aantal legale woorden; prefixcelbudget 1..5000000. Uitvoer: maand-ID op positie 3, voorkomens tot en met die positie, drieletterprefix, betaalde celbovengrens en expliciete :third-day-prefix-only-scope. Ongeldige rang/te klein budget/fout doel-dag geven expliciete afwijzing.
- Onafhankelijke normatieve oracle: volledige wevingen op vier KLEINE families tegen ranggrenzen; op drie ECHTE berekeningsdagen een tweede implementatie van jaar, koteletten en maandnamen, maar **NIET** onafhankelijke volledige lexicografische maandweving. De echte vergelijkingen zijn dus *gedeeltelijke* canonieke vergelijkingen, geen volledig bewezen E2E.
- Acceptatie DIAG06 uitsluitend na statische broncontrole, commit- en blob-readback, exact-SHA native+verify completed SUCCESS én ruwe aantallen/diagnoselog met drie geldige echte derde-dag-projecties. Zelfs bij groen: DISCOVERY24 en Stage 2 blijven OPEN tot volledige budgetveilige canonical E2E-differential.
- Geen main, merge, publicatie, universele datumclaim of onbegrensde cijfer-/tijdskosten.
