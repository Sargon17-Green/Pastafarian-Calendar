# QA26 finite original Native source-frontier acceptance — 23 October 2026

**PASS for 64 precommitted natural-input PyFunge-98 routes; Stage 1 remains OPEN.**

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39945902093
- Tested HEAD: `0d6ab84dafc406cc8512c8664a66ba68edc69d0b`; five CI jobs PASS (four Native 16-case shards and one independent 64-case aggregate).
- Immutable source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- 32 valid plus 32 malformed new unique inputs (all disjoint from QA20/QA24), totaling **1,796,720 actual PyFunge STEP operations**. Each raw compressed trace was independently decompressed, checked for expected SHA-256, monotonically numbered ticks, and counted. Independently retrieved original five ZIP artifacts all passed SHA-256/CRC.
- 52 of 52 forged reports rejected by the independent CI auditor.
- **Zero previously unseen** source-control candidates among the original 15 gained natural opcode exposure, and zero of their minimum Manhattan distances improved. Three previously known source-coordinate/opcode contacts were observed: `(10,44)`, `(179,44)`, `(396,17)`. No other prior source contact is disproved.
- All 15 previously unobserved original source opcodes remain unresolved (not certified dead).

| Role | Original artifact | ZIP SHA-256 | Native steps |
|---|---|---|---:|
| Shard 0 | 12500778468 | `2c4364836b83569288415e2ab477482da64cfddfcc4f9a3464dc9ee8526c7d60` | 297544 |
| Shard 1 | 12501296803 | `c474dea33150e2b0a2cabd482a2d5b98493ca567d8d8d158690d189787e05887` | 474256 |
| Shard 2 | 12500584244 | `da2afe9157ba2049fa5717d2b848b9d95f2ceb44eef7cd0f2fb907c4b5546e2f` | 521880 |
| Shard 3 | 12500923302 | `abf02955ed23ef6423c27b879907b6432e5c90f25a827e9982687ea546998608` | 503040 |
| Independent aggregate | 12504082236 | `44a04c37326e084e4cad67c25f81fa29cb11f3b43c3610bda6d05555dc530404` | 1796720 |

These checks establish finite actual execution and input-output parity only. Physical STEP traces alone are insufficient to prove static-byte ownership if preceding memory writes occurred; global geometry, unrestricted input and mutation ownership remain open. No production changes, no main/canonical changes, no PR #17 merge, no Stage 2.

`CURRENT_STAGE=1`, `LAST_COMPLETED_STAGE=0`, `FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`.
