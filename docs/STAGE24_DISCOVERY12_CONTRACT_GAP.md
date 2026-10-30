# Stage 24 / Discovery 12 — Contract preflight (NOT OPENED)

**Project:** PowerShell+Tagalog  
**Review date:** 2026-10-30  
**Branch before this review:** `PowerShell+Tagalog` at `524bc7686bce06a208ebbb90debb4cf1be03ac07`  
**Status:** BLOCKED — missing exact Stage 24 historical-defect contract; this document is an evidence artifact, not a Stage 24 implementation or approval gate.

## Scope and verified evidence

The branch's `DEVELOPMENT_STAGE.md` states `TOTAL_STAGES=55`, `CURRENT_STAGE=23`, `LAST_COMPLETED_STAGE=23`, `CURRENT_PATCH=11`, and `STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED`. The completed Stage 23 native Windows PowerShell 5.1 finalizer-idempotency gate is recorded in [GitHub Actions run 40708873568](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40708873568). **This review did not rerun that CI gate.**

A bounded source-inspection preflight completed **7/7 static checks**:

1. Stage 23 sealed/green metadata is present — PASS (static read).
2. Stage 24 is not opened in metadata — PASS (static read).
3. Independent oracle defines the order-successor operation — PASS (static read).
4. Stage 23 test explicitly guards against premature `biasedLegacyPick`, `queriedNextBowl`, and Patch 12 code — PASS (static read).
5. Development history ends at Stage 23 and says Stage 24 Discovery 12 is not yet included — PASS (static read).
6. Architecture notes exclude Patch 12 next-bowl logic — PASS (static read).
7. README names Stage 24 Discovery 12 and calls for contract/plan verification first — PASS (static read).

These **are not seven PowerShell unit tests** and are not native, differential, Stage 24, or CI PASS.

## Defined normative operation

The test-only oracle at `oracle/NormativeCore.ps1`, `Get-NormNextBowlInDrop46Order`, defines:

```text
order := SauceResult.OrderAtDrop46 // permutation of six bowl IDs
p := indexOf(order, QueriedBowlId) // zero-based
if p < 0: error
normativeNext := order[(p + 1) mod 6]
```

This uses the **corrected drop-46 order**, not the post-stir general order memory. Stage 23 protects that corrected order in a distinct latch.

For illustration only (NOT an authenticated production fixture): with `order=[4,1,6,2,5,3]`, query `6` returns `2` and query `3` wraps to `4`.

## Unresolved, material specification

Stage 23 reserves future code names `biasedLegacyPick` and `queriedNextBowl`, and the README identifies Discovery 12 as the next stage. **Neither provides a definition of the faulty historical picker** or an exact Discovery 12 test contract.

At least these incompatible historical defects could produce red cases, and the verified branch sources do not select among them:

- choose the numerically consecutive bowl ID, disregarding the drop-46 permutation;
- use the overwritten post-stir order in place of the drop-46 latch;
- perform a biased pick based on an as-yet-undefined weighting or rank.

Do not select a defect solely from the function name, and do not borrow a sibling implementation's behavior as a substitute for this branch's contract.

To implement Stage 24 deterministically, the project needs a *versioned, authoritative stage specification* establishing (a) the exact `biasedLegacyPick` rule and inputs; (b) where the legacy picker executes in the live production path; (c) required fixed fixture/query IDs and expected `EXPECTED_RED` versus incidental matches; and (d) invocation-owned state, observability-neutrality, boundary and failure requirements. Those cannot be deduced uniquely from the normative successor function.

## Safe next action and completion gate

1. Supply/locate the authoritative Discovery 12 faulty-picker contract and exact expected red probes, or make an explicit substantive choice among incompatible designs.
2. Revalidate live HEAD before writing. Keep Stage 23 semantics and historical scar untouched.
3. Open Stage 24 only after the contract is resolved, implement the specified discovery path and bounded tests, run the native PowerShell 5.1 CI gate, and retain the run ID, SHA and artifact.
4. Keep `main` unchanged. Do not mark Stage 24 PASS until actual evidence exists.

**Changes in this preflight:** documentation-only evidence artifact. No Stage 24 runtime code, stage metadata, tests or CI reruns.