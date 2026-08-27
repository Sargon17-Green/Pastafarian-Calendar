# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium primum gradum evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nullus codex, nulla probatio, nullum datum ex alia implementatione adhibitum est.

## Finis gradus primi

Gradus hic nondum continet vitia historica nec emendationes viginti sex posteriores. Pars productionis solum structuram generalem et neutralem praebet: contextum invocationis, dispatchatorem fundamentalem, validationem fundamentalem, involucrum errorum et testam metricarum. Haec structura nullam regulam futurae emendationis praescit.

Oracle normativum ad probationes tantum in `tests/reference/` positum est. Formulae normativae, portae, anni, segmenta, menses et textura mensium ibi directe ex Appendice A redduntur. Pars productionis oraculum non vocat.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Ad numeros integros sine limite finito adhibetur `boost::multiprecision::cpp_int`, bibliotheca C++ ex solis capitibus constans. Nullus interpres externus nec runtime alterius linguae requiritur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` est `constexpr` atque post hunc gradum immutabilis habendus est. Ordo normativus semper per `canonicalIndex` definitur; textus Neo-Latinus non participat sortitionem, gradum, cache semanticum aut unranking.

## Aedificatio et probationes

Ex radice directorii:

```text
g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. tools/generate_bootstrap_fixtures.cpp tests/reference/normative_reference.cpp -o build/generate_bootstrap_fixtures
./build/generate_bootstrap_fixtures tests/fixtures/bootstrap_expected.tsv

g++ -std=c++20 -O2 -Wall -Wextra -pedantic -Iinclude -I. tests/bootstrap_tests.cpp tests/reference/normative_reference.cpp src/monster.cpp -o build/bootstrap_tests
./build/bootstrap_tests . tests/fixtures/bootstrap_expected.tsv
```

Exitus exspectatus probationum:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
```
