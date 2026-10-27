# Post-55 Kotlin+Cymraeg exact weaving maintenance evidence — 2026-10-27

**Scope:** Stage-55/post-55 maintenance only. This is a **component verification**, NOT full-date certification, NOT an independent cross-engine soak certification, and NOT approval for another stage.

## Changed production and test files

- [ProductionMonthWeavingEngine.kt](../../src/main/kotlin/pastafari/ProductionMonthWeavingEngine.kt) — exact suffix counting by inserting months in canonical ordinal order, tracking the position of each month's first residual occurrence. Replaces an exponential memoized state traversal with one-dimensional coefficient DP. State/work budgets fail closed and the LRU cache has 4,096 entries.
- [Post55ProductionWeavingTests.kt](../Post55ProductionWeavingTests.kt) — extends brute-force test families and adds an 84+84+84 exact-count regression (252 days), first/last rank checks, and resource-cap failure check.

**Code commit:** faea7a142e370622e7c0612797b9dcc8f1c59f62

## Local reproducible execution

Environment: kotlinc-jvm 1.9.0; OpenJDK 21.0.12.1.

Compiled exactly these two Kotlin files:

~~~sh
kotlinc ProductionMonthWeavingEngine.kt Post55ProductionWeavingTests.kt -include-runtime -d test.jar
java -cp test.jar pastafari.Post55ProductionWeavingTests
~~~

Observed stdout:

~~~text
POST55_PRODUCTION_WEAVING_SYNTHETIC_428_GREEN
POST55_WEAVING_LONG_252_DAYS_EXACT_GREEN
POST55_WEAVING_COMPONENT_NOT_FULL_DATE_CERTIFICATION
~~~

Exact recorded blob hashes matching locally compiled source:

- ProductionMonthWeavingEngine.kt: f60cf91e21bab3da717aea71ad8c613e570f7e9a
- Post55ProductionWeavingTests.kt: e0b14e3e8263e91508ee02f2ab62fd6a91c1ed90

An auxiliary Python brute-force state enumerator compared the counting recurrence against all reachable suffix states for 11 small examples containing lengths 1–3 and 2–4 months; no mismatches. This is **not** a Python+Türkçe independent full-date differential.

## Unverified / next gate

No compilation of Post55ProductionDateBridge.kt together with the entire production Kotlin source tree was performed in this run. The FOUNDATION±1 and TABLETS±1 seven-field boundary cases, malformed-input behavior with real production engines, and bounded diagnostic with the separately SHA-pinned Python+Türkçe engine remain unverified. The 252-day synthetic case is not a production calendar date.

The bridge's --certify provenance gate must remain closed. No main modification or PR merge occurred.
