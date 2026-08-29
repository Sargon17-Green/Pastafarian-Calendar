# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 7 de 55: PATCH 03**. Li scars de `oldRemainder`/Patch 01 e `oldDayTag`/Patch 02 resta intact e testabil. `oldDistance(calculationDay, targetDay)` resta anc intentionalmen defectiv: it mesura li diferentie inter tags. Li nov detour cronologic ne modifica ti function.

Li path real passa per `LegacyDistanceAdapter`, `Discovery03DistanceHandler` e `Patch03DistanceWrapper`. Li wrapper calcula li distance cronologic absolut, substitue li valore legacy si necessi e adjunte poy li unit inclusiv. Li context conserva ambi versiones e li decision de substitution. Li repository es **GREEN**.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; `patchedCounts` e null defect de stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ usa `BigInt`. Null floating-point es usat por SAVE, rangs, counts, gates, annus, compositiones o intertexes. `M = 2^127 - 1` es representat exactmen. Counts combinatori posse crescer ultra `M` sin truncation.

## Tests

Li suite precedent, includente li regression original de Discovery 03 tra li patch actual, deve restar verd:

```text
npm run test:previous
```

Li commande principal es nu verd:

```text
npm test
```

Por executar solmen li prova nov de Patch 03:

```text
npm run test:patch-03
```

Li tests confirma que `oldDistance` resta defectiv e que `distanceWithChronologyDetour` es equivalent al `distance` de `workCounts` sur un gril exhaustiv circum li Foundation e sur cases lontan. Li correction usa exactmen li ordine historic: legacy, comparation con li distance cronologic, substitution si necessi, poy `+1`.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.
