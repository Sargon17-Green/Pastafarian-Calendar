# Spaghetti 08 — Concurrent NFUN seventeenth-dimension debris and nested stack rendezvous

Scope: QA companion on `qa-befunge98-stage1-order-isolation-20261008` ONLY, not an upgrade to the 2D
production source. This experiment preserves Stage 1 OPEN and PR #17
unmerged. Exact parent QA07 `4c9bff056cb61004d37dd2d949fccf171b4ddf0f`
must remain unchanged. QA08 source:
`0b49d3b4175055d365a089267cfc2450ea6d83aa`.

## Actual language-native topology and memory ownership

The specimen is a 17-component **BeQunge/Funge-98** program, executed
on a SHA-pinned Funge++ engine in **cooperative concurrent** mode.
Native instruction `t` creates a second instruction pointer with a
*cloned* stack and a reflected direction. The parent IP immediately
follows positive x while its child traverses the independent **negative
x hyperplane**. This is not a Python branching simulation: native
Funge++ clones and schedules the real instruction pointers.

The child enters **two nested `{` stack frames**, passes the value 31
between frames via real negative and positive `u` operations, and uses
`}` to restore its prior storage vectors and return computed results.
It computes a nontrivial residual 62 from 20 + 11 + 31. It then
writes first the dependent residue 31 at (10001,0,...,0), and **only
after that** writes the synchronization flag 62 at
(10000,0,...,0). Finally it terminates its own IP using `@`.

The main IP polls the synchronization flag through a genuine 17D `g`
and conditional `|` branch. Until 62 is observed, it loops via
`<` and `^`; when 62 is present, it takes a distinct negative-y
plane to enter the 16-stage 17D code-generation cascade. This ordering
prevents scheduling order from changing correctness:
child's residue `p` strictly precedes flag `p`, and gate reception
precedes all dependent compiler reads.

The main IP then reads the residue at (10001,...,0) via native `g`,
records that concrete value, and for each axis i constructs three
future executable opcode bytes from:

```
H_i = cumulative sum of live axis contributions
s   = Native QA06 branch stamp (1 or 2) carried through QA07's receipt
w   = second IP's physically written residue (normally 31)
A_i = 48 + 10 * ((H_i + s + w - 31) mod 2)
B_i = 36 + (H_i - i(i+1)/2 + w - 31)^2
C_i = 62 + (H_i - i(i+1)/2 + w - 31)^2
```

The 48 future instructions are not in the original file: 48 original
`@` traps occupy distinct sites and are overwritten at runtime using
17D `p`. The code emits `0$>` or `:$>` per axis on healthy inputs.
All emitted byte values are also read back with native `g` and recorded
as numeric receipts before the parent IP enters their coordinates.

This makes a worker's **nested under-stack side effect** an obligatory
input for all later generated code, and binds it to the earlier Native
QA06 history through an explicit cross-interpreter provenance receipt
(no false claim that independent runs share a live instruction pointer).

## Real Native testing and honest limits

The source pins 2D production, QA06 and QA07, plus exact Funge++
commit `cd6d7f005b4fc33b486fcc2380b35406f6125ca4`.
A completely fresh Native QA06 history receipt and independently
successful QA07 receipt must be generated before QA08 begins.

Proof obligations:
- Both inherited branch seeds 1 and 2 result in Native output of
  worker residue 31, followed by 16 four-integer code emission
  receipts [A,B,C,axis] and a final 136*seed.
- 48 static code traps may be changed to `q` without modifying
  the Native result, proving code was installed *before* execution.
- Six dedicated breakage controls attack actual `t` concurrency,
  nested `{` scopes, `u` ownership transfers, worker arithmetic,
  and shared synchronization; all must cause changed Native output or
  changed termination.
- 16 additional one-coordinate counterfactuals corrupt contributions
  on the individual dimensional source panels, again checking actual
  Funge++ execution and preservation of the other parts of the code.
- The QA evidence records both complete Native outputs and mutations.
  No PASS is asserted until the exact-head GitHub workflow succeeds.

Real concurrency with a shared memory rendezvous does *not* mean that
the parent merges IP stacks: the two stacks are cloned at the fork,
remain independently owned, and communicate only through shared
Funge-space cells. This is faithful to Funge semantics and is an
important boundary of the experiment.

This remains a reproducible **17-dimensional QA sidecar**, not a full
port of the canonical Pastafarian calendar to BeQunge. Round 8 of 12
does not certify Stage 1 or constitute the project's final release.
