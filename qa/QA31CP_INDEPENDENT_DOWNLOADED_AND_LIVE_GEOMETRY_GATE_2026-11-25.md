# QA31CP — independent downloaded receipts and remaining physical geometry gate (2026-11-25)

Scope: existing Stage 1 only; no production edits, merge or Stage 2. Live parent `ebe759782313674707bc14171cd93cedf24a180c` is three commits ahead of the register SHA `531351f5260910bfffe76d5e5eae818de0f61092`. The active work_counts source blob is `7418e1ec5fe88fe5c14b75710dea2d5607527f28`, unchanged from native run 45635056768's tested commit `e124409b2e5d8b34f08af3f7914ede29b3741054`.

## Downloaded evidence independently reviewed
Each ZIP was downloaded again from Actions, SHA-256 matched the job log and artifact metadata, and every member passed ZIP CRC. The checks below parse receipts, not a fresh interpreter replay.

| Run / job | Artifact | SHA-256 | Independent receipt check |
| --- | --- | --- | --- |
| 45556217425 / 139008784647 | 14996746545 | c120ee9fa8ffd15ccc3b11ae7119238787573efc84392688f1a423b6761ebc2f | 27 suffixes with output, digest, step and p/g parity; 538528 steps; 39 rejects with no arithmetic suffix |
| 45556217425 / 139008784311 | 14996851186 | 16a83ecc4349b7d97c8ddf2a0171c9b7db57134ffba73a15fa156b3d32830fea | 31 output receipts; 93 ordered phases; 2596 puts; 856 snapshot cells; 1395 retired-space comparisons; 45201 cell comparisons |
| 45556217425 / 139008784546 | 14996542354 | cd3258e2bb3231b92bd78edc6f52bd6cc1213675402b4318b720c61244bab133 | 9 shell results match expectations; job log 421 regression invocations and 4x25 isolation cases; stage1_accepted=false |
| 45635056768 / 139278155210 | 15030924408 | 8e3a1572686e5fd9dcbd2f7717c9590bcdd119be6c0053745e6df4b7fe157696 | 4 valid input pairs; 6 healthy crossings, 4 crossings across 2 perturbed executions; six independent synthetic receipt corruptions rejected |

All four jobs are completed/success. Reset totals were reconstructed independently as 3*sum(i) and 3*sum of each prior snapshot-size prefix, rather than trusting the summary. Each last-write value was compared with the retired snapshot. This reset evidence refers to the older interleaved_work_counts source, not the new work_counts entry point.

The digit increment oracle was independently reconstructed by repeated Euclidean divmod of both unsigned magnitudes, signs and decimal place. Each observed increment, running sum, physical fetched arrow, executed arm, final seven fields and added step count was compared. Opposite-arm interventions at the first nonzero increment change the sum by -2*z and hence each recovered signed day by -z; SAVE remains unchanged. Equal-length, equal-sign valid pairs 0 21 1 12 and 0 12 1 21 have identical original arithmetic hash and distinct active arithmetic hashes with equal total arithmetic ticks 12265. Both arms are numerical rather than a decorative detour. This is finite native evidence with independent arithmetic receipt verification, not verification of every physical IP step from the raw trace: the CP ZIP contains summary hashes and gate observations, not full traces.

## Remaining geometry gate (no new dispatch)
The current parent already adds .github/workflows/befunge-stage1-live-geometry.yml and a collector/auditor. The connector's commit-run endpoint returns only PR-triggered first-page runs: Canonical Names Lock 45639070655 success is not evidence of the new push workflow. Do not infer that it did not run. Obtain the actual run/job/log/source and geometry ZIP, check exact SHA and CRC, then perform the following *additional* checks on existing raw traces, not another sweep of the historical fifteen coordinates:

1. Bind route-08 and route-09 to the pinned work_counts source and their exact valid inputs, compare from the first fetch of (1020,1046) rather than comparing whole-input paths. For each visit, bind the previous physical p at that address to the recorded byte; verify the actual next physical coordinate is (1020,1047) for v or (1021,1046) for >. Require opposite order v/> and >/v. Check the distinct downstream arithmetic routes and common rejoin, not only a difference in hashes or scanner routes.
2. The existing geometry auditor unions all input paths when counting forks/joins. Do not use these totals alone as evidence that two valid inputs of equal length diverge inside arithmetic. Record per-input edge sets and first differing outgoing edge after the gate; separately preserve invalid-path and lexical-path counts.
3. Require final active entry-point reset/ownership and reference replay receipts from the current source distribution, including the new work_counts blob. The old reset ZIP cannot substitute. Validate the actual reference.json contents and source archive manifest before final sign-off; the geometry auditor's evaluate() currently does not consume reference.json.
4. Retain Stage1 OPEN until all these and the existing functional/architecture gates pass. No duplicate run and no historical-coordinate repetition.

This is a QA-only evidence review, not a new Native execution or a policy change.
