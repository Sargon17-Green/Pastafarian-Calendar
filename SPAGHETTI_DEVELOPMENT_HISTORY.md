# Spaghetti monster development history

## Stage 1 - Bootstrap - accepted

### Initial state

Nothing. The J + Romanian line started in an empty tree, exclusively from the specification supplied for this line.

### What was built

Only neutral, general mechanisms were introduced: an invocation context, phase dispatcher, base validator, deterministic error wrapper, metrics registry, and non-semantic logging. None contains knowledge of legacy defects or patches 01-26.

A normative test reference was also created in J, separate from the production skeleton. The reference is not available as a production fallback.

### Source-language catalog

The Romanian catalog was frozen in Stage 1. Semantic order is defined exclusively by `canonicalIndex`; Romanian text does not participate in sorting, rank, unrank, semantic caches, or selection.

### Monster layer

The added layer is intentionally modest and neutral: context + dispatcher + validator + error wrapper + metrics. It is observational or structural and does not change normative results.

## Stage 2 - DISCOVERY 01 - accepted

An independent J production path was introduced for five work values: calculation-day label, target-day label, inclusive distance, sum, and direction. The result remains only in `semanticPending` in the context, while the calendar API continues to declare `NOT_INTEGRATED`: the five final date components do not yet exist.

Stage 2 tests are separate from the 63 Stage 1 checks and use explicit expected values, including reverse direction, crossing the foundation, and extended integers. There is no oracle import in production. Stage 2 was accepted by native J9.7.1 execution on Windows: Stage 1 63/63, Stage 2 17/17, exit code 0, manifest 26/26, and 19/19 Git blobs verified.

## Stage 3 - PATCH 01 - prepared for Native QA, not accepted

Independent review of Stage 2 identified a representation defect: the validator accepts exact rational inputs whose value is an integer, but mixed calculations preserve/promote the rational type (128). Thus the five work values can be rational instead of extended integer (64), although their values are exact integers.

PATCH 01 canonicalizes each day after validation: `2 x:` extracts numerator and denominator as extended integers, denominator is checked as 1, and the day is stored as an extended integer in the context and production calculations. Stage 2 formulas are unchanged. The normative reference remains test-only and the public path remains `NOT_INTEGRATED`.

The new suite `test/stage03_patch01_tests.ijs` covers the fixture type, forward/reverse/same-day results, a large rational integer, type 64 for results and context days, fractional rejection, and preservation of `NOT_INTEGRATED`. Stage 3 acceptance depends on native Windows J9.7.1 results; until then Stage 3 remains unaccepted.
