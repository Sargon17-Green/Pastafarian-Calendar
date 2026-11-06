# Full-date integration: bounded release-scope and acceptance matrix — Lua + Kreyòl ayisyen

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Planning source lock: `a4c0b6e11f6a204d231384a498be37cd23637b81`  
Date: 2026-11-06  
Artifact type: **QA / forward contract draft only**. No Stage56, no executable integration, no release approval.  
Current product-release assessment: **NOT_READY_FOR_FULL_CALENDAR**. Stage55/PATCH27 remains accepted only within its documented octile-gate scope.

## Confirmed baseline versus proposed scope

- At the source lock, `DEVELOPMENT_STAGE.md` states `TOTAL_STAGES=55`, `LAST_COMPLETED_STAGE=55`; Stage55's accepted run is 41978829563, and documentation-closure run 42124762972 is 84/84 on its own SHA.
- `src/spaghetti.lua` ends with `calendarDateSpaghetti()` raising `error("calendarDateSpaghetti poko entegre nan Stage 35", 0)`. The Stage35 reference in the error string is stale, not evidence of a current Stage35 state.
- `test/normative_oracle.lua` already defines `calendarDateIds(calculationDay,targetDay)` and `calendarDate(calculationDay,targetDay)`, where the latter returns exactly **five** ordered values: `{year.number, Catalog.cutlet(cutletNameIndex), dayInCutlet, Catalog.month(monthNameIndex), dayInMonth}`. These are existing reference behaviors; no claim is made that a corresponding production API is implemented.
- The reference specifies gate-defined year selection (including year 5000 and neighboring years); cutlet partition and naming; bounded month lengths; month weaving. Constants in that source: year length 252..5778 days, cutlets 6..17, month count 3..47, month length 4..123. They are *reference* bounds, not verified production behavior.
- This **planning profile A** covers a hypothetical five-field callable date interface only. It deliberately excludes a sixth date field, `postStir12`, any new user-facing publication or merger, and any claim that all calendar requirements have been completed. The release scope for a sixth field must be assessed separately; it cannot be silently added to profile A.

## Input/output specification for a future implementation gate (not yet authorized as a new stage)

Proposed invocation: `calendarDateSpaghetti(calculationDay, targetDay)`. Both arguments must be exact Lua integers within a separately proved overflow-safe operating window; the requested window must be documented by the implementation before acceptance. Do **not** assert unbounded BigInt-day support from the existing Lua-integer oracle. The expected successful output is an ordered array of **exactly five** values, with year/cutlet-day/month-day integers and two catalog-derived names, equal to `normative_oracle.calendarDate(calculationDay,targetDay)` for identical valid inputs. Errors must be explicit and deterministic for missing, noninteger, unsafe, or unsupported inputs. There must be no partial date returned after a failed call.

Reference output alone does not authorize copying its implementation into production. A structurally independent verifier and bounded hand-checkable fixtures are mandatory, in addition to reference differential tests.

## Acceptance matrix — planned tests, NOT_EXECUTED

| ID | Requirement / exact observation | Proposed finite evidence and independent check | Acceptance criterion | Status at planning |
| --- | --- | --- | --- | --- |
| M00 | Existing 55-stage source and acceptance are frozen | Record parent SHA, changed paths, Stage55 job+log links; verify no `src/`, `test/`, workflow or `DEVELOPMENT_STAGE.md` modifications by this planning commit | Planning commit changes this document alone; never relabel Stage55 or product release | PLAN_ONLY |
| M01 | API type and output shape | 3 valid reference-driven input pairs; 8 invalid calls covering 0/1/more-than-2 arguments, nil, string, fractional and unsupported bounds | Exact five-field order and types for valid calls; 8/8 fail closed with no partial return; numeric day window documented and checked | NOT_EXECUTED |
| M02 | Anchor-year and adjacent-year selection | Precompute 2 feasible reference-year witnesses and test each `openGateDay`, `openGateDay+1`, `closeGateDay`, `closeGateDay+1` (8 target positions), with a fixed calculation day; explicit 5000/next/previous-year trace | Correct half-open/closed membership `openGateDay < target <= closeGateDay`; equality of year numbers and five fields with reference; any missing feasible witness recorded rather than counted as pass | NOT_EXECUTED |
| M03 | Cutlet partition / names | For at least 2 independently constructed bounded year structures, verify 6..17 cutlets, adjacent coverage and unique assigned names; probe 2 first/last-day boundaries per structure (8 probes) | All year days partitioned once with no overlap/hole; cutlet-name indices unique; boundary positions agree with reference | NOT_EXECUTED |
| M04 | Month structure and weaving | For 2 feasible reference structures, independently sum month lengths and check 3..47 months of 4..123 days each; examine at least first/last occurrence of 2 distinct month IDs per structure (8 observations) | Sum equals year length; weaving contains every day once; opening and closing order constraints hold; names unique | NOT_EXECUTED |
| M05 | Five-field differential date result | At least 12 distinct bounded `(calculationDay,targetDay)` pairs; fixed seed and stored reference values, including equal-day, earlier/later target, a negative day and a year-edge witness if feasible | All 12/12 five-tuples agree exactly with frozen reference outputs; no output of sixth value | NOT_EXECUTED |
| M06 | Additional independent oracle (not just production-vs-normative) | Independently implement a tiny direct enumeration or bounded day-by-day reconstruction **only on small feasible structures**, with at least 4 reproducible witnesses; validate five-tuple consistency and interval arithmetic | 4/4 agree with reference and production; production may not import the reference or the verifier, and neither may share the same date-composition routine | NOT_EXECUTED |
| M07 | State ownership / isolation | 3 A/B/A interleaving scenarios, 2 independent repeated runs, 2 failures followed by recovery | Deterministic outputs, no aliasing or leaked intermediate state, 2/2 recoveries | NOT_EXECUTED |
| M08 | Error / safety / runtime | Bounded Lua5.3 test jobs with explicit per-case timeout 60 s and suite timeout 600 s (tentative budget, revise only with measured data); verify overflow and no infinite search | No timeout or unbounded search for a claimed supported input. If reference feasibility exceeds budget, document the unresolved limit and **do not** claim gate PASS | NOT_EXECUTED |
| M09 | Native and CI identity | On **future implementation SHA only**, `luac5.3 -p`, native differential tests with counts and stdout, exit=0, empty stderr, published per-job evidence SHA/manifest/CRC and matching branch HEAD | Completed/log evidence for exact SHA and every required gate; queued/in_progress is neither PASS nor blocker; do not rerun prior Stage55 PASS on unchanged SHA | NOT_EXECUTED |
| M10 | Product/release decision boundary | Evidence-based review of M01–M09 and separately scoped sixth-field/`postStir12` requirements | A five-field candidate may be called **profile A validated** only after all its gates, **never** full-product READY by itself; no release, merge or scope expansion in this document | NOT_EXECUTED |

Counts above are **proposed minimum sample counts**, not observed results; all future witnesses must be frozen with input, expected output, independent algorithm, SHA, status and log before scoring. Reference-derived fixtures are not logically independent evidence for the requirement of an independent algorithm.

## Execution dependency and bounded rollout plan

1. **F0: feasibility preflight, read-only.** Establish two usable `year5000` reference witnesses with a strictly bounded exploratory run. If the current reference is too expensive, report exact timeout/inputs and design a small structural enumerator before attempting the full matrix. Do not assert success from theoretical feasibility.
2. **F1: freeze the API.** Decide exact supported Lua-integer window, error contract and five-tuple schema before changing implementation. Document source and shape compatibility; no silent sixth field.
3. **F2: independent checkers.** Write bounded direct enumeration/interval arithmetic distinct from the production algorithm; compare with the normative reference on small fixtures. For large BigInts, use exact arithmetic and reject float-based comparison.
4. **F3: implementation and adversarial QA only after separate scoped integration work is legitimately opened.** Exercise M01–M08; errors or missing witnesses remain open issues and are never relabeled expected-red without actual reproduction.
5. **F4: release-review evidence.** Complete native/CI for exact implementation SHA; return to scope decision for omitted sixth field, `postStir12`, and publication. This planning document is **not** that decision.

## Evidence links

- [Bounded release-readiness audit](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a4c0b6e11f6a204d231384a498be37cd23637b81/docs/RELEASE_READINESS_SCOPE_AUDIT_LUA_HAITIAN_2026-11-06.md)
- [Stage55/PATCH27 bounded contract](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a4c0b6e11f6a204d231384a498be37cd23637b81/docs/STAGE55_OCTILE_EDGE_PATCH_CONTRACT_2026-11-05.md)
- [Production facade](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a4c0b6e11f6a204d231384a498be37cd23637b81/src/spaghetti.lua)
- [Existing normative oracle](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a4c0b6e11f6a204d231384a498be37cd23637b81/test/normative_oracle.lua)
- [Previously accepted documentation-closure run](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42124762972)
- [Audit-only CI awaiting a final result at planning time](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173015711)

**Acceptance state at document creation: PLANNING_ONLY / M01–M10 NOT_EXECUTED / RELEASE_NOT_READY.** No product code, integration tests, stage numbering or release status changed.
