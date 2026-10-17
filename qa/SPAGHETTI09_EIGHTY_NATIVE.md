# Spaghetti 09B — a self-generated 80-opcode executable on 17 axes

**State: Native candidate, NOT yet accepted.**
This is a QA-only separate 17D Funge++ BeQunge program, not a
replacement for the canonical 2D Pastafarian production implementation.
QA08 source blob `4ba6902de08cf9483374f43a33f1d4ae7a14e3f6`
and QA09A accepted two-worker fixture blob
`e22a8b706fb84e3356db6c70aac29b9145642201` are immutable parents.

Source Git blob:
`29b2a0c4ead0c7d102ee9c2680a3491d5bc89932`.
Engine:
`cwesson/funge-plus-plus@cd6d7f005b4fc33b486fcc2380b35406f6125ca4`.
Physical source contains 108 one-line BeQunge panels and **80 single-cell
static `@` traps** on distinct 17-component coordinates.

## Genuine fan-out and cross-worker dependencies

The already verified QA09A topology contains exactly two native `t`
forks in a single 17D Funge-space (maximum three running IPs). One
independent worker goes to negative x, uses two nested stack frames
and Funge-98 `u`, and writes `A=31` to (10001,0,...,0) followed by
its ready flag 62 at (10000,0,...,0). A different worker traverses a
backward-running lane which the coordinator skipped with native `j`.
It uses its *own* two nested frames and writes `B=33` at x10003,
then its ready flag 66 at x10002. The coordinator cannot enter the
compiler until **both independent ready flags** have been physically
read. The original source has a passive `z` sentinel with a nonzero
coordinate component on the 17th axis, because Funge++ otherwise
collapses unused high dimensions despite the BeQ metadata header.

The compiled code is calculated from:
```
H_i = sum of executed dimension contributions = i(i+1)/2
S   = live QA06-derived branch seed, persisted at the original (0,...,0)
E   = (A - 31) + (B - 33)              # cross-worker zero-residue
A_i = 48 + 10*((H_i + S + E) mod 2)
B_i = 36 + (H_i - i(i+1)/2 + E)^2
D_i = 48 + 10*((H_i + S + E + 1) mod 2)
E_i = 36 + (H_i - i(i+1)/2 + E)^2
C_i = 62 + (H_i - i(i+1)/2 + E)^2
```
Here the notation `E` (share error) and `E_i` (the fourth emitted
instruction) refer to different objects. On healthy inputs every axis
generates **five** valid executable bytes, alternately
`0$:$>` and `:$0$>`; each dialect preserves the live accumulator.
The source cells themselves contain `@@@@@` at their future sites,
not any of those five executable bytes. The compiler writes each byte
using native 17-component `p`, rereads the emitted value via native
`g` for an observable numeric receipt, then native NFUN `Z` enters
the subsequent spatial axis and executes the newly written instructions.

This is a genuine data dependency from **two different concurrent
workers through physical memory to dynamically installed future code**.
Neither the contents of one worker's stack nor a nominal source-level
comment is a substitute for that causal chain.

## Strict Native checks

The source-manifest script must pin the exact source blob and every
physical target; assert 17D auto-dimension discovery, 16 stages,
80 unresolved static traps and 108 BeQunge source sections.
The GitHub workflow must compile pinned Funge++, recreate QA06 in
Native PyFunge, execute QA07 and QA08 on the pinned 17D Native engine,
and rerun the accepted QA09A rendezvous.

The full QA09B script then checks:
- Both seeds (1 and 2), three repetitions per seed, on Funge++
  cooperative `-fthreads=funge` and OS thread `-fthreads=native`
  (twelve Native runs) with exactly 99 expected numeric output values
  recording A, B, 80 newly emitted opcodes, 16 axis witnesses and final
  checksum.
- Every original single-cell trap replaced with `q` while preserving
  complete, correctly terminating output (two masking experiments).
- Separate removal of worker A fork, worker B fork, worker B's under-stack
  transfer, and sabotage of its residue computation.
- Sixteen separate one-axis arithmetic mutations which must alter
  Native output or termination.

Negative mutants that merely exceed a bounded 3-second limit are
classified as **nontermination effects**, not evidence of a wrong but
terminating numeric result. Historical RED attempts stay preserved.

No Native PASS, release claim, PR merge, Stage1 completion, or
Stage2 transition is made until these checks actually pass. The
candidate is more complex than QA08 but is not a proof of a
hypothetical global maximum in code complexity.
