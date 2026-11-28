# Canonical Stage02 DISCOVERY 01 — recovered contract and scope reconciliation

PROJECT_ID: PC-BRANCH-SQL-TAMIL
Date: 2026-11-28
Source HEAD: f7f75af9517be1cdcc1f6ebaa6fee543af4e5f88
Tree: d82e89b98d549784b42f44506f7421cc7d64f453

## Recovered authority
Original 06-implementation-prompt.md, uploaded 2026-08-26, Library file_000000003bf881f5bee252b1c10017c9, version 1. Sections 3–5 (lines 296–370), patch 01 (622–647), map and DISCOVERY/PATCH rules (930–1073), final integration (1074–1108), invariants (1259–1302), Appendix A arithmetic (1738–1768) were read directly. No other implementation was inspected. The original map is 1 Bootstrap, 2 DISCOVERY 01, 3 PATCH 01, 4 DISCOVERY 02, ... 54 integration, 55 audit. It expressly forbids skipping or combining DISCOVERY and PATCH. The project's later explicit authorization to operate branch-locally takes precedence over original historical handoff instructions; no main/merge.

## Exact source findings
- DEVELOPMENT_STAGE.md blob e2ff994887f8440bd87862a49802d9c95079fe86: CURRENT_STAGE=1, LAST_COMPLETED_STAGE=1, BOOTSTRAP, GREEN.
- sql/03_stage02_production_core.sql blob 72ae68d3ec009f65f081a099c8bf06e0dd3ed9d6: regular_mod implements Euclidean remainder; save_value directly implements 1+regular_mod(x-1,M); day_count and work_counts already use correct normative semantics. The direct SAVE expression does not route through the specified legacy oldRemainder(x) or retain the specified explicit zero-to-M detour.
- sql/test/50_stage02_production_core_tests.sql blob 1a7336ae9a08d3bac0eb1e10673d7a39821a9e02 lines 25–32 tests correct SAVE at 1, M, M+1, 2M, zero, negative one, large value and fractional rejection. It is a green correctness suite, not a historical divergence test. sql/test/20_stage01_tests.sql blob e198492857a0236284d25642f0e69e8c0bcc2ea7 tests normative SAVE independently.
- Historical first-slice report POSTGRESQL_NATIVE_CI_41032411855.md blob 8ec4de9923b25001b492be9e6520e098c9b5e7b9 records Native core 37/37 and isolation 4/4 at 8dbe132b175a5d464ee64612d550a11d23177404 (run 41032411855, job 123985046839, artifact 12967040391). The report expressly did not independently recompute the artifact digest; this turn reads the report, not the original ZIP or log. Preserve the historical claim, do not promote it to canonical DISCOVERY acceptance.
- sql/02_monster_bootstrap.sql blob 3367fe9c34e830b0bd99049ebef64398d150cd79: calendar_date_spaghetti is a zero-row skeleton. Original section 13 requires the full authoritative entrypoint only at Stage54. Separate calendar_date text API and its accepted Slice25 remain untouched; neither constitutes canonical Stage02.
- Original Appendix A defines exact integral arithmetic; no absolute input limit was found in the reviewed arithmetic/axis sections. The finite-distance resource issue remains an open later engineering/policy issue, not a prerequisite to the four small DISCOVERY 01 inputs. Do not introduce a finite cap or run huge finite probes.

## Recovered measurable canonical contract
M=170141183460469231731687303715884105727. Implement the Stage02 legacy production path oldRemainder(x)=regularMod(x,M); no zero-to-M patch in this stage. Test-only independent normative SAVE(x)=1+regularMod(x-1,M). Route an actual Stage02 computation through the legacy helper, not just a dead helper or a fixture returning constants.

| x | legacy | normative | match |
|---|---:|---:|---|
| M | 0 | M | false |
| 2M | 0 | M | false |
| 3M | 0 | M | false |
| M+1 | 1 | 1 | true |

Calculated with exact integer arithmetic independently from the SQL implementation. These are predicted values, NOT observed Native results. Required: four independently derived named comparisons, exactly three semantic mismatches and one matching control; SQL infrastructure errors, wrong values, or missing rows are failures, not EXPECTED_RED. Stage01 prior suite must remain green and production must have no test-only dependency. Pin baseline and delta Git blobs, native PostgreSQL version, checkout SHA, bounded statement/job/watchdog, exit codes, raw original artifact, logs, CRC/hash and per-case typed values. Preserve Tamil source catalogue and existing accepted slices.

## Next bounded action
Build an isolated canonical Stage02 reconstruction candidate from the verified Stage01 baseline within the authorized branch (separate delta/source lane, no reset, no overwriting current calendar or accepted slices). It must include the actual legacy route and native tests; no PATCH 01. First identify exact historical Stage01 baseline and its existing test commands/source locks; no cross-implementation copying. A candidate is not canonical acceptance or a retroactive historical run. Do not promote DEVELOPMENT_STAGE.md until acceptance and the historical-order reconciliation are evidenced. If a clean historical lineage cannot be reconciled without changing branch governance, request explicit policy decision rather than erase work.

This report is documentation/static contract only. No production edits, no new CI/Native evidence, no replay, no dispatch, no Stage03/main/merge. Canonical Stage02 NOT ACCEPTED. Preserve accepted slice scope and nonfinite rejection 24/24 evidence.
