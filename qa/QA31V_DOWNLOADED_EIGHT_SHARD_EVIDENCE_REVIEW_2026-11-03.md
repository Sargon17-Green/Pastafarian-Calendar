# QA31V — independent downloaded ZIP evidence review (finite ACCEPTED)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ  
Branch: `qa-befunge98-stage1-order-isolation-20261008`  
Audited exact-head commit: `e3700d9bd600f215b0cdc47d29d45e74f3b7667e`  
Unmodified original source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`  
Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481 (completed/success; 8/8 jobs completed/success)

## Independent download and structural evidence

All eight GitHub Actions ZIPs were downloaded and checked locally, not merely enumerated from the Actions API. For each ZIP: verified outer SHA256 against GitHub's recorded artifact digest, full ZIP CRC, 29 members including 25 distinct gzipped physical traces, `qa31v_receipt.json`, `qa31v_independent.json`, and both logs. For each of 200 cases: rebuilt exact raw input bytes independently from the 10x16 + 4x10 corpus definition, compared input hex and SHA256 with the receipt, asserted HALT with no error and <=25,000 STEP, compared trace filename and SHA256 of the actual compressed trace, decompressed the complete GZIP and counted physical trace rows exactly against receipt STEPs, and cross-checked the independent receipt's per-case summaries and shard totals. Original source blob pins match in both receipts for all eight shards; `source_modified=false`, `stage1_pass=false`. Each ZIP's audit log and `qa31v_independent.json` confirm 18/18 hostile controls rejected by the workflow auditor. The hostile mutations were **not independently replayed in this download review**; their recorded CI verdicts were inspected.

| Shard | Artifact | SHA256 | HALT | Physical STEP | Controls rejected | ZIP CRC / compressed trace SHA / row count |
|---:|---:|---|---:|---:|---:|---|
| 0 | [13257568625](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13257568625) | `5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553` | 25 | 493937 | 18/18 | PASS |
| 1 | [13257143122](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13257143122) | `375cdf0e4fd88edbadd096fc7876d5fecde3e08364903222b2f85924d0803c2f` | 25 | 494479 | 18/18 | PASS |
| 2 | [13255923675](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13255923675) | `9e71ecd677e9a16f748836ebf567413f27802554ed86d80c9c11376ab3ab396a` | 25 | 516001 | 18/18 | PASS |
| 3 | [13257900770](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13257900770) | `19196d6b0a0e37e6ce0703baff330e1d4a004669862d48be3adb6a19a1828458` | 25 | 507305 | 18/18 | PASS |
| 4 | [13258005544](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13258005544) | `83de475f9fc295d16c353e92e8c3a565686f53ecb936bc3666af59a7752f7f45` | 25 | 511653 | 18/18 | PASS |
| 5 | [13256499233](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13256499233) | `180d394a9aacf11d1b9a381f7997e252ee6dc1e6c772823d2f1698f9085186d0` | 25 | 511653 | 18/18 | PASS |
| 6 | [13256873940](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13256873940) | `1eda4ea3bfcb6f305499444752b4c269318ac40cf17f09fce979d3e7e8b30f14` | 25 | 341837 | 18/18 | PASS |
| 7 | [13257484076](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481/artifacts/13257484076) | `b54d244fcd45d38a4c7f8c99a490d32bfe55ff17de43b33a8239ec5fbf1dfa38` | 25 | 251525 | 18/18 | PASS |
| **Total** | **8 ZIPs** | **8/8 digest checks** | **200/200** | **3,628,390** | **144/144 recorded workflow rejections** | **all 200 full physical traces checked structurally** |

## Bounded observations, not global conclusions

- 150 cases made two recorded reads; 50 made one; 140 EOF-read events in the signed auditor observations.
- All 200 receipts recorded seven `-1` output fields. There were seven distinct STEP counts (17875, 20201, 18027, 9701, 22527, 20353, 10061), eight distinct combined route/read/STEP signatures.
- All first-visit fields for (286,5), (235,23), (235,32) were null in the audited 200-case corpus; observed finite frontier hits 0. This **does not** prove global unreachability of any address or general correctness.
- This Native matrix uses raw prefix `b'1 0 0 0'` plus exactly two suffix bytes; it tests 200 of 65,536 possible two-byte suffixes, not the full space. QA31U's earlier 256 one-byte suffixes remain separately accepted.
- The ZIP review independently checks outer and compressed-trace bytes and receipt consistency; the per-STEP FungeSpace/source behavior was verified by the Python 3 independent auditor in the completed CI jobs, **not replayed locally by this reviewer**.
- No production source modification, no Stage1 global PASS, no Stage2, no main/merge.

**Verdict: QA31V finite scope ACCEPTED** with the complete signed Native evidence and independently verified downloaded artifacts. Stage1 remains OPEN.

## Next engineering action (QA31W, independent offline characterization)

Use the 200 existing signed QA31V traces (no rerun of passed Native) to measure the causal boundary at each raw byte and EOF: produce a canonical 200-row `first_octet,second_octet,reads,eof_reads,steps,m29,q32,q38,j29,j32,j38,x29,x32,x38` table; group by first and second octet and verify the previously observed eight physical signatures. Build an **independent trace-level** classifier from the recorded STEP stream, rather than trusting the previously generated summaries. Include input-boundary/ownership checks for digit→digit, digit→NUL/FF, digit→whitespace, whitespace→digit, and disagreements across the 25-case shard boundary. Validate against at least eight corrupt traces spanning the eight observed signatures; expected-red requires actual rejection. Bound work to the 200 existing traces; separate observational class signatures from normative program behavior. If data do not support a causal claim, report the undecidable part, not a theorem. Preserve Stage1 OPEN.
