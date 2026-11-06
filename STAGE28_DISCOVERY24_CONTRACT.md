# Stadio 28 — DISCOVERY 24: la unua prefikso atinganta sojlon

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj. LAST_COMPLETED_STAGE=27. Ĉi tiu dosiero estas **kontrakto**, ne malkonfirmita produktkodo aŭ Native PASS.
Antaŭa akceptita HEAD: `ae55c7887a7c730d5d49d0f33b46d5f7fbba70cb`; [Native 42173354424](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173354424), job 127746065584, **298/298**, Gleam 1.18.1 / OTP 28, formatter kaj fontintegreco PASS; [Names Lock 42173354376](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173354376), job 127746065106, SUCCESS sur sama SHA. Artefakto 13481978641 SHA256 9383fa07794ae61ee075a7895e869f78434127e14d7e51901ae8671375b77dbe.

## Elektita mezurebla operacio

Stage24 donas strikt-pozitivajn eksplicitajn `gap`-valorojn 42..963; Stage25 liveras ordkonservan petoliston; Stage26 kalkulas prefiksajn sumojn. Stage28 determinu por ĉiu petita entjera sojlo la **plej fruan** prefikson kies sumo atingas la sojlon. Tio ne estas kanona pordegoserio, jarlongo aŭ datkonverto. Ne uzu aliajn lingvo-branĉojn aŭ iliajn fiksaĵojn, kodon aŭ orakolojn.

### API, signifo kaj limoj

- Nova produktmodulo `src/pastafari/discovery_24_threshold_reach.gleam`; nova testmodulo `test/discovery_24_test.gleam`. Akceptitaj produktmoduloj kaj referencorakoloj restu netuŝitaj.
- Publikaj tipoj: `Reach = ReachedAt(prefix_size: Int) | NotReached` kaj `ThresholdFinding(threshold: Int, reach: Reach)`.
- `dispatch_discovery_24(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), thresholds: List(Int)) -> Result(List(ThresholdFinding), discovery_19_interval_value.Discovery19Error)`.
- Voku `discovery_22_gap_prefixes.dispatch_discovery_22(context, requested_bowl_ids)` **unufoje** antaŭ ajna sojla serĉo. Propagu `Error(e)` netuŝita, ankaŭ ĉe `thresholds=[]`. Ne rekalkulu Stage25/26 po sojlo.
- Por `k` specimenoj, `s_0=0`, `s_i=g_1+...+g_i`. Por sojlo `t` redonu `ReachedAt(min {i en 0..k : s_i >= t})`, se tia indekso ekzistas; alie `NotReached`. Do `t<=0` trafas `0`, `t=s_i>0` trafas la plej fruan egalecon, kaj `t>s_k` ne trafas. Konservu la ordon, nombron kaj duplikatojn de `thresholds`.
- Kun malplena bovlolisto, Stage26 sukcesas eĉ ĉe neuzata nevalida kunteksto; sojlo `<=0` trafas nulon, pozitiva ne trafas. Kun malvalida ne-malplena bovlolisto, Stage26-eraro prioritas eĉ ĉe malplenaj sojloj.
- Uzu Gleam `Int` sen 64-bita konvertiĝo; sen artefarita ses-bovla limo. Unu Stage26-voko plus serĉo tra jam kalkulitaj prefiksoj: plej malbona tempo `O(k + k*q)` por `q` sojloj. Neniu senlima orakolserĉo.

### Sendependa orakolo kaj precize 12 apartaj testoj

La test-orakolo voku rekte `discovery_21_gate_batch.dispatch_discovery_21`, ne Stage26/27/28. Sekvence sumi `sample.gap` kaj trovi la unuan atingitan sumon. Por pozitiva `t`, kontrolu minimumecan invarianton: ĉiuj pli fruaj sumoj estas `<t`, kaj la trovita estas `>=t`. Verifi ankaŭ striktan 42..963-limon de ĉiu specimeno.

Testaj klasoj, ĉiu aparta `pub fn ..._test()`:
1. Malplenaj bovloj kaj sojloj.
2. Malplena petolisto, negativaj/nulaj/pozitivaj sojloj kaj neuzata nevalida kunteksto.
3. Unu bovlo: `1`, `gap`, `gap+1`.
4. Pluraj bovloj: `0`, `1`, `total`, `total+1`.
5. Neordigitaj sojloj konservas ordon.
6. Duplikataj sojloj konservas multoblon.
7. Nulo kaj pluraj negativaj sojloj trafas indekson 0.
8. Egala al pozitiva prefikso trafas precizan plej fruan indekson.
9. Unu pli ol interna prefikso trafas poste aŭ ne trafas.
10. Malvalida bovla ID prioritas super malplenaj sojloj.
11. Nevalida ne-malplena kunteksto prioritas super nepozitiva sojlo.
12. Grandaj pozitivaj/negativaj tagoj, ripetaj eksplicitaj bovloj kaj grandaj Int-sojloj kun limigita sendependa orakolo kaj minimumeco.

Ne tuŝu antaŭajn 298 testojn. Ne inventu expected-red aŭ kalkulon de tuta kalendaro.

### Apartaj CI-pordegoj

1. **Kontrakto**: atomika du-dosiera commit (`DEVELOPMENT_STAGE.md` kaj ĉi tiu dokumento); same-SHA Native **298/298**, formatado, fontintegreco kaj Names Lock SUCCESS.
2. **Kodo**: unu nova produktmodulo, 12 testoj, metadata, en aparta commit; **310** estas nur prognozo ĝis reala same-SHA Native 310/310 kaj Names SUCCESS.
3. **Dokumenta fermo** kaj **fina metadata** estu apartaj commit-oj, ĉiu kun novaj sam-SHA 310/310 Native kaj Names SUCCESS antaŭ Stage28-akcepto.
4. `queued/in_progress` estas nek PASS nek blokado. Neniu main/merge/eldono aŭ nova jarlonga regulo.

## Koda HEAD akceptita; aparta dokumenta fermo (2026-11-06)

La Stage28-kontrakto ĉe `5b7ffa17647cf7917c408c8c229f18c51ebcfda6` pasis [Native 42174237129](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42174237129), **298/298**, kaj same-SHA [Names Lock 42174237160](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42174237160) SUCCESS. La unua Stage28-kodo `57a656c9c48426fb0c8fbe9e8d8eaf2e31061693` kreis unu produktmodulon, precize 12 sendependajn Stage25-bazitajn testojn kaj metadata. [Native 42174665058](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42174665058) malsukcesis ĉe formatter-kontrolo de la du novaj Gleam-dosieroj **antaŭ testado**; [Names 42174665095](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42174665095) sukcesis. PATCH01 `b836bce8a29bba86350d1f741f015d2204dfe5e4` faris nur la loge postulitajn kanonajn formatkorektojn sen ŝanĝi logikon aŭ nombron de testoj.

[Native 42174994694](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42174994694), job `127751296990`, estas completed/success por tiu sama PATCH01 SHA: Gleam 1.18.1, OTP 28, formato kaj fontintegreco PASS, **310/310 testoj, neniu malsukceso**. Artefakto `13482637777`, SHA256 `22b7168ddb2b1922607d58a3787484be6ef82e7f688951a69c14144b3a236371`. [Names Lock 42174994711](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42174994711), job `127751296923`, estas completed/success ĉe la sama SHA. Neniu kanona kalendara pordegoserio, jarlongo aŭ plena datkalkulo estis enkondukita.

**Ĉi tiu dokumenta HEAD ankoraŭ bezonas siajn proprajn same-SHA Native 310/310 kaj Names Lock sukcesojn.** Poste aparta fina metadata HEAD bezonos ambaŭ pordegojn antaŭ fina Stage28-akcepto. LAST_COMPLETED_STAGE=27 ĝis tiuj sukcesoj; neniu main/merge/eldono.
