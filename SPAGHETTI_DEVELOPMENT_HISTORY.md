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
