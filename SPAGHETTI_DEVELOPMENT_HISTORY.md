# Utviklingshistorie for spagettimonsteret

## Stage 1 — Bootstrap

### Kva vi bygde

Implementasjonslina vart oppretta frå null. Vi la inn eit eksakt BigInt-lag i AWK, ein rein testreferanse, eit testoppsett, den frosne nynorske kjeldekatalogen og berre den generelle infrastrukturen som er lov i bootstrap-steget.

### Monsterlaget som vart lagt til

Eit nøytralt grunnlag for invocation-eigd kontekst, base-dispatch, validering, feilstatus, deterministisk loggskal og metrikkar vart lagt inn. Laget har enno ingen historiske feil, compatibility-banar, legacy-adapterar eller patch-spesifikke flagg.

### Kvifor laget ikkje endrar semantikk

Produksjonsbanen er enno ikkje implementert og kan difor ikkje gi ein kalenderverdi. Grunnlaget eig berre livssyklus- og observabilitetsdata. Den reine normative referansen ligg berre i testlaget og blir ikkje brukt som runtime-fallback.

Ingen seinare patchhistorie er skriven på førehand.
