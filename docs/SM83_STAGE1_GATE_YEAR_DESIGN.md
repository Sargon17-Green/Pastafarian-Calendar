# Stage1 bounded gate stream and year-candidate histogram

**Status:** design and independent Host property test added; no Native gate-stream or year-selection PASS is claimed.

**Normative source:** main README at commit 56bc4173aae4975ded019ef5ab5a36249f1424df, sections O–R and AC.1. The executable source-pair primitive is Native394 on the implementation branch.

## 1. Bounded gate window

Let F be Foundation and let c be the calculation day. The runtime stores c as a signed 32-bit offset from F. Gate offsets from F are strictly increasing:

- G(0) = 0.
- G(n) = G(n-1) + positiveGap(n), for n > 0.
- G(-n) = G(-(n-1)) - negativeGap(n), for n > 0.
- Every gap is in [42, 963].

For year selection, only gates in the inclusive search window [c - 5778, c + 5778] can participate. The year itself is the half-open interval (openGate, closeGate], with at least six gate intervals and a length in [252, 5778].

Because distinct gates are at least 42 days apart, each side of c contains at most:

~~~text
floor(5778 / 42) + 1 = 138 gates
~~~

The bounded gate window therefore contains at most 138 opening gates and 138 closing gates. The Cartesian upper bound is 138 × 138 = 19,044 candidate pairs. The implementation must fail closed if the configured gate-index horizon cannot cover both edges of the requested window; it must not silently truncate the candidate set.

The proposed ROM representation is a source-derived table of 1,025 signed-32 gate offsets from Foundation for indices -512 through +512 (4,100 bytes). It is a compiled cache of the normative recurrence, not a canonical-output fixture. A build-time Host verifier must regenerate every entry from the independent sauce/selection oracle and compare the complete table. Native394 remains the executable check of the underlying gap primitive. The Native gate-stream implementation can binary-search the monotonic table for the first gate at or after c - 5778, then stream until the first gate beyond c + 5778. Each retained offset relative to c is in [-5778, 5778] and fits signed 16-bit storage. The final table/bank-switch layout remains subject to RGBDS, linker-map, ROM-header and PyBoy verification.

## 2. Candidate contract

The gate stream is stored in ascending gate-index order. Split it into:

- opening gates with gate < c;
- closing gates with gate >= c.

A pair is eligible exactly when:

~~~text
closeIndex - openIndex >= 6
252 <= closeGate - openGate <= 5778
~~~

The sort key is exactly:

~~~text
(closeGate - openGate, openGate)
~~~

Thus shorter years come first; equal-length years are ordered by the earlier opening gate. Since the gate stream is strictly increasing, the opening-gate order is also the opening-index order.

The full span key space contains:

~~~text
5778 - 252 + 1 = 5527 distinct integer span buckets
~~~

The runtime must not allocate or sort a 19,044-entry candidate array.

## 3. Two-level radix histogram

A full 5,527-byte histogram is unnecessary. Split each 16-bit span into its high and low bytes:

- high byte: 0..22, so 23 unsigned-16 counters (46 bytes);
- low byte: 0..255, so 256 unsigned-8 counters (256 bytes), populated only for the selected high byte.

The counter bounds are proven from the gate spacing:

1. A fixed opening gate can have at most floor(255 / 42) + 1 = 7 closing gates in one 256-wide high-byte band. With at most 138 openings, a high-byte counter is at most 138 × 7 = 966, so 16 bits are sufficient.
2. Once the high byte is fixed, each low byte identifies one exact span. A fixed opening gate has at most one closing gate at that exact span. Therefore each low-byte counter is at most 138, so 8 bits are sufficient.

Selection proceeds without sorting:

1. Enumerate all eligible pairs once and accumulate the 23 high-byte counters. Their sum is N, the candidate count; require 1 <= N <= 19,044.
2. Compute the normative answer flow for (c,c), bowl 1, seal 10, and obtain the selected rank in 1..N. For NEXT/PREVIOUS the same radix kernel can use the corresponding fixed endpoint and seal 11/12.
3. Subtract high-byte bucket counts in ascending order to identify the selected high byte and the rank within that bucket.
4. Enumerate pairs again, populate the 256 low-byte counters only for that high byte, and subtract in ascending low-byte order to identify the exact span and rank within that span.
5. Scan opening gates in ascending order and find the rank-th eligible pair with that exact span. This implements the opening-gate tie-break directly.

The runtime visits at most 19,044 pairs per pass and never stores the full candidate list. The full 5,527-span key space is represented by the two radix levels.

## 4. WRAM budget and isolation

The three principal buffers require:

| Buffer | Bytes |
|---|---:|
| 276 signed-16 gate offsets | 552 |
| 23 unsigned-16 high counters | 46 |
| 256 unsigned-8 low counters | 256 |
| **Total** | **854** |

The Native394 MAP reports 1,044 bytes free in WRAM0, leaving 190 bytes for scalar state and bounded loop variables before any further changes. This is a budget, not a final link claim: every Native candidate must be re-measured from its own MAP, with ROM0 free >= 10.

This design does not borrow or mutate owner payload, lease tags, or SRAM. It does not require an extra scratch-SRAM lease. If the final assembly state exceeds the remaining WRAM budget, the implementation must be redesigned or measured differently; it must not silently use caller-owned SRAM.

## 5. Host evidence and Native boundary

The new Host test compares the radix selector against a separately full-sorted candidate list over 1,000 deterministic nonempty bounded windows, checks first/middle/last ranks on a subset, stresses a 137-member equal-span bucket, and checks the source-derived Foundation window using the real bowl-1/seal-10 answer flow (43 candidates, rank 15).

This establishes only the Host candidate-ordering design. It does not establish the Native table, Native histogram, year5000, NEXT11, PREVIOUS12, or the five-field calendar. Those require a separate isolated Native milestone, exact-SHA CI logs, measured ROM0/WRAM/ROMX maps, ROM-header verification, bounded PyBoy A5/395/40 evidence, regression jobs, and artifact ROM/MAP/SYM readback.

## 6. Next implementation milestone

Implement the source-derived gate table and bank-2 read path, the bounded gate-window builder, and the two-level radix candidate selector as an isolated Native395 target. Keep the accepted Native370..394 targets unchanged. Do not change main, merge, release, or start Stage2.