# Stadio 18 — DISCOVERY 14: la unua respondo kaj direkto de unu bovla demando

**Stato 2026-10-31:** nur mezurebla kontrakto; neniu Stage18-produktkodo aŭ nova Stage18-testaro ankoraŭ kreita. Stage17 estas koda GREEN ĉe `26a44311c764c4b6e5d0205c93a4e92f4bf6f3d8` (178/178 Native; Names Lock SUCCESS); la dokumenta HEAD de ĉi tiu kontrakto mem bezonas apartan Native/Names-verifikon antaŭ Stage18-koda akcepto.

## Motivado kaj limigita amplekso

La kanona testo-referenco `test/reference/sauce.gleam::ask_bowl` dependas de la konservita 46-a guta bovloordo, de la ses finaj bovlaj valoroj kaj de ekstera `seal`. Stage17 jam trovas la sekvan bovlon sen modifi la ordon. Stage18 produktos precize `first` kaj `direction_step` por **unu** demandita bovlo, sen generi `answer_at`, `choose_rank`, datkomponentojn aŭ plenan daton. La sello `seal: Int` estas enira argumento, ne kaŝe derivita valoro; ĝia tuta entjera domajno estas permesita.

## Produktada interfaco kaj erar-ordo

Krei `src/pastafari/discovery_14_ask_bowl.gleam`:
- `ask_bowl_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int, seal: Int) -> Result(Discovery14Answer, Discovery14Error)`.
- `dispatch_discovery_14(context: bootstrap.MonsterContext, queried_bowl_id: Int, seal: Int) -> Result(Discovery14Output, Discovery14Error)`.
- `Discovery14Answer(first: Int, direction_step: Int)`; `Discovery14Output` konservu la kompletan validan kuntekston, ĉiujn ses finajn bovlojn, la latĉitan ordon, demanditan kaj sekvan identigilojn, la eniran `seal` kaj la `Discovery14Answer`.
- `Discovery14Error` distingas `InvalidBowlId` de `InvalidContext(bootstrap.BootstrapError)`. Unue validigu la kuntekston en dispatch; se ankaŭ identigilo estas malvalida, redonu la kuntekstan eraron. Validaj bovlo-IDoj estas nur 1..6.

Reuzu la produktan Stage17-dispatch por akiri la ses finajn bovlojn, latĉitan ordon kaj sekvan identigilon; ne reruligu 46 gutojn, 12 postmiksadojn, aŭ la propran sekvan serĉon. Ne importu `test/reference` en produktadon.

## Aritmetiko (arbitre precizaj entjeroj)

Fiksu `M = 170141183460469231731687303715884105727`, `save(x) = 1 + mod(x-1,M)` kun nenegativa modulo; `B_j` estas la fina bovlvaloro de identigilo `j`; `next` estas la Stage17-sekvanto; `s = seal`. Kalkulu sendepende de la testa orakolo:

```text
first = save((B_id + s + 181)^2 + 179*B_next + s)
direction_number = save((first + s + 194)^2 + 193*first + 197*B_6)
direction_step = +1 se mod(direction_number,2)=1; alie -1
```

La rezulto devas plenumi `1 <= first <= M` kaj `direction_step ∈ {-1,+1}`. Neniu ŝanĝo al historia bovloordo aŭ al la ses bovlaj valoroj. La konstanto `194` estas ĝuste `1+193` de la referenca formulo, ne nova parametra interpreto.

## Aparta orakolo kaj 12 testfunkcioj

La valida-domena orakolo estas `test/reference/sauce.gleam::ask_bowl(sauce.sauce(a,b),id,seal)`, ĝiaj `first` kaj `direction_step` komparataj aparte kun la produktada rezulto. Ĝi ne validigas erar-prioritaton; tiu estas rekta kontrakta aserto. 12 funkcioj en `test/discovery_14_test.gleam`:

1. Unu kazo `(11,21,id=1,seal=0)` kontraŭ la orakolo.
2. Ĉiuj ses identigiloj por unu tagparo, kun orakolo.
3. Antaŭa kaj inversa tagdirektoj `(11,21)` kaj `(21,11)`.
4. Sama tago `(0,0)` kaj la fundamenta paro `(F,F)`.
5. Transiroj `(F-1,F+1)` kaj `(F+1,F-1)`.
6. Grandaj entjeroj `±10^30` por la du tagoj en ambaŭ direktoj.
7. Pozitivaj, negativaj kaj nulaj selloj `s=0,1,-1,10^30,-10^30`.
8. Ĉiam `1 <= first <= M` kaj `direction_step` estas ĝuste `-1` aŭ `+1`.
9. Verifi ke `direction_step` kongruas kun la pareco de la kalkulita `direction_number`, ne nur hazarde kun la orakolo.
10. Komparu la bovlojn, latĉitan ordon kaj sekvan ID kontraŭ la Stage17-produktada diagnozo; nenio mutaciiĝas.
11. Interplektitaj validaj kuntekstoj konservas proprajn diagnozojn, staton, sellojn kaj rezultojn.
12. Malvalidaj IDoj `0,7,-1`; retry/recovery negativaj kunteksteraroj havas prioritaton antaŭ malvalidaj IDoj.

Konservu ĉiujn 178 antaŭajn testojn. **190/190 estas prognozo**, ne Stage18 Native-rezulto. Apartaj orakolaj referencoj restu nur en la testdosierujo; neniu alikoda branĉa fixture.

## Akceptpordegoj kaj daŭrigo

Antaŭ Stage18-koda akcepto, certigu ke la Stage17 dokumenta HEAD estas Native+Names `completed/success` sur la sama SHA; ne prenu nur la kodan SHA kiel pruvon de la posta dokumenta HEAD. Stage18-kodo bezonos `gleam format --check src test`, `gleam test` kun precize mezurita nombro kaj neniuj malsukcesoj, senmutacian source-integrity, Native CI-kontrolon sur la ĝusta SHA kaj apartan Names Lock. Post koda GREEN ankaŭ posta dokumenta HEAD postulas propran CI. Neniu duobla CI-ekigo, main/merge aŭ ekstera publikigo.
