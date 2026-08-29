# Statu del developation

```text
TOTAL_STAGES=55
CURRENT_STAGE=18
CURRENT_KIND=DISCOVERY
CURRENT_PATCH=09
LAST_COMPLETED_STAGE=18
EXPECTED_REPOSITORY_STATE=EXPECTED_RED
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=JavaScript
NATURAL_LANGUAGE=Interlingue / Occidental
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Li infrastructura e scars precedent, plus legacyPoursToFixedBowlIds, LegacyFixedPourAdapter e Discovery09FixedPourHandler quel calcula li order reparat ma usa ancora bowl IDs fix 1,2,3 por li tri pours.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=NO
GIT_HISTORY_MUTATED=NO
HANDOFF_PACKAGE_PREPARED=YES
```

Stage 18 es finit quam **DISCOVERY 09**. `legacyPoursToFixedBowlIds(drop,index,oldBowls,stoneRow)` calcula li order exact per `orderPatchFromValue`, ma li tri pours continua leer `oldBowls[1]`, `oldBowls[2]` e `oldBowls[3]` quam si positions 1,2,3 esset bowl IDs fix.

Li defect es conectet a un path real de production tra `LegacyFixedPourAdapter` e `Discovery09FixedPourHandler`. Por un order identic li scar posse coincider accidentalmen; por drop 127 li order es `[2,1,4,3,5,6]` e li pours legacy `16163,16188,16242` diverge de `16167,16182,16252`. Li regression nov es intentionalmen rubi. Null `bowlAlias`, null correction de Patch 09 e null code posterior es present.
