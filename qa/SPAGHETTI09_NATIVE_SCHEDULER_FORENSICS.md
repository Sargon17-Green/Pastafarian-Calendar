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
