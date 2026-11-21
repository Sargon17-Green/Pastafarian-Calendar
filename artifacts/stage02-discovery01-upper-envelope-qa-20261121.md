# Stage02 DISCOVERY01 — upper-domain envelope and remaining evidence audit (2026-11-21)

Project: PC-BRANCH-WAT-SPANISH. Authorized branch: WAT+Español.
Scope: targeted QA on the existing DISCOVERY01 contract, not a new stage or a claim of global Stage02 acceptance.

## Immutable identities and already accepted evidence

- Branch baseline before this QA: ac3668f3c9bba41a041f85356f0865cd0884d495, verified identical with the live branch (ahead=0, behind=0).
- Locked WAT source: 871f9b70216c16c57abcd552ec6fb0ed1010e305; Git blob e23f013ab96b498b0ac365dbb1b25273c845e790; SHA-256 18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980.
- Existing completed CI run 44923220858: canonical job 136903552858 SUCCESS, Node semantic job 136903553082 SUCCESS (111/111 and 83 BigInt checks), WasmKit job 136903553258 SUCCESS on the locked source. Logs and job statuses inspected in this audit. Artifact 14714581950 is present with 30,745 bytes and SHA-256 51ba91e192a661947fa343125f82d7c1dd14709eef8c2863752e668d853b1bfa. ZIP content and 111 per-case logs were independently audited in the preceding QA report; this audit does NOT claim a second download or Native run.
- The six original DISCOVERY01 cases and 105 regressions remain accepted only within their documented gates. Original historical Stage02 ZIP/manifest remain UNVERIFIED; neither runtime's PASS authenticates historical delivery.

## Concrete uncovered upper-envelope assertion

The existing WAT header states that 1100 limbs of base 2^30 can handle even N = 47^5778. This is a stated stress bound in the source, NOT an independently validated legal/domain maximum. The export inventory contains exactly 111 unique parameterless i32 test exports; the highest explicitly named k-level in them is k=5. No k=253 Native evidence was established by this audit.

A separately computed exact-integer preflight for stress input N = 47^5778 gave:
- M = 2^127-1, bit length 127.
- N bit length 32095.
- Minimal k satisfying M^k >= N is 253 (M^252 < N <= M^253).
- M^253 occupies 32131 bits; M*N occupies 32222 bits; both below 1100*30 = 33000 bits.
- floor(M^253/N) has 37 bits and is strictly less than M; the precondition SPACE < M*N holds.
- The WAT memory layout declares 19 4416-byte scratch cells, 1100 30-bit limbs each, and 96 WebAssembly pages. The locked source's integer globals, cell stride, and 111-export inventory were inspected. Layout and arithmetic capacity are sufficient for the stated stress input, subject to the actual implementation following its declarations.

## Independent arithmetic witnesses (not WAT execution)

Let S = sum(j*M^j, j=0..252). Two separately formulated calculations agreed:
S = (M - 253*M^253 + 252*M^254)/(M-1)^2.

- Forward starting at 1, step +1, k=253: initial x = 1+S is below the acceptance limit. Its rank has 32012 bits and the SHA-256 of its ASCII decimal representation is 82908b318fb3f8d991bdbec92b2ac2c51f96e093b806ef979df084974f08e6a5.
- Backward starting at M, step -1: initial x = M^253-S exceeds the acceptance limit. The mathematically first accepted value is the limit and the rank equals N; SHA-256 of the ASCII decimal rank is 3b8e337f6d91ec378519cd6dcc489d920f171c13910556889b56775697d18631.

Reproducible standard-library checker: tests/stage02_wat_envelope_audit.py. It checks immutable source digests, memory/limb layout, export count, k=253 bounds, and the two independently calculated position sums. Its successful result is STATIC_NUMERIC_PASS only. It is NOT a binary WebAssembly test, a completed CI run, a differential result against WasmKit, or evidence of k=253 performance/liveness. Separate math preflight was executed successfully and py_compile passed; full script execution against the WAT inside GitHub CI remains unverified.

## Exact remaining gaps and next authorized action

1. Historical Stage02 provenance: original approved ZIP and manifest lack an authenticated file identity/hash/chain of custody. Keep this UNVERIFIED; do not substitute this generated QA evidence.
2. Upper-domain runtime: 111 accepted Native self-tests do not establish performance or return-value correctness at k=253. The new checker makes the expected forward/backward numeric witnesses reproducible without copying from another branch, but a source-fresh narrowly scoped Native test would require a separate QA plan and source-locked evidence; it has NOT been run.
3. Confirm whether N=47^5778 is actually an approved domain maximum before using it as a formal acceptance boundary. The WAT comment alone is not authoritative for that policy.

NEXT: run the new source-aware checker in a bounded QA workflow or local clone at the locked WAT SHA, verify its output and source digest; then make a narrowly scoped decision about an upper-envelope Native witness without rerunning the accepted 111 cases unnecessarily. Keep Stage02 OPEN/READY, global NOT ACCEPTED. No main/merge/release.
