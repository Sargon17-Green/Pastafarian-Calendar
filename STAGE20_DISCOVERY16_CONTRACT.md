# Stadio 20 — DISCOVERY 16: mallonga ranga elekto el unu respondfluo

**Stato 2026-11-01:** nur memstara kontrakto; produktkodo kaj 12 novaj testoj **NE** estas kreitaj. Stage19-koda HEAD `cc4ac602a0a34990d356128f126c408412a72abf` Native GREEN (202/202, formatter, senmutacia kontrolo) kaj Names Lock SUCCESS sur ĝuste la sama SHA. Ĉi tiu nova dokumenta HEAD ankoraŭ bezonas apartajn Native kaj Names Lock completed/success antaŭ Stage20-kodkomenco.

## Amplekso kaj elekto

Post Stage19, unu kanona respondfluo havas unuan valoron `first` kaj direkton `step` en {-1,+1}. La aparta kanona referenco `test/reference/sauce.gleam::choose_rank_short` elektas rangon inter 1 kaj `n` per rifuzo de valoroj pli grandaj ol `limit`. Stage20 liveros **nur unu mallongan rangon**, por `1 <= n <= M`, el unu jam akirita fluo. Neniuj larĝaj rangoj (`n > M`), aliaj datkomponentoj, fina kvinkomponenta dato aŭ main/merge.

Ni elektas matematike ekvivalentan senbuklan produktan strategion pro grava maksimumkaza risko: por `n = floor(M/2)+1`, la laŭvorta referenca rifuzbuklo povas preni proksimume `M/2` paŝojn, kio estas nepraktika. Ne kopiu ĝian buklon al produktado. Uzu ĝian funkcion nur kiel **apartan testorakolon** por pruve mallongaj trajektorioj.

## Konstantoj, eniroj, eraroj kaj produkta API

`M = 170141183460469231731687303715884105727`, entjero de arbitra precizeco. Nova modulo `src/pastafari/discovery_16_short_rank.gleam`:

- `short_rank_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int, seal: Int, n: Int) -> Result(Int, Discovery16Error)`.
- `dispatch_discovery_16(context: bootstrap.MonsterContext, queried_bowl_id: Int, seal: Int, n: Int) -> Result(Discovery16Output, Discovery16Error)`.
- `select_short_rank(first: Int, step: Int, n: Int) -> Result(ShortSelection, Discovery16Error)` estas pura funkcio por mezureblaj sintetaj randokazoj; validigu `1 <= first <= M`, `step ∈ {-1,+1}`, `1 <= n <= M`.
- `Discovery16Output(previous: discovery_15_answer_at.Discovery15Output, n: Int, limit: Int, accepted_value: Int, rank: Int)`; `previous` estas la neŝanĝita Stage19-diagnozo ĉe `k=0`.
- `Discovery16Error`: `InvalidContext(bootstrap.BootstrapError)`, `InvalidBowlId`, `InvalidRankRange`, `InvalidStream` (nur por rekta malvalida pura-funkcia eniro).

Uzu Stage19 `dispatch_discovery_15(context,id,seal,0)` ĝuste unufoje por akiri la fluon kaj ĝiajn diagnozojn; ne rekalkulu ŝtonojn, 46 gutojn aŭ 12 postmiksadojn. Erarprioritato en la dissendilo: nevalida kunteksto antaŭ nevalida bovlo-ID antaŭ malvalida `n`. `n=0`, negativa `n`, kaj `n>M` estas eraroj, ne larĝrangaj petoj en ĉi tiu etapo.

## Normativa matematiko kaj O(1) elektado

Difinu `L = floor(M/n)*n`. La referenco ekzamenas `x(k)=1+mod(first-1+step*k,M)` por `k=0,1,...`; ĝi akceptas la **unuan** `x(k) <= L`, poste redonas `1+mod(x(k)-1,n)`. La preciza senbukla ekvivalento estas:

1. Se `first <= L`, metu `accepted_value = first`.
2. Se `first > L` kaj `step = +1`, metu `accepted_value = 1` (la unua akceptita post ĉirkaŭvolvo).
3. Se `first > L` kaj `step = -1`, metu `accepted_value = L` (la unua akceptita dum retroira malsupreniro).
4. `rank = 1+mod(accepted_value-1,n)`.

La modulo estas ĉiam nenegativa; neniuj 32-/64-bitaj konvertoj. `1<=L<=M`, `1<=rank<=n`; kun `n=M` tuj akceptu `first`. La algoritmo postulas konstantan nombron da aritmetikaj operacioj, sendepende de la nombro de rifuzitaj referencaj valoroj (BigInt-operacia kosto restas dependanta de operandlongo). Neniu modulo `n=0`.

**Pruvskizo:** la cikla fluo moviĝas je ekzakte unu modulo `M`. Se ĝia unua valoro estas en `[1,L]`, ĝi estas jam la unua akceptebla. Se la unua valoro estas en `[L+1,M]`, la antaŭenira fluo restas en la rifuzita fina intervalo ĝis ĝi ĉirkaŭvolvas al 1; la retroira fluo atingas `L` unue. Do la elektitaj valoroj estas identaj al la referenca unua akcepto.

## Precize 12 novaj testfunkcioj

Nur `test/discovery_16_test.gleam`; testreferenco restas sub `test/reference`, neniam importita de `src`. Konservu ĉiujn antaŭajn 202 Native-verditajn testojn; `214/214` estas **nur prognozo** ĝis CI.

1. Bazkazo `(11,21,id=1,seal=0,n=7)` kontraŭ `sauce.choose_rank_short`, kun limigita serĉo.
2. Ĉiuj ses bovlo-IDoj kun `n=2`; orakolo nur kiam antaŭkalkulita rifuzdistanco <= 8.
3. Antaŭen/reverse/sama tago, `n=1,3,5`, orakolaj kazoj kun mallonga distanco.
4. Fundamentaj tagoj `F-1,F,F+1`, ambaŭ direktoj, `n=11`.
5. Selloj `0,±1,±10^30`; konfirmu konservitan Stage19-`seal`.
6. Tagoj je `±10^30`, kun rezultintervaloj kaj determinigeco.
7. `n=1`: rango ĉiam 1; `n=M`: rango `first`, `limit=M`.
8. `n=M-1`: pruvu la precizan tuj-akcepton aŭ unu-paŝan ĉirkaŭvolvon sur sintetaj unuaĵoj.
9. Por `n=floor(M/2)+1`, sintetaj `first=M`, `step=±1`: atestoj por longrifuza branĉo en konstanta aritmetika tempo; **ne** voku malrapidan referencan buklon.
10. Sendependa pura-invarianta kontrolo de `accepted_value <= L`, `1<=rank<=n` kaj ĉe akcepto `rank=1+mod(accepted_value-1,n)`.
11. Interplektitaj kuntekstoj kaj senmutacia Stage19-diagnozo; postulata `previous.index=0`.
12. `n=0,-1,M+1`, `first=0,M+1`, `step=0,2`, malvalidaj ID `0,7,-1` kaj negativaj retry/recovery; prioritato de eraroj.

Ĉiu orakola komparo devas **antaŭe** kontroli malgrandan nombron de rifuzoj, por eviti enorman referencan ciklon. Alie uzu matematike sendependan ateston per intervaloj kaj sintezaj fluoj. Sen hazarda nek limtempe nedefinita testo.

## Akceptpordegoj

1. Unue: dokumenta HEAD kun ĉi tiu kontrakto atingas completed/success por Native (mezuritaj 202/202, formatter/source integrity) kaj Names Lock sur sama SHA.
2. Poste: implementu precize la ĉi-supran API kaj 12 novajn testojn, sen referencimportoj en `src` kaj sen ŝanĝo de antaŭaj algoritmaj semantikoj.
3. Koda HEAD: readback de branĉo, arbo, ambaŭ bloboj; `gleam format --check src test`, `gleam test`, source integrity kaj Names Lock per du completed/log-pordegoj, kun 214 nur laŭ efektiva mezuro.
4. Fermu Stage20-dokumentadon kaj apartan doc-HEAD CI antaŭ Stage21; neniu duobla run, main, merge aŭ publikigo. Neniu plena datkalkulo en Stage20.
