# Historio dil spaghetti-developo

## Stage 1 — Bootstrap

### Quo esis konstruktita

Nova Logo + Ido repository esis kreita de zero, sen portado, kopiado o komparo kun altra implemento. La `SourceLanguageCatalog` havas 17 koteleto-nomi e 47 monato-nomi kun stabila `canonicalIndex`. La nomi esas prezental; la algoritmala ordino uzas nur la indexi.

La test-zono kontenas pura normativa referenco derivita nur de Appendix A. La production-zono kontenas nur neutrala baza context, dispatcher, validigilo, eroro-envelopilo, mezuro e logado. Nula historiala legacy-defekto esas introduktita en ca etapo.

### Monster-arkitekturo adicionita

Nur neutrala shelo esas adicionita: per-invocation context, faza dispatchado, validation boundary, determinista logado e mezuro. Ca shelo ne havas patch-specifala flagi, cache, detour, ghost, latch o futura compatibility-vojo.

### Semantika neutralajo

La neutrala shelo ne kalkulas kalendarala rezulto. Ol nur valida la input-formo e haltas kun explicita Stage-1 stato. La oracle esas test-only e nultempe esas vokata de production. La production-contexto apartenas a un invocationo e ne esas dividita inter du vokoj.

### Stato

La Stage-1 fonti esis verifikita per Berkeley Logo / UCBLogo 6.2.5. Dum la unesma native-rulado, kelka Logo-vorti `true` e `false` bezonis explicita quotado, e la rekursiva helper `bi.mag.qdigit.work` bezonis la mankanta denominator-argumento. Nur ca Stage-1 erori esis korektita; nula Stage-2 kodo esis adicionita.

La fina komando `logo test/stage01_tests.logo` finis kun exit-statuso 0 e atingis la marker `STAGE_1_TESTI_PASIS`. Pro to Stage 1 esas kompletigita e `LAST_COMPLETED_STAGE=1`.

## Stage 2 — DISCOVERY 01 (nova, sendependa laboro)

La uzanto la 2026-11-02 explicitamente permis la nova sendependa
implemento anstataus la perdita historiala delta-arkivo. Ol ne esas
restauro ni kopio di la antea Stage-2 fonti.

Nova production-proceduro `monster.stage02.normalize` kalkulas la
1-bazita resta modulo M per 0-resta aparta handlingo. La norma test-only
formulo esas `nr.save`; nula production-voko a la oracle existas.
La boundary-discovery inkluzis M, 2M, 3M, M+1, zero e negativa inputi.

Native UCBLogo 6.2.5, run 41522957906, completed SUCCESS: 44/44
asserti, `STAGE_2_CHECKS_PASIS 44`, `STAGE_2_DISCOVERY_01_PASIS`
e `NATIVE_STAGE_2_DISCOVERY_01_VERIFICATION=PASS`.
La Stage-1 regresio run 41522957076 completed SUCCESS; la verify
run 41522957044 completed SUCCESS, sur commit
`f0498eeb99eea99038e080d300f26ff0615ce564`.

DISCOVERY 01 esas verifikita. Stage 2 ankore ne kompletas la
kalendarala kvinoplo. La historiala EXPECTED_RED ne esis
reproduktita; nula bugo esas deklarita sen reproduktajo.

## Stage 2 — DISCOVERY 02 (native GREEN)

Nova production-proceduro monster.stage02.context, separita de la
Stage1 calendarDateSpaghetti, konstruas unu contexton por singla
invocation e kalkulas du normaligita BI modulo-valori en [1,M].
L'originala inputi ne mutacesas; logi e metrics ne fuitegas inter vokoj.
Nula norma test-only oracle esas vokata da production.

En commit 3de04eef770f9ca7a4aeb82e512a80b0db0b7c27, Native
Stage2 run 41536277402 completed SUCCESS:
28 input-pari, 406 asserti, e la marki
STAGE_2_DISCOVERY_02_PAIRS_PASIS 28,
STAGE_2_DISCOVERY_02_CHECKS_PASIS 406,
STAGE_2_DISCOVERY_02_PASIS,
NATIVE_STAGE_2_DISCOVERY_02_VERIFICATION=PASS.
Stage2 DISCOVERY01 44/44 anke restis GREEN en la sama run.
Stage1 native 41536277596 e verify 41536277432 completed SUCCESS.

DISCOVERY02 esas acceptita. La Stage2 entere ne esas deklarita
completigita; LAST_COMPLETED_STAGE restas 1.
La futura DISCOVERY03 traktos exakta dayCount/distance/connection/direction
kom novi intermediate BI state-valori, ne la fina kvinoplo.
 
## Stage 2 — DISCOVERY 03 (native GREEN)

En commit `c2dbe2ac93ae8ac2e73ceabafa289daa97f73ea4`, Native Stage2 run 41537356932,
job 125592479688, completed SUCCESS. La autentika Logo-outputo
kontenis 26 input-pari, 404 asserti, e la marki
STAGE_2_DISCOVERY_03_PAIRS_PASIS 26,
STAGE_2_DISCOVERY_03_CHECKS_PASIS 404,
STAGE_2_DISCOVERY_03_PASIS,
NATIVE_STAGE_2_DISCOVERY_03_VERIFICATION=PASS.
Native Stage1 run 41537356917 (job 125592479713) e verify
41537356864 (job 125592479140) anke completed SUCCESS.
DISCOVERY03 esas acceptita; LAST_COMPLETED_STAGE restas 1.

## Stage 2 — DISCOVERY 04 (metamorfala testado, native pendanta)

Ca nexta unajo expandas la QA de la independenta Stage2 workcounts;
ol ne modifikas production-kodon. 24 determinista input-pari kontrolas
18 asserti per paro = 432 asserti. La prova-kontrato uzas nur test-only
nr.work.counts kom sendependa normativa oracle, kune kun inversa input-
ordino e simultana shift +M. Konservenda invarianti: symetrio de
distance e connection, reciproka action/target, direkto-sumo 4,
perioda modulo, sama distance/direkto pos shift, e exacta BI konturi.
La limiti inkluzas foundation, zero, tablets, -M, +M e +/-1000M.
Native PASS esas ankor ne deklarita. Nula fliko o historiala bugo
esas asertita sen reproduktajo; nula main/merge.

## Stage 2 — DISCOVERY 04 (native GREEN)

En commit `7c7e9df6dd56b8fe004704311e81ed716f82d0ff`, Native Stage2 run 41617790643
(job 125855472320) completed SUCCESS, kun 24 pari, 432 asserti
e la marki STAGE_2_DISCOVERY_04_PAIRS_PASIS 24,
STAGE_2_DISCOVERY_04_CHECKS_PASIS 432,
STAGE_2_DISCOVERY_04_PASIS,
NATIVE_STAGE_2_DISCOVERY_04_VERIFICATION=PASS.
La sama job anke verificis DISCOVERY 01–03.
Native Stage1 run 41617790656 (job 125855472594) e
Canonical Names verify 41617790663 completed SUCCESS.
DISCOVERY04 esas acceptita; LAST_COMPLETED_STAGE restas 1.

## Stage 2 — DISCOVERY 05 (kontrato redactita, implemento ne komencita)

La proxima injenierala tasko esas valida la strukturo di exakta
BI-inputo ante modulo o workcounts. La kontrato esas en
STAGE02_DISCOVERY05_CONTRACT.md. Ca tasko esas defensiva,
ne aserto pri reproduktita bugo. Nula Stage1 API o main esas modifikita.

## Stage 2 — DISCOVERY 05 (kanonala BI gardilo; Native ankore ne acceptita)

La sendependa Stage2-only gardilo rekonocas la exakta [sign, digits] formo
ante modulo-kalkulo o mezuro/logado. Nevalida enigo donas
FAILED_VALIDATION sen kalkuli intermedia konturi, sen state-liko.
Stage1 validator e calendarDateSpaghetti restas netushita.
Separita test-only katalogo havas 12 kanonala enigi, 12 nevalida
enigi; 8 kontrol-punkti por kazo, entute 192 planita asserti.
La CI provo esas bounded e konservas Discovery01–04 regresio.
Ca commit NE deklaras Native PASS ni Stage2 acceptance.

## Stage 2 — DISCOVERY 05: Native acceptita (2026-11-03)

Komito 8201d09b9c2d97b61814dbbaed0d7cd9931da21d efektivigis Stage2-only BI gardilo e
24 determinista kazi (12 valida, 12 nevalida), 192 asserti.
Native Stage2 run 41712427420 / job 126183616662 completed SUCCESS:
STAGE_2_DISCOVERY_05_CASES_PASIS 24,
STAGE_2_DISCOVERY_05_CHECKS_PASIS 192,
NATIVE_STAGE_2_DISCOVERY_05_VERIFICATION=PASS.
Discovery01–04 regresio markeri omna PASS en la sama completed-log.
Stage1 run 41712427288 / job 126183616905 completed SUCCESS,
kun STAGE_1_TESTI_PASIS; verify run 41712427305 / job
126183616678 completed SUCCESS. Nula manuala re-run o merge.
Stage2 ne esas kompleta; LAST_COMPLETED_STAGE=1 restas.

## Stage 2 — DISCOVERY 06 (planita)

Sequanta substantiva derivado esas la 46-ronda 5-valora stone-series
recidivo el Appendix A. Exakta algoritmo, 240 asserti e Native
acceptance-gates esas en STAGE02_DISCOVERY06_CONTRACT.md.
Ca komito nur dokumentas la nova kontrato, ne implikas Discovery06 PASS.

## Stage 2 — DISCOVERY 06 (implementation committed; Native pending)

Nova independanta Stage2-only procedure monster.stage02.stones
prenas nur valida INTERMEDIATE_COUNTS_ONLY context, uzas immutabla
antea quinteto per ronda, e konstruktas 46 stone-quinopli.
Production-normaligo uzas monster.stage02.normalize e bi.*;
nr.stones e nr.stone.next restas strikte test-only.
La test-file komparas 46 x 5 exakta BI valori kun Appendix-A
normativa oracle plus 10 context/isolation kontroli = 240.
CI konservas Discovery01–05 e Stage1 regresioni.
Nula Native rezulto por Discovery06 esas ankor deklarita;
LAST_COMPLETED_STAGE restas 1, nula main/merge.


## Stage 2 — DISCOVERY 06 timeout e provizora eficienc-fixo (2026-11-04)

En implementation commit `8e202f67d273d908b08ff1bd645accae954a641f`,
Native Stage2 run 41776086633 / job 126396653732 completed FAILURE,
exit=124 post 240s en Discovery06. Discovery01–05 test-steps
completed SUCCESS. Nula 46/240 PASS marker existas; Discovery06
NE esas acceptita.

La originala `bi.mag.qdigit` uzis repetata subtrahi por unika
baz-10000 quotient-digit, teorie til 9999 subtrahi po digit. Ca
faciĝas severa en 46-ronda modulo recurrence. Substitutas exacta
binary search en [0,9999] kun maximume 14 compari po quotient-digit;
la mathematal semantiko ne chanjesas. 32 sendepende generita
quotient/remainder vektori, 128 Native asserti, e kvar instrumentala
markers pro la D6 testa fazi esas adjuntita. Source/Stage1 regresioni
restas necesa. Ca esas performance remediation e diagnoso, ne
pruvo di sole causajo: CI Native por la nova commit restas PENDING.
LAST_COMPLETED_STAGE restas 1. Nula main/merge.

## Stage 2 — DISCOVERY 06 Native acceptita (2026-11-04)

La optimumiga commit `342e740e830108da40f3da92d147328e1c77e874` konservis la exacta BI aritmetiko
e adjuntis 32 independenta divmod-vektori, 128 asserti.
Native Stage2 run 41870469940 / job 126715826531 completed SUCCESS:
`STAGE_2_FAST_DIVMOD_CHECKS_PASIS 128`,
`NATIVE_BI_DIVMOD_FAST_VERIFICATION=PASS`,
`STAGE_2_DISCOVERY_06_ROUNDS_PASIS 46`,
`STAGE_2_DISCOVERY_06_CHECKS_PASIS 240`,
`STAGE_2_DISCOVERY_06_PASIS` e
`NATIVE_STAGE_2_DISCOVERY_06_VERIFICATION=PASS`.
Discovery01–05 regresioni anke completed SUCCESS en sama job,
sen failure markers. Stage1 run 41870469866 / job 126715826423
completed SUCCESS kun autentika `STAGE_1_TESTI_PASIS` e
`NATIVE_STAGE_1_VERIFICATION=PASS`; Canonical Names 41870469889
completed SUCCESS. DISCOVERY06 ACCEPTED; Stage2 ne esas entere
completigita, LAST_COMPLETED_STAGE=1. Nula manuala CI rerun, main o merge.

## Stage 2 — DISCOVERY 07 (kontrato derivita; implementation NE komencita)

Sequanta tasko esas la sep hidden-seed BI valori en Appendix A,
dependanta de la 46 verificita stone-serio e kvin workcounts.
La aparta `STAGE02_DISCOVERY07_CONTRACT.md` definesas exacta
inputo, formulas, 3 valida + 2 nevalida contexti, 53 asserti,
Native test-oracle apartiguro e termino-limiti. Nula D7 Native PASS
esas deklarita en ca komito.

## Stage 2 — DISCOVERY 07 (independenta implementation, Native pending)

Separata `src/stage02_hidden.logo` implementas exacta 7-hidden-seed
transformation super Stage2 STONE_SERIES_ONLY context, sen vocar
`nr.hidden.*`; test-only `nr.hidden.build` esas l'oraklo.
Tri valida + du nevalida contexti produktas 53 programmita asserti
(3*(7+9+1)+2). Workflow enplusas bounded 420s Native D7 test-step,
konservas Stage2 D1–D6 regressioni, strict 20-minuta job budget.
Ca commit NE deklaras Native PASS o Stage2 full acceptance.
LAST_COMPLETED_STAGE=1 restas; nula main/merge.
 
## Stage 2 — DISCOVERY 07 Native acceptita (2026-11-04)
Native Stage2 run 41872294990 / job 126722352207, completed SUCCESS
sur SHA 3e56c8ab5d800a9e9b8d8652d664eb295b9f0a97. Real markers:
STAGE_2_DISCOVERY_07_CASES_PASIS 5,
STAGE_2_DISCOVERY_07_CHECKS_PASIS 53,
STAGE_2_DISCOVERY_07_PASIS,
NATIVE_STAGE_2_DISCOVERY_07_VERIFICATION=PASS.
Discovery01–06 regressioni anke completed SUCCESS.
Stage1 Native run 41872294983/job 126722361171 completed SUCCESS
kun STAGE_1_TESTI_PASIS e NATIVE_STAGE_1_VERIFICATION=PASS.
Canonical Names run 41872294959/job 126722351770 completed SUCCESS.
Discovery07 ACCEPTED; plena Stage2 NE acceptita; LAST_COMPLETED_STAGE=1.

## Stage 2 — DISCOVERY 08 (first-five visible prefix; Native pending)
Nova production `monster.stage02.visible.prefix` konstruktas la prime
5 visible drops per exakta Appendix-A BI-aritmetiko e 11 grind-rondi.
La test-only oracle `nr.visible.one` esas sendependa de production.
2 valida + 2 nevalida contexti, 34 asserti; Native bounded 420s;
D1–D7, Stage1 e Canonical Names regressioni restas deviga.
Nula plena 46-drop claim, nula main/merge. LAST_COMPLETED_STAGE=1.

## Stage2 D8 first CI failure triage / bounded timing patch (2026-11-05)
On 34a966d9fd58146c91cd6ba5dae0704c9c1d53ae completed Stage2 run 41879013512/job 126746318536 failed at Discovery07 regression by timeout exit=124 at 420s; D1-D6 PASS, D8 step skipped, no D8 native acceptance. Same immutable Stage7 production and test had 5 cases/53 assertions PASS in about 251s at 3e56c8ab (run 41872294990). Stage1 41879013378 PASS with STAGE_1_TESTI_PASIS / NATIVE_STAGE_1_VERIFICATION=PASS; Canonical Names 41879013339 SUCCESS; same SHA. No semantic discrepancy demonstrated. Targeted CI-only guard: allow 650s per D7/D8, 30min job, add case BEGIN/END diagnostic markers without altering test counts or algorithm; new SHA Native remains PENDING, not PASS. No main/merge.

## Stage 2 — DISCOVERY09 Native acceptita (2026-11-06)
SHA 3efd58c2e5a0276e6ac2efb88e677b9bc4726ca8: Stage2 run 42125675962/job 127589109092 completed SUCCESS kun STAGE_2_DISCOVERY_09_CASES_PASIS 4, STAGE_2_DISCOVERY_09_CHECKS_PASIS 20 e NATIVE_STAGE_2_DISCOVERY_09_VERIFICATION=PASS. D1–D8 regressioni SUCCESS. Stage1 run 42125675924/job 127589109571 completed SUCCESS kun STAGE_1_TESTI_PASIS e NATIVE_STAGE_1_VERIFICATION=PASS. Names Lock 42125675872 completed SUCCESS. D9 acceptita; plena Stage2 ne acceptita; LAST_COMPLETED_STAGE=1.

## Stage 2 — DISCOVERY10 (visible 11–15; Native PENDING)
Production-only exact BI extension uzas verified prior/initial/grind helpers; test-only normative nr.visible.one independent de production. 1 valida + 3 nevalida, 20 target asserti. Separata Native CI <=900s test, <=20m job, D1–D9, Stage1 e Names still obligatory same SHA. Ca candidate NE deklaras Native PASS; nula main/merge.

## Stage 2 — DISCOVERY10 unua Native FAIL e sola testala fixo (2026-11-06)
Native run 42173607919/job 127746881149 completed FAILURE; exact marker `STAGE_2_DISCOVERY_10_TESTO_FALIIS: [foundation_tablets] [determinism]`. Origina testala assertion vokis `monster.stage02.visible.ten` por komparar D10 rezulto; invalid guards vokis D9 anke, e D10 runner havis D9 nomo. Ta fixo nur korektigas testala D10 call sites e runner nomo; production, test oracle e cardinali 4 cases/20 asserti nechanjita. D1–D9 42173608092 SUCCESS, Stage1 42173607850 SUCCESS, Names 42173607821 SUCCESS sur originala SHA df4e81746206ae55703dd13c6905ff6c41e9d223. Nova candidate bezonas propra Native PASS e sama-SHA regresioni; nula main/merge, LAST_COMPLETED_STAGE=1.

## Stage2 DISCOVERY10 Native ACCEPTED, DISCOVERY11 candidate (2026-11-06)
D10 fix SHA 2c47a2ae7d0d8be06b4b87e0cf92afb6fc9f85a6: 42176772918/job 127756927922 SUCCESS (4 cases, 20 checks, NATIVE_STAGE_2_DISCOVERY_10_VERIFICATION=PASS). Same-SHA D1–D9 42176772883 SUCCESS, original Stage1 42176772872 SUCCESS, Names 42176772880 SUCCESS. D10 aceptita. D11 16..20 exact BI production extension and independent 1..20 normative oracle; four planned cases/twenty assertions; separate bounded Native CI. D11 NOT Native accepted until same-SHA D1–D10, Stage1, Names and D11 completed log evidence. No main/merge, LAST_COMPLETED_STAGE=1.

## Discovery11 static readback correction before Native evidence (2026-11-06)
Readback of original D11 candidate b953cd5e69c7aa5e89ee4c8e973e3568c156ddb0 detected test output field mistakenly read as visibleFifteen, not visibleTwenty; CI job identifier still said discovery-10. Targeted fix only to D11 test and D11 workflow job identifier. No observed Native failure is claimed; D11 acceptance PENDING, four cases/twenty checks unchanged. Original D10 production, oracle, tests and prior accepted evidence untouched.
