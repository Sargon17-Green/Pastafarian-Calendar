# Stadio 46 — DISCOVERY 42: miksita direkta kovro

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Baza akceptita HEAD: 00a0aa356d9a7929668c1b5cb0f84feb781149cb; LAST_COMPLETED_STAGE=45.
Rajtigo: Issue #36, komento 7085562104 (2026-11-22), daŭra rajtigo ene de la ekzistanta branĉprogramo.

## Celo kaj kontrakto
Stage45 disponigas Q=(1-CL)(1-CR); Stage44 J=CL*CR; CL=I/L kaj CR=I/R kun vakua kovro 1 ĉe nula fonto. Stage46 aldonas la simetrian miksitan mezuron X=CL*(1-CR)+(1-CL)*CR. Ĝi ne estas probablo-aserto; ĝi kompletigas la dispartigon J+Q+X=1. Por pozitivaj L,R, X=I*(L+R-2*I)/(L*R). Ambaŭ malplenaj: 0/1. Precize unu malplena: 1/1. Disaj ne-malplenaj aŭ egalaj aroj: 0/1. Subaro (3,7,3): 4/7; parta (5,3,2): 8/15; nesimetria (7,5,3): 18/35. X=0 iff ambaŭ kovroj estas 0 aŭ ambaŭ 1; X=1 iff precize unu aro malplena. X=2*M-2*J, M=(CL+CR)/2. Reduktita p/q, q>0, 0<=p<=q; simetrio, neniu glitkomo.

## Produkta API
Nova modulo src/pastafari/discovery_42_mixed_directional_coverage.gleam kaj test/discovery_42_test.gleam.
Publika tipo MixedDirectionalCoverage(previous: discovery_41_joint_directional_deficit.JointDirectionalDeficit, mixed_coverage_numerator: Int, mixed_coverage_denominator: Int).
dispatch_discovery_42(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), left_bands: List(discovery_27_sum_bands.SumBand), right_bands: List(discovery_27_sum_bands.SumBand)) -> Result(MixedDirectionalCoverage, discovery_19_interval_value.Discovery19Error).
Voku Stage41 precize unufoje kun la samaj argumentoj, ankaŭ ĉe malplenaj enigoj; repropagu Error senŝanĝe, konservu previous. Legu L,R,I,T,CL,CR,M,J,Q; kontrolu kardinalecojn (0<=I<=min(L,R), L+R-I<=T), pozitivajn denominatorojn, redukton, vakuajn konvenciojn, kaj kongruon de J,Q kun CL,CR. Kun a/b=CL,c/d=CR formu n=a*(d-c)+(b-a)*c kaj q=b*d; reduktu per loka Eŭklida gcd. Kontrolu rektan kardinalecan formulon inkluzive nul-kazojn, J+Q+X=1 kaj X=2*M-2*J per krucmultipliko; malkongruo -> InvalidStream. Neniu fenestra enumerado, Stage21-voko, mutacio, nova dependeco, translingva fixture aŭ plena datkonverto en produkto. Konstanta nombro da entjeraj operacioj plus logaritma gcd-paŝokosto; ne konstanta bitkosto.

## Sendependa orakolo
Nur en testoj: ricevu Stage21-gapojn, enumeru ĉiujn indeksajn fenestrojn (a,b), 0<=a<b<=k, sumu rekte kaj kontrolu membrecon kontraŭ ORIGINALAJ bandoj. Por ĉiu flanko konstruu liston de buleaj indikiloj de membro en la alia aro; se la fonto malplena, uzu unu virtualan True indikilon (nur por la vakua konvencio). Enumeru ordigitajn parojn el la du listoj; nombri malsamajn buleojn (XOR), dividu per la nombro de paroj. Serĉu plej malgrandan pozitivan denominatoron z tia ke (count*z) mod total=0; numeratoro=count*z/total. Neniu produkta gcd aŭ produkta nombrilo kiel orakolo. Kontrolu ankaŭ heredajn L,R,I,CL,CR,J,Q; ripetitaj ID-oj restu apartaj laŭ indekso.

Precize 12 unikaj publikaj discovery_42_*_test:
1. both_empty 0/1.
2. left_empty 1/1.
3. right_empty 1/1.
4. disjoint_nonempty 0/1.
5. equal_nonempty 0/1.
6. left_subset (3,7,3) 4/7.
7. right_subset (7,3,3) 4/7.
8. partial_overlap (5,3,2) 8/15.
9. asymmetric_overlap (7,5,3) 18/35.
10. repeated_ids_duplicate_bands: indeksa obleco kaj originala membreco.
11. wide_inverted_and_error_priority: limoj ĝis 10^70, inversaj bandoj, InvalidBowlId/InvalidContext, sama prioritato kiel Stage41.
12. matrix: determinisma k<=12, rekta fenestra XOR-orakolo, simetrio, nul-/unu-kazoj, redukto, identecoj kaj previous.

## Matematika antaŭkontrolo — NE Native
JavaScript precizaj sekuraj entjeroj: k=0..12, T=k(k+1)/2, L,R=0..T, I=max(0,L+R-T)..min(L,R). Por ĉiu stato la kandidato a*(d-c)+(b-a)*c super b*d estis reduktita per gcd. Sendependa orakolo konstruis buleajn listojn de longo max(1,L), max(1,R), la unuaj I veraj (ĉe malplena listo unu virtuala True), sumis por ĉiu maldekstra buleo la nombron de dekstraj malsamaj buleoj kaj serĉis minimuman denominatoron per modulo. Kontrolitaj ekzakta frakcio, intervalo, X=CL+CR-2*CL*CR, nul-/unu-kazoj. Rezulto 202735/202735, 0 malkongruoj, 9386 nulaj, 728 unuaj, maksimuma reduktita denominatoro 5929. Abstrakta kardinaleco, ne realaj bandaj enigoj, ne Gleam, ne differential, ne CI.

## Pordegoj
A: nur ĉi tiu kontrakto kaj DEVELOPMENT_STAGE.md; propra sama-SHA Native 514/514, read-only format/source integrity, Gleam1.18.1/OTP28, Names Lock, job/log/artifact/head_sha/digest kaj verification.log.
B nur post A: unu nova produkta modulo kaj 12 testoj; 526/526 antaŭdirita, ne mezurita, propra sama-SHA Native+Names.
C nur post B: dokumenta fermo kun propra sama-SHA Native526/526+Names.
D nur post C: fina metadata-markilo kun propra sama-SHA Native526/526+Names antaŭ LAST_COMPLETED_STAGE=46.
Ĝis D LAST_COMPLETED_STAGE=45. queued/in_progress ne PASS nek bloko. Neniu duobla dispatch, Stage47, main, merge, publikigo, politika ŝanĝo aŭ plena datkonverto.
