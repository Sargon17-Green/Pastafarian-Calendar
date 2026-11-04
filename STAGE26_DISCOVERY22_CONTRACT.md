# Stadio 26 — DISCOVERY 22: prefiksaj sumoj de eksplicite petitaj pordeg-interspacoj

**Kontrakta malfermo: 2026-11-04.** Stage25 estis akceptita ĉe la fina metadata HEAD `428a62a10265a26c1ae674406b9f663a4eb52782`: [Native 41873127564](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41873127564), job `126725345082`, `completed/success`, **274/274, neniu malsukceso**, Gleam 1.18.1 / Erlang/OTP28, formato kaj fontintegreco PASS, artefakto 13346455146; [Canonical Names Lock 41873127698](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41873127698), job `126725345346`, `completed/success` ĉe la **sama SHA**. Ĉi tiu nova kontrakta HEAD ne ankoraŭ havas propran Native/Names-akcepton.

## Preciza limigo de la sekva komponanto

Stage25 konservas la ordon de eksplicita finia listo de petoj por bovloj 1..6. La sekva **pure aritmetika** etapo liveru prefiksajn sumojn de la jam elektitaj interspacaj specimenoj. Ĉi tio **ne** estas kalendara jarlongo, pordega kronologio, aŭtomate elektita bovlo, vera jara pordegoserio aŭ plena dato. Neniu norma nombro aŭ reala ordo de pordegoj estas ĉi tie konata; la petanto mem donas la liston. Por ajna listo kun ripetoj, ĉiu ripeto estas aparta peto kaj kontribuas aparte al la suma aritmetiko.

## Publika API kun antaŭekzistanta erarordo

Kreu nur `src/pastafari/discovery_22_gap_prefixes.gleam`, `test/discovery_22_test.gleam`, kaj la ordinaran stage-metadata ŝanĝon, **nur post sukcesa CI de ĉi tiu kontrakta HEAD**. Ne modifu Stage01–25, la kanonan referencon, `main`, workflows aŭ frostigitajn nomojn.

- `pub type GapPrefix { GapPrefix(sample: discovery_20_gate_gap.GateGapOutput, prefix_total: Int) }`.
- `pub type GapPrefixBatch { GapPrefixBatch(entries: List(GapPrefix), total: Int) }`.
- `pub fn dispatch_discovery_22(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int)) -> Result(GapPrefixBatch, discovery_19_interval_value.Discovery19Error)`.
- Alvoku `discovery_21_gate_batch.dispatch_discovery_21(context, requested_bowl_ids)` **ĝuste unufoje**. Je `Error(e)` redonu `Error(e)` sen transformo. Je `Ok(samples)`, trairu la specimenojn en ilia jam akceptita ordo. Produktu `entries` kun `sample` **identa al la originala tipita Stage24-rezulto**, sen rekalkulado aŭ kunfandado.
- Por `k` specimenoj kun `g_i=sample_i.gap`, difinu `s_0=0`, `s_i=s_(i-1)+g_i` por `1<=i<=k`. La kampo `prefix_total` por i estu `s_i`; `total=s_k`; `entries` enhavu precize k elementojn. `total` estas **nur suma valoro de la eksplicitaj petoj**, ne jaro.
- Malplena listo devas redoni `Ok(GapPrefixBatch(entries: [], total: 0))`, eĉ se la neuzata kunteksto estas malvalida, ĉar Stage25 ne validigas kuntekston kiam neniu peto ekzistas.
- `pub fn prefix_total_for_days(calculation_day: Int, target_day: Int, requested_bowl_ids: List(Int)) -> Result(Int, discovery_19_interval_value.Discovery19Error)` konstruu unu `bootstrap.new_context`, delegu al `dispatch_discovery_22` nur unufoje kaj redonu `total`.
- Neniu kaŝita stato, IO, algoritmo por aŭtomata sekvigo, limigo al 6 petoj aŭ supozo pri 64-bita entjero. Aritmetika parto `O(k)` tempo kaj `O(k)` memoro (aldone al Stage25-delegado), sen ripetaj plenskanadoj de akumulitaj prefiksoj.

## Sendependa kontrolorakolo kaj randoj

Por ĉiu valida `requested_bowl_ids`, akiru **sendepende** unu rektan Stage25-vokon nur en la testoj (ne importu novan Stage26-produkton en la orakolan kalkulon). Konstruu atendantajn prefiksojn per alternativa `gleam/list.fold` aŭ rekta aritmetika referenca procedo, ne kopiu la produktan prefiksan traverson. Kontrolu la metamorfajn invariantajn diferencojn `s_i-s_(i-1)=g_i`, la identan individuan `GateGapOutput`, totalon `sum(g_i)`, kaj por `k>0`, `42*k<=total<=963*k`; k=0 havas totalon 0. Uzu `test/reference/sauce.gleam` kiel sendependan saŭcan orakolon **nur por individuaj bovloj kun maksimume 8 antaŭkalkulitaj rifuzoj**; alie kontrolu nur akceptitan Stage25-komponan ekvivalentecon kaj nomu tiujn kazojn nekompareblaj al la saŭca orakolo. Ne kopiu kodon aŭ fixture de alia branĉo. Neniu falsita expected-red aŭ antaŭe ne observita bug.

## Dek du novaj publike nomitaj testfunkcioj

1. Malplena listo + valida kunteksto: `entries=[]`, `total=0`.
2. Malplena listo + `retry_budget=-1`: sama `Ok`, neniu kaŝa validigo.
3. Ĉiu individua ID 1..6: unu prefikso identa al sia `sample.gap` kaj Stage25/Stage24-orakolo.
4. Listo `[1,2,3,4,5,6]`: ses ordigitaj elementoj, preciza prefiksa aritmetiko kontraŭ sendependa `fold`.
5. Listo `[6,5,4,3,2,1]`: ordo restas malsama, suma valoro egala al antaŭa laŭ komuteco; ne asertu malsamajn valorojn se ili hazarde egalas.
6. Ripetoj `[3,3,3,1,3]`: ne sen-duobligu, kreskigu sumon por ĉiu kopio.
7. Samtagaj, inversaj kaj negativaj tagoj: neniu malsama Stage25-semantiko.
8. `F-1,F,F+1` por ambaŭ argumentoj: inkludeco ne modifiĝu.
9. Pozitivaj kaj negativaj grandegaj tagoj pli ol `M²`: neniu 64-bita troflua supozo.
10. Malvalidaj bovlaj ID-oj ĉe komenco, mezo kaj fino; sama unua Stage25-eraro.
11. `retry_budget=-1`, `recovery_depth=-1`, malvalidaj bovloj: ekzakte heredita erarprioritato; kuntekstaj diagnozoj ne poluiĝu.
12. Komforta API kontraŭ plena `dispatch_discovery_22`; kontrolu almenaŭ unu sendependan `reference/sauce` rangon kiam la <=8-rifuza antaŭkondiĉo vere validas.

La antaŭaj **274** Native-testoj devas resti senŝanĝaj; la nova nombro **286 estas nur prognozo** ĝis Native-loko ĝin mezuras. Ĉiu nova kazo havu apartan `pub fn ..._test()`. Ne ekzekutu senlimajn aŭ pezajn orakol-serĉojn.

## Same-SHA akceptopordegoj

1. Kontrakta HEAD: `gleam format --check src test`, `gleam test` **274/274**, fontintegreco, Names Lock completed/success sur la **sama** SHA antaŭ koda commit.
2. Koda HEAD: unu nova produkta modulo, precize dek du novaj testoj kaj metadata. Postulu **286/286 mezuritan** Native, formaton, netuŝitan fonton kaj Names SUCCESS sur sama SHA; `queued/in_progress` estas nek PASS nek blokado. Nur pruvitaj eraroj rajtigas flikon.
3. Dokumenta fermo kaj fina metadata estu **apartaj commit-oj** kun propraj same-SHA Native/Names sukcesoj antaŭ fina Stage26-akcepto aŭ Stage27.
4. Ne faru `main`-merge, publikigon, supozon pri vera pordegoserio, jarlongo aŭ datkalkulo.
