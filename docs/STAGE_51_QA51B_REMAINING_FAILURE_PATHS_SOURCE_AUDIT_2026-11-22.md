# QA51-B — Remaining failure paths: exact-source safe-seam audit (2026-11-22)

Project: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`; authorized branch: `COBOL+简体中文`.
Audited source HEAD: `b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc` (branch and commit checked before this document-only update).
Evidence class: SOURCE-LEVEL FEASIBILITY REVIEW ONLY. No new COBOL test, simulated fault, CI run, Native PASS, differential PASS, or stage acceptance is claimed by this document. Stage52 is not opened.

## Verified baseline; preserve its original scope

- Exact source CI: [run 44954071859](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954071859), completed/success; REST jobs page=1, per_page=100: total_count=52, 52 returned, 52 completed/success.
- Strict Stage51 Native: job `136998174720`, completed/success, GnuCOBOL `-Werror`; log `STAGE51_RUNS=00025`, `STAGE51_PASS=00025`, `STAGE51_UNEXPECTED_FAILURES=00000`, `STAGE51_TO_TEXT_OVERFLOW_REJECTS=00001`, `STAGE51_TO_TEXT_OVERFLOW_GATE=PASS`, INIT 75, TO-TEXT 50, FREE-A 50, invalid sign 25; final measured HEAP-LIVE zero.
- [Artifact 14726943612](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954071859/artifacts/14726943612) name `cobol-stage51-five-live-same-sign-cancellation-evidence`, GitHub digest `sha256:18e59a466c2d89cdf61bc7cfa4a3a4027ed1136bd8814dd530cb6615de7c06c0` (matching prior independently recorded ZIP SHA/CRC and embedded identity inspection). This review did not download and rehash the ZIP.
- Historical Stage51 formal acceptance remains separate from later QA51-B witnesses. Neither a documentation-only HEAD nor these scoped witnesses reaccepts the whole stage.

## ABI and reachable-control-flow review

Only these same-HEAD source blobs were examined:
- [`src/monster_distance.cob`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc/src/monster_distance.cob), blob `100c52e9c459c1ea1a1cfa291b459fe55da4f583` (dispatcher / sign / occupied checks).
- [`src/patched_distance.cob`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc/src/patched_distance.cob), blob `4e8412030716debca481306ba28be805ade76326`, lines 57–134. It calls `SUB`, `INIT-TEXT` of fixed literal `"1"`, and `ADD`, then `FREE-A` on local diff/one and on output only after a nonzero service status.
- [`src/big_integer.cob`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/b10ccbe1dd2df691c9c4f73839d0f5f9c47894fc/src/big_integer.cob), blob `982c1f266a18c2bcaba79b994177a93750f27bfa`, lines 198–455, 510–635, 875–1050, 1710–1937. `BIG-INTEGER-SERVICE` accepts nine BY REFERENCE operands, no fault-injection or allocator-control argument.

| Uncovered target | Source evidence | Safe deterministic witness using existing legal ABI? | Scope conclusion |
| --- | --- | --- | --- |
| Allocation denial / partially allocated temporary chain | `PREPEND-CHUNK-R` at 955, `APPEND-CHUNK-R` at 975, and further `ALLOCATE NODE-N` sites; direct allocation with no user-supplied failure knob | **No verified one.** Legal decimal input cannot guarantee a particular allocator failure, and resource exhaustion could terminate the runtime rather than return a stable COBOL status. | NOT DEMONSTRATED; no inferred status or cleanup proof |
| Valid-owner `FREE-A` failure | Dispatch 442–448 invokes `LOAD-A-H1`, unregistration and `FREE-H1`. Valid owner generally follows normal release. Existing 50/50 rejection checks target independent invalid NULL-head scratch descriptors, not a valid owner failing in mid-free. | **No verified one.** Descriptor tampering/aliased or dangling live pointers violates ownership or risks invalid dereference/free. | Valid-owner FREE failure NOT DEMONSTRATED |
| `HEAP-LIVE` service failure | Dispatch 234–235 unconditionally copies `BI-LIVE-ALLOCATIONS` to `LK-TEXT-LEN` after initial `LK-STATUS=0` (line 201). | **No**, this operation has no service failure branch or injection argument in the audited source. | A correct heap measurement (including observed zero) is not evidence that a HEAP-LIVE failure was handled |
| `PATCHED-DISTANCE` cleanup after subordinate failure | Lines 76–134: SUB / fixed one INIT / ADD; records service error, performs two temp frees, then frees result on failure. Initial occupied-result and invalid-sign rejects return before those calls. | **No verified one** under valid independent owners/inputs: direct validation failures in test code do not reach the internal calls; no seam to force the subordinate call failure during valid computation. | Internal cleanup-on-error NOT DYNAMICALLY EXERCISED |

## Safety rejection rules and independent oracle

Acceptable experiment inputs have valid separately owned decimal C/T values, an initially zero/NULL result, and no alias between live owners and scratch descriptors. Preserve exact descriptor contents and independently serializable values; compare `HEAP-LIVE` to a pre-probe baseline and require final zero after *valid* release. A safe negative witness must have a reachable, deterministic precondition **at the production service call site** and an exact expected status from the source ABI, never merely `status != 0`.

The reviewed ABI does not meet that precondition for the four targets above. In particular:
- Never corrupt or forge `HEAD`/`TAIL`, change `CHUNKS` on a live owner, free an aliased pointer, alter `BI-LIVE-ALLOCATIONS`, or deliberately exhaust process memory.
- Never replace a production call with a mock or treat a standalone direct-service rejection as a `PATCHED-DISTANCE` internal failure.
- Do not claim an observed implementation bug merely from a branch that has not been dynamically reached.
- No synthetic expected-red, fabricated status, CI or Native pass is legitimate here.

## Decision boundary / next admissible work

**Source-audit result:** `NO_SAFE_DETERMINISTIC_UNALIASED_FAILURE_SEAM_VERIFIED` for these remaining QA51-B paths on this exact source. The authorized safe test-only investigation has reached its limit. Do not add a fake witness, Stage52, or change production/main/merge/release.

Next action requires an explicit project decision:
1. **Close QA51-B coverage review with explicit uncovered paths**, retaining all existing Stage51 acceptance and narrower successful QA evidence, with no claim of failure-path acceptance; **or**
2. **Authorize a separately reviewed, test-build-only deterministic failure-injection interface** to the real subordinate operations, with precise call-index, allocation/failure status and cleanup contract to be designed *before implementation*. This changes the previously accepted constraints; no such interface exists or is authorized by this audit.

No new workflow dispatch is justified by a documentation-only audit. If a future change is authorized, it must be independently code-reviewed and gated by exact commit, successful completed CI, Native log, and verified artifact. The current review does not require local-user execution or deletion of any pending package.
