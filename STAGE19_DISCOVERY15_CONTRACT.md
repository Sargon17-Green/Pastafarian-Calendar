# Stadio 19 — DISCOVERY 15: unu elemento de jam konata respondfluo

**Stato 2026-11-01:** kontrakto plus unua memstara produkta efektivigo kaj 12 statike kalkulitaj testfunkcioj. Stage18-koda HEAD `eeb7c5b381e83a5a5eb4fca66788787feab0d51d` kaj posta dokumenta HEAD `30b740de99d3b678332cbfbada599bd1c02d12b6` estas Native GREEN (190/190, formatter kaj fontintegreco PASS) kaj Names Lock SUCCESS ĉe respektivaj SHA. La nova Stage19-koda HEAD ankoraŭ bezonos proprajn Native kaj Names Lock-pordegojn; **202/202 estas nur prognozo**, ne mezurita rezulto.

## Celo kaj strikta amplekso

La kanona testreferenco `test/reference/sauce.gleam::answer_at` donas la valoron ĉe entjera indekso `k` de unu respondfluo; `ask_bowl` jam difinas ties unuan valoron kaj direkton. Stage18 liveris `first` kaj `direction_step` por specifa bovlo, du tagoj kaj ekstera `seal`. Stage19 liveros **nur unu indeksitan respondon** por tiu sama fluo kaj sen mutacio de antaŭaj diagnozoj. Ĝi ne elektos rangon, ne generos kvin datkomponentojn, ne kunigos plenan daton kaj ne importos orakolon en produktadon.

## Produktada API kaj valida domajno

Nova dosiero `src/pastafari/discovery_15_answer_at.gleam`:
- `answer_at_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int, seal: Int, k: Int) -> Result(Int, Discovery15Error)`.
- `dispatch_discovery_15(context: bootstrap.MonsterContext, queried_bowl_id: Int, seal: Int, k: Int) -> Result(Discovery15Output, Discovery15Error)`.
- `Discovery15Output(previous: discovery_14_ask_bowl.Discovery14Output, index: Int, value: Int)`; `previous` enhavu la sendifektan Stage18-diagnozon, latĉitan ordon, ses bovlojn, demanditan kaj sekvan IDojn, `seal`, `first` kaj `direction_step`.
- `Discovery15Error` distingas `InvalidContext(bootstrap.BootstrapError)` kaj `InvalidBowlId`, konvertante la erarojn de Stage18 sen perdi prioritaton.

Reuzu `discovery_14_ask_bowl.dispatch_discovery_14` unufoje per demando; ne rekalkulu la 46 gutojn aŭ la 12 postmiksadojn mem. La valida bovlo-ID estas 1..6. La signohavaj `calculation_day`, `target_day`, `seal` kaj `k` estas arbitre precizaj entjeroj. **Neniu limo al `k`: negativaj kaj grandegaj indeksoj estas validaj**; ili reprezentas retroiran aŭ plurciklan pozicion, ne eraron. Se kunteksto kaj ID ambaŭ estas malvalidaj, la kunteksta eraro devas venki, kiel ĉe Stage18.

## Formala funkcio

Metu `M = 170141183460469231731687303715884105727`. Post Stage18, `first ∈ [1,M]` kaj `direction_step ∈ {-1,+1}`. La Stage19-valoro estas:

`answer_at(k) = 1 + mod(first - 1 + direction_step*k, M)`

kie `mod(x,M)` estas la unika restaĵo en `[0,M-1]`, eĉ se `x < 0`. Uzu BigInt-precizan `Int`; nek 32-bita nek 64-bita konverto estas permesita. Implementu la restaĵan normaligon rekte en produktado, ne per dependeco de `test/reference`.

Devigaj invariantoj:
- `1 <= answer_at(k) <= M` por ĉiu valida eniro.
- `answer_at(0) == first`.
- `answer_at(k+1) == 1 + mod(answer_at(k)-1+direction_step,M)`.
- `answer_at(k+M) == answer_at(k)` kaj `answer_at(k-M) == answer_at(k)`.
- Neniu influo de la petita `k` al la Stage18-diagnozo, bovloj aŭ la originala `seal`.

## Aparta orakolo kaj precize 12 testfunkcioj

Nur en `test/discovery_15_test.gleam`, komparu produktadon kun:
`sauce.answer_at(sauce.ask_bowl(sauce.sauce(a,b), id, seal), k)`.
La valida-domajna orakolo restas en la testa dosierujo; negativa-domena erarprioritato estas rekte asertita laŭ kontrakto.

1. `k=0` kongruas kun Stage18 `first`.
2. `k=1` kaj `k=-1` kongruas kun aparta referenco.
3. Ĉiuj ses bovlo-IDoj por unu tagparo, kun sendependaj orakolaj valoroj.
4. Antaŭa, inversa kaj sama-taga kontekstoj.
5. Fundamentaj transiroj `F-1,F,F+1` en ambaŭ direktoj.
6. Pozitiva, negativa kaj nula sello.
7. Ekstremaj tagoj kaj selloj je `±10^30`.
8. La periodaj indeksoj `0,M,-M,2M,-2M`.
9. Proksime de la randoj: `M-1,M,M+1,-M-1`.
10. Intersekvitaj validaj kontekstoj ne miksas diagnozojn, sellojn aŭ respondojn; ripetita voko estas determinisma.
11. Rekta invarianto por rango 1..M kaj unu-paŝa rekursio en ambaŭ direktoj, apartigita de nura orakola egaleco.
12. Nevalidaj bovloj `0,7,-1` kaj negativa `retry_budget`/`recovery_depth`; ĝusta kunteksta erarprioritato sendepende de `k`.

Konservu ĉiujn **190** antaŭajn Native-verdajn testojn. Stage19 enkonduku **12** novajn testfunkciojn; celataj **202** estas nur prognozo antaŭ nova CI, ne mezurita sukceso.

## Akceptpordegoj kaj sekva ago

1. La dokumenta HEAD kiu aldonas ĉi tiun kontrakton devas finiĝi per Native kaj Names Lock `completed/success` sur **ĝuste la sama SHA**, kun videbla `gleam test`-nombro, sen fontmutacio. Ne ekiru per nefinita verda konkludo.
2. Poste implementu Stage19-produktkodon kaj 12 testfunkciojn sen importi `test/reference` en `src`.
3. Sur la nova koda SHA: `gleam format --check src test`, `gleam test` kun mezurita kalkulo, senmutacia fontkontrolo, aparta Names Lock kaj preciza HEAD. Korektu nur pruvitajn fiaskojn.
4. Post koda GREEN, fermu Stage19-dokumentadon kaj rericevu CI por la posta dokumenta HEAD. Neniu reekzigo de jam sukcesa SHA, `main`-kunfando aŭ publikigo.

