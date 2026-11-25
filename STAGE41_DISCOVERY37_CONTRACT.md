# Stadio 41 — DISCOVERY 37: signita diferenco de direktaj kovroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Akceptita baza HEAD: 514599e955a18effb097c938d06050df3e54c02a; LAST_COMPLETED_STAGE=40.
Rajtigo: la daŭra uzanta regulo de 2026-11-22, issue #36, komento 7085562104: neniu aparta rajtigo necesas por transiri inter stadioj en ĉi tiu sama ekzistanta branĉprogramo. Tio ne rajtigas main, merge, protektitajn branĉojn, publikigon, fremdan realigon, malfortigon de orakoloj aŭ plenan datkonverton. Historiaj kontraktoj restas senŝanĝaj.

## Akceptita bazo — Stage40

La nuna viva branĉo kaj la fina akcepta SHA estas identaj: 514599e955a18effb097c938d06050df3e54c02a.
Native run 45671995673, job 139409458427: completed/success; HEAD kontrolita; Gleam 1.18.1, OTP 28, ERTS 16.4.0.8; gleam format --check src test kaj fontintegreco PASS; 454 pasis, neniu fiasko.
Artifact 15049273909: ZIP elŝutita; verification.log enhavas la saman HEAD kaj 454/454; ZIP SHA256 39ef8637e973901367874fd2cd27d17c613a46bb81649c465a1450764d4b2a0f, identa al GitHub digest.
Canonical Names Lock run 45671995659, job 139409457792: completed/success, sama checkout SHA.
Ĉi tio estas fina Stage40-akcepto 40/55; neniu rerulo de jam akceptita SHA.

## Kontrakto

Enigoj: bootstrap.MonsterContext; ordigita List(Int) de eksplicitaj bovlo-ID-oj; du originalaj List(discovery_27_sum_bands.SumBand), A kaj B. Ripetitaj ID-oj restas apartaj laŭ indekso. Inversaj intervaloj estas malplenaj. Ĉiuj antaŭaj validigaj reguloj kaj erarprioritato estas tiuj de Stage36.

Stage36 liveras la rektajn kovrojn:
- L = nombro de indeksaj fenestroj en A;
- R = nombro de indeksaj fenestroj en B;
- I = nombro de fenestroj en ambaŭ;
- CL = I/L se L>0, alie 1/1;
- CR = I/R se R>0, alie 1/1.

La nova diagnozo estas la signita diferenco:
S = CL - CR.

Por L>0 kaj R>0:
S = I/L - I/R = I(R-L)/(LR).

Nul-kazoj laŭ la hereda Stage36-vakua konvencio:
- L=0 kaj R=0: CL=CR=1/1, do S=0/1.
- L=0 kaj R>0: CL=1/1, CR=0/1, do S=+1/1.
- L>0 kaj R=0: CL=0/1, CR=1/1, do S=-1/1.

La publika rezulto estas unu reduktita signita frakcio p/q kun q>0, gcd(abs(p),q)=1 kaj -q<=p<=q. La numeratoro povas esti negativa; la denominatoro ĉiam estas pozitiva. Neniu glitkomo.

Semantiko:
- S>0 signifas, ke la parto de A kovrita de B estas pli granda ol la parto de B kovrita de A.
- S<0 signifas la inversan direkton.
- S=0 kiam CL=CR; ĉe L,R>0 tio okazas se I=0 aŭ L=R.
- Interŝanĝi A kaj B devas negi S precize.
- A=B devas doni S=0.
- Ĉe L,R>0 kaj I>0, sign(S)=sign(R-L): pozitiva kiam L<R, negativa kiam L>R.
- La limo |S|<=1 sekvas el CL,CR en [0,1].

Abstraktaj atestantoj, ne asertoj pri apartaj realaj bovlo-ID-oj:
- L=5,R=3,I=2: S=2/5-2/3=-4/15.
- L=3,R=5,I=2: S=2/3-2/5=+4/15.
- L=3,R=7,I=3: S=1-3/7=+4/7; interŝanĝo donas -4/7.

## API kaj produkta disciplino

Nova produkto: src/pastafari/discovery_37_signed_coverage_difference.gleam.
Nova testdosiero: test/discovery_37_test.gleam.

Publika tipo:
SignedDirectionalCoverageDifference(
  previous: discovery_36_directional_coverage.DirectionalWindowCoverage,
  signed_difference_numerator: Int,
  signed_difference_denominator: Int,
)

Publika funkcio:
dispatch_discovery_37(
  context: bootstrap.MonsterContext,
  requested_bowl_ids: List(Int),
  left_bands: List(discovery_27_sum_bands.SumBand),
  right_bands: List(discovery_27_sum_bands.SumBand),
) -> Result(SignedDirectionalCoverageDifference, discovery_19_interval_value.Discovery19Error)

La nova produktmodulo devas:
1. Voki precize unufoje discovery_36_directional_coverage.dispatch_discovery_36 kun la samaj argumentoj, ankaŭ ĉe malplenaj enigoj.
2. Repropagi ĉiun Error senŝanĝe; ne ŝanĝi erarprioritaton.
3. Sur Ok(previous), konservi previous sen modifo.
4. Kontroli ke la kvar hereditaj kovrokampoj havas denominatorojn >0, numeratorojn en [0,denominatoro], kaj reduktitajn frakciojn; kontroli ankaŭ ilian kongruon kun la heredaj L,R,I kaj vakua konvencio.
5. Kalkuli n0 = left_numerator*right_denominator - right_numerator*left_denominator kaj d0 = left_denominator*right_denominator. d0 devas esti pozitiva.
6. Redukti per loka Eŭklida gcd(abs(n0),d0); gcd(0,d0)=d0. Ne uzi absolutan valoron por forigi la signon de la numeratoro.
7. Kontroli q>0, gcd(abs(p),q)=1, -q<=p<=q kaj p*d0=n0*q. Ĉe malkongruo redoni InvalidStream.
8. Ne voki Stage21, ne enumeri fenestrojn, ne kanonigi aŭ kunfandi bandojn, ne aldoni dependecojn kaj ne importi alian lingvon.

Kosto super Stage36: O(log(max(1,d0))) Eŭklidaj paŝoj kaj O(1) pliaj entjeraj valoroj; neniu konstanta bitkosta aserto por grandaj entjeroj. Ĉiu kalkulo estas preciza entjera aritmetiko.

## Sendependa test-orakolo kaj precize 12 testoj

Nur en test/discovery_37_test.gleam:
- Por validaj ID-oj, ricevi la gapojn per Stage21 kaj enumeri rekte ĉiujn indeksajn fenestrojn (a,b), 0<=a<b<=k.
- Kalkuli sumojn kaj membrecon kontraŭ la ORIGINALAJ A kaj B; ne uzi Stage36/37 nombrilojn por konstrui la atendatan rezulton.
- Rekalkuli L,R,I per rektaj buleaj membrecoj.
- Trovi CL kaj CR per serĉo de la plej malgranda pozitiva denominatoro, ne per gcd.
- Por L,R>0, uzi n0=I(R-L), d0=LR kaj serĉi la plej malgrandan q>=1 por kiu (n0*q) mod d0=0; p=n0*q/d0. Nul-kazoj estas eksplicitaj. La orakolo ne uzas produktan gcd.
- Kontroli ankaŭ la heredajn Stage36 kampojn per la rekta fenestra orakolo kaj eksplicitaj fiksaĵoj, ne nur per metamorfozoj.

Precize 12 unikaj publikaj *_test:
1. discovery_37_both_empty_test — L=R=I=0; S=0/1.
2. discovery_37_left_empty_test — L=0<R; S=+1/1.
3. discovery_37_right_empty_test — R=0<L; S=-1/1.
4. discovery_37_equal_cardinality_disjoint_test — L=R>0,I=0; S=0/1.
5. discovery_37_equal_cardinality_overlap_test — L=R>0,I>0; S=0/1.
6. discovery_37_left_subset_test — A estas strikta subaro; S=+4/7 por fiksa atestanto.
7. discovery_37_right_subset_test — inversa kazo; S=-4/7.
8. discovery_37_partial_overlap_negative_test — L=5,R=3,I=2; S=-4/15.
9. discovery_37_partial_overlap_positive_test — interŝanĝita atestanto; S=+4/15.
10. discovery_37_index_multiplicity_and_duplicate_bands_test — ripetitaj ID-oj, duplikataj/nestitaj bandoj, neniu deduplikado de indeksaj fenestroj aŭ duobla kalkulo de intervaloj.
11. discovery_37_wide_inverted_and_error_priority_test — limoj ±10^70, inversaj bandoj, InvalidBowlId kaj InvalidContext kun ĝusta prioritato.
12. discovery_37_matrix_test — determinisma matrico k<=12; rekta orakolo, interŝanĝa negado, identeco, signaj kazoj, intervalo kaj reduktita denominatoro.

Neniu nova produkta modulo aŭ testdosiero estas aldonata en la kontrakta pordego.

## Ekstera matematika antaŭkontrolo — ne Native

Python entjera aritmetiko, sendependa de Gleam kaj de la produkta modulo: por ĉiu k=0..12, T=k(k+1)/2, ĉiuj realigeblaj kardinalecaj statoj L,R,I kun 0<=L,R<=T, 0<=I<=min(L,R), L+R-I<=T. Entute 202735 statoj.
Por ĉiu stato, la signita diferenco per Eŭklida redukto estis komparita kun sendependa serĉo de la plej malgranda pozitiva denominatoro; 202735/202735 kongruis, neniu malkongruo. 94467 pozitivaj, 94467 negativaj, 13801 nulaj; plej granda reduktita denominatoro 5852. Kontrolitaj ankaŭ q>0, gcd(abs(p),q)=1 kaj |p|<=q. Tio estas nur antaŭkontrolo de la matematika kontrakto, NE Gleam, CI, Native aŭ differential PASS.

## Devigaj SHA-pordegoj

A. Kontrakto: nur ĉi tiu kontrakto kaj minimumaj ŝanĝoj en DEVELOPMENT_STAGE.md. Akcepto post sama-SHA Native job/log completed/success kun 454/454, gleam format --check src test read-only PASS, fontintegreco PASS, Gleam 1.18.1/OTP28, kaj Canonical Names Lock completed/success. Kontrolu head_sha, artifact, ZIP digest kaj verification.log. Neniu mana dispatch duobla.
B. Nur post A: unu nova modulo kaj precize 12 unikaj publikaj testoj. 466/466 estas antaŭdiro, ne rezulto. Akcepto post sama-SHA Native 466/466 kaj Names Lock, kun job/log/artifact/digest.
C. Nur post B: dokumenta fermo kaj propra sama-SHA Native 466/466 + Names.
D. Nur post C: fina metadata-markilo kaj propra sama-SHA Native 466/466 + Names. Nur tiam LAST_COMPLETED_STAGE=41.
Ĝis D, LAST_COMPLETED_STAGE=40. queued/in_progress ne estas PASS nek bloko; ne lanĉi rerun duoblan. Neniu Stage42, main, merge, publikigo, plena datkonverto aŭ ŝanĝo de politiko.
