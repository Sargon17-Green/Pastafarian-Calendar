# Statu del developation

```text
TOTAL_STAGES=55
CURRENT_STAGE=15
CURRENT_KIND=PATCH
CURRENT_PATCH=07
LAST_COMPLETED_STAGE=15
EXPECTED_REPOSITORY_STATE=GREEN
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=JavaScript
NATURAL_LANGUAGE=Interlingue / Occidental
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Li infrastructura e scars precedent, li table zero-based de Discovery 07, e Patch07GrindSentinelWrapper quel conserva li caller one-based per un sentinel permanent a index 0 e li undec rows real a indices 1..11.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=NO
GIT_HISTORY_MUTATED=NO
HANDOFF_PACKAGE_PREPARED=YES
```

Stage 15 es finit quam **PATCH 07**. `legacyGrindRow(grind)` resta sin modification e continua usar li ordinal 1..11 directmen contra li table zero-based, incluente `undefined` por grind 11. Li nov `GRIND_TABLE_WITH_SENTINEL` conserva un sentinel in index 0 e li undec rows real exactmen in indices 1..11.

`grindRowWithSentinel(grind)` conserva li convention one-based del caller e lee directmen ti table reparat. Li route historic passa per `Discovery07GrindIndexHandler` e poy `Patch07GrindSentinelWrapper`; li context conserva li output legacy, li index semantic/fisic, li sentinel e li output reparat. Li regression de Stage 14 es verd. Null `oldPermutationUnrank0` o code de Patch 08 o posterior es present.
