# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 6 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 6 est `DISCOVERY 03`. Emendationes 01 et 02 integrae manent. Vitium novum legacy nunc in viam activam inductum est:

```text
oldDistance(cDay, tDay) = abs(dayTagWithFoundationScar(cDay) - dayTagWithFoundationScar(tDay))
```

Haec functio distantiam inter notas dierum computat, non distantiam chronologicam inclusivam quae norma requirit:

```text
abs(targetDay - calculationDay) + 1
```

Nulla correctio huius vitii hoc gradu adest. `patchedCounts`, `Patch03`, status specificus PATCH 03 et calculus `chronological` absunt.

Via activa transit per `BaseMonsterManager::executeDistance`, `BaseDispatcher::dispatchLegacyDistance`, `Discovery03DistanceHandler` et `LegacyDistanceAdapter`, donec ad `oldDistance` pervenit. `LegacyDistanceReport` exitum legacy separatim servat ut cicatrix in gradibus futuris probari possit.

Status huius gradus est `EXPECTED_RED`.

## Quid regressio nova demonstrat

Octo casus adhibentur. Tres casus fortuito cum norma concordant: duo dies adiacentes eodem latere Fundationis et transitus a Fundatione ad diem proximum posteriorem. Quinque casus discrepantiam manifestant:

```text
IDEM_FOUNDATION: 0 pro 1
IDEM_POST: 0 pro 1
DUO_POST: 4 pro 3
DUO_ANTE: 4 pro 3
TRANS_FOUNDATION: 1 pro 3
```

Ita vitium non est mera omissio constantis unius. Notae dierum ipsae iam normativae sunt post PATCH 02, sed earum differentia non est mensura chronologica dierum.

## Correctio auditus temporalis Gradus 5

Probatio PATCH 02 continebat auditum temporale quo etiam nomen `oldDistance` prohibebatur, quia in Gradus 5 nondum adesse debebat. In Gradus 6 `oldDistance` ipsum est legacy obligatorie introducendum; illa prohibitio igitur invariant perpetuum esse non potest.

Probatio Gradus 5 hoc gradu tantum in hac parte temporali contracta est: adhuc vetat `patchedCounts`, `Patch03` et `patch03`, sed iam non vetat `oldDistance`. Casus normativi, valores exspectati et omnes assertiones PATCH 02 manent idem. Regressio Gradus 5 post hanc correctionem transit.

## Stratum monstri additum

Gradus 6 addit:

- `legacyDistanceCalculationDay`, `legacyDistanceTargetDay`, `legacyDistanceOutput` et `legacyDistanceReady` in contextu invocationis;
- `LegacyDistanceAdapter`;
- `Discovery03DistanceHandler`;
- dispatchationem propriam distantiae;
- `LegacyDistanceReport` qui exitum activum et exitum legacy separatam servare potest.

Haec strata correctionem nondum faciunt. Tantum vitium legacy per viam realem exponunt et readiness determinant. Metrics et branch trace semanticam non mutant.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Gradus 1–5 virides manent. Regressio Gradus 6 consulto rubra est:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
REGRESSIO_DISCOVERY_02_TRANSIIT
REGRESSIO_PATCH_02_TRANSIIT
REGRESSIO_DISCOVERY_03_DEFECIT: 5 discrepantiae normativae inventae sunt
```

Hoc est status rectus pro `DISCOVERY 03`.
