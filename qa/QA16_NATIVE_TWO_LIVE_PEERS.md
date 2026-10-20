# QA16 — Native hot reset while **two** other Befunge-98 Programs remain live

## Contract and limitations

**Status: CI PENDING, not final approval**. This QA-only experiment extends QA15 to a *new physical-state topology*, not to full Pastafarian calendar computations: there are three separate real PyFunge `Program` instances, all running the same frozen original **2D** production source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. One Program completes and is explicitly reset **using `Program.__init__` on the very same object**, while the other **two** already executed at least 1,500 Native steps each, and remain live with independent Funge-space, IP/stack, semantics, stdin/stdout and previous physical writes.

Four disjoint scenarios include invalid→valid and valid→invalid actor transitions, three unequal schedule quanta, and both directions of sign/lexical errors. Before and after the reset, no active Native quantum may mutate either passive Program's objects, stack, output, inputs or exact previously written Funge-space destinations. The abandoned actor's original written-cell memory is compared before/after reset and again after all three Programs terminate. A deliberately injected, immediately restored hostile write to a passive Program's existing physical target **must be detected** by the snapshot mechanism. This negative-control injection is *test-only*, never attributed to an actual Native opcode or counted as production writes.

Every valid seven-value expected answer is generated exclusively by independent Native Befunge `reference/work_counts.b98` and two Native `reference/save.b98` invocations; invalid input must produce seven rejection sentinels. Each real Native Program result is compared to its reference, including both continuously live peers. Python directs scheduling and verifies isolation only; it does not implement calendar arithmetic. An independent Python 3 audit checks a fixed scenario/order schedule, six valid native reference vectors, all measured overlap and physical-state counters, and rejects 12 synthetic corrupted reports. The CI runner uses SHA256-pinned original PyFunge-0.5-rc2 in Python2.7 Docker and retains receipts on success or failure.

Files:

- `qa/stage1_qa16_hot_reset_two_live_peers.py`
- `qa/stage1_qa16_hot_reset_two_live_peers_audit.py`
- `.github/workflows/befunge-stage1-qa16-native-two-live-peer-hot-reset.yml`

This is a finite QA experiment. It **does not** prove unlimited thread safety, process isolation at every possible opcode, unsupported no-reset reuse, completion of geometric spaghetti or final Stage 1 functional coverage. Do not change production source, QA10–QA15 accepted originals, `main`, `Befunge+Кыргызча`, PR #17, or Stage 2. `CURRENT_STAGE=1; LAST_COMPLETED_STAGE=0`.
