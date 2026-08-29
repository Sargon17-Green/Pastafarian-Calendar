# Calendarium Pastafarianum — linea C++ et Neo-Latina

Hoc directorium Gradum 7 evolutionis continet. Linea implementationis ab initio condita est ex solo specimine normativo in mandato incluso. Nulla implementatio aliena, nullum output alienum, nullus hash alienus et nulla probatio differentialis trans implementationes adhibita est.

## Status praesentis gradus

Gradus 7 est `PATCH 03`. Vitium Gradus 6 non deletum est:

```text
oldDistance(cDay, tDay) = abs(dayTagWithFoundationScar(cDay) - dayTagWithFoundationScar(tDay))
```

`oldDistance` adhuc eundem exitum historicum reddit et per viam diagnosticam separatim exerceri potest.

Super eam addita est emendatio localis:

```text
d = oldDistance(cDay, tDay)
chronological = abs(tDay - cDay)
si d != chronological: d = chronological
distance = d + 1
```

Functio concreta est `distanceWithChronologicalPatch`. Via auctoritaria huius gradus transit per `BaseMonsterManager::executeDistance`, `BaseDispatcher::dispatchPatchedDistance`, `Patch03DistanceHandler`, `LegacyDistanceAdapter` et `Patch03DistanceWrapper`.

Status huius gradus est `GREEN`.

## Cicatrix legacy servata

`Patch03DistanceHandler` primum `oldDistance` re vera vocat et exitum eius in `legacyDistanceOutput` servat. Tantum post hanc vocationem wrapper distantiam chronologicam computat. `executeUnpatchedDistanceDiagnostic` adhuc viam `Discovery03DistanceHandler` exercet et exitum legacy incorreptum reddit.

Probatio Gradus 7 manifeste confirmat exempla historica:

```text
oldDistance(FOUNDATION, FOUNDATION) = 0
oldDistance(FOUNDATION+1, FOUNDATION+3) = 4
oldDistance(FOUNDATION-1, FOUNDATION+1) = 1
```

Ita cicatrix physice et exsecutabiliter manet.

## Cur patch normae aequivalet

Norma distantiam operis definit ex axe dierum ipso:

```text
abs(targetDay - calculationDay) + 1
```

Wrapper primum exitum legacy recipit. Deinde `chronological = abs(targetDay - calculationDay)` computat. Si legacy discrepat, valor legacy localis eodem `chronological` superatur; si iam concordat, manet. Post utrumque ramum unum additur. Ergo exitus semper est exacte distantia chronologica inclusiva normativa.

`BaseValidationManager::requirePatch03Ready` eandem aequivalentiam copia validationis separata verificat. Haec copia tantum errorem invariantiae iacere potest; non est fallback neque fons alterius responsi.

## Correctio auditum temporalium priorum

Regressiones Graduum 5 et 6 continebant prohibitiones temporales contra codicem PATCH 03, quia in illis gradibus patch futurum erat. Post adventum Gradus 7 illae prohibitiones iam invariant perpetua esse non possunt.

- In probatione Gradus 5 remotum est solum auditum qui nomina `Patch03`/`patch03` vetabat. Assertiones PATCH 02, duo custodes Fundationis et omnes valores normativi manent intacti.
- In probatione Gradus 6 auditum futurum substitutum est assertione perpetua quae praesentiam physicam `oldDistance` requirit. Eadem inputs et eadem expected values manent.

Forma correcta regressionis Gradus 6 contra codicem Gradus 6 pristinum separatim probata est et adhuc quinque discrepantias cum exitu `1` produxit. Ergo mutatio probationis vitium historicum non abscondit.

## Stratum monstri additum

Gradus 7 addit:

- `patchedDistanceOutput` et `patch03Applied` in contextu invocationis;
- `Patch03DistanceWrapper`;
- `Patch03DistanceHandler`;
- dispatchationem propriam patch;
- viam diagnosticam legacy separatam;
- `requirePatch03Ready` cum computatione validationis duplicata;
- memoriam exitus legacy in relatione etiam post correctionem.

State semanticum manet proprium invocationi. Metrics et branch trace non leguntur ad decisionem normativam.

## Lingua computationis

Omnis codex exsecutus huius lineae est C++. Integra arbitraria per `boost::multiprecision::cpp_int` tractantur. Nullus interpres externus, FFI, runtime alienus aut generator in alia lingua adhibetur.

## Catalogus linguae fontis

Catalogus Neo-Latinus in `include/pastafari/source_language_catalog.hpp` congelatus manet. Ordo normativus per `canonicalIndex` tantum definitur; textus linguae fontis non participat ranking, unranking, cache semanticum aut electionem.

## Probationes

Omnes regressiones usque ad Gradum 7 virides sunt:

```text
OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT
REGRESSIO_DISCOVERY_01_TRANSIIT
REGRESSIO_PATCH_01_TRANSIIT
REGRESSIO_DISCOVERY_02_TRANSIIT
REGRESSIO_PATCH_02_TRANSIIT
REGRESSIO_DISCOVERY_03_TRANSIIT
REGRESSIO_PATCH_03_TRANSIIT
```

Gradus proximus est `DISCOVERY 04`; nullum eius codicem hic gradus continet.
