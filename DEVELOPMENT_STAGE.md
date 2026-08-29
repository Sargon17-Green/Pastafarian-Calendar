# Statu del developation

```text
TOTAL_STAGES=55
CURRENT_STAGE=46
CURRENT_KIND=DISCOVERY
CURRENT_PATCH=23
LAST_COMPLETED_STAGE=46
EXPECTED_REPOSITORY_STATE=EXPECTED_RED
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=JavaScript
NATURAL_LANGUAGE=Interlingue / Occidental
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Li infrastructura e scars precedent, plus legacyMaterializeMonthLengthWays, LegacyMonthLengthAllWaysAPI e Discovery23MonthLengthMaterializationHandler quel expone li old contract de un Array concret con omni vias e executa un sondage capat sur li request semantic por demonstrar li risc de materialisation sin provocar OOM.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=NO
GIT_HISTORY_MUTATED=NO
HANDOFF_PACKAGE_PREPARED=YES
```

Stage 46 es finit quam **DISCOVERY 23**. Li repository local es intentionalmen `EXPECTED_RED` solmen por li nov regression de month-length materialization.

Li scar nov `legacyMaterializeMonthLengthWays(totalDays,monthCount)` expone li assumption historic: li API retorna un `Array` concret contenente omni compositions legal de longores de mensus, con chascun longore inter 4 e 123 e li summa egal al longore del year. `LegacyMonthLengthAllWaysAPI.allWays` conserva exactmen ti contract e ne contene null backend virtual.

`Discovery23MonthLengthMaterializationHandler` veni pos `RepeatedNamePatchWrapper`. It deriva li longore semantic del year, selecte li month count ex bowl 3 / seal 30 per li dispatcher ja reparat, conserva anc li answer ring de bowl 3 / seal 31, e executa li sam enumerator concret quam un sondage diagnostic capat a 2048 rows. Li cap existe solmen por impedir un OOM durant Discovery; it ne es un representation semantic nov e ne calcula li count complet.

Li witness have year length `1000`, limites 9..47 mensus e month count selectet `16`. Li sondage materialisa 2048 rows e prova que plu rows existe. Li reference test-only conta exactmen `5239332298078798668173613753510` compositions legal. Ti count demonstra que li contract old "omni vias quam Array concret" ne es materialisabil securmen.

`VirtualLegacyList`, exact DP count production e exact lexicographic `itemAt1` ne es present. Null code de Patch 23, `legacyChooseEachDaySeparately` o Patch 24 es includet.
