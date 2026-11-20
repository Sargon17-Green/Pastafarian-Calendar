# Stadio 33 — DISCOVERY 29: nombro de fenestroj EKSTER unio de fermitaj sumintervaloj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj. Unua Stage33-artefakto estas nur kontrakto kaj metadata; Stage33 produktkodo kaj ĝiaj novaj Gleam-testoj ankoraŭ NE ekzistas.

## Antaŭkondiĉo, realaj completed/log atestoj

Stage32 fina metadata HEAD: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/80d237f30642431297ab2d6c8a95947f59d69a7e
- Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44707057315, job 136189185924, completed/success sur precize 80d237f30642431297ab2d6c8a95947f59d69a7e; Gleam 1.18.1, OTP 28 / ERTS 16.4.0.7, read-only `gleam format --check src test`, 358 passed / 0 failures, post-test Git source-integrity check PASS. Artifact ID 14616796131, GitHub-upload digest f96be1d909dd8cbb903da026be02f9785cca7aa276352ddb11b66e8f25c67b84 (ĉi tio estas upload-digesto, ne loka recalculo).
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44707057136, job 136189185205, completed/success kaj Git HEAD sama SHA.
- Stage32 akceptita produkt-API: `discovery_28_union_bands.dispatch_discovery_28`. Ĝi kalkulas la nombron de malsamaj ne-malplenaj sinsekvaj fenestroj, kies sumoj apartenas al almenaŭ unu petita fermita intervalo, kaj liveras kanonan unuon sen duobla nombro.

## Celo kaj matematika difino

Por eksplicita listo de `k` bovlo-identigiloj, la sama `bootstrap.MonsterContext` kaj listo de `q` fermitaj entjeraj `SumBand(lower,upper)`, kalkulu la nombron de ne-malplenaj sinsekvaj fenestroj `[a,b)`, `0 <= a < b <= k`, kies pozitiva gapsumo NE estas en IU ajn originala ne-inversa intervalo.

`T = k*(k+1)/2`.
`I = |{(a,b): 0<=a<b<=k kaj ekzistas (L,H) kun L<=H kaj L<=sum(g[a:b])<=H}|`.
`O = T-I = |{(a,b): 0<=a<b<=k kaj por ĉiu petita (L,H), ne (L<=H kaj L<=sum(g[a:b])<=H)}|`.

La Stage32-kalkulo `I` jam estas akceptita. La produkto Stage33 rajtas kalkuli `T` el la longo de la ORIGINALA petita id-listo kaj subtrahi Stage32 `I`. Ĉar Stage21 donas precize unu gap por ĉiu sukcesa id-peto, tiu longo estas `k`, ankaŭ kun ripetitaj idoj. Ne uzu `k-1`, kaj ne deduplikigu identigilojn.

Post sukcesa Stage32-voko, validigu `0<=I<=T` antaŭ konstruo de rezulto; ekster tiu intervalo redonu la ekzistantan `Discovery19Error.InvalidStream`. Komunaj invariantoj: `0<=O<=T`, `I+O=T`. Por `k=0` ĉiam `I=O=T=0` post la antaŭa validiga semantiko.

Malplena intervalo-listo aŭ nur inversaj intervaloj: `I=0`, `O=T`. Intervalo enhavanta ĉiujn eblajn sumojn: `I=T`, `O=0`. Duplikataj, nestitaj, apudaj aŭ interkovrantaj intervaloj ne ŝanĝas la matematikan union. Negativaj limoj kaj arbitraprecize grandaj entjeroj ne estu satigitaj aŭ konvertitaj al maŝinaj entjeroj; BEAM `Int` subtenas arbitran precizecon.

## Unu publika produktmodulo, unu publikvoko

Nova dosiero: `src/pastafari/discovery_29_complement_bands.gleam`.
Nova testdosiero: `test/discovery_29_test.gleam`.

```gleam
pub type ComplementWindowCount {
  ComplementWindowCount(
    canonical_bands: List(discovery_27_sum_bands.SumBand),
    inside_windows: Int,
    outside_windows: Int,
    total_windows: Int,
  )
}
pub fn dispatch_discovery_29(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
) -> Result(ComplementWindowCount, discovery_19_interval_value.Discovery19Error)
```

1. Voku `discovery_28_union_bands.dispatch_discovery_28(context, requested_bowl_ids, bands)` PRECIZE UNUFOJE por ĉiu publika alvoko, inkluzive de `bands=[]` kaj `ids=[]`. Neniu rekta produktvoko al Stage21/26/27/31. Ne rekalkulu la kanonan union.
2. Propagu la originalan `Error(error)` sen ŝanĝo. Tio konservas validigon de ne-malplenaj malĝustaj idoj/kunteksto eĉ por malplena unio; malplena id-listo konservas antaŭan konduton kun neuzata nevalida kunteksto.
3. Nur ĉe `Ok(union)`, kalkulu `k=list.length(requested_bowl_ids)`, `T=k*(k+1)/2`, `I=union.qualifying_windows`. Se `I<0` aŭ `I>T`, redonu `Error(InvalidStream)`; alie redonu la SAME kanonan `union.canonical_bands` kaj `inside_windows=I, outside_windows=T-I, total_windows=T`.
4. Sen dato-jaro, kronologia serio, plena datkonverto, ŝanĝo de antaŭa modulo, aŭ prunto el aliaj branĉoj. Ĉi tiu API estas por eksplicitaj bovlo-ID-petoj sole.

La aldonita Stage33-produktlaboro estas `O(k)` por longo + `O(1)` aritmetiko, aldone al Stage32 `O(q log q + k*m + k)`, kie `m<=q` estas nombro de kanonaj intervaloj. Memoro de Stage33 estas `O(1)` super Stage32 (ekskluzive de kunhavata rezultlisto).

## Vere sendependa test-orakolo

En TESTOJ SOLAJ, voku `discovery_21_gate_batch.dispatch_discovery_21` rekte por realaj pozitivaj gapoj (42..963). Enumeraciu per du nestitaj listtrairoj ĉiujn `[a,b)` kun `a<b`; akumulu sumon; kalkulu `outside` se ne ekzistas IU ORIGINALA valida petita intervalo, kiu enhavas sumon. Kalkulu `inside` kiel la komplementan membrecan decidon dum la sama nombrado. Ne uzu Stage26..32, Stage32-union-sumon aŭ ĝian kanonigilon por la atendataj nombroj. Sendependaj fiksaĵoj kontrolu la kanonan liston; kontrolu `inside+outside=T`.

## 12 unikaj planitaj gleeunit-testoj (ne Native ĉe la kontrakta commit)

1. Malplenaj idoj + malplenaj intervaloj: ĉiuj tri nombroj nulo.
2. Malplenaj idoj + neuzata nevalida kunteksto: `Ok` kun nulaj nombroj, malgraŭ ne-malplena intervalo-listo.
3. Unu gap: preciza ferma intervalo `outside=0`; eksteraj intervaloj `outside=1`.
4. Du kaj kvar gapoj: direktaj sendepend-orakolaj nombroj kaj `k(k+1)/2`.
5. Sen intervaloj, `outside=T`, ankaŭ por pluraj idoj.
6. Nur inversaj intervaloj: `outside=T`; kanona [].
7. Duplikataj kaj nestitaj intervaloj ne ŝanĝas `outside`.
8. Interkovrantaj kaj apudaj entjeraj intervaloj konservas ĝustan kanonan union kaj komplementon.
9. Apartaj intervaloj tranĉantaj unu-gapajn kaj plur-gapajn sumojn: rekta oracle.
10. Ripetitaj idoj en malsamaj pozicioj konservas ĉiujn malsamajn fenestrojn.
11. Nevalida ID aŭ nevalida ne-malplena kunteksto propagas ekzaktan Stage32-eraron eĉ kun `bands=[]`.
12. Arbitraprecizaj pozitivaj/negativaj limoj, grandaj kuntekstaj tagoj kaj monotoneco: aldoni validan bandon ne pliigas `outside`.

## Antaŭkontrolo efektive farita — ne Gleam Native

Reproduktebla Python 3-programo uzas apartan rektan fenestro-enumeracian oracle kontraŭ prefikssumoj kaj binara serĉo en kanonigitaj intervaloj. Determinisma krado: 364 gaplistoj de longo 0..5 kun valoroj 42,43,963 × 14 intervalo-familioj = **5096/5096**. Pliaj 2000 determinitaj hazarde generitaj kazoj kun 0..8 gapoj, 0..10 intervaloj, kaj entjeraj limoj ĝis 10^70: **2000/2000**. Sume **7096/7096**, neniuj malsamaj respondoj. Ĉi tio estas nur kalkula antaŭkontrolo, ne kompilita Gleam-ekzekuto, ne CI-gate, kaj ne garantio pri la estonta kod-efektivigo.

## Devigaj akcepto-pordegoj

A. Kontrakta commit ŝanĝas `DEVELOPMENT_STAGE.md` kaj ĉi tiun novan kontrakton, ne `src/` aŭ `test/`. Post ĝia preciza SHA: `completed/success` Native kun **358/358**, read-only formatter + checkout/source-integrity PASS, kaj Canonical Names Lock `completed/success` ĉe sama SHA. Aŭtomate en-vicigita CI NE estas PASS.
B. Nur post A, efektivigu produktmodulon kaj 12 unikajn publikajn sendepend-orakolajn testojn: **370** estas nur antaŭvidita testnombro. Nova kod-SHA bezonas `370/370` Native + Names success.
C. Post B, aparta dokumenta fermo kaj aparta fina metadata commit markante `LAST_COMPLETED_STAGE=33`. Ĉiu nova SHA bezonas kompletigitajn sam-SHA Native 370/370 kaj Names logs. Ne antaŭtempe nomu Stage33 ACCEPTED.
D. Neniu mana duobla CI-dispatch, neniu merge/main, neniu eksterna publikigo.
