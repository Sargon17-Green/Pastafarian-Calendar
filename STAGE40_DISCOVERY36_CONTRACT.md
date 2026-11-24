# Stadio 40 — DISCOVERY 36: direkta kovrado de indeksaj sumfenestraroj

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Akceptita baza HEAD: bbf5810e84a973a438cc0b32919fef88ab0323da, LAST_COMPLETED_STAGE=39.
Rajtigo: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/36#issuecomment-7085562104 . Nur ĉi tiu branĉo; neniu main, merge, publikigo, plena datkonverto aŭ fremda realigo. Ĉi tiu kontrakto elektas novan diagnozon, ne inventas difekton aŭ EXPECTED_RED.

Stage39 baza atesto: Native https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45263942797 job 138005746813, completed/success, precize 442 pasis, neniu fiasko, Gleam 1.18.1 / OTP 28 / ERTS 16.4.0.7, read-only format kaj fontintegreco. Names https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45263942811 job 138005746715 completed/success, sama SHA en checkout-log. Artifact 14861288798, digest 164e08c010896f49972bd38539d70d390a73455bcc0b647764e89b4108382862, head_sha identa; antaŭa sendependa ZIP-digest kontrolo registrita en la projektreĝistro. Neniu rerulo de akceptita SHA.

## Kontrakto
Enigo: bootstrap.MonsterContext, ordigita List(Int) de eksplicitaj bovlo-ID-oj, kaj du List(discovery_27_sum_bands.SumBand) A,B. Ripetoj restas distingaj laŭ indekso; inversaj bandoj estas malplenaj. Sama validigo, erarprioritato kaj kanonigo kiel Stage39. Pozitivaj gapoj de Stage21; fenestro (a,b), 0<=a<b<=k, sumo g[a:b]. UA kaj UB estas indeksaj fenestraroj kun sumoj en la originalaj validaj bandoj. L=|UA|, R=|UB|, I=|UA∩UB|, U=|UA∪UB|, X=|UA△UB|, T=k(k+1)/2.
Nova rezulto: CL=I/L kiam L>0, alie 1/1; CR=I/R kiam R>0, alie 1/1. La malplena fontaro estas vakue plene kovrita; tio estas intenca loka konvencio, NE ŝanĝo de la antaŭa overlap-konvencio. Ĉiu frakcio estas reduktita, kun pozitiva denominatoro kaj 0<=p<=q. CL=1 iff UA estas subaro de UB, CR=1 iff UB estas subaro de UA; ambaŭ 1 iff UA=UB. Interŝanĝo de A,B interŝanĝas CL,CR. Ambaŭ malplenaj: (1,1); nur A malplena: (1,0); nur B malplena: (0,1). Ĉe L,R>0: max(CL,CR)=O, min(CL,CR)<=D<=max(CL,CR), J<=min(CL,CR); kiam unu estas malplena O=0 malgraŭ max=1. Ĉiuj komparoj per krucomultipliko. Neniu flitkomo.
Abstrakta ekzemplo g=[42,42,42], A=[[42,85]], B=[[43,963]]: L=5,R=3,I=2,U=6,X=4,T=6; CL=2/5,CR=2/3. Ne aserto pri konkretaj bovlo-ID-oj.

## API kaj spageta kresko
Nova src/pastafari/discovery_36_directional_coverage.gleam, nova test/discovery_36_test.gleam. Publika tipo DirectionalWindowCoverage kun kampoj previous: discovery_35_overlap_bands.OverlapWindowSimilarity, left_coverage_numerator: Int, left_coverage_denominator: Int, right_coverage_numerator: Int, right_coverage_denominator: Int. Publika dispatch_discovery_36(context, requested_bowl_ids, left_bands, right_bands) -> Result(DirectionalWindowCoverage, discovery_19_interval_value.Discovery19Error), argumenttipoj kiel supre.
Voku precize unufoje discovery_35_overlap_bands.dispatch_discovery_35 eĉ ĉe malplenaj enigoj; repropagu Error senŝanĝe. Sur Ok, konservu previous sen modifo. Kontrolu ne-negativajn nombrilojn, I<=min(L,R), L,R<=U<=T, U=L+R-I, X=U-I, T=k(k+1)/2. Kontrolu heredajn J,D,O (reduktitaj, precizaj inkluzive de iliaj propraj nulaj konvencioj). Reduktu la du novajn frakciojn per loka Eŭklida gcd; neniam dividu per nulo. Kontrolu la novajn valorojn kaj invariantojn supre; malkongruo -> InvalidStream. Neniu nova dependeco, kanonigo, fenestrenumerado, Stage21-revoko en produkto, aŭ fremda kodo. Kosto super Stage39: O(k) paŝoj por la longo de la ligita ID-listo kaj O(log(max(1,L,R,T))) Eŭklidaj aritmetikaj paŝoj kaj O(1) pliaj entjer-vortoj; neniu konstanta bitkosta aserto. La hereda arkitekturo restu netuŝita.

## Sendependa orakolo kaj 12 testoj
Nur en nova testdosiero: uzu Stage21 gapojn por validaj ID-oj; enumeru ĉiujn indeksajn (a,b) kun k<=12, kalkulu rektajn sumojn kaj membrecon en ORIGINALAJ A,B; kalkulu L,R,I,U,X,T per buleaj membrecoj, ne per Stage39-nombriloj. Trovu ĉiun atendatan CL/CR per plej malgranda pozitiva denominatoro q<=L aŭ R kun (I*q) mod n=0; n=0 eksplicite 1/1. Ne uzu produktan gcd. Kontrolu heredajn kampojn per rekta orakolo kaj eksplicitaj kanonaj fiksaĵoj, ne sole metamorfoj.
1. Malplenaj ID-oj kaj bandoj: ambaŭ 1/1.
2. Malplenaj ID-oj kun ne-malplenaj, inversaj kaj eksteraj bandoj.
3. Unu gap ambaŭ trafitaj ĉe inkluzivaj limoj.
4. Nur unu flanko trafita, ambaŭ direktoj: vakua 1/1 kontraŭ 0/1; neniu trafita.
5. Du-gapaj partaj interkovroj kaj ses nombriloj.
6. Tri/ kvar-gapaj malsimetriaj, netrivialaj reduktitaj frakcioj; elektu validajn ID-ojn laŭ orakolo.
7. Vera strikta subaro: unu CL/CR=1, alia <1; ambaŭ direktoj.
8. Egalaj fenestraroj kun malsamaj originalaj bandoj, duplikatoj kaj nestado.
9. Apudaj/inversaj/negativaj kaj ±10^70 bandlimoj.
10. Ripetitaj ID-oj kaj samvaloraj sumoj de malsamaj indeksaj fenestroj.
11. InvalidBowlId kaj InvalidContext, erarprioritato eĉ kun malplenaj bandoj.
12. Determinisma matrico k<=12: rekta orakolo, simetria interŝanĝo, subaraj iff, J/D/O-rilatoj, reduktitaj frakcioj.
Ekstera matematika antaŭkontrolo (JS BigInt, NE Gleam Native): 121 sinsekvoj longo 0..4 super {42,43,963} x 13 bandfamilioj x 13 = 20449, plus 5000 determinismaj LCG32 kazoj seed 20261125, k<=12, gapoj 42..963, ĝis sep bandoj flanke. Rekta indeksa Set-membreco, minimum-denominatora serĉo kontraŭ Eŭklida redukto, nul-kazoj kaj invariantoj: 25449/25449, 0 malkongruoj; 16555 malsimetriaj; 17292 kun almenaŭ unu malplena fenestraro. Tio ne estas produkto/Native/differential PASS.

## Pordegoj
A: nur kontrakto kaj metadata, sama fina SHA Native 442/442 + Names Lock, completed/success, job/log/artifact/head_sha/digest, read-only format kaj fontintegreco.
B: nur post A, unu nova produkta modulo kaj 12 unikaj publikaj *_test; 454/454 estas antaŭdiro, akcepto post propra sama-SHA Native kaj Names kun plena atesto.
C: nur post B, dokumenta fermo kun propra 454/454 Native+Names.
D: nur post C, fina metadata-markilo kun propra 454/454 Native+Names. LAST_COMPLETED_STAGE=39 ĝis fina akcepto; markilo povas esti nur provizora antaŭ D. Neniu duobla mana dispatch; queued/in_progress nek PASS nek bloko. Neniu Stage41, main/merge/publish.
