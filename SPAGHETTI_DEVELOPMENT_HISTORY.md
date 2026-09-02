# Spaghetti Development History

## Stage 1 - Bootstrap

### What existed

Nothing from an earlier implementation line. This line started from an empty project tree.

### What was established

The line fixed Fortran as the only executable programming language and English as the only human source language. A frozen SourceLanguageCatalog v1 was created with stable canonical indices. A Fortran-native arbitrary-precision integer layer was added because 128-bit machine integers cannot safely hold every required intermediate or combinatorial count.

A clean test-only normative oracle was implemented from the embedded normative reference. Neutral production-side infrastructure was also introduced: a base invocation context, dispatcher, validator, error-recording shell, and metrics shell.

### Monster architecture added in this stage

Only neutral bootstrap scaffolding was added. The base dispatcher and context establish a place for later historical growth, but no future legacy defect, patch-specific flag, compatibility detour, cache scar, ghost computation, or historical manager is present.

### Why the bootstrap layer does not change semantics

The production bootstrap does not yet implement calendar semantics. The test-only oracle is isolated under `test/`. Metrics and trace fields in the production bootstrap are observational and are not read by any normative computation.
