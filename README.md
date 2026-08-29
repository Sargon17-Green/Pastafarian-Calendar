# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 12 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 12 est `DISCOVERY 06` et consulto `EXPECTED_RED`. Quinque emendationes anteriores integrae et virides manent. Hoc gradu introducitur helper legacy ad historiam guttarum visibilium:

```text
legacyPrior(dropStore, i, back) = dropStore[i-back]
```

Semantica eius veteris contractus stricte limitatur ad indices iam visibiles `1..i-1`. Si `i-back < 1`, helper errorem mittit. Quare in prima gutta visibili, ubi `i=1`, petitiones `back=1..7` nullum indicem visibilem habent et omnes septem reiciuntur.

Via activa huius gradus transit per:

```text
BaseMonsterManager::executePrior
-> BaseDispatcher::dispatchLegacyPrior
-> Discovery06PriorHandler
-> LegacyPriorAdapter
-> legacyPrior
```

`calculationDay` et `targetDay` iam per contextum huius viae transeunt, sed handler DISCOVERY 06 eis ad guttas occultas resolvendas consulto non utitur. Hoc spatium necessarium est ut PATCH 06 postea supplementum ad historiam occultam supra eundem helper legacy addere possit sine helper veteri delendo.

## Quid regressio demonstrat

`tests/stage_12_discovery_06_tests.cpp` duas proprietates distinguit.

Primum, helper legacy in historia visibili recte operatur. Cum `dropStore = [101,202,303]` et `i=4`, petitiones `back=1,2,3` valores `303,202,101` reddunt. Petitio `back=4` recte reicitur quia index prior iam non est inter `1..i-1`.

Deinde probatio eadem computatione diei utitur qua Gradus 10–11 septem guttas occultas normativas iam habent. Pro `i=1`, omnis petitio `back=1..7` semantice correspondet `hidden1..hidden7`. `legacyPrior` autem septies errorem mittit:

```text
DISCREPANTIA PRIOR_OCCULTUS back=1 ... actualis=NON_RESOLUTUS
...
DISCREPANTIA PRIOR_OCCULTUS back=7 ... actualis=NON_RESOLUTUS
REGRESSIO_DISCOVERY_06_DEFECIT: 7 petitiones historiae occultae a helper legacy non resolutae sunt
```

Exitus est `1`, sicut gradus DISCOVERY postulat. Forma probationis iam PATCH-compatibilis est: si via activa postea omnes septem valores occultos recte resolvet, eadem probatio sine mutatione ad nullas discrepantias et transitum perveniet; helper `legacyPrior` directus tamen adhuc debet indices non visibiles reicere.

## Cicatrix legacy et stratum monstri

Additi sunt `VisibleDropStore`, `legacyPrior`, campi prioris in `BaseMonsterContext`, `LegacyPriorReport`, `LegacyPriorAdapter`, `Discovery06PriorHandler`, validatio `requireLegacyPriorReady` et dispatchatio separata.

Helper legacy non cognoscit `HiddenDrops`, non vocat `hiddenByNearness`, non aedificat guttas occultas et non habet ramum pro indicibus `0..-6`. Error eius est pars defectus historici observabilis.

Omne state semantically activum huic invocationi proprium manet. Metricae et trace tantum observant; exitum semanticum non eligunt.

## Quod consulto nondum adest

Nullum codicem PATCH 06 introduximus. Absunt `priorPatch`, `Patch06`, `patch06Applied` et omnis resolver qui, post defectum `legacyPrior`, guttam occultam eligat. Nulla mutatio formulae guttarum visibilium hoc gradu facta est.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Omnes regressiones usque ad Gradum 11 virides sunt. Regressio nova Gradus 12 est consulto rubra:

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
REGRESSIO_DISCOVERY_06_DEFECIT: 7 petitiones historiae occultae a helper legacy non resolutae sunt
```

Gradus proximus est `PATCH 06`; nullum eius codicem hic gradus continet.
