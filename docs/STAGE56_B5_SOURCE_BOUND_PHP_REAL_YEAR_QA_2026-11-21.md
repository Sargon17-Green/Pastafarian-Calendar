# Stage56 B5: source-bound real PHP year QA (NOT stage acceptance)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Parent SHA: ac68044d4639bff79c07307ce25228ba641e797a
Authorized branch: PHP+Bahasa-Melayu
Date: 2026-11-21

The predecessor CI #44927905786 completed/success (30/30) at the exact parent SHA. The external-reference-differential job #136917943360 completed/success, including the independent Scroll comparison of all 27 gate positions (-12..14), six comparator regression tests and the external 271-sample semantic comparison. Artifact #14716944417 has ZIP metadata SHA256 48d83a96d03051934deec8f3d53724b3c42ba20b5f906a9c09fd469b5b2e1566. These were external QA subgates, not PHP production.

New tests/stage56_source_bound_php_year.php executes the actual opt-in PHP YearStructureProvider56, once for each year 4999, 5000 and 5001, in three isolated processes. It rejects any different canonical Git origin/HEAD, dirty canonical worktree, modified source bytes or Scroll source bytes, any mismatched pinned reference SHA256 (46b2f...), pinned gate witness SHA256 (f2d5c...), contextual calculation JDN (-13334246), mismatched Year5000 anchor, different three-year endpoints, missing 27 gate positions, missing successful independent Scroll report, wrong branch SHA, PHP month length/weave divergence, cutlet coverage violation, rank/unrank divergence, or resource excess. Candidate Year5000 and trusted anchor are cross-checked from differently materialized gate/reference records; these records are still produced by external canonical code and should NOT be mistaken for an independent PHP provenance authority. Scroll comparator is executed separately in the preceding CI step, not rederived from these PHP callbacks.

Each run is capped at 900 seconds and 512MiB, retaining stdout, stderr, exit, output JSON, source provenance and SHA256 sidecars when possible. The JSON includes PHP-owned cutlet and month structures, month differential, and count/rank/unrank profile. Any failure is a real observed failure only after the exact new SHA's CI and logs are inspected. Do not label a queued or in-progress run PASS. The full source-independent cutlet semantic oracle is not established by this change, and Stage56 remains NOT ACCEPTED pending verified completed results and any remaining gate(s). No PATCH22/PATCH23 integration, merge/main or publication.
