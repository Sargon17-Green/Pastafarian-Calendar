# DISCOVERY03 — bounded sparse-kernel differential QA (2026-11-04)

This research-only QA follows the existing sparse dual implementation; it
does not modify, fork, or replace that implementation and does not open Stage6.

For 137 small positive month-length families, construct up to three distinct
lexicographically representative accepted words using independent complete
enumeration. For each sampled proper prefix, compare the new sparse forward
transfer after every month against the prior dense transfer by expanding the
sparse vector. Test the transposed operator directly from its defining
matrix: (T^t a)[p] = sum_{i=p}^n a[i+1] * weight(i,...). Include both the
actual prefix spec and the hypothetical older-symbol spec. Use deterministic
signed adjoint vectors rather than all ones and verify the dot-product adjoint
identity. This strengthens the existing word-count/rank oracle by probing
the underlying operators with values not arising from positive word counts.

Expected bounded markers: 137 families, 1,988 sampled prefix states, 4,901
forward-transfer comparisons, and 9,802 transpose comparisons. Runtime
must be under 25 seconds (OS timeout 30 seconds), peak RSS <512 MiB. The
earlier independent finite word oracle remains authoritative for lexical
ranks. This QA does not establish performance for full median unrank/rank,
does not turn the old Chapel 180s timeout into a Legacy witness, and does
not claim overall CI success when the legacy year-weave remains inconclusive.

Local separate prototype previously validated the dense/single-gap fast path
for 137 families, 1,988 transitions, and 4,901 transpose comparisons with
signed vectors; the exact new sparse-interval implementation is accepted
only after this new script obtains completed CI/log evidence on its commit.
