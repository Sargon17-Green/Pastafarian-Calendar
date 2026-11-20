# Stadio 34 — DISCOVERY 30: fenestroj en A sed ne en B (diferenco de sumintervalaj unioj)

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Programo: 55 stadioj. Ĉi tiu unua Stage34-komito estas **nur kontrakto kaj stadiometadatenoj**; Stage34-produktkodo kaj la 12 novaj Gleam-testoj ankoraŭ NE ekzistas.

## Kontrolita antaŭkondiĉo

La akceptita Stage33 fina metadata-HEAD estas [f6ddd69a9d4bf59db6cb9ac9a0d7fc5f76c1bd81](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/f6ddd69a9d4bf59db6cb9ac9a0d7fc5f76c1bd81).
- Native [44734275167](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734275167), job 136281593192: `completed/success` ĉe precize la sama HEAD; Gleam 1.18.1, OTP 28, read-only `gleam format --check src test`, **370 passed, no failures**, kaj posttesta kontrolado de Git-fontintegreco sukcesis.
- Canonical Names Lock [44734275186](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44734275186), job 136281593052: `completed/success` ĉe la sama HEAD.
- La Stage32-produktfunkcio `discovery_28_union_bands.dispatch_discovery_28` jam kalkulas unian nombron sen duobligi fenestrojn; Stage33 kalkulas ĝian komplementon. La nuna stadio aldonas **du-argumentan diferencon de unioj** sen plena datkonverto.

## Matematika kontrakto

Enigaĵoj: `bootstrap.MonsterContext`, eksplicita ordigita `List(Int)` de k bovlo-identigiloj (inkluzive ripetojn), kaj **du apartaj** listoj A, B de fermitaj entjeraj `SumBand(lower,upper)`. La akceptita Stage21 produktas precize k pozitivajn interspacojn g[0..k-1] (42..963) aŭ eraron. Ĉiu ne-malplena sinsekva fenestro estas indeksa paro `(a,b)`, `0 <= a < b <= k`, kun sumo `s(a,b)=sum(g[a:b])`.

`UA = { (a,b) : s(a,b) apartenas al almenaŭ unu valida intervalo de A }`.
`UB = { (a,b) : s(a,b) apartenas al almenaŭ unu valida intervalo de B }`.
`UAB = UA ∪ UB`.
**`D = |UA \\ UB| = |UAB| - |UB|`.** `T=k*(k+1)/2`.
Invariantoj: `0 <= |UB| <= |UAB| <= T`, `0 <= D <= T` kaj `D+|UB|=|UAB|`.

`lower > upper` signifas malplenan intervalon (ne eraron). Malplena A donas D=0; malplena B donas D=|UA|; ambaŭ malplenaj donas D=0. Intervaloj kun negativo, arbitr-granda BEAM `Int`, duplikatoj, nestoj, apudeco kaj interkovroj uzas ekzakte fermitajn inkluzivajn limojn. Neniam deduplikigu petitan id-liston. Ripetitaj identigiloj kreas malsamajn **indeksajn** fenestrojn.

## Preciza produkt-API kaj voka disciplino

Nova dosiero: `src/pastafari/discovery_30_difference_bands.gleam`.
Nova testdosiero: `test/discovery_30_test.gleam`.

```gleam
pub type DifferenceWindowCount {
  DifferenceWindowCount(
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_excluded_bands: List(discovery_27_sum_bands.SumBand),
    combined_windows: Int,
    excluded_windows: Int,
    difference_windows: Int,
    total_windows: Int,
  )
}
pub fn dispatch_discovery_30(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  included_bands: List(discovery_27_sum_bands.SumBand),
  excluded_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(DifferenceWindowCount, discovery_19_interval_value.Discovery19Error)
```

1. Unue voku Stage32 `dispatch_discovery_28(context, ids, list.append(included_bands, excluded_bands))` **precize unufoje**, poste ĉe `Ok` voku `dispatch_discovery_28(context, ids, excluded_bands)` **precize unufoje**; neniam reuzu Stage33-komplementon por la ĉefa kalkulo. Eĉ por malplenaj listoj, ne saltu la suban validigvojon.
2. Propagu la unuan `Error(error)` sen ŝanĝo; nur ĉe unua sukceso rajtas veni la dua voko. Propagu ankaŭ ĝian originalan eraron sen ŝanĝo. Ĉi tiu ordo konservas erarprioritaton por nevalidaj ne-malplenaj idoj/kunteksto. Se `ids=[]`, malvalida sed neuzata kunteksto konservas antaŭan Stage32-semantikon.
3. Post ambaŭ sukcesoj, kalkulu `T` de la originala `list.length(ids)`, `combined=first.qualifying_windows`, `excluded=second.qualifying_windows`. Se `excluded<0`, `combined<excluded` aŭ `combined>T`, redonu `Error(discovery_19_interval_value.InvalidStream)`; alie redonu `D=combined-excluded` kaj **precize** la du kanonajn listojn de respektivaj Stage32-rezultoj.
4. Neniu rekta produktvoko al Stage21/26/27 aŭ al test/reference; ne reimplementu la Stage32-kanonigilon, ne tuŝu antaŭajn produktmodulojn kaj ne legu alian lingvan branĉon.
5. Komplekseco: du Stage32-vokoj, proksimume `O((p+q) log(p+q) + k*(p+q) + q log q + k*q)` kun p=|A|, q=|B|; plia Stage34-memoro `O(p+q)` por kombini la petlistojn kaj `O(1)` por nombrila rezulto. La kompleta kosto inkluzivas la Stage32-memoron. Neniu fiksita ses-bovla limo, jara serio aŭ kronologia konverto.

## Vera sendependa test-orakolo

**Nur en testoj** akiru pozitivajn interspacojn rekte per `discovery_21_gate_batch.dispatch_discovery_21`; listigu ĉiujn `(a,b)` per du nestitaj traversoj. Por ĉiu fenestrosumo, testu membrecon rekte en la **originalaj, nekanonigitaj** A kaj B. Kalkulu D nur se iu valida A-intervalo enhavas la sumon **kaj** neniu valida B-intervalo ĝin enhavas. Sendepende kalkulu `combined`, `excluded` kaj `T`. La atendoj NE uzu Stage26..33, nek iliajn kanonajn listojn, nek la produkta identeco `U(A∪B)-U(B)`; por kanonaj listoj uzu eksplicitajn fiksaĵojn. La test-orakolo kontrolu la gap-limojn 42..963.

## 12 unikaj planitaj gleeunit-testoj (ankoraŭ ne Native)

1. Malplenaj idoj kaj malplenaj A/B: ambaŭ kanonaj listoj [], ĉiuj nombroj 0.
2. Malplenaj idoj kun neuzata malvalida kunteksto kaj netrivialaj A/B: `Ok`, nulaj fenestronombroj, kanonaj listoj laŭ fiksaĵoj.
3. Unu gap ĝuste ĉe A-limo, B malplena: D=1; tuj ekster A: D=0.
4. Unu gap en ambaŭ A kaj B: D=0; ĉe inkluzivaj malsupraj/supraj limoj.
5. Pluraj gapoj (2 kaj 4), apartaj originalaj A/B, du-nesta rekta orakolo.
6. Malplena A, B ne-malplena: D=0, `combined=excluded`.
7. Malplena B, A ne-malplena: D=unuopa unio; malplenaj ambaŭ listoj sed ne-malplenaj idoj: D=0.
8. Nur inversaj/negativaj intervaloj ambaŭflanke: ĝustaj malplenaj kanonoj, D laŭ orakolo.
9. Duplikataj, nestitaj kaj interkovrantaj intervaloj kun trans-A/B-kovro: neniu duobla kalkulo.
10. Apudaj fermitaj intervaloj kaj disaj plej-altaj sumoj: precizaj du kanonaj listoj kaj D.
11. Ripetitaj idoj; nevalida id kaj nevalida uzata kunteksto propagas originalan Stage32-eraron ankaŭ ĉe malplena A/B.
12. Arbitr-grandaj poz/negaj limoj kaj kuntekstaj tagoj, inkluzivaj limoj, monotoneco: aldoni B-intervalojn ne pliigas D; aldoni A-intervalojn ne malpliigas D.

## Kvanta sendependa antaŭkontrolo — NE Gleam Native

Ekzekutita sendependa JavaScript BigInt-a antaŭkontrolo: **364** gap-listoj el `{42,43,963}` por longo 0..5, krucigitaj kun **14 × 14** fiksaĵaj A/B-familioj: **71,344** kazoj. Pliaj **2,000** determinisme generitaj kazoj kun 0..8 gapoj, 0..10 A/B-intervaloj kaj entjeraj limoj inkluzive de `10^70`: entute **73,344/73,344**, neniu malsamo. Unu vojo rekte listigis fenestrojn kaj testis membrecon en originalaj A/B; la alia sendepende kunfandis intervalojn, uzis prefikssumojn kaj binaran serĉon por kalkuli `U(A∪B)-U(B)`. Ĉi tio kontrolas nur la matematikan projekton, **ne** la ankoraŭ ne-ekzistantan Gleam-produktkodon aŭ Native/CI.

## Devigaj pordegoj kaj sekva ago

A. Ĉi tiu kontrakta komito ŝanĝas **nur** `DEVELOPMENT_STAGE.md` kaj `STAGE34_DISCOVERY30_CONTRACT.md`; la nova preciza SHA bezonas `completed/success` Native kun **370/370**, read-only formatter, fontintegreco, kaj Canonical Names Lock `completed/success` sur la sama SHA. Aŭtomata CI `queued/in_progress` estas nek PASS nek bloko.
B. Nur post A, faru la produktmodulon kaj **12 unikajn publikajn** sendepend-orakolajn Gleam-testojn en aparta koda komito. **382** estas prognozo, ne Native-mezuro. Preciza koda SHA bezonas Native **382/382** kaj Names Lock success.
C. Nur post B, aparta dokumenta fermo kaj poste fina metadata-komito povas marki `LAST_COMPLETED_STAGE=34`; ĉiu nova SHA bezonas sian propran komplete sukcesan Native **382/382** kaj Names Lock.
D. Ne duobligu CI-dispatch; ne ŝanĝu main, ne merge, ne publikigu. Ne atribuu PASS al kontrakto antaŭ la novaj logoj.

## Fermo-dokumentado post koda CI (2026-11-20; atendas propran HEAD-CI)

La unua alineo kaj la 12 planitaj testoj supre priskribas la historian **kontraktan komiton**, ne la nunan kodan staton. La kontrakta pordego estis akceptita ĉe `fe8ac18262a622a457b1f3215fd3aecb9e457717`: Native [44800345737](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44800345737), job 136510549385, `completed/success`, 370/370, format/source-integrity PASS, artefakto 14663585433 (`sha256:6daf492df97875ec05a44b383f2839d0a9e6b80c3598cb16b4a2f24c77f5c5d5`); Names Lock [44800345738](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44800345738), job 136510549809, `completed/success`.

La origina aparta koda komito [637fa929](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/637fa9292f4de7b204128240f64ebec84cee9e5a) aldonis `src/pastafari/discovery_30_difference_bands.gleam` kaj `test/discovery_30_test.gleam`, kun 12 unikaj publikaj testoj. Native [44811503113](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811503113), job 136548937934, finiĝis kun **formata malsukceso** en la sola nova testdosiero: tri kanonaj format-diferoj; **neniu testo ruliĝis**. Ĝia artefakto estas 14668530514. Names Lock [44811503326](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811503326), job 136548941122, sukcesis ĉe tiu origina SHA. Nek tiu malsukcesa Native nek la antaŭviditaj 382 testoj estas PASS.

Aparta preciza, nur-formata flikaĵo [379750d0](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/379750d078b27e3ce3566c090f751c21a528da22) aplikis la tri diferencojn nur en `test/discovery_30_test.gleam`, sen algoritmoŝanĝo, konservante ĉiujn 12 unikajn testojn. Native [44819860467](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819860467), job 136577633798, `completed/success` je la **preciza sama SHA**: Gleam 1.18.1 / OTP 28 / ERTS 16.4.0.7, read-only formatter PASS, **382 passed, no failures**, fontintegreco PASS. Artefakto 14672000553, `sha256:404444d50b5b2861e6dae75daec1b904db059018f233fc41b37cc7d0224371ed`. Canonical Names Lock [44819860615](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44819860615), job 136577634843, ankaŭ `completed/success` ĉe tiu sama SHA. **La koda pordego estas akceptita; ne la tuta Stage34.**

Ĉi tiu aparta dokumenta komito ŝanĝas **nur ĉi tiun kontrakton kaj `DEVELOPMENT_STAGE.md`**, kun `LAST_COMPLETED_STAGE=33`. Nur kiam ĝia propra HEAD havas ambaŭ `completed/success` Native **382/382** kaj Names Lock, oni rajtas krei apartan finan metadata-komiton; ankaŭ tiu fina SHA bezonas sian propran Native 382/382 kaj Names Lock antaŭ `LAST_COMPLETED_STAGE=34`. Neniu merge/main/publikigo/duobla CI-dispatch.
