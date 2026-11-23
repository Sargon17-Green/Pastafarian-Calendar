# SQL Tamil Slice25 — independent fixed-year gate diagnostic (2026-11-23)
PROJECT_ID: PC-BRANCH-SQL-TAMIL
Branch: SQL+தமிழ்
Verified pre-change HEAD: 7a4dcefd919ce1c463f5157e1a5736f9b7852a7d
Scope: QA only; NO production, main, merge, release, or full 56-case rerun.

## Reason and immutable oracle
Original 44928511225/job136919794548 PG17.12 completed/failure: the 720-second statement expired after find_target_year alone used 694470.435ms, later in negative_gate_gap. Original ZIP #14718837632 SHA/CRC previously verified. Rerunning calendar_date without isolating year navigation would not diagnose the gap scan.

Independent archived year record from original PG17 run 44701320191/job136170134637, source-locked JSONL 152 (blob 6df7a01df2e96289aeac9aa26746e25443068ece): year_rec=(4996,-38,-29,-15074038,-15070673). Independently locked 29-golden JSONL 151 (blob 21f38cd280498070b08b6c3074780f1742c36957) has actual first/middle/last. Middle five-field expected: (4996,வெண்கலம்,302,தவளை,50). These values are input and assertion only; this test does not call the independent five-field oracle.

## Reproducible gate
The new test 177 invokes unchanged production negative_gate_gap directly exactly once per index -38..-30 (offset=-index), partitioned into three separate PostgreSQL statements with 60s timeout EACH. The nine integer gaps must lie [42,963], and must sum to the independently locked close-open=3365. Temporary SQL objects only; per-step ENTER/EXIT and elapsed_ms, segment status, final aggregate, exit code, exact production hashes and PG17.12 version are archived.

The scoped GitHub workflow locks production 13/27 Git blobs and 151/152 independent fixture blobs; it validates 29 goldens, eight year records, fixed 4996 record and explicit three segments before Native execution. It loads unchanged sql/00..27, runs no calendar_date/find_target_year, preserves failed-job logs, and uploads original SHA manifests. No dispatch of accepted one-stone or full matrix. Expected Native completion is UNKNOWN until completed job logs and original artifact ZIP SHA/CRC are inspected.

Native gap PASS does NOT imply full five-field oracle PASS, source equivalence PASS or full Slice25 acceptance. No user execution requested; no Pending_User_Execution cleanup.
