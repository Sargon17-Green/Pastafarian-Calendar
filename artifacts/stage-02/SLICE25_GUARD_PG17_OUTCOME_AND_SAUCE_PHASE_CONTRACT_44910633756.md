# SQL+தமிழ் / Slice25: guard probe outcome and bounded sauce-phase next contract

**PROJECT_ID:** PC-BRANCH-SQL-TAMIL  
**Evidence date:** 2026-11-21  
**Original tested branch/commit:** `SQL+தமிழ்` / `dca2b8e5594c2c80e24d68604d79bf45f140a00a`  
**Status:** Guard pilot NOT ACCEPTED; full Slice25 NOT ACCEPTED. No production modification, no merge/main/release.

## Source-locked completed evidence (not queued)

- PG17 candidate run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910633756 — exactly two completed jobs on the tested SHA, offline PostgreSQL **17.12**.
- Job **136865491966**, `anchor_cutlet_boundary`: **completed/success**; original PG log shows **5/5** distinct independent locked field PASS notices, `SLICE25_MATRIX_GREEN=native:anchor_cutlet_boundary`, elapsed **331421.750 ms**. Original ZIP artifact **14709851794**: SHA256 `1a90dd0fe7fedb5114de0b90039b7d741e684e08e1a8626e56c3b3aba69d76c9`; GitHub digest == upload-log digest == downloaded original bytes; ZIP CRC PASS (11 entries).
- Job **136865492170**, `prev_3_prev_middle`: **completed/failure**; PostgreSQL `statement_timeout` after 12 minutes; **0/5** field notices and no green marker. Actual stack `floor_div → save_value → stone_state → stone_value → bowl_round → sauce → build_year_structure line 12 → calendar_date line 45`. Original ZIP artifact **14710610663**: SHA256 `5b972d19d81e14b6e885a0d43d4647159b78ac693780bd7ad100939efac26873`; three-way digest match and ZIP CRC PASS (10 entries).
- Both ZIPs' version records match tested SHA, project, branch, PG17.12, production `sql/20` Git blob `42acfb80e9eabfd9d091176643763ee7d7bca9ee`. Their identical QA-only candidate `20_candidate.sql` has SHA256 **`e03a733509e33702ede22bc1240af44ab3982d4e4dae66bbef8454ae64cd490a`**. Each generated `test.sql` SHA matches its own in-ZIP source manifest. The two SQL test files are case-specific and intentionally differ.
- Stage1 run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910633604 job **136865491614** **completed/success**, source SHA exact, archived native markers **52 ordinary + 7 saved-sum + 4 isolation**. Original artifact **14710261008**: SHA256 `27ad991c1363ccc9112712ba95fefbe3e3cb1348abb7c1fd82b3a7704bc62c85`; GitHub digest == upload digest == downloaded original bytes, CRC PASS (3 entries).
- Names Lock https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44910633708 job **136865491567**, **completed/success**. Its checkout and original log show the same triggering SHA; canonical-lock step completed/success. This workflow has no ZIP artifact to compare.
- Reproducible evidence audit: `sql/test/168_stage25_cutlet_guard_evidence_audit.py`. Invoked against these **three actual original ZIPs**: exit **0**; all three SHA256/CRC and all candidate source/test/versions locks verified, five-field green and failed-phase discrimination verified. Local script SHA256 `8f0c57808652af4844e24977654b4560c8da1da4034284985bdc07049d8f5366`, Git blob `f349b737eb702f4f33d75716372d07f1c2a664e9`. This is an evidence-only QA script, not a new PG run.

## Causal interpretation and prohibition on blind retry

Accepted `sql/26_stage02_year_structure.sql` at Git blob `faac634a06aee59354de207eb088e4e9996034fa` assigns `v_sauce := pastafari_sql_tamil.sauce(p_calculation_day,(p_year).open_gate_day+1)` **before** it calls `choose_cutlet_partition(...)`. The tested guard transforms only `sql/20_stage02_cutlet_partition.sql`, within the latter function. Therefore it cannot avoid or accelerate the failed `sauce` invocation shown in the original PG stack. This explains why the tested guard does not resolve the problematic case; it does **not** establish that `sauce` itself is incorrect, that `bowl_round` is the dominant total-runtime cost in other cases, or that the guard is universally equivalent.

The earlier full Slice25 run **44896020377** had 53 success/3 PG 12-minute timeouts, and the earlier DP candidate **44905408848** had a separate upstream timeout. Neither past result is superseded by a two-case guard pilot. Do not promote this guard to production on this evidence, and do not re-dispatch any already accepted matrix or old failed run without a new instrumented hypothesis.

## NEXT — isolated sauce/bowl_round phase profile, authorized branch-only QA

**Inputs:** immutable locked case `prev_3_prev_middle`: `calculation_day=-15055671`, `target_day=-15072356`, expected year number **4996** and five-field locked historical independent oracle. Positive control `anchor_cutlet_boundary` has already passed and need not be repeated absent a changed source. Lock SQL/26 and every instrumented source file by exact Git blob before running.

**Design:** First inspect the actual accepted SQL definitions of `sauce`, `bowl_round` and their helper calls (do not infer implementation from stack names). Create a **QA-only copy**, replacing exactly one source block with a reversible transform and no persistent state; insert timestamp notices at `find_target_year` completion, `sauce` entry/exit, and each identifiable nested `bowl_round` phase. Preserve unchanged production source in branch. Restrict to the single previously failing input and record original PostgreSQL version, manifest, source/test SHA, per-phase elapsed ms, branch SHA, and bounded timeout. Preserve logs and ZIP even on failure. Verify static source locks and SQL compilation separately from any Native execution.

**Oracle and gates:** Report only phases actually reached; absent completion markers are **not** PASS. If PG completes, compare **all five** independently locked fields, test semantic equality to unmodified source on the same input, verify generated files and original ZIP SHA+CRC. If it times out, identify the last emitted phase and SQL call stack; an upstream partial result cannot accept Slice25 or a production optimization. No user-machine execution required. No new full 56-job dispatch, no merge/main/release.

**Classification:** D=פתוחה, G=READY. NEXT is further bounded QA diagnosis of `sauce`/its nested calls, not user approval and not local OS execution.
