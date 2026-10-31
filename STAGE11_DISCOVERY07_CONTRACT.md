# Stadio 11 — DISCOVERY 07: malkodigo de ses-bovla permuta ordo

**Stato (2026-10-31):** Stage11 kompletiĝis verda ĉe koda HEAD 7c12a4a8eeff8f4c68371e2373a8d9ca62b92205; Stage12 estos aparta paŝo.

## Kanona celo kaj limoj

La kanona `test/reference/core.gleam` difinas `permutation_unrank1(rank1, [1,2,3,4,5,6])` kaj `bowl_order_from_drop(drop_value)`. Stadio 11 realigu nur la senchavan ses-bovlan permutan unranking kun periodicaj nul/negativaj/gigantaj drop-valoroj; ne la plenan 46-ŝtonan saŭcon aŭ finan kvin-komponentan daton. Ne kopiu produkton aŭ fixture el alia branĉo.

La ses bovloj estas ekzakte `[1,2,3,4,5,6]`, do `6!=720` malsamaj ordoj. Por ajna `drop: Int`, normigu per `rank1 = 1 + mod(drop-1,720)` kun pozitiva resto en `0..719`. La ordon malkodu per faktoriala numerada sistemo; produktkodo havu propran iteracian malkodilon kaj elekton el restantaj bovloj, ne importu `reference/core`. Nek la ses bovloj nek ilia ordo estas sesa datokomponanto.

## Enigo kaj eligo

Enigo: `bootstrap.MonsterContext` (por konteksta valideco) kaj `drop_value: Int`. Eligo je valida kunteksto: `Ok(Discovery07Output(context, drop_value, rank1, order))`, kie `order` enhavas la ses apartajn Int-ojn `1..6`. Je nevalida konteksto konservu `InvalidRetryBudget` antaŭ `InvalidRecoveryDepth`. Ne ŝanĝu `main`, kanonajn nomlistojn, aŭ `test/reference/core.gleam`.

## Sendependa orakolo kaj atestoj

Testa orakolo: `core.bowl_order_from_drop(drop_value)`, ne la produktkodita malkodilo. Ekstera Python-kalkulo laŭ faktoriala matematiko (antaŭkontrolo nur, ne Gleam Native):
- `drop=1` → `[1,2,3,4,5,6]`; `drop=2` → `[1,2,3,4,6,5]`.
- `drop=720` kaj `drop=0` → `[6,5,4,3,2,1]`; `drop=721` kaj `drop=-719` → `[1,2,3,4,5,6]`.
- `drop=-1` → `[6,5,4,3,1,2]`; `drop=2^70` → `[3,4,5,2,6,1]`.

Planu 12 novajn unit-testojn: (1) unua rango, (2) dua rango, (3) rango 720, (4) nulvaloraj/negativaj drop-valoroj, (5) perioda 720, (6) granda pozitiva/negativa BigInt, (7) ĉiuj 720 kontraŭ la aparta orakolo, (8) ĉiuj 720 unikaj permutaĵoj kun ses senripetaj bovloj, (9) konteksta izolado, (10) nevalida retry-budget, (11) nevalida recovery-depth, (12) ambaŭ nevalidaj kaj ĝusta prioritato. Evitu teston de rango ekster `1..720` sen aparta difinita erarkontrakto.

## Verifiko

1. Antaŭ koda efektivigo konfirmu Stage10 dokumentan HEAD per `completed` Native/Names kaj la 90/90 logojn; `queued`/ `in_progress` ne estas PASS aŭ blokilo.
2. Aldonu unu produktmodulon, 12 testojn kaj stage-statusajn kampojn; ekzistantaj referenco, produktaj moduloj, kvin finaj datokomponantoj kaj nomlistoj restu netuŝitaj.
3. La regresobazo estas 90 mezuritaj testoj; Stage11 celo **102 PASS / 0 FAIL (nur prognozo)**. Deviga `gleam format --check src test`, `gleam test`, kaj Canonical Names Lock ĉe identa commit SHA; logoj, labor-ID, artifact/hash estas pruvodevigaj.
4. Neniu `main`-merge, plena datokonverto, aŭ aldona dato-komponanto.

## Fakta fermo (2026-10-31)

- Formatter-only korekto en test/discovery_07_test.gleam atingis HEAD 7c12a4a8eeff8f4c68371e2373a8d9ca62b92205.
- Native run 41199740784, job 124533006663: completed/success; Gleam 1.18.1/OTP28, formato PASS, 102 passed/0 failures. HEAD-kontrolo kaj senmodifa fontkontrolo sukcesis.
- Artifact 13042089676, SHA256 ceae21269bb7e5498b794bbee1a908716a7efd68d7c16f7786e048902444a245.
- Names Lock run 41199740794, job 124533006857: completed/success ĉe sama SHA.
- 90 pasintaj regresoj + 12 Discovery07 testoj. Ne plena dato.
