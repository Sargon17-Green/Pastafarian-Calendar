# Stage2 D20/D21 bounded composition QA — Logo+Ido

PROJECT_ID: PC-BRANCH-LOGO-IDO
SOURCE_BRANCH: Logo+Ido
CANONICAL_SOURCE_SHA: ad001c6aeeb6c758f5004b206a656fec5d6fc403
QA_ONLY: YES
STAGE2_ACCEPTED: NO

## Engineering gap and scope

D20 `monster.stage02.answer.at(stream,k)` is accepted only for integer k=0..31.
D21 `monster.stage02.choose.short(stream,N)` is accepted for canonical exact
BI N in [1,M], M=2^127-1. Their isolated acceptance does not establish
that they agree on the same stream and the *first accepted* value.

This QA uses **synthetic, structurally valid ASK streams**, not a D19 sauce
integration path; it does not implement calendarDateSpaghetti, a calendar
quintet, wide choice, unranking, or another development stage.

## Independent oracle and finite matrix

The QA-only Python generator directly steps Python integers x forward/backward,
wrapping explicitly at 1 and M. It admits a fixture only when the first x<=L
occurs at k<=31, where L=floor(M/N)*N. The expected rank is computed from
the Python walker-selected value, not from either Logo production reporter.
The bounded native matrix has:
- 150 valid first-accepted cases, including 36 with k>0 and 6 with k=31.
- Four shared invalid stream cases.
- 1,094 exact Logo assertions on shapes, values, ranks, determinism,
  acceptance limit, predecessor rejection where k>0, and invalid rejection.
- Eighteen candidates excluded because the first acceptance exceeds D20's
  contract bound. These are not failures; the already-accepted unrestricted
  D21 gate covers long gaps separately.

## Required evidence before QA acceptance

This isolated QA branch receives one naturally triggered GitHub Actions
workflow. Gate requires the precise checkout SHA; four production Git blob
source locks; host oracle markers; the actual pinned UCBLogo 6.2.5 interpreter
at upstream a0215433f07384e4c42fe247525867f11e6f32f7; 480-second Native
process bound; genuine Native markers of 154 cases / 1094 checks / PASS;
absence of failure/error messages; completed-success run/job and a retained
artifact with generated fixtures and raw host/Native logs.

The Python generator, static verification, or workflow configuration alone
does **not** constitute Native PASS. No acceptance claim is made for Stage2,
D19 end-to-end integration or the final calendar result.

## Next action

Inspect the exact-SHA run, job, raw logs, and artifact; correct a proven
QA defect on this QA branch only if needed. Then inspect the remaining
Appendix-A downstream selection/unranking requirements without introducing
a new stage or modifying main or the canonical Logo+Ido HEAD.
