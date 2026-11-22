# QA31CD — Two new original-source Native candidate inputs (Stage 1 only)

**PROJECT_ID:** PC-BRANCH-BEFUNGE98-KYRGYZ
**Branch:** qa-befunge98-stage1-order-isolation-20261008
**Parent evidence:** QA31CC (HEAD 2a80f404f18c5c2f15caf349a2b97e0dd55a04d6); accepted QA31CB 900-case finite CI run 44996727508.
**Immutable production Git blob:** 560d6aa5807a7f766213a33835cce85eab0fa40c
**Immutable Native runtime:** PyFunge 0.5-rc2 TAR SHA-256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac

## Measurable contract

- **Inputs:** exactly two distinct natural, ASCII, no-newline stdin byte sequences, `1 1 0 100` and `1 1 0 999`. These are NOT members of the prior accepted 900-input domain `1 0 0 N`.
- **Execution:** fresh PyFunge program and original entry IP for each case; original source bytes unchanged, no artificial source, runtime cell or IP mutation. At most 50,000 physical STEP records per case, and explicit HALT / STEP_LIMIT / MULTI_IP / RUNTIME_ERROR.
- **Output:** two individual SHA256-pinned compressed full JSONL physical traces (not just digest receipts); per-case exact input bytes/SHA, STDIN read offsets, every IP/op/stack/SO/p/g/read and next-IP, stdout, status and source identity.
- **Independent oracle:** Python 3 standalone auditor does NOT import the Python 2 Native execution runner or interpret Befunge. Verify original Git blob and initial cell geometry, trace SHA, full STEP monotonicity and IP successor, p/g stack-derived effective addresses and values, source read events, output and receipts, then the specific second-input-operand write/read, `!*!*` gate, owner put/get, dynamic `56*g+62` put and subsequent opcode fetch. Do not carry old case results forward as new executions.
- **Required positive witness:** actual original-source `g(19,1696) != 0`, causally preceded by owner `p` fed from second operand (5,1691) and the four-op gate, followed by actual `p(1500,1860)=56*g+62` and corresponding opcode fetch with no intervening code-cell overwrite. All physically executed; a source-only prediction is not a witness.
- **Negative and incomplete outcomes:** pre-gate branch divergence, invalid input, HALT before the chain, STEP_LIMIT, MULTI_IP, RUNTIME_ERROR or partial nonzero owner must be reported separately. No blanket inference about global reachability.
- **Hostiles:** independently reject at least 20 detached tamper mutations (receipts, raw stdin, SHA, source flags, p/g event summaries, stdout and trace continuity). A failed audit is not a PASS.
- **Artifact:** GitHub Actions run ID/job/commit and two retained full traces, signed receipts, independent audit JSON, stdout/stderr logs, source/toolchain SHA, file manifest with SHA256 and ZIP CRC checked post-run.
- **Comparators:** historical accepted `1 0 0 100` and `1 0 0 999` QA31CB traces; do not rerun old domain.
- **Gates:** QA31CB finite Native+CI remains accepted at its exact prior SHA; QA31CD is new and must be evidenced by completed exact-commit CI/job/log/artifact; full Stage 1 remains OPEN, no production edit, main/merge/Stage2.

Do not claim QA31CD Native PASS from code review, a queued run, or a predicted value.
