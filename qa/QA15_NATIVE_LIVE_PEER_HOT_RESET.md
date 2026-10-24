# QA15 — Native hot reset with a concurrently live peer

**Status: New Native CI pending; NOT Stage 1 acceptance.**

This experiment closes a distinct finite coverage gap left by the successful prior tests: QA13/QA14 proved physical Funge-space ownership across fixed independent processes; existing reset tests exercised repeated exact-`Program` identity after completion; concurrent ownership tests did not reset one already completed `Program` *while another independent Program remained alive and partially executed*.

Four scenarios: two invalid→valid and two valid→invalid, with peers on actual independent valid Native BF98 paths. The peer executes **1,500 real Native steps** before any actor reset. The first actor completes, then the identical Python `Program` instance is reinitialized while the peer retains its original IP/space/semantics/input/output. The reset must allocate new private Funge-space, semantics, platform and initial IP, without mutating the previous actor's physical `p` write targets, or the other live Program's full available state plus every prior physical write target.

After the reset, both run via interleaved real PyFunge `execute_step` until normal termination; all seven numerical results come only from three real independent native Befunge references per valid input, or the seven rejection sentinels for invalid inputs. The tests instrument every native `Space.get` / `Space.put` owner, ensure physical `p` writes were performed correctly, and disallow unexpected runtime `putspace`. Each quantum checks the passive program's states and prior written cells. An independent Python3 auditor verifies report binding, counts, scope and rejects nine forged receipts.

Sources: `qa/stage1_qa15_hot_reset_with_live_peer.py`; auditor `qa/stage1_qa15_hot_reset_audit.py`; CI `.github/workflows/befunge-stage1-qa15-native-live-peer-hot-reset.yml`. Pin immutable QA production Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`; references `f941efc793c9eee4accf5d03873f8ed029b16725` and `7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44`.

This test does **not** assert that unreset reuse is supported or safe, nor prove general concurrency or calendar semantics. If GitHub CI fails, retain RED as diagnosis and repair the test or source only after evidence; do not lower the contractual requirements. Do not modify `main`, `Befunge+Кыргызча`, accepted QA10–QA14 originals, or start Stage 2.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`; functional and geometric final gates remain OPEN.

## QA15 Native CI final acceptance — 20 October 2026

The earlier **CI PENDING** header above is superseded for the following *bounded scope only*. The final corrected [GitHub Actions run 39381505937](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39381505937) at exact tested commit `7be63aff4dd51f74bc6571423eb1d4b7bc34085e` completed **SUCCESS**; independent acceptance artifact `12245524436` exists and was downloaded and inspected. Archive contains `native_live_peer_hot_reset.json`, `qa15_hot_reset_independent_audit.json` and `auditor.log`.

- **4 real Native BF98 live-peer hot-reset scenarios, 12 Native Program executions, 18 independent Befunge reference invocations**; same original object reinitialized while a second owner remained active.
- Peer pre-reset overlap rounds: **944**, post-reset overlap rounds: **645**; **3,905** checks of preserved live-peer state and prior-written coordinates.
- Each scenario uses **1,500 actual peer warmup steps** and independent seven-field reference output. Valid/invalid transitions in both directions, old actor Funge-space no-stale-write assertion, and new private semantics, IP, I/O assertions passed.
- Independent auditor produced `qa15_hot_reset_independent_audit.json` SHA-256 `2bf117883638371eb5211ce66e62d665187b4b8bf65437e4e94ab59c225da21b` and rejected **9/9 fabricated reports**. Raw actual Native receipt `native_live_peer_hot_reset.json` SHA-256 `d8737b3e8d2789e120fcfc3a130d010905b5a2c6d927fc08d8fddecc2031c3b3`. Exact source Git blob remains `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Preserve failed earlier QA15 workflow attempts separately as historical RED; final GREEN claim is specifically based on successful `39381505937` and the downloaded artifact, not a CI status indicator alone.

**Strict limitation:** QA15 proves only four finite traces with explicit `Program.__init__` hot reset and a single non-resetting live peer. It does **not** certify implicit in-place reuse, arbitrary interleavings, general semantic state ownership, production geometry, global Stage 1 or release readiness. Keep `CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`, no Stage2 or canonical branch merges.
