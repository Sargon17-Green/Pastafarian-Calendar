# Stadio 8 — DISCOVERY 04: direkta klasifiko de du tagoj

**Stato:** kodo kaj 12 testoj preparitaj; NATIVE/Names Lock ankoraŭ ne konfirmitaj. Ne deklaru ĉi tiun stadion finita antaŭ kompletaj CI-registroj. La antaŭa stadio 7 estas kontrolite GREEN ĉe SHA `f6c7624231ebb9e5d63063775b77bdc7e4f9ce74` (53/53 Native, Names Lock SUCCESS).

## Izolita celo kaj datumfluoj

Nova diagnoza, nurlega kampo `direction` respondas al la jam difinita kvina kampo de `test/reference/core.gleam::work_counts` (la labor-kalkula direkto), ne al iu el la kvin finaj datokomponantoj.

- Enigo: `bootstrap.MonsterContext(calculation_day: Int, target_day: Int, ...)`.
- Valida eligo: `Ok(Discovery04Output(context: completed, direction: Int))`.
- Direkta kodo: `1` kiam `target_day < calculation_day`; `2` ĉe egaleco; `3` kiam `target_day > calculation_day`.
- Kalkulo en la produktkodo: signo de la diferenco `target_day - calculation_day`. La test-referenco komparas rekte la tagojn, sen importaĵo al produktkodo.
- Eraro: konservu `InvalidRetryBudget` aŭ `InvalidRecoveryDepth` el `bootstrap.dispatch_context`; se ambaŭ malvalidas, `InvalidRetryBudget` havas prioritaton.
- Ne ŝanĝu diagnozojn, spurojn aŭ validigajn listojn krom la jam dokumentitaj transiroj de la baza dissendilo. Ne modifu `test/reference/core.gleam`, la kvin datokomponantojn, aŭ `main`.

## Sendependa orakolo kaj limkazoj

La sendepende lokita orakolo `core.work_counts(a,b).direction` uzas rektaĵan komparon kun `a`, male al la produktkoda signo de `b-a`.

Testu almenaŭ: `F=-15_055_671` kun `(F,F-1)->1`, `(F,F)->2`, `(F,F+1)->3`; ambaŭ direktoj trans `F±2`; `(-1,0)->3`, `(0,-1)->1`, `(0,0)->2`; grandajn kontraŭsignajn entjerojn; identecon sub sama translacio de ambaŭ tagoj; inversan paron kun direktoj sumantaj al 4. Aldone kontrolu izolajn kuntekstojn, listojn kaj erarprioritaton.

La 10 sendependaj Python-aritmetikaj antaŭkontroloj (10/10) nur konfirmas la matematikan klasifikon, **ne** Gleam-kondiĉojn, Native, aŭ CI.

## Akceptokriterioj

1. Antaŭa pordego: Stage07 ĉe `f6c7624231ebb9e5d63063775b77bdc7e4f9ce74`, 53 PASS/0 FAIL, Names Lock SUCCESS; jam dokumentite.
2. Kodo: nova modula limigita produkta diagnozo; neniu kopio de alia programlingva branĉo; 12 novaj testoj kaj antaŭaj 53 regresioj konservitaj. Atendataj **65 testoj**, ne mezurita rezulto.
3. `gleam format --check src test` kaj `gleam test` per Gleam 1.18.1 / Erlang OTP 28. Se malsukceso aperas, esploru realan logon; ne supozu EXPECTED_RED.
4. Canonical Names Lock SUCCESS sur la precize sama nova HEAD. Konservu run ID, SHA, kompletan konkludon, rezultan testnombron, kaj eventualan artifakton.
5. Nur post ambaŭ kompletaj pordegoj ĝisdatigu `LAST_COMPLETED_STAGE=8`. Neniu merge al `main`, eldonado, aŭ pretendo pri kompleta kalendara dato.

## Enkonduka indico

La novaj dosieroj estas `src/pastafari/discovery_04_direction.gleam` kaj `test/discovery_04_test.gleam`. Tiu ĉi kontrakto ne enhavas antaŭfaritan pretendon pri historia peko aŭ retro-trovita malsukceso.
