# Stadio 37 — DISCOVERY 33: ekzakta Jaccard-simileco de sumfenestraroj

PROJECT_ID: `PC-BRANCH-GLEAM-ESPERANTO`
Branĉo: `Gleam+Esperanto`. Programo: 55 stadioj.
**Aparta amplekso rajtigita de la uzanto la 2026-11-21** per eksplicita respondo **“מאשר”** al la demando pri preparo de aparta mezurebla Stage37-kontrakto. Pruva noto: [issue #34](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/34#issuecomment-7067715635). La historia `STAGE36_SCOPE=...NO_STAGE37...` limigis Stage36, sed ĉi tiu nova rajtigo permesas nur apartan Stage37. Neniu `main`, merge, publikigo, fremdlingva fixture aŭ plena datkonverto.

**Kontrakto unue.** Ĉi tiu preparo enhavas nur ĉi tiun kontrakton kaj la necesajn `DEVELOPMENT_STAGE.md` metadatenojn (la konektilo povas krei du sinsekvajn nur-dokumentajn komitojn). Neniu nova produktmodulo aŭ Gleam-testdosiero ekzistas pro la kontrakta pordego. Ne konfuzi matematikajn antaŭkontrolojn kun Native/CI.

## Akceptita baza stato

Stage36 fina branch-HEAD [`3f10f0ac66047414716acfb892faa56f8f930816`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/3f10f0ac66047414716acfb892faa56f8f930816) estis komparita kontraŭ `Gleam+Esperanto`: identical, ahead=0, behind=0. Native [44927945841](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927945841), job `136918062780`, `completed/success`, Gleam 1.18.1 / Erlang OTP 28 / ERTS 16.4.0.7, read-only formatter/source-integrity PASS, **406 passed, no failures**. Artefakto [14716447102](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927945841/artifacts/14716447102): `head_sha=3f10f0ac66047414716acfb892faa56f8f930816`, `sha256:143fd352f71cea73cc3664b4c044f8027e733da84a50b973207116e2a26b4dc8`. Canonical Names Lock [44927945798](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44927945798), job `136918062610`, `completed/success` sur sama SHA. **LAST_COMPLETED_STAGE=36**, ne 55.

## Preciza matematika kontrakto

Enigo: `bootstrap.MonsterContext`; eksplicita ordigita listo `List(Int)` de `k` bovlo-identigiloj, ripetoj permesitaj; originalaj listoj `A` kaj `B` de fermitaj entjeraj `discovery_27_sum_bands.SumBand(lower,upper)`. La jam akceptita Stage21 liveras pozitivajn `g[i]` en `[42,963]` aŭ originalan eraron. Indeksa fenestro `(a,b)` plenumas `0<=a<b<=k` kaj `s(a,b)=sum(g[a:b])`. Ĉiu indeksa paro estas distinga, ankaŭ ĉe ripetitaj idoj aŭ samaj sumoj; `T=k(k+1)/2`. UA/UB enhavas tiujn fenestrojn kies sumoj kuŝas en almenaŭ unu valida origina fermita bando de A/B respektive. Inversa bando `lower>upper` estas malplena (ne eraro).

La Stage36-eligo donas `L=|UA|`, `R=|UB|`, `I=|UA∩UB|`, `U=|UA∪UB|`, `X=|UA△UB|`, `T`. La **Jaccard-simileco de fenestraroj**, NE de nombraj intervaloj mem, estas la ekzakte reprezentita reduktita frakcio `J=p/q`:
- Se `U=0`, la difinita konvencio estas `p=1,q=1` (du fenestraroj sen ajna kongrua fenestro estas identaj), ankaŭ kiam A/B ne estas malplenaj sed neniu fenestro kvalifikiĝas.
- Se `U>0`, kalkulu `d=gcd(I,U)`, kun `gcd(0,U)=U`; `p=I/d`, `q=U/d`. Ĉi tio estas ekzakta entjera dividado, sen glitkoma aritmetiko, sen rondigo kaj sen dividado per nulo.
- Devigaj invariantoj: `0<=I<=L<=U<=T`, `0<=I<=R<=U<=T`, `U=L+R-I`, `X=L+R-2I=U-I`, `0<=X<=U`. Ĉe `Ok`, `0<=p<=q`, `q>=1`, `gcd(p,q)=1`. Se `U>0`, `p*U=I*q`; se `U=0`, `I=X=L=R=0`.
- Ekzemplo kun `g=[42,43]`: fenestrosumoj estas `42,43,85`; A=`[[42,85]]`, B=`[[43,85]]` donas `L=3,R=2,I=2,U=3,X=1,T=3,J=2/3`. Se `UA=UB`, J=1/1, eĉ kiam ambaŭ estas malplenaj. Se `I=0<U`, J=0/1.

Simileco estas simetria je interŝanĝo A/B, sed **NE** monótona je unuflanka aldono de bandoj; ne metu eraran monotonecan aserton en testojn. Ekstremaj BEAM-grandaj entjeraj limoj kaj pluraj nestitaj/interkovrantaj/apudaj/duplikataj/inversaj bandoj sekvas Stage36-semantikon.

## Produkta API kaj deviga vokordo

Nova dosiero: `src/pastafari/discovery_33_jaccard_bands.gleam`.
Nova testdosiero: `test/discovery_33_test.gleam`.

~~~gleam
pub type JaccardWindowSimilarity {
  JaccardWindowSimilarity(
    canonical_left_bands: List(discovery_27_sum_bands.SumBand),
    canonical_combined_bands: List(discovery_27_sum_bands.SumBand),
    canonical_right_bands: List(discovery_27_sum_bands.SumBand),
    left_windows: Int,
    right_windows: Int,
    intersection_windows: Int,
    combined_windows: Int,
    symmetric_difference_windows: Int,
    total_windows: Int,
    similarity_numerator: Int,
    similarity_denominator: Int,
  )
}
pub fn dispatch_discovery_33(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(JaccardWindowSimilarity, discovery_19_interval_value.Discovery19Error)
~~~

1. Voku **precize unufoje** `discovery_32_symmetric_difference_bands.dispatch_discovery_32(context,ids,A,B)`, sen mallongvojo eĉ ĉe A=[], B=[] aŭ ids=[]. `Error(err)` estas redonata **senŝanĝe**; ne modifu la prioritaton de Stage36-validigo.
2. Nur ĉe `Ok(previous)`, ekstraktu la ses nombrilojn kaj kontrolu **ĉiujn** supre listigitajn antaŭfrakciajn invariantojn. Ĉe malobservo redonu `Error(discovery_19_interval_value.InvalidStream)`. Ne ŝanĝu antaŭajn modulojn por produkti artefaritan malvalidan `Ok`; testu normalan validigon kaj dokumentu ĉi tiun defendan garantion statike.
3. Se `U=0`, uzu `(1,1)`; alie Eŭklida `gcd(I,U)` per ekzakta entjera resto, ekzakta `Int`-divido. Denove kontrolu `q>0`, `0<=p<=q`, kaj `p*U=I*q` antaŭ `Ok`. Resendu la tri jam kanonigitajn listojn **en la sama sinsekvo**; neniu rekanonigo.
4. Neniu produkta voko al Stage21, Stage32-retromoduloj, test/reference, alia lingva branĉo, plen-datkonvertilo aŭ fenestra enumerado. Neniu nova dependeco, neniu glitkomo. Produktkosto: unu Stage36-voko + `O(log(max(U,1)))` Eŭklida aritmetiko kaj `O(1)` plia memoro; neniu `O(k²)` produkta fenestrospaco.
5. Ĉi tiu API nur taksas jam difinitajn eksplicitajn bovlo-indeksajn fenestrojn; ne pretendas efektivigi plenan kalendaran datkonverton.

## Sendependa TESTA orakolo — ne uzu la produktan frakciokalkulon

En **nur** la nova Gleam-testdosiero, uzu la akceptitan Stage21 `dispatch_discovery_21` por g-listo; kalkulu ĉiujn fenestrojn per du nestitaj traversoj de la originalaj gapoj, kontrolu membrecon en la **originalaj, nekanonigitaj** A kaj B rekte, sendepende akumulu L/R/I/U/X/T. Ĉiu atendata frakcio por `U>0` estas trovata per **ekzakta, aparta serĉo de la plej malgranda pozitiva denominatoro** `q` en `1..U` por kiu `(I*q) mod U=0`, poste `p=(I*q)/U`; `U=0` atendu 1/1. Ne uzu produktan Eŭklidan `gcd`, Stage32..37, Stage36-frakciojn aŭ produktan kanonigilon en atendataj kalkuloj; kanonaj listoj laŭ malgrandaj eksplicitaj fiksaĵoj. En longaj kazoj `k<=12` tenas la sendependan denominator-serĉon malgranda. La produktan API oni vokas nur por kompari la rezulton kun ĉi tiuj sendependaj atendoj.

Planu **precize 12 unikajn publikajn `*_test`** funkciojn:
1. `ids=[]`, A/B=[], frakcio 1/1 kaj ĉiuj ses nombroj nul.
2. `ids=[]`, ne-malplenaj A/B, neuzata malvalida kunteksto: 1/1, kanonoj laŭ eksplicita fiksaĵo.
3. Unu gap ĉe ambaŭ fermitaj finpunktoj, A=B: 1/1.
4. Unu gap nur A, nur B, kaj ekstere de ambaŭ: 0/1 respektive 1/1.
5. Du gapoj kun L/R/I/U/X malkoincidaj, ekzakte 1/2 aŭ 2/3 laŭ origina rekta orakolo.
6. Kvar gapoj, parta intersekco, ne-triviala redukto (ekz. I/U=2/4 -> 1/2) trovita per origina enumerado.
7. A=[], B ne-malplena, poste inversaj flankoj; malsamaj idoj, nul-unio kaj pozitiva unio.
8. A=B kun duplikatoj, nestitaj kaj disaj bandoj: 1/1, neniu duobla kalkulo.
9. A/B interkovritaj, apudaj kaj kun inversaj intervaloj; ĉiuj tri kanonoj per eksplicitaj atendoj.
10. Ripetitaj bovlo-identigiloj sen deduplikigo; U/T kaj ĝusta frakcio laŭ indicoj.
11. InvalidBowlId, InvalidContext kaj erar-prioritato ankaŭ ĉe A/B=[]: ekzakte sama `Error` kiel Stage36.
12. BEAM-grandaj pozitivaj/negativaj bando-limoj, 12 gapoj, simetrio J(A,B)=J(B,A), neniuj false postulataj monotonecoj; `0<=p<=q` kaj J(A,A)=1/1.

## Sendependa matematika antaŭkontrolo (NE Gleam Native)

Python 3. Metodo A rekte enumeras ĉiujn indeksajn fenestrojn, komparas originalajn A/B-bandlistojn kaj kalkulas L/R/I/U/X. Frakcio laŭ serĉo de minimuma pozitiva denominatoro. Metodo B estas Python `fractions.Fraction(I,U)` (aŭ `Fraction(1,1)` ĉe U=0), kiu normigas sendepende. 13 propraj bandfamilioj, ĉiuj gaplistoj de longo 0..4 laŭ {42,43,963}: **20,449** fiksaĵoj. Aldone 5,000 determinismaj kazoj kun seed 20261121, 0..12 gapoj, ĝis 7 bandoj/flanko, ekstremaj finoj inkluzive de ±10^70. **25,449/25,449 kongruaj, 0 malkongruoj**, kun kontrolo de Stage36-araj invariantoj. Ĉi tio kontrolas nur abstraktan matematikan kontrakton, NE la Gleam-implementadon, CI, Native, aŭ diferencialan teston kontraŭ alia lingvo.

## Devigaj akceptopordegoj

A. **Kontrakta pordego.** Post ĉi tiu dokumenta preparo, la fina nova **exact-SHA HEAD** (ambaŭ rajtigitaj dokumentaj dosieroj, neniu kodo aŭ nova testo) devas ricevi Native `completed/success` **406/406** (Gleam 1.18.1, OTP28, read-only `gleam format --check src test`, fontintegreco), kun kontrolitaj run/job/log/artifact/head_sha/digest, KAJ Canonical Names Lock `completed/success` ĉe la sama SHA. `queued/in_progress` ne estas PASS aŭ bloko. Ne sendu duoblan CI. Stage36 restas lasta akceptita ĝis fina pordego.
B. **Nur post A:** aparta Stage37-koda komito, aldoni nur produktmodulon kaj **12 unikajn publikajn** sendepende oracle-kontrolitajn Gleam-testojn; **418/418 estas PROGNOZO**, ne mezurita. Nur exact-SHA Native 418/418 kaj Names completed/success akceptas kodan pordegon. Kompila/formatter fiasko NE signifas ke testoj pasis.
C. **Nur post B:** aparta dokumenta fermo kaj ĝia propra exact-SHA 418/418 Native + Names, poste aparta fina metadata-komito markanta `LAST_COMPLETED_STAGE=37` **nur** post aŭ kun ties propra same-SHA 418/418 Native + Names. Distingu kontraktan, kodan, dokumentan, kaj finan akcepton.
D. Malpermesite: `main`, merge, publikigo, Stage38 sen nova specifa amplekso, plena datkonverto, malfortigo de orakoloj/testoj, alilingvaj fixture-oj, kaj konfuzo inter antaŭkontrolo, static, CI kaj Native. Konservu Stage36 kaj antaŭajn pruvojn.


## Aparta dokumenta fermo post la akceptita Stage37-koda pordego (2026-11-21; propra CI ankoraŭ PENDING)

La kontrakta pordego A estas akceptita ĉe la fina kontrakta SHA `40fdca9ffe85b1bfd527e982d20f6e238b5c3b13`. Native [44939022405](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44939022405), job `136951902776`, `completed/success`: Gleam 1.18.1, Erlang/OTP 28, ERTS 16.4.0.7, read-only `gleam format --check src test` kaj fontintegreco PASS, **406 passed, no failures**. Artefakto [14722222971](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44939022405/artifacts/14722222971), SHA-256 `408ac0486bf7c67faead5d8c41dc5746b5bd250e304fd5108f488e6b660e28c3`. Canonical Names Lock [44939022492](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44939022492), job `136951902767`, `completed/success` ĉe la sama SHA. **Stage37 kontrakta pordego estas akceptita.**

La Stage37-koda amplekso estis efektivigita en nur la du planitaj novaj dosieroj: `src/pastafari/discovery_33_jaccard_bands.gleam` kaj `test/discovery_33_test.gleam`. Komparo de la kontrakta SHA `40fdca9ffe85b1bfd527e982d20f6e238b5c3b13` al la fina koda SHA `aa908287cd84a8569430b88da8aa73138ea2c451` montras ses antaŭenajn komitojn, neniun malantaŭan komiton, kaj **nur tiujn du aldonitajn dosierojn**; neniu alia dosiero ŝanĝiĝis. La testdosiero enhavas precize 12 unikajn publikajn `*_test`-funkciojn. Statika inspekto konfirmis Stage21-indekso-fenestra enumerado kaj original-banda membreco en la sendependa orakolo, minimum-pozitiva-denominatora serĉo (sen produkta GCD en la orakolo), unu Stage32-voko en produktkodo, kaj neniun glitkomon aŭ produktan dependecon de Stage21/reference.

La unua formatter-korektita koda SHA `0064e2c56b8c04f75b7b5668cd56e8664087a8bf` havis Native [44953887264](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44953887264), job `136997601248`, `completed/failure`: format-kontrolo pasis, sed kompilado haltis ĉe `Private type used in public interface` en `test/discovery_33_test.gleam:518` (`DirectCounts`); **la testoj ne ruliĝis**. Artefakto `14726432956`, SHA-256 `9e3257956354378bcde9537a934ec6ae0b5715ef7b4bebca4f48c9aa3d87cfa3`. La korekto ĉe `aa908287cd84a8569430b88da8aa73138ea2c451` konservis la atendatan rezulton loka kaj aldonis aserton `total_windows=10`, tiel ke la publika testfunkcio redonas `Nil`; neniu produktkodo aŭ orakolo ŝanĝiĝis.

La fina koda SHA `aa908287cd84a8569430b88da8aa73138ea2c451` pasis Native [44958275007](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958275007), job `137011141811`, `completed/success`: Gleam 1.18.1, OTP 28, ERTS 16.4.0.7, read-only formatter kaj fontintegreco PASS, **418 passed, no failures**. Artefakto [14728272330](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958275007/artifacts/14728272330), SHA-256 `01691979040e00e828e10fe5eb2df72f747fb720532dcbb1d47f5e6e6c515a7e`. Canonical Names Lock [44958274996](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44958274996), job `137011141980`, `completed/success` ĉe la **sama koda SHA**. **Stage37 koda pordego B estas akceptita.**

La nuna stato restas `LAST_COMPLETED_STAGE=36`. La tuta Stage37 ankoraŭ NE estas akceptita: ĉi tiu aparta dokumenta fermo devas ricevi sian propran exact-SHA Native **418/418** (formatter kaj fontintegreco) kaj Canonical Names Lock sukceson; poste aparta fina metadata-komito povas marki `LAST_COMPLETED_STAGE=37`, sed ĝia propra exact-SHA Native **418/418** kaj Names Lock ankaŭ devas sukcesi. Neniu Stage38, plena datkonverto, `main`, merge aŭ publikigo.
