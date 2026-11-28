# QA31AN — physical visits and counter-address audit on 200 frozen original Native traces

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Verified starting HEAD: 6eef9188deaaba8d0697d6a5a34f8ae17855763c
Original production source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Original previously accepted input archive in ChatGPT Library:
/Befunge_QA_Artifacts/QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip
Expected exact original archive SHA256:
9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49

## Audited evidence

The existing nested QA31AI/QA31AH/QA31Y/8 QA31V archives were read,
not regenerated. Independently checked original package hash, nested
SHA256 manifests, 8 shard SHA256 hashes, all 200 gzip trace SHA256
receipts, 200 original HALT receipts, 3,628,390 contiguous STEP indices
and IP next-to-next record consistency. No new Native invocation.

Exactly 140 of 200 frozen cases executed at least one of the 10
QA31AM conditional counter-address candidate source p sites. Including
compound p(369,575), 1,710 executions were found at 11 sites. The
actual p operands (pop y,x,v, with pre[-2:] = x,y) were examined in
the original trace itself. None wrote to q=(1,49) or m=(3,49).
Counter writes from all other source sites are NOT zero: 2,920 writes
were observed at established canonical writer sites. The 200 original
traces do not prove that alternative natural inputs are impossible.

## Scripts and traceability

- qa31an_receipt_oracle.py: first independent complete SHA/receipt/full
  trace replay, segmented 0..4 and 4..8 for bounded execution. It
  stores per-case raw hexadecimal input, compressed gzip SHA256, STEP
  count and the exact candidate IP, STEP, value and target on every
  observed p event. Source package is required as a positional input.
- qa31an_scan_segmented.py: a separate raw-record extraction pass;
  result JSON files are included for comparison.
- qa31an_ledger_oracle.py: independent totals/site-target check with
  12 deliberately corrupted synthetic JSON reports rejected.
- qa31an_crosschecked_summary.json: 200-case aggregate and the frozen
  per-case source-hash/receipt provenance.
- qa31an_receipts_0_4.json and qa31an_receipts_4_8.json: 200 original
  cases and 1,710 individual source-target puts.

Rerun with Python 3 standard library:

    python qa31an_receipt_oracle.py ORIGINAL_QA31AI.zip 0 4 receipts0.json
    python qa31an_receipt_oracle.py ORIGINAL_QA31AI.zip 4 8 receipts4.json
    python qa31an_ledger_oracle.py qa31an_crosschecked_summary.json --out ledger.json

The compressed original input corpus is intentionally NOT duplicated
inside this small evidence package; use the exact pinned previously
accepted Library archive to independently redo full-trace verification.


## Independently checked original physical puts (from all 200 signed receipts)

| Original p source coordinate | Executed events | Sole observed put target (x,y) |
|---|---:|---|
| (96,480) | 140 | (1500,1860) |
| (195,958) | 140 | (61,1706) |
| (292,1430) | 140 | (3,1690) |
| (369,575) | 140 | (7,1692) |
| (384,575) | 140 | (11,1693) |
| (575,959) | 225 | (59,1705) |
| (577,1430) | 140 | (83,1711) |
| (860,99) | 225 | (53,1704) |
| (860,1142) | 140 | (79,1710) |
| (948,860) | 140 | (73,1709) |
| (1332,480) | 140 | (19,1696) |

This is **11 executed source sites**: ten QA31AM candidate sites plus compound p(369,575).
There are 1,710 observed physical p executions at those coordinates, with
zero writes to the two counter addresses (1,49) and (3,49). Separately,
2,920 original counter-address writes were observed at six earlier,
canonical p sites. The 200 signed-case corpus cannot justify a global
unreachability theorem.

## Frozen delivery and acceptance provenance

Standalone QA31AN evidence ZIP, ChatGPT Library:
/Befunge_QA_Artifacts/QA31AN_BEFUNGE98_KYRGYZ_ORIGINAL_200_SIGNED_TARGET_AUDIT_20261107.zip
ZIP SHA256: 9aebc80a4b9a1c7b8b32482ec2eaeaf0849bbaef382bfc019e5a7e5a5bfe8124
ZIP: 11 entries, CRC complete; each non-manifest member SHA256 pinned by QA31AN_MANIFEST.json.
Input QA31AI original SHA256: 9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49.
Full original QA31AI/AH/Y manifests, 8/8 original QA31V shard hashes,
200/200 per-case gzip trace hashes and HALT receipts, contiguous STEP
indexes and next→IP were checked in a separate receipt-based scan.
Raw trace data were NOT created or changed here; the original signed
input archive remains the canonical immutable source. Distinct raw-record
scanning and receipt replay agree for every case and source-target count;
independent summary oracle rejected 12/12 synthetic corruptions.

Acceptance is **QA31AN finite 200-case reanalysis** only, not new Native
execution, not a GitHub CI run, not Stage1 PASS. Reproducible Python scripts
and event-level evidence are included in the standalone ZIP. No claim is
made that a hypothetical new input could not alter the observed stacks.

NEXT QA31AO: choose a bounded source-originating predecessor / stack-production
investigation of the ten physically observed candidate sites; use raw input
receipts and original trace deltas to see whether an independent natural
input witness for put→q/m is constructible. Do not fabricate an expected-red,
run new Native without independently validated concrete input, or bypass the
25,000 STEP/case limit. Global functional/geometric Stage1 remains open.

## Scope and NEXT

QA31AN finite signed-original-corpus acceptance only. This identifies
ACTUAL visits, correcting the earlier possibility that external p
sites may never execute. The precise incoming stack at these visits
does not match any of the hypothetical q/m target witnesses.
No new natural-input candidate for q/m target was established. No
fresh Native or other user-computer execution required. Stage1 global,
functional and geometric gates remain OPEN. No main/merge/Stage2.

NEXT QA31AO: bounded original-source reverse stack/producer investigation
for a new natural input inducing q/m target from one of the 10 sites;
begin with the 200 signed raw stdin receipts and source stack deltas.
Do not infer global impossibility from finite misses; only run Native
on a concrete independently source-checked input, <=25,000 STEP/case.