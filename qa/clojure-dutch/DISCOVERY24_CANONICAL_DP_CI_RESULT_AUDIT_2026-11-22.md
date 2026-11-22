# DISCOVERY24 isolated canonical DP — completed evidence audit (2026-11-22)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Branch: Clojure+Nederlands
Exact tested source: `ec0051ec6335fe178c03bcf3583b3dbfec1ffa84`
Workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365
Scope: TEST/QA ONLY; Stage2 still OPEN.

## Verified completed outcomes
- Run 45065505365 (attempt 1): completed; canonical verify job 137340625261 SUCCESS; isolated DP job 137340625561 SUCCESS; full Native and unrelated opt-in jobs SKIPPED.
- CI step `Python QA preflight`: `STATIC_QA_PASS profiles=9 words=135 rank_position_checks=1102 max_abstract_cells=53 canonical_bigint_roundtrip_digits=5288`. This verifies the previously blocked 5288-digit conversion path's self-test, not a date differential.
- Exact-GITHUB_SHA canonical Clojure source extraction completed; 128N search budget remains.
- Artifact: ID 14770898411, GitHub ZIP sha256 `eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5`, 12,468 B. Downloaded archive was independently SHA-256 checked and opened.
- Contained `discovery24_canonical_dp_input.json` sha256 `25af5f3f21262c1fa29b8e495d0fd6be3942c5b9bdf3bb15529ee441920f947c`, 16,993 B;
  `discovery24_canonical_dp_result.json` sha256 `8a315b22b903e64a1733f2e5f77aa07a85fd8d398105ad3aad2fc05ef64ed8ce`, 12,124 B;
  `discovery24_dp_python_selftest.log` sha256 `da4d685bc14d1089969abc6881b3805ef6a5d497f396393f2f32f9feccb77295`, 212 B.
- Input/result independently parsed from ZIP: project_id/source_sha exact; canonical calculation/target day `-15055654`, target year 5000, month_count 33. Profile length 33, all lengths 4..123, sum 3569 = close_gate_day - open_gate_day. Independent normative and production rank strings equal, rank is 5288 decimal digits, 1 <= rank <= total, production and normative weaving totals equal.
- QA model (not production differential): `abstract_unique_states=22`, `abstract_legal_transitions=43`, `abstract_units_charged=65`, `abstract_budget=5000000`.
- Bounded accounting result: `production_equivalent_work_charged=4973786`; next charge `113505`; sum `5087291 > 5000000` confirmed arithmetically. `status=DP_FEASIBILITY_UNPROVEN`; `reason=production-equivalent-work-budget-exceeded`; `prefix_p82=null`, `prefix_p520=null`, `numeric_witness_emitted=false`, `five_field_differential=false`, `full_month_weaving_computed=false`, `stage2_accepted=false`.
- This `production_equivalent` model is the diagnostic implementation's claim based on `src/pastafari/maandrang.clj:raming`; its equivalence to mandatory production insertion-cell counting has NOT yet been independently established. The historical distinct p81=4,995,675 and proposed p82=5,002,652 witness remains a different LIMITED accounting result; no direct numeric identity between accounting approaches is asserted.
- Dependency fix evidence: Java Maven cache saved after the run; the previous 429 pre-source failure is no longer present in this exact run. No claim about eliminating future 429 rate limits.
- Existing p1/p16 earlier witnesses remain scoped to their own exact SHAs; legacy generic full E2E remains 0/7; Stage2 remains OPEN, not accepted.

## Gate decisions
- PYTHON_QA=PASS on ec0051ec6335fe178c03bcf3583b3dbfec1ffa84 only; canonical input cross-check=PASS; isolated CI job=SUCCESS; DP numerical feasibility=UNPROVEN (controlled refusal); Native full suite=SKIPPED; five-field p82/p520=NOT_PROVEN; Stage2=OPEN.
- Successful job with a controlled unproven exit is *not* a positive numeric result. No rerun on this SHA needed for these same checks.

## NEXT — independent, measurable, TEST/QA only
1. Inspect the exact production `raming` cost function and the DP accounting transition mapping at the accepted SHA. Define a fixed correspondence table between every diagnostic charged operation and the mandatory insertion-cell production operation. Independent source audit must prove a safe upper bound or identify a counterexample.
2. Test that correspondence on independent small families and existing non-canonical p81/p82 accounting witness; do not treat matching final numbers alone as proof of stepwise equivalence. Keep 5,000,000-cell, 128-search limits unchanged.
3. Only if a strictly proven, safe canonical p82/p520 cost bound permits it, add a *distinct* numeric five-field differential probe on a new exact SHA. Otherwise maintain explicit budget-unproven status; no duplicate same-SHA run.
4. Preserve all historical evidence and Stage2 OPEN. No production/API/budget/main/merge/publication/user-machine execution.

This docs-only evidence commit is marked [skip ci]; no new Native/DP work is claimed on the report's own SHA.
