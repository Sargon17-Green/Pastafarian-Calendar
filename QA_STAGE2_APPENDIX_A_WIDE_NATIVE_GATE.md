# Stage2 Appendix-A — two-digit wide-selection source and Native gate

PROJECT_ID: PC-BRANCH-LOGO-IDO
BRANCH: qa/logo-ido-stage2-wide-selection-audit-20261121
PARENT_AT_PREPARATION: 5b5ad91755a06ae986a26bff6ee7e75cb1debbdd
CANONICAL_HEAD_UNCHANGED: ad001c6aeeb6c758f5004b206a656fec5d6fc403
STATUS_AT_PREPARATION: IMPLEMENTATION_AND_GATE_PREPARED; NATIVE_NOT_YET_VERIFIED
STAGE2_ACCEPTED: NO
CANONICAL_PROMOTION: NO

## Input / output and scope

Pure Logo reporter monster.stage02.choose.wide :stream :N, used only for canonical
exact-BI stream [first,step], 1<=first<=M, step in {-1,+1}, M<N<=M^2,
M=2^127-1. Valid output: canonical exact-BI rank 1..N. Invalid bounded input:
[] (without state mutation or float conversion). This implements only the
two-digit subdomain, not arbitrary k, rank dispatch, unranking, or date output.
Internally malformed data outside the documented canonical-BI guard is excluded.

Compute successor using the already accepted bounded D20 reporter (k=1).
Initial wide value W = first + M*(successor-1). Let S=M^2, L=S-(S mod N).
If W<=L, rank=1+((W-1) mod N). If W>L, the only rejected interval is
(L,S]. A +1 cyclic walk next accepts W=1, rank=1; a -1 walk next accepts
W=L, rank=N. This leap has no rejection-gap enumeration, and all operations
use base-10000 exact BI.

## Independent oracle, matrix and evidence gates

The host QA model qa/logo_stage2_wide_selection_host_oracle.py predates
production and exhaustively walks small circles (3340 finite cases including
669 rejections); it is not production code. A separate Python integer
generator qa/logo_stage2_wide_native_vectors.py constructs 96 large-M valid
vectors (8 N values x 6 stream starts x 2 directions), including 11 rejected
initial candidates (5 positive, 6 negative); plus 16 malformed/range
guards. Total required Native = 112 cases and 400 explicit checks.
The expected rank is derived from Python integers only. The Logo reporter
must not generate expected results. The generated fixture is retained.

Native gate: pin UCBLogo version_6.2.5 at commit
a0215433f07384e4c42fe247525867f11e6f32f7, verify exact Git checkout
SHA and source blob locks, execute unmodified fixture, assert raw Native
markers, lack of failure text and zero exit status, preserve raw host/native
logs, test fixture, source SHA-256 manifest, and commit SHA as artifact.
An observed completed-success run plus job, logs, artifact and digest is
required before the bounded QA may be called ACCEPTED. A queued/in_progress
run is NOT a PASS. No automatic Stage2 acceptance and no main/merge.

## Non-destructive constraints

The canonical Logo+Ido branch and already accepted D20/D21 composition QA
branch remain untouched. Existing Stage1 / last completed stage=1 unchanged.
A source-relevant failure requires inspection before a revised attempt; do
not manually duplicate a queued workflow or rerun accepted composition.
