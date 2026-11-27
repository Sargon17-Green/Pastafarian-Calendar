# Pastafarian Calendar - Fortran / English line

This directory grew from the Stage 1 bootstrap of an independent implementation line. It was created from an empty project tree from the embedded specification supplied for this line. No implementation, test, fixture, generated table, checksum, trace, cache, or expected output from another implementation line is used.

## Language contract

Fortran is the only programming language used for executable project code. English is the only human source language used for project prose and the adopted English display names. Machine identifiers remain conventional Fortran identifiers.

## Stage 1 scope

Stage 1 contains only neutral bootstrap infrastructure and a clean test-only reference oracle. It deliberately contains no legacy defect, no historical patch, and no compatibility flag belonging to Stages 2 through 53.

The bootstrap includes:

- an arbitrary-precision signed integer implementation written in Fortran;
- a frozen version 1 English SourceLanguageCatalog with 17 cutlet names and 47 month names;
- neutral base context, dispatcher, validation, error-recording, and metrics shells;
- a test-only clean reference oracle implementing discrete-day arithmetic, sauce construction, answer streams, short and wide rank selection, gate generation, year construction and walking, cutlet structure, month structure, exact ordered-family counting and unranking, legal month weaving, and the final five-field calendar result;
- a Fortran-only Stage 1 test harness.

The physical-instant to discrete-day conversion is not implemented because the current canonical corpus does not yet define a canonical numerical astronomy profile.

## Build and test

Run:

```text
./run_tests.sh
```

The script only compiles Fortran sources and runs the resulting Fortran test executable. It contains no algorithmic shell logic.

## Semantic boundaries

The production-side bootstrap infrastructure does not call the reference oracle. The oracle lives under `test/` and is test-only; it is a verification tool, not a parallel canonical authority. The Stage 1 production skeleton contained no calendar algorithm. Stage 2 opens the historical spaghetti path with Discovery 01 only.

## Stage 2 - Discovery 01 (open)

The production path now executes the historical raw Euclidean remainder, which returns zero for exact multiples of M instead of M. The invocation owns its input and result; the test-only oracle remains isolated. See [the acceptance contract](test/STAGE02_DISCOVERY01_CONTRACT.md). Patch 01 is not implemented. Native acceptance is pending.
