# Stadio 43 — DISCOVERY 39: relativa signita malsimetrio de direktaj kovroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Akceptita baza HEAD: 74be256d54a4eba7fd6c367dcd33829c22a3a3e5; LAST_COMPLETED_STAGE=42.
Rajtigo: la daŭra uzanta regulo de 2026-11-22, issue #36, komento 7085562104: neniu aparta rajtigo necesas por transiri inter stadioj en ĉi tiu sama ekzistanta branĉprogramo. Tio ne rajtigas main, merge, protektitajn branĉojn, publikigon, malfortigon de orakoloj, translingvajn fiksaĵojn aŭ plenan datkonverton. Historiaj kontraktoj restas senŝanĝaj.

## Akceptita bazo — Stage42

Stage42 / DISCOVERY38 estas akceptita 42/55 ĉe la fina markilo SHA 74be256d54a4eba7fd6c367dcd33829c22a3a3e5.
- Native run 45693484956, job 139484724124: completed/success, 478/478, Gleam1.18.1, OTP28 / ERTS16.4.0.8, read-only format kaj fontintegreco PASS.
- Artifact 15059907058: elŝutita ZIP SHA-256 e7695fef6573b8353063a06739eee7c186614e8dab172a50fa3998425b484490, egala al GitHub digest; verification.log enhavas la saman HEAD kaj 478/478.
- Canonical Names Lock run 45693484898, job 139484725841: completed/success, sama checkout SHA; log konfirmas la saman HEAD kaj sukcesan CANONICAL_NAMES_LOCK kontrolon.
- Branĉa HEAD estis kontrolita egala al la markilo SHA. Tio estas fina Stage42-akcepto; neniu rerulo de la akceptita SHA.

## Kontrakto

Enigoj: bootstrap.MonsterContext; ordigita List(Int) de eksplicitaj bovlo-ID-oj; du originalaj List(discovery_27_sum_bands.SumBand), A kaj B. Ripetitaj ID-oj restas apartaj laŭ indekso. Inversaj bandoj estas malplenaj. Ĉiuj antaŭaj validigaj reguloj kaj erarprioritato estas tiuj de Stage38.

Stage38 liveras la simetrian mezan kovron:
M = (CL + CR)/2.
Stage37 konservas la signitan diferencon:
S = CL - CR.
La nova mezuro estas la relativa signita malsimetrio:
A = S/M, kiam M>0.
Kiam M=0, ambaŭ direktaj kovroj estas nulaj; laŭ eksplicita konvencio A=0/1.

Ekvivalenta formulo:
A = 2(CL-CR)/(CL+CR), kiam CL+CR>0.

Por L>0, R>0 kaj I>0:
A = 2(R-L)/(L+R).
La intersekca kvanto I nuligas sin nur en ĉi tiu kazo; la mezuro do kaptas relativan diferencon de la du kovraj kardinalecoj kondiĉe ke ekzistas almenaŭ unu komuna fenestro.

Vakua kaj nula konvencio:
- L=0 kaj R=0: CL=CR=1, M=1, S=0, do A=0/1.
- L=0 kaj R>0: CL=1, CR=0, M=1/2, S=+1, do A=+2/1.
- L>0 kaj R=0: CL=0, CR=1, M=1/2, S=-1, do A=-2/1.
- L>0, R>0, I=0: CL=CR=0, M=0, S=0, do A=0/1.
- L>0, R>0, I>0: A=2(R-L)/(L+R), reduktita.

La publika rezulto estas reduktita signita frakcio p/q kun q>0, gcd(abs(p),q)=1 kaj -2q<=p<=2q. Neniu glitkomo.

Semantiko kaj invariantoj:
- A mezuras la signitan diferencon rilate al la meza kovro; ĝi estas sendimensia kaj ne dependas de komuna multipliko de L kaj R.
- A>0 signifas ke la kovro de A per B estas pli granda ol la kovro de B per A; A<0 signifas la inversan direkton.
- Interŝanĝi A kaj B devas negi A precize.
- A=0 kiam la du direktaj kovroj egalas; tio okazas ĉe L=R, ĉe neniu intersekco, kaj ĉe ambaŭ malplenaj.
- A estas en [-2,2]. La ekstremaj valoroj ±2 okazas kiam ĝuste unu flanko estas malplena.
- A=B donas A=0.
- M kaj A kune rekonstrue donas ambaŭ direktajn kovrojn:
  CL = M(1 + A/2); CR = M(1 - A/2).
  La identecoj estas kontrolataj per krucomultipliko, inkluzive de M=0.

Abstraktaj atestantoj, ne asertoj pri apartaj realaj bovlo-ID-oj:
- L=3,R=7,I=3: A=2(7-3)/(3+7)=4/5.
- L=5,R=3,I=2: A=2(3-5)/(5+3)=-1/2.
- L=7,R=5,I=3: A=2(5-7)/(7+5)=-1/3.

## API kaj produkta disciplino

Nova produkto: src/pastafari/discovery_39_relative_directional_asymmetry.gleam.
Nova testdosiero: test/discovery_39_test.gleam.

Publika tipo:
RelativeDirectionalCoverageAsymmetry(
  previous: discovery_38_mean_directional_coverage.MeanDirectionalCoverage,
  asymmetry_numerator: Int,
  asymmetry_denominator: Int,
)

Publika funkcio:
dispatch_discovery_39(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(RelativeDirectionalCoverageAsymmetry, discovery_19_interval_value.Discovery19Error)

La nova produktmodulo devas:
1. Voki precize unufoje discovery_38_mean_directional_coverage.dispatch_discovery_38 kun la samaj argumentoj, ankaŭ ĉe malplenaj enigoj.
2. Repropagi ĉiun Error senŝanĝe; ne ŝanĝi validigon aŭ erarprioritaton.
3. Sur Ok(previous), konservi previous sen modifo.
4. Kontroli la hereditajn Stage36 kovrojn, Stage37 signitan diferencon kaj Stage38 mezan kovron: pozitivaj denominatoroj, redukto, intervaloj kaj kongruo kun L,R,I kaj la vakua konvencio.
5. Se M=0, kontroli S=0 kaj redoni A=0/1.
6. Se M>0, kalkuli n0 = S_numerator*M_denominator kaj d0 = S_denominator*M_numerator. d0 devas esti pozitiva.
7. Redukti per loka Eŭklida gcd(abs(n0),d0); gcd(0,d0)=d0. Konservi la signon de la numeratoro.
8. Kontroli q>0, gcd(abs(p),q)=1, -2q<=p<=2q kaj p*d0=n0*q.
9. Kontroli la nombrilan formulon: ĉe L=R=0, A=0/1; ĉe L=0<R, A=+2/1; ĉe R=0<L, A=-2/1; ĉe L,R>0 kaj I=0, A=0/1; ĉe L,R>0 kaj I>0, p*(L+R)=2*(R-L)*q. Malkongruo redonas InvalidStream.
10. Kontroli la rekonstruajn identecojn CL=M(1+A/2) kaj CR=M(1-A/2) per krucomultipliko kontraŭ la heredaj Stage36 kovraj frakcioj.
11. Ne voki Stage21, ne enumeri fenestrojn, ne kanonigi aŭ kunfandi bandojn, ne aldoni dependecojn kaj ne importi alian lingvon.

Kosto super Stage38: O(log(max(1,d0))) Eŭklidaj paŝoj kaj O(1) pliaj entjeraj valoroj; neniu konstanta bitkosta aserto por grandaj entjeroj. Ĉiuj kalkuloj estas preciza entjera aritmetiko.

## Sendependa test-orakolo kaj precize 12 testoj

Nur en test/discovery_39_test.gleam:
- Por validaj ID-oj, ricevi gapojn per Stage21 kaj rekte enumeri ĉiujn indeksajn fenestrojn (a,b), 0<=a<b<=k.
- Kalkuli sumojn kaj membrecon kontraŭ ORIGINALAJ A kaj B; ne uzi Stage36/37/38/39 nombrilojn por konstrui atendatajn rezultojn.
- Rekalkuli L,R,I per rektaj buleaj membrecoj.
- Rekalkuli CL, CR, S kaj M per sendependaj minimum-denominatoraj serĉoj.
- Rekalkuli A: eksplicitaj nul-kazoj; por L,R>0 kaj I>0 uzi 2(R-L)/(L+R), kun minimum-denominatora serĉo; ne uzi produktan gcd.
- Kontroli hereditajn Stage36/37/38 kampojn kontraŭ la rekta orakolo.
- Kontroli CL=M(1+A/2) kaj CR=M(1-A/2) per krucomultipliko.

Precize 12 unikaj publikaj *_test:
1. discovery_39_both_empty_test — L=R=I=0; A=0/1.
2. discovery_39_left_empty_test — L=0<R; A=+2/1.
3. discovery_39_right_empty_test — R=0<L; A=-2/1.
4. discovery_39_disjoint_nonempty_test — L,R>0,I=0; A=0/1.
5. discovery_39_equal_cardinality_overlap_test — L=R=I>0; A=0/1.
6. discovery_39_left_subset_test — L=3,R=7,I=3; A=+4/5.
7. discovery_39_right_subset_test — inversa kazo; A=-4/5.
8. discovery_39_partial_overlap_negative_test — L=5,R=3,I=2; A=-1/2.
9. discovery_39_partial_overlap_positive_test — interŝanĝita atestanto; A=+1/2.
10. discovery_39_index_multiplicity_and_duplicate_bands_test — ripetitaj ID-oj kaj duplikataj bandoj; L=7,R=5,I=3; A=-1/3.
11. discovery_39_wide_inverted_and_error_priority_test — limoj ±10^70, inversaj bandoj, InvalidBowlId kaj InvalidContext kun ĝusta prioritato.
12. discovery_39_matrix_test — determinisma matrico k<=12; rekta orakolo, interŝanĝa negado, identeco, rekonstrueco de CL/CR, intervalo kaj reduktita denominatoro.

Neniu nova produkta modulo aŭ testdosiero estas aldonata en la kontrakta pordego.

## Ekstera matematika antaŭkontrolo — ne Native

Python-entjera aritmetiko, sendependa de Gleam kaj de la produkta modulo: por ĉiu k=0..12, T=k(k+1)/2, ĉiuj realigeblaj kardinalecaj statoj L,R,I kun 0<=L,R<=T, 0<=I<=min(L,R), L+R-I<=T. Entute 202735 statoj.
Por ĉiu stato, A per Eŭklida redukto estis komparita kun sendependa serĉo de la plej malgranda pozitiva denominatoro; samtempe kontrolitaj la nul-kazoj, intervalo [-2,2] kaj rekonstruo de CL/CR el M kaj A. Rezulto: 202735/202735 kongruis, neniu malkongruo; maksimuma reduktita denominatoro 155. Tio estas nur matematika antaŭkontrolo, NE Gleam, CI, Native aŭ differential PASS.

## Devigaj SHA-pordegoj

A. Kontrakto: nur ĉi tiu kontrakto kaj minimumaj ŝanĝoj en DEVELOPMENT_STAGE.md. Akcepto post sama-SHA Native 478/478, read-only format/source integrity PASS, Gleam 1.18.1/OTP28, Canonical Names Lock completed/success, job/log/artifact/head_sha/digest kaj verification.log.
B. Nur post A: unu nova produkta modulo kaj precize 12 unikaj publikaj testoj. 490/490 estas antaŭdiro, ne rezulto. Akcepto post propra sama-SHA Native 490/490 + Names, kun job/log/artifact/digest.
C. Nur post B: dokumenta fermo kun propra sama-SHA Native 490/490 + Names.
D. Nur post C: fina metadata-markilo kun propra sama-SHA Native 490/490 + Names. Nur tiam LAST_COMPLETED_STAGE=43.
Ĝis D, LAST_COMPLETED_STAGE=42. queued/in_progress ne estas PASS nek bloko; ne lanĉi rerun duoblan. Neniu Stage44, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
