# Stage27 / Patch13 — short rejection sampling

Branch: PowerShell+Tagalog. Previous sealed stage: Stage26 Discovery13 expected-red. Predecessor HEAD: 988c52ffdef10fe6165f388f66abcd16952f3b8c.

M=2^127-1. N must be in 1..M, First in 1..M, Step exactly -1 or +1. Compute limit=floor(M/N)*N; reject each stream answer x>limit; rank=1+((accepted-1) mod N). Advance cyclically in 1..M. Wide N>M belongs to a later stage, not this patch.

A contiguous rejected suffix permits a constant-time equivalent to iterative sampling: if First<=limit accept First with zero skips; if First>limit and Step=-1 accept limit after First-limit skips; if First>limit and Step=+1 wrap and accept 1 after M-First+1 skips. The historical first-answer modulo continues to run and remains queryable for comparison. Production uses only real Stage25 46+12 write context, Patch11 latch, Patch12 positional successor, and Stage26's existing stream. The normative oracle appears only in tests, never production.

Native acceptance requires Stage01/23/24/25/26/27 suites under Windows PowerShell 5.1, canonical names verify, Stage23 idempotency unchanged, preservation of four Stage26 expected-red witnesses, four repaired Stage27 cases, boundary comparisons for both stream directions and three real precursor histories. Stage27 remains AWAITING until the matching HEAD has completed/success Native logs; no merge to main.

Independent bounded algorithm check before commit: 56 boundary and direction cases tested against an iterative oracle, zero mismatches; this is NOT PowerShell Native.
