# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 8 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 8 est `DISCOVERY 04`. Tres cicatrices priores cum emendationibus suis integrae manent. Hoc gradu vitium novum in fabricam lapidum introductum et in viam activam coniunctum est:

```text
mutateStonesWrong(i, S)
```

Functio quinque partes lapidis non ex uno statu veteri computat. Ipsa `S` ordine mutatur: triticum primum scribitur, hordeum deinde triticum iam novum legit, sal hordeum iam novum legit, amarum sal iam novum legit, et rubrum etiam valores huius ipsius transitionis mutatos legit.

`buildStonesThroughWrongLegacyMutation` hunc mechanismum re vera adhibet ad lapides 2–46. Via activa transit per:

```text
BaseMonsterManager::executeStoneTable
-> BaseDispatcher::dispatchLegacyStoneMutation
-> Discovery04StoneMutationHandler
-> LegacyStoneMutationAdapter
-> buildStonesThroughWrongLegacyMutation
-> mutateStonesWrong
```

Nulla correctio huius vitii adhuc adest. Status huius gradus est `EXPECTED_RED`.

## Quid regressio demonstrat

Probatio `tests/stage_08_discovery_04_tests.cpp` tabulam viae activae cum `buildStones()` oraculi localis eiusdem lineae comparat. Lapis 1 recte idem est, quia est semen immutatum. In lapide 2 pars prima etiam fortuito recta est, quia prima assignatio adhuc totum input vetus legit. Partes 2–5 autem statum intra eandem transitionem iam contaminatum legunt.

Exempla prima:

```text
i=2 pars=2: normativum 1073, legacy 1434
i=2 pars=3: normativum 2375, legacy 3780
i=2 pars=4: normativum 6195, legacy 9932
i=2 pars=5: normativum 10493, legacy 25047
```

A lapide 3 etiam prima pars discrepans fit, quia semen totius transitionis iam ex lapide 2 contaminato venit. In tota tabula 224 ex 230 componentibus inspectis post semen non congruunt.

Regressio consulto exitum `1` reddit. Hic rubor est conditio correcta DISCOVERY, non defectus regressionum priorum.

## Cicatrix legacy et stratum monstri

Gradus 8 addit:

- `Stone` et `StoneTable` ut state productionis huius cicatricis;
- `mutateStonesWrong` cum mutatione sequentiali;
- `buildStonesThroughWrongLegacyMutation`;
- `legacyStoneTable` et `legacyStoneTableReady` in `BaseMonsterContext`;
- `LegacyStoneMutationAdapter`;
- `Discovery04StoneMutationHandler`;
- dispatchationem propriam;
- `LegacyStoneTableReport`;
- validatorem readiness qui semen tantum confirmat, non vitium corrigit.

Omne state semanticum huius tabulae contextui invocationis proprium est. Metrics et branch trace observabilia sunt et in calculum lapidum non redeunt.

## Quod consulto nondum adest

Gradus 8 non continet snapshot veteris lapidis, vocationem legacy super clone cum overwrite tardivo, `stonePatch`, `Patch04` aut aliam correctionem mutationis sequentialis. Illa pertinent ad Gradum 9 tantum.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Regressiones usque ad Gradum 7 virides manent:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
REGRESSIO_DISCOVERY_02_TRANSIIT
REGRESSIO_PATCH_02_TRANSIIT
REGRESSIO_DISCOVERY_03_TRANSIIT
REGRESSIO_PATCH_03_TRANSIIT
```

Regressio nova consulto rubra est:

```text
REGRESSIO_DISCOVERY_04_DEFECIT: 224 discrepantiae componentium normativae inventae sunt
```

Gradus proximus est `PATCH 04`; nullum eius codicem hic gradus continet.
