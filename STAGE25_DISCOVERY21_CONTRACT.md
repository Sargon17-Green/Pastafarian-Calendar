# Stadio 25 — DISCOVERY 21: ordkonserva aro de eksplicitaj pordeg-interspacaj petoj

**Kontrakta malfermo: 2026-11-04.** Stage24 estis akceptita ĉe la fina metadata HEAD `0d60e2c4d2f4af7c96ebe620d972c813ec889b76`: [Native 41869792928](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41869792928), job `126713415603`, `completed/success`, **262/262 testoj, neniu malsukceso**, Gleam 1.18.1 / OTP28, formato kaj fontintegreco PASS; artefakto `13342769597`, SHA256 `64846bd564b53b9a045d774dac347d2426784bf465eaa2782f5831edaec04764`. [Names Lock 41869793231](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41869793231), job `126713418030`, `completed/success` ĉe la sama SHA. La kontrakta commit Stage25 ne asertas Native-PASS por si mem.

## Elekto kaj epistemaj limoj

La akceptita Stage24 liveras **unu** tipitan specimenon de pordeg-interspaco laŭ eksplicita `queried_bowl_id`; kanona referenco montras ses bovlojn kaj `min_gate_gaps_per_year=6`, sed tio **ne** difinas ordon, precizan nombron, aŭ interrilaton de kalendaraj pordegoj. Tial ĉi tiu stadio implementu nur **ordkonservan aron de eksplicitaj petoj**; ĝi ne konstruu kanonan jaran pordegoserion, ne deduktu bovloelekton, ne sumigu jarlongon, ne kalkulu plenan daton. Kie mankas aŭtoritata regulo, ne inventu ĝin.

## Mezurebla API kaj konduto

- Nova produktmodulo: `src/pastafari/discovery_21_gate_batch.gleam`; nova testa dosiero: `test/discovery_21_test.gleam`. Ne ŝanĝu Stage01–24, la kanonan referencon, frostigitajn nomojn aŭ workflow.
- `dispatch_discovery_21(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int)) -> Result(List(discovery_20_gate_gap.GateGapOutput), discovery_19_interval_value.Discovery19Error)`.
- Por `[b1, ..., bk]`, apliku `discovery_20_gate_gap.dispatch_discovery_20(context, bi)` sinsekve, **precize unufoje po elemento**, konservante la saman neredaktitan kuntekston. Ĉe `Ok` redonu `k` erojn samorde; ĉiu rezulto identu al aparta Stage24-voko, kun `gap` en `[42,963]`, sigelo 1 kaj ĝusta `queried_bowl_id`.
- Unua `Error` en la eniga ordo tuj haltigu traversadon, sen voki postajn erojn; erara tipo kaj prioritato estu ekzakte tiuj de Stage24. Duplicitaj bovlo-identigiloj estas validaj apartaj petoj, ne kaŝa sen-duobligo.
- Malplena listo: `Ok([])` sen alvoki Stage24 kaj **sen validigi la neuzatan kuntekston**. Tio estas API-neŭtrala rando, ne aserto pri valida kalendara jaro.
- Ne trudigu ses-elementan limon aŭ jaran ordon: la enigo estas ajna finia listo de entjeroj; memoro kaj nombro da Stage24-vokoj kresku `O(k)` kun longo `k`, sen tutmonda stato.
- Komforta API: `gap_values_for_days(calculation_day: Int, target_day: Int, requested_bowl_ids: List(Int)) -> Result(List(Int), discovery_19_interval_value.Discovery19Error)` kreu unu bazan kuntekston, delegu al `dispatch_discovery_21` unufoje kaj redonu la `gap`-valorojn samorde, aŭ la identan eraron.

## Sendependa orakolo kaj testaro

Ne kopiu produktan algoritmon aŭ fixture el alia branĉo. Testu ĉiun ne-eraran eron kontraŭ akceptita Stage24 por kompona ekvivalento; aparte, uzante `test/reference/sauce.gleam`, konstruu matematikajn orakolrezultojn **nur kiam** antaŭkalkulitaj rifuzoj estas maksimume ok. Por aliaj kazoj raportu nur Stage24-ekvivalentecon, ne falsan sendependan orakolan PASS. La orakolo ne importu `discovery_21_gate_batch` por sia kalkulo. Ne prenu la produkton kiel sian propran orakolon.

Dek du publikaj `*_test`-funkcioj, ĉiu aparte mezurebla:
1. Malplena listo kun valida kunteksto -> `Ok([])`, neniu elvoko.
2. Malplena listo kun malvalida kunteksto -> sama `Ok([])`; neniu kaŝa validigo.
3. Unu peto por ĉiu el 1..6: sama Stage24-rezulto kaj sendependa limigita orakolo kie disponebla.
4. `[1,2,3,4,5,6]`: ses eroj, preciza ordo kaj valoroj.
5. Inversa ordo `[6,5,4,3,2,1]`: rezultoj kaj identigiloj en inversa ordo.
6. Ripetoj `[3,3,3,1,3]`: ne deduplikigu; determinismaj samaj rezultoj por sama bovlo.
7. Same-taga, inversa kaj negativaj tagparoj per pluraj bovloj.
8. Randoj `F-1, F, F+1`, ambaŭ tagargumentoj, nenia ŝanĝo de inkludeco.
9. Grandegaj pozitivaj kaj negativaj tagoj, pli grandaj ol `M²`, sen 64-bita supozo.
10. Nevalidaj identigiloj ĉe la komenco, mezo kaj fino: unua eraro en eniga ordo.
11. Malvalida `retry_budget` / `recovery_depth` kun nevalida bovlo: heredita `InvalidContext` prioritato; diagnozoj de apartaj kuntekstoj restas izolitaj.
12. Komforta API kontraŭ plena `dispatch_discovery_21`, kaj limigita per-elementa sendependa orakolo kie sekure.

Antaŭaj 262 Native-testoj restu netuŝitaj; prognozo post koda aldono = **274**, ne mezurita ĝis CI. Verigu la nombron de novaj publikaj `*_test()`.

## Akceptaj pordegoj kaj dislimoj

1. **Kontrakta HEAD**: aŭtomata Native `gleam format --check src test`, `gleam test` **262/262**, fontintegreco kaj Names Lock SUCCESS sur **ekzakte sama SHA**, antaŭ nova Stage25-produktkoda commit. `queued/in_progress` estas nek PASS nek blokado.
2. **Koda HEAD**: nova modulo + 12 testoj + ĝisdatigita metadata, sen ŝanĝi antaŭajn modulojn. Akceptu nur kun Native **274/274 mezuritaj**, formato, fontintegreco, Names Lock same-SHA SUCCESS. Ŝanĝu nur laŭ pruvitaj malsukcesoj.
3. **Dokumenta fermo** kaj **fina metadata HEAD** estu apartaj commit-oj, ĉiu kun sia propra same-SHA Native kaj Names SUCCESS antaŭ `LAST_COMPLETED_STAGE=25` aŭ malfermo de Stage26.
4. Nenio ĉi tie estas jara pordegoserio, jarlongo, plena kalendaro, `main`-merge aŭ ekstera publikigo.

## Koda validigo kaj dokumenta fermo (2026-11-04)

La kontrakta HEAD `da95873b6d511999b6845e9ff6f6685e045ce545` pasis [Native 41870491929](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870491929) kun **262/262** testoj, same-SHA [Names Lock 41870491914](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870491914) sukcesis. Koda commit `fdefbd9f899cd6fc410dcf3b1d2caa89913ff7a5` aldonis la ordkonservan eksplicitan aron kaj dek du apartajn testfunkciojn.

La unuaj malsukcesoj estis precize diagnozitaj, sen aserti testojn kiuj ne ekzekutiĝis: [Native 41871125579](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41871125579) montris **tri formatŝanĝojn** en la nova testdosiero; ĉe `a7181166338697187c51121e4e2ef00353ea9bae`, [Native 41871606423](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41871606423) montris **tipan eraron** pro malsama interpreto de `==` kaj la pipa operatoro; ĉe `f7144b89d5e5762b7c1665da3438d8ffde58d408`, [Native 41871794526](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41871794526) montris denove **formatan malkongruon** ĉe la aserto. En ĉiuj tri kazoj testoj **ne ruliĝis**. La izola korekto ĉe `7584d2b00583ff51d1b42b22f2f003ee48450b35` uzis apartan bulean valoron antaŭ la aserto; la produkta semantiko restis netuŝita.

Ĉe tiu ekzakte sama koda SHA [Native 41872000434](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41872000434), job `126721297807`, estis `completed/success`, kun **274/274 testoj, neniu malsukceso**, Gleam **1.18.1**, Erlang/OTP **28**, kanona formatkontrolo kaj senŝanĝaj fontoj; artefakto `13344812488`. [Names Lock 41872000470](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41872000470), job `126721297751`, estis `completed/success` je **la sama SHA**. Tio akceptas **nur la kodan HEAD** de Stage25.

**Ĉi tiu aparta dokumenta ferm-HEAD ankoraŭ devas pruvi siajn proprajn same-SHA Native 274/274, formato/fontintegreco kaj Names Lock.** Poste aparta fina metadata HEAD devas same pasi. `LAST_COMPLETED_STAGE=24` ĝis ambaŭ sekvaj pordegoj pasas. Neniu kronologia pordegoserio, nova jarlongo, plena datkalkulo, `main`-merge aŭ publikigo estas asertita.
