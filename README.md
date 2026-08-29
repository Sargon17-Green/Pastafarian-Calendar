# Calendare Pastafarian — JavaScript + Interlingue / Occidental

Ti directoria es un linea de implementation completmen independent. It ha esset creat de zero por li pare `JavaScript` + `Interlingue / Occidental`, solmen ex li specification normativ includet in li task. Null code, test, fixture, output, table generat, cache, log, hash o checksum de un altri implementation ha esset usat.

## Statu actual

Li linea es in **Stage 19 de 55: PATCH 09**. Omni scars e patches 01..08 resta intact e testabil. `legacyPoursToFixedBowlIds` conserva li assumption historic de bowl IDs fix 1,2,3, ma li nov `bowlAlias[position]=order[position]` traducte chascun position semantic al bowl ID current.

`poursThroughBowlAlias` voca realmen li legacy e passa omni read semantic de bowl por li tri pours tra `bowlAtLegacyPosition`. `Patch09BowlAliasWrapper` conserva li garbage legacy, li alias e li output reparat in li sam context. Null `vaultOld`, null `pending` e null code de Patch 10 existe in ti stage.

Li function final `calendarDateSpaghetti` resta intentionalmen ne implementat; null defect de stage posterior posse aparir ante su stage historic.

## Lingue-fonte canonic

`src/source-language-catalog.js` contene un unic `SourceLanguageCatalog` congelat. Li 17 nomes de cutlettes e li 47 nomes de mensus have indices canonic 1..17 e 1..47. Li órdine semantic usa exclusivmen `canonicalIndex`; textu, collation, Unicode e locales ne participa in selection, rank, unrank o cache semantic.

Nomes con signification lexical es traductet secun lor signification. Nomes de locs con form international stabil usa lor form international in Interlingue. Nomes inventet sin signification ne recive un signification artificial.

### Regul deterministic de transliteration

Por formes hebreic vocalisat, signes de vocalisation es resoluet in vocales `a e i o u`; consonantes es transliterat in lettres latines secun un table fonetic stabil, e marcas cantillatori ne es conservat. Por un form non-vocalisat u li scritura ne determina unicmen li pronunciation, li resultate es un entry explicit e congelat in li catalog; un tal entry ne posse esser recalculat per locale o collation. Por li du formes inventet del specification, li outputs congelat de Bootstrap es `Palgursh` e `Karshumb`. Ti decision es solmen presentation; lor `canonicalIndex` resta li unic identitá semantic.

## Exactitá numeric

Omni calcul normativ e historic numeric usa `BigInt`. Null floating-point es usat por SAVE, tags, distance o mutation de stones. `M = 2^127 - 1` es representat exactmen.

## Tests

Omni regressions precedent, includente Discovery 09 reparat per li route Patch 09, deve restar verd:

```text
npm run test:previous
```

Li test specific de Patch 09 deve esser verd:

```text
npm run test:patch-09
```

Li suite complet deve esser verd:

```text
npm test
```

Li verifier confirma que li helper legacy continua leer bowls fix 1,2,3, que li route semantic instala `bowlAlias` ex li order e que omni tri reads de pour passa tra ti alias. It confirma anc que null `vaultOld`, `pending` o code posterior contamina production.

## Independentie

Li reference normativ complet por tests trova se in `tests/normative-reference.js`. It ne es importat de production e ne posse servir quam fallback runtime. Null implementation extern, artefact cross-implementation, hash, checksum o differential cross-implementation es usat.

## Stage 11 — Patch 05

Li storage legacy del sett hidden drops resta fisicmen retrograd. `hiddenByNearness` adjunte exclusivmen li translator `8-k` por access semantic per proximity; it ne reverse, ne copie in ordine nov e ne elimina li scar de Discovery 05. `Patch05HiddenNearnessWrapper` registra li proximity demandat e li slot fisic usat durant li route historic. Li regression de Discovery 05 es nu verd.


## Stage 12 — Discovery 06

Li history legacy ne conosse li hidden drops. `legacyPrior(dropStore, i, back)` lee directmen `dropStore[i-back]`; por un slot positiv it posse trovar un visible drop precedent, ma por `0..-6` it ne traducte a hidden1..hidden7. `Discovery06PriorHandler` conserva ti failure intact in li route historic. Li correction `priorPatch` es reservat exclusivmen por Stage 13.

## Stage 13 — Patch 06

`legacyPrior` resta intact. `priorPatch` usa li call legacy real quand `i-back >= 1`; altrimen it mappa li slot non-positiv a `k = 1-(i-back)` e delega a `hiddenByNearness`. Li array hidden backward ne es reversat ni migrat. `Patch06PriorWrapper` conserva li scar e li decision de branch in li context. Li regression de Discovery 06 es verd.


## Stage 14 — Discovery 07

Li table historic de visible grinds es almacenat quam un array zero-based de undec rows, durante que li caller historic continua numerar grinds 1..11 e usa ti ordinal directmen quam index. Li data self es correct; li defect es exclusivmen li mismatch de convention de indices. `Discovery07GrindIndexHandler` conserva ti scar in li route production. Li sentinel reparativ de Patch 07 ne es present in ti stage.

## Stage 15 — Patch 07

`LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED` e `legacyGrindRow` resta intact quam scar historic. `GRIND_TABLE_WITH_SENTINEL` adjunte un slot permanent a index 0 e conserva li undec rows real in indices 1..11. `grindRowWithSentinel` usa ancora li ordinal one-based directmen quam index, e `Patch07GrindSentinelWrapper` conserva li output legacy e li reparat in li sam context. Li regression de Discovery 07 es nu verd sin deleter li sentinel.


## Stage 16 — Discovery 08

`oldPermutationUnrank0(rank0)` es congelat quam li helper historic de unranking por rank0 0..719. Li caller de Discovery 08 deriva `oneBased = regularMod(drop-1,720)+1` e passa ti ordinal directmen al helper, ergo rank 1 deven li duesim permutation in vice del prim, e talmen por omni valore acceptat. Li conversion `legacyRank0 = oneBased-1` apartene exclusivmen a Patch 08 in Stage 17.


## Stage 17 — Patch 08

`oldPermutationUnrank0` e `legacyBowlOrderFromDrop` resta intact quam scars historic. `orderPatchFromValue` conserva exactmen li bridge mandat `oneBased = regularMod(value-1,720)+1`, `legacyRank0 = oneBased-1`, poy voca li helper legacy con ti rank0. `Patch08PermutationWrapper` conserva li ordinal e li rank traductet in li context. Li regression de Discovery 08 es nu verd; li chain -1 ... +1 ... -1 ne es simplificat.


## Stage 18 — Discovery 09

Li order de bowls ja es reparat per Patch 08, ma li routine historic de pours ne usa ti IDs selectet. It tracta positions semantic 1,2,3 quam bowl IDs fisic 1,2,3 e lee directmen `oldBowls[1]`, `oldBowls[2]`, `oldBowls[3]`. `LegacyFixedPourAdapter` e `Discovery09FixedPourHandler` conserva ti mismatch. Li translator de Patch 09 resta reservat por Stage 19.


## Stage 19 — Patch 09

`legacyPoursToFixedBowlIds` resta intact quam scar historic. `installBowlAlias` fixa li relation `bowlAlias[position]=order[position]` por positions 1..6, e `bowlAtLegacyPosition` es li unic read semantic usat por li bowls del tri pours. `poursThroughBowlAlias` executa realmen li helper legacy ante li overwrite aliased; `Patch09BowlAliasWrapper` conserva li output legacy e li reparat. Li regression de Discovery 09 es nu verd sin introducter li snapshot/commit de Patch 10.
