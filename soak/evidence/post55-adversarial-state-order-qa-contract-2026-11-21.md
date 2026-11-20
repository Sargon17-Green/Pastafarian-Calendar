# Post55 Kotlin+Cymraeg: bounded adversarial production state/order QA contract
Date: 2026-11-21
PROJECT_ID: PC-BRANCH-KOTLIN-CYMRAEG
Status: CONTRACT_DEFINED_ONLY — NO NEW EXECUTION OR PASS
Baseline source: a7bad6d54750ce4a27d1d057087cd6afaf7dd348 (Kotlin+Cymraeg)
Previously accepted Names Lock: run 44800379946 attempt 2, completed/success, 29 successful jobs plus 1 expected skipped post55-diagnostic-not-certification. Stage35 job 136578082366 completed/success (original-oracle step succeeded and STAGE35_FULL_NATIVE_GREEN in job log).
Previously accepted order diagnostic: run 44800380132, 45 real interior queries in 3 fresh navigators; this contract does not rerun or replace it.

## Scope and reason
Stress **same-instance reuse**, alternating near-boundary and cross-year queries, and exact half-open interval ownership. The existing 45-query diagnostic sampled only strictly interior days and used distinct fresh navigators for each order. This new diagnostic must compare Kotlin production against the independently recomputed, **unseeded** Python gate/geometry oracle on the same locked source. This is a QA specification, NOT an implemented runner or an acceptance claim.

## Fixed inputs and execution
- Production implementation: src/main/kotlin/pastafari/ProductionYearNavigator.kt, compiled with ALL src/main/kotlin/pastafari/*.kt plus a NEW purpose-built Kotlin probe; JDK 21, Kotlin 1.9.0.
- Fixed calculationDay FOUNDATION = -15055671; years 4998, 4999, 5000, 5001, 5002, derived from year5000 and previousYear/nextYear with the production navigator, then **independently** recomputed by Python.
- navigator(maxGateAbsIndex=8192,maxYearTransitions=8), freshly constructed once per **session**, reused across both phases. No production limit change. No checkpoint/table seed, cached expected answers, or fixture copying from another branch.
- Date interval convention from current production code: (openDay, closeDay], so atOpen belongs to the PREVIOUS year, atClose belongs to the current year, afterClose to the NEXT year.
- 18 named probes, in this canonical indexed sequence:
  - indexes 0..4: AFTER_OPEN(y) = openDay(y)+1 for y=4998..5002;
  - indexes 5..9: AT_CLOSE(y) = closeDay(y) for y=4998..5002;
  - indexes 10..13: AT_OPEN(y) = openDay(y) for y=4999..5002 (expected y-1);
  - indexes 14..17: AFTER_CLOSE(y) = closeDay(y)+1 for y=4998..5001 (expected y+1).
- Thus 18 named probes map to exactly 10 distinct target days (8 intentional aliases). Enforce the expected alias identities: AT_OPEN(y) == AT_CLOSE(y-1), AFTER_CLOSE(y) == AFTER_OPEN(y+1).
- Session A/NATURAL: case IDs [0..17]; session B/REVERSED: [17..0]; session C/STRIDE5: [(5*i) mod 18 for i=0..17]. The STRIDE5 sequence is 0,5,10,15,2,7,12,17,4,9,14,1,6,11,16,3,8,13; multiplication is bijective mod 18 since gcd(5,18)=1.
- Each session executes phase 1 in its designated order; phase 2 in the exact REVERSE of that session's order using the SAME navigator instance. No navigator reset or shared gate cache between sessions.
- Result: 3 sessions * 2 phases * 18 calls = **108 real Kotlin findTargetYear calls**, 10 distinct target days, 5 contiguous years. Require exactly 36 results per session; all 108 must match independent five-field tuples (year number, open gate index, close gate index, open day, close day).
- Per-session expandedGateCount must be in [1,8192] after both phases. Limits and maximum permitted 8 transitions are mandatory, not targets to be relaxed to obtain green.
- Independent Python oracle, reconstructed on the locked SHA: derive 560 signed gate gaps in strict order -1..-280 then +1..+280 from independent_sauce_oracle.evaluate and gap_from_witness, with no checkpoint seed; construct GateLedger and IndependentYearGeometry, and independently calculate all five year tuples and 18 ownership expectations. Verify 561 gate days (-280..+280) against Kotlin production seed gate trace. Enforce exactly 560 questions, exact index order, and 0 discrepancies; min/max gate gap checks stay those of the independent oracle.
- Independent geometry.find must verify all 18 expectations, with <=8 transitions per call. Both oracle and Kotlin should be anchored to FOUNDATION (no TABLETS).
- Evidence runtime budget: 900 seconds end-to-end, Kotlin subprocess <=600 seconds, fail-closed on deadline; emit hash digests for JAR, Kotlin transcript, independent signed-gap trace, and the complete JSON result.
- Fail-closed transcript schema: 108 CASE rows, each 11 tab-separated fields: literal CASE, session name, phase 1|2, in-phase position 0..17, canonical case ID 0..17, target day, and the five canonical signed integers returned by production. 3 SESSION_GATES rows (literal, session, count), 561 GATE rows (literal, signed index, day), 1 SEED_GATES row (literal, count=561). EXACTLY **673 rows** in that fixed order. Each phase's case IDs must be the specified permutation/reversal; strict newline/no CRLF, no extra rows or debug output.
- Evidence JSON must include source SHA, runner/probe version, production compilation identity, job/run ID, process exit status, expected/actual counts for 108 calls / 560 gaps / 561 trace / 18 ownership cases, 3 session gate counts, <=8 transitions, mismatches=0, artifact link and SHA256. The standalone report must not call itself a certification.

## Independent verification and negative controls (minimum)
Synthetic tests must prove rejection of: a missing/duplicated CASE row, phase order mutation, swapped canonical IDs, noncanonical numeric tokens (-0/leading zeros), a forged target day, wrong previous/next-year ownership at open/close, one altered result tuple, production gate budget 8193, one mutated independent gate day, omitted/duplicated signed-gap question, reused session identity, and a truncated/missing JSON artifact. Do not manufacture expected-red outcomes; first implement and execute these controls before claiming they PASS.

## Acceptance gate
1. Baseline Names Lock run 44800379946 attempt2 is already ACCEPTED for its original SHA only; do not rerun it to validate this specification.
2. For a NEW probe SHA, require completed/success GitHub Actions job with exact HEAD SHA, JDK21/Kotlin1.9 production compilation, all protocol/mutation tests passing, all 108 real queries / 18 ownership checks, 560 unseeded gaps, 561 real gate comparisons, valid gate budgets, zero mismatches, verifiable artifact contents/digest and readback. Queued/in_progress cannot pass.
3. If original oracle/probe disagrees, retain failing evidence and diagnose; never silently change the oracle, query set, gate limit, expected-red classification, or status.
4. Claim at most PASS_BOUNDED_REAL_PRODUCTION_BOUNDARY_STATE_ORDER_NOT_CERTIFIED after evidence. This test does not prove TABLETS full-date, seven-field conversion, global algorithmic independence, main readiness, or --certify.

## Implementation NEXT
Implement a fresh Kotlin boundary-state probe, matching fail-closed Python audit and mutation tests, plus a narrowly scoped workflow with artifact upload even on failure. Do not modify existing accepted three-order probe or its run. Verify current branch HEAD before commit; only write Kotlin+Cymraeg. Preserve existing production 8192 and main/merge boundaries.
