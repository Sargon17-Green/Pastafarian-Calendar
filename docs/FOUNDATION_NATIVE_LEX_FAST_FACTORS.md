# Exact O(s) native SystemVerilog branch-factor optimization — Stage 1

**STATUS: source implemented, CI unverified.** Separate test-only module
`tests/tb_weave_native_lex_fast.sv`, runner `scripts/verify_native_lex_fast.sh`.
This does NOT implement production ASIC RTL. It reuses the 101,594-cell H
archive produced by native SystemVerilog and the independently SHA-locked rank;
neither the Python month-word nor its rank-interval ledger is read.

## Formula

Let `k` be the first still-positive started label. Every earlier label must
have zero remaining copies, and all labels `k..s` must be positive. Put
`R_j = sum(r_1..r_j)`.

The ordered-LAST combinatorial factor is

`A(r) = product_{j=k+1..s} C(R_j-1,r_j-1)`.

Precompute each **prefix factor**

`P_j = product_{m=k+1..j} C(R_m-1,r_m-1)`, with `P_k=1`;

and each **suffix factor after decrement of any earlier label**

`S_i = product_{m=i+1..s} C(R_m-2,r_m-1)`, with `S_s=1`.

Then all legal old-label child factors follow without recalculating A for
every branch:

- `A(r-e_k)=S_k` (even if `r_k=1` and it becomes a legal leading zero).
- For `i>k`, if `r_i=1`, then `A(r-e_i)=0` because a non-leading
  zero would violate the last-appearance ordering.
- For `i>k`, if `r_i>1`, then
  `A(r-e_i)=P_(i-1)*C(R_i-2,r_i-2)*S_i`.
- For all-zero r, `A(r)=1` and all old child factors are zero.

The new-label factor has the *independent* direct formula

`A(r, L_(s+1)-1)=A(r)*C(N+L_(s+1)-2,L_(s+1)-2)`.

The module independently compares this multiplied by
`H_(s+1)(N+L_(s+1)-1)` with the parent minus the old children.

## Verification and resource policy

The new module uses only **O(s)** binomial evaluations and 22,528-bit exact
multiplications per position, versus repeated direct `A(r-e_i)` calls.
As an extra guard, the direct implementation remains present as a unit
cross-check on every parent and each eligible child in the first 64
positions and in the final 106 positions of a future full-year native run.

An independently implemented Python combinatorics audit compared parent
and each eligible child against direct `A` for **9,000 seeded states**.
That is mathematical preparation only, not an SV or CI verdict.

The bounded isolated CI job will perform:
1. Fast 64-byte prefix identical byte-for-byte to the existing native SV
   decoder; independently pinned SHA256 `c799e928b30deb45924e8aa9f11be013b5a5f205190788e01dc99508793447dc`.
2. 256 decoded bytes, with exactly 45 months first started by physical
   position **255** and **no possible new label** at position 256;
   independently recomputed SHA256
   `f85aafeaa582a87bbc66c43a752a40fe3a2a88ad7d47b8e43500a2306f69c45b`.
3. Tampering with the native H old-branch count must be rejected.
4. The H archive remains ephemeral; only logs and compact prefixes retained.

A separate full-reference audit found first real month exhaustion at
position 4138, so a 256-byte prefix **does not** test real exhaustion
in the canonical full-year word. The dedicated six-case native edge
fixture covers that structural rule. Full 4244-symbol native proof,
synthesizable 5-component calendar output, and 64/64 independent
Kalaallisut name approvals remain OPEN.

No Stage 2, no main merge, PR #20 DO NOT MERGE.
