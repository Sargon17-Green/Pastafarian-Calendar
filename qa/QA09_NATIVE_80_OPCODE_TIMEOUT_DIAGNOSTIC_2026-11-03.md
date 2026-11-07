# QA09B — bounded diagnosis of the 17D Native 80-opcode timeout

Project: PC-BRANCH-BEFUNGE98-KYRGYZ  
Branch: qa-befunge98-stage1-order-isolation-20261008  
Diagnostic parent: QA31S HEAD 990d53a2d8362229eccaeda101dfc588e4001398

## Existing failure, verified from run and artifact

Workflow run 41525895742 completed with failure on parent SHA b111f5f7980c427eccea16bc7f24318e976460f2. Build, the Hello World Native smoke, QA06, QA07, QA08 and QA09A rendezvous steps completed. The six `funge`-mode cases (seeds 1 and 2, three repetitions each) all passed with 99 numeric output cells. The first `native`-mode case, seed 1 repetition 0, returned exit 124 after the existing 12-second bound with no stdout. The artifact 13179429554 has SHA256 ae65bd5db28f7768ba0b666965ad7994c99fd79a6b36b563267b17e20052fb13; its four preserved provenance receipts pass ZIP CRC. The final QA09 80-opcode receipt was not produced.

This is a real bounded timeout, not proof of deadlock, semantic failure, or unreachability.

## Diagnostic design

- Pin the original production source, QA08 source, QA09 rendezvous fixture, 80-opcode candidate, manifest, and Funge++ submodule commit.
- Run only the exact first failing case: candidate input seed 1, mode `native`, once, with a 60-second bound.
- Run one `funge`-mode seed-1 control with the original 12-second bound.
- Capture wall time, exit status, output, stderr tail, process CPU ticks, resident memory, thread count, and bounded per-thread state/wait-channel samples at 1/5/10/20/40/60 seconds.
- Do not rerun the full 80-opcode matrix, mutate the candidate, modify production, or infer a deadlock from a timeout.

## Decision

- If Native completes with the exact 99-cell oracle within 60 seconds, the original 12-second limit was insufficient for this case; the full QA09 matrix still needs a separate bounded rerun with a justified per-case limit.
- If Native still times out at 60 seconds, retain the thread/CPU evidence and design a narrower instrumented concurrency investigation. Do not label it a deadlock without evidence.
- If Native exits with incorrect output or a nonzero status before the limit, preserve the exact result and investigate that concrete discrepancy.

This is diagnostic evidence only. QA09 full 80-opcode acceptance remains OPEN; no Stage1 PASS, production edit, merge, main update, or Stage2.
