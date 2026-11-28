# Stage02 historical source-lock reconciliation — 2026-11-28

PROJECT_ID: PC-BRANCH-SQL-TAMIL. Branch: SQL+தமிழ். Audited production baseline: c536ab40e01ec6d2ff8de1ee23b909b052064550. This is static evidence reconciliation, NOT a new Native or differential result, NOT global Stage02 acceptance.

## Method and reproducible source map

Read the 22 historical Native reports in this directory and compared each tested source SHA with the live baseline using the GitHub compare endpoint (22/22 ahead, zero behind; 109–254 changed paths, below 300). Independently read the complete recursive Git trees at all 22 source SHAs and the baseline; compared each numbered top-level production SQL blob and normative reference blob by exact path and SHA. All historical existing production files equal the baseline except the three exceptions listed below. For each mapped slice n, historical numbered SQL files 00 through n+2 are present; all later numbered files are additions, not changes to historical sources. Normative blob ce17bf6fd166451b6904411c5e29d1b26d92e278 is identical in 22/22 trees. This does not rehash historical artifact bytes or rerun their jobs; counts are transcribed from prior original-log/ZIP reports. Slice1 report explicitly did not independently recompute its ZIP digest.

| Slice | Tested source commit | Historical report | Reported Native / isolation / differential | Modified pre-existing production files |
|---|---|---|---|---|
| 1 | 8dbe132b175a5d464ee64612d550a11d23177404 | [CI_41032411855](POSTGRESQL_NATIVE_CI_41032411855.md) | 37/4/— | none |
| 2 | 2ff10689af6305160070e530b2d8809fe8fee734 | [STONES_41040652056](POSTGRESQL_NATIVE_STONES_41040652056.md) | 23/4/— | none |
| 3 | 92ddc5b4fa1ccbd89405ea55b07ea4779674b3d0 | [HIDDEN_41087167102](POSTGRESQL_NATIVE_HIDDEN_41087167102.md) | 38/4/28 | none |
| 4 | 114e185adde2a0d7feeaac57d9bb7fa8ac00323e | [VISIBLE_41091834656](POSTGRESQL_NATIVE_VISIBLE_41091834656.md) | 51/4/184 | 06 |
| 5 | — | Not located | unresolved | unknown |
| 6 | — | Not located | unresolved | unknown |
| 7 | 3245ab144331d2dd5ab4ae1d38ac261b3241525f | [POST_STIR_41117852743](POSTGRESQL_NATIVE_POST_STIR_41117852743.md) | 62/4/306 | 06,08 |
| 8 | eb3521ce4eb4b69b57d671a17922d7f632c60702 | [SAUCE_41136575671](POSTGRESQL_NATIVE_SAUCE_41136575671.md) | 34/4/42 | 06,08 |
| 9 | 6f10dc43171db6ab0989a15b661de47a29a1a3cd | [ANSWER_STREAM_41179677850](POSTGRESQL_NATIVE_ANSWER_STREAM_41179677850.md) | 44/4/28 | 06,08 |
| 10 | 7746a3e086bd71e23fd9ea117b2960a37f145998 | [CHOOSE_RANK_41184465569](POSTGRESQL_NATIVE_CHOOSE_RANK_41184465569.md) | 100/4/62 | 06,08 |
| 11 | 9ee775d8a1487efb83a7cb383f872de3e99c913d | [GATE_GAPS_41193117807](POSTGRESQL_NATIVE_GATE_GAPS_41193117807.md) | 32/4/12 | 06,08 |
| 12 | b16e4893d37dced05885ee2dcc52138c63dbc804 | [GATE_SELECTOR_41197009920](POSTGRESQL_NATIVE_GATE_SELECTOR_41197009920.md) | 26/4/14 | 06,08 |
| 13 | 95ade2e3cf48bda4026de5148d0d8dc699ad9c31 | [YEAR5000_GATE_CANDIDATES_41211362509](POSTGRESQL_NATIVE_YEAR5000_GATE_CANDIDATES_41211362509.md) | 35/4/14 | 06,08 |
| 14 | 9826aa2913c06dd35c222db63398efbc4989fe37 | [YEAR5000_SLICE14_41238928425](POSTGRESQL_NATIVE_YEAR5000_SLICE14_41238928425.md) | 23/4/25 | 06,08,16 |
| 15 | be0cf1983e8dd4037ba3d35a8e20fc1030ef3722 | [ADJACENT_YEAR_SLICE15_41245801827](POSTGRESQL_NATIVE_ADJACENT_YEAR_SLICE15_41245801827.md) | 36/4/4 groups | 06,08,16 |
| 16 | d6c0c3e05d371c5d04a8ef300149da8bf06fc07d | [TARGET_YEAR_41283131434](POSTGRESQL_NATIVE_TARGET_YEAR_41283131434.md) | 18/4/5 groups | 06,08,16 |
| 17 | c13209e05602b1706fd6ce97533d7b62d33e7df4 | [CUTLET_COUNT_41350490055](POSTGRESQL_NATIVE_CUTLET_COUNT_41350490055.md) | 20/4/4 | 06,08,16 |
| 18 | 513c252d5654ec9f7274283aa88d9fcf8d78cca5 | [CUTLET_PARTITION_41523792140](POSTGRESQL_NATIVE_CUTLET_PARTITION_41523792140.md) | 14 jobs; see report | 06,08,16 |
| 19 | e216dde0b80c0a85607af97413039ccf2316d811 | [CUTLET_NAMES_41618421392](POSTGRESQL_NATIVE_CUTLET_NAMES_41618421392.md) | 42/4/8 | 06,08,16 |
| 20 | 9a65e3ef86f174bb68389420334c6c93858a3fad | [MONTH_COUNT_41714259445](POSTGRESQL_NATIVE_MONTH_COUNT_41714259445.md) | 36/4/8 +50 goldens | 06,08,16 |
| 21 | 837ec975e81ff96889ade43762f314ba817f94ae | [MONTH_LENGTHS_41871310680](POSTGRESQL_NATIVE_MONTH_LENGTHS_41871310680.md) | 43/5/8 +50 goldens | 06,08,16 |
| 22 | 91cb0e9ff837f8c823f7cdaa8a1992f09367f424 | [MONTH_WEAVING_42126854985](POSTGRESQL_NATIVE_MONTH_WEAVING_42126854985.md) | 59/8/8 | 06,08,16 |
| 23 | d61dfbeef318ea7d73f86bb9703c00eb771bb77e | [MONTH_NAMES_42177386297](POSTGRESQL_NATIVE_MONTH_NAMES_42177386297.md) | 96/11/8 | 06,08,16 |
| 24 | 4c71d677eb382eea55eeae2d3ac8da99760d2bd5 | [YEAR_STRUCTURE_44364076198](POSTGRESQL_NATIVE_YEAR_STRUCTURE_44364076198.md) | 232 incl isolation /72 diff | 06,08,16 |

### Exact modified blobs (old -> baseline)
- 06_stage02_visible_drops.sql: 2cc67c27b1f5e0c2f22537e479e42956a5711b9e -> caf2991b2ae89f99074d80814655d162f6c68b78
- 08_stage02_bowl_round.sql: 68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6 -> f84f0ac6c2b570aa3ef61038247a44e602014534
- 16_stage02_year5000.sql: e09afd9bb99a2a576a5bd5808b350d161072e124 -> b2fd62c17b133c639f8751fe2eaa03e93ae167f5

## Dependency triage (source-level; not a complete dynamic call graph)
Read exact baseline SQL 07 and 09–26; extracted schema-qualified function definitions/calls. Existing file changes do not automatically invalidate a test of a function whose transitive callable dependencies remain unchanged.
- Slices1–3: all pre-existing numbered production blobs identical. Preserve historic scope, not a fresh runtime result.
- Slice4 visible drops: changed 06; Slice6 bowl_round: changed 08. Existing recorded stone-reuse run 45900542068 at 3b8121ecd0eb8820d9af55c0d562150cdff003b6 compares 3772+3496 drops/rounds; scope and exact blob identity to baseline must be carried into the gap ledger rather than replaying.
- Slice5 bowls: 07 defines bowl_factorial, bowl_order_from_number, bowl_order_from_drop, initial_bowls; references regular_mod/save_value (03); no call to 06/08 in direct supplied-input path. Slice7 post_stir_round -> 03/07; no 06/08. Slice9 answer stream -> 03; Slice10 choose_rank -> 03/11. Slice13 gate-pair enumeration/pick -> own functions only. These are candidates for historical direct-call evidence transfer, subject to checking old harness and type/DDL dependencies.
- Slice8 sauce -> 03/06/07/08/09, affected. Slices11 gate_gap_signed -> sauce/choose_rank/ask_bowl/foundation_day; 12 gate_day/selectors -> 11/03; 14 year5000 -> 16/15/12/11/10; 15 adjacent_year -> 11/10/12; 16 find_target_year -> 16/17. Real composition paths affected, not all synthetic subtests. Prior eight fast-window jobs 44828306955 and original artifact audit address bounded window selector; prior record documents exact function equality and remaining scope limitations.
- Slice17 cutlet_count -> 11/12; Slice19 cutlet_names -> 11/12; Slice20 month_count -> 11/12; Slice21 month_lengths -> 11/12; Slice22 weaving -> 11/12; Slice23 names -> 11/12. Direct supplied-sauce numeric paths need harness/type lock check; they do not call sauce() themselves. Slice18 cutlet_partition -> 19/14/12/11, so exact_gate_index path reaches changed sauce. Slice24 build_year_structure -> sauce and all seven structure selectors; affected through 06/08 and indirect gate selection. Slice25 integration depends on find_target_year, build_year_structure, gate_day and source_name.
- This is lexical function-call extraction, not catalog dependency closure; composite type declarations, SQL search path, implicit casts and test harness call sites must be checked before any final transfer decision. No new expected-red or observed mismatch.

## Reconstructed bounded contract (not new policy)
The committed Slice25 calendar_date contract requires numeric calculation/target day -> typed five fields (year number, Tamil cutlet name, positive cutlet ordinal, Tamil month name, positive month ordinal), STRICT null semantics, distinct text result type without replacing legacy index result, independent ordinal oracle, at least 24 reachable inputs over >=8 years, boundary/occurrence coverage, >=40 native assertions, >=8 fresh isolation checks, >=24 full typed differential comparisons, bounded PG17 jobs (15min) with source/ZIP/log provenance. Existing exact matrix 45948648426, closure subset 46034295580, real-sauce 46072082194 remain accepted in their recorded scopes; no rerun. This reconstruction is a necessary bounded integration contract, not proof that the global Stage02 governance contract is complete. Existing development-stage metadata remains Stage1; no promotion.

## Residual action
1. Recover Slice5/6 exact tested SHAs, run/job/log/artifact from the two known workflow paths (.github/workflows/sql-tamil-stage02-bowls-native.yml and sql-tamil-stage02-bowl-round-native.yml). Workflow-specific run-list request was rejected by the connector; use targeted historical commit/run retrieval instead, not a broad Drive scan. Absence of an MD report is not evidence of failure.
2. Verify exact source-lock/dependency and harness correspondence of recorded stone-reuse, fast-window, full matrix and real-sauce gates against baseline, then classify uncovered changed-source cases only. If historical coverage is not transferable, define the smallest independent bounded PG17 regression with locked inputs, actual/oracle values, source locks, isolation and original ZIP/exit evidence.
3. Reconcile the existing global Stage02 acceptance/governance contract including any legacy public entrypoint requirement; do not infer a new implementation stage. Stage02 NOT ACCEPTED. No production modification, new run, duplicate dispatch, main, merge, release or user execution in this audit.
