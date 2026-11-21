# QA31BE — bounded original signed next-gate review (2026-11-16)

Project PC-BRANCH-BEFUNGE98-KYRGYZ. Branch qa-befunge98-stage1-order-isolation-20261008.
Parent c897bdf7195993ca091c4e0592a7a192e62d81bf. Original source blob 560d6aa5807a7f766213a33835cce85eab0fa40c.
Original QA31AI signed ZIP SHA256 9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49.
Original QA31BC ZIP SHA256 2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77.

**Physically observed in old signed 200-case traces, NOT fresh Native**: 200 HALT cases, 3,628,390 contiguous STEP records, all nested ZIP and original trace hashes verified. 365 second-hop windows (140 selector >, 225 selector v), at most 256 signed STEPs after second x per window. Gate events g=1600, p=730, x=2190, j=0. All 2190 x target vectors verified; all 1600 g last-writer lookups performed, 24 independently reverse-scanned. Fifteen of fifteen hostile non-noop derived-summary mutants rejected.

> path first gate g(1144,1620); next g(1125,1620), x(1112,1620), p(670,1598). Source-conditional third x target (670,1620).
v path first gate x(575,639); next g(1430,1149), x(1430,1183), p(1249,1050). Source-conditional third x target (1430,1145).
Observed p address targets: > (71,1708) 140, (73,1709) 140; v (37,1700) 225, (41,1701) 225.
Observed g address events: > (53,1704) 280, (59,1705) 280, (71,1708) 140; v (13,1694) 225, (17,1695) 225, (29,1698) 225, (37,1700) 225.
No observed source selector corridor p overwrite in signed finite sample, not a proof for unseen stdin.

Two independent bounded oracle classes: signed original physical trace/last-writer audit in evidence ZIP; exact source blob and source-only RPN arithmetic in GitHub with 24 synthetic nonnoop source mutations. CI checks source only, NOT 46 MB signed trace, and may not be called PASS before exact-head completion. Source-conditional and physically observed evidence are deliberately separated.

Evidence Library: /Befunge_QA_Artifacts/QA31BE_BEFUNGE98_KYRGYZ_ORIGINAL_200_NEXT_GATE_20261116.zip
SHA256 73c222bba77c4ff53dd74b2217d5a39274d9ab808bb5f2ecbcda47d947b97d0a; CRC 6/6, manifest members SHA 5/5. The original signed 46 MB archive is not duplicated in this package.

Global 57-p-site address reachability, alternate ingress, unseen stdin, and Stage1 functional/geometric/global PASS remain UNKNOWN/OPEN. New Native 0. No production/main/merge/Stage2.

NEXT QA31BF: bounded original signed owner-to-reader study of g(29,1698) and p targets (37,1700), (41,1701), with independent oracles and distinct counterfactual versus physically observed conclusions.
