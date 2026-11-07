# QA09 N-dimensional OS-thread scheduling forensic

Status: independent **engine** experiment, not a new calendar implementation.

The historical run 39057292952 passed six full 17D Funge++ tests with
`-fthreads=funge` then timed out for `-fthreads=native`. The
source-pinned user QA09B candidate is
`275cec0add8705565d27da4233860bf42d134a27` (80 dynamic opcodes);
the fully Native-proven QA09A worker rendezvous is
`e22a8b706fb84e3356db6c70aac29b9145642201`.

Code inspection of the **exact** upstream engine revision
`cwesson/funge-plus-plus@cd6d7f005b4fc33b486fcc2380b35406f6125ca4`
found this lifecycle asymmetry:
- FungeUniverse::wait() blocks in `cv.wait(lock, !isRunning())`.
- FungeUniverse::operator() in `THREAD_FUNGE` calls `cv.notify_all()`
  when a runner ends.
- Its `THREAD_NATIVE` block drains and joins the native threads, but
  has **no corresponding condition-variable notification** when the
  thread queue becomes empty.

This may leave the process waiting indefinitely **after its result is
already printed**. That is an interpreter shutdown / scheduler issue,
not proof that a dynamically generated opcode is wrong.

The forensic script runs unchanged engine mode for three increasingly
strong specimens: one simple 17D IP, independently working QA09A
dual-worker rendezvous, and full QA09B 80-opcode source. On TimeoutExpired,
it records stdout bytes instead of discarding them.

In the same CI job, it then tests **one local engine-only correction**,
adding `cv.notify_all()` immediately after the native thread-queue
drain in FungeUniverse.cpp and recompiling. This is an **ephemeral
modification in the CI checkout**, NOT a commit to upstream Funge++, nor
a mutation of the Pastafarian Calendar production/QA sources. The
pinned upstream engine source and its original Native RED are preserved.

The experiment passes only if the original cooperative baseline stays
green and all three **patched-engine Native** cases terminate with
exact expected numeric output. The results are kept in an artifact
for precise causal diagnosis. Any resulting successful patched-engine
run must be labeled separately from unmodified upstream Native mode.
No QA09B general PASS or Stage1 completion should be inferred until
the actual evidence is inspected.

## Verified Native forensic result on 17 October 2026

On exact QA branch HEAD `bc57f31a5a225a1ab34c13826cf9de1e50233e48`,
[run 39060863054](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39060863054)
(job 117478357867) was **SUCCESS**. Unmodified upstream Funge++
`THREAD_NATIVE` timed out **even with a single 17D IP**:
`upstream_one_ip rc=124`, versus `upstream_one_ip -fthreads=funge rc=0, [0]`.
The same unmodified native engine also timed out with the verified
QA09A dual-worker and the QA09B 80-opcode source. Bounded timeouts
reported zero *flushed* stdout bytes; they cannot prove no computation
took place because stdout may have remained in an unflushed buffer.

The ***local, isolated*** addition of `cv.notify_all()` after the
native thread queue drained changed all three Native fixtures into
successful termination with correct numeric outputs:
single IP [0], dual-worker [31,33], QA09B exactly 99 numeric
cells ending in checksum 136 (seed=1). Each healthy `funge`
counterpart also passed. This is convincing differential evidence
of an interpreter thread lifecycle defect, **not** an assertion that
the upstream engine has been fixed.

A separate workflow named
`Befunge QA09B 17D Dual-Worker 80-Opcode Patched Native Engine Acceptance`
recompiles the same pinned Funge++ source with **only this temporary
life-cycle patch**, then reruns the complete source-pinned QA06→QA09B
acceptance chain, all 12 healthy QA09B runs, 80-trap source masking,
worker sabotage and 16 per-dimension mutations. That workflow is
a **patched-engine result**, not a test of the unchanged upstream native
scheduler. Stage 1 remains OPEN, source production unchanged and PR #17
unmerged.
