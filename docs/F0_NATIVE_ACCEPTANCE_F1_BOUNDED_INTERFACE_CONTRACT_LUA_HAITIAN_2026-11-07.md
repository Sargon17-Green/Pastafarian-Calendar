# F0 native evidence acceptance and F1 bounded API contract — Lua/Kreyòl ayisyen

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Date: 2026-11-07  
Frozen F0 source HEAD: `1580d25561bde1f19000b49da1938e79d6e043df`  
Scope: **read-only QA evidence plus future-interface planning**. This document does NOT implement `calendarDateSpaghetti`, open Stage56, approve release, add a sixth field, or implement `postStir12`. Stage55 retains its separately accepted scope.

## F0: completed native evidence, limited acceptance

- Workflow: [Canonical Names Lock run 42250109667](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250109667), completed/success, attempt 1, branch and source SHA matching the source lock.
- Exact job: [lua_haitian_f0_year5000 / 128002633224](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250109667/job/128002633224), completed/success on Ubuntu 24.04 / Lua 5.3.
- Original [artifact 13521833565](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250109667/artifacts/13521833565): `lua-haitian-f0-year5000-evidence.zip`; verified SHA256 `9864e0b118119fbce9bca7af5c151a0a5472cb8f35a3a655e2bd19bb2576a64d`; ZIP CRC PASS; seven expected members, no extras.
- Manifest PROJECT_ID/SHA/offsets/90s budget match; oracle blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`, probe blob `4325233a4ac48b852c7934087171bd2dad9a9986`, both independently cross-checked against the source files at the lock.
- Both witness files contain exactly one `F0_WITNESS|` line each; both exit-code files contain `0`, and both stderr files are empty. The job log reports `F0_TWO_WITNESSES_PASS: 2/2 bounded reference-only calls`. No invocation approached the per-case 90s deadline.

| Offset | calculationDay | year | open index/day | close index/day | gaps | length | CPU seconds |
| --- | ---: | ---: | --- | --- | ---: | ---: | ---: |
| 0 | -15055671 | 5000 | -4 / -15057703 | 4 / -15053459 | 8 | 4244 | 10.102 |
| 12000 | -15043671 | 5000 | 15 / -15047236 | 25 / -15042878 | 10 | 4358 | 14.959 |

Independent integer arithmetic re-check, **not** another native oracle execution:
1. `calculationDay = FOUNDATION_DAY + offset` in 2/2 cases.
2. `openGateDay < calculationDay <= closeGateDay` in 2/2, with distances from opening 2032/3565 days and until closing 2212/793 days.
3. `closeGateIndex - openGateIndex = gateGaps >= 6` in 2/2.
4. `closeGateDay - openGateDay = yearLength`, within the reference `252..5778` bounds, in 2/2.
5. CRC/manifest/file count and both zero exit/empty stderr checks pass.

**Interpretation limit:** `year5000(calculationDay)` selects a year interval based on the calculation-day anchor. The two witnesses have the same reported year number but different bounds; they do NOT demonstrate a unique global year-5000 interval. F0 proves only that these two specific bounded reference computations completed with the listed invariants. It proves neither `calendarDate` feasibility, independence of the normative implementation, full date integration, nor a release gate.

## F1: frozen design profile for future five-field interface (NOT EXECUTED)

The API name remains a **proposal**, not a production declaration: `calendarDateSpaghetti(calculationDay,targetDay)`.

- Positive output shape: an ordered Lua array of **exactly 5 values** `{yearNumber, cutletName, dayInCutlet, monthName, dayInMonth}`; integer, string, integer, string, integer. Names must equal the canonical catalog mapping. No sixth result.
- All inputs must satisfy `type(x) == "number" and math.type(x) == "integer"` in Lua 5.3. No silent float-to-integer coercion or arbitrary-size day promises. Numeric overflow and unsupported domains must fail closed.
- **Initial candidate validation profile, not an accepted production range:** `calculationDay` must be one of `-15055671` or `-15043671`; for that anchor, `targetDay` must be in the corresponding **witnessed** integer interval `openGateDay < targetDay <= closeGateDay` from the table above. This is a finite, reproducible test-domain specification, not evidence that all these target days are computationally feasible. Do not extrapolate to intermediate calculation-day anchors.
- Error categories proposed for a later implementation contract: `BAD_ARITY` (not exactly two arguments), `NONINTEGER_DAY` (wrong type or fractional), `OUT_OF_PROFILE` (outside above candidate domain), and `UNSUPPORTED_RUNTIME` (a separately proved resource/overflow limit). Any future implementation must choose deterministic error messages/codes, throw before returning a partial tuple, and demonstrate each with tests; the current unimplemented facade must NOT be relabeled as passing this contract.
- Date composition must agree with `test/normative_oracle.lua` for supported pairs **and** an algorithmically independent direct-enumeration/interval checker. The reference is a comparison source, not an allowed production implementation dependency.

### F1 acceptance gates and sequence

1. **F1 contract/design acceptance only:** audit these exact types, arity, candidate domain, error categories, output schema, and evidence limits. Nothing here counts as a native F1 test or proof that a production API exists.
2. **F2 feasibility next (bounded, independent):** design small synthetic structures and a separate interval/day enumerator without importing or copying the normative calendar-date composition routine; obtain 4/4 independent hand-checkable witnesses for interval arithmetic, cutlet partition and month weaving; separately test runtime budget before claiming the large reference-year date path is feasible.
3. Only after successful F2 feasibility and a separately scoped integration authorization by the existing development plan may later implementation work attempt M01–M09 of the [release acceptance matrix](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/d584a4767549dee15c1cddfa2f0740fc9bb38661/docs/FULL_DATE_INTEGRATION_RELEASE_SCOPE_ACCEPTANCE_MATRIX_LUA_HAITIAN_2026-11-06.md). Previous historical Stage55 acceptance must not be rerun or converted to full-product PASS.

Status: **F0_REFERENCE_2_OF_2_NATIVE_ACCEPTED; F1_DESIGN_FROZEN_ONLY; F2_NOT_EXECUTED; PRODUCT_RELEASE_NOT_READY**. No production, test, workflow or stage-status changes are permitted by this single-document update.
