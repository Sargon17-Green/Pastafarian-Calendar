# Stadio 7 — PATCH 03: korekti la inkluzivan distancon

**Stato:** efektivigita por kontrolo; Native kaj Names Lock ankoraŭ ne deciditaj. Antaŭa branĉa HEAD: `80a1f01c36e74767733d1a8f92ea86e14510abcf`. Ne ŝanĝu `main` kaj ne deklaru GREEN sen kompletaj registroj.

## Enigo, eligo kaj limoj
Enigo: `MonsterContext` kun `calculation_day: Int` kaj `target_day: Int`. Uzu la ekzistantan `bootstrap.dispatch_context`; ĉe valida kunteksto eligu `Discovery03Output` kun la kompletigita kunteksto, la malnova `legacy_distance` kaj la nova `inclusive_distance`. Ĉe nevalida `retry_budget` aŭ `recovery_depth` konservu la ekzistantajn erarojn. Ne ŝanĝu la kvin kanonajn datokomponantojn kaj ne pretendu kalkuli plenan daton.

## Kontrakto de la korekto
- Historia diagnozo: `legacy_distance(a,b) = |b-a|`; konservu ĝin por komparo, sen ŝanĝo de la malnova algoritmo.
- Aktiva valoro: `inclusive_distance(a,b) = |b-a| + 1`, tiel ke sama tago havas distancon 1.
- Nur la produktvojo liveras la novan aktivan kampon; la normiga orakolo restas en `test/reference/core.gleam`, en `work_counts(a,b).distance`. Neniu importaĵo el `test/reference` al `src`.
- Ne ŝanĝu la restajn kuntekstajn kampojn, la diagnozajn listojn aŭ la validaĵan konduton.

## Sendependa testorakolo kaj limkazoj
La ekzistanta, aparta test-referenco kalkulas `abs_int(b-a)+1`. Ĉe `F=-15_055_671`:
- (F,F): legacy=0, aktiva=1.
- (F,F+1): legacy=1, aktiva=2.
- (F+1,F): legacy=1, aktiva=2.
La tri antaŭaj EXPECTED_RED-atestoj devas nun pasi sen ŝanĝi la orakolon. Aldone kontrolu konservadon de la tri legacy-valoroj, simetrion kaj konsenton kun la orakolo por grandaj pozitivaj kaj negativaj entjeroj, inkluzive de samtagaj kazoj. La antaŭaj testoj por izolaj kuntekstoj kaj malvalidaj retry/recovery-valoroj devas resti.

## Aceptopordegoj
1. Antaŭa stadio: Native 48 PASS / 3 intencaj FAIL, Names Lock SUCCESS, sur la dokumentita HEAD `80a1f01c36e74767733d1a8f92ea86e14510abcf`; jam kontrolita. Tio ne estas Stage07 PASS.
2. Statika kontrolado: neniu ŝanĝo al `test/reference/core.gleam`, konservitaj 43 Stage05-regresioj kaj 5 Stage06-kontroloj; plus la 3 korektitaj normigaj testoj kaj 2 novaj regresioj, entute atendataj **53 PASS / 0 FAIL**.
3. Ekzekutu `gleam format --check src test` kaj `gleam test` je Gleam 1.18.1 / OTP 28. Konservu realan testnombron kaj logon; se formatter aŭ testoj malsukcesas, ne deklaru PASS.
4. Konfirmu Canonical Names Lock SUCCESS sur la sama preciza SHA. Eĉ se CI atendas, ĝi ne estas bloko aŭ PASS. Neniu nenecesa rerun por sama SHA.
5. Fermu Stage07 nur post kompletaj kaj kongruaj Native/Names Lock-registradoj, per aparta dokumenta konfirmo. Neniu merge, publika eldono aŭ plena dato.
