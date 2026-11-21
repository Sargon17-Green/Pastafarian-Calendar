# DISCOVERY24 — verificatie van generieke datum-E2E-haalbaarheid (2026-11-21)

Project-ID: `PC-BRANCH-CLOJURE-DUTCH`. Dit is een **QA- en ontwerpdocument**, geen wijziging van de productiecode, de bestaande test, de budgetlimiet of de acceptatiecriteria.

## Reproduceerbare bronketen

- Branch `Clojure+Nederlands`, getoetste bron-HEAD `0cde9a3ec6e5c3ec142ab0e765013545de1e8701`; parent `7045c7d9148403c0eddc0d9c443906b511c20766`.
- Automatische push-CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877197819; `event=push`, `head_sha=0cde9a3ec6e5c3ec142ab0e765013545de1e8701`, `completed/success`, attempt 1.
- Native-job `136764399693`: `completed/success`; ruwe log: **152 tests / 168997 assertions / 0 failures / 0 errors**; legacy `echte E2E` bleef **0 bewezen / 7 geweigerd** bij `100000N`.
- Naamlock-verify-job `136764399602`: `completed/success`.
- Gerichte feasibility-job `136764399509`: `completed/success`; `SOURCE_SHA=0cde9a3ec6e5c3ec142ab0e765013545de1e8701` werd in de log afgedwongen.
- Bewijsartifact `clojure-dutch-generic-e2e-feasibility`, ID `14697129391`: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44877197819/artifacts/14697129391. ZIP-grootte **34016 bytes**, SHA-256 **`d02e29e5b61286d76b946da75bdb19c7b1af5532978e934b5a6400304f0f0a47`**. Het ZIP is werkelijk gedownload: één bestand `discovery24_generic_feasibility.edn` van 98812 bytes. SHA-256 van gedownload ZIP = door GitHub gerapporteerde digest.
- Testbron `test/pastafari/stage02_end_to_end_test.clj` blob `e125b4aaee030ff07569d80bb2a9420798d1278e`; bestaand contract `STAGE_02_DISCOVERY24.md` blob `42e34750001e96ece09c8179ff4830a86acb180d`.

## Zeven canonieke gevallen: uit oorspronkelijke EDN geverifieerd

| Case | Jaar | 1-based positie p | Jaarlengte L | Classificatie |
|---|---:|---:|---:|---|
| base-first | 5000 | 1 | 4244 | first-day-fast-path |
| base-middle | 5000 | 2122 | 4244 | interior-selective-prefix |
| base-last | 5000 | 4244 | 4244 | last-day-fast-path |
| previous-last | 4999 | 4126 | 4126 | last-day-fast-path |
| next-first | 5001 | 1 | 5567 | first-day-fast-path |
| shifted-plus-17 | 5000 | 520 | 3569 | interior-selective-prefix |
| shifted-minus-23 | 5000 | 3332 | 3700 | interior-selective-prefix |

Onafhankelijke *artifact-structure* hercontrole buiten Clojure (Python, rechtstreeks uit de gedownloade EDN, zonder broncode te kopiëren): **7/7** met `sum(month-lengths)==L`, `close-open==L`, `target-open==p` en `1<=p<=L`. Deze rekenkundige consistentiecontrole is extra QA; zij bewijst geen numerieke vijfveldsgelijkheid.

Clojure-model-QA: **127/127** onafhankelijke kleine-familie-prefixvergelijkingen; de test vergelijkt oorspronkelijke normative weaving-families met afzonderlijke insertion-prefixselectie. Deze uitslag is geen bewijs voor de zeven grote jaarposities.

**Eén echte gebudgetteerde proef:** `calculation-day=-15055654N`, `target-day=-15056158N`, `p=16N`, vijf numerieke velden `[5000 15 16 44 2]` exact gelijk aan de onafhankelijke normatieve referentie, 16 exacte maand-ID's, gerapporteerde `month-prefix-cell-upper-bound=2400883N`. Zoekbudget `128N`, cumulatieve grens `5000000N`; geen volledige maandweving opgebouwd. `pilot=:bewezen`, `five-fields-proven?=true`, `scope=:bounded-prefix-only`.

## Resterende bewijskloof en concrete engineering-NEXT

De labels `first-day-fast-path` en `last-day-fast-path` zijn **classificaties**, nog geen bewezen snelle productie-uitvoering. De oude generieke E2E-benadering vraagt een volledig maandweefwoord en weigert alle zeven gevallen bij `100000N`. Zelfs voor een binnenjaarpositie vereist de bestaande selectieve methode prefix/rangwerk; voor `p=520`, `p=2122` en `p=3332` is **geen nieuwe selectieve kost gemeten**. De grotere full-weaving-bovengrenzen zijn géén gemeten selective-prefix-kosten. `p=16` bewijst evenmin dat `p=520` betaalbaar is.

**NEXT: test-only witness voor exact één canonieke first-day-case (`base-first`, p=1).** Behoud exact de bestaande API en grenzen `search=128N` en `prefix-cells<=5000000N`; maak maximaal één echte productieaanroep. Bouw de onafhankelijke normatieve jaar-, kotelet-, maandlengte-/maandnaam- en weefranggegevens via de test-oracle, niet via productie `tel-rest`/`prefix-op-rang`/cache. Bij succes moeten alle vijf datumvelden en de ene maand-ID exact overeenkomen, `scope=:bounded-prefix-only`, `month-weaving-computed?=false`, geen `:month-weaving`, en gerapporteerde kosten binnen de grens. Bij weigering: uitsluitend de geobserveerde `:bounded-prefix-budget-unproven`, daarna precies het eerste onbetaalbare kandidaatblok/rekengedeelte instrumenteren voordat een algoritmische optimalisatie wordt gekozen. Geen ongeteste fast-path claim.

Daarna pas `next-first` of een precies afgebakende factorhergebruik-optimalisatie voor de lange binnenjaarposities. Iedere nieuwe codecommit vergt Clojure static-preflight, exact HEAD/blob-readback en nieuwe exact-SHA completed Native+verify-resultaten met ruwe aantallen; aanvaarding van één kortere prefix is geen `7/7` en geen Stage 2.

**Gates blijven onveranderd:** legacy E2E `0/7`, Stage 2 `OPEN`; geen budgetverhoging, geen main/merge/publicatie, geen dubbele CI-dispatch. Deze docs-only auditcommit wordt met `[skip ci]` gemaakt om de reeds geaccepteerde tests op ongewijzigde bronnen niet opnieuw te draaien.
