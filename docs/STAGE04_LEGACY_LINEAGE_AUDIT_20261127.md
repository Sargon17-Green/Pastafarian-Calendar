# Stage 04 — FOUNDATION_DAY_TAG: legacy lineage audit (option A)

PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Branch: Object-Pascal+Português
Audited HEAD: bd5fef99e907a4c6e4fc3bb43fc7f0bad4adcf6d
Audited tree: 83fd28be3afd3b714a7a4430f5feb1a4e300a93f
Date: 2026-11-27
User decision: continue searching for a distinct real live legacy path; do not change acceptance policy.

## Evidence and method

The branch ref and unprotected state were read from GitHub. Recursive tree enumeration at the exact HEAD returned truncated=false. The entire production source inventory is:
- src/BigInt.pas 6f7333e514a0dc2d6af0f0cbaaade230f372f189 (generic arithmetic)
- src/MonsterBootstrap.pas 766d22f199e57b0fcd1928dea182f72adc019d1a (context clone, lifecycle, dispatch, metrics)
- src/PastafariCalendar.pas bdc5baa8fafb4886ac7a72e9169b1c33b5094eb3 (bootstrap and context wrapper)
- src/SourceLanguageCatalog.pas 2804f0a0b445d538682d3c519a81a567e8258d64 (names only)
- src/Stage02WorkCounts.pas 88da645965a0898a5217718582dc829e04afff2c (single tag formula)

All five files were read. Call graph:
ComputeWorkCountsDecimal -> ParseCanonicalDay -> ComputeWorkCounts -> CountForDay (twice).
WorkCountsForContext -> ComputeWorkCounts -> CountForDay (twice).
BootstrapProbe -> ExecuteBootstrap -> DispatchBootstrap (no tag computation).
Direct CountForDay calls use the same implementation. The two public wrappers are not distinct legacy formulas.

test/NormativeOracle.pas cccddafdf05bc2eb409b060e6f873331b9e24d49 has an explicit equality branch in DayCount and calls it from WorkCounts; it is a test-only unit, not a production path. The test calendar oracle also remains under test/. No production unit imports either oracle. No test oracle will be relabelled as legacy.

## Historical inventory

- 52d36b0079b3b48c1bd297abae1c7ad04347d8c0: Object Pascal bootstrap. Recursive tree (not truncated) had only BigInt, MonsterBootstrap, PastafariCalendar, SourceLanguageCatalog under src/. The commit explicitly states no future legacy paths or patches were introduced. PastafariCalendar blob 26d724397daf131bc320e13d72214ea13dd19059 exposes BootstrapProbe only.
- f97f7f161927cb8043765ba79997966e0a7d066a: pre-WorkCounts tree (not truncated), same four source paths, same PastafariCalendar and MonsterBootstrap blobs. No production day tag implementation.
- dd3e5f2b84e16c5232ad42d0486e9642622564dc: first and only path-history entry for src/Stage02WorkCounts.pas. The introduced CountForDay is already normative: before F, 2*(F-d); at and after F, 2*(d-F)+1, F=-15055671.
- 18f9650c27593ccd99b4a2b9b22ca9df8477b918: added context wrapper; calls ComputeWorkCounts, no independent formula.

GET commits scoped to src at audited HEAD returned 16 entries (page size 100); nine belong to the Object Pascal lineage starting at 52d36b00. The seven older entries precede that bootstrap, including unrelated Assembly/Coptic history, and are not a live Object Pascal path. They were not imported or treated as legacy evidence. All eight post-bootstrap source-changing commit diffs were fetched:
- e46cbb3dcee1b6e7f6316ddb115814b9b8054c8d, 43e80adf72418dd9a3a1e4cbf429281aaa56d105: catalog only.
- 453e3614f28e9ce2158582a17277ae7ee12f34f9, 0ba86bfa969863f404fec60c881bff0e73911c72: generic BigInt changes, no distinct tag formula.
- dd3e5f2b84e16c5232ad42d0486e9642622564dc, 18f9650c27593ccd99b4a2b9b22ca9df8477b918: implementation and wrapper described above.
- a2c8c8fa3fb0605fef07d3f9c945548d7becd02b, 43add99d816cc0a8b5feb17df3e76935957e5a90: BigSave changes, no distinct tag formula.

The compare from bootstrap 52d36b00 to HEAD reports ahead by 67 total commits, no removed/renamed source file, only one new source unit (Stage02WorkCounts) and modifications to BigInt, PastafariCalendar and SourceLanguageCatalog. Path history for MonsterBootstrap and NormativeOracle each contains the bootstrap only; PastafariCalendar contains the bootstrap and the wrapper commit.

## Conclusion and unchanged gate

The pinned plan at 0c2bad7393f4d66b77f884520f8ab6f5025feedd explicitly requires EXPECTED_RED_AND_LIVE_LEGACY_PATH for Stage04 and LEGACY_RETAINED_AND_FULL_REGRESSION_GREEN for Stage05.
No distinct real live legacy tag path was identified in the audited Object Pascal lineage. This is a bounded source/history audit, not proof that every arbitrary-precision input is correct, and not a Native or differential run. No compiler was available in the preparation container. Prior accepted Native results have not been repeated or reclassified. No EXPECTED_RED, production patch, acceptance or policy change.

Stage04 NOT ACCEPTED; Stage05 NOT STARTED. Next: locate additional concrete Object Pascal legacy source or known discrepancy if it exists outside the audited lineage; absent that, the unchanged gate cannot be satisfied by this evidence. Do not manufacture a legacy defect or import another branch's implementation.
