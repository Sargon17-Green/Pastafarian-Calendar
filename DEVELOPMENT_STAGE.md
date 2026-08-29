# Statu del developation

```text
TOTAL_STAGES=55
CURRENT_STAGE=17
CURRENT_KIND=PATCH
CURRENT_PATCH=08
LAST_COMPLETED_STAGE=17
EXPECTED_REPOSITORY_STATE=GREEN
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=JavaScript
NATURAL_LANGUAGE=Interlingue / Occidental
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Li infrastructura e scars precedent, li caller one-based defectiv de Discovery 08, e Patch08PermutationWrapper quel conserva li chain oneBased -> legacyRank0=oneBased-1 -> oldPermutationUnrank0.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=NO
GIT_HISTORY_MUTATED=NO
HANDOFF_PACKAGE_PREPARED=YES
```

Stage 17 es finit quam **PATCH 08**. `oldPermutationUnrank0(rank0)` e `legacyBowlOrderFromDrop(drop)` resta sin modification, ergo li scar one-based continua directmen observabil. Li nov `orderPatchFromValue(value)` conserva intentionalmen li chain `oneBased = regularMod(value-1,720)+1`, `legacyRank0 = oneBased-1`, `oldPermutationUnrank0(legacyRank0)`.

Li route historic passa per `Discovery08PermutationRankHandler` e poy `Patch08PermutationWrapper`. Li context conserva li ordinal one-based, li rank0 traductet e li output reparat. Li regression de Stage 16 es verd durant que li caller legacy resta defectiv. Null `bowlAlias` o code de Patch 09 o posterior es present.
