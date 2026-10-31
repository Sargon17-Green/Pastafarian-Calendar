# Fase 2 — DISCOVERY16 — exacte maandlengtes (4..123)

## Basis
- Clojure+Nederlands. DISCOVERY15 HEAD a3d945e8e3285b496fea8e15a3160d66aae801cc: GitHub run 41223113191 completed SUCCESS, Native 75 tests / 31801 assertions / 0 failures / 0 errors, verify SUCCESS.
- Stage 2 is nog niet voltooid; geen maandweving, namen of vijfdelige datum.

## Invoer/uitvoer en grens
- `aantal-lengtereeksen(duur, maanden)`: exacte BigInt-telling voor 1..47 delen, elk 4..123, duur 4..5778 en haalbaar. Geen kalenderpoort nodig voor deze generieke helper.
- `lengtes-op-rang(duur, maanden, rang)`: eengebaseerde lexicografische compositie, ongeldig: `:invalid-month-length-rank`.
- `kies-maandlengtes(lijn,berekeningsdag,doeldag[,budget])`: erft bewezen jaar, koteletgrenzen en maandaantal uit DISCOVERY15; structurele saus op dag na open jaarpoort; kom 3 / zegel 31. Voegt `:month-lengths` en `:month-length-family-count` toe, laat alle bestaande velden intact.
- Bij onmogelijke duur/maanden: `:invalid-month-length-family`; eerder bewezen dag-/poort-/budgetfouten blijven onveranderd.

## Onafhankelijke controle
- Productie: iteratieve schuivende-venstersom over overschot boven vier dagen per maand, O(maanden * overschot) exacte BigInt-optellingen. Lexicografisch suffixblok-unrank; geen enumeratie.
- Tests: zelfstandige brute-force diepte-eerst-opsomming voor alle kleine families (m=1..4, som 4m..4m+12) en iedere rang.
- Randen: 12/3, 369/3, 252/3, 5778/47, inclusief C(49,3)=18424 bij laatste.
- Echte doeldagen: onafhankelijk recursief `normative-oracle/choose-month-lengths` op twee gescheiden rekenmomenten, direct en verlengde poortlijn.
- Controle op eerste/laatste rang, kom 3/zegel 31, behoud van eerdere velden en foutcodes.
- Geen code of fixtures overgenomen uit een andere branch.

## Acceptatie
- Statische delimitertest en onafhankelijke lokale modelcontrole (geen Native).
- Atomische commit op exact HEAD, readback van branch en blobs.
- Native `clojure -M:test` en `verify` beide completed SUCCESS op exact SHA, ruwe test-/assertionaantallen, nul fouten. queued/in_progress is geen PASS.
- Geen main/merge, geen volledige Stage2/datum-PASS.

## NEXT
Na geverifieerde DISCOVERY16-acceptatie: DISCOVERY17 — begrensde maandweving met legale open-/sluitvolgorde (kom 4, zegel 32), telling en lexicografische rang met onafhankelijke oracle.
