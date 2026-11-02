# Pastafarian Calendar - J + Romanian

This is an independent implementation line started from zero. The programming language is J and the human source language is Romanian. Stage 1 and Stage 2 have been accepted by native execution; Stage 3 / PATCH 01 is prepared for native verification and is not yet accepted.

## Stage 1 scope

Stage 1 freezes the source-language catalog, builds a test-only normative reference directly from the embedded specification, prepares neutral monster infrastructure, and defines a local test harness. No legacy defect or patch from stages 2-53 is present in the initial skeleton.

## Independence rules

No other calendar implementation was cloned or consulted. Tests, fixtures, expected results, generated tables, traces, or hashes were not copied from another line. The normative reference in `test/normative_reference.ijs` is written for this line exclusively from the Stage 1 specification.

## Running

For native Windows verification, use the versioned Native QA package prepared for the current stage. The J 9.7.1 runtime is downloaded and SHA256-verified by the runner.

The Stage 1 local command remains:

```text
jconsole test/complete_stage01.ijs
```

## Numeric precision

All normative calculations use J extended integers (`x`) and, where an intermediate division is necessary, exact operators that preserve the integer/rational domain. Floating-point arithmetic is not used for normative decisions. PATCH 01 normalizes accepted integral days, including rational inputs with denominator 1, to extended integers before calculating the five work values.

## Development status

Stage 1: 63/63 Native PASS. Stage 2: 17/17 Native PASS. Stage 3 / PATCH 01: prepared for Native QA, awaiting results; the public path remains `NOT_INTEGRATED`.
