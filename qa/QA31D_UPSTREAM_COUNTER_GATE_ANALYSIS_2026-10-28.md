# QA31D continuation — upstream pre-`j` gate reconstructed from immutable source and signed Native STEP traces

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ`. Date: 2026-10-28. Scope: **Stage 1 only**, read-only offline analysis. This is **not** a new QA stage, a new Native run, Stage 1 acceptance, or evidence of universal input independence.

## Provenance and exact checks

- QA branch at inspection: `qa-befunge98-stage1-order-isolation-20261008`, HEAD `032e4fbce1f8fa62c5e941252264749cf0df34c2`; PR #17 open Draft, base `Befunge+Кыргызча`, unmerged.
- Original unmodified production source: `src/interleaved_work_counts.b98`, Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. Read via GitHub Git blob, not from a guessed source copy.
- Previously independently verified [QA31D exact-head Native run 40709128569](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40709128569) and [original artifact 12825616476](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40709128569/artifacts/12825616476). In this continuation the existing ZIP was reread, **not** reexecuted: SHA-256 `b8df61e31a3f28bfcc21bbccb4d2ee26b5ccfeca534969e87d95a211fbb40eeb`, ZIP `testzip() == None`. Complete gzip STEP files contain 17,387 `valid00` plus 19,713 `valid01` signed-format physical instructions. These remain the originally accepted bounded QA31D observations, not independently newly rerun Native execution.
- A direct byte-for-byte comparison of the decompressed complete STEP sequences finds **11,253 identical physical STEP rows** from tick 1 through tick 11,253. Both executed the target `j` at tick 9,607, `(114,38)`, with operand 61 and next physical position `(176,38)`. Their first differing STEP row is tick **11,254**, both at `(1500,1750)`, fetched opcode `62 ('>')` for `valid00` versus `118 ('v')` for `valid01`. This difference is **downstream** of the target `j` and does not provide pre-`j` causal variation.

## Exact local source reconstruction

The full original source row `y=38`, positions `x=11..114`, was parsed with elementary Befunge-98 stack arithmetic, independently of calendar-level semantics. No edited source or speculative route was used.

| Observed original physical source position | Source operations | Deterministic stack effect under standard Befunge-98 semantics |
| --- | --- | --- |
| `(11..56,38)` | Two base-10 arithmetic literal builders | Push `x=1`, `y=49` |
| `(57,38)` | `g` at signed tick **9557** | Read FungeSpace value `m` at `(1,49)` (storage offset zero on the inspected path) |
| `(58..80,38)` | Arithmetic literal builder | Push `4` |
| `(81..82,38)` | `-!` | Replace `m,4` with `1` iff `m=4`, else `0` |
| `(83..105,38)` | Arithmetic literal builder | Push `61` |
| `(106..113,38)` | Seven spaces, then `*` at tick **9606** | `61 * [m = 4]` |
| `(114,38)` | `j` at tick **9607** | Pop operand `61 * [m = 4]`; verified next `x = 114 + 61 + 1 = 176` |

In equation form, with `[P]` denoting `1` if proposition `P` holds and `0` otherwise:

```
pre_j_operand = 61 * [FungeSpace(1,49) == 4]
```

The signed traces show zero executed `{`, `}`, `u`, or `k` before this `j` on either path (among 9,607 observed ticks), so no observed storage-offset or nested-`k` change invalidates this standard interpretation. No direct `g` read-value event was captured by QA31D: the value `m=4` follows **deductively from the verified pre-`j` operand and the local source operations**, not from an independently instrumented FungeSpace memory snapshot.

## Upstream counter provenance (further source + STEP analysis)

The original source's row `y=2` initializes four cells at `y=49`: physical `p` sites `(58,2)`, `(106,2)`, `(154,2)`, `(202,2)` write zero to `x=0,1,2,3`, respectively, under the standard `p` operand ordering. In particular, the original Native trace executes the `(106,2)` initialization at tick **146**.

The original source at `y=26` explicitly implements an increment of the cell `(1,49)`: `... (push 1,49) g 1 + (push 1,49) p ...`; the corresponding `p` is at `(248,26)`. In **both complete QA31D STEP files**, this same physical `p` executes at ticks **2408, 4670, 6932, 9194** (four occurrences). A source-level symbolic evaluation of `y=26,x=11..344` identifies the other `p` at `(152,26)` as writing to `(10+m,49)`, and `p` at `(296,26)` and `(344,26)` as writing to `(2,49)` and `(3,49)`. The other observed `p` sites in rows 5 and 14 target `(0,49)`, `(2,49)`, or `(3,49)`, not `(1,49)`. All 36 physical `p` STEP occurrences before `j` were enumerated; no other executed `p` source site was seen. Thus, **within these two signed paths and the observed standard interpreter semantics**, the count goes `0 -> 1 -> 2 -> 3 -> 4` before the target `g` and explains the identical 61 pre-`j` operands.

The source file originally has no populated row `y=49`, so the cell's value is runtime state, **not an immutable original source character**. This study reconstructs `p/g` operations from pinned source plus genuine physically visited opcodes; QA31D itself did **not** instrument individual `FungeSpace.put` calls or prove ownership against every possible mutation API in every input.

## Narrow finding, implications and next permissible step

**New finite result:** the target `j` is locally gated by an upstream **count-equals-four** test rather than by the final numeric value of the fourth input field. `valid00` and `valid01` both execute four increments and must take the same `j` displacement along these witnessed paths. Retesting another pair that differs only in the fourth input value while keeping this counter trajectory unchanged would not be a justified pre-`j` differentiability experiment.

This does **not** establish a theorem for all valid inputs or unreachable source cells. The remaining original 15-source-cell frontier and `FULL_FUNCTIONAL_QA_PASS` / `GEOMETRIC_SPAGHETTI_QA_PASS` still remain open. **No Stage 1 PASS, Stage 2, merge, or change to `main` / canonical `Befunge+Кыргызча`.**

**NEXT, without new costly Native execution:** cross-index the already-signed QA31A/QA20 routes that reach `j=(114,38)` against the `(248,26)` increment count and source-plane `p/g` provenance. Determine whether any original **valid** route demonstrably reaches the same `j` with fewer than four increments; if not, record a finite no-counterexample result and return to the unresolved 15-cell/control-ownership frontier. Propose a new original-Native memory-intervention test only if a genuinely distinct reachable counter trajectory emerges or an ownership ambiguity cannot be settled from existing evidence.
