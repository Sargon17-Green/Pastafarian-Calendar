# Stadio 47 — DISCOVERY 43: kondiĉa konkorda kovro

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto; programo 55 stadioj.
Baza akceptita HEAD: fc4176bcf57505465348402afa114f9ad6e4e16d; LAST_COMPLETED_STAGE=46.
Rajtigo: Issue #36 komento 7085562104, daŭra rajtigo ene de ekzistanta branĉprogramo.

## Celo kaj kontrakto
Stage44 J=CL*CR, Stage45 Q=(1-CL)*(1-CR), Stage46 X=CL*(1-CR)+(1-CL)*CR; J+Q+X=1. La nova mezuro S=J/(J+Q) kondiĉas sur konkordaj buleaj paroj, ne estas empiria probablo. Se J+Q=0, rezulto eksplicite NoConcordantPairs, neniam arbitra 0/0 aŭ 0/1. Tio okazas precize kiam unu aro estas malplena kaj la alia ne. Alie reduktita Fraction(p,q), q>0, 0<=p<=q, gcd(p,q)=1. Ambaŭ malplenaj: 1/1; disaj ne-malplenaj: 0/1; egalaj: 1/1; ne-malplena subaro: 1/1; (L,R,I)=(5,3,2): 4/7; (7,5,3): 9/17. Por L,R>0, S=I^2/[I^2+(L-I)*(R-I)]. Simetria sub interŝanĝo. Ne identigu kun Jaccard aŭ Dice.

## Produkta API
Nova modulo src/pastafari/discovery_43_conditional_concordant_coverage.gleam; test/discovery_43_test.gleam.
Publika tipo ConcordantScore kun NoConcordantPairs kaj Fraction(numerator: Int, denominator: Int).
Publika tipo ConditionalConcordantCoverage(previous: discovery_42_mixed_directional_coverage.MixedDirectionalCoverage, score: ConcordantScore).
dispatch_discovery_43(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), left_bands: List(discovery_27_sum_bands.SumBand), right_bands: List(discovery_27_sum_bands.SumBand)) -> Result(ConditionalConcordantCoverage, discovery_19_interval_value.Discovery19Error).
Voku Stage46 precize unufoje, eĉ ĉe malplenaj enigoj. Repropagu Error senŝanĝe. Konservu previous. Kontrolu kardinalecojn 0<=I<=min(L,R), L+R-I<=T, heredajn reduktitajn CL,CR,J,Q,X, vakuan konvencion, J+Q+X=1 kaj J,Q kontraŭ CL,CR per krucmultipliko. Kun J=j/u,Q=h/v, kalkulu n=j*v, d=j*v+h*u; se d=0 kontrolu X=1 kaj precize unu malplenan aron antaŭ NoConcordantPairs; alie reduktu n/d per loka Eŭklida gcd, kontrolu kardinalecan formulon kaj limojn. Malkongruo -> InvalidStream. Neniu fenestra enumerado, Stage21-voko, mutacio, nova dependeco, translingva fixture aŭ plena datkonverto en produkto. Konstanta nombro de entjeraj operacioj plus logaritma gcd-paŝokosto; ne konstanta bitkosto.

## Sendependa test-orakolo
Nur en testoj: ricevu Stage21-gapojn, enumeru ĉiujn indeksajn fenestrojn (a,b), 0<=a<b<=k, sumu rekte, kontrolu membrecon kontraŭ ORIGINALAJ bandoj. Por ĉiu fontaro konstruu bulean liston (membro en la alia aro); ĉe malplena fonto unu virtuala True. Enumeru ordigitajn parojn de tiuj listoj; retenu nur parojn kun egalaj buleoj kaj nombri la parojn True/True. Se neniu retenita paro, NoConcordantPairs. Alie serĉu plej malgrandan pozitivan denominatoron z kun (true_pairs*z) mod retained_pairs=0; numeratoro=true_pairs*z/retained_pairs. Neniu produkta gcd, produkta nombrilo aŭ produkta S-formulo kiel orakolo. Kontrolu previous, heredajn nombrojn kaj la erarprioritaton. Ripetitaj ID-oj restu apartaj laŭ indekso.

Precize 12 unikaj publikaj discovery_43_*_test:
1. both_empty 1/1.
2. left_empty NoConcordantPairs.
3. right_empty NoConcordantPairs.
4. disjoint_nonempty 0/1.
5. equal_nonempty 1/1.
6. left_subset (3,7,3) 1/1.
7. right_subset (7,3,3) 1/1.
8. partial_overlap (5,3,2) 4/7.
9. asymmetric_overlap (7,5,3) 9/17.
10. repeated_ids_duplicate_bands: indeksa obleco kaj originala membreco.
11. wide_inverted_and_error_priority: limoj ĝis 10^70, inversaj bandoj, InvalidBowlId/InvalidContext, sama prioritato kiel Stage46.
12. deterministic matrix k<=12: rekta fenestra par-orakolo, simetrio, difiniteco, redukto, previous, identeco S*(J+Q)=J nur se difinita.

## Matematika antaŭkontrolo — NE Native
JavaScript ekzaktaj sekuraj entjeroj; k=0..12, T=k(k+1)/2, L,R=0..T, I=max(0,L+R-T)..min(L,R). Kandidato kalkulis n=a*c, d=n+(b-a)*(d2-c), kun CL=a/b, CR=c/d2 kaj vakua 1/1; gcd-redukto. Sendependa orakolo rekte enumeris la buleajn parojn, retenis egalajn kaj nombris True/True, poste minimum-denominatora serĉo. 202735/202735, 0 malkongruoj; 728 nedifinitaj, 9009 nulaj, 18395 unuaj, maksimuma reduktita denominatoro 5777. Abstraktaj kardinalecoj, ne realaj bandaj enigoj, ne Gleam, ne differential, ne CI.

## Pordegoj
A: nur ĉi tiu kontrakto kaj DEVELOPMENT_STAGE.md; sama-SHA Native 526/526, read-only format/source integrity, Gleam1.18.1/OTP28, Names Lock, job/log/artifact/head_sha/digest kaj verification.log.
B nur post A: unu nova produkta modulo kaj 12 testoj; 538/538 antaŭdirita, ne mezurita; propra sama-SHA Native+Names.
C nur post B: dokumenta fermo kun propra sama-SHA Native538/538+Names.
D nur post C: fina metadata-markilo kun propra sama-SHA Native538/538+Names antaŭ LAST_COMPLETED_STAGE=47; acceptance record kun propra exact-SHA CI.
Ĝis D LAST_COMPLETED_STAGE=46. queued/in_progress ne PASS nek bloko. Neniu duobla dispatch, Stage48, main, merge, publikigo, politika ŝanĝo aŭ plena datkonverto.
