# QA31V — full original-Native two-byte EOF suffix matrix (200 cases)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Parent: 554b319125fc5610fe00b34703bc296ab330c20e
Original production source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Pinned PyFunge 0.5-rc2 archive SHA256: e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac

## Exact two-byte raw input corpus

Fixed prefix b'1 0 0 0' (seven ASCII bytes), plus exactly TWO raw suffix bytes; no implicit LF.

A: first octet is any ASCII digit 0x30..0x39; second is one of ten ASCII digits 0x30..0x39 followed by NUL 0x00, TAB 0x09, LF 0x0A, CR 0x0D, ASCII space 0x20, 0xFF. First-byte-major 10x16 = 160 cases.
B: first octet is TAB, LF, CR or ASCII space (0x09,0x0A,0x0D,0x20); second any ASCII digit. First-byte-major 4x10 = 40 cases.
A then B: 200 pairwise distinct cases, 8 shards of exactly 25.

This is a finite transition test after QA31U (256 one-byte suffixes; accepted run 41651086578). It does not re-run any one-byte case or claim exhaustive coverage of all 65536 two-byte suffixes.

## Runtime and audit evidence

- Original unchanged BF98 production source and original unpatched PyFunge interpreter. Each case instantiates a fresh one-IP Native Program.
- 25,000 physical STEP limit per case; 625,000 per shard and 5,000,000 aggregate. Every case must HALT; any STEP_LIMIT or runtime error is a failure, not a green result.
- Python 2 records the true physical IP, delta, source/p-overlaid opcode, stringmode, complete pre/post stack, next position/delta, p/g events, stdin byte spans and EOF, output and gzipped full trace SHA256.
- Independent Python 3 auditor reconstructs every expected input byte sequence independently, validates original source Git blob and 2015-row geometry, exact receipt/cardinality, raw input hash, every physical event, p/g overlay, true byte offsets and EOF, j/x observations, and first physical visits of (286,5), (235,23), (235,32). Its per-case summaries include m29/q32/q38 reads, j operands and x exit events.
- The auditor reuses the QA31U stable 11 malformed-receipt plus 7 physical trace tamper test definitions, but invokes them with a QA31V-specific independent receipt validator, yielding exactly 18 expected rejections per shard (144 total). This is local test-process configuration, not an engine/source change.
- Acceptance: eight exact-head jobs completed/success; 200/200 HALT, all 200 compressed physical traces independently checked, 144/144 forgeries rejected; download all eight GitHub ZIP artifacts and verify exact SHA256 and CRC before marking finite QA31V PASS.

## Explicit scope limits

Global reachability or input ownership of any source cell remains unproven; finite nonvisit does not imply impossibility. Full functional and geometric Stage1 gates remain outstanding. No production modification, no Stage1 PASS, no Stage2, no main/merge, no release.
