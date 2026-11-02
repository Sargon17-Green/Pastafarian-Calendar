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
