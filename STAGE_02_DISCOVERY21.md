# Fase 2 — DISCOVERY21 — budgetbewezen koppeling van maandselectie

## Geaccepteerde basis
- Branch `Clojure+Nederlands`, SHA `68dc2c1ed979bdee1e16115dcc0619e0723899f9`.
- Run 41409200332: `verify` job 125158106827 en `clojure-native-stage02-discovery20` job 125158106919 beide completed/SUCCESS.
- Native ruwe log: 95 tests, 39252 assertions, 0 failures, 0 errors. DISCOVERY20 aanvaard; Stage 2 en de vijfdelige datum blijven OPEN.

## Nieuwe strikt afgeschermde productie-API
- Namespace `pastafari.maandselectie`; opt-in `kies-bewezen-maandweving(lijn, berekeningsdag, doeldag[, zoekbudget, celbudget])`.
- Invoer: geërfde bewezen poortlijn/dagen, zoekbudget (standaard 128), celbudget (standaard 5000000, toegestaan 1..5000000).
- Hergebruikt **zonder aanpassing** `kies-maandlengtes`, de bestaande kom 4 / zegel 32, `kies-rang`, de exacte grote BigInt-familietelling en `weving-op-rang-groot`.
- Vóór een saus-/ranganalyse de conservatieve gesloten bovengrens `N*m*(1+(m+1)*(N+1))` controleren. Alleen `C <= celbudget` autoriseert de selectie.
- Bij `C > celbudget`: `:weaving-unrank-budget-unproven`, nooit een onvoorwaardelijke poging. Bestaande invoer- en budgetfouten blijven intact.
- Uitvoer behoudt alle eerder bewezen velden plus `:month-weaving`, `:month-weaving-family-count`, `:month-weaving-cell-bound`. Geen maandnamen, geen publieke datum, geen uitbreiding van oude `kies-maandweving`.
- Garantie is uitsluitend voor geadministreerde kandidaatcellen; **geen** gegarandeerde runtime/heap-bovengrens en geen volledige kalendercorrectheid.

## Onafhankelijke oracle en acceptatie
- Test vergelijk de nieuwe eindselectie tegen de losstaande, recursieve `normative-oracle/weaving-family` op [4,4], [4,4,4], [4,5,4], met lexicografische grens-, midden- en nabijgrensrangen.
- Verifieer exact kom 4/zegel 32, behoud van bestaande metadata, telling en `month-weaving-cell-bound`.
- Zes maanden van vier dagen: oude begrensde API moet blijven weigeren, nieuwe opt-in selecteert geldige woorden met exact multipliciteiten.
- Onveilige maximale 47-maandenfamilie (46*123+120=5778), een te kleine begroting en ongeldige begrotingen: reject vóór saus-/rangkeuze.
- Fout `:invalid-gate-line` wordt onveranderd geërfd.
- Native `clojure -M:test` en `verify` beide completed/SUCCESS op dezelfde SHA en branch, ruwe tests/assertions/0 failures/0 errors vereist; alleen daarna DISCOVERY21 ACCEPTED.

## Volgende stap
DISCOVERY22: voer een afzonderlijk, begrensd en onafhankelijk bewezen maandnaamselectiecontract uit (kom 5/zegel 33), zonder vijfdelige datum te claimen vóór volledige end-to-end differential. Geen main/merge/publicatie.
