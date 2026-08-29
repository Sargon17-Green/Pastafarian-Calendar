# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium gradum 2 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nullus codex, nulla probatio, nullum datum ex alia implementatione adhibitum est.

## Status praesentis gradus

Gradus 2 est `DISCOVERY 01`. Primus defectus historicus nunc re vera in productione adest: `oldRemainder(x)` residuum Euclideum ordinarium modulo `M_OLD` reddit. Via productionis transit per manager, dispatcher, handler et adapter arithmeticum legacy.

Emendatio huius defectus nondum adest. Propterea status totius gradus est `EXPECTED_RED`: regressio nova ostendit discrepantiam pro `M`, `2M` et `3M`, dum `M+1` concordat. Probationes Bootstrap Gradus 1 manent virides.

Oracle normativum ad probationes tantum in `tests/reference/` positum est. Pars productionis oraculum non vocat.

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
```

Exitus probationum Bootstrap exspectatus:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
```

Exitus regressionis novae exspectatus est defectus determinatus cum tribus discrepantiis normativis. Hoc rubrum est pars ipsa Gradus 2 et hoc gradu corrigi non debet.
