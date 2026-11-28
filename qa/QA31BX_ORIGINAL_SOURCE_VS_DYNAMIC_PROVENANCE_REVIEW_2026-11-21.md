# QA31BX — original Git source vs dynamic instruction provenance

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Entry HEAD (verified by GitHub branch API):** `75f2dab496ab41769281ab5dbc4d4ee0e8e2a0ed`  
**Disposition:** **QA31BX finite original-only QA PASS** (dual-source evidence); **Stage1 OPEN**. No new Native/CI; no main/production/Stage2/merge.

## Immutable full original source check — distinct from signed receipts

Fetched full original blob from GitHub by *immutable Git blob object SHA-1* `560d6aa5807a7f766213a33835cce85eab0fa40c`. An independently written, pure-JavaScript SHA-1 over the canonical Git object (`b"blob " + decimal byte count + NUL + full original source bytes`) returned **exactly** the requested object ID. Independent algorithm sanity check: SHA-1(`abc`) = `a9993e364706816aba3e25717850c26c9cd0d89d`. Source length **1,836,425 bytes**, all ASCII, 2,016 `split('\n')` entries, terminal LF, no CRLF.

0-based line/column source-byte checks (source-only, *not* runtime observations):

| Coordinate | Original line length | Immutable static byte |
|---|---:|---:|
| `(1500,1860)` | 1531 | **ASCII 32** (space) |
| `(1500,1881)` | 1501 | **ASCII 46** (`.`) |

The original full 1.8 MB blob was **not copied into the offline evidence package**. GitHub blob retrieval/re-hash and local raw-signed-trace audit were separate tool-backed steps. The local Python checker can repeat the Git object SHA/size and byte checks only when provided full original bytes via `--original-source`; without that option, it explicitly labels these two source-byte assertions as a previously independently verified source attestation, *not* a fresh local blob rehash. The signed receipts' `source_blob` fields alone would not establish the contents.

## Independent local QA31BX audit of existing original signed Native traces

Inputs (untouched): `/Befunge_QA_Artifacts/QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip` SHA-256 `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`, nested AH SHA-256 `4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271`, Y `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`, eight pinned QA31V shards; and `/Befunge_QA_Artifacts/QA31BW_BEFUNGE98_KYRGYZ_EFFECTIVE_ADDRESS_20261121.zip` SHA-256 `a9e76afb498ab922fb5086254edf9b59c96ada07ead73ba5f1ee37726c847628`.

For both ZIP trees: verify SHA-256, ZIP CRC, internal manifests and physical original compressed STEP SHA. For all 200 native-original receipts, independently parse every original STEP and verify contiguous tick, IP/next continuity, raw-stdin SHA, HALT status and pinned source id. Reconstruct last physical `p` writer from each *original* `pre` stack without using QA31BW's reported owner. Compare exact writer tick/IP/value and observed reader IP/tick/value against each of the existing 280 QA31BW signed site witnesses. Do not claim that this is a fresh independent Native implementation or proof of altered-run behaviour.

| Gate | Actual result |
|---|---:|
| Original HALT receipts with pinned compressed traces | **200/200** |
| Independently parsed original physical STEP records | **3,628,390** |
| `(1500,1860)` fetch witnesses re-derived and matched | **140/140** |
| `(377,1240)` `g(79,1710)` independent control witnesses matched | **140/140** |
| At observed `(1500,1860)`: original source byte 32 vs dynamic `>` opcode byte 62 | **140/140** |
| Each `>` was preceded by physical `p` of value 62; writer evidence matched tick/IP/value | **140/140** |
| Observed fetches at `(1500,1881)` | **0** |
| Physically observed `p` writes to `(1500,1881)` | **0** |
| Original physically executed `i`, `s`, `{`, `}` | **0** |
| Distinct untouched signed-original controls | **12/12** |
| Detached source/receipt corruptions rejected | **14/14** |
| Detached focused witness/owner corruptions rejected | **13/13** |

Thus this original signed corpus exhibits **actual code mutation** at `(1500,1860)`: the original space byte was replaced by the previously physically executed `p` value 62 before the observed opcode fetch. This is compatible with Befunge-98's self-modifying FungeSpace semantics, and cannot by itself identify a conversion error. The last physical writer of each selected original fetch was at IP `(96,480)`; each witness records its independent tick and byte, not a simulated overwrite.

At unvisited `(1500,1881)`, the *immutable* source has byte `.` (46), and there were no physically observed original `p` writes or execution at that coordinate in the 200 traces. That is **not** evidence that some changed input reaches it, nor an observed dynamic opcode there. As in QA31BW, storage offset was recorded zero at observed original sites; it must **not** be extrapolated to altered runs. Any statement about changed-run source, target accessibility, IP, stack or output remains **UNKNOWN**.

## Methodology boundary and limitations

- The SHA-1 algorithm check is a **source-integrity** check. Git SHA-1 is content-addressed identity, not a claim about collision resistance against a sophisticated adversary; supplementary SHA-256 provenance is available for archive bytes.
- The rewalk reads historical signed traces; it does not re-execute Befunge-98, re-run CI, or perform differential verification against a new interpreter. QA31BW owner evidence was independently recomputed for the two target sites, but no full modified-branch runtime oracle was run.
- The detached negative controls are local modifications of copies and expected rejections of the QA checker, **not** new Native red outcomes.
- Runtime behaviour under unobserved inputs, relocated storage offsets, modified source, altered-path control flow, stack and output is **UNKNOWN**. `FULL_FUNCTIONAL_QA_PASS`, `GEOMETRIC_SPAGHETTI_QA_PASS`, and whole Stage1 acceptance are **not established**.

## NEXT — QA31BY (QA-only, no new stage)

Form an independent, bounded *source-to-path* reachability contract for the path leading toward `(1500,1881)`, with a concrete input/intervention hypothesis and explicit distinction between static source, physically written FungeSpace, stack and storage offset. Require (a) a deterministic input and full original-source SHA/size; (b) exhaustive predecessor/next-IP analysis **within declared bounds** rather than assumed global reachability; (c) at least twelve untouched original signed controls and twelve detached negative controls; (d) separate acceptance for any *future* changed-run Native experiment. If there is no justified input hypothesis or separate authorization, leave changed-run evidence UNKNOWN. Do not repeat existing CI/Native without a new specific hypothesis. No main/merge/production/Stage2 changes.
