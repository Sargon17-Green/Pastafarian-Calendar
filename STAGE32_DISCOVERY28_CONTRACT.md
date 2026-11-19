# Stadio 32 — DISCOVERY 28: unia nombro de sinsekvaj fenestroj en pluraj fermitaj sumintervaloj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj. Stage31 estas plene akceptita; Stage32 komenciĝas nur per ĉi tiu kontrakto. Neniu Stage32-produktkodo aŭ nova Native-testo estas ankoraŭ efektivigita.

## Kontrolita antaŭkondiĉo

Stage31 fina metadata commit: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/16a8eb2141c7e1a1f2720467f968776d60263085.
- Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613044932, job 135874354777, completed/success ĉe la ĝusta SHA, **346/346**, neniuj malsukcesoj; Gleam 1.18.1 / OTP 28, formatter, HEAD-kontrolo kaj fontintegreco PASS. Artifact 14572882717, GitHub-upload SHA256 db6a8567243126998bce016a97f358bc1866c828307ca157a64adec027b81c52.
- Canonical Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613044907, job 135874354837, completed/success ĉe la sama SHA.
- Stage31 kodo: `src/pastafari/discovery_27_sum_bands.gleam`; ĝia akceptita API konservas petordon kaj redonas unu `SumBandCount` por ĉiu fermita intervalo. Neniu aŭtomata kalendara sinsekvo aŭ datkonverto estas jam akceptita.

## Preciza celo kaj matematika kontrakto

Donitaj eksplicite petitaj bovlo-identigiloj, Stage21-provitaj pozitivaj interspacoj g_0,...,g_(k-1) (ĉiu inter 42 kaj 963), kaj q fermitaj sumintervaloj [l_i,u_i], kalkulu unu `U`: la nombro de **malsamaj ne-malplenaj sinsekvaj fenestroj** [a,b), 0 <= a < b <= k, kies sumo apartenas al almenaŭ unu ne-inversa petita intervalo.

`U = |{(a,b) : 0 <= a < b <= k kaj ekzistas i kun l_i <= sum(g_a..g_(b-1)) <= u_i}|`.

La apartaj fenestroj, ne la nombron de kongruaj intervaloj, estas kalkulataj. Duplikataj, interkovrantaj kaj apudaj fermitaj entjeraj intervaloj ne duobligas fenestrojn. Intervaloj kun lower > upper estas malplenaj; ili tamen ne rajtas preterlasi la validigon de idoj aŭ kunteksto.

La kanona unio estu ascende ordigita listo de disaj, **ne-apudaj** fermitaj `SumBand`: forigu inversajn intervalojn, ordigu laŭ `lower` (kaj `upper` ĉe egaleco), kunfandu se `next.lower <= current.upper + 1`, kaj uzu la maksimuman `upper`. Sen validaj intervaloj, la listo estas []. La kanonigo ne ŝanĝu la entjeran union, inkluzive de grandegaj pozitivaj aŭ negativaj limoj. Ĉar Gleam BEAM `Int` havas arbitran precizecon, ne uzu maŝin-entjeran saturigon aŭ konvertadon.

Por kanonaj disaj intervaloj [L_j,H_j], `U = sum_j B(L_j,H_j)`, kie `B` estas la **jam akceptita Stage31**. Neniu duobla nombrado eblas ĉar la kanonaj intervaloj estas disaj. Ĉiam `0 <= U <= k*(k+1)/2`, kaj por `k=0` rezulto estas 0.

## Publika API kaj izoliteco

Nova produktmodulo: `src/pastafari/discovery_28_union_bands.gleam`.
Nova testmodulo: `test/discovery_28_test.gleam`.

```gleam
pub type UnionWindowCount {
  UnionWindowCount(
    canonical_bands: List(discovery_27_sum_bands.SumBand),
    qualifying_windows: Int,
  )
}
pub fn dispatch_discovery_28(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  bands: List(discovery_27_sum_bands.SumBand),
) -> Result(UnionWindowCount, discovery_19_interval_value.Discovery19Error)
```

La produkta funkcio:
1. Kanonigu nur la petitan liston de sumintervaloj sen tuŝi la originalan liston, identigilojn aŭ kuntekston.
2. Voku `discovery_27_sum_bands.dispatch_discovery_27(context, requested_bowl_ids, canonical_bands)` **precize unufoje en ĉiu publika voko**, ankaŭ kiam `bands=[]`, ĉiuj estas inversaj, aŭ `requested_bowl_ids=[]`. Neniam voku Stage21, Stage25, Stage26 aŭ Stage30 rekte en produktkodo, kaj neniam voku Stage31 aparte por ĉiu intervalo.
3. Propagu la ekzaktan `Error(error)` de Stage31 sen modifo. Tiel nevalida ne-malplena id-listo aŭ kunteksto restas eraro eĉ se la petita unio estas malplena. Malplena id-listo konservas la antaŭan Stage31-konduton kun neuzata nevalida kunteksto.
4. Ĉe `Ok(counts)`, kontrolu la unu-al-unu kanonan ordon kontraktitan de Stage31; sumu la `qualifying_windows` kaj redonu `Ok(UnionWindowCount(canonical_bands, total))`. Neniu fenestro estu kalkulita pli ol unufoje; neniu modulo de antaŭaj stadioj estu ŝanĝita.

Celaj limoj: kun q intervaloj kaj k eksplicitaj interspacoj, ordigo/fandado `O(q log q)` per determinisma finia ordigo, Stage31 `O(k*m+k)` por m <= q kunfanditaj intervaloj, memoro `O(q+k)`. Neniu ses-elementa artefarita limo, senlima serĉado, jarkalkulo, aŭtomata kalendara serio, plen-datkonverto, aŭ kodprunto el alia branĉo.

## Sendependa oracle

La testmodulo rekte akiru gapojn per `discovery_21_gate_batch.dispatch_discovery_21`; por ĉiu starta indekso kaj ĉiu ebla fino, akumulu sumon kaj kalkulu +1 **nur unufoje**, se almenaŭ unu ORIGINALA valida petita intervalo enhavas la sumon. Ne kanonigu la originalajn intervalojn por la oracle de la fina nombro; ne uzu Stage26, 27, 28, 29, 30 aŭ 31 por atendata valoro. Apartaj eksplicitaj fiksaĵoj kontrolu la kanonan ordigitan ne-apudan liston. Konfirmu ke ĉiuj gapoj restas en 42..963.

## Dek du planitaj publikaj gleeunit-testoj (ankoraŭ NE Native)

1. Malplenaj idoj, malplenaj intervaloj: kanona [], U=0.
2. Malplenaj idoj kaj neuzata nevalida kunteksto: Ok kun U=0 kaj laŭregula kanona listo.
3. Unu id, unu ĝusta ferma intervalo: U=1, kun eksteraj limoj U=0.
4. Du identaj intervaloj: rezulto identa al unu intervalo.
5. Parta interkovro kaj inkluzivaj limoj: neniu duobla kalkulado.
6. Apudaj entjeraj intervaloj: kanona kunfandiĝo ankaŭ kiam neniu fenestrosumo troviĝas ĉe la kuniga limo.
7. Neordigitaj kaj nestitaj intervaloj: ascenda kanona listo, ne duobligita U.
8. Inversaj/negativaj intervaloj, inkluzive de ĉiuj inversaj: U=0, kanona [].
9. Disaj intervaloj kun unu- kaj plur-gapaj internaj fenestroj: rekta oracle.
10. Duplikataj bovlo-identigiloj en pluraj pozicioj: ĉiu fenestro estas distingata per indeksoj.
11. Nevalida id-listo kaj nevalida ne-malplena kunteksto propagas Stage31-eraron eĉ por malplena unio.
12. Grandegaj +/- entjeraj limoj, granda pozitiva/negativa kunteksto, duplikatoj, mallarĝaj kaj larĝaj intervaloj: rekta oracle, kanona listo, limo 0..k(k+1)/2, monotoneco kiam aldoniĝas validaj intervaloj.

## Sendependa sinteza antaŭkontrolo — ne Gleam Native

364 listoj de longo 0..5 kun eroj el {42,43,963} × 14 determinismaj intervalaj familioj (malplena, inversa, duplikata, interkovranta, apuda, disigita, granda negativa/pozitiva limo kaj precizaj sumlimaj fiksaĵoj) = **5,096/5,096** JS-kazoj egalaj, **0 mismatches**, **0 limmalobservoj**. La referenco rekte enumeraciis ĉiujn ne-malplenajn fenestrojn kaj testis membrecon en la originalaj intervaloj; la dua kalkulo kanonigis intervalojn kaj uzis sendependan prefiks-suman binaran serĉon por `C(lower)-C(upper+1)`. Tio kontrolas nur la dezajnon en la preciza JS-numera kampo (limvaloroj <= 10^12); ĝi NE estas Gleam kompilo, Native, aŭ plena kontrolo de arbitraprecizaj entjeroj.

## Akceptopordegoj kaj sekva ago

A. Ĉi tiu **kontrakta** commit rajtas ŝanĝi nur `DEVELOPMENT_STAGE.md` kaj ĉi tiun novan kontrakton. La kontrakta SHA bezonas siajn proprajn completed/log Native **346/346**, read-only formatter + source-integrity PASS kaj Names Lock SUCCESS antaŭ produktkoda komito. PENDING ne estas PASS aŭ bloko.
B. Post A, efektivigu unu novan produktmodulon kaj **12 unikajn publikajn sendepend-orakolajn testojn**; antaŭkalkulita suma nombro **358** estas prognozo, ne mezurita Native. Kod-SHA bezonas Native **358/358** plus Names SUCCESS.
C. Post B, aparta dokumenta fermo kaj poste aparta fina metadata commit kun `LAST_COMPLETED_STAGE=32`; ĉiu ŝanĝita SHA bezonas siajn proprajn Native **358/358** kaj Names SUCCESS.
D. Ne faru manan duoblan CI-dispatch, merge al main, ŝanĝon de protektita branĉo aŭ eksteran publikigon.
