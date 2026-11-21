# FPC 3.2.2 managed-result warnings — bounded source audit (2026-11-21)

Project: `PC-BRANCH-OBJECT-PASCAL-PORTUGUESE`  
Authorized branch: `Object-Pascal+Português`  
Audited source commit: `6723533964faeebb1f615d2d49630e0a529a7943`  
Audited file: `src/BigInt.pas`, Git blob `25aa2b0f25c5d7694e9e057320f395253f543ef1`  
Scope: functions `AddAbs` and `SubAbs`, warnings at lines 220:19 and 246:19.  
Method: static source/control-flow review plus existing completed native-job log; **no new compiler or native execution**.

## Reproduced evidence in the existing job log

- Native workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896224487
- Native job: `136822345956`, completed/success, Ubuntu FPC 3.2.2, on the audited SHA.
- Exact diagnostic (repeated when multiple programs compile the unit): `BigInt.pas(220,19) Warning: function result variable of a managed type does not seem to be initialized` and same wording for `BigInt.pas(246,19)`.
- Names Lock workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896224456, job `136822345715`, completed/success.
- Native artifact: `14704187799`; published SHA-256 `c8e380345e1d9f39767103bb2e0e9a06400543ca24bb110ac6560af2bba92404`. Prior evidence review: 30 suite exits 0, 22,977/22,977 aggregate assertions; **not re-executed here**.
- Historical Stage 1 provenance for the original October 12/13 source patch remains unavailable; **Stage 1 overall is not accepted**.

## Exact data-flow audit

`TBigInt` is a record with `Sign: ShortInt` and `Digits: array of UInt32`. The dynamic-array field makes the record managed. `BIG_BASE = 10^9`.

### `AddAbs(A,B)` (warning at 220)

1. Compute `N=max(Length(A.Digits),Length(B.Digits))`.
2. First use of the result's managed field is `SetLength(Result.Digits,N+1)`, immediately followed by `Result.Sign := 1`. This is the warning site, not a read of an arithmetic digit.
3. Initialize `Carry := 0`. For every `0 <= I < N`, construct `Cur := Carry + optional A[I] + optional B[I]`, write `Result.Digits[I] := Cur mod BIG_BASE`, update `Carry := Cur div BIG_BASE`.
4. If carry is nonzero, assign `Result.Digits[N]`; otherwise shrink the result to `N`. `Normalize(Result)` removes trailing zero limbs and sets the zero sign.
5. No `Exit` statement exists inside this routine. Even with `N=0`, the unused extra allocated limb is shrunk away before normalization. For canonical inputs, `Carry <= 1` and `Cur <= 2*BIG_BASE-1`, safely in `UInt64`.

### `SubAbs(A,B)` (warning at 246)

1. Enforce `BigCompareAbs(A,B) >= 0`; otherwise raise `ERangeError` *before* constructing a result. Exception path does not return a value.
2. Allocate `Length(A.Digits)` result limbs, then set `Result.Sign := 1`.
3. Initialize `Borrow := 0`; on each `I=0..High(A.Digits)`, compute `Cur=A[I]-Borrow-optional B[I]`. If negative, add `BIG_BASE` and set `Borrow := 1`, else set `Borrow := 0`. Assign every `Result.Digits[I]`.
4. `Normalize(Result)` yields the canonical zero representation on equality; with zero-length inputs the loop has no iterations and normalization sets sign to zero.
5. No early `Exit` exists after the length assignment. `SubAbs` is called from `BigAdd` for unequal absolute magnitudes and from `BigDivModPositive` for subtraction of a bounded divisor multiple.

### Managed-result semantics and conclusion

Free Pascal explicitly documents that managed variables are implicitly initialized, and that its “function result variable of a managed type does not seem to be initialized” warning can occur on intended code. Reference: https://www.freepascal.org/docs-html/user/userse64.html (Symbol handling, warning text). See also https://www.freepascal.org/docs-html/ref/refse20.html (managed types); upstream report https://gitlab.com/freepascal.org/fpc/source/-/issues/35475 (SetLength-related warning).

In the reviewed paths, arithmetic limbs are initialized before they are read, the sign is assigned before normalization, and every successful return goes through normalization. **No concrete uninitialized-digit read, missing assignment on normal return, observable arithmetic error, or established test-coverage gap was found in this bounded review.** This is a static finding, not a proof of all possible runtime/ABI behavior. Do not relabel the warnings as an observed defect. No production edit or warning suppression is justified solely by the diagnostic.

## Independent repro/oracle contract, conditional only

Only if new evidence establishes a reproducible failure or uncovered input class, add a **separate** bounded native regression rather than replaying the accepted 30-suite run on an unchanged SHA.

- Inputs: decimal signed strings `a,b` forming valid canonical BigInt values, with focused categories: both positive, both negative, equal magnitudes of opposite signs, unequal opposite signs, carry propagation across `10^9` limbs, borrow propagation across multiple limbs, and zero normalization; include `-1,0,1,(10^9-1),10^9,(10^9+1),10^(9k)±1` for bounded `k=1..8`.
- Oracle: independently evaluate `a+b` and `a-b` using Python's arbitrary-precision `int`, not project Pascal code or copied fixtures. Compare exact canonical decimal output and repeat under FPC 3.2.2 with range/heap checking enabled; distinguish normal outputs from expected precondition exceptions for private `SubAbs`.
- Output: an input TSV, canonical expected outputs, native stdout/stderr, exact compiler version and exit code, complete source SHA and digest, and count of distinct test pairs; any failure must contain minimal reproducer, actual vs expected values and trace.
- Acceptance: zero oracle differences, zero unexpected exceptions, all selected cases executed, and a completed native job on the exact tested source SHA. A static review or queued job is **not** native PASS.
- Trigger: **not met** at this checkpoint; do not add an unmotivated duplicate regression.

## Decision and next bounded work

Disposition: **warning explained; no evidenced defect; static audit completed, no new native test, no production source change**. Preserve previously accepted native QA on the audited source SHA; committing this audit note does not retroactively certify any newer SHA. Preserve Stage 1's missing-provenance limitation.

Next permitted independent QA: inspect the *different* FPC implicit AnsiString/UnicodeString conversion warnings reported at `test/stage01_tests.pas` lines 151–153 for an observable Portuguese/Unicode data-loss risk. First trace the actual literals, type declarations and call sites; only add independent test vectors if an evidence-backed gap is found. No merge/main.
