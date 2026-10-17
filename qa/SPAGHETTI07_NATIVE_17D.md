# QA07 — the 17-dimensional native residue mesh

**Scope:** research-only companion to Stage 1 on branch `qa-befunge98-stage1-order-isolation-20261008`.
Do **not** promote into the 2-dimensional production `src/interleaved_work_counts.b98`,
declare Stage 1 complete, merge PR #17, or start Stage 2.

## Language and interpreter: a real distinction

Befunge-98 denotes the **two-dimensional** member of the Funge-98 family.
The family naturally generalizes coordinates and deltas to higher dimensions;
a 17-dimensional program is not a standard 2D `.b98` binary.
Our historical PyFunge 0.5-rc2 supports only -d1, -d2, or -d3.
The new specimen uses 17 physical dimensions in the `.beq` format
and the **NFUN** extension implemented by the independent Funge++
interpreter. Pinned engine:
`cwesson/funge-plus-plus@cd6d7f005b4fc33b486fcc2380b35406f6125ca4`.

This is an **actual n-dimensional Funge-space**, not 17 scalar variables
disguised as axes. Its interpreter has 17-component IP coordinates, 17D
movement vectors and 17D `p`/`g` coordinates. Each `Z` instruction
activates a new genuine basis axis, in sequence 1..16, starting from
the original x-axis (axis 0). The 17D state is stored sparsely in the
BeQunge text sections. The static `@` bytes are deliberately misleading.

## Dependency cascade — material not visible in the source

The first IP reads a branch seed via native `&`, duplicates it, and
writes one copy through native 17D `p` into the original source coordinate
(0,0,...,0), overwriting the initial input instruction. The other seed
survives on the stack. At each of the sixteen subsequent axes:

1. The running arithmetic accumulator adds the next axis index. Its
   sum is the entire already-executed dimensional history, not an
   independent constant.
2. The old seed is reread from the now-obscured original cell via
   **17-dimensional native `g`**.
3. Three instructions are *compiled* at three distinct points along
   the not-yet-entered dimension using three native 17D `p` writes.
4. Three native 17D `g` reads retrieve those newly written bytes
   before execution. Their actual ASCII values are emitted with `.`
   as execution receipts.
5. Native NFUN `Z` points the IP along the next genuine dimension;
   it executes those three formerly `@` cells after their overwrite.
   The third emitted instruction turns the IP back into the x direction
   on a higher-dimensional hyperplane.

For axis `i`, cumulative residue `T_i = i(i+1)/2`, and inherited QA06
branch seed `s`, the new instruction triplet is:

```
A_i = 48 + 10*((T_i + s) mod 2)        # 0 or :
B_i = 36 + (T_i - i(i+1)/2)^2           # $
C_i = 62 + (T_i - i(i+1)/2)^2           # >
```

The second and third instructions are live, self-diagnostic equations:
perturbing an earlier axis's contribution changes the later generated
executable byte values rather than merely a final numeric accumulator.
Under a valid execution the two dynamic dialects are `0$>` and
`:$>`, which restore the accumulator and advance to the next panel.

The last stage emits a checksum proportional to the original seed.
Every axis contributes an observable ordinal marker. The native
output therefore has **16 groups of [A,B,C,axis] and one final total**.
The sources are not ordinary plaintext versions of those future
instructions: there are **48 source traps**, one for every emitted opcode.

## Verification and provenance

The 2D Stage 1 QA06 specimen is run first in native PyFunge and exports a
SHA-pinned JSON receipt: two cases yield seed 1 and two yield seed 2.
That receipt supplies the *input* to the separate 17D Funge++ process.
This is an explicit cross-process bridge, **not** a claim that QA06 and
QA07 share the same interpreter state or instruction pointer.

The exact-head 17D workflow pins Funge++ at the commit above and
compiles the engine on the runner. The Python QA harness assembles only
the test source and reads Native output; no calendar computation or
17D interpreter is implemented in Python. It requires:

- All 17 component coordinates and 16 N-dimensional turns to be
  present in the exact BeQunge source.
- Numeric parity for both authentic Native QA06 seeds: 65 output cells
  each, including the 48 generated instruction bytes.
- Complete masking of all **48 original `@` traps**, replaced with
  `q` on disk. Native execution must still produce identical output,
  proving the source traps are overwritten before being used.
- One causal source mutation on *every one* of the 16 new dimensions.
  A faulty accumulator contribution must change the normal output,
  termination or both.

The source and all evidence are retained, including any failed
intermediate Native attempts. This experimental component does not
replace the 2D canonical arithmetic or constitute Stage 1 completion.

No claim of winning a subjective 'most monstrous code' contest is made:
this establishes independently testable complexity, not a numerical
award or absolute maximum.
