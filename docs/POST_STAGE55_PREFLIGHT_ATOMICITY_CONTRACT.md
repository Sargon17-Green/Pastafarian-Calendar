# Post-Stage55: preflight atomicity and one-step Native budget QA

Project: PC-BRANCH-TYPESCRIPT-MARATHI / TypeScript+मराठी
Parent: 2b766162b0e7917d0b8500614e1086dfaf61a835
Prerequisite: exact-SHA Actions 41711700565 completed/success, five of five jobs; negative signed marker with seven pairs, 35 components, five independently ranked families, zero mismatches and physical Patch11 856 calls / 49,648 writes.
Scope: test, package and workflow only. This is NOT Stage56, NOT a new calendar rule, and NOT a permission to merge or release.

## Coverage gap and choice

Accepted public positive/negative date tests verify correctness but do not measure whether invalid typed arguments and malformed execution budgets consume physical Patch11 Native work before rejection. The signed gate factory accepts an explicit positive safe-integer per-side execution budget. This add-on tests the early rejection contract and the first valid budget boundary, without duplicating expensive year-wide differential cases.

## Input, output, independent assertion

Ninety-seven rejection probes: nine invalid runtime day representations (number zero, NaN, Infinity, string, null, undefined, object, array and boolean) across both argument positions in four public/production entrypoints = 72; eight invalid gate budgets in the prefix and request factory = 16; seven invalid year-walk budgets = 7; two enormous signed bigint inputs accompanied by invalid zero budgets = 2. Every probe must throw MonsterValidationError and complete zero physical Patch11 runs and zero memory writes. Invalid numeric types must not be silently coerced.

One valid-bounded probe: calculation and target day equal FOUNDATION_DAY + 1n, maxPerSide = 1. The first real positive gate gap is 41 + rank with rank in [1,922], thus at most 963 days. A prefix must cover the requested upper neighbourhood at radius 5782 days, so a single gap cannot meet the coverage precondition. Its next iteration must reject the budget before a second Native run. Require exactly one completed physical Patch11 call, exactly 58 writes, and MonsterValidationError; any success, unexpected exception, or a second call fails. Count physical Patch11.run results, not only Patch14 dispatches. Always restore the prototype in finally.

## Acceptance and boundaries

Run this test once in the existing Stage27 npm test chain, without adding a sixth heavy CI job. Exact marker:
POST_STAGE55_PREFLIGHT_ATOMICITY_PASS malformedRejected=97 preflightNativeCalls=0 boundedNativeCalls=1 boundedSharedWrites=58 budgetExhausted=1

The existing five jobs remain required. Exact-SHA completed/success plus actual marker in the Stage27 log is required before accepting this follow-up. Syntax validation alone is not runtime/Native PASS. No src changes, Stage56, main merge, release, or external publication.
