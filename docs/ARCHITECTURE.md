# Bootstrap architecture

Stage 1 does not build the final monster in advance. The current architecture contains only neutral elements that can host later historical growth.

`src/monster_base.ijs` defines the invocation context, phase dispatcher, base validation, deterministic errors, and observational state. A context is created for one invocation and is not reused across calls.

`src/calendar_spaghetti.ijs` is only the production Bootstrap entry point. It validates input types, creates a context, and explicitly declares that the historical engine is not integrated. It does not call the normative reference.

`test/normative_reference.ijs` contains the clean test-only oracle. It is not loaded by production files.

`test/stage01_tests.ijs` checks local normative properties, the source-language catalog, and that the production skeleton does not import the oracle.

## Stage 2 - incremental work-count path

`src/stage02_counts.ijs` implements production day labels, inclusive distance, sum, and direction. `calendarDateSpaghettiBootstrap` calculates them after input validation and stores them in the context's `semanticPending` field. `MONSTER_STATUS_NOT_INTEGRATED` remains mandatory until the complete date calculation is integrated. `test/stage02_tests.ijs` tests this path with explicit expected values, without importing the normative oracle into production.

## Stage 3 - PATCH 01: canonical integral days

The validator accepts exact rational numbers when their value is an integer. In J, however, a rational value remains in the rational domain under operations such as `floor`; mixed arithmetic promotes extended integer operands to rational. Without canonicalization, a valid input such as `_15055671r1` can make the five work values type 128 instead of the extended integer type 64 required by the work-count contract.

`stage02CanonicalDay` extracts the exact numerator and denominator with `2 x:`, verifies denominator 1, and returns the numerator as an extended integer. `stage02CountForDay` and `stage02WorkCounts` use the canonical form; the public entry point also replaces the context's day values with that form after validation. No floating-point arithmetic is used, the five formulas are unchanged, and the oracle is not imported into production.

`test/stage03_patch01_tests.ijs` verifies that fixtures are genuinely rational type 128, results and context days are extended integer, forward/reverse/same-day behavior, a large rational integer, fractional rejection, and preservation of `NOT_INTEGRATED`. Stage 3 remains pending native Windows QA.
