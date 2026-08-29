# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 8 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 9 est `PATCH 04`. Vitium sequentiale Gradus 8 non deletum est: `mutateStonesWrong` eodem modo quinque partes eiusdem recordi ordine mutat et adhuc directe exerceri potest. Correctio super hanc cicatricem addita est, non intra eam.

`stonePatch(i, state)` primum snapshot immutatum `old` capit. Deinde `mutateStonesWrong(i, state)` re vera vocatur super copiam valoris; exitus eius in variabili `garbage` servatur. Tantum post hanc vocationem omnes quinque partes `garbage` denuo scribuntur formulis quae solum `old` legunt.

Via auctoritative huius gradus transit per:

```text
BaseMonsterManager::executeStoneTable
-> BaseDispatcher::dispatchPatchedStoneMutation
-> Patch04StoneMutationHandler
-> LegacyStoneMutationAdapter
-> buildStonesThroughWrongLegacyMutation       [cicatrix observabilis]
-> Patch04StoneSnapshotWrapper
-> buildStonesThroughLegacyBuilder
-> stonePatch
-> mutateStonesWrong                           [vocatio legacy realis]
-> overwrite quinque partium ex snapshot old
```

Via diagnostica `executeUnpatchedStoneTableDiagnostic` adhuc Gradum 8 exercet et tabulam sequentialiter contaminatam reddit.

## Quid regressiones demonstrant

Probatio `tests/stage_08_discovery_04_tests.cpp` eadem tabula normativa et eosdem indices ac Gradus 8 servat. Solum assertio de nomine handler/status dilatata est, quia metadata viae inter DISCOVERY et PATCH necessario mutatur. Forma haec contra productionem veterem Gradus 8 denuo probata est et adhuc exactly 224 discrepantias cum exitu `1` produxit.

Contra productionem Gradus 9 eadem regressio transit:

```text
REGRESSIO_DISCOVERY_04_TRANSIIT
```

Probatio nova `tests/stage_09_patch_04_tests.cpp` insuper confirmat:

- `mutateStonesWrong(2, initium)` adhuc a lapide normativo secundo discrepare;
- `stonePatch(2, initium)` cum norma congruere;
- builder reparatum omnes lapides 1–46 cum oraculo locali congruere;
- report productionis simul tabulam rectam et tabulam legacy ante patch servare;
- viam diagnosticam patch non applicare;
- in fonte apparere tum vocationem realem `mutateStonesWrong` tum overwrite quinque partium ex `old`.

## Cicatrix legacy et stratum monstri

Gradus 9 addit:

- `patchedStoneTable` et `patch04Applied` in `BaseMonsterContext`;
- `stonePatch` et `buildStonesThroughLegacyBuilder`;
- `Patch04StoneSnapshotWrapper`;
- `Patch04StoneMutationHandler`;
- dispatchationem PATCH 04 separatam;
- viam diagnosticam tabulae lapidum legacy;
- `requirePatch04Ready`, quae computationem quinque partium ex snapshot veteri separatim repetit ad validationem tantum;
- in `LegacyStoneTableReport` utramque tabulam, auctoritative rectam et legacy vitiosam.

Validatio duplicated exitum non eligit nec oraculum productionis vocat. Semantica provenit ex `stonePatch`; validatio solum invariantiam confirmat.

## Quod consulto nondum adest

Nulla logica DISCOVERY 05/PATCH 05 de septem guttis occultis, storage inverso aut `hiddenByNearness` introducta est. Ea ad gradus posteriores pertinet.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Regressiones usque ad Gradum 9 virides sunt:

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
```

Gradus proximus est `DISCOVERY 05`; nullum eius codicem hic gradus continet.
