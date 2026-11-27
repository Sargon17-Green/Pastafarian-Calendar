# Stage10 / DISCOVERY05 — final acceptance after Stage04 regression repair

PROJECT_ID=PC-BRANCH-RUST-AZERBAIJANI
BRANCH=Rust+Azərbaycan-dili
STAGE10_CLOSURE=ACCEPTED
CURRENT_STAGE=10
LAST_COMPLETED_STAGE=10
STAGE11=NOT_STARTED
PATCH05=NOT_STARTED
FULL_CALENDAR=BOOTSTRAP_ONLY

## Evidence and scope

The prior exact code SHA 3f5c7e756709085057d08035696f5d35f7bb4f8b passed Stage10 Native run 45949515073/job 140341856756 (49 passed, 0 failed), strict expected RED exit 101, independent raw replay 35/35 (30 RED, 5 MATCH), physical slots 8/8 and Stage05–09 regression oracles. Artifact 15175619477: 55197 bytes, SHA256 fb074de203b48180413a8313df980b58d300bbb442afe9d2621f5d3a157c788a, CRC 14/14, exact identity and exit 0. These prior verified observations are retained in audit/STAGE_10_DISCOVERY05_NATIVE_EVIDENCE_AND_STAGE04_DEPTH_2026-11-27.md. Git compare proves that the only intervening changes were the Stage04 checkout depth (100 to 256) and that audit file; no production, test or oracle code changed.

Exact regression SHA d4166fd01ae13da9fce35ec7a55ad7778a7572af, Stage04 run 45950455454/job 140344832548 completed/success with all steps successful, including provenance, callability, Native regression, direct runtime differential, approved reconstruction and whole-stage consistency. Canonical Names Lock run 45950455399/job 140344832420 completed/success with exact checkout and successful verification. Stage04 artifact 15176224392: 69051 bytes, independently computed SHA256 353fe7f33ace6e021a66bb41d1d9d3e63c1764d19acfc446e57d8ebfc9e11970 matches GitHub and upload log; CRC 21/21; exit 0; exact PROJECT_ID and SHA. Pinned historical source commit 716e5a6f335b1a15464029b446edb468f3a8482c src/lib.rs blob 8a813ba020c9101276007148c93cb00ae7836644 independently confirmed via GitHub. Provenance 16 PASS; callability 19 PASS (synthetic positive only). Historical pre-Stage03 Rust runtime RED remains NOT_PROVEN.

Independent Python replay of downloaded TSV and direct-runtime report: all 15 rows matched day offset d=day+15055671, legacy=2*abs(d), corrected=2*abs(d)+(d>=0), candidate and classifications; 8 RED, 7 CONTROL, 0 unexpected, patch/candidate 15/15. Archived Python blob SHA1 independently recomputed 405f461b2e2cdd170ded010e6f8046b78d6b4ab6. Approved reconstruction report records static admission and 128 verified observations (64 before, 64 on/after foundation), not newly re-executed independently here. Whole-stage candidate confirms Stage04 accepted with 15 original and 128 reconstructed rows; historical gate unchanged.

Stage10 is accepted from prior exact semantic evidence plus repaired regression on unchanged code. The state-only acceptance commit is not itself claimed to have passed fresh CI until its automatic runs complete. No PATCH05, Stage11, main, merge, release or duplicate dispatch.
