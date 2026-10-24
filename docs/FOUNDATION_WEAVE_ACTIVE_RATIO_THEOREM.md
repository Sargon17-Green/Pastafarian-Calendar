# Exact completion-block ratios for ordered-last active months

**Stage 1 engineering reference; not a synthesis acceptance.**
Inputs and source semantics remain pinned to
`main@56bc4173aae4975ded019ef5ab5a36249f1424df`.

## Counting the already-started months

After a legal fixed prefix, suppose months `1..s` have
appeared at least once, and their **remaining** occurrence
counts are `r_1,..,r_s`. For now assume every `r_j≥2`
(to avoid a final-occurrence boundary in the next decision).

Let `R_j = Σ_{i≤j} r_i`, `N=R_s`. Since first occurrences
already happened, the only ordering constraint among these
remaining copies is that their *last* occurrences appear in
ascending month-index order.

Build a word incrementally, inserting all copies of the next
larger month `j`. Its final copy must follow every previously
placed copy, while other copies can interleave freely. Therefore

```text
A(r) = Π_{j=2}^s binomial(R_j - 1, r_j - 1)
     = (N! / Π_j r_j!) × Π_{j=2}^s (r_j/R_j).
```

Both formulas are exact integers. **This is a factor for
started-label suffixes**, not the full woven calendar count;
fresh months must still be inserted with their first and last
appearance constraints.

For any fixed ordered-last word of length N, the number of
ways to insert all fresh months `s+1..45` depends only on N
and the fresh month lengths, not on the internal identities of
the already-started symbols. Denote that factor by
`H_s(N)`. The exact legal suffix count is

```text
C(prefix) = A(r) × H_s(N).
```

If one already-started month `i` is consumed next and all
remaining started counts remain positive, the fresh factor
`H_s(N−1)` is the same regardless of i. Thus all such next
blocks can be obtained from one exact full-width count by
rational multiplication and division:

```text
C(prefix+i) / C(prefix+1)
   = A(r−e_i) / A(r−e_1)
   = ((r_i−1) / r_1)
     × Π_{j=2}^{i−1} ((R_j−1) / R_j),  for i≥2.
```

The branch for the *first fresh month* `s+1` is the parent
completion count minus all existing-label branches. Verify
both the rational divisions are exact and the branch sum
equals the parent count. Use **one-based** lexical rank and
subtract earlier branches only.

### Foundation prefixes and observed checks

| Selected prefix | Active remaining counts before next symbol | Expected choice | Native Icarus |
|---|---|---|---|
| [1,2,3,4] | [114,107,118,108] | 5 | PASS, run 39981519434 |
| [1,2,3,4,5] | [114,107,118,108,105] | 6 | PASS, run 40001527283 |
| [1,2,3,4,5,6] | [114,107,118,108,105,80] | 7 | Test written, CI pending |

For six started months, the relative ratios for labels
1 through 6 are exactly:

```text
1
53/57
330/323
306020/328491
132658240/146835477
365288495/533244627
```

All numerators and denominators currently fit a signed
32-bit integer. Exact 22528-bit limb-wise division and a
multiply-back check prevent silent truncation. Later months
might require larger rational intermediates; this fixture is
**not** a complete/general-purpose arbitrary-precision ratio
engine, and `r_i=1` needs separate final-occurrence handling.

### Seventh-label complete witness

Exact arbitrary-precision independent arithmetic derives
the next seven completion blocks after the selected prefix
`[1,2,3,4,5,6]`. Their 2809-byte big-endian SHA-256:

```text
next 1: f97527164d81d4ad20b57ed73ccb3405419e4443155f57ef3268f2627115d56a
next 2: 9b4e02318ff20605a87f40d8b66a0dc96107687912eb664b8df5fbff55358d90
next 3: 98e6f44578f9d282e55827de162049ad5ebb964bc8993f519b5a15e6b62eebaa
next 4: ec5720877d81cb22b0c12662f8f338236f3c6d1b3b0bf180b67d7874b27892dd
next 5: 8e4bf7b121644aacf90203fd17e24253e9f9c32083403f1b378a8b31b71baf85
next 6: e79620ded1098212086edb88f7a1c5ea4ebff66ffd1f872895fc3d53ba84ab29
next 7: c89443f21642a9cbacbc12f4e6d970ab4815806d3b1b6dc836f247c1a4cc8849
```

Parent hash `262ef3db56038db64fba34de4d013437c0f49fd6b99852e800491221d7836f2d`.
All seven blocks add exactly to that parent, and the
canonical selected rank falls inside the next-7 block.

**Important limitation:** The entire 4244-symbol woven year
was decoded in independent arithmetic research and its
SHA256 was recorded previously, but the full word is NOT
yet decoded in SystemVerilog. This one-symbol-at-a-time
testing strategy is too costly for 4244 positions and should
be replaced with a memoized, resource-bounded general-purpose
exact suffix-count/unrank engine before Stage-1 signoff.
