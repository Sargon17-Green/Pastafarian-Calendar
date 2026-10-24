# Exact counting of all canonical woven months: compressed transfer

**Status: derived, independently arithmetic-tested; the full-sized
SystemVerilog/ASIC engine is NOT YET IMPLEMENTED or validated.**

### Canonical conditions

For a vector of monthly lengths `l_1..l_m`, a weave is a
multiset word of total length `L` in which first appearances and
last appearances of month indices **both** follow 1,2,...,m.
Labels are canonical indices, not Unicode-sorted strings.

### A polynomial-size exact root counter

Let `F_j[f]` count canonical weaves involving months
`1..j`, in which the **first occurrence of month j**
is at 1-based position `f`. Let `N` be the total length
of months `1..j-1`.

Base case: `F_1[1]=1`, all other entries zero.

Build any valid weave of months 1..j-1, preserving the order
of all old copies. Insert `l_j` copies of month j. Its final
occurrence must follow all old letters (the final old letter
is the last occurrence of month j-1), and its first
occurrence must follow the first occurrence of month j-1.
If the first j occurs after exactly k old letters
(`F_old` first position `f≤k≤N`), then:

```
for k=1..N-1:
  F_j[k+1] = (Σ_{f=1..k} F_(j-1)[f])
             * C(l_j+N-k-2, N-k)
F_j[N+1] = Σ_{f=1..N} F_(j-1)[f]
```

The coefficient counts distributing copies into the
`N-k+1` gaps after old letters k..N with at least one
copy in the first and in the last gaps. At k=N only one
gap exists and all new copies go there.

Prefix sums make the transfer use O(N) bigint operations.
Every legal final word has exactly one original word
obtained by deleting the maximal label, so this counts
each legal weave once and only once.

### Exact completion counts after a fixed legal prefix

Let `r_j` be remaining occurrences, and `s` the
greatest month already seen. Validity of the fixed prefix
guarantees month indices initially seen are 1..s, and
all completed months form an initial segment.

1. For months `j≤s` with `r_j>0`, no further **first**
   appearance restriction remains, only the order of
   their last occurrences. Build their suffixes in
   increasing index, inserting `r_j` copies of j
   anywhere but requiring at least one after all
   previously processed letters. If N old letters exist,
   multiply the count by `C(N+r_j-1,N)`.
2. If there are fresh months `j>s`, insert the
   first fresh index anywhere, subject to its last copy
   following the last old letter. Track the resulting
   first-position distribution. When N=0, it is
   `F[1]=activeCount`; otherwise for `k=0..N`,
   `F[k+1]=activeCount * B(k,N,r_j)`.
3. Insert later fresh indices with the root recurrence
   above. Here `B(k,N,n)=C(n+N-k-2,N-k)` for k<N,
   and `B(N,N,n)=1`. For an insertion with distinct
   first and last gap, the coefficient is zero when
   `n=1`.
4. Sum the final first-position distribution. This
   is the exact number of legal completions of the
   fixed prefix, and therefore is the correct
   lexicographic block size for selecting the next
   month index.

This avoids the intractable dense tensor over every
`(r_1,..,r_m)` state. It is a polynomial operation per
suffix query, but a 4244-step exact unranking will
require caching, resource profiling, and arbitrary-
precision memory management. Do **not** assume it is
fast enough for tapeout without benchmarking.

### Independently checked toy cases

Brute-force word enumeration agrees with the
first-position counter for month-length vectors:

```
[2,2]       => 2
[2,2,2]     => 5
[3,2,2]     => 9
[2,2,2,2]   => 14
[4,2,1]     => 4
[1,1,1,1]   => 1
[1,2,1]     => 1
[4,4]       => 20
```

Also checked **258 legal prefixes** from these eight
cases: their full-brute completion counts agree
with the compressed suffix transfer. The new
`tests/tb_weave_small_exhaustive.sv` implements
these verification ideas in test-only SystemVerilog,
but must be judged by an actual CI run separately.

### Foundation year: exact count checkpoint (research evidence)

For the *45 length candidates* committed to
`FOUNDATION_MONTH45_LENGTHS_REFERENCE.csv`,
the first-position transfer and the independent
prefix-completion transfer both produced the same
exact nonnegative integer `W`:

```
bit_length(W)                  = 22470
decimal digits                 = 6765
minimal big-endian byte length = 2809
uint32 limbs needed            = 703
minimum base-M digits          = 177
SHA256(minimal big-endian W)   =
  925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da
hex high-order 120 nibbles:
  3b0054026ebe0123abec6265f1eaa5fa9e2956ccd7a46b4ad53934016027fd6ae871b8b424b0b60bd52436396f781d9b4c12a734f045bb02c34712f1
hex low-order 120 nibbles:
  9ee02ae1d19ddbd2b9d29efcd0c9bbcddae2a4bcd271d0f85ce66a191c7130d0297ed5918ba7eb26aed483715a31dcc6ad4761227200307294007f78
```

Since `M=2^127-1`, direct exact-integer comparison
verifies `M^176 < W ≤ M^177`; therefore the first wide
answer must contain **exactly 177** consecutive base-M
digits. The full word is still unknown.

This numeric checkpoint was produced in research
arithmetic, **not by a SystemVerilog executable**.
It cannot be accepted as an independent production
oracle until equivalent exact SV arithmetic and
full-rank selection pass CI.

### Remaining work

- Design exact bounded bigint arithmetic for up to
  22,470-bit intermediate weave counts/ranks.
- Implement and verify suffix block-count queries
  and deterministic 4244-step lexical unranking.
- Apply bowl 4 seal 32 equal-selection semantics,
  preserving all 177 answer digits and rejection
  direction and count, then recover the physical
  woven month and occurrence day.
- Unrank `47P45` canonical month-name sequences
  through bowl 5 seal 33.
- Validate month-name index 20 and occurrence 56
  for c=t=Foundation, and eventually **all** five
  fields over all canonical conformance vectors.
- Complete qualified 64-name Kalaallisut approval.

Stage 1 remains OPEN; no commit may use the above
research figures to mark Stage 2 PASS.
