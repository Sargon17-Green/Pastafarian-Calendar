# QA15 — Native hot reset with a concurrently live peer

**Status: New Native CI pending; NOT Stage 1 acceptance.**

This experiment closes a distinct finite coverage gap left by the successful prior tests: QA13/QA14 proved physical Funge-space ownership across fixed independent processes; existing reset tests exercised repeated exact-`Program` identity after completion; concurrent ownership tests did not reset one already completed `Program` *while another independent Program remained alive and partially executed*.

Four scenarios: two invalid→valid and two valid→invalid, with peers on actual independent valid Native BF98 paths. The peer executes **1,500 real Native steps** before any actor reset. The first actor completes, then the identical Python `Program` instance is reinitialized while the peer retains its original IP/space/semantics/input/output. The reset must allocate new private Funge-space, semantics, platform and initial IP, without mutating the previous actor's physical `p` write targets, or the other live Program's full available state plus every prior physical write target.

After the reset, both run via interleaved real PyFunge `execute_step` until normal termination; all seven numerical results come only from three real independent native Befunge references per valid input, or the seven rejection sentinels for invalid inputs. The tests instrument every native `Space.get` / `Space.put` owner, ensure physical `p` writes were performed correctly, and disallow unexpected runtime `putspace`. Each quantum checks the passive program's states and prior written cells. An independent Python3 auditor verifies report binding, counts, scope and rejects nine forged receipts.

Sources: `qa/stage1_qa15_hot_reset_with_live_peer.py`; auditor `qa/stage1_qa15_hot_reset_audit.py`; CI `.github/workflows/befunge-stage1-qa15-native-live-peer-hot-reset.yml`. Pin immutable QA production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`; references `f941efc793c9eee4accf5d03873f8ed029b16725` and `7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44`.

This test does **not** assert that unreset reuse is supported or safe, nor prove general concurrency or calendar semantics. If GitHub CI fails, retain RED as diagnosis and repair the test or source only after evidence; do not lower the contractual requirements. Do not modify `main`, `Befunge+Кыргызча`, accepted QA10–QA14 originals, or start Stage 2.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`; functional and geometric final gates remain OPEN.
