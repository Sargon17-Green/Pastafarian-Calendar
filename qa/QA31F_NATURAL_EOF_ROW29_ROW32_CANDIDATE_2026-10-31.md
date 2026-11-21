# QA31F natural EOF reflection candidate — 2026-10-31

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ`; branch `qa-befunge98-stage1-order-isolation-20261008`.

Original source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c` (`src/interleaved_work_counts.b98`). Previous exact-SHA model CI [run 41179346927](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41179346927) completed/success for `c9646d2f834fa0f0753b072ee61970d2a64c9a83` (60 ASCII-prefix models, three hostile modifications). **Those are not Native results.**

## Question

Can a naturally terminated short stdin cause `m=g(3,49)=1` at the row29 `j` gate, even though all earlier observed QA20 row29 visits took the `m=0` branch? This is a finite source-model counterexample to an overly broad inference of unreachability; it is **not** a native or global reachability proof.

## New executable contract

Script `qa/stage1_qa31f_eof_reflect_row29.py` loads the original Git-blob-pinned source through the existing same-branch source verifier. It models a specific Funge-98 EOF behavior: no input byte available at `~` causes direction reflection (not a synthetic byte value). A separate bounded interpreter observes the source's operand stack, `g/p` overlay, row29/row32 jumps, and row35 write; input is consumed byte by byte. Six stdin candidates, four source-opcode sabotage controls, ≤7,000 model steps per case. No repeated QA20 corpus scan or 263-case q-writer scan.

Expected finite observations for natural stdin termination (model tick indices are zero-based):

| stdin bytes | EOF `~` | row29 `j` | `m` at gate | row32 `j` | row35 `p(1,49)` | halt |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| empty | 319 | 462 | 0 | no | no | 859 |
| `0`, `1`, `9` | 1236 | 1379 | 1 | 1544 | 1844 | 2241 |
| `1 ` | 2777 | 2920 | 0 | no | no | 3317 |
| `1 1 ` | 5235 | 5378 | 0 | no | no | 5775 |

In the single-byte case, `m` is written by source `p(248,14)`; EOF at `(13,5)` reflects to `(12,5)`, turns down to row6 and subsequently reaches `j(89,29)`. There the source model takes `j=61`, reaches row32, row35, and writes `q=1`. The four mutation guards blank original physical opcodes `v(12,5)`, `p(248,14)`, `j(89,29)`, `p(248,35)`; all must be rejected.

## Evidence boundary

All counts above are model observations; the new GitHub workflow has to finish on its exact new SHA before the scripted six fixtures/four guards can be marked verified. An EOF reflection is an interpreter-specific assumption in this model, **not yet matched to actual PyFunge Native behavior**. No signed STEP trace was produced; no global source-ownership proof; no Stage1 PASS. No change to production, protected branch, main, or Stage2.

NEXT: read the exact-SHA targeted CI result and log. If completed/success, construct a **new minimal Native EOF probe** for stdin `b"1"` versus `b"1 "` and `b""`; pin original source blob, capture full per-step IP/operand/p/g and input/EOF events; independently audit each complete trace and reject forged provenance. If the interpreter does not reflect on EOF, record the actual observable behavior rather than changing the expected result to fit the model. Never infer a Native success from Python CI.
