# QA31D — same-size valid-pair pre-j Native diagnostic

Project ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`. Stage 1 of 55 stays open; no Stage 2, merge or canonical/main edits.

## Why this is new
QA31B measured pre-`j` operand 61 on `valid00` and 0 on `invalid18`, but the latter is an **empty** invalid input and not a same-size valid intervention. QA31C measured genuine Native stdin-to-output causality for `valid00` versus `invalid16`; `invalid16` did not visit `j`.

This bounded QA31D experiment changes **one byte** between two eight-byte, newline-aligned **valid** source inputs:
- QA20 signed shard 0: `valid00 = "0 0 0 0\\n"`
- QA20 signed shard 1: `valid01 = "0 0 0 1\\n"`

The physical Python 2/PyFunge program is instantiated from unmodified source blob `560d6aa5807a7f766213a33835cce85eab0fa40c`, with identical initial input buffer, IP and Funge-space. Only bytes actually returned by a real stdin read are substituted. Every unsampled physical STEP and terminal output must match a **different already signed QA20 original**. At every actual `j` at (114,38) moving right, directly sample the Native pre-operand TOSS, verify pop and signed successor. Independently verify the original manifest SHA256, all STEP lines, read receipts, signed source, and ten hostile forgeries.

**Decision rule:** report a *finite* input-to-pre-`j` operand difference only if **both** routes visit the same `j` and their Native operands differ. Otherwise report only bounded equality or absence of a paired witness. No implication of global ownership or full Stage 1 acceptance. The original 136-route frontier, 15 unseen cells, and all open full-functional / geometry requirements remain open.

## Verification state
Implementation committed as Stage-1-only QA. Native / CI acceptance is **PENDING** until exact-head workflow result, raw artifacts and independent hostile audit are checked. A green syntax check alone is not Native evidence.

## Next
Inspect the exact-head [QA31D workflow](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/workflows/befunge-stage1-qa31d-native-valid-pre-j.yml), then its original artifact, SHA256/ZIP CRC and 10 hostile rejections. Record finite result without closing Stage 1. No rerun of any known failed unequal-length experiment.
