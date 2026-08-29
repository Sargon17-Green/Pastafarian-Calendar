# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium gradum 4 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nullus codex, nulla probatio, nullum datum ex alia implementatione adhibitum est.

## Status praesentis gradus

Gradus 4 est `DISCOVERY 02`. Emendatio prior `PATCH 01` integra et viridis manet: `oldRemainder(x)` adhuc cicatrix vitiosa est, dum `savePatch(x)` eam postea exacte corrigit.

Hoc gradu nova opinio historice falsa in productionem inducta est:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)
```

Functio `oldDayTag` consulto nondum correcta est. Via activa transit per `BaseMonsterManager`, `BaseDispatcher`, `Discovery02DayTagHandler` et `LegacyDayTagAdapter`, atque ipsum valorem legacy manifestum reddit.

Regressio nova cum `dayCount` oraculi localis comparat. In die Fundationis via legacy `0` reddit pro normativo `1`; uno et duobus diebus post Fundationem valores legacy respective `2` et `4` sunt pro normativis `3` et `5`. Uno et duobus diebus ante Fundationem viae concordant. Hic gradus igitur consulto `EXPECTED_RED` est.

Nulla emendatio `PATCH 02`, nullum incrementum pro parte posteriore, nullus custos specialis diei Fundationis hoc gradu adest.

Oracle normativum ad probationes tantum in `tests/reference/` positum est. Pars productionis oraculum non vocat.

## Quid nunc demonstratum est

Formula legacy distantiam a Fundatione recte duplicat, sed duplicatio sola signum lateris non continet. Pars ante Fundationem ex norma numeros pares accipit et cum formula legacy congruit. Dies Fundationis ipse atque pars posterior numeris imparibus egent; ibi formula legacy zerum vel numeros pares reddit et normam violat.

Haec discrepantia hoc gradu tantum detegitur. Correctio historica sequentis gradus nondum scripta est.

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

g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. tests/stage_04_discovery_02_tests.cpp tests/reference/normative_reference.cpp src/monster.cpp -o build/stage_04_discovery_02_tests
./build/stage_04_discovery_02_tests
```

Exitus exspectati trium regressionum priorum sunt virides:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
```

Regressio Gradus 4 consulto exitum `1` reddit et tres discrepantias normativas indicat. Hic est status `EXPECTED_RED`, non defectus inopinatus.
