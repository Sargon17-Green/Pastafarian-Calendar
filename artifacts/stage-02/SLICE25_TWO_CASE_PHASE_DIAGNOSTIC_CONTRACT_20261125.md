# SQL+தமிழ் Slice25 — two-case phase diagnosis and Native-middle contract

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL  
**Branch:** SQL+தமிழ்  
**Parent HEAD:** fc5077856416c1658baf15126b4ba49097601e21  
**Scope:** QA-only instrumentation plus one independent direct archived-oracle case. No production SQL, main, merge, or release.

## Why these cases

The original 56-job matrix has two live normative differential timeouts that remain unresolved:

- prev_3_prev_last: timeout stack reaches exact_gate_index → gate_index_at_or_before → negative_gate_gap → gate_gap_signed → sauce → bowl_round → stone_value → stone_state.
- next_3_next_middle: timeout stack reaches bowl_factorial → bowl_order_from_number → post_stir_round → post_stir_chain → sauce → gate_gap_signed → positive_gate_gap → calendar_date.

The previous QA-only DP candidate is not production-equivalent and is not credited as a fix. The diagnostic therefore clones the current production function definitions to qa_* aliases and adds only reversible tracing wrappers. The original production functions remain loaded unchanged.

## Exact inputs and independent five-field oracle

All inputs and expected values are selected from the immutable 29-case fixture:

- Fixture path: sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl
- Fixture Git blob: 21f38cd280498070b08b6c3074780f1742c36957
- Historical fixture source commit: 1ddaef9a315f83402ececaf4dc31f96dbdd051bd
- All 28 production SQL files plus the fixture are locked by exact Git blob SHA-1: 29/29.

| Mode | Case | Calculation day | Target day | Expected typed tuple |
|---|---|---:|---:|---|
| Phase | prev_3_prev_last | -15055671 | -15070673 | (4996, சாம்பல், 213, மாதுளை, 115) |
| Phase | next_3_next_middle | -15055671 | -15037302 | (5004, கொத்து, 1703, நினவே, 61) |
| Direct Native | prev_3_middle | -15055671 | -15067833 | (4997, வெண்கலம், 517, நாக்கு, 54) |

Each case is executed in its own fresh, network-isolated PostgreSQL 17.12 database. The direct Native case calls the unchanged production calendar_date; the two phase cases call the reversible QA alias and compare all five typed fields to the archived independent record. No normative/reference schema is loaded, so this is not a live normative differential.

## Phase instrumentation

- prev_3_prev_last: explicit ENTER/EXIT and elapsed milliseconds for exact_gate_index, gate_index_at_or_before, negative_gate_gap, gate_gap_signed, sauce, bowl_round, stone_value, and stone_state.
- next_3_next_middle: explicit ENTER/EXIT and elapsed milliseconds for bowl_factorial, bowl_order_from_number, bowl_order_from_drop, post_stir_round, post_stir_chain, and sauce.
- All traced aliases are QA-only and are generated from exact-locked source definitions. Reverse-transform checks and a deliberately damaged-call mutation test must pass before PostgreSQL starts.
- The diagnostic is observational. A QA alias result is not itself a live normative differential or whole-Slice25 acceptance.

## Resource and evidence contract

- SQL statement_timeout: 720 seconds.
- External watchdog: 750 seconds, with TERM/KILL cleanup.
- GitHub Actions job cap: 15 minutes.
- One case per job and one fresh PostgreSQL container per job; no matrix replay and no retry of either timeout.
- Each artifact retains the 29 exact source/fixture locks, current tested SHA, generated SQL, PostgreSQL version, phase ENTER/EXIT log, five typed assertions, actual PSQL exit code, and status.
- After completion, independently compare original ZIP raw SHA-256 with upload-log SHA-256 and GitHub artifact metadata digest, verify ZIP CRC, and verify internal generated-SQL hashes.
- A timeout or nonzero PSQL exit is NOT ACCEPTED, even if some phase markers exist.
- A 5/5 archived-oracle pass is a case-level result only. It does not close the live normative differential gate or accept Slice25.

## Scope boundary

No production function body is edited. No branch protection, main, merge, release, or publication operation is included. After phase evidence identifies the actual hot path, a separate production-preserving optimization or explicit bypass must be designed and regression-tested against the original oracle before it can be considered for acceptance.
