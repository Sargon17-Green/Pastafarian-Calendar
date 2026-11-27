# Stadio 45 — DISCOVERY 41: komuna direkta manko

PROJECT_ID: PC-BRANCH-GLEAM-ESPERANTO
Branĉo: Gleam+Esperanto. Programo: 55 stadioj.
Baza akceptita HEAD: 6eabaffb7a2b722280ab17e7d75448a15bb1f96d; LAST_COMPLETED_STAGE=44.
Rajtigo: Issue #36, komento 7085562104 (2026-11-22), daŭra rajtigo ene de la ekzistanta branĉo; neniu main, merge, publikigo aŭ plena datkonverto.

## Bazo kaj celo
Stage44 Gate D kaj akcepta rekordo estas akceptitaj. La rekorda HEAD estis komparita kun la aktuala branĉo (identical 0/0). Native 45907378941 / job 140207255607 completed/success, 502 pasis, neniu malsukceso; Names 45907379060 / job 140207256005 completed/success. La logoj montras la saman SHA. Artifact 15158358027, digest sha256:94ca921ee56a015ff7356b49c2c02c0b22262371ea328a98c97bac408e106f56; la antaŭa elŝutita ZIP kaj verification.log estis kontrolitaj laŭ la akcepta registro; ĉi-hodiaŭ la artifact-metadatumoj kaj job-logoj estis rekontrolitaj. Tio NE estas Gate A de Stage45.

## Kontrakto
Por la hereditaj indeksaj fenestraroj L, R kaj intersekca kardinaleco I, la direktaj kovroj estas CL=I/L, CR=I/R, kun kovro 1 por malplena fonto. Stage44 donas J=CL*CR. Stage45 aldonas la komunan direkta-mankan frakcion Q=(1-CL)*(1-CR). Ĝi mezuras la produkton de la du ne-kovritaj proporcioj; ne estas probablo-aserto kaj ne estas 1-J.

Se L,R>0: Q=(L-I)*(R-I)/(L*R). Se L=0 aŭ R=0: Q=0/1 (vakua kovro en almenaŭ unu direkto). Disaj ne-malplenaj aroj donas 1/1. Subaro en ambaŭ direktoj aŭ egalaj aroj donas 0/1.
Rezulto p/q plene reduktita, q>0, 0<=p<=q. Sen glitkomo. Q simetria. Q=0 iff almenaŭ unu aro estas subaro de la alia (inkluzive malplenan); Q=1 iff L,R>0 kaj I=0. Q <= min(1-CL,1-CR). Identecoj Q=1-2*M+J, Q=(1-M)^2-S^2/4, kie M estas Stage38 meza kovro kaj S Stage37 signita diferenco. Kontrolu per krucomultipliko.

## Produkta API
Nova modulo src/pastafari/discovery_41_joint_directional_deficit.gleam.
Nova testdosiero test/discovery_41_test.gleam.
Publika tipo JointDirectionalDeficit(previous: discovery_40_joint_directional_coverage.JointDirectionalCoverage, joint_deficit_numerator: Int, joint_deficit_denominator: Int).
dispatch_discovery_41(context: bootstrap.MonsterContext, requested_bowl_ids: List(Int), left_bands: List(discovery_27_sum_bands.SumBand), right_bands: List(discovery_27_sum_bands.SumBand)) -> Result(JointDirectionalDeficit, discovery_19_interval_value.Discovery19Error).
Voku Stage40 precize unufoje kun la samaj argumentoj, eĉ por malplenaj enigoj. Repropagu Error senŝanĝe. Konservu previous sen modifo. Legu hereditajn CL,CR,M,S,J,L,R,I; validigu pozitivajn denominatorojn, reduktitajn frakciojn, kardinalecajn limojn, vakuajn kovrojn kaj la produktan J. Formu raw numeratoron (CL_d-CL_n)*(CR_d-CR_n), raw denominatoron CL_d*CR_d. Reduktu per loka Eŭklida gcd; kontrolu la rektan kardinalecan formulon, nul-/unu-kazojn, limojn kaj ambaŭ identecojn. Malkongruo -> InvalidStream. Neniu Stage21-voko, fenestra enumerado, mutacio, nova dependeco aŭ translingva fixture en produkto. Aldona kosto: konstanta nombro da entjeraj operacioj plus O(log(max(1,raw_denominator))) Eŭklidaj paŝoj; ne asertas konstantan bitkoston.

## Sendependa orakolo
Nur en la nova Gleam testdosiero: ricevu Stage21-gapojn kaj rekte enumeru indeksajn fenestrojn (a,b), 0<=a<b<=k, kontraŭ ORIGINALAJ bandoj. Kalkulu L,R,I sen produktaj nombriloj. Por ne-malplenaj aroj, enumeru ordigitajn parojn el la maldekstra kaj dekstra fenestraroj kaj kalkulu parojn kie la maldekstra fenestro ne estas en R kaj la dekstra ne estas en L. Serĉu la plej malgrandan pozitivan denominatoron per ekzakte dividebla entjera numeratoroprodukto, sen produkta gcd. Se almenaŭ unu aro estas malplena, atendu 0/1. Kontrolu ankaŭ inherited Stage36–40 per rekta fenestra orakolo. Ripetitaj ID-oj restas apartaj laŭ indekso.

Precize 12 publikaj unikaj *_test:
1. both_empty — 0/1.
2. left_empty — 0/1.
3. right_empty — 0/1.
4. disjoint_nonempty — 1/1.
5. equal_nonempty — 0/1.
6. left_subset — L=3,R=7,I=3, 0/1.
7. right_subset — interŝanĝita, 0/1.
8. partial_overlap — L=5,R=3,I=2, 1/5.
9. asymmetric_overlap — L=7,R=5,I=3, 8/35.
10. repeated_ids_duplicate_bands — indeksa obleco, ne duobla bando-nombrado.
11. wide_inverted_and_error_priority — limoj ĝis 10^70, inversaj bandoj, InvalidBowlId kaj InvalidContext, sama prioritato kiel Stage40.
12. matrix — determinisma k<=12; rekta orakolo, simetrio, Q=0 iff subaro, Q=1 iff disaj ne-malplenaj, limoj, redukto, identecoj kaj antaŭa rezulto. Testaj nomoj prefiksitaj discovery_41_ kaj sufiksitaj _test.

## Ekstera matematika antaŭkontrolo (NE Native)
JavaScript preciza entjera aritmetiko en la sekura Number-intervalo: por k=0..12, T=k(k+1)/2, L,R=0..T, I=max(0,L+R-T)..min(L,R). Produkt-kandidato reduktita per gcd; orakolo sendepende sumas R-I por ĉiu el la L-I maldekstraj ekskluzivaj indeksaj membroj, poste serĉas minimuman denominatoron. Kontrolitaj rekta frakcio, Q=1-CL-CR+CL*CR, limoj kaj nul-/unu-kazoj. 202735/202735, 0 malkongruoj, 19123 nulaj, 9009 unuaj, maksimuma reduktita denominatoro 5929. Abstrakta kardinaleco nur; ne realaj bandaj enigoj, ne Gleam, ne differential, ne CI.

## Pordegoj
A: kontrakto kaj minimuma DEVELOPMENT_STAGE.md ĝisdatigo nur; propra sama-SHA Native 502/502, format --check, fontintegreco, Gleam 1.18.1/OTP28, Names Lock, job/log/artifact/head_sha/digest kaj verification.log.
B nur post A: unu nova produkta modulo kaj 12 novaj testoj; 514/514 antaŭdirita, ne mezurita, propra SHA Native+Names.
C nur post B: dokumenta fermo kun propra SHA Native514/514+Names.
D nur post C: fina metadata-markilo kun propra SHA Native514/514+Names, tiam LAST_COMPLETED_STAGE=45.
Ĝis D LAST_COMPLETED_STAGE=44. queued/in_progress ne PASS nek bloko. Neniu duobla dispatch, Stage46, main, merge, publikigo, politika ŝanĝo aŭ plena datkonverto.
