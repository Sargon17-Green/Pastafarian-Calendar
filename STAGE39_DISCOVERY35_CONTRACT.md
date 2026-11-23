# Stadio 39 — DISCOVERY 35: ekzakta koeficiento de interkovro de sumfenestraroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto; programo: 55 stadioj.
Baza akceptita HEAD: `5c6be73496da1633e6bf882d97da4f3bf31a3e0d`, LAST_COMPLETED_STAGE=38/55.
Nur kontrakta preparo; neniu Stage39-a produkta kodo aŭ nova Gleam-testdosiero en ĉi tiu pordego.

## Rajtigo kaj antaŭkondiĉoj

La daŭra uzanta decido de 2026-11-22 ([issue #36, komento 7085562104](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/36#issuecomment-7085562104)) permesas transiri inter stadioj en la **sama** ekzistanta branĉprogramo sen aparta aprobo. Ĝi NE permesas main/merge, protektitajn branĉojn, publikigon, alilingvan kopiadon, malfortigi testajn orakolojn aŭ efektivigi plenan datkonverton. Historiaj kontraktoj restas senŝanĝaj.

Stage38 antaŭe akceptita ĉe identa branĉa SHA `5c6be73496da1633e6bf882d97da4f3bf31a3e0d`: [Native run 45076391796](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076391796), job 137374441963, **completed/success, 430/430**, Gleam 1.18.1 / OTP 28 / ERTS 16.4.0.7, read-only formatter kaj fontintegreco PASS. [Artifact 14775333264](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076391796/artifacts/14775333264), head_sha identa kaj GitHub ZIP digest `sha256:98dd01133aad70eeed90571650f0b1ac96ad0768a928ea9b639482bcda008d79`. [Canonical Names run 45076391785](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45076391785), job 137374441915, completed/success sur sama SHA. Tiuj historiaj 430 sukcesoj ne estos rerulitaj sur tiu sama SHA.

## Ekzakta matematika kontrakto

Enigo: `bootstrap.MonsterContext`; ordigita `List(Int)` de `k` eksplicitaj bovlo-ID-oj (ripetoj NE deduplikataj); du originalaj `List(discovery_27_sum_bands.SumBand)` kun inkluzivaj entjeraj limoj A kaj B. Tuta erar-prioritato kaj kanonigo estas **precize** tiuj de Stage38. Inversa intervalo `lower>upper` reprezentas la malplenan aron, ne eraron.

Stage21 donas pozitivajn gapojn `g[0..k)`. Ĉiu distinga **indeksa** fenestro `(a,b)`, `0<=a<b<=k`, havas sumon `s(a,b)=sum(g[a:b])`; identaj sumoj ĉe malsamaj indeksaj paroj restas malsamaj fenestroj. `UA` enhavas fenestrojn kies sumo kuŝas en almenaŭ unu **origina** valida A-bando; `UB` simile por B.

Difinu `L=|UA|`, `R=|UB|`, `I=|UA∩UB|`, `U=|UA∪UB|`, `X=|UA△UB|`, `T=k(k+1)/2`. La koeficiento de interkovro (Szymkiewicz–Simpson) estas:
- `L=R=0`: `O=1/1` (du malplenaj fenestraroj estas egalaj).
- `min(L,R)=0 < max(L,R)`: `O=0/1`.
- `L>0` kaj `R>0`: `O=I/min(L,R)`, reprezentita kiel **ekzakta reduktita** frakcio `p/q` kun `gcd(p,q)=1`, `q>0`, `0<=p<=q`.

Ĉiam kontrolu `0<=I<=min(L,R)`, `L<=U<=T`, `R<=U<=T`, `U=L+R-I`, `X=U-I=L+R-2I`, `0<=X<=U`. Kiam ambaŭ flankoj ne estas malplenaj, `O=1` se kaj nur se la pli malgranda fenestraro estas subaro de la alia; tio **ne** postulas `UA=UB`. Interŝanĝi A kaj B ne ŝanĝas O. Ne asertu monotonecon de O ĉe unuflanka aldono de bandoj.

Por sanaj ne-malplenaj flankoj validas `O >= D >= J`, kie `D=2I/(L+R)` (Stage38), `J=I/U` (Stage37); kontrolu per ekzakta krucomultipliko, ne per glitkomoj. Kiam ambaŭ flankoj malplenaj, ĉiuj tri estas 1; kiam unu flanko estas malplena, ĉiuj tri estas 0. Metamorfoj estas **aldonaj** kontroloj, NE la sendependa orakolo.

Abstrakta atestanto (NE aserto pri ekzisto de apartaj realaj bovlo-ID-oj): `g=[42,42,42]`, A=`[[42,85]]`, B=`[[43,963]]` donas `L=5,R=3,I=2,U=6,X=4,T=6,O=2/3`. Alia atestanto: `g=[42,42,43]`, A=`[[42,43],[85,85]]`, B=`[[43,963]]` donas `L=4,R=4,I=2,U=6,X=4,T=6,O=1/2`.

## Publika API kaj produkta disciplino

Plana nova produkto: `src/pastafari/discovery_35_overlap_bands.gleam`.
Plana nova testdosiero: `test/discovery_35_test.gleam`.

~~~gleam
pub type OverlapWindowSimilarity {
  OverlapWindowSimilarity(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    intersection_windows: Int,
    combined_windows: Int,
    symmetric_difference_windows: Int,
    total_windows: Int,
    jaccard_numerator: Int,
    jaccard_denominator: Int,
    dice_numerator: Int,
    dice_denominator: Int,
    overlap_numerator: Int,
    overlap_denominator: Int,
  )
}

pub fn dispatch_discovery_35(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(OverlapWindowSimilarity, discovery_19_interval_value.Discovery19Error)
~~~

1. Voku **precize unufoje** `discovery_34_dice_bands.dispatch_discovery_34(context, ids, A, B)`, ankaŭ por `ids=[]` kaj `A=B=[]`. Repropagu `Error(e)` senŝanĝe; neniam ŝanĝu la erar-prioritaton.
2. Sur `Ok(previous)`, kontrolu ĉiujn ses nombro-invariantojn. Krome validigu la heredajn reduktitajn Jaccard- kaj Dice-frakciojn: pozitiva denominatoro, intervalo [0,1], gcd=1, ĉe `U=0` J=1/1 alie `j_p*U=I*j_q`; ĉe `L+R=0` D=1/1 alie `d_p*(L+R)=2I*d_q`. Malkongruo redonas `Error(discovery_19_interval_value.InvalidStream)`. Ne kreu falsajn erarojn per ŝanĝo de antaŭaj moduloj.
3. Metu la tri rezultajn kazojn `(1,1)`, `(0,1)`, aŭ `(I/h, min(L,R)/h)` kie `h=gcd(I,min(L,R))`; neniam kalkulu gcd kun nula denominatoro. Poste kontroli `q>0`, `0<=p<=q`, `gcd(p,q)=1`, kaj en la tria kazo `p*min(L,R)=I*q`. Kontrolu ankaŭ `O>=D>=J` per krucomultipliko. Propagu ĉiujn 12 heredajn kampojn kaj la tri kanonajn listojn sen ordŝanĝo aŭ rekanonigo.
4. La nova produktmodulo NE voku Stage21, Stage32, Stage33, test/reference, alilingvan fonton, fenestro-enumeradon aŭ plen-datan kalkulon. Kosto super unu Stage38-voko: `O(log(max(1,min(L,R))))` aritmetikaj Eŭklidaj paŝoj kaj `O(1)` plia entjer-vorta stokado, sen aserto pri konstanta bitkosto ĉe grandaj BEAM-Int.
5. Neniu nova dependaĵo, glitkomo, bandomerge aŭ fenestra materialigo.

## Vere sendependa testo-orakolo

En **nur** `test/discovery_35_test.gleam`, prenu originalajn gapojn el Stage21 por validaj ID-oj. Rekalkulu rekte ĉiujn `(a,b)` kun du nestitaj iteracioj kaj originala, nekanonigita A/B-membreco; ne legu la L/R/I/U de Stage38 por kalkuli atendatajn rezultojn. Por L/R/I, aldonu po unu laŭ la respektivaj buleaj membrecoj. Trovu la frakcion per serĉado de **plej malgranda pozitiva denominatoro** `q=1..min(L,R)` tiel ke `(I*q) mod min(L,R)=0`, poste `p=I*q/min(L,R)`; la nul-kazoj estas eksplicitaj. Neniam uzu produktan gcd en la orakolo. Kanonajn bandlistojn kontrolu per eksplicitaj malgrandaj fiksaĵoj. K=0..12 limigas la testan buĝeton.

Planu **precize 12 unikajn publikajn `*_test`**:
1. Malplenaj ID-oj kaj ambaŭ malplenaj bandoj: `L=R=I=T=0,O=1/1`.
2. Malplenaj ID-oj, ne-malplenaj/eksteraj/inversaj bandoj: `O=1/1`, eksplicitaj kanonoj.
3. Unu gap, A=B, ambaŭ fermitaj finpunktoj: `O=1/1`.
4. Unu gap nur en unu flanko (ambaŭ direktoj): `O=0/1`; ambaŭ ne-trafitaj: `O=1/1`.
5. Du-gapaj part-interkovraj kazoj kun rekte nombritaj ses nombriloj.
6. Tri- kaj kvar-gapaj kazoj kun vere ne-trivialaj reduktoj (`1/2`, `2/3`, `3/4`) trovataj per orakolo, ne supozataj el nevalidaj ID-oj.
7. Unu fenestraro vera subaro de la alia sed ne egala: `O=1/1`, `J<1` kaj `D<1`.
8. A=B kun duplikataj/nestitaj/interkovrantaj bandoj: nenia duobla kalkulo.
9. Apudaj kaj inversaj intervaloj, negativaj/±10^70 limoj: eksplicitaj kanonoj, precizaj frakcioj.
10. Ripetitaj bovlo-ID-oj, malsamaj indeksaj fenestroj kun samaj sumoj: neniu deduplikado.
11. InvalidBowlId kaj InvalidContext: ĝusta sama `Error` kaj prioritato kiel Stage38, ankaŭ ĉe A=B=[].
12. Ĉe ĝis 12 gapoj: simetrio, identeco, `O>=D>=J`, ekzaktaj denominatoroj kaj sendependa rekta orakolo.

Neniu testdosiero aŭ produkta modulo estas skribata dum ĉi tiu kontrakta pordego.

## Ekstera matematika antaŭkontrolo — ne Native

En aparta JavaScript BigInt-sen-dependa antaŭkontrolo la **indeksa** fenestro-orakolo kun originala bandomembreco, sendependa minimum-denominatora serĉo kaj alispeca Eŭklida redukto estis komparitaj. 121 gapsekvencoj de longo 0..4 super {42,43,963} × 13 elektitaj A-bandfamilioj × 13 elektitaj B-bandfamilioj = **20,449** kazoj. 5,000 pliaj determinismaj pseudo-hazardaj kazoj (LCG 32-bit, seed 20261123, k=0..12, ĝis sep bandoj flanke, inkluzive inversajn kaj ±10^70-limojn) donis entute **25,449/25,449 kongruojn, 0 malkongruojn**. Ankaŭ kontroliĝis la ses nombrilaj invariantoj kaj `O>=D>=J` per krucaj produktoj. Tio estas nur matematika modelo de Stage39, ne Gleam-koda, CI-, Native- aŭ differential-akcepto.

## Devigaj SHA-pordegoj

A. **Kontrakto antaŭ kodo**: en ĉi tiu etapo nur ĉi tiu kontrakto kaj minimume necesa `DEVELOPMENT_STAGE.md` stato. Por akcepti la kontrakton, bezonatas **sama fina SHA** Native job/log completed/success kun ekzakte 430/430, `gleam format --check src test` read-only PASS, fontintegreco PASS, Gleam 1.18.1/OTP28, kaj Canonical Names Lock completed/success. Kontrolu artefakton `head_sha`, digest kaj logon. `queued` kaj `in_progress` ne estas PASS nek bloko. Neniu mana duobla CI.
B. **Nur post A**: aparta koda komito kun unu nova produkta modulo kaj ekzakte 12 publikaj unikaj sendepend-orakolaj testoj; **442** estas nur antaŭdiro (430+12), ne Native rezulto. Akcepto nur post sama-SHA completed/success Native 442/442 kaj Names, kun job/log/artifact/digest. Formatter-/kompilfiasko signifas `NOT_RUN` por testoj.
C. **Nur post B**: aparta dokumenta fermo kaj ĝia sama-SHA Native442/442+Names, poste aparta fina metadata-markilo kaj ĝia **propra** sama-SHA Native442/442+Names antaŭ ol la Stage39 estu akceptita kaj `LAST_COMPLETED_STAGE` povu fariĝi 39.
D. `LAST_COMPLETED_STAGE=38` dum A/B/C estas neakceptitaj; neniam ŝanĝu main, merge/publish, rajtigan politikon, kanonajn nomojn, aŭ la jam akceptitajn Stage38-testojn. Ne troigu partan PASS kiel tutan akcepton.
