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

## Native forensic failure 1 (retained)

Native workflow 39037198820 for candidate HEAD 4c7e0702 reproduces QA06
and QA07 PASS; QA08 seed1 times out with no output in 20s. No PASS.
A follow-up native forensic workflow 39037581878 isolates: an original
standalone worker returns `0 0` rather than expected `31 62`, while
both full concurrent handshake probes time out. Thus the original
stack/worker calculation or memory offset handling is broken; it is
not legitimate to claim that the fork and nested stacks have passed.
The original workflow, failure and forensic probes are retained.

## Native forensic physical allocation fix
The Native forensics run 39037831108 confirmed the worker's nested stack result 62 and actual split-IP execution, while unallocated far-address p/g readbacks failed. Preseeding the flag enabled successful parent joining and a 31/62 memory readback. This experimental iteration explicitly places two mutable source bytes at x10000 and x10001, initially # (35, not ready) and & (38, untrusted), so the child must overwrite them using p before the parent can observe ready 62. Earlier RED workflows remain. A new exact-head Native check is required before PASS.

## Forensic fix to true parent re-poll geometry

The instrumented Funge++ run 39040416313 isolated the failure in Native
pointer movement: when a non-ready flag sends the parent from `|` down
into the y=1 westbound back-lane, the `^` at (1,1) resumes northward at
(1,0). The old (1,0) ASCII `0` did not reset the IP direction, so it
continued north and never re-read the flag, even though the worker had
correctly emitted p(10001)=31 followed by p(10000)=62. Source content,
real physical addresses and engine worker history are therefore valid.

**One-cell native source fix:** (1,0) changes from `0` to `>`.
An initial eastbound execution now executes `>a*` instead of `0a*`:
Funge's defined empty-stack-pop value is zero, so the address-building
arithmetic still starts at zero; when the IP returns from (1,1), `>`
restores eastward motion and retries physical 17D `g` correctly.
Source dimensions, all 48 future traps, dynamic target coordinates,
worker stack code, QA07 source and 2D production source are unchanged.
A dedicated `poll_east_return_suppressed` mutant restores `0` to
require RED under native Funge++; no PASS is claimed pending exact-head
verification. All original failed attempts remain retained.

## Final QA08 Native acceptance — 17 October 2026

**Accepted source SHA:** `4ba6902de08cf9483374f43a33f1d4ae7a14e3f6`
(`qa/spaghetti08_17d_concurrent_stack_residue.beq`).
**Code-and-harness HEAD:** `2c721032f99e30375b2cb10506502abeed15ff3e`.
**Authoritative green workflow:** [Native run 39040932851](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39040932851);
Native job 117420124892, artifact
[12103649404](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39040932851/artifacts/12103649404).
The exact pinned Funge++ commit, fresh QA06 and QA07 Native receipts and final
QA08 Native test all passed in one job. Other Native regression workflows
are tracked separately; green QA08 is not a Stage 1 completion claim.

The original semaphore bug was **parent control-flow**, not shared-memory
writes. The worker successfully wrote physical (10001,0,...,0)=31 then
(10000,0,...,0)=62. Initially the parent saw the stale value 35, traveled
west on its y=1 retry lane, and returned north to (1,0). The original
instruction there was `0`, which left the IP heading north and thus
prevented it from rereading the flag. The one-byte `0 → >` patch at (1,0)
restored eastward travel on every retry. The subsequent `a*` multiplication
uses Befunge's defined empty-stack pop of zero, preserving the decimal
address computation.

Native green receipts establish **both** seeds 1 and 2; in each case the
worker-generated residue is 31, all 16 axis numbers 1..16 are output,
all 48 dynamically emitted opcode bytes agree with the expected dialect,
and the seed-dependent final checksum matches. Both independent masking
runs successfully replace every one of the 48 source `@` cells with
`q`, without changing the result, because native `p` overwrites them
before native execution.

All **23 counterfactual mutants** succeeded as negative controls:
7 fork/poll/stack/`u`/worker causality probes and 16 independent
dimension-contribution probes. Of these, 22 encountered bounded
3-second nontermination (rc=124); the dimension-4 mutant exited normally
with incorrect output. They demonstrate a changed termination or output
in the tested cases, not that every mutant terminates differently.

Historical RED workflows
[39037198820](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39037198820)
and [39038284468](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39038284468)
remain preserved. Isolated forensics
[39040932810](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39040932810)
also reproduce a successful full worker/parent rendezvous, with real
physical g observations 35 → 35 → 62 and readback 31/62.

**Scope boundary:** this is a 17-dimensional, cooperative-scheduler
Funge++ QA sidecar. It does not test every possible OS-thread scheduling,
does not implement the calendar's entire canonical 2D arithmetic in 17D,
does not promote QA code into production, and does not close Stage 1.
Only QA08/12 has passed here; QA09/12 through QA12/12 remain open.
