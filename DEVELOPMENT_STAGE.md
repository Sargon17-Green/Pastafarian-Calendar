# Statu del developation

```text
TOTAL_STAGES=55
CURRENT_STAGE=16
CURRENT_KIND=DISCOVERY
CURRENT_PATCH=08
LAST_COMPLETED_STAGE=16
EXPECTED_REPOSITORY_STATE=EXPECTED_RED
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=JavaScript
NATURAL_LANGUAGE=Interlingue / Occidental
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Li infrastructura e scars precedent, plus oldPermutationUnrank0, LegacyPermutationOrderAdapter e Discovery08PermutationRankHandler quel passa li ordinal one-based 1..720 directmen quam rank0 zero-based.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=NO
GIT_HISTORY_MUTATED=NO
HANDOFF_PACKAGE_PREPARED=YES
```

Stage 16 es finit quam **DISCOVERY 08**. `oldPermutationUnrank0(rank0)` es un helper legacy correct solmen por su contract zero-based `0..719`. Li caller historic calcula `oneBased = regularMod(drop-1,720)+1` e passa ti valore `1..720` directmen al helper quam si it esset rank0.

Li defect es conectet a un path real de production tra `LegacyPermutationOrderAdapter` e `Discovery08PermutationRankHandler`. Por drops con `oneBased` de 1 til 719, li resultate es desplazzat un permutation avan; `oneBased=720` es extra li contract fisic del helper. Li regression nov es intentionalmen rubi. Null `legacyRank0=oneBased-1`, null wrapper de Patch 08 e null `bowlAlias` o code posterior es present.
