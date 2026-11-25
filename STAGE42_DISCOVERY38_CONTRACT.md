# Stadio 42 — DISCOVERY 38: simetria meza de direktaj kovroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Akceptita baza HEAD: 9fbcc96c6f35cda9aaabb9f9f0eb1b7519f7f0e5; LAST_COMPLETED_STAGE=41.
Rajtigo: la daŭra uzanta regulo de 2026-11-22, issue #36, komento 7085562104: neniu aparta rajtigo necesas por transiri inter stadioj en ĉi tiu sama ekzistanta branĉprogramo. Tio ne rajtigas main, merge, protektitajn branĉojn, publikigon, malfortigon de orakoloj, translingvajn fiksaĵojn aŭ plenan datkonverton. Historiaj kontraktoj restas senŝanĝaj.

## Akceptita bazo — Stage41

Stage41 / DISCOVERY37 estas akceptita 41/55 ĉe la sama fina markilo SHA 9fbcc96c6f35cda9aaabb9f9f0eb1b7519f7f0e5.
- Native run 45690395716, job 139474000233: completed/success, 466/466, Gleam 1.18.1, OTP28 / ERTS16.4.0.8, read-only format kaj fontintegreco PASS.
- Artifact 15057704112: elŝutita ZIP SHA-256 0351bed85d68453cfed4e7c3a133d952ea6d741d79c6c06eb04c7a953e625d02, egala al GitHub digest; verification.log enhavas la saman HEAD kaj 466 passed.
- Canonical Names Lock run 45690395728, job 139474000555: completed/success, sama checkout SHA; log konfirmas la saman HEAD kaj sukcesan kontrolon de CANONICAL_NAMES_LOCK.sha256.
- Branĉa HEAD estis kontrolita egala al la markilo SHA. Tio estas fina Stage41-akcepto; neniu rerulo de la akceptita SHA.

## Kontrakto

Enigoj: bootstrap.MonsterContext; ordigita List(Int) de eksplicitaj bovlo-ID-oj; du originalaj List(discovery_27_sum_bands.SumBand), A kaj B. Ripetitaj ID-oj restas apartaj laŭ indekso. Inversaj bandoj estas malplenaj. Ĉiuj antaŭaj validigaj reguloj kaj erarprioritato estas tiuj de Stage37.

Stage37 heredas de Stage36 la rektajn kovrojn:
- L = nombro de indeksaj fenestroj en A;
- R = nombro de indeksaj fenestroj en B;
- I = nombro de fenestroj en ambaŭ;
- CL = I/L se L>0, alie 1/1;
- CR = I/R se R>0, alie 1/1.
Stage41 aldonas S = CL - CR, reduktitan signitan frakcion.

La nova simetria mezumo estas:
M = (CL + CR) / 2.

Por L>0 kaj R>0:
M = (I/L + I/R)/2 = I(L+R)/(2LR).

Vakua konvencio heredita de Stage36:
- L=0 kaj R=0: CL=CR=1/1, do M=1/1.
- L=0 kaj R>0: CL=1/1, CR=0/1, do M=1/2.
- L>0 kaj R=0: CL=0/1, CR=1/1, do M=1/2.

La publika rezulto estas reduktita frakcio p/q kun q>0, gcd(p,q)=1 kaj 0<=p<=q. Neniu glitkomo.

Semantiko kaj invariantoj:
- M estas la aritmetika mezumo de la du kovroj, do la kovro atendata kiam oni elektas unu el la du direktoj kun probablo 1/2.
- M estas simetria: interŝanĝi A kaj B ne ŝanĝas M.
- M=1 kiam CL=CR=1; M=0 kiam ambaŭ kovroj estas nulaj.
- Ambaŭ malplenaj donas M=1; ĝuste unu malplena flanko donas M=1/2 laŭ la eksplicita vakua konvencio.
- 0<=M<=1.
- Kune kun Stage41 S, M rekonstrue donas ambaŭ direktajn kovrojn:
  CL = M + S/2; CR = M - S/2.
  La identecoj estas kontrolataj per krucomultipliko, ne per glitkomo.
- Interŝanĝo de A kaj B konservas M kaj negas S.
- A=B donas M=1 kaj S=0.

Abstraktaj atestantoj, ne asertoj pri apartaj realaj bovlo-ID-oj:
- L=3,R=7,I=3: CL=1, CR=3/7, M=5/7, S=+4/7.
- L=5,R=3,I=2: CL=2/5, CR=2/3, M=8/15, S=-4/15.
- L=7,R=5,I=3: CL=3/7, CR=3/5, M=18/35, S=-6/35.

## API kaj produkta disciplino

Nova produkto: src/pastafari/discovery_38_mean_directional_coverage.gleam.
Nova testdosiero: test/discovery_38_test.gleam.

Publika tipo:
MeanDirectionalCoverage(
  previous: discovery_37_signed_coverage_difference.SignedDirectionalCoverageDifference,
  mean_numerator: Int,
  mean_denominator: Int,
)

Publika funkcio:
dispatch_discovery_38(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(MeanDirectionalCoverage, discovery_19_interval_value.Discovery19Error)

La nova produktmodulo devas:
1. Voki precize unufoje discovery_37_signed_coverage_difference.dispatch_discovery_37 kun la samaj argumentoj, ankaŭ ĉe malplenaj enigoj.
2. Repropagi ĉiun Error senŝanĝe; ne ŝanĝi validigon aŭ erarprioritaton.
3. Sur Ok(previous), konservi previous sen modifo.
4. Kontroli la du hereditajn Stage36-kovrojn: denominatoroj >0; numeratoroj en [0,denominatoro]; reduktitaj frakcioj; kongruo kun L,R,I kaj la vakua konvencio.
5. Kontroli la hereditan Stage41 signitan diferencon: q>0; gcd(abs(s),q)=1; -q<=s<=q; krucomultipliko kontraŭ la du hereditaj kovroj kaj kontraŭ I(R-L)/(LR), inkluzive de la tri nul-kazoj.
6. Kalkuli n0 = left_numerator*right_denominator + right_numerator*left_denominator kaj d0 = 2*left_denominator*right_denominator. d0 devas esti pozitiva.
7. Redukti per loka Eŭklida gcd(n0,d0); gcd(0,d0)=d0.
8. Kontroli q>0, gcd(p,q)=1, 0<=p<=q kaj p*d0=n0*q.
9. Kontroli la nombrilan formulon: ĉe L,R>0, p*(2LR)=I(L+R)*q; ĉe L=R=0, p/q=1/1; ĉe ĝuste unu nula flanko, p/q=1/2. Malkongruo redonas InvalidStream.
10. Ne voki Stage21, ne enumeri fenestrojn, ne kanonigi aŭ kunfandi bandojn, ne aldoni dependecojn kaj ne importi alian lingvon.

Kosto super Stage37: O(log(max(1,d0))) Eŭklidaj paŝoj kaj O(1) pliaj entjeraj valoroj; neniu konstanta bitkosta aserto por grandaj entjeroj. Ĉiuj kalkuloj estas preciza entjera aritmetiko.

## Sendependa test-orakolo kaj precize 12 testoj

Nur en test/discovery_38_test.gleam:
- Por validaj ID-oj, ricevi gapojn per Stage21 kaj rekte enumeri ĉiujn indeksajn fenestrojn (a,b), 0<=a<b<=k.
- Kalkuli sumojn kaj membrecon kontraŭ ORIGINALAJ A kaj B; ne uzi Stage36/37/38 nombrilojn por konstrui atendatajn rezultojn.
- Rekalkuli L,R,I per rektaj buleaj membrecoj.
- Trovi CL kaj CR per serĉo de la plej malgranda pozitiva denominatoro, ne per gcd.
- Rekalkuli S per rekta formulo kaj minimum-denominatora serĉo; rekalkuli M per la simila sendependa serĉo. Nul-kazoj eksplicitaj.
- Kontroli heredajn Stage36 kaj Stage37 kampojn kontraŭ la rekta orakolo.
- Kontroli CL=M+S/2 kaj CR=M-S/2 per krucomultipliko; ne uzi produktajn frakciojn kiel atendatajn valorojn.

Precize 12 unikaj publikaj *_test:
1. discovery_38_both_empty_test — L=R=I=0; M=1/1, S=0/1.
2. discovery_38_left_empty_test — L=0<R; M=1/2, S=+1/1.
3. discovery_38_right_empty_test — R=0<L; M=1/2, S=-1/1.
4. discovery_38_equal_cardinality_disjoint_test — L=R>0,I=0; M=0/1, S=0/1.
5. discovery_38_equal_cardinality_overlap_test — L=R=I>0; M=1/1, S=0/1.
6. discovery_38_left_subset_test — L=3,R=7,I=3; M=5/7, S=+4/7.
7. discovery_38_right_subset_test — inversa kazo; M=5/7, S=-4/7.
8. discovery_38_partial_overlap_negative_test — L=5,R=3,I=2; M=8/15, S=-4/15.
9. discovery_38_partial_overlap_positive_test — interŝanĝita atestanto; M=8/15, S=+4/15.
10. discovery_38_index_multiplicity_and_duplicate_bands_test — ripetitaj ID-oj kaj duplikataj bandoj; L=7,R=5,I=3; M=18/35, S=-6/35.
11. discovery_38_wide_inverted_and_error_priority_test — limoj ±10^70, inversaj bandoj, InvalidBowlId kaj InvalidContext kun ĝusta prioritato.
12. discovery_38_matrix_test — determinisma matrico k<=12; rekta orakolo, interŝanĝa simetrio, identeco, rekonstruo de CL/CR, intervalo kaj reduktita denominatoro.

Neniu nova produkta modulo aŭ testdosiero estas aldonata en la kontrakta pordego.

## Ekstera matematika antaŭkontrolo — ne Native

Python-entjera aritmetiko, sendependa de Gleam kaj de la produkta modulo: por ĉiu k=0..12, T=k(k+1)/2, ĉiuj realigeblaj kardinalecaj statoj L,R,I kun 0<=L,R<=T, 0<=I<=min(L,R), L+R-I<=T. Entute 202735 statoj.
Por ĉiu stato, M per Eŭklida redukto estis komparita kun sendependa serĉo de la plej malgranda pozitiva denominatoro; samtempe kontrolitaj M en [0,1], la tri nul-kazoj kaj rekonstruo de CL/CR el M kaj S. Rezulto: 202735/202735 kongruis, neniu malkongruo; plej granda reduktita denominatoro 11704. Tio estas nur matematika antaŭkontrolo, NE Gleam, CI, Native aŭ differential PASS.

## Devigaj SHA-pordegoj

A. Kontrakto: nur ĉi tiu kontrakto kaj minimumaj ŝanĝoj en DEVELOPMENT_STAGE.md. Akcepto post sama-SHA Native 466/466, read-only format/source integrity PASS, Gleam 1.18.1/OTP28, Canonical Names Lock completed/success, job/log/artifact/head_sha/digest kaj verification.log.
B. Nur post A: unu nova produkta modulo kaj precize 12 unikaj publikaj testoj. 478/478 estas antaŭdiro, ne rezulto. Akcepto post propra sama-SHA Native 478/478 + Names, kun job/log/artifact/digest.
C. Nur post B: dokumenta fermo kun propra sama-SHA Native 478/478 + Names.
D. Nur post C: fina metadata-markilo kun propra sama-SHA Native 478/478 + Names. Nur tiam LAST_COMPLETED_STAGE=42.
Ĝis D, LAST_COMPLETED_STAGE=41. queued/in_progress ne estas PASS nek bloko; ne lanĉi rerun duoblan. Neniu Stage43, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
