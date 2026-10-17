# QA11A — Three causally dependent 17D Funge instruction pointers

**State: experimental smoke fixture; full QA11 17D generated-code mesh NOT
yet accepted.** Do not edit the signed QA10 source or 2D calendar.

The pinned parent is QA10: `010efd012ae52a60740aa97750b5a02519912e92`.
QA11A's genuinely separate Funge++ BeQ source is
`64a8cc2c4dcb0c150e970f9f84a6cc715e10614c`.
Its baseline is the preexisting QA09A Native dual-shard fixture,
`e22a8b706fb84e3356db6c70aac29b9145642201`.

## Causal fan-out/fan-in

The two existing worker IPs remain unaltered. The main IP first
waits until worker A has put physical (10001,0,...,0)=31 and ready
flag at (10000,...)=62, then until worker B has put (10003,...)=33
and ready flag (10002,...)=66. At their **already existing**
rendezvous cell (232,-2,0,...,0), the code changes direction
`>` into real Funge-98 **`t`**, which forks a third,
separately scheduled worker C heading WEST in the y=-2 plane.

Unlike independent synthetic numbers, worker C must use true native
17D `g` twice to fetch both A=31 and B=33; it computes
`(A+B)/2 = 32`, writes it with native 17D `p` to (10007,0,...,0)
and only THEN writes a different ready flag 70 to (10006,0,...,0).
These cells initially contain `#` (=35), a value neither equal to
the ready flag nor to the correct residue.

Meanwhile the main IP follows a separate y=-2 polling source lane
at x233..283. On a not-ready value it walks the NEW y=-3 return
plane; on observing exactly 70 it turns into y=-1 and reads the
three independent physical residues in order. Expected stdout:
`31 33 32`. A nonexistent third worker, damaged C read of B,
or damaged third-flag predicate must break parity.

This truly creates a **third independent instruction pointer
and nested historical residue dependence** without faking a
threaded computation in a host language. Native Funge++
`-fthreads=funge` and `-fthreads=native` tests run under an
explicitly identified *disposable scheduler lifecycle patch*
of the pinned upstream commit; unchanged upstream Native shutdown
remains known broken.

The QA11A acceptance goal is 12/12 two-mode Native executions
(two seeds, three repetitions), plus at least three actual source
mutation counterexamples. The derived 32 is a small integration
witness, not yet a third shard feeding a 208+ byte macro;
that stronger integration is the next QA11B requirement.
Never mark QA11/12 overall PASS on QA11A alone.

Historical QA10 successful receipt: [39069333028](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39069333028).
QA10 remains immutable and Stage1 OPEN; Stage2 not started.
