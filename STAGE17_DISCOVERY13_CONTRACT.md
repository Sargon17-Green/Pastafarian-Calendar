# Stadio 17 — DISCOVERY 13: la sekva bovlo laŭ konservita ordo

**Stato 2026-10-31:** Stage17 produktkodo kaj 12 testoj konfirmitaj ĉe `26a44311c764c4b6e5d0205c93a4e92f4bf6f3d8`: Gleam 1.18.1 / OTP 28 Native run `41239196546`, job `124649317545`, 178/178 PASS, format kaj source integrity PASS, artefakto `13056792745` SHA256 `c0d9c9aa9f45ee3378730ac4d3997accad3ed8d496b9b1bade011230a7e7c5da`; Names Lock run `41239196481`, job `124649317353`, SUCCESS. Ĉi tiu posta dokumenta HEAD bezonas apartan CI-kontrolon; nenio ĉi tie pruvas ĝian rezulton.

## Motivo kaj amplekso

La posta miksado ŝanĝas la ses bovlajn valorojn sed **neniam** la ordon `order_at_drop_46`. La unua sekva observado en `test/reference/sauce.gleam` estas `next_bowl_in_drop_46_order`, kiu elektas cikle la sekvan identigilon en la historia 46-a guta ordo. Tial Stage17 efektivigu nur ĉi tiun apartan konsulton; la posta `ask_bowl` kaj ĝia demand-fluo restos al alia estonta stadio. Neniu nova datokomponento estas kreata.

## API, domajno kaj eraroj

Krei `src/pastafari/discovery_13_next_bowl.gleam` kun:
- `next_bowl_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int) -> Result(Int, Discovery13Error)`.
- `dispatch_discovery_13(context: bootstrap.MonsterContext, queried_bowl_id: Int) -> Result(Discovery13Output, Discovery13Error)`.
- `Discovery13Output` konservu la kompletigitan kuntekston, la finajn ses bovlojn, la originalan `order_at_drop_46`, la demanditan identigilon kaj la elektitan sekvan identigilon.

La domajno de `queried_bowl_id` estas precize 1..6. Difinu `Discovery13Error` kun `InvalidBowlId` kaj `InvalidContext(bootstrap.BootstrapError)`. Por `dispatch_discovery_13`, kontrolu la bootstrap-kuntekston unue: se kaj konteksto kaj identigilo estas malvalidaj, la bootstrap-eraro havu prioritaton. En valida kunteksto, identigilo ekster 1..6 revenu `InvalidBowlId`. La simpla funkcio por tagoj ankaŭ redonu `InvalidBowlId` por eksterdomena identigilo.

Por valida identigilo, ricevu la Stage16 `#(final_bowls, order_at_drop_46)` sen re-efektivigi 46 gutojn aŭ postmiksadojn. Trovu la pozicion `p` de `queried_bowl_id` en la konservita permuta listo; la sekva identigilo estas `order_at_drop_46[1 + mod(p,6)]` per unu-bazita indeksado. La ses finaj valoroj kaj la latĉita ordo estas transdonataj sen mutacio. Uzu propran produktan serĉon kaj ne importu `reference/`, fremdan branĉon aŭ la plena-datan algoritmoon.

## Sendependa orakolo kaj 12 testoj

La nura valida-domena orakolo estas `test/reference/sauce.gleam::next_bowl_in_drop_46_order`, uzata kun referenca `sauce(calculation_day,target_day)`; ne kun la produktkalkulo. Invalid-id/eraro-prioritato estas normativaj limtestoj, ne atribuitaj al la referenca funkcio, kiu ne kontraktas invalidajn identigilojn.

Plani 12 funkciojn en `test/discovery_13_test.gleam`:
1. Cikla permuta mapo por ĉiuj ses identigiloj kun unu kunteksto.
2. La ses rezultaj identigiloj formas permuton de 1..6.
3. La 46-a ordo estas konservita sen ŝanĝo pro postmiksadoj.
4. Fundamenta tagparo (`foundation_day,foundation_day`) kontraŭ referenco.
5. Antaŭen (`11,21`) kontraŭ referenco.
6. Malantaŭen (`21,11`) kontraŭ referenco.
7. Alia sama tago (`0,0`) kontraŭ referenco.
8. Fundamentaj transiroj en ambaŭ direktoj.
9. BigInt `±10^30` en ambaŭ direktoj.
10. Limoj `0,7,-1` donas `InvalidBowlId`; `1,6` validas.
11. Interplektitaj validaj kuntekstoj konservas proprajn diagnozojn, staton, ordon kaj bovlojn.
12. Retry/recovery-eraro-prioritato inkluzive de malvalida identigilo kaj du samtempaj eraroj.

Konservitaj ĉiuj 166 Stage16-testoj; la 12 novaj testoj kaj ĉiuj 166 regresiaj testoj pasis Native (178/178) ĉe la kontrolita koda SHA. La testoj devas ĉefe uzi rektan referencan orakolon, sed kontroli ankaŭ la 6-ciklan strukturon sen orakola dependeco.

## Akcepto

Pordegoj: `gleam format --check src test`, `gleam test`, source integrity, GitHub Actions Native `completed/success` kun ĝusta HEAD/job/artefakto+SHA256, kaj Canonical Names Lock `completed/success` ĉe la sama SHA. Neniu rerulo de jam sukcese kontrolita SHA, neniu inferita PASS el queued/in_progress. Post la verda koda HEAD, aparta dokumenta HEAD bezonas novan pruvon. Neniu main/merge/publikigo.
