# QA31AV — post-EOF original signed q/m gate and last-writer audit (2026-11-07)

**Project:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Frozen production Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Entering HEAD:** `35be44889d19b9d707d71d0063afcd948cad4b67`  
**Immutable original QA31AI 200-case ZIP SHA256:** `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`.

## Source gate theorem, conditional on exact unmodified original ray

The exact original-source row y=29 x=10..89 (80 bytes, 73 physical
nonspace opcodes), source byte slice SHA256
`a9d50261deb05722aa7a465f1dda6790a475816400a593e86bb9d27a6908a64d`,
reads m=(3,49) at g(57,29), constructs 61*m with original source
arithmetic, and executes j(89,29). For any original integer m,
**the local ray's jump operand is 61*m**.

The exact original-source row y=32 x=10..113 (104 bytes, 97
nonspace opcodes), source slice SHA256
`570dc07da27206e51eab0548078c10e21a1f54633e62040df5b4cd6a588eb61b`,
reads q=(1,49) at g(57,32), performs a source comparison,
and executes j(113,32) with **61*int(q>3)**.
Both literal slices and all nine key `g/j/p` opcode locations were
independently read from the frozen Git blob, with exact byte equality
to the original-source pins. These are **local source-conditional**
equations, not global proof against alternate IP ingress,
self-modification, or unseen natural input stack states.

## Real signed original full-corpus evidence

Two independently implemented Python source/receipt auditors reread
the same eight **original signed QA31V source shards**, all 200 original
raw stdin SHA256, gzip STEP SHA256 and HALT receipts; checked all
**3,628,390** contiguous STEP and next→IP transitions, with
the two gate-ray source opcode / full pre/post-stack transitions
for **140*73+100*97 = 19,920** physical original-source
instructions. No new Native runner execution occurred.

Of 200 frozen cases, exactly 140 physically reached EOF and then
source x(73,6)→(10,29). Other 60 HALT before EOF. Original
post-EOF branch results:

| Post-EOF input population | Cases | m at g(57,29) | j(89,29) | q at g(57,32) | j(113,32) |
|---|---:|---:|---:|---:|---:|
| m=1, proceeds to row32 | 100 | 1 | 61 | 3 | 0 |
| m=0, does not reach row32 | 40 | 0 | 0 | not reached | not reached |
| No original EOF | 60 | no post-EOF read | no post-EOF gate | no post-EOF read | no post-EOF gate |

These are **physical original IP and actual signed stack/value
events**, not modeled counter values.

All **580** post-EOF original `g` reads of q/m agree with the
exact signed last `p` writer (IP, value and STEP), in two separate
full-trace scans:
- m g(57,29) =1 in 100 cases, last writer p(248,14);
- m g(57,29) =0 in 40 cases, last writer p(344,26);
- q g(57,32) =3 in 100 cases, last writer p(248,26);
- q g(127,35) and g(199,35)=3 in 100 cases each, same last owner;
- q g(57,38)=4 in all 140 cases, BUT with **two distinct owner routes**:
  100 were updated to 4 **after EOF** by p(248,35),
  40 had been written to 4 **before EOF** by p(248,26).

The 100 post-EOF p(248,35) actual q writes occur **after** the
physical row32 q=3 gate in those cases. Do **not** infer an open
q>3 gate from the later row38 q=4 observation.

There are exactly **2,920 signed original p writes** to q/m across
the full corpus and exactly six observed canonical source sites:

| Original writer | Destination | Physical signed puts |
|---|---|---:|
| p(106,2) | q=(1,49) | 200 |
| p(202,2) | m=(3,49) | 200 |
| p(248,14) | m=(3,49) | 1,060 |
| p(248,26) | q=(1,49) | 680 |
| p(344,26) | m=(3,49) | 680 |
| p(248,35) | q=(1,49) | 100 |

Additionally, the **11 previously identified conditional outer-p
sites actually execute a total of 1,710 p writes AFTER EOF**
in the same 140 signed cases. None of those 1,710 physical p
events targeted (1,49) or (3,49). The visits are REAL, but their
observed stack/addresses do not constitute a natural-input witness
for targeting either counter.

## Independent tests and evidence distribution

The first auditor performs exact original source byte→stack
replay for both gate rays. The second **does not import the first**
and uses a separate symbolic AST oracle, independently reads all
eight original shard SHA256 manifests and all 200 gzip receipts,
derives the exact signed last-writer map, and checks the complete
200-case event-level forward ledger. It rejects **22/22** intentionally
corrupted synthetic reports. A synthetic mutant is not a fresh
original Native trace.

Read-only QA31AV standalone evidence archive:
`QA31AV_BEFUNGE98_KYRGYZ_ORIGINAL_200_POST_EOF_COUNTER_AUDIT_20261107.zip`.
SHA256 `7efd888ed86751749499ebf8c835e4a5cdd7257ac9fc96463cd86c4219a9e862`;
71,139 bytes, **11 ZIP members CRC PASS and 10/10 independently
recomputed member SHA256 manifest checks**. It includes both complete
reproducible Python source auditors, exact original-source pin
fixture, full per-case original signed event ledger, a CSV of counter
values and last writers, summary JSON and actual logs. The
original 46MB QA31AI signed archive is required for rerun and is
not copied into this artifact.

**Delivery note:** a sandbox copy was verified in the current
conversation. Attempted mirror upload to the persistent ChatGPT
Library `/Befunge_QA_Artifacts/` failed with
`container_session_expired`; this report therefore does NOT
claim that the QA31AV ZIP has been mirrored successfully. The
archive's SHA256 and original 200-case ledger remain verifiable
from the sandbox artifact and the pinned original SHA.

## Status / NEXT

**QA31AV finite signed original 200-case gate/owner PASS only**.
Stage1 global/functional/geometric **OPEN**. No independently
verified concrete new natural stdin that writes to either counter
from a newly discovered conditional p site. Alternate IP paths
and future self-modification remain UNKNOWN. **No new Native,
no new full-corpus CI, no production edits, no main/merge/Stage2.**

**QA31AW:** Focus on the **40 cases where q=4 is already present
before EOF** (owner p(248,26), m=0 later at g(57,29)), versus
the 100 cases where q=3 at row32 and the q=4 update occurs
only after the closed q>3 gate. Source-pin original
p(248,26), m writer p(344,26)/p(248,14), and preceding byte
classification path; seek a concrete independently grounded
natural stdin producing **m=1 AND q>3 at the row32 gate**.
Do not infer a genuine candidate from a constructed stack.
No new Native without independently checked original natural
stdin and <=25,000 STEPs/case. Preserve Stage1 OPEN.
