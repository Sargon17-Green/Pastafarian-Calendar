# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium gradum 5 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nullus codex, nulla probatio, nullum datum ex alia implementatione adhibitum est.

## Status praesentis gradus

Gradus 5 est `PATCH 02`. Vitium Gradus 4 physice integrum manet:

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION_DAY_OLD)
```

Haec functio adhuc in die Fundationis `0`, uno die post `2`, duobus diebus post `4` reddit. Non correcta neque rescripta est.

Super eam addita est functio historica `dayTagWithFoundationScar`. Ea primum `oldDayTag(day)` re vera vocat; deinde, si dies non est ante Fundationem, unum addit. Custos secundus, consulto redundans sed historice obligatus, manet:

```text
n = oldDayTag(day)
if day >= FOUNDATION_DAY_OLD:
    n += 1
if day == FOUNDATION_DAY_OLD and n != 1:
    n = 1
```

Via productionis transit per `BaseMonsterManager`, `BaseDispatcher`, `Patch02DayTagHandler`, `LegacyDayTagAdapter` et `Patch02DayTagWrapper`. Handler primum valorem legacy captat, postea patch applicat, tum `BaseValidationManager` copiam validationis separatam computat antequam exitum patefaciat.

Via diagnostica `executeUnpatchedDayTagDiagnostic` adhuc per `Discovery02DayTagHandler` transit et valorem vitiosum `oldDayTag` sine emendatione reddit.

Status gradus est `GREEN`.

## Correctio structurae regressionis Gradus 4

Probatio Gradus 4 initio duas res simul faciebat: viam productionis exercebat, sed numerum discrepantiarum etiam ex vocatione directa `oldDayTag` deducebat. Talis forma non poterat umquam viridis fieri post patch, nisi ipsa cicatrix legacy deleretur, quod specimine vetatur.

Gradus 5 igitur structuram probationis corrigit, non valores exspectatos: eadem quinque dies et idem `dayCount` oraculi localis servantur, sed discrepantia ex exitu viae productionis metitur. Haec forma correcta contra codicem Gradus 4 pristinum separatim exsecuta est et easdem tres discrepantias cum exitus codice `1` invenit. Contra PATCH 02 eadem regressio viridis fit. Probatio nova Gradus 5 seorsum confirmat `oldDayTag` adhuc vitiosum esse.

## Aequivalentia localis PATCH 02

Pro die ante Fundationem `oldDayTag(day) = 2 * (FOUNDATION_DAY_OLD - day)`, quod iam est `dayCount` normativum; patch nihil addit.

Pro die Fundationis vel post eum `oldDayTag(day) = 2 * (day - FOUNDATION_DAY_OLD)`. Additio unius exacte seriem imparem normativam efficit. Custos secundus diei Fundationis post primam additionem non mutat valorem in via ordinaria, sed manet tamquam cicatrix historica obligata.

Ita `dayTagWithFoundationScar(day) == dayCount(day)` pro omni integro die.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Ad numeros integros sine limite finito adhibetur `boost::multiprecision::cpp_int`, bibliotheca C++ ex solis capitibus constans. Nullus interpres externus nec runtime alterius linguae requiritur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus semper per `canonicalIndex` definitur; textus Neo-Latinus non participat sortitionem, gradum, cache semanticum aut unranking.

## Aedificatio et probationes

Ex radice directorii:

```text
g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. -c src/monster.cpp -o build/monster.o
g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. -c tests/reference/normative_reference.cpp -o build/normative_reference.o
```

Singulae probationes deinde compilantur et cum duobus obiectis communibus conectuntur. Probationes exsecutendae sunt:

```text
./build/bootstrap_tests . tests/fixtures/bootstrap_expected.tsv
./build/stage_02_discovery_01_tests
./build/stage_03_patch_01_tests
./build/stage_04_discovery_02_tests
./build/stage_05_patch_02_tests src/monster.cpp
```

Exitus huius gradus:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
REGRESSIO_DISCOVERY_02_TRANSIIT
REGRESSIO_PATCH_02_TRANSIIT
```

Nullus codex `DISCOVERY 03` aut `PATCH 03` adest.
