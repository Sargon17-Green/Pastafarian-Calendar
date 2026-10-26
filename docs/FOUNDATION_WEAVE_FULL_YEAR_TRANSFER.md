# Exact full-year woven-month transfer: linear state-space reference

**Status:** independent Python exact implementation executed locally
and returned the full, previously known SHA256 word in approximately
19 seconds while checking all candidate blocks at all 4244 positions.
A separate SystemVerilog STRUCTURAL checker is written, but
**the new code has not yet passed native CI**. This reference is not
synthesizable production RTL and is not a native SV lexical unrank.

## The factorization

Let `s` months have already started, and `r=(r1,...,rs)`
be their remaining positive occurrence counts, allowing only
a *leading* group of zeros for months whose last occurrences
have already legally completed. Define `N=Σ r_i`.

The number of suffix words over *already-started* months
whose last occurrences are in increasing ordinal order is:

```text
A(r) = product_{j=2..s} C(R_j-1, r_j-1),
R_j = sum_{i=1..j} r_i,
```

with zero values omitted only when those zeros form a legal
leading prefix. The number of all canonical future woven
completions factors as

```text
C(prefix) = A(r) * H_s(N).
```

`H_s(N)` depends **only** on the number of started labels,
the total number of their unconsumed occurrences, and the
fixed lengths of as-yet-unstarted months; it does not depend
on the identities/order of the started month copies.

## New recurrence, cached for the entire year

For `s=45` no new month remains, so `H_45(N)=1`. For
`s<45`, let `v=L_(s+1)`, the length of the next fresh
month. Partition all completions after a fixed started-only
suffix pattern by their next symbol:

- Taking one old symbol leaves `N-1` old symbols to
  interleave, contributing `H_s(N-1)`.
- Taking the **first** occurrence of the next fresh month
  leaves `v-1` copies of that label; its final occurrence
  must follow all old letters. Exactly `C(N+v-2,N)`
  interleavings satisfy this before later fresh labels.
  The rest contribute `H_(s+1)(N+v-1)`.

Thus the exact recurrence is

```text
H_s(-1) = 0
H_45(N) = 1
H_s(N) = H_s(N-1)
        + C(N + v - 2, N) * H_(s+1)(N + v - 1)
```

for every reachable integer `N>=0`. The coefficient
sequence is computed exactly with

```text
B(0) = 1
B(N) = B(N-1)*(N+v-2)/N
```

and divisibility checked on every update.

Given `s`, only `0<=N<=Σ_(i<=s)L_i-s` is reachable.
For the Foundation length vector the entire precomputed
table contains **101594** arbitrary-precision integer
cells. It is constructed by descending `s`, without
constructing a huge state vector of remaining counts.

The root of the entire 45-month weave, once the required
first symbol 1 has been consumed, is **exactly**
`H_1(L_1-1)=H_1(114)`.

## Complete exact lexical unranking

Compute the selected one-based rank independently from
bowl4, seal32, 177 base-`(2^127-1)` digits, with its
previously established reverse direction. For every
subsequent position:

1. Evaluate **all** old-label blocks:
   `A(r-e_i)*H_s(N-1)`; illegal last-occurrence
   order yields zero.
2. The first fresh-month block is exactly
   `A(r)*H_s(N) - Σ_i old_block_i`.
3. Confirm the entire partition is nonnegative and
   select the first lexicographic block containing the
   residual one-based rank; subtract all preceding blocks.
4. Update `r`, `s`, and `N`. Confirm selected old/fresh
   cases have consistent exact counts, never use floating
   point or approximate residues.
5. At the end require 4244 bytes, all lengths conserved,
   first and last occurrences ascending, and residual
   one-based rank exactly 1.

`scripts/test_foundation_weave_full.py` implements this
formula in ordinary Python arbitrary-precision integers;
the binomial factors are cached. All potential next
blocks are enumerated, even if the selected block occurs
early, so partition conservation is checked in **each of
4244 positions**.

## Independently locked results and boundaries

```text
root bits: 22470
root SHA256 (minimal big-endian):
925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da

selected one-based rank bits: 22469
selected rank SHA256 (minimal big-endian):
2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06

full woven year: 4244 bytes, each in [1..45]
word SHA256:
e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29

first 11 ordinals: 1,2,3,4,5,6,7,4,8,9,10
year day 2032: physical month ordinal 8
occurrence within physical month 8: 56
ordinal 8 -> canonical month-name index: 20
```

The 45-name mapping is checked against the versioned
`docs/FOUNDATION_MONTH_NAME_45_INDICES.csv`, **not** by
sorting Kalaallisut strings. This reproduces
`P(Foundation,Foundation)=(5000,10,503,20,56)` when
combined with the independently native-proven year and
cutlet oracle; it does **not** imply that the production
RTL can yet emit the tuple.

## Independent HDL structural witness and CI

The Python test-only runner emits:

```text
build/foundation_weave_all4244.bin
build/foundation_weave_all4244.hex
build/foundation_weave_reference_metrics.txt
```

The binary is externally verified by the SHA256 above.
`tests/tb_weave_reference_structure.sv` independently
reads the 4244-element hex file and checks all 45 monthly
lengths, first/last appearance order, first 11 symbols,
last symbol, and day 2032 (month 8, occurrence 56).

`scripts/verify_foundation_full_year_reference.sh` has
explicit 120-second Python and 30-second simulator timeouts.
The isolated `full_year_reference` QA job has a 9-minute
wall-clock limit and a 3-GiB virtual-memory ceiling,
and preserves source SHA, logs and raw binary evidence.

**Strict claims:** Passing this QA job demonstrates
(a) a fast independent full-year mathematical *reference*
and (b) native SV *structural validation of that reference*.
It is **not** proof of an entirely native SystemVerilog
full-year unrank, nor completion of synthesizable production
calendar logic or native-speaker Kalaallisut names.
Stage 1 remains open, Stage 2 closed, QA PR #20 draft,
and `main` unchanged.
