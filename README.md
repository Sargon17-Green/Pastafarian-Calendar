# Pastafari Calendar — Logo / Ido — Stage 1

Ca repository esas nova, sendependa implemento komencita de zero. Nula antea repository esas supozita. La sola programlinguo dil linio esas Logo, e la sola homala fonto-linguo esas Ido.

Stage 1 kontenas nur la neutrala fundamento permisesita por Bootstrap:

- frozita `SourceLanguageCatalog` kun 17 koteleto-nomi e 47 monato-nomi;
- stabila `canonicalIndex` kom sola normativa nom-ordino;
- exakta entjero-subteno sen floating-point kalkulo;
- pura test-only normativa referenco derivita nur de Appendix A;
- nova Stage-1 test-harness en Logo;
- neutrala per-invocation `MonsterContext`-shelo;
- baza dispatcher, validigilo, eroro-limito, mezuro e logado.

Nula legacy-defekto o fliko 01–26 esas en la production-vojo. Nula future-stage flag, cache, ghost, latch, detour o compatibility-vojo esas introduktita.

La production-proceduro `calendarDateSpaghetti` ne vokas la oracle. En Stage 1 ol intence ne produktas kalendarala kvinoplo; ol nur konstruktas e validigas la neutrala invocation-contexto.

## Strukturo

- `src/exact_integer.logo` — exakta entjero-aritmetiko necesa por la normativa domeno.
- `src/source_language_catalog.logo` — la frozita Ido-katalogo.
- `src/monster_bootstrap.logo` — la neutrala production-shelo.
- `test/normative_reference.logo` — pura normativa test-only referenco.
- `test/stage01_tests.logo` — Bootstrap-testi.
- `SOURCE_LANGUAGE_CATALOG.md` — dokumento pri traduko, translitero e canonicalIndex.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md` — historio nur til la reale atingita etapo.
- `DEVELOPMENT_STAGE.md` — mashin-lektebla etapa stato.
- `HANDOFF_STAGE_01.md` — Stage-1 transdono al mantenanto.

## Lokala testo

La destinita dialekto esas Berkeley Logo / UCBLogo-kompatibla Logo. De la repository-radiko, la atendata komando esas:

`logo test/stage01_tests.logo`

La atendata fina lineo esas:

`STAGE_1_TESTI_PASIS`

En la aktuala livera medio nula Logo runtime esas disponebla. Pro to la testi ne povis esar rulita. Nula altra programlinguo esis uzita kom substituto.

## Etapa limito

Stage 2 ne komencez til la Stage-1 Logo-testi esas reale rulina e verda. La fakto ke ca repository komencas de zero esas normala e ne esas blokilo.
