# Stage20 — initial bowls (design and independent mathematical oracle)

Project: PC-BRANCH-FALSE-ARABIC · branch `FALSE+العربية` · stage 19 remains last accepted (bounded).

## Pinned normative specification

`test/normative_reference.false` Git blob `3e9acc012bedf83294a6ec3cccb081a069556b5b`, operation **54**, reads five fields of `workCounts` and produces six positive BigInt quantities. This project will implement an independent op37 using a **direct heap table**, not the immutable sequence representation of the test reference.

An allocated unary argument `[countsHandle]` refers to exactly six allocated cells `[5,C,T,D,S,q]`: four canonical nonnegative BigInt handles and one small direction integer `q∈{1,2,3}`. Output will be a newly allocated seven-cell direct table `[6,B1,B2,B3,B4,B5,B6]` containing six canonical BigInt handles. Neither the argument nor the counts table nor any input BigInt cell may change. Numeric output must be deterministic; output handles need not be identical between calls.

For `M=2^127-1`, `c=(17,19,23,29,31,37)`, and `i=1..6`, let `x_i=C+i*T+D+S+q+c_i²+i`. All `x_i>0`. Define `B_i=1+((x_i-1) mod M)`, so a positive multiple of `M` maps to `M`, not zero. The input-output map is not invertible; no inverse is claimed.

## Executed testable oracle

`tools/stage20_initial_bowls_design_oracle.mjs` does not import production, the reference program, or fixtures. Direct exact BigInt evaluation and a recurrence with independently implemented Mersenne folding are cross-checked. Local mathematical QA: **397 cases** (13 anchors, 384 deterministic seeded), **2382 numeric comparisons**, **1985 adjacency checks**, **397 frozen-input nonmutation checks**, six invalid input shapes rejected, five wrong-algorithm witnesses rejected and one deliberately corrupted expected result detected. Explicit anchor `[0,0,0,0,1]` yields `[291,364,533,846,967,1376]`; a deliberately constructed positive multiple of M returns M.

These checks are local JavaScript mathematical QA only — **not FALSE Native, CI, differential comparison, or Stage20 acceptance**. Vectors and summary live under `test/` and `evidence/` in the same commit.

## NEXT and hard gates

Implement a new production op37 without rewriting accepted op0..36. Add independent fixtures and test valid count records, invalid headers 4/6, invalid direction 0/4, Base512 sign/count/digits, six BigInt outputs, unchanged heap input, deterministic repeats, and mutant expectations. Source-lock a GitHub Actions job to the original FALSE interpreter commit `eb3135565a8670cced3f6bbca4dbf7b014c45634`; do not dispatch duplicate runs. Full acceptance needs completed run/job/log/exit/stderr, artifact SHA256 and CRC, Git source blob pinning, and independent offline audit with corrupted-evidence rejection.

Excluded: unallocated pointers, physically truncated tuples or tables, corrupt heap, and invalid handles; FALSE does not provide safe extent metadata. Do not claim those are tested. No main/merge or release.

## Stage20 implementation checkpoint (2026-11-23)

Independent production op37 was appended only to `src/monster_bootstrap.false`, preserving the byte-for-byte prefix that contains operations 0..36. It reads `[5,C,T,D,S,q]`, checks the header/direction and nonnegative signs, builds `C+D+S+q`, adds `i*T+(c_i)^2+i`, applies the existing positive `SAVE` (op25) and materializes a contiguous fresh seven-cell table only after all six BigInt calculations. The six temporary result handles are stored in newly allocated scratch cells, avoiding noncontiguous output tables. This is a production SOURCE CHANGE and bracket/prefix STATIC QA only. No original FALSE interpreter has executed this new operation yet. Native/CI/differential/acceptance remain NOT_RUN/NOT_ACCEPTED. Next: construct source-pinned executable Native fixtures and a separate offline artifact auditor, and inspect the resulting completed run/job before claiming PASS.
