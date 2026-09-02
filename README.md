# Pastafarian Calendar - Fortran / English line

This directory is the Stage 1 bootstrap of an independent implementation line. It was created from an empty project tree from the embedded specification supplied for this line. No implementation, test, fixture, generated table, checksum, trace, cache, or expected output from another implementation line is used.

## Language contract

Fortran is the only programming language used for executable project code. English is the only human source language used for project prose and canonical display names. Machine identifiers remain conventional Fortran identifiers.

## Stage 1 scope

Stage 1 contains only neutral bootstrap infrastructure and a clean test-only normative oracle. It deliberately contains no legacy defect, no historical patch, and no compatibility flag belonging to Stages 2 through 53.

The bootstrap includes:

- an arbitrary-precision signed integer implementation written in Fortran;
- a frozen version 1 English SourceLanguageCatalog with 17 cutlet names and 47 month names;
- neutral base context, dispatcher, validation, error-recording, and metrics shells;
- a test-only clean normative oracle implementing discrete-day arithmetic, sauce construction, answer streams, short and wide rank selection, gate generation, year construction and walking, cutlet structure, month structure, exact ordered-family counting and unranking, legal month weaving, and the final five-field calendar result;
- a Fortran-only Stage 1 test harness.

The physical-instant to discrete-day conversion is not implemented because the embedded normative reference explicitly leaves the numerical ephemeris model undefined.

## Build and test

Run:

```text
./run_tests.sh
```

The script only compiles Fortran sources and runs the resulting Fortran test executable. It contains no algorithmic shell logic.

## Semantic boundaries

The production-side bootstrap infrastructure does not call the normative oracle. The oracle lives under `test/` and is test-only. The Stage 1 production skeleton has no calendar algorithm yet; the historical spaghetti path begins only when Stage 2 introduces Discovery 01.
