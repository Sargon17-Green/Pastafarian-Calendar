# Stadio 36 — DISCOVERY 32: simetria diferenco (XOR) de sumintervalaj fenestroj

PROJECT_ID: `PC-BRANCH-GLEAM-ESPERANTO`
Branĉo: `Gleam+Esperanto`. Programo: 55 stadioj. Nova amplekso estis **eksplicite rajtigita de la uzanto la 2026-11-21** per respondo "מאשר" al la limigita Stage36-peto; dokumentita en [issue #33](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/33#issuecomment-7061513839). La historia `NO_STAGE36` en Stage35-kontrakto restas vera por *Stage35*, sed ĉi tiu nova aparta rajtigo ebligas nur Stage36. Neniu main, merge aŭ publikigo.

**Ĉi tiu komito estas kontrakto kaj metadatenoj NUR.** Ĝi NE enhavas Stage36-produktan kodon, novajn Gleam-testojn aŭ plenan datkonverton.

## Kontrolita antaŭkondiĉo

Stage35 fina metadata SHA [a3d79bd051a2f650050dfd1d87d66540efce55c9](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/a3d79bd051a2f650050dfd1d87d66540efce55c9) estas identa al la branĉo (ahead=0, behind=0). Native [44892531882](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44892531882), job `136811240553`, `completed/success`, Gleam 1.18.1 / Erlang OTP 28 / ERTS 16.4.0.7, read-only `gleam format --check src test`, fontintegreco PASS, **394 passed, no failures**; artefakto `14702188799`, digest `sha256:a1a8d8c0e7bbf0dd61152a4c4897164d7a3b2eb7518118caed5e3d89f5056f3b`, head SHA identa. Canonical Names Lock [44892531924](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44892531924), job `136811240714`, `completed/success` sur la sama SHA. Ĉiuj Stage35-pordegoj estas akceptitaj. La malnova `STAGE35_FINAL_METADATA_CI_PENDING` en historio priskribis staton antaŭ la konfirmo.

## Matematika kontrakto

Enigo: `bootstrap.MonsterContext`, eksplicita ordigita `List(Int)` de k bovlo-identigiloj (ripetoj estas permesataj), kaj du listoj A kaj B de inkluzivaj entjeraj `discovery_27_sum_bands.SumBand(lower, upper)`. La akceptita Stage21 liveras pozitivajn gapojn `g[i]` en [42,963], aŭ sian originalan eraron. Fenestro estas la **indeksa** paro `(a,b)`, `0 <= a < b <= k`, kun `s(a,b)=sum(g[a:b])`. Neniam deduplikigu ripetitajn identigilojn.

`UA` enhavas fenestrojn kies sumo apartenas al almenaŭ unu valida fermita bando de A; `UB` analoge por B. Inversa bando (`lower > upper`) estas simple malplena kaj NE eraro. Difinu:
- `L=|UA|`, `R=|UB|`, `I=|UA ∩ UB|`, `U=|UA ∪ UB|`, `T=k(k+1)/2`.
- **`X=|UA △ UB|=|UA \\ UB|+|UB \\ UA|=L+R-2I=U-I`**.
- Devigaj invariantoj: `0<=I<=L<=U<=T`, `0<=I<=R<=U<=T`, `U=L+R-I`, `0<=X<=U<=T`, `X=L+R-2I`.

A=[] aŭ B=[]: X estas la fenestronombro de la alia aro; ambaŭ malplenaj: X=0; A=B: X=0. Duplikataj, nestitaj, interkovrantaj, apudaj aŭ disaj bandoj; negativaj ekstremaj entjeraj limoj; 0 idoj; grandaj BEAM Int valoroj kaj finpunktoj estas permesataj laŭ la suba Stage35-semantiko. Neniuj ŝanĝoj de validigordo pro malplenaj listoj.

## Produkta API kaj vokordo

Nova produktdosiero: `src/pastafari/discovery_32_symmetric_difference_bands.gleam`.
Nova testdosiero: `test/discovery_32_test.gleam`.

```gleam
pub type SymmetricDifferenceWindowCount {
  SymmetricDifferenceWindowCount(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    intersection_windows: Int,
    combined_windows: Int,
    symmetric_difference_windows: Int,
    total_windows: Int,
  )
}
pub fn dispatch_discovery_32(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(SymmetricDifferenceWindowCount, discovery_19_interval_value.Discovery19Error)
```

1. Voku **precize unufoje** `discovery_31_intersection_bands.dispatch_discovery_31(context, ids, A, B)`, eĉ kiam listoj estas malplenaj. Ĉe `Error(err)`, resendu **la saman** `Error(err)` sen aldona laboro; ne anstataŭigu erarojn.
2. Nur ĉe `Ok(value)`, prenu `L=value.left_windows`, `R=value.right_windows`, `I=value.intersection_windows`, `U=value.combined_windows`, `T=value.total_windows`; kontrolu ĉiujn invariantojn antaŭ redoni `Ok`. Ĉe iu malobservo redonu `Error(discovery_19_interval_value.InvalidStream)`.
3. Kalkulu `X=L+R-2*I` per ekzakta `Int`-aritmetiko. Resendu la tri **jam kanonigitajn** bando-listojn en sia originala maldekstra, kombinita, dekstra ordo kaj ĉiujn nombrilojn. Ne kanonigu denove.
4. En produktkodo ne voku Stage21, Stage32, Stage33, Stage34, test/reference, alian lingvan branĉon aŭ plenan datkonvertilon. Neniu produktfenestra enumerado. Ne modifu antaŭajn modulojn.
5. Komplekseco: unu Stage35-voko (ĝi jam kunmetas tri Stage32-vokojn) plus **O(1)** aritmetiko kaj rezulto-referencoj; neniu kroma proporcionala fenestro-memoro, neniu nova dependeco. Ĉi tio estas nur kalkulo de eksplicitaj indeksaj sumfenestroj, NE kalendara datkonverto.

## Sendependa test-orakolo

**Nur en testoj** voku Stage21 `discovery_21_gate_batch.dispatch_discovery_21(context, ids)` por akiri la realajn gapojn (kontrolu [42,963]). Enumeru ĉiujn `(a,b)` per du nestitaj traversoj; sumu la originalajn gapojn sen produkta sumfenestra helpilo. Por ĉiu sumo, apartaj rektaj membrecotestoj sur **originalaj, nekanonigitaj** A kaj B; pliigu la atendatan X nur kiam `in_A != in_B`. Rekalkulu L, R, I, U, T rekte por la ceteraj kampoj. Por kanonaj listoj, uzu **eksplicitajn malgrandajn fiksaĵojn**, ne Stage27-produktan kanonigilon. La atendataj valoroj ne rajtas voki Stage32..36 aŭ uzi la produktan algebran egalecon `L+R-2I`.

Planu **precize 12 unikajn publikajn `*_test`** funkciojn:
1. Malplenaj idoj kaj ambaŭ bando-listoj: ĉiuj nombroj 0, ĉiuj kanonoj [].
2. Malplenaj idoj kun neuzata nevalida kunteksto, ne-trivialaj A/B, kanonoj per eksplicitaj fiksaĵoj.
3. Unu gap ekzakte ĉe fermitaj limoj, inkluzive de sama singleton en ambaŭ: X=0.
4. Unu gap nur en A kaj poste nur en B: X=1; tuj ekster: X=0.
5. Du kaj kvar gapoj kun rekte enumerita nekongrua membreco; ĉiuj raportitaj nombroj egalas la orakolon.
6. A=[], B ne-malplena; poste B=[], A ne-malplena; neniu valida bando: X=0.
7. A=B kun kovrantaj disaj/duplikataj bandoj: X=0; interŝanĝo A/B ne ŝanĝas X.
8. Inversaj, negativaj kaj disaj bandoj; neniuj falsaj pozitivaj fenestroj.
9. Duplikataj, nestitaj kaj interkovrantaj bandoj, kun trans-flanka kovro: sen duobla kalkulo.
10. Apudaj fermitaj bandoj, triaj kombinitaj kanonoj kaj inkluzivaj finpunktoj.
11. Ripetitaj bovlo-identigiloj: fenestroj laŭ indekso; propagado de nevalida id/kunteksto laŭ Stage35-prioritato, ankaŭ ĉe A/B=[].
12. Tre grandaj poz/negaj limoj, longaj gaplistoj, simetrio `X(A,B)=X(B,A)`, `X(A,A)=0`, kaj limoj `X<=T` (ne pretendu monotonecon de XOR ĉe pligrandigo de unu aro).

## Sendependa kvanta antaŭkontrolo — NE Gleam Native

Ekzekutita determinisma JavaScript BigInt-kontrolo kun du apartaj metodoj: (1) rekta fenestro-enumerado kaj XOR-membreco en originalaj bandoj; (2) kanonigo, intervalsekco, prefikssumoj kaj duuma serĉo por kalkuli `L+R-2I`. Gapoj elektitaj el {42,43,963}. **20,449** fiksitaj kazoj (ĉiuj gaplistoj de longo 0..4 × 13² bando-familioj), plus **3,000** determinismaj kazoj (seed 20261121, 0..8 gapoj, ĝis 7 bandoj/flanko, limoj inkluzive de ±10^70): **23,449/23,449 kongruaj, 0 malkongruoj**. Ĉi tio estas matematika antaŭkontrolo, **ne Gleam-kompilo, CI aŭ Native PASS**.

## Devigaj akceptopordegoj

A. **Kontrakto unue:** nur ĉi tiu kontrakto kaj `DEVELOPMENT_STAGE.md` ŝanĝiĝas. La nova kontrakta SHA devas ricevi **Native completed/success, 394/394**, read-only formatter/source-integrity PASS, konfirmita job/log/artefakto **kaj** Canonical Names Lock completed/success ĉe **la sama SHA**. Queued/in_progress ne estas PASS nek bloko; neniu duobla CI-dispatch.
B. **Nur post A:** aparta koda komito aldonu nur la novan produktmodulon kaj 12 unikajn publikajn sendepend-orakolajn testojn; **406** estas nur prognozo, ne Native-mezuro. Akcepto post exact-SHA Native **406/406** + Names Lock success, kun job/log/artefakto.
C. **Nur post B:** dokumenta fermo en aparta komito, ĝia exact-SHA Native 406/406 + Names, poste aparta fina metadata-komito kiu markas `LAST_COMPLETED_STAGE=36` nur post sia propra exact-SHA Native 406/406 + Names. Ĉiu SHA havas propran pruvon.
D. Malpermesite: main/merge/publikigo, ŝanĝo de protektita branĉo, test-malfortigo, alia lingva fixture, plen-datkonverto, malpligrandigo de pruvpordegoj aŭ kreo de Stage37 sen aparta amplekso. Konservu Stage35-evidenton.