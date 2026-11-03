# Stadio 22 — DISCOVERY 18: unuigita mallonga/larĝa ranga elekto

**Malfermo 2026-11-03.** Stadio 21 estas akceptita ĉe fina metadata HEAD `301e66dd7e5d298ea9aef2dfbf12028290abcd4a`: [Native run 41650968423](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41650968423), job `125968695396`, completed/success, **226/226 testoj**, Gleam 1.18.1/OTP28, formato kaj fontintegreco PASS, artefakto `13236219650`, SHA256 `87e43d37e0d8c7039db5b1824a0b55e53a3eeb2bdecfe9947dcdb2860fa35cd1`. [Names Lock run 41650968419](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41650968419), job `125968695220`, completed/success sur **la sama SHA**.

## Motivo kaj preciza amplekso

La aparta kanona orakolo `test/reference/sauce.gleam` enhavas `choose_rank(stream,n)` kaj disbranĉiĝas je `n <= M`. La jam akceptita produkta kodo havas `discovery_16_short_rank.select_short_rank` por `1 <= n <= M` kaj `discovery_17_wide_rank.select_wide_rank` por `n > M`, sed neniu unuigita publika dissendilo. **Elekto:** Stage22 enkondukas maldikan, puran unuigilon kaj dissendilon de unu rangnumero. Neniu rekalkulo de saŭco, ŝtonoj, 46 gutoj, 12 postmiksadoj aŭ kompleta kvinkomponenta dato. Neniu importo de `test/reference` en `src`; neniu kodo aŭ fiksaĵo de alia programlingva branĉo.

Konstanta `M = 170141183460469231731687303715884105727` (Gleam/Erlang arbitre preciza `Int`).

## Produkta kontrakto — API, datumtipoj, erarprioritato

Nova modulo `src/pastafari/discovery_18_choose_rank.gleam`:

- `select_rank(first: Int, step: Int, n: Int) -> Result(RankSelection, Discovery18Error)`.
- `choose_rank_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int, seal: Int, n: Int) -> Result(Int, Discovery18Error)`.
- `dispatch_discovery_18(context: bootstrap.MonsterContext, queried_bowl_id: Int, seal: Int, n: Int) -> Result(Discovery18Output, Discovery18Error)`.
- `RankSelection` havas du videblajn variantojn `ShortRank(selection: discovery_16_short_rank.ShortSelection)` kaj `WideRank(selection: discovery_17_wide_rank.WideSelection)`. La precizaj antaŭaj elektaj datumoj restu nesanĝitaj.
- `Discovery18Output(previous: discovery_15_answer_at.Discovery15Output, n: Int, selection: RankSelection, rank: Int)`. `previous.index=0`, kaj `previous` estas ekzakte la Stage19-diagnozo.
- `Discovery18Error`: `InvalidContext(bootstrap.BootstrapError)`, `InvalidBowlId`, `InvalidRankRange`, `InvalidStream`.

`select_rank` kontrolu `n >= 1` antaŭ validigi `first,step`; malvalidaj `n` inkluzive nulo kaj negativaj redonas `InvalidRankRange`. Validaj fluoj havas `1 <= first <= M` kaj `step in {-1,+1}`; alie `InvalidStream`. Post validigo, `n <= M` delegu ekzakte al la jam akceptita pura Stage20-elektilo; `n > M` al la jam akceptita pura Stage21-elektilo. Neniu forĵetbuklo en Stage22.

La dissendilo alvoku `discovery_15_answer_at.dispatch_discovery_15(context,id,seal,0)` **unufoje**, mapu ĝiajn erarojn kaj poste alvoku la puran unuigilon. Erarprioritato: malvalida kunteksto (inkluzive `retry_budget<0` kaj `recovery_depth<0`) > malvalida bovlo-ID (nur 1..6 validas) > malvalida `n` > malvalida fluo. Konservu la originajn tagojn (signohavaj, sen 64-bitaj limoj), `seal`, kontekstajn diagnozojn kaj ordon; neniu mutacio de jam konfirmitaj Stage19–21-datumoj.

## Matematikaj postkondiĉoj

Por ĉiu valida `n`: `1 <= rank <= n`. Por `n <= M`: `rank=ShortSelection.rank`, `limit=floor(M/n)*n`. Por `n > M`: `rank=WideSelection.rank`; `digit_count = min{k>=2 | M^k>=n}`, `space=M^digit_count`, `limit=floor(space/n)*n`. Por `n=M` devas esti `ShortRank`, por `n=M+1` `WideRank`; `n=1` ĉiam `rank=1`. Ambaŭ subelektiloj jam pruviĝis senrifuzbuklaj, sed la testorakolo uzas la laŭvortan rifuzmetodon nur kiam sendepende kalkulita distanco al unua akcepto estas **maksimume 8**. Por pli longaj trajektorioj kontrolu branĉan elekton, intervalojn, limojn, determinismon kaj laŭbezone sintezajn atestojn sen alvoki malrapidan kanonan `choose_rank`.

## Ekstera antaŭkontrolo (NE Gleam Native)

Sendependa entjera sintetika kontrolo super `m in {5,7,11,13}`, ĉiu `n in [1,m^3+1]`, `first in [1,m]`, `step in {-1,+1}`: **92,528** totalaj kazoj, inkluzive 728 mallongaj kaj 91,800 larĝaj. Literalaj orakoloj finiĝis ene de 8 rifuzoj por **74,598** kazoj, ĉiuj precize samrangaj kun senbukla elekto; **17,930** eksplicite nekomparitaj pro la 8-rifuza limo. Nul observitaj diferencoj inter kompareblaj kazoj. Ĉi tio ne estas Gleam-kompilado, Stage22-Native aŭ pruvo pri la nekomparitaj kazoj.

## Precize 12 novaj testfunkcioj

Nur `test/discovery_18_test.gleam`, plus la ekzistantaj 226 nesanĝitaj testoj; 238 estas **prognozo**, ne mezurita PASS. `reference/sauce.choose_rank` rajtas esti vokata nur post sendependa, finia kontrolo de la rifuzdistanco `<=8`; neniam por nedeterminite longa rifuzo.

1. Baza mallonga kazo `n=7` por dato `(11,21,id=1,seal=0)` kontraŭ sendependa orakolo; konfirmu `ShortRank`.
2. Baza larĝa `n=M+1` kun sama datumaro; konfirmu `WideRank` kaj limigitan orakolon.
3. Preciza ŝanĝo `n=M-1,M,M+1,M+2`; `n=M` ankoraŭ mallonga.
4. Ĉiuj ses bovloj por `n=3` kaj `n=M+1`; orakolo nur kiam la rifuzdistanco ne superas 8.
5. Antaŭa/malantaŭa/sama tago, inkluzive fundamenton `F-1,F,F+1`, ambaŭ elektiloj.
6. `seal=0,±1,±10^30`; antaŭaj diagnozoj konservas la originan `seal`.
7. Signohavaj tagoj `±10^30`, interplektitaj kuntekstoj, ripetaj samaj respondoj.
8. Sintezaj `first=1,M-1,M` kun `step=±1`, `n=1,3,M`: mallongaj postkondiĉoj kaj sekura orakolo.
9. Sintezaj `first=1,M-1,M` kaj `step=±1`, `n=M+1,M^2,M^2+1`; larĝaj intervaloj kaj potencaj limoj, kun orakolo nur laŭ kapo.
10. Longaj rifuzoj mallongaj `n=floor(M/2)+1` kaj larĝaj `n=floor(M^2/2)+1`; asertu konatan unuan akcepton antaŭen/malantaŭen sen malrapida orakolo.
11. Struktura izolo: `previous` egala al aparta Stage19-voko ĉe indekso 0, unuigita rango egalas la puran subelektilon, antaŭaj diagnozoj senmutaciaj.
12. Nevalidaj `n=0,-1`, `first=0,M+1`, `step=0,2`, bovloj `0,7,-1`, negativaj `retry_budget/recovery_depth`; asertu precizan erarprioritaton.

## Devigaj CI-gate-oj

1. Antaŭ Stage22-produktkodo: ĉi tiu kontrakta HEAD devas havi **completed/success** Native kun almenaŭ **226/226**, `gleam format --check src test`, netuŝita fonto kaj Canonical Names Lock sur la **sama SHA**. Nenio `queued` aŭ `in_progress` estas PASS, kaj ne duobligu aŭtomatan CI-dispatch.
2. Post la kontrakta gate, efektivigu nur la suprajn du novajn dosierojn (plus etapa metadatena ŝanĝo), precize 12 novajn testfunkciojn. Neniuj ŝanĝoj al Stage19–21 aŭ al la aparta orakolo.
3. Akceptu kodon nur per kompletaj same-SHA Native **238/238**, fontintegreco, formato, kaj Names Lock. Korektu nur realajn log-faktojn.
4. Aparta dokumenta HEAD kaj ĝia propra same-SHA CI estas devigaj antaŭ Stage23. Neniu `main`, merge, publikigo aŭ kompleta dato.

**Post kontrakta komito:** Stage21 estas finita kaj Stage22 nur planita; ĝia kodo, Native kaj ĝenerala PASS ankoraŭ ne ekzistas.
