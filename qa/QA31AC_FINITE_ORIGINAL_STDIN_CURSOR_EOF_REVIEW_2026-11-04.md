# QA31AC — original signed Native `~` read-cursor and EOF finite review (2026-11-04)

Project: `PC-BRANCH-BEFUNGE98-KYRGYZ`. Working branch: `qa-befunge98-stage1-order-isolation-20261008`.
Verified pre-change branch HEAD: `3c38411bb716d2170de5e563d36c6acbfc60b652`.
Original production Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c` (site `(13,5)` is `~`); no production modification.

## Exact bounded input and evidence

This analysis reuses the frozen [QA31Y 17-item archive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view?usp=drivesdk), outer SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`. Its eight SHA-pinned original QA31V ZIPs passed ZIP CRC, receipt/trace gzip SHA256, STEP continuity and trace metadata checks (29/29 selected original HALT cases, 510,835 STEP records). Source-pinned opcode-site checks: 3,557. Original Native run: [41689861481](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481). QA31AB's 261 original source-pinned local `~`→`p(60,5)` witnesses were treated as a separate consistency requirement, not substituted for the input evidence.

### Measurable contract

Input: 8 unchanged ZIPs, SHA-pinned QA31W table, 261 earlier QA31AB witnesses, and these two Python 3 standard-library scripts. Every case is opened through `CaseReader`, which independently SHA-pins each original ZIP and each original compressed trace. `~(13,5)` is source-pinned via the prior original blob and per-event opcode checks. Reject any unmodeled I/O-read site, any observed `s` or `p` overwrite of the input instruction, inconsistent receipt raw-byte digest or `readline` offsets, incorrectly shaped read records, malformed stack transition, extra/missing byte, or EOF without a zero-byte read and a reverse IP direction.

Forward algorithm: increment a byte cursor across each logged `readline` payload and require the next physical `~` return to equal the next buffered byte; check the complete concatenated buffer against the independent per-case receipt `raw_hex` and `raw_sha256`. An empty read can witness EOF only after the declared raw input has been exhausted. Cross-link each successful `~` to the QA31AB physical `~`→`p(60,5)` witness.

Independent reverse algorithm: start from receipt raw input bytes at their final index, walk actual `~` returns **right to left**, match each value to the preceding raw byte, and independently assign a unique prior `readline` interval by `start/end` membership. It does not import or call the forward cursor checker. Compare the independently computed byte indices to the output witness CSV only after each original has passed this reverse validation. Perturb genuine signed trace event copies and receipt fields as hostile controls.

Output: machine-readable per-case JSON, per-step CSV, two summaries, logs, scripts, and a SHA256 manifest. All checks are bounded to these 29 archived cases; none is a new Native execution.

## Finite outcome

| Check | Accepted |
|---|---:|
| Exact original ZIP SHA256 + CRC | 8/8 |
| Original SHA-pinned Native traces | 29/29 |
| Signed physical STEPs | 510,835 |
| Original-source opcode event checks | 3,557 |
| Physical `~(13,5)` instructions | 281/281 |
| Successful byte returns, receipt SHA and unique offset mapping | 261/261 |
| QA31AB byte-value→`p(60,5)` equality on those same successful events | 261/261 |
| `readline` event/range/payload validation | 53/53 |
| Empty-read EOF reflections (delta `[1,0]`→`[-1,0]`, next IP `(12,5)`) | 20/20 |
| Independent reverse matches versus forward offsets | 261/261 |
| Forward synthetic positive / negative tests | 1/1 and 10/10 |
| Independent hostile mutations of a real signed original trace/receipt | 23/23 rejected |

The total recorded raw input across these 29 cases contains 261 bytes, matching all physically successful `~` returns. Twenty original `~` operations report an empty `readline` and physically reflect. Other observed `~` instructions consume an already returned `readline` buffer rather than creating a new read record. No `&` read instruction executed in these selected traces. SHA/CRC-pinned original receipts carry a `raw_hex` and `raw_sha256` for each case; the finite byte owner is thus identifiable *within this signed receipt + trace model*, not via a direct introspection of the interpreter's internal buffer.

**Boundary:** No independent observation of arbitrary untested stdin byte streams, no proof that the original tracing code cannot have a correlated defect, no global reachability proof for unvisited instructions or all input classes, and no automatic establishment of FULL_FUNCTIONAL_QA_PASS or GEOMETRIC_SPAGHETTI_QA_PASS. `Stage1` remains **OPEN**. This is not production release, `main` merge, Stage2, or global 55-stage acceptance. No Native/CI rerun was performed.

## Reproduction

1. Extract the pre-existing frozen QA31Y ZIP so `QA31V_SHARD0.zip` … `QA31V_SHARD7.zip` are all in one directory.
2. Extract this QA31AC package into a second directory. No external Python packages required.
3. From the QA31AC package directory run:

```sh
python stage1_qa31ac_forward_cursor.py --zip-dir /path/to/QA31Y --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --qa31ab-witnesses QA31AB_FORWARD_WITNESSES.json --out out_reproduced
python stage1_qa31ac_reverse_receipt_oracle.py --zip-dir /path/to/QA31Y --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --forward-csv out_reproduced/QA31AC_FORWARD_CURSOR_WITNESSES.csv --out out_reproduced
```

## NEXT / QA31AD

Run the same source-pinned finite cursor-and-EOF verification across **all 200** original QA31V signed HALT cases, not merely the 29-case QA31X selection. First derive the exact expected counts from original receipts and classify any unsupported read site or nonstandard EOF as `unknown`, not automatic failure of untested cases. Require per-case 8/8 ZIP SHA/CRC, trace SHA/STEP, input receipt hash, raw-byte cursor match, and independent reverse oracle; add adversarial sample/receipt controls and report case-by-case exact counts. Reuse the existing frozen ZIPs (no default Native rerun). This is a bounded coverage extension, not a Stage1 completion claim.