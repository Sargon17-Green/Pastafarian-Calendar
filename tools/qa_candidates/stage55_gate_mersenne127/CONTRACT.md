# Mersenne-127 exact-arithmetic candidate — QA only

## Why this candidate

The original LegacyRemainderAdapter.oldRemainder always applies the fixed modulus M = 2^127-1. It is called repeatedly by the inner bowl/stone compatibility routes. The baseline BigInt.regularMod delegates each operation to general multi-limb division. This candidate replaces only the internal reduction algorithm for that exact modulus. It does not memoize values and does not bypass any compatibility route.

## Exact reduction

The BigInt representation uses base B = 10^7. For each input limb d_i, processed from most significant to least significant, maintain 0 <= r < M and compute x = r*B + d_i.

Since r < M, x < M*B < 2^151. Split x = lo + hi*2^127, with 0 <= lo < 2^127 and 0 <= hi < B. Because 2^127 is congruent to 1 modulo M, x modulo M equals (lo + hi) modulo M.

The candidate stores lo as four little-endian uint32 limbs, with 31 live bits in the highest limb. The top-limb addition is explicitly bounded at bit 127 (not bit 128); any carry out of bit 126 is folded back as +1. If the resulting 127-bit value equals M, it is mapped to zero. The fold is sufficient because lo+hi < 2^127+B.

The largest per-limb intermediate is below 2^56, so it fits exactly in uint64. Converting the final four uint32 limbs back to base 10^7 also uses intermediates below 2^56.

For negative input, first reduce its magnitude to r; if r is nonzero, return M-r, otherwise return zero. This is the same nonnegative remainder as floor-based regularMod.

## Immutable scope

The patcher requires the exact baseline commit and exact original BigInt, GateQuestionEngine, and LegacyRemainderAdapter blobs. It changes only src/+pastafari/BigInt.m in a disposable checkout. The original LegacyRemainderAdapter and all route sources remain byte-identical.

## Native test contract

- Python arbitrary-precision divmod is the independent oracle for both floorDivMod and regularMod.
- Deterministic vectors include positive/negative inputs, boundaries around 2^127 and 2^128-1, the exact Mersenne modulus, one-limb divisors, and unrelated multi-limb divisors.
- The original and candidate run one profiled pass over the same 24 target days, plus two unprofiled timing passes (48 additional direct GateQuestionEngine calls).
- Each of the nine inner compatibility-route classes must be profiled exactly 24 times in each variant.
- All 48 unprofiled exact gap results must match between baseline and candidate; the first 24 must also match the profiled pass.
- Each variant is bounded by a 3 GiB MATLAB process-tree RSS ceiling and 10,000 s watchdog.
- Candidate performance gate: at least 1.5x faster in each of the two unprofiled timing passes.

## Non-goals and acceptance boundary

This is an isolated arithmetic experiment, not a Stage55 audit, not the 4,249-call public soak, and not production integration. A passing result only authorizes a separate bounded public pilot with the exact candidate SHA. No main/merge/release or stage advancement is implied.
