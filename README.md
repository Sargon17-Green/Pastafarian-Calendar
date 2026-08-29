# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium gradum 3 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nullus codex, nulla probatio, nullum datum ex alia implementatione adhibitum est.

## Status praesentis gradus

Gradus 3 est `PATCH 01`. Functio historice vitiosa `oldRemainder(x)` integra et callable manet atque residuum Euclideum ordinarium modulo `M_OLD` reddit. Ea consulto non correcta est.

Super eam addita est functio `savePatch(x)`. Haec primum `oldRemainder(x)` vocat; si residuum zerum est, valorem ad `M_OLD` mutat; aliter residuum legacy intactum relinquit. Via productionis transit nunc per `BaseMonsterManager`, `BaseDispatcher`, `Patch01RemainderHandler`, `LegacyArithmeticAdapter` et `Patch01SaveWrapper`.

Regressio Gradus 2 nullo modo mutata est. Eadem probatio, quae in Gradus 2 consulto rubra erat, nunc viridis fit quia via productionis emendationem super legacy applicat. Probationes Bootstrap etiam virides manent.

Oracle normativum ad probationes tantum in `tests/reference/` positum est. Pars productionis oraculum non vocat.

## Cur emendatio exacte aequivalet

Pro omni integro `x`, `oldRemainder(x)` residuum Euclideum in intervallo `0..M_OLD-1` reddit. Regula normativa `SAVE(x)` idem residuum servat, sed classi residui zerum repraesentantem valorem `M_OLD` attribuit. Ergo sola discrepantia est `r == 0`; substitutio `M_OLD` in illo solo casu exacte `SAVE` reddit.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Ad numeros integros sine limite finito adhibetur `boost::multiprecision::cpp_int`, bibliotheca C++ ex solis capitibus constans. Nullus interpres externus nec runtime alterius linguae requiritur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus semper per `canonicalIndex` definitur; textus Neo-Latinus non participat sortitionem, gradum, cache semanticum aut unranking.

## Aedificatio et probationes

Ex radice directorii:

```text
g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. tests/bootstrap_tests.cpp tests/reference/normative_reference.cpp src/monster.cpp -o build/bootstrap_tests
./build/bootstrap_tests . tests/fixtures/bootstrap_expected.tsv

g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. tests/stage_02_discovery_01_tests.cpp tests/reference/normative_reference.cpp src/monster.cpp -o build/stage_02_discovery_01_tests
./build/stage_02_discovery_01_tests

g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. tests/stage_03_patch_01_tests.cpp tests/reference/normative_reference.cpp src/monster.cpp -o build/stage_03_patch_01_tests
./build/stage_03_patch_01_tests
```

Exitus exspectati:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
```
