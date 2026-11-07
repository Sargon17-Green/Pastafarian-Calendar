# Stadio 29 — DISCOVERY 25: plej mallonga sinsekva fenestro atinganta sojlon

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj. LAST_COMPLETED_STAGE=28. **Nur mezurebla kontrakto; neniu Stage29 produktkodo aŭ Stage29 Native PASS ankoraŭ.**
Antaŭa akceptita HEAD: `b55f642d213c7ef564794004f7ea75880f3cdb55`; [Native 42176602212](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176602212), job 127756388886, **310/310**, Gleam 1.18.1 / OTP28, formato kaj fontintegreco PASS; [Names Lock 42176602195](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176602195), job 127756388957, SUCCESS sur la **sama SHA**. Native artefakto 13483343800 SHA256 1cf8a6207d8a08dfb28ffcab9d2e486b4f37c286e878efc39dcd378687f44121.

## Elekto kaj celo

Stage25 produktas ordigitan laŭ la petoj (ne laŭ kalendaro) liston de strikt-pozitivaj interspacoj en 42..963; Stage26 produktas ĝiajn prefiksajn sumojn; Stage27 demandas pri jam specifitaj duonmalfermitaj fenestroj; Stage28 serĉas nur la unuan atingantan **prefikson**. Stage29 serĉu anstataŭe la **plej mallongan kontiguan fenestron ie ajn** en la eksplicita petolisto kies suma interspaco atingas sojlon. Tiu problemo ne reduktiĝas al Stage28-prefiksa serĉo. Ne konstruu aŭ supozu kanonan sinsekvon de pordegoj, jarojn aŭ datkonverton.

## Preciza publika API kaj rezultoj

- Nova produktmodulo: `src/pastafari/discovery_25_shortest_window.gleam`. Nova testmodulo: `test/discovery_25_test.gleam`. Ne redaktu la antaŭajn produktmodulojn, referencajn orakolojn, nomlistojn aŭ 310 ekzistantajn testojn.
- Publikaj tipoj: `WindowReach = WindowFound(start: Int, end: Int, total: Int) | NoWindow`; `ThresholdWindow(threshold: Int, reach: WindowReach)`.
- `dispatch_discovery_25(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), thresholds: List(Int)) -> Result(List(ThresholdWindow), discovery_19_interval_value.Discovery19Error)`.
- Unu sola alvoko al `discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)` **antaŭ** ajna kalkulo por la sojloj, eĉ kiam `thresholds=[]`. Eraro de Stage26 devas transiri sen ŝanĝo; validigo de petoj/kunteksto havas prioritaton super malplenaj aŭ nepozitivaj sojloj.
- Por `k` specimenoj `g_0,...,g_(k-1)`, ĉiuj `42 <= g_i <= 963`, fenestro `[a,b)` signifas `0 <= a <= b <= k`, kun `S(a,b)=sum(g_i por a<=i<b)`. Por `t>0`, elektu inter ĉiuj fenestroj kun `S(a,b)>=t` la minimuman longecon `b-a`; inter egal-longaj elektu la minimuman `a`. Redonu `WindowFound(start:a,end:b,total:S(a,b))`; se ne ekzistas, `NoWindow`.
- Por `t<=0`, la kanona respondo estas la malplena fenestro `WindowFound(start:0,end:0,total:0)`, ankaŭ se `k=0`. Por `k=0,t>0` redonu `NoWindow`. Por `t>sum(g_i)` redonu `NoWindow`.
- Konservu precize la nombron, ordon kaj multoblon de `thresholds`. La sama bovlo povas aperi plurfoje: pozicioj estas apartaj petoj; ne dedupliku nek ordigu ilin. Ne ŝanĝu la donitan kuntekston.
- Produkta algoritmo: unu Stage26-prefiksvoko, poste po pozitiva sojlo monotona du-montrila / glita-fenestra serĉo. Pro strikt-pozitivaj interspacoj, ĉiu montrilo moviĝas nur antaŭen; `O(k + k*q)` tempo kaj `O(k+q)` memoro por `q` sojloj. Ne uzu pro ĉiuj fenestroj `O(k²*q)` en produkta vojo; ne uzu i64-konverton, ses-bovlan limon, nedeterminisman generadon aŭ senlimajn serĉojn.

## Sendependa orakolo

Testa orakolo **rekte** voku `discovery_21_gate_batch.dispatch_discovery_21` kaj legu `sample.gap`; ĝi neniam voku Stage26, 27, 28 aŭ produktan Stage29 por atendoj. Por ĉiu pozitiva sojlo, per du nestitaj, limigitaj bukloj enumeraciu ĉiujn kontiguajn nenul-longajn fenestrojn; komparu laŭ triopo `(longeco, starto, sumo)` kun longeco/starto kiel prioritataj ŝlosiloj. Por `t<=0`, atendu `[0,0)`. Kontrolu `42..963` por ĉiu `sample.gap`. Komparu **plenajn** rezultajn strukturojn kun la produkta respondo. Uzu malgrandajn determinismajn petarojn por `O(k²)`-orakolo, sen kopii solvon el alia lingvo/branĉo.

## Precize 12 publikaj gleeunit-testoj

1. `([],[])` kaj nula produktrespondo.
2. Malplena bovlolisto kun `[-1,0,1]`, inkluzive de neuzata malvalida kunteksto.
3. Ununura bovlo ĉe `1`, `gap`, `gap+1`.
4. Plurbovla listo kun `total`, `total+1` kaj `1`; plej mallonga fenestro, ne simple prefikso.
5. Interna optimuma fenestro kun dinamike derivita sojlo el Stage25-sample.
6. Ekvalongaj optimumoj ĉe ripetitaj identaj bovloj: plej frua `start` venku.
7. Neordigitaj kaj duplikataj sojloj, revena ordo kaj multoblo.
8. Negativaj kaj nula sojloj: ĝuste `[0,0)`, sumo 0.
9. Preciza suma limo de fenestro kaj plus-unu limo, kun plenaj `total`-valoroj.
10. Nevalida bovlo propagas originan eraron ankaŭ kun malplenaj sojloj.
11. Malvalida ne-malplena kunteksto propagas eraron antaŭ nepozitiva sojlo.
12. Grandaj pozitivaj/negativaj tagoj, ripetitaj petoj, grandegaj Gleam `Int`-sojloj; limigita sendependa elĉerpa orakolo.

Preflight-kontrolo por la proponita matematika algoritmo: **4,004 determinismaj sintezaj kazoj**, longo 0..5, valoroj el `{42,43,963}`, 11 sojloj, du montriloj kontraŭ sendependa plena enumeracio, **0 malkongruoj**. Tio ne estas Gleam Native/CI kaj ne estas testrezulto pri realaj Stage25-valoroj.

## Akceptaj pordegoj — ĉiu en aparta HEAD

1. **Kontrakto**: atomika commit de `STAGE29_DISCOVERY25_CONTRACT.md` kaj `DEVELOPMENT_STAGE.md`; same-SHA Native **310/310**, `gleam format --check`, fontintegreco kaj Canonical Names Lock SUCCESS. Antaŭ tiuj rezultoj ne atribuu akcepton al kontrakto.
2. **Produktkodo**: nur post kontraktaj pordegoj, nova produktmodulo + precize 12 novaj publike nomitaj testoj + metadata, atomike. La celo **322** testoj estas prognozo ĝis efektiva same-SHA Native **322/322** kaj Names SUCCESS.
3. **Dokumenta fermo**: post akcepto de kodo, aparta dokumenta commit kun pruvitaj 322/322 + Names sur sia SHA.
4. **Fina metadata**: aparta commit post dokumenta akcepto kaj poste same-SHA 322/322 + Names antaŭ LAST_COMPLETED_STAGE=29 definitiva akcepto.
5. `queued/in_progress` estas nek PASS nek blokado. Neniu `main`/merge/eldono. Neniu fremda solvo aŭ fiksaj datumoj el alia branĉo.

## Stage29 koda pordego kaj aparta dokumenta fermo (2026-11-07)

La Stage29-kontrakto ĉe `1e0b8852d6835cd458b29406a73eec0a5bda30d4` jam ricevis apartajn sam-SHA Native **310/310** kaj Canonical Names Lock SUCCESS (vidu la kontraktajn atestojn en `DEVELOPMENT_STAGE.md`). La origina koda commit `c26d47aa9a4451219880bfbf7ddecd6476c3a1f7` malsukcesis ĉe la Gleam-formata kontrolo antaŭ ol ekzekuti unitajn testojn ([Native 42188902020](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42188902020)); [Names 42188901811](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42188901811) sukcesis. La aparta formato-PATCH01 `b75df0579b244e9c2f29a85b55dd02f39e6e5842` modifis nur `src/pastafari/discovery_25_shortest_window.gleam` kaj `test/discovery_25_test.gleam`, konservante precize 12 novajn publikajn testfunkciojn kaj la sendependan Stage25-bazitan test-orakolon.

Por PATCH01 ĉe la **sama koda SHA**:
- [Native 42250446626](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250446626), job `128003809058`: **completed/success**, preciza checkout `b75df0579b244e9c2f29a85b55dd02f39e6e5842`, Gleam 1.18.1 / Erlang OTP 28, `gleam format --check` PASS, **322 passed, no failures**, read-only fontintegreca kontrolo PASS. Native-artefakto [13519534516](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250446626/artifacts/13519534516), registrita SHA256 `2c0bc3fcb7b606d1a84801ff8bee83df09243eb336767107a7eadcac904f2fd8` (valoro el antaŭa atestregistro; ne rekalkulita ĉi tie).
- [Canonical Names Lock 42250446657](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250446657), job `128003809693`: **completed/success** ĉe tiu sama SHA; la job-log konfirmas ke la kanonaj `CANONICAL_NAMES_LOCK.sha256` eroj estis kontrolitaj sen mismatch.

**La koda pordego estas akceptita.** Ĉi tiu aparta dokumenta commit ne estas sam-SHA kun la supraj kodaj CI-ruloj. Ĝi bezonas siajn proprajn **Native 322/322 + formato/fontintegreco + Names SUCCESS**, kontrolitajn el completed/job-log antaŭ dokumenta akcepto. Nur poste faru apartan finan metadata-commit kun `LAST_COMPLETED_STAGE=29`, kaj ankaŭ tiu fina SHA bezonas novajn sam-SHA Native 322/322 kaj Names SUCCESS por definitiva akcepto. Ĝis tiam `LAST_COMPLETED_STAGE=28`; `queued`/`in_progress` ne estas PASS aŭ blokado. Neniu `main`/merge/eldono.
