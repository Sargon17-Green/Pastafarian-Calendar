# Stadio 23 — DISCOVERY 19: entjera valoro en fermita intervalo

**Kontrakta malfermo: 2026-11-03.** Stage22 finis ĉe fina metadata HEAD `9b9a32038f406ae706010f33b148f5d9efd2a6eb`; [Native run 41688438429](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41688438429), job `126100309491`, completed/success **238/238 testoj, 0 malsukcesoj**, Gleam 1.18.1/OTP28, formato kaj netuŝita fonto PASS, artefakto `13255946382`, SHA256 `a946ffdc6fd9467975dca3d70170e5bc2a232bd08c63c80167e5faf5647ec121`; [Canonical Names Lock run 41688438218](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41688438218), job `126100308354`, completed/success ĉe ekzakte tiu SHA. `LAST_COMPLETED_STAGE=22` estas registrita. Ĉi tiu nova stadio ne modifas antaŭajn kalkulojn.

## Unu inĝeniera decido: fermita intervalo, ne tuta kalendaro

La aparta kanona `test/reference/sauce.gleam` enhavas `choose_rank(stream, n)` por ĉiu pozitiva `n`; Stage22 havas jam akceptitan `discovery_18_choose_rank.dispatch_discovery_18`, kiu kalkulas unu respondfluon kaj unu rangon sen rifuzbuklo. La sekva minimuma necesa komponanto estas transformi rangon en valoron en **inkluziva** entjera intervalo `[lower, upper]`, sen plia saŭco.

Por `lower <= upper`, `n=upper-lower+1`, `1<=rank<=n`, **`value=lower+rank-1`**; do `lower<=value<=upper`. Por `lower > upper`, rezultu `InvalidInterval` sen modulo aŭ produktada kalkulo de rango. Erlang/Gleam `Int` ne limiĝu al 64 bitoj. `n <= M` kaj `n > M` delegu senŝanĝe al la jam akceptita Stage22-elektilo. `M=170141183460469231731687303715884105727`. La fakaj limoj `[42,963]` kaj `[252,5778]` el `test/reference/core.gleam` estas testekzemploj, **ne** aserto ke ĉi tiu stadio jam produktas veran pordegon aŭ jaron. Elekto de specifa sigelo, bovlo kaj kalendara pordego estas por postaj stadioj.

## Publika API, rezultoj kaj erarprioritato

Nova `src/pastafari/discovery_19_interval_value.gleam`:
- `select_interval(first: Int, step: Int, lower: Int, upper: Int) -> Result(IntervalSelection, Discovery19Error)`.
- `value_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int, seal: Int, lower: Int, upper: Int) -> Result(Int, Discovery19Error)`.
- `dispatch_discovery_19(context: bootstrap.MonsterContext, queried_bowl_id: Int, seal: Int, lower: Int, upper: Int) -> Result(Discovery19Output, Discovery19Error)`.
- `IntervalSelection(lower: Int, upper: Int, n: Int, selection: discovery_18_choose_rank.RankSelection, rank: Int, value: Int)`.
- `Discovery19Output(previous: discovery_18_choose_rank.Discovery18Output, lower: Int, upper: Int, n: Int, value: Int)`. La `previous` entenu la precizan Stage22-strukturon, inkluzive Stage19-originan fluon, nekopiitan saŭcon kaj diagnozojn.
- `Discovery19Error`: `InvalidContext(bootstrap.BootstrapError)`, `InvalidBowlId`, `InvalidInterval`, `InvalidStream`.

Pura `select_interval` unue validigu `lower<=upper`, poste delegu `discovery_18_choose_rank.select_rank(first,step,n)` **unufoje** kaj mapu ĉiujn originajn erarojn. `dispatch_discovery_19` delegu al `discovery_18_choose_rank.dispatch_discovery_18` ekzakte unufoje; ĝi ne faru apartan alvokon al Stage19, ne duobligu saŭcon aŭ respondfluon. Por `lower>upper`, eblas transdoni `n=0` al Stage22-dispatĉo por konservi ĝian konatan validigan prioritaton. Erarordo de dispatĉo: **InvalidContext > InvalidBowlId > InvalidInterval > InvalidStream**. Tio inkluzivas malvalidajn `retry_budget` kaj `recovery_depth`, bovlojn 0,7,-1 kaj kontraŭdirajn limojn; en la pura elektilo intervalo unue. Neniu `test/reference`-importo en `src`, neniu sola 64-bita limo, neniu modifo de Stage19–22 aŭ de orakoloj.

## Postkondiĉoj, sendependeco kaj limoj

Kiam `lower<=upper`, la rezulto estu ekzakte `lower+Stage22.rank-1`; `lower<=value<=upper`, `rank=value-lower+1`, `n=upper-lower+1`. Pura Stage22 `RankSelection` restu nesanĝita. Ĉiu validigita dispatĉo redonu la originan Stage22 `previous`, kiu enhavas unu Stage19-demando ĉe indekso 0 kaj neniuj flankefikoj. Same-tagaj, antaŭaj, postaj kaj grandegaj signohavaj tagoj kaj sigeloj konservu identajn komputajn valorojn. La aparta kanona malrapida `reference/sauce.choose_rank` estu vokata nur kiam **sendepende** kalkulita sinsekvo de rifuzoj havas maksimume **8** paŝojn; alie komparu rekte la produktan Stage22-elektilon kun la nova intervalo + limoj. Ne fabrikiku diferencialajn PASS por nekovritaj kazoj. Nenia aserto pri kompletaj kalendaraj datoj.

## Precize 12 novaj testfunkcioj

La sola nova testdosiero: `test/discovery_19_test.gleam`. La antaŭaj 238 testoj restu netuŝitaj; 250 entute estas prognozo, **ne** mezurita rezulto.

1. Baza [42,963] por (calculation_day=11,target_day=21,id=1,seal=1), egaleco al sekura kanona orakolo.
2. Baza [252,5778] kaj [4,123] ĉe konfirmita fluo, inkluziva ofseto kaj ekstremaj rangoj.
3. Degenera intervalo `lower=upper`, inkluzive nulon kaj negativan limon: `value=lower`, rango 1.
4. Intervaloj `[0,M-1]`, `[0,M]`, `[-M,0]` ĉe ĝusta ŝaltilo `n=M/M+1`; assert `ShortRank`/ `WideRank`.
5. Sintezaj antaŭenkuraj kaj malantaŭenkuraj fluoj `first=1,M-1,M`, `step=±1`, malgrandaj pozitivaj intervaloj, ĉiam ene de limoj.
6. Grandegaj arbitre precizaj limoj `lower=-(10^40)`, `upper=10^40` plus grandaj ŝovitaj intervaloj; ĝusta rango + ofseto.
7. Ĉiuj ses bovloj kun sama saŭco, samaj originalaj tagoj, `seal=1`; uzu sekuran orakolon laŭ antaŭkontrolo.
8. Sigeloj `0,±1,±10^30` kaj ambaŭ direktoj; konservu originalan sigelon kaj originajn Stage22-datumojn.
9. Fundamentaj tagoj `F-1,F,F+1`, retroaj kaj samtagaj demandoj, interplektitaj kuntekstoj sen poluado.
10. Konserva ekvivalento: nova `previous` egala al sendependa Stage22-dispatĉo, kaj `value=lower+previous.rank-1`; neniu duobla antaŭa kalkulo.
11. Longaj rifuzoj `n=floor(M/2)+1` kaj `n=floor(M²/2)+1`; testu deklivon, precizan ofseton, kaj min/max sen voki malrapidan orakolon.
12. Prioritato kaj eraroj: `lower>upper`, malvalida fluo, `id=0/7`, negativa `retry_budget/recovery_depth`; verifu precize `InvalidContext > InvalidBowlId > InvalidInterval > InvalidStream`.

## Same-SHA akceptaj pordegoj

1. La kontrakta HEAD devas pasi aŭtomatajn Native `gleam format --check src test`, netuŝitan fonthashon, **238/238** kaj Canonical Names Lock **completed/success sur sama SHA** antaŭ produkta kodo. `queued` / `in_progress` neniam estas PASS nek blokado.
2. Poste aldonu nur `src/pastafari/discovery_19_interval_value.gleam`, `test/discovery_19_test.gleam` kaj etapajn metadatenojn; precize **12** novaj testoj, 250 prognozitaj entute. Neniuj ŝanĝoj al la antaŭaj fontoj/testoj aŭ aparta orakolo.
3. Koda HEAD: Native **250/250 mezuritaj**, formato kaj fontintegreco PASS, Names Lock SUCCESS sur la sama SHA.
4. Aparta dokumenta HEAD kaj memstara fina metadata HEAD, ĉiu kun propra sam-SHA Native kaj Names SUCCESS, antaŭ `LAST_COMPLETED_STAGE=23` kaj Stage24.
5. Neniu ŝanĝo de `main`, merge, publikigo, kalendara pordego aŭ kvinkomponenta dato.

## Koda HEAD akceptita; dokumenta HEAD devas esti aparte kontrolita

La kontrakta HEAD `da68c1aa24e7a292aa7eccdc0a3fa59b5d2f2c87` trapasis [Native 41688948597](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41688948597), 238/238, kaj [Names 41688948574](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41688948574), SUCCESS sur sama SHA.

Unua Stage23-kodo ĉe `bcc97eb979793c8bd9325af53a4fa38e7294ef4c` aldonis la produktan modulon kaj 12 novajn testfunkciojn; [Native 41689347543](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689347543) malsukcesis nur ĉe formato antaŭ ol ruli testojn. Formata korekto `74078b30a5f558098203cb60a76b3a3de4ae1472` rezultigis [Native 41689614933](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689614933): eraro dum kompilado de testoj pro malĝusta aliro al enmetita kunteksta kampo; testoj ne ruliĝis. La preciza alirkorekto estis farita ĉe `999151313e66815d4910a0ba072bb04eea365262`.

**Mezurita koda akcepto:** [Native 41689906383](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689906383), job `126105440215`, completed/success sur ekzakte `999151313e66815d4910a0ba072bb04eea365262`, **250/250 testoj, 0 malsukcesoj**, Gleam 1.18.1 / OTP 28, read-only formato, netuŝita spura fonto PASS. Artefakto [13256484893](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689906383/artifacts/13256484893), SHA256 `3305b79fd9717e46a5969e164eef5e7130686175e4263cd0812dbfcbb618eb26`. [Canonical Names Lock 41689906121](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689906121), job `126105438461`, completed/success ĉe la **sama SHA**.

La 12 novaj testfunkcioj estas laŭ la kontrakta listo kaj 238 antaŭaj testoj restas. Ĉi tiu noto estas dokumenta fermo **ne** fina stage-akcepto: dokumenta commit devas mem trapasi Native kaj Names; nur poste eblas aparta fina metadata HEAD kun siaj propraj du CI-pordegoj. `LAST_COMPLETED_STAGE=22` restas ĝis la fina akcepto. Neniu `main`, merge, publikigo aŭ plena dato.
