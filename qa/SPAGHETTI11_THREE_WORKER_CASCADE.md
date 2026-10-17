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

## Second candidate: actual directional fork and self-skip trampoline

The first Native QA11A candidate (source blob `64a8cc2c4dcb0c150e970f9f84a6cc715e10614c`) **failed** its first healthy cooperative run at [39076167637](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39076167637) with rc124. The defect is geometrical: replacing the original `>` at (232,-2) directly with `t` forked while the parent IP was still moving **south**, not east. The new child did not enter its intended third-worker code. Historical RED is preserved.

The revised BeQunge source is `990d8fb2b84c7ee728634bb93a8e7baaef992c40`. It preserves the existing physical `>` at (232,-2), so the main IP first turns east. At x233 it dynamically computes the number 11 on the stack; at x242 it executes a genuine Befunge trampoline `#` that skips the `j` cell at x243; at x244 it executes **the actual `t` fork**. Parent C's own stack is explicitly popped with `$` at x245 before the coordinator polls readiness from x246.

The cloned child goes west from x244 into x243, where `j` **is** executed, popping 11 and jumping from x243 to x231. This skips both its spawn setup and the original `>` at x232 and enters its independent physical third-worker program stored backward across x67–x231 at y=-2. Worker C must still read the physically written residues of both historical workers A and B, produce residue 32, write flag70 only afterward, and permit the coordinator's new third semaphore to turn north into the dedicated output lane. The 17D geometry is exact and collision-free. This route is not a mere static output trick: a parent and child execute different instruction histories despite sharing their initial stack content. Nevertheless, full Native validation must pass before a PASS label is assigned.

## Native QA11A v2: healthy path green, an initially inert negative control

At [Native run 39076544736](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39076544736), **all 12 healthy cases passed**: two seeds, three repetitions each, cooperative and temporarily patched Native OS threads, with exact output `31 33 32`. Deleting the real third fork and corrupting C's read of worker B both changed termination/output. However the first attempt to break the third flag using `-z|` remained *behaviorally inert* in Native — it still ended with `31 33 32`, so the workflow was correctly RED. This attempt remains part of the original history, not misreported as PASS.

The new strict third negative control changes the physical predicate `-!|` to `-0|`, so the conditional `|` receives **zero** independently of the read flag. It must keep the main IP in the retry path even when the real worker has set 70; under the same 8-second bound it must differ in observable output or termination. QA11A cannot claim complete PASS until the corrected control and its independently repeated healthy cases pass in actual Funge++. The 17D source SHA and all healthy program bytes remain identical.

## Second Native negative-control RED and stricter physical read sabotage

The next [Native run 39076719953](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39076719953) again demonstrated all 12 healthy parallel runs, and the absence-of-fork and worker-residue corruption controls both changed observed behavior. But `-0|` also **failed to perturb** the correct output. This is a test-design failure, NOT proof that the readiness comparator is essential. Preserve that record. The next control changes the unique physical `g` instruction in the third semaphore-read block at (233,-2,...,0) to Funge-98 `q`. The test must prove the actual physical read is executed: `q` terminates the Native universe before the three residue output cells are read. It is a *read-site sabotage witness*, not a claim of an interleaving/race proof. The previously pinned 17D 3-IP specimen remains unchanged.
