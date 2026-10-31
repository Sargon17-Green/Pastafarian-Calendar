# Fase 2 — DISCOVERY17 — begrensde maandweving

## Gecontroleerde voorloper
- DISCOVERY16 HEAD `928f03349261917a0799f7f29545cddfbb03b8f0`.
- GitHub Actions run 41239273679: Native en verify beide completed SUCCESS; ruwe Native-log 80 tests / 34280 assertions / 0 failures / 0 errors.
- Stage 2 / vijfdelige datum niet voltooid.

## Contract, grens en uitvoer
- `aantal-wevingen(maandlengtes)`: exact BigInt aantal woorden met ieder maand-ID precies zijn lengte, waarin eerste en laatste voorkomens allebei in de volgorde 1..m liggen.
- `weving-op-rang(maandlengtes,rang)`: eengebaseerde lexicografische maand-ID-reeks.
- `kies-maandweving(lijn,berekeningsdag,doeldag[,budget])`: behoud van alle `kies-maandlengtes` velden en fouten; saus op dag na jaaropening; kom 4 / zegel 32; nieuwe `:month-weaving` en `:month-weaving-family-count`.
- **Expliciete, voorlopige grens**: 1..5 maanden, elk 4..123 dagen, totaal hoogstens 32 dagen. Ongeldige familie `:invalid-weaving-family`; legale familie buiten grens `:weaving-bound-exceeded`; ongeldige rang `:invalid-weaving-rank`. Geen onbewezen uitbreiding naar 47 maanden / 5778 dagen.
- De volgende maand mag pas verschijnen na opening van alle vorige maanden. Een maand mag pas eindigen na sluiting van alle vorige maanden.

## Onafhankelijkheid
- Productie: bottom-up topologische DP over restvectoren, met aantallen voor suffixen en lexicografisch ontleden; geen woordenumeratie.
- Tests: volledige brute-force generator van alle multisetwoorden zonder productie-pruning, achteraf filter op eerste/laatste verschijning; afzonderlijke tweemaandsidentiteit `C(a+b-2,a-1)`.
- QA: 1..3 maanden, grootste bewezen geval 5 maanden / 20 dagen, eerste/laatste rang, kom 4/zegel 32, behoud velden en foutcodes; geen code of fixtures van andere branch.

## Acceptatie
- Statische delimitercontrole en onafhankelijk numeriek model zijn preflight, **geen Clojure Native**.
- Atomische commit op exacte branch HEAD, blob-/ref-readback.
- Native `clojure -M:test` en `verify`: alleen completed SUCCESS op exact SHA plus ruwe tests/assertions/0 failures/errors.
- Geen main/merge of Stage2-/datum-PASS.

## NEXT
DISCOVERY18 — onafhankelijk afgeleide algebraïsche compressie en begrensde geheugen-/tijdmetingen om de weving naar 3..47 maanden, jaarlengtes tot 5778 uit te breiden. Behoud `:weaving-bound-exceeded` buiten bewezen bereik.
