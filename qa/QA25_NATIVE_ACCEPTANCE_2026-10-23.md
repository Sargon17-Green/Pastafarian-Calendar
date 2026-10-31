# QA25 — Native original source-byte ownership, finite 24-input acceptance

**PASS (finite original-source ownership only). Stage 1 is not accepted.**

## Accepted original GitHub evidence
- Workflow: [39930780869](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39930780869) — `SUCCESS`; **5/5 jobs**, four original 6-input PyFunge-98 Native shards and separate independent aggregate.
- Exact tested workflow commit: `21e9d78b3f9836b419f2d0ce50907326ab05804b`.
- Four Native shard ZIPs were independently downloaded and checked with SHA-256 and ZIP CRC:
  - Shard 0 artifact `12490929126`, SHA-256 `3f31b743b2c1db2290288331cf95654979d2113535e68f1b910c2bc5629d35bc`.
  - Shard 1 artifact `12490568959`, SHA-256 `dbdb8a775937d512a2ffdaa6a2a946f4fcfd6a9bdde36a6d2b3114ad0c613198`.
  - Shard 2 artifact `12491512291`, SHA-256 `d337301e6bdd27a9da98c8662fa277b6111cd75c274dbf7a5764b028e8b6232a`.
  - Shard 3 artifact `12491486514`, SHA-256 `eea75355ecbd4509d481398ad6c9ffc004e11dddaadfea3e208ef2a3e25dff6a`.
- Independent aggregate artifact `12492276024`, ZIP SHA-256 `1aa74e3a3da2267594a62a76db4cb65f29fae0e559232926c6c8c147f0de0f97`, ZIP CRC PASS; raw aggregate JSON independently checked.
- Separate external reanalysis of all 24 original Native receipts and 776,706 compressed physical steps agrees with GitHub aggregate; receipt JSON SHA-256 `f8f7e9d72c9cfe3c039503c41b3638c657bd7ad2b3b10e854bac2ee4261f1828`. External analysis is additional verification, **not** substituted for successful GitHub CI.

## Verified narrow finite measurements
| Measure | Original Native evidence |
| --- | ---: |
| Actual unchanged input-origin programs freshly replayed | 24 |
| Valid / invalid inputs | 16 / 8 |
| Entire original QA24 physical STEP stream re-executed and compared | 776,706 steps |
| Real executed `FungeSpace.put` calls seen | 3,319 |
| `FungeSpace.put` calls targeting any original 21 source cells | 0 |
| Fetches of 21 candidate source coordinates | 24 |
| Fetched candidate original opcodes (outside stringmode, no prior physical `put` to that cell) | 4 distinct coordinates |
| Original newly reached source cells from previously unseen 15 | 0 |
| Forged candidate-source-ownership receipts rejected | 32 (8 per Native shard) |

Original byte-owned executable coordinates in this QA24 corpus are `(10,44)`, `(179,44)`, `(235,11)`, and `(396,17)`. All were known from QA20. The remaining **15 original source opcodes stay unobserved, not dead-code-certified**.

## Historical failure and exact infrastructure recovery
Previous QA25 run `39915235834` produced 4/4 green Native source shards, but the aggregate work failed before audit during GitHub artifact download: `HTTP 503 Egress is over the account limit`. It was not a negative Native result and did not close QA25. Commit `21e9d78b3f9836b419f2d0ce50907326ab05804b` changed only the **per-shard artifact-download retry/backoff**, without altering Native programs, acceptance thresholds, historical evidence, or independent verifiers. The later CI run `39930780869` completed all 5 jobs.

## Non-inferences and governance
This is **finite actual Native observed put-to-fetch provenance**, not a global proof that no alternate mutation mechanism exists. Its byte ownership conclusion is limited to the observed original 24 executions and the audited `FungeSpace.put` API. It does not certify all possible inputs, unobserved 15 cells, numeric necessity, full state isolation, unrestricted spaghetti geometry, or Stage 1 completion.

Original production Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`, unchanged. Do not edit `main`, canonical `Befunge+Кыргызча`, historical QA10–QA24 evidence, merge PR #17, or open Stage 2.

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`; `FULL_FUNCTIONAL_QA_PASS=NO`; `GEOMETRIC_SPAGHETTI_QA_PASS=NO`.
