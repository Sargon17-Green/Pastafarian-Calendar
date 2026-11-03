# Stadio 24 — DISCOVERY 20: kanona pordeg-interspaca specimeno

**Kontrakta malfermo: 2026-11-03.** Stage23 estis akceptita ĉe la fina metadata HEAD `9cd1bf9e6ef8e7bbb3f1ebd19358ffe51d61972c`: [Native 41712396030](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712396030), job `126183510044`, completed/success, **250/250 testoj, 0 malsukcesoj**, Gleam 1.18.1 / Erlang/OTP28, formato kaj fontintegreco PASS; artefakto `13268251550`, SHA256 `58850a9c37c80d0fb6e2896922c04f3ccf424b52af529bf1580c2f830a7456ad`. [Canonical Names Lock 41712395919](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712395919), job `126183509782`, completed/success ĉe la sama SHA. `LAST_COMPLETED_STAGE=23` en la nova kontrakta HEAD; tio ne asertas ke Stage24 jam estas akceptita.

## Elektita unuopa inĝeniera sekvaĵo

La aparte konservita kanona referenco `test/reference/core.gleam` difinas `gate_gap_min=42`, `gate_gap_max=963` kaj `seal_gate_gap=1`. La akceptita Stage23 permesas elekti valoron en ajna fermita intervalo uzante eksplicitan bovlon kaj sigelon. La plej malgranda sekva komponanto estas **tipita specimeno de unu pordeg-interspaco por eksplicite donita bovlo**, kun kanonaj fiksaj limoj kaj sigelo; **ne** kalendara pordegoserio, ne aŭtomata bovloelekto, ne nova jarlongo kaj ne plena dato.

Por ĉiu valida `queried_bowl_id` en 1..6, la nova komponanto devas delegi al la ekzistanta `discovery_19_interval_value.dispatch_discovery_19(context, queried_bowl_id, 1, 42, 963)` **ekzakte unufoje** kaj sen rekalkuli saŭcon. Rezulto estas `gap` en fermita intervalo [42,963], kun preciza `n=922`, `gap=42+rank-1`, `rank=gap-41`. La antaŭa Stage23-strukturo restu netuŝita; ĝia enmetita Stage22-strukturo, fluo, demanda indekso 0, sigelo kaj diagnozoj restu identaj. La elektebla bovlo restu eksplicita por ke posta stadio povu difini sekvencon laŭ aŭtoritata regulo, sen konjekto ĉi tie.

## Produkta API kaj senŝanĝa erarordo

Kreu **nur** `src/pastafari/discovery_20_gate_gap.gleam` kaj `test/discovery_20_test.gleam` (plus etapa metadata ŝanĝo).

- Publikaj konstantoj: `gap_min=42`, `gap_max=963`, `gap_seal=1`; ili devas korespondi al la tri apartaj kanonaj konstantoj, sed `src` ne importu `test/reference`.
- Publika tipo `GateGapOutput(previous: discovery_19_interval_value.Discovery19Output, queried_bowl_id: Int, seal: Int, gap: Int)`. Konservu la antaŭan rezulton rekte, ne reconstruu ĝin.
- `dispatch_discovery_20(context: bootstrap.MonsterContext, queried_bowl_id: Int) -> Result(GateGapOutput, discovery_19_interval_value.Discovery19Error)`.
- `gap_for_days(calculation_day: Int, target_day: Int, queried_bowl_id: Int) -> Result(Int, discovery_19_interval_value.Discovery19Error)`; ĝi konstruu konatan bazan kuntekston kaj delegu al `dispatch_discovery_20` nur unufoje.
- Neniu propra validigo aŭ ŝanĝo de prioritato: heredita `InvalidContext > InvalidBowlId` por ĉi tiu ĉiam valida intervalo; aliaj Stage23-erartipoj konserviĝu sen artefarita modifo.
- Sen ŝanĝo al Stage01–23, al kanona `test/reference`, al `main`, aŭ al frozen names. Neniu kaŝita stato aŭ unika 64-bita aritmetika supozo.

## Postkondiĉoj kaj sendependa oracle

Por ĉiu sukcesa elvoko: `output.gap == output.previous.value`, `output.seal==1`, `output.queried_bowl_id==queried_bowl_id`, `output.previous.lower==42`, `output.previous.upper==963`, `output.previous.n==922`; ĝuste unu antaŭa Stage23-dissendo. Datumoj devas esti ekvivalentaj al aparta alvoko de la jam akceptita Stage23 API kun fiksaj parametroj. Por vera diferenciga orakolo, uzu la aparte konservitan kanonan `test/reference/sauce.gleam` kaj matematike sendependan antaŭkontrolon: `reference/sauce.choose_rank` estas permesata **nur** kiam antaŭkalkulitaj rifuzoj estas ne pli ol ok; aliaj kazoj ricevu ekvivalencan kontrolon kontraŭ Stage23, ne falsan oracle-PASS. Ne kopiu la produktan algoritmon en la orakolon, ne pruntu kodon de alia branĉo.

## Dek du apartaj testfunkcioj (262 entute nur prognozitaj)

1. `11 -> 21`, bovlo 1: valorintervalo kaj rangofseto kontraŭ sekura kanona orakolo.
2. Ses bovloj 1..6 por samaj tagoj kaj sigelo 1; ĉiu konservas la ĝustan `queried_bowl_id`.
3. Bazo `F-1`, `F`, `F+1` por ambaŭ tagargumentoj: neniu ŝanĝo de inkludeco.
4. Samtagaj, inversaj kaj pli fruaj tagoj: preciza ekvivalento al eksplicita Stage23.
5. Grandegaj pozitivaj/negativaj tagoj pli grandaj ol `M²`; rezulto restas en [42,963].
6. Konservu ekzakte la tutan `previous` Stage23-rezulton kaj la tutan Stage22-nestitan rezulton.
7. Assert ĉiuj kvar publikaj kampoj de `GateGapOutput` kaj la inkluzivaj limoj ĉe ranga ekstremaĵo.
8. `gap_for_days` identa al `dispatch_discovery_20(new_context(...))`.
9. Malvalidaj bovloj 0, 7, -1; ĝuste heredita `InvalidBowlId`.
10. `retry_budget=-1` kun malvalida bovlo: `InvalidContext(InvalidRetryBudget)` prioritate.
11. `recovery_depth=-1` kun malvalida bovlo: `InvalidContext(InvalidRecoveryDepth)` prioritate.
12. Interplektitaj kuntekstoj, diversaj diagnozaj markiloj kaj ripetaj vokoj; neniu poluado, neniu ŝanĝo de enmetita sigelo.

Kontrolu la nombron per `pub fn ..._test()` en nova dosiero. Antaŭaj 250 testoj devas resti netuŝitaj. **262 estas prognozo**, ĝis Native-loko pruvas alie.

## Same-SHA pordegoj kaj ekskludoj

1. Ĉi tiu **kontrakta HEAD** devas ricevi aŭtomatajn `gleam format --check src test`, `gleam test` kun **250/250**, netuŝitan spuran fonton kaj Canonical Names Lock SUCCESS sur **unu identa SHA**, antaŭ ajna Stage24-produktkoda komito. `queued/in_progress` neniam estas PASS aŭ blokado.
2. Poste kreu la produktan modulon, precize 12 testfunkciojn, metadata ŝanĝon. Akceptu la kodan HEAD nur je Native **262/262 mezuritaj** kaj Names Lock SUCCESS sur sama SHA.
3. Poste faru apartan dokumentan HEAD kaj finan metadata HEAD, ĉiun kun propra Native kaj Names sama-SHA antaŭ `LAST_COMPLETED_STAGE=24` aŭ Stage25.
4. Ĉio ĉi estas nur **unu pordeg-interspaca specimeno por eksplicita bovlo**. Neniu vera pordegoserio, jara kalkulo, plena dato, `main`-merge aŭ publikigo.
