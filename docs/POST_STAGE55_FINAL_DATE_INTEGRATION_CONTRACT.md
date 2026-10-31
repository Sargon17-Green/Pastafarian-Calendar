# Post-Stage55 — final five-component production-date integration contract

**Project:** PC-BRANCH-TYPESCRIPT-MARATHI / TypeScript+मराठी  
**Scope:** engineering integration within the existing 55-stage program, **not Stage56**.  
**Grounded parent:** `b551479ec73dc9d00705cb1313914578ddc24082` (Stage55/PATCH27 accepted on Actions run 41186928752).  
**Status of this document:** implementation contract; the final production API is **not** enabled or accepted by writing this document.

## 1. Source-grounded gap and decision

- `src/monsterBase.ts` exports `calendarDateSpaghetti(calculationDay, targetDay): never`; it validates its `bigint` arguments and deliberately throws `MonsterStageError`.
- `test/normativeOracle.ts` has a **test-only** independently calculated `NormativeOracle.calendarDate(c,t)`, returning five values. Never import, call, copy, or generate data from that test oracle in `src/`.
- `src/patch27MonthMembership.ts` validates membership against the **actual** legal weaving, via the complete Stage54 historical/Native chain. It does **not** assemble a final date, construct its own two-argument input request, or expose the canonical five-tuple.
- `test/discovery21Fixtures.ts` supplies `buildStage41CompatibleLegacyFixture()` using the test-only `NormativeOracle` to create `Patch20StructureRequest`. That builder is valid test infrastructure, **not a production input factory**.
- Therefore a direct two-argument wrapper around `patch27MonthMembership(handler,q,...)`, or a `src/` import from `test/`, would violate the accepted independence contract. The missing work is **a real production Native question/request builder and final-date projection**, not just replacing the throw with a test result.

## 2. Public API, mathematical output, and validation

Keep exactly two positional inputs, both signed `bigint`: `calendarDateSpaghetti(c: bigint,t: bigint)`.
The successful return is a frozen, readonly tuple with exactly five **canonical** components:
```ts
readonly [
  yearNo: bigint,
  cutletName: string,
  dayInCutlet: bigint,
  monthName: string,
  monthOccurrenceOrdinal: bigint
]
```
No sixth date component, no status/metadata inside the tuple, no JS `number` in the returned numeric components, no local-calendar alias, and no value derived by using Marathi label text as an index. The strings come only from the locked 17-cutlet and 47-month canonical catalogs. Invalid non-bigint inputs must raise `MonsterValidationError` before expensive work; no silent coercions, truncation, float arithmetic or arbitrary practical limit on signed input magnitude. (Execution-cost bounds for CI are separate from domain bounds.)

Let the fully validated production Native year be `Y`, with `Y.openGateDay < t <= Y.closeGateDay`, `first = Y.openGateDay + 1n`, `L = Y.closeGateDay - Y.openGateDay`, and `d = t - first + 1n` (1-based year day, `1 <= d <= L <= 5778`). Cutlets are partitioned by the corrected gate-gap composition; find the **unique** cutlet `k` containing `t`, set `dayInCutlet = t - cutletFirstDay(k) + 1n`, and resolve the cutlet's distinct canonical name index via the corrected Stage44/PATCH22 name selection.

Let `w[1..L]` be the actual corrected Stage49/PATCH24 legal month weaving, and `monthId=w[d]` be its **position ID**, not its textual name or a contiguous-span guess. Its canonical month-name index comes from the distinct corrected month name permutation, not directly from `monthId`. Set
```text
monthOccurrenceOrdinal = Σ(i=1..d) [w[i] == w[d]]
```
as an exact `bigint`. This is the fifth and final component. Independently check `w[d] == monthId` using Stage55/PATCH27 direct membership, and match the Stage51/PATCH25 prefix counter. Do not use Stage53 suffix-end, Stage54 span guess, or calendar-day-in-year as the month ordinal.

For the verified Year5000 Native witness, month 44 has 123 actual occurrences and 4,989 internal non-member days; year day **239 is a non-member of month 44**. This test MUST prove that `w[239] != 44`; it must **not** falsely conclude the target day has no month or assign month 44 to that day. Another legal month covers it.

## 3. Build real inputs without an oracle dependency

Implement a production-owned question construction path from **only** `c,t`. The path must produce the signed gate questions, real target-year search, the true year-first-day Sauce question, and `Patch20StructureRequest` needed by the already accepted full Native Stage55 handler. Use production computations and exact `bigint` arithmetic. Preserve all historical predecessor calls/observations as defined by the accepted handlers; do not substitute cached test fixtures, fictitious candidates, normalized witnesses, mock Sauce calls, or unrelated branch implementations.

**Required source audit before coding:** trace the precise upstream types and dependency order starting at `Patch18Question`, `Discovery20StructureRequest` / `Patch20StructureRequest`, Stage19 year-cache, Stage21 cutlet partition, Stage22 canonical cutlet names, Stage23 month lengths, Stage24 legal weaving, Stage25 prefix ordinal, and Stage27 direct membership. Record which source produces each final field. If the existing handlers require an injected precomputed question, implement a genuine production factory with measurable call counts rather than taking an extra public API argument. Never import `test/normativeOracle.ts` into `src/`.

Use a fresh owner/context for each top-level call. Deep predecessor failure must not commit partial trace, metrics, or shared state to the caller; an explicit injected fault and subsequent clean retry must demonstrate rollback/retry behavior. A successful call must finish with deterministic immutable output; two independent calls on the same arguments must agree.

## 4. Call-budget and resource constraints

- Existing Stage55 witness baseline: **61** actual Native predecessor calls, **3,538** shared writes (58 per call), **zero** additional Native queries by derived PATCH27. These are facts for the Stage55 **prebuilt-request witness**, not a promised total for a new two-argument production request factory.
- For that identical prebuilt-request path, the post-Stage55 **tuple projection** may introduce **zero** additional Native queries, and no re-run of Seal32 to calculate membership or month ordinal.
- For a self-contained public factory, count all incremental real Sauce/gate/choice calls and 58-write sequences separately, with a strict arithmetic reconciliation `writes == 58n * calls`. Document and test any unavoidable new construction calls; do not falsely report the old baseline as a universal 2-argument budget.
- Bounded Native CI must use a measured fixture set and timeout budget; no exhaustive full-range iteration, uncontrolled year walks, or cache growing without a cap. Never convert unbounded signed `bigint` to `number` except after proving the year-local offset is in `[0,5777]`.

## 5. Independent verification and acceptance matrix

All of the following are required before claiming final-date integration PASS:

1. **Typecheck and API guard:** `npm run typecheck`; actual callable two-argument `calendarDateSpaghetti`, exact five-tuple return, rejects `number`, `NaN`, strings, null, and malformed runtime inputs. `Object.isFrozen(result)` is true; no public sixth field.
2. **Independent oracle differential:** under `test/` only, compare against independently computed `NormativeOracle.calendarDate(c,t)`. Start with at least **six bounded distinct (c,t) pairs** representing past/future/same-day, an exact gate, first/last year day, and a different year. Record all pair values, total queries, zero or precise mismatches. Do not reuse production selectors to generate expected values. A simple naming match alone is insufficient.
3. **Boundary/property tests:** for the actually generated 2-argument year, test cutlet first/last day and neighbor, year first/last day and cross-year neighbor, dispersed months with nonadjacent occurrences, 1-based prefix ordinal, repeatability and canonical names lock. Check `sum(monthLengths) == L`, weaving member counts match month lengths and `1 <= ordinal <= monthLength(monthId)`. At least **39 local interleaving checks** and the **real Year5000 day239** nonmembership witness survive; report exact counts, not guessed passes.
4. **Ownership/fault test:** inject a deep Stage14/Stage24 Native exception, prove no partial outward state; retry under a clean owner; prove a second call does not share mutable state. A second use of a consumed owner must be rejected where applicable.
5. **Native accounting:** report total actual calls and writes; reconcile `58 × calls`; Stage55 derived membership adds zero Native queries. No test-only request builder or oracle is reachable from `src/`.
6. **Regression and lock:** the full prior `npm test` suite, dedicated final-date test markers, existing Stage54/55 expected-red proof, and canonical 17/47 names verification remain green. Existing tests that assert the *deliberate throw* in `test/run.ts` and `test/patch27.ts` must be updated only in the later implementation commit, to assert final production semantics rather than preserving the obsolete barrier.
7. **CI evidence:** both `verify` and TypeScript Native jobs reach **completed/success on the exact integration SHA**; inspect full logs for typecheck, prior-stage guards, dedicated final-date differential/Native markers, zero unanticipated mismatches, and names lock. Queued/in_progress is neither PASS nor blocker. Do not rerun a completed prior SHA simply to duplicate PASS.

## 6. Delivery gates and next executable step

**Gate A — contract:** this document is reviewed against the actual production source and the preexisting requirements; capture any request-factory feasibility gap before changing `calendarDateSpaghetti`. A contract commit is not an integration PASS.

**Gate B — first implementation change:** introduce a **production-only** `(c,t) -> Patch20StructureRequest` builder, with narrowly scoped native ownership/trace and a bounded unit test; do not yet change the public final API if source dependencies remain unverified. Make the builder's real outputs and costs measurable, not oracle-derived.

**Gate C — projection:** extract from the already verified Stage55 full-chain result the corrected year, cutlet intervals and unique names, legal weaving, corrected month names and the prefix occurrence; assemble the exact tuple and replace the throw. Use checked in-year indexing and preserve the historical diagnostic objects.

**Gate D — acceptance:** dedicated differential, malformed-input, boundary, Year5000 gap, rollback/retry, Native budget, previous suite and names lock; completed CI logs on the final integration SHA. Only then may the branch be marked integrated. No merge into `main`, no release and no Stage56.
