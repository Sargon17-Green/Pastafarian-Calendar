# Stadio 21 — DISCOVERY 17: larĝa ranga elekto el unu respondfluo

**Malfermo 2026-11-02.** Stage20 estis akceptita ĉe la dokumenta HEAD `ab7910f5aa0d5e2035b5d3d0e69d53b802c9d102`: Native run [41503732206](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41503732206), job `125477522826`, completed/success, **214 testoj pasis, 0 malsukcesis**, Gleam 1.18.1, formato kaj fontintegreco PASS; Names Lock run [41503732208](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41503732208), job `125477522740`, completed/success, sur la **sama** SHA. Tio fermas Stage20, ne Stage21.

## Unu solvita inĝeniera elekto

La aparta kanona testreferenco `test/reference/sauce.gleam` enhavas `choose_rank_wide`, `smallest_power_count`, `build_wide` kaj `choose_wide_loop`. Stage20 traktis nur `1 <= n <= M`; Stage21 traktos **nur `n > M`**. Ĝi donos unu larĝan rangon, ne la kompletan kvinkomponentan daton. La 214 jam verdigitaj testoj ne ŝanĝiĝos.

La kanona referenco paŝas unu post unu dum rifuzo, eble terure longe. Produkta kodo uzos **senrifuzbuklan, matematike ekvivalentan elekton**; la aparte konservita referenco servos kiel orakolo nur por trajektorioj kun pruve maksimume 8 rifuzoj. Ĉi tiu kontrakto ne transprenas efektivigan kodon aŭ fiksaĵojn de aliaj programlingvaj branĉoj.

## Domajno, tipoj, publika API kaj erarprioritato

Konstanto `M = 170141183460469231731687303715884105727`, arbitre preciza entjero (`Int` de Gleam sur Erlang). Nova produkta modulo `src/pastafari/discovery_17_wide_rank.gleam`:

- `wide_rank_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int, seal: Int, n: Int) -> Result(Int, Discovery17Error)`
- `dispatch_discovery_17(context: bootstrap.MonsterContext, queried_bowl_id: Int, seal: Int, n: Int) -> Result(Discovery17Output, Discovery17Error)`
- `select_wide_rank(first: Int, step: Int, n: Int) -> Result(WideSelection, Discovery17Error)`
- `WideSelection(digit_count: Int, space: Int, first_wide: Int, limit: Int, accepted_value: Int, rank: Int)`
- `Discovery17Output(previous: discovery_15_answer_at.Discovery15Output, n: Int, digit_count: Int, space: Int, first_wide: Int, limit: Int, accepted_value: Int, rank: Int)`
- `Discovery17Error`: `InvalidContext(bootstrap.BootstrapError)`, `InvalidBowlId`, `InvalidRankRange`, `InvalidStream`.

La norma dissendilo reuzos `discovery_15_answer_at.dispatch_discovery_15(context, id, seal, 0)` **ekzakte unufoje**, kaj donos la senŝanĝan Stage19-diagnozon en `previous`. Ne rekalkulu saŭcon, ŝtonojn, 46 gutojn aŭ 12 postmiksadojn; ne importu `test/reference` en `src`. Stage20 mallongranga funkcio restas senŝanĝa, kaj unuigita mallonga/larĝa dissendado estas ekster la Stage21-amplekso.

Erarprioritato en la dissendilo: malvalida kunteksto > malvalida bovlo-ID (validaj 1..6) > malvalida rango. Por la pura funkcio, malvalida `n` venku malvalidan fluon. `n <= M` inkluzive 0 kaj negativajn n estas `InvalidRankRange`; `first` devas esti en `[1,M]` kaj `step` devas esti `-1` aŭ `+1`, alie `InvalidStream`. La tagoj kaj sello povas esti negativaj aŭ multe pli grandaj ol 64 bitoj. Ne konvertu al maŝinaj 32-/64-bitaj entjeroj.

## Preciza matematika kontrakto

Prenu la Stage19-fluon `x(j) = 1 + mod(first - 1 + step*j, M)`, kun `mod` ĉiam en `[0,M-1]`.

1. Elektu la plej malgrandan entjeron `k >= 2` por kiu `S = M^k >= n`. Kalkulu ĝin per ripeta multobligo de `M`; neniu ŝvebpunkta logaritmo.
2. Formu la larĝan komencan valoron `W = 1 + sum((x(j)-1)*M^j, j=0..k-1)`. Ĉi tie la plej frua valoro estas la **malplej signifa cifero**, precize laŭ la orakolo. `1 <= W <= S`.
3. Metu `L = floor(S/n)*n`; garantiu `n <= L <= S`.
4. Se `W <= L`, `A=W`. Se `W>L` kaj `step=+1`, `A=1`. Se `W>L` kaj `step=-1`, `A=L`.
5. Redonu `rank = 1 + mod(A-1,n)`, kun `1 <= rank <= n`.

**Pruvo de la senbukla rifuzo:** la orakolo movas `W` je `step` modulo `S` tra la intervala aro `[1,S]`. Ĉiuj malakceptitaj valoroj formas la unu kontinuan voston `[L+1,S]`. Se `W` estas en ĝi, unupaŝa cikla antaŭiro ne povas akcepti antaŭ ĉirkaŭvolvo al 1; unupaŝa retroiro unue eniras `[1,L]` ĝuste ĉe `L`. Sekve la senbukla produktada elekto egalas la unuan akcepton de la referenco. Tempo `O(k)` aritmetikaj operacioj por konstrui `W`, plus `O(1)` por la elekto; BigInt-bitkosto ne estas konstanta.

La limoj `n=M+1`, `n=M^2`, `n=M^2+1`, `n=M^3` devas elekti la ĝustan `k`. Por `n=M^2`, `L=S`, tial ne ekzistas rifuzo. Neniu modulo per nulo. `n` ne ricevas artefaritan maksimumon, sed la testoj uzos limigitajn grandecojn kaj finite multajn paŝojn.

## Ekstera aritmetika antaŭkontrolo (NE Gleam Native)

Oni sendepende komparis senbuklan elekton kun la laŭvorta referenca rifuzbuklo por malgrandaj sintezaj moduloj `m in {5,7,11,13}`, `n in [m+1,m^3+1]`, ĉiu `first in [1,m]` kaj ambaŭ direktoj. El 91,800 kazoj, **80,606** finis la referencon ene de 100 provitaj kandidatoj kaj donis precize la saman rangon; **11,194** estis eksplicite nekomparitaj pro la 100-paŝa limo, ne kalkulitaj kiel PASS. Ĉi tio pruvas nur limigitan aritmetikan antaŭkontrolon; nek Gleam-kompilado nek ĉi-etapa Native CI estis rulitaj.

Ekzempla kontrola fiksaĵo kun sinteza `m=7, first=7, step=-1, n=50`: `k=3, S=343, W=238, L=300, A=238, rank=38`. La produktada `M` restas la supre fiksita granda konstanto.

## Precize 12 novaj testfunkcioj

Nur `test/discovery_17_test.gleam`; antaŭaj **214** Native-verditaj testoj restas. Celataj 226/226 estas prognozo ĝis novaj efektivaj CI-logoj. La orakolo `reference/sauce.choose_rank_wide` povas esti vokata **nur se** sendepende kalkulita rifuzdistanco `<=8`; alie kontrolu matematikajn invariantojn kaj sintezajn atestojn sen alvoki la malrapidan referencon.

1. Baza `(11,21,id=1,seal=0,n=M+1)` kontraŭ la aparta kanona orakolo.
2. Ĉiuj ses bovlo-IDoj por `n=M+1` kontraŭ mallongrifuza orakolo.
3. Antaŭen, malantaŭen kaj sama tago kun `n=M+3`.
4. Transiroj de la fundamenta tago `F-1,F,F+1` kaj ambaŭ direktoj.
5. Selloj `0,±1,±10^30`; antaŭaj diagnozoj konservas precize la originan `seal`.
6. Grandaj signohavaj tagoj `±10^30`; determinismo kaj la inkluziva rangintervalo.
7. Sintezaj unuaj valoroj ĉe `1,M-1,M`, ambaŭ paŝoj, kun `n=M+1`.
8. Larĝaj limoj `n=M^2, M^2+1, M^3`; precizaj `k,S,L` kaj BigInt sen detranĉo.
9. Kaza transiro tuj antaŭ kaj post potenclimoj; ordo de ciferoj (malplej signifa unue) kontraŭ la aparta `build_wide` orakolo.
10. Atestoj pri longa rifuzo kun `n=floor(M^2/2)+1`, validaj komencaj fluoj en la rifuzita vosto kaj ambaŭ paŝoj; ne alvoku la laŭvortan rifuzbuklon.
11. Senmutacia Stage19-diagnozo, interplektitaj kontekstoj, `previous.index=0`, kaj invariantoj `1<=W<=S`, `A<=L`, `1<=rank<=n`.
12. `n=0,-1,M,M-1`, malvalidaj `first=0,M+1`, `step=0,2`, bovloj `0,7,-1`, kaj negativaj `retry_budget/recovery_depth`; asertu la erarprioritaton.

## Devigaj etapaj pordegoj

1. Antaŭ ajna Stage21-produktokodo: la **nova kontrakta HEAD** devas esti completed/success por Native (almenaŭ 214/214, formato, fontintegreco) kaj Names Lock, ĉe ekzakte la sama SHA. Neniu duobla CI-dispatch.
2. Poste efektivigu la listigitan API kaj precize 12 novajn testfunkciojn; neniu ekstera orakolo en `src`, neniu ŝanĝo al jam akceptita Stage20.
3. Nova koda HEAD: efektivaj `gleam format --check src test`, `gleam test`, senmutacia fontkontrolo, kompletaj Native kaj Names Lock same-SHA. Raportu konkretan testnombron, ne prognozon.
4. Fermu Stage21-dokumentadon kaj atendu ĝian propran dokumentan HEAD-CI antaŭ Stage22. Neniu `main`, merge, publikigo, aŭ kompleta kvinkomponenta dato.

**Post ĉi tiu sola kontrakta komito:** Stage20 estas fermita; Stage21 havas kontrakton, sed **ne** havas produkton, Native-PASS aŭ ĝeneralan Stage21-PASS.
