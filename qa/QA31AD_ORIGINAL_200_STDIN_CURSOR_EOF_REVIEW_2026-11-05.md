# QA31AD — Original signed Native stdin byte cursor/EOF review, full 200-case corpus (2026-11-05)

- `PROJECT_ID`: `PC-BRANCH-BEFUNGE98-KYRGYZ`
- Working branch: `qa-befunge98-stage1-order-isolation-20261008`
- Pre-change branch HEAD: `9d2c898bf4c0c9d2dd8c21633da0b4e4e7c3108a`
- Original production Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c` (no source changes)
- Original Native run: `41689861481`, 8 already-completed shards. **Zero new Native or CI runs.**
- Immutable 17-item original QA31Y archive in Drive: https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view ; SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`.

## Scope and algorithm

Extend QA31AC's source-pinned `~(13,5)` buffered-return and EOF reverse-direction verification from the 29 selected QA31X original cases to **every** 200 original QA31V HALT case. Frozen SHA256 for each of eight artifact ZIPs is enforced in the earlier QA31X `CaseReader`, along with ZIP CRC, actual compressed gzip STEP SHA, exact STEP counts and chronological IP/direction continuity. `QA31W` classification CSV SHA is independently pinned. Original per-case `raw_hex` and `raw_sha256` in receipts determine the expected raw byte lengths. All `readline` payloads, offsets, positions and return values are checked against that pinned raw receipt. The algorithm separately checks a right-to-left byte-index/refill-owner oracle (imported from QA31AC); per-return exact raw offsets must agree with forward reconstruction.

The QA31AD runner classifies observed unsupported input opcodes `&`, `s`, writes to the original `~` site, unexpected stdin sites/direction and multiple refills as `UNKNOWN`. It does **not** silently convert such behavior into a pass or infer a bug. Invalid source pins, compressed traces, receipt digests, refill records or cursor transitions fail closed. Tests include original-record mutations of a source-site opcode, a byte-return stack effect, receipt SHA, receipt read count, physical next-IP, plus modified original outer ZIP and compressed trace bytes: **7 negative controls per shard**, all triggering rejection. QA31AC's 10 synthetic controls plus one positive control were also executed.

## Actually observed finite results

| Check | Result |
|---|---:|
| Frozen outer SHA256 and ZIP CRC | 8/8 original ZIPs |
| Original compressed Native SHA256 and STEP count | 200/200 physical traces |
| Total historical Native STEPs inspected | 3,628,390 |
| Original-source pinned opcode checks | 24,440 |
| `~` physical instructions inspected | 1,940 |
| Byte returns consistent with original input receipts | 1,800/1,800 |
| Independent backward refill/byte offset oracle | 1,800/1,800 |
| Original `readline` calls (including empty EOF reads) | 350 |
| Empty-read EOF reflections | 140 |
| Original signed trace/receipt/source/ZIP mutation rejections | 56/56 |
| Synthetic negative controls (and positive baseline) | 10/10 (1/1) |
| Observed unsupported cases (`UNKNOWN`) | 0/200 |

All 200 cases have the fixed 9-byte raw prefix+suffix input recorded in their signed receipts; the 1,800 returned bytes match these per-case records. `readline` counts include 140 empty EOF reads and 210 non-empty reads. This is **independent checking of an existing physically logged corpus**, not direct instrumentation of the interpreter's internal read buffer. The checks cannot eliminate a defect shared by the original trace producer and receipt logging.

No universal input ownership, EOF semantics for arbitrary streams, unvisited-source reachability, FULL_FUNCTIONAL_QA_PASS or GEOMETRIC_SPAGHETTI_QA_PASS is proved. **Stage1 remains OPEN**, even though this finite QA31AD audit passes. No production source change, no `main` merge, no Stage2 or publication.

## Reproduction

Python 3.9+ stdlib only. Download the exact QA31Y ZIP (linked above), and extract the companion QA31AD package containing `RUN_QA31AD.py`, `stage1_qa31ad_full_200_cursor_eof.py`, and original-source QA31X/Y and QA31AC dependencies. In that directory:

```
python RUN_QA31AD.py --qa31y-archive path/to/QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip --out qa31ad_reverified
```

The runner validates the original outer SHA256 and CRC before unpacking only the nine allowlisted evidence names, runs all eight 25-case verifiers and combines the results, writing per-shard physical witnesses, per-case CSV, reverse witness CSV, summary and SHA256 manifest. All results here were independently generated offline against the frozen original QA31Y evidence.

## Next (QA31AE, proposed bounded work)

Take the same 200 signed original traces and measure the remaining source-control coverage frontier, especially the previously identified 15 unvisited control glyphs. Build a 200×15 source-pinned physical presence matrix, independently verify each observed entry against the original source blob, and enumerate **observed** local predecessors only; separately report source locations never visited in this corpus. Mutate original signed STEP/source-site copies for expected-red. No new Native by default. This cannot establish global reachability or Stage1 completion. Do not alter source code or start Stage2.