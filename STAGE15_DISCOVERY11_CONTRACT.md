# Stadio 15 — DISCOVERY 11: 46 sinkronaj verŝoj sur ses bovloj

**Stato (2026-10-31):** kontrakto sola; la kodo, la 12 novaj testoj kaj Stage15 Native ankoraŭ ne estas faritaj.

## Pordo de la antaŭa stadio

Stage14 koda HEAD `33c0d42ab75ae0dc01732147113830436c7bcdb0`: Gleam 1.18.1 / OTP 28; Native `41215807946`, job `124579962007`, formato kaj fonta integreco PASS, precize **142/142**; artefakto `13046989969`, SHA256 `9f659ef45a1b908b54bf54036dec01fbd3a286453be8f82a84aab4d1902d90d9`; Names Lock `41215808009`, job `124579962051`, SUCCESS. Post la dokumenta commit devas ankaŭ esti akceptita ĝia aparta HEAD antaŭ nomi Stage14 komplete fermita ĉe tiu HEAD.

## API kaj amplekso

Krei memstaran `src/pastafari/discovery_11_pouring.gleam` kun:

- `pour_visible_drops_for_days(calculation_day: Int, target_day: Int) -> #(List(Int), List(Int))`. La unua listo estas ses bovloj post ekzakte 46 gutoj; la dua estas la permuta ordo ĉe guto 46.
- `dispatch_discovery_11(context: bootstrap.MonsterContext) -> Result(Discovery11Output, bootstrap.BootstrapError)`. La eligo enhavu la kompletan validan kuntekston, la ses bovlojn kaj la finordon; kontraŭvalida kunteksto redonu la saman bootstrap-eraron sen ŝanĝo de prioritato.
- Uzi la antaŭajn **proprajn** produktmodulojn por komencaj bovloj, la 46 videblaj gutoj, ŝtonoj kaj la permut-ordo. La produktkodo neniam importu `test/reference` aŭ kodon de fremda lingva branĉo.

Neniu post-verŝa 12-foja miksado, neniu plena datokonverto kaj neniu ŝanĝo al la kvin datokomponentoj.

## Kanona matematiko, indeksado ekde 1

Kun `M=170141183460469231731687303715884105727`, `save(x)=1+mod(x-1,M)` kaj restaĵo ne-negativa. Lasu `B^{(0)}` esti la ses Stage14-bovloj. Por ĉiu `i=1..46`, la kanona videbla guto estas `d_i`, ĝia ŝtono `T_i=(w_i,b_i,s_i,k_i,r_i)`, kaj `O_i` estas la ses-elementa permuto devenanta de `d_i`.

La verŝoj laŭ **pozicio en O_i** estas:
`V_1=save(d_i²+w_i*B[O_i[1]]+3i)`,
`V_2=save(d_i²+b_i*B[O_i[2]]+5i)`,
`V_3=save(d_i²+s_i*B[O_i[3]]+7i)`,
`V_4=V_5=V_6=0`.

Por ĉiu **bovla identigilo** `j=1..6`: `p=position_of(O_i,j)`; `prev=O_i[wrap1(p-1,6)]`; `next=O_i[wrap1(p+1,6)]`; `kind=[1,2,3,4,5,1][p]`; `field=stone_value(T_i,kind)`. Difinu
`S=B[j]+2B[prev]+3B[next]+V[p]+d_i+field`;
`B'[j]=save(S²+5B[prev]*B[next]+i*p)`.

**Esenca invariaĵo:** ĉiuj ses `B'[j]` en unu guto estu kalkulitaj de la sama nemodifita antaŭa `B` (sinkrona transiro, ne mutacio de unu bovlo post alia). La lasta `O_46` restas aparte. La sola fina eligo estas `#(B^(46), O_46)`.

## Sendependa orakolo kaj testaj pordegoj

Nur en `test/discovery_11_test.gleam`, kalkuli la atendatan paron per `test/reference/sauce.gleam::apply_visible_drops_to_bowls` kun `reference/core.work_counts`, `reference/core.build_stones`, `reference/sauce.build_hidden_drops`, `reference/sauce.build_visible_drops` kaj `reference/sauce.initial_bowls`. La produktado devas havi propran algoritmon kun sendependa datumfluo kaj sen rekopii la referencan rekursian efektivigon. Konservi la 142 antaŭajn testojn.

Plani **12** testfunkciojn: (1) ses eliraj bovloj; (2) ordo ĝusta permuto de 1..6; (3) fundamento al fundamento; (4) ordinara antaŭen; (5) ordinara inverso; (6) alia sama tago; (7) transiro fundamento-1 ĝis fundamento+1 ambaŭdirekte; (8) grandaj pozitivaj/negativaj BigInt-tagoj; (9) ĉiu bovlo en [1,M]; (10) ripeteblo kaj almenaŭ unu unu-guta sinkrona sentinelo; (11) du interplektitaj validaj kuntekstoj konservantaj diagnozojn; (12) negativa retry/recovery kun retry-prioritato. Celata suma nombro: **154**, nur prognozo ĝis Native.

Akcepto nur post `gleam format --check src test`, `gleam test`, fonta integreco, 154/154 Native kompletigitaj kun job/artefakta SHA256 kaj Canonical Names Lock completed/success sur la **sama nova HEAD**. Komenca koda akcepto ne egalas al fina dokumenta HEAD-akcepto. Nek main/merge nek ekstera publikigo.
