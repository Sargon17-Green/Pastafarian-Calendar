# Stage23 allocated malformed Native independent review — 2026-11-28

Project PC-BRANCH-FALSE-ARABIC. Original push run located via repository Actions runs GET filtered by exact head_sha (not PR-only lookup). Run 46128444907, job 140928147071 completed success, source fa548e8c7d9f6a24506c60ff3834fc3c27057f01, original runtime eb3135565a8670cced3f6bbca4dbf7b014c45634. Artifact 15256802059, 296150 bytes, SHA256 67bdda60e9d6798537ba5d0cb478775fe7b77c03e6a1a91e983efe7517773599 matches local bytes, GitHub metadata and upload log. 191 unique ZIP entries, CRC PASS.

Independent offline Python audit executed without importing the CI runner: reconstructed signed radix-512 values, classified malformed raw witnesses using sign/length/digit/canonical-zero/top/signed-range predicates, independently encoded valid counterpart -15055671 and generated both eleven-cell padded records plus offsets 0/11 and argument pointer 22. Exact combined program bytes matched all 24 artifacts plus abort preflight. Checked all 25 per-case receipts against summary, exit code 1, exact stdout, source-bound divide-by-zero stderr line/column/excerpt/caret and unique marker token, timing RSS and recorded caps (600s, 2GiB). 75 program/output hashes + 7 source SHA256; seven Git blob hashes matched live source tree de93d60f78d3097683edfad9c63bfc5a7631d909. Max recorded elapsed 0.003s, RSS 2000 KiB. All 24 passed independently: SIGN 4, LENGTH 4, DIGIT 4, ZERO 4, TOP 2, RANGE 6.

Git blobs:
- src/bigint.false 1e8de1147ba46cd0eb75a47f24673bbd9783946f
- src/monster_bootstrap.false f3e51dabc3c4afc95ad75ea79c572f5024f75a38
- tools/stage23_measure.py d1c0958e4b717c960c234817922b26df66d7f032
- tools/stage23_malformed_native.py 549bd5a564839ec8a9cb4860e909c97692ce0e87
- .github/workflows/false-arabic-stage23-malformed.yml 285c0d8285baf170f78a83ab38879918934b3514
- RUN_STAGE23.md 57cd52a53e24394d574adce09719ac11857fef31
- evidence/stage23_signed64_independent_review_2026-11-28.md 0e4aa785f947e9ca56b79514d10141b628974ff4

MALFORMED_ALLOCATED_NATIVE_PASS only. No physical invalid pointer/truncation claim. No new Native replay or mutants; Stage23 NOT_ACCEPTED. No production change or duplicate dispatch. Next: bounded replay/interleaving and numerical mutant fixtures under original caps as specified in stage23_malformed_static_and_replay_design_2026-11-28.md; retained-heap double-full call unassessed.
