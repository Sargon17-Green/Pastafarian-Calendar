# Stadio 38 — DISCOVERY 34: ekzakta reduktita Sørensen–Dice-simileco de sumfenestraroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto; programo: 55 stadioj.
Baza akceptita stato: Stage37, LAST_COMPLETED_STAGE=37/55, fina SHA bfe1c01d7c0d784f657ba46f8ca78a53bf1c433e.

## Daŭra rajtigregulo — historiaj limigoj ne reverkataj

La uzanto klarigis eksplicite la 2026-11-22: **“אין צורך בהרשאה לעבור משלב לשלב”** — ne necesas aparta rajtigo por transiri de unu stadio al la sekva en ĉi tiu ekzistanta projekto/branĉo. La decido estis registrita en [issue #36, komento 7085562104](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/36#issuecomment-7085562104). La historia Stage37-kontrakto kaj ĝia NO_STAGE38 limigis nur la antaŭan rajtigperiodon; oni ne retroaktive modifu ĝin. Stage38 nun povas esti preparata en la rajtigita branĉo **laŭ per-SHA akceptopordegoj**, sed nenia rajtigo ekzistas por main, merge, protektitaj branĉoj, publikigo, interlingva kopiado, malfortigo de orakoloj aŭ ekster-kontrakta plena datkonverto. Same ne postulu apartan uzantan rajtigon por la posta stadio post akcepto de ĉi tiu stadio.

Stage37-a fina pruvo ĉe identa branĉ-HEAD: Native [45065337222](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065337222), job 137340112001, completed/success, Gleam 1.18.1 / Erlang OTP 28, 418/418, read-only format kaj fontintegreco PASS; [artifact 14771370376](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065337222/artifacts/14771370376), digest sha256:6141056db7f62d455d786a3594ceda342fafe3874cdd029bb008113188659fb9 kaj ĝusta head_sha; [Names 45065337235](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065337235), job 137340112247, completed/success. Nek Stage37 nek ĝiaj testoj bezonas rerulon sur tiu jam akceptita SHA.

## Preciza matematika difino

Enigo: bootstrap.MonsterContext, eksplicita ordigita List(Int) de k bovlo-identigiloj, kaj du List(discovery_27_sum_bands.SumBand) A kaj B kun inkluzivaj entjeraj finoj (inversaj bandoj ne enhavas valorojn). Ĉiuj validigoj kaj erar-prioritatoj herediĝas el Stage37.

Por la pozitiva gap-listo g[0..k), fenestro estas la **indeksa** paro (a,b), kun 0 <= a < b <= k, sumo s(a,b)=sum(g[a:b]). La fenestraroj UA, UB enhavas la indeksajn fenestrojn kun sumo en respektive almenaŭ unu ORIGINALA bando de A aŭ B. Ripetitaj bovlo-identigiloj ne estas deduplikataj. Difinu:
- L=|UA|, R=|UB|, I=|UA∩UB|, U=|UA∪UB|, X=|UA△UB|, T=k(k+1)/2.
- Invariantoj: 0<=I<=L<=U<=T, 0<=I<=R<=U<=T, U=L+R-I, X=U-I=L+R-2I.
- D(A,B) = 1 kiam L+R=0 (ambaŭ fenestraroj malplenaj); alie D(A,B)=2I/(L+R).
- Eligo p/q estas ekzakte reduktita: q>0, 0<=p<=q, gcd(p,q)=1 kaj p*(L+R)=2I*q se L+R>0. Neniu glitkomo aŭ proksimuma kalkulo.
- D(A,B)=D(B,A); D(A,A)=1; 0<=D<=1. **Ne** asertu ĝeneralan monotonecon dum unuflanke aldonas bandojn.
- Kiam U>0 la metamorfaj frakcioj J=I/U (Stage37) kaj D kontentigas D=2J/(1+J) per ekzaktaj krucaj multiplikoj. Ĉi tiu rilato estas nur kroma kontrolo, ne anstataŭ sendependa orakolo.

## Produkta API kaj deviga vokordo

Nova dosiero: src/pastafari/discovery_34_dice_bands.gleam
Nova testdosiero: test/discovery_34_test.gleam

~~~gleam
pub type DiceWindowSimilarity {
  DiceWindowSimilarity(
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
  )
}

pub fn dispatch_discovery_34(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(DiceWindowSimilarity, discovery_19_interval_value.Discovery19Error)
~~~

1. Voku **precize unufoje** discovery_33_jaccard_bands.dispatch_discovery_33(context, ids, A, B), eĉ ĉe ids=[] aŭ A=B=[]. Eraro estas resendata **senŝanĝe**, konservante la tutan antaŭan validigprioritaton.
2. Nur ĉe Ok(previous), ekstraktu L,R,I,U,X,T kaj kontrolu ĉiujn supre difinitajn invariantajn neegalaĵojn/egalecojn. Kontrolu ankaŭ la Stage37 Jaccard-frakcion per q>0, 0<=p<=q, gcd(p,q)=1, kaj ĉe U=0 ĝuste 1/1, ĉe U>0 p*U=I*q. Ĉiu malobservo -> Error(discovery_19_interval_value.InvalidStream). Ne ŝanĝu antaŭajn modulojn por artefarite injekti nevalidan rezulton.
3. Se L+R=0, metu (dice_numerator,dice_denominator)=(1,1). Alie, per ekzaktaj entjeroj metu n=2I, d=L+R, h=gcd(n,d), (p,q)=(n/h,d/h). Postkalkule kontrolu q>0, 0<=p<=q, gcd(p,q)=1 kaj p*(L+R)=2I*q. Propagu la tri jam kanonigitajn bandlistojn en la sama ordo kaj ĉiujn antaŭajn nombrilojn/frakcion sen novaj kanonigoj.
4. Produktkodo ne voku Stage21, Stage32 aŭ pli fruajn fenestromodulojn, test/reference, alilingvan branĉon, plen-datkonvertilon aŭ fenestran enumeradon. Neniu nova dependeco, neniu nova per-fenestra memoro.
5. Kosto aldonita super unu Stage37-voko: O(log(max(1,L+R))) Eŭklida aritmetiko, O(1) plia memoro (ekzaktaj BEAM-entjeroj; ne pretendu konstantan bit-koston). Neniu ekster-kontrakta kalendara datkonverto.

## Sendependa orakolo en Gleam-testoj

Nur la nova testdosiero povas voki Stage21 (dispatch_discovery_21) por ekstrakti realajn originalajn gapojn. Rekalkulu ĉiujn indeksajn fenestrojn per du nestitaj traversoj; kontrolu rekte la membrecon en la ORIGINALAJ, nekanonigitaj A kaj B. Derivu L/R/I/U/X/T de tiuj buleaj testoj, neniam de Stage37/Stage38-produkta algebra kombino aŭ produktaj kanonigiloj. Kiam L+R>0, serĉu sendepende la **plej malgrandan pozitivan denominatoron** q en 1..(L+R) por kiu (2I*q) mod (L+R)=0 kaj p=2I*q/(L+R). Kiam L+R=0, atendu 1/1. Neniam uzu produktan gcd en la orakolo. Kanonajn bandojn validigu per eksplicitaj malgrandaj fiksaĵoj, ne per produktfunkcio. Teni k<=12 por buĝeti la testan serĉon.

Planu **precize 12 unikajn publikajn *_test** funkciojn:
1. ids=[], A=B=[] -> ĉiuj nombriloj 0 kaj D=1/1.
2. ids=[], A kaj B ne-malplenaj kun inversaj/eksteraj limoj -> D=1/1, eksplicitaj kanonoj.
3. Unu gap kun egalaj A=B ĉe ambaŭ fermitaj finpunktoj -> D=1/1.
4. Unu gap nur A, nur B, aŭ nek A nek B -> D=0/1 aŭ 1/1 laŭ rekte enumerita orakolo.
5. Du-gapaj kaj tri-gapaj part-intersekcoj kun vere ne-trivialaj pozitivaj reduktoj; ĉiuj ses nombriloj el orakolo.
6. Kvar-gapaj kazoj kun D=1/2 aŭ D=2/3 kiam atestite per rekte enumerita orakolo.
7. A=[] kun B ne-malplena, poste interŝanĝitaj flankoj; nul-unio kaj pozitiva unio.
8. A=B kun duplikatoj, nestitaj, disaj kaj interkovrantaj bandoj; neniu duobla kalkulo.
9. Apudaj inkluzivaj, inverse ordigitaj, negativaj kaj malvalidaj (lower>upper) bandoj; eksplicitaj kanonoj.
10. Ripetitaj bovlo-identigiloj sen deduplikigo, pluraj indeksaj fenestroj kun sama sumo.
11. Erar-prioritato: InvalidBowlId kaj InvalidContext eĉ se A=B=[]; ekzakte sama Error kiel Stage37.
12. 12-gapaj kaj ±10^70-limaj kazoj: D(A,B)=D(B,A), D(A,A)=1, intervalaj limoj, kaj sendependa rekta orakolo; metamorfa rilato al J nur kiel plia aserto.

## Matematika antaŭkontrolo jam efektivigita — NE Gleam Native

En izola JavaScript BigInt-kontrolo, rekta indeks-fenestra enumerado per originalaj bandlistoj + minimum-pozitiva-denominatora serĉo estis komparata kontraŭ aparta Eŭklida gcd-redukto de 2I/(L+R). 13 propraj bandfamilioj × ĉiuj gaplistoj kun longo 0..4 el {42,43,963} donis 20,449 kazojn. Aldone 5,000 determinismaj pseudo-hazardaj kazoj (LCG 32-bit, seed 20261122, gapoj longo 0..12, bandoj ĝis sep per flanko, inter finpunktoj ±10^70) donis **25,449/25,449 kongruajn, 0 malkongruojn**. La maksimuma kontrolita L+R estis 145. Kontrolitaj ankaŭ U=L+R-I kaj 0<=I<=min(L,R). Ĉi tio validigas la **abstraktan matematikan formulon**, NE la Gleam-kodon, Native, CI aŭ tutan Stage38.

## Devigaj akceptopordegoj

A. **Kontrakto antaŭ kodo.** Ĉi tiu nova kontraktdosiero kaj la necesaj DEVELOPMENT_STAGE.md-metadatenoj estas la solaj Stage38-ŝanĝoj. Nur post same-SHA Native completed/success **418/418**, Gleam1.18.1/OTP28, read-only gleam format --check src test, fontintegreco, kaj Canonical Names Lock completed/success, kun kontrolitaj run/job/log/artifact/head_sha/digest, la kontrakta pordego estas akceptita. Queued/in_progress ne estas PASS nek teknika bloko. Ne lanĉu duoblan CI.
B. **Nur post A:** aparta koda komito kun la produktmodulo kaj precize 12 unikaj publikaj sendepend-orakolaj testoj. **430/430 estas prognozo, NE Native mezuro.** Akceptu la kodan pordegon nur kun exact-SHA Native 430/430 + Names kaj artefakta kontrolo. Formatter- aŭ kompilfiasko signifas ke la testoj NE estis rulitaj.
C. **Nur post B:** aparta dokumenta fermo kun propra exact-SHA Native430/430 + Names, poste aparta metadata-finmarkilo kun sia propra exact-SHA Native430/430 + Names antaŭ ŝanĝo al LAST_COMPLETED_STAGE=38/55 kiel akceptita.
D. Nenia main, merge, publikigo, protektita branĉo, plena datkonverto, kopiado el aliaj lingvaj branĉoj, malfortigo de testoj aŭ falsa aserto pri CI. Post akcepto de Stage38, la ĝenerala uzanta regulo permesas plani Stage39 sen aparta permespeto, sed Stage39 havos sian propran kontrakton kaj proprajn per-SHA pordegojn.
