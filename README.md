# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 13 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 13 est `PATCH 06` et status repository exspectatus est `GREEN`. Sex detectio prioris gradus ostendit `legacyPrior(dropStore,i,back)` tantum historiam visibilem `dropStore[i-back]` intellegere. Helper legacy ipse non mutatus est et pro indicibus conceptu occultis adhuc errorem mittit.

Emendatio nova contractum normativum sequitur:

```text
slot = i - back
if slot >= 1:
    return legacyPrior(dropStore, i, back)
hiddenK = 1 - slot
return hiddenByNearness(legacyHidden, hiddenK)
```

Hoc schema in `priorPatch` servatur. Nulla inversio array occultarum fit; `hiddenByNearness` ex PATCH 05 mapping `8-k` retinet.

## Via activa

`BaseMonsterManager::executePrior` nunc transit per:

```text
BaseMonsterManager::executePrior
-> BaseDispatcher::dispatchPatchedPrior
-> Patch06PriorHandler
-> Patch06PriorWrapper
-> priorPatch
```

Handler tabulam lapidum per viam productionis iam emendatam construit, deinde septem guttas occultas in repositione retrograda legacy fabricat. `priorPatch` eligens slot positivum ad `legacyPrior` redit; slot non positivum ad `hiddenByNearness` transit.

`executeUnpatchedPriorDiagnostic` viam `Discovery06PriorHandler -> LegacyPriorAdapter -> legacyPrior` integram servat. Sic cicatrix prioris gradus adhuc directe exerceri potest.

## Regressio Gradus 12

Probatio `tests/stage_12_discovery_06_tests.cpp` una mutatione harness indiguit: nomen handler et status Gradus 12 erant nimis stricte fixi ad viam DISCOVERY. Expected values, casus `back=1..7`, verificatio quod `legacyPrior` directus occultas reicit, et numerus discrepantiarum ante patch non mutati sunt.

Forma correcta contra productionem Gradus 12 pristinam adhuc exactas septem petitiones `NON_RESOLUTUS` et exitum `1` producit. Contra Gradum 13 eadem probatio nullas discrepantias producit et transit.

## Probatio PATCH 06

`tests/stage_13_patch_06_tests.cpp` separat cicatricem et exitum auctoritative:

- `legacyPrior` directus pro `i=1, back=1..7` adhuc reicitur;
- `priorPatch` pro iisdem septem casibus hidden1..hidden7 recte reddit;
- pro slot positivo `priorPatch` viam legacy servat;
- relatio productionis indicat utrum via legacy an via occulta adhibita sit;
- diagnosticum sine patch pro historia occulta adhuc deficit;
- petitio ultra septem occultas reicitur.

Omnes regressiones Graduum 1–13 transeunt.

## Quod consulto nondum adest

Nullum codicem DISCOVERY 07 aut PATCH 07 introductum est. Absunt sentinel tabulae molendi, `Patch07`, `patch07Applied` et omnis emendatio indexing molitionis futurae.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Semantica ordinis per `canonicalIndex` tantum definitur; textus presentationis computationem non mutat.

## Exitus probationum

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
REGRESSIO_DISCOVERY_02_TRANSIIT
REGRESSIO_PATCH_02_TRANSIIT
REGRESSIO_DISCOVERY_03_TRANSIIT
REGRESSIO_PATCH_03_TRANSIIT
REGRESSIO_DISCOVERY_04_TRANSIIT
REGRESSIO_PATCH_04_TRANSIIT
REGRESSIO_DISCOVERY_05_TRANSIIT
REGRESSIO_PATCH_05_TRANSIIT
REGRESSIO_DISCOVERY_06_TRANSIIT
REGRESSIO_PATCH_06_TRANSIIT
```

Gradus proximus est `DISCOVERY 07`; nullum eius codicem hic gradus continet.
