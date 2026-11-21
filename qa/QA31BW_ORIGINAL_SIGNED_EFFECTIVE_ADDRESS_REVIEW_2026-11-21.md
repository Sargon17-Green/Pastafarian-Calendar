# QA31BW — original signed effective p/g addresses and last-p writer provenance

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**QA-only authorized branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified entry HEAD:** `93bd9e7124ddbac373ae15b3252df2752ce513dc`  
**Disposition:** **QA31BW LOCAL FINITE PASS (QA-only); Stage1 OPEN; zero new Native/CI runs.**

## Immutable original inputs and scope

Five Library archives AI, BN, BO, BT and BP were read from `/Befunge_QA_Artifacts` with their previously pinned SHA-256 bytes checked. AI contains nested AH and Y, also verified against independent pinned SHA-256. The Y manifest SHA-256 validated all eight original QA31V shards and associated evidence, and each QA31V shard passed ZIP CRC. Each of 200 case receipts had source Git **blob SHA-1** `560d6aa5807a7f766213a33835cce85eab0fa40c`, matching the pinned original source identifier; every original compressed STEP passed its receipt SHA-256, original raw stdin hex passed SHA-256, status was HALT, and steps had contiguous ticks with physical IP/next continuity. The entire Git source blob itself was **not** newly fetched/rehashed; source-byte content outside these original receipts is not certified by this pass. Manifest and receipt controls are not substitutes for global functional coverage.

## Contract and independent oracles

- The original QA31BV finite audit established that executed original `{`/`}` changes were zero, so storage offset is (0,0) at **observed** p/g sites. Only these original signed sites are addressed here.
- Address oracle F directly indexes the physically recorded bottom-to-top pre-stack: `p` consumes `(v,x,y)`, while `g` consumes `(x,y)`, with zero on underflow. Each original effective address is `(x+SO_x,y+SO_y)`, and SO=(0,0) at these observed sites. All original p/g coordinate operands were integer-valued. It does **not** silently coerce observed floating-point *values* into integers.
- Independent address oracle R copies each physical pre-stack and uses sequential LIFO pops with explicit zero-on-underflow, without consulting F. Eight synthetic underflow/negative-coordinate contracts check both algorithms, but are not Native evidence.
- Chronological last-p oracle F maintains an address→most recent physically observed `p` ledger, taking reads/fetches before any writes at their own tick. Reverse oracle R separately parses **reversed** p STEP records, independently reconstructs p coordinates/values, indexes them by address and resolves each reader's strictly earlier predecessor using binary search. Neither uses the other's writer state. This proves only a *last physically observed p*, not universal initial-source ownership; `s`/`i`/block storage-offset instructions were also checked for original physical occurrence and none occurred.
- Site-level evidence records the signed case, trace SHA, physical tick/IP, effective coordinate, observed g value or fetched opcode, and the last signed p tick/IP/value. If no prior p exists, ownership is UNKNOWN, not inferred from a source row. The unvisited original y1881 site and all modified-run properties remain UNKNOWN.

## Measured results (signed original, finite)

| Gate | Actual result |
| --- | ---: |
| Original signed HALT receipts | 200/200 |
| Original contiguous physical STEPs | 3,628,390 |
| Physically executed p | 14,820 |
| Physically executed g | 27,395 |
| Forward-address vs independent stack-pop address oracle | 42,215/42,215 |
| Chronological vs reverse last-p predecessor oracle (27,395 g + 140 selected fetches) | 27,535/27,535 |
| Original g reads with an earlier physical p | 27,395/27,395 |
| Values returned by g disagreeing with earlier p | 0 |
| Original observed fetches at (1500,1860) | 140 |
| Original observed fetches at (1500,1881) | 0 |
| Original p/g operand underflow sites | 0 |
| Original p with **float** value recorded in physical pre-stack | 361 |
| Executed original `{`, `}`, `s`, `i` | 0 |
| Untouched distinct original signed-case positive controls | 12 |
| Genuine signed BN no-numeric-effect control rows / cases | 24 / 6 |
| Detached hostile original-receipt/trace/source modifications rejected | 16/16 |
| Synthetic LIFO underflow controls | 8/8 |

### Two concretely observed original writer→reader chains

In each of the 140 original paths that visited the selected sites, `g` at physical IP `(377,1240)` read effective coordinate `(79,1710)` with physical result `30111343`; the nearest earlier recorded `p` at `(860,1142)` supplied the same value. At `(1500,1860)` the physically fetched original opcode was ASCII `62` (`>`), and the nearest earlier recorded `p` at `(96,480)` wrote value `62` to that address. These are finite **original path** witnesses, not a changed-branch experiment. The selected JSONL evidence preserves signed case/tick-level provenance.

The trace includes 361 signed original `p` values represented as JSON floating-point numbers (e.g. `1.7014118346046923e+38`); all actual p/g coordinate operands were integers. Converting such large *values* to integers would invent a different byte/number provenance, so these observed numeric values were preserved exactly as parsed. No unsound claim about idealized integer-only Befunge behaviour is made.

## Evidence and acceptance boundary

Package includes Python 3.11+ auditor (standard library, optional `orjson` accelerator), manifest, full 200-case summaries, 280 selected signed site witnesses, untouched/hostile control logs, and the exact stdout. Every output file has an entry in the package's SHA-256 manifest, and the ZIP passes CRC. The five original source ZIPs are **not** repackaged or modified.

**No global Stage1 acceptance.** The proof is finite original Native provenance, not a fresh Native trial or CI. It does not establish altered-run route/IP, storage offsets, modified FungeSpace, actual branch reachability, source-byte rehash, changed-run stack/output, or FULL_FUNCTIONAL_QA_PASS / GEOMETRIC_SPAGHETTI_QA_PASS. No main, merge, protected branch, production code, workflow dispatch or Stage2 changes are authorized or performed.

**NEXT QA31BX (QA-only, no Native/CI repeat):** Fetch the full *original* source Git blob by immutable blob ID, independently verify its Git object SHA-1 and size, then compare static bytes at the 140 observed `(1500,1860)` fetches and the unvisited `(1500,1881)` original coordinate against physical last-p-writer evidence. Report source-vs-dynamic provenance separately and maintain `UNKNOWN` for changed-run reachability and stack/output. Reject at least 12 detached corruptions and retain 12 original signed controls. If a new Native experiment becomes justifiable, require a distinct source-bound intervention and separate acceptance gate, not a synthetic extrapolation.
