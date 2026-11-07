# Stage 1 Native invalid-input semantic ownership — QA extension

The existing 64-run writer/g provenance audit covers 32 valid inputs,
each with the original fork and forced opposite fork. This additional
job evaluates 21 actual rejected inputs: six invalid numeric cases and
fifteen malformed lexical strings from the existing native lexical QA.

Every Native PyFunge run must terminate with exactly seven -1 sentinels.
Post-source-load hooks observe execution-time Space.put and Space.putspace.
Each actual top-level g read is checked against the latest observed p write
to that coordinate or the original pinned source byte. Every engine-level
put must be attributable to a p step, and all executed k targets must be
different from g or p. An independent Python 3 evidence verifier validates
the complete invalid corpus and rejects eight falsified reports.

Scope: finite real-PyFunge input corpus, not universal coverage of all
memory APIs, hidden nested dispatches, full functional or geometric
acceptance, or final semantic ownership. Stage 1 remains OPEN.
No changes to canonical Befunge+Кыргызча, main, or PR #17 merge status.
Exact-head CI verification is required before calling this audit PASS.
