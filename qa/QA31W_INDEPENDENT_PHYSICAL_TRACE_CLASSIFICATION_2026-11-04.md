# QA31W — independent offline physical-trace classification (finite accepted, 2026-11-04)

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ`  
Working branch: `qa-befunge98-stage1-order-isolation-20261008`  
Starting branch HEAD: `ccf87af55be788dad2b73b6dd6675518d7bd8687`  
QA31V original Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481  
Native source commit: `e3700d9bd600f215b0cdc47d29d45e74f3b7667e`  
Original source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`

## Reproducible evidence archive

[Five-file QA31W bundle, Google Drive](https://drive.google.com/file/d/1OpaqpvSGETQ2HUIDmGTHXyLVawIpXCRm/view)  
SHA256 (downloaded ZIP): `54c80435b9d09ce73c258884459e17f4202b5e9092915f4268d1f58a7e08d50f`

This ZIP contains:
- `stage1_qa31w_offline_trace_classifier.py`: complete Python 3 standard-library-only reproducible analyzer; provide `QA31V_SHARD0.zip` ... `QA31V_SHARD7.zip` using `--zip-dir`; pass `--out` for the output directory.
- `QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv`: all 200 original cases including raw first/second octets, stdin reads and EOF reads, STEP count, memory gates, j operands, x vectors, and route signature. SHA256 `0c45aea30f021671084bb4ccaa67436a00edcf1aaa41a6b23e3afbfdf9b89800`.
- `QA31W_EVIDENCE.json`: canonical source pins, per-shard totals, all boundaries, eight signed-independent physical signatures and structural failure witnesses. SHA256 `5d3675269afd2d5e53a02b4705aa78eb47460dd582d6f8625e46dbd4d79386f4`.
- `QA31W_EIGHT_ACTUAL_CORRUPT_TRACES.zip`: eight genuinely modified compressed physical traces, each distinct original-route class and structurally rejected when SHA enforcement was deliberately bypassed to test the parser. SHA256 `a771a40aaa38039e0067cdd2065451ef12cb22560db6d61db7506958ad247272`.
- `QA31W_OFFLINE_TRACE_REVIEW.md`: human review table, original boundaries, 7 shard edges and all expected-red witnesses. SHA256 `e6f3c2778b2581ef01beab364378a7d68f24528ca2ed0bbd1544c66ab0c42bd6`.

## Checks actually performed

- 8/8 QA31V outer original artifact ZIP SHA256 and full ZIP CRC matched the pinned GitHub Actions artifacts.
- 200/200 case inputs reconstructed from `b'1 0 0 0'` and two raw suffix octets, with SHA256, labels, and order checked.
- 200/200 original gzip compressed-trace SHA256 verified before parsing.
- 3,628,390 actual physical STEP records read; ordinal, IP/delta continuity, raw stdin consumption and EOF provenance, and observed g/j/x spatial and stack constraints checked independently of earlier summaries.
- 200/200 physically derived per-case signatures agreed with signed independent QA31V summaries **after** classification, not as input to the classifier.
- Eight concrete altered gzip trace files were written and checked: 8/8 **structural expected-red** rejections across eight observed route signatures, for tick, initial IP, step continuity, stdin hex, g stack, j geometry, final HALT, and x vector.
- No new Native execution, no modifications to the original program or main.

## Eight physical signatures

| Route | Cases | STEPs | reads | EOF | gate and route observation |
|---|---:|---:|---:|---:|---|
| R1 | 20 | 9,701 | 1 | 0 | no m/q/j/x gate |
| R2 | 30 | 10,061 | 1 | 0 | no m/q/j/x gate |
| R3 | 10 | 10,061 | 2 | 0 | no m/q/j/x gate |
| R4 | 1 | 17,875 | 2 | 1 | m=1; q32=3,q38=4; j=(61,0,61); x29/x32/x35 |
| R5 | 4 | 18,027 | 2 | 1 | m=0; q38=4; j29=0,j38=61; no x |
| R6 | 9 | 20,201 | 2 | 1 | m=1; q32=3,q38=4; j=(61,0,61); x29/x32/x35 |
| R7 | 36 | 20,353 | 2 | 1 | m=0; q38=4; j29=0,j38=61; no x |
| R8 | 90 | 22,527 | 2 | 1 | m=1; q32=3,q38=4; j=(61,0,61); x29/x32/x35 |

Raw-octet classes: digit→digit 100 (R4=1,R6=9,R8=90); digit→NUL/FF 20 (R1); digit→whitespace 40 (R5=4,R7=36); whitespace→digit 40 (R2=30,R3=10). All seven 25-case shard edges were assessed: only `pair_34_00→pair_34_09` crosses a route-signature boundary. This is an **observed partition** of 200 samples, not a causal input-ownership theorem.

## Remaining scientific gap / next

**QA31W finite trace classification ACCEPTED. Stage1 remains OPEN.** These checks are a physical trace characterization, not an independent full FungeSpace evaluation of each opcode; that stronger oracle was exercised by the original QA31V CI. Zero frontier visits in this finite sample does not establish global inaccessibility.

**NEXT QA31X:** bounded, offline pairwise first-divergence analysis of the eight observed physical routes (one representative per class and at each input/shard boundary); compare raw stdin read event ticks, IP/delta and the earliest control-flow split; distinguish noncausal differences due to repeated loop counts from the first witnessed changed branch; provide minimal witness pairs and invariant checks against the 200-row QA31W corpus. Use existing ZIPs, no duplicate Native runs or Stage1 PASS claim. If the physical trace cannot establish ownership of a byte, report that uncertainty.