# Stage22 CSV post-acceptance micro-CI — verified GitHub Native QA

Date: 2026-11-23
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
SOURCE_COMMIT_LOCK: bb49201411b6397819c97e5fc2b40238251e48ce
Workflow implementation SHA: 1fce45680162643744f99d4b09dee3b1a72119b8

## Verification: completed exact-SHA run

- Canonical Names Lock automatic push workflow run: [45133678832](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45133678832), attempt 1, completed/success, head 1fce45680162643744f99d4b09dee3b1a72119b8.
- Total workflow jobs paginated (100+71): 171; exactly 1 dedicated QA job completed/success, 170 other jobs skipped. No full 12/52, 13×4, or suite replay.
- Dedicated job ID 137554747831, name "Stage22 CSV parser and small independent oracle (111 TAP)", completed/success. All job steps successful; original decoded job log independently fetched and inspected; log contained strict TAP_VERIFIED=66/66 and TAP_VERIFIED=45/45 markers.
- Perl v5.40.5, GitHub-hosted Ubuntu 24.04.
- Artifact ID 14798647702, name perl-stage22-csv-qa-source-locked, downloaded independently through GitHub API. Provider/upload/independently computed ZIP SHA256 matched: 6125942033486ade3bfec40bdf7c613d395705103f9e3351c14d5c0be78c9471. 4,434 bytes, 20 entries, ZIP CRC 20/20.
- Independently parsed artifact: 3 syntax checks exit0 with syntax OK, negative=66/66 TAP contiguous with exactly one correct marker, positive=45/45 TAP contiguous with exactly one correct marker, both test exits0/stderr 0 bytes and no "not ok". All 8 individual SHA256 manifest entries match independently recomputed hashes. Negative and positive TAP SHA256: c72e9d76f83696f279d9c0232e86816b36bb0bba4718f3f516235a2881f12e98 and a9f8b6e44d4e6b1274ca762c408d761425d1f479991192b68767197c0656bfe8.
- Exact QA Git blobs recovered from artifact source.txt:
  - b6f6e055c41e31be369b11fbacc33f6d0279856e (forward oracle)
  - b41ae40b2b04a07a6b3eb385b2f246097bb5f036 (negative CSV regression)
  - 85d055ae9dfec705105109195b8ed259c552d39c (independent positive small contract)
- Parent lease 72034f71d106a4427621af4afb114318e60fc051 enforced and observed as job success; the workflow itself is solely QA, no production modifications.

## Gate classification

- CODE: QA workflow and contract changed in 1fce45680162643744f99d4b09dee3b1a72119b8; producer/QA inputs unchanged.
- STATIC: source SHA, parent and 3 blobs verified.
- CI / GitHub-hosted Native (new, NARROW): ACCEPTED only for Stage22 CSV 66 TAP + independent small 45 TAP and syntax3.
- Differential: independent small oracle 45 TAP tested only; no new wide cross-implementation differential claim.
- Stage22 historical accepted 13/52 and isolated 12/52 runs retain prior identities only; no rerun.
- Full-year generator, Stage23, main/merge/release: NOT CLAIMED.

NEXT: No repetition of this exact-SHA CI. Future QA-only work may examine remaining distinct source-locked Stage22 parser boundary classes without changing producer or stage scope, after a new measurable contract. Do not imply full-year or a new stage acceptance.
