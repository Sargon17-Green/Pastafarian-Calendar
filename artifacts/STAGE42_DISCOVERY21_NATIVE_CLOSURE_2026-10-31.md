# Stage42/DISCOVERY21 — native expected-red confirmed

Date: 2026-10-31 | PROJECT_ID=PC-BRANCH-PHP-MALAY
Code SHA: c4e14f56d9021f53be572d93761541581cf55faa
GitHub Actions run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41192299864
Run: completed/success, 13/13 jobs. Native Stage42 job:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41192299864/job/124511375213
PHP 8.3.36, 64-bit. Lint PASS. controls=12, candidates=2,
reproduced=2, rejected=0, exit=0, stderr empty.
Witness A: forward_anchor_5001_as_5000 canonical_year=5001 returned_year=5000 target=-15053458
Witness B: backward_anchor_4999_as_5000 canonical_year=4999 returned_year=5000 target=-15057703
Artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41192299864/artifacts/13039146723
ZIP sha256: 6cb277b01d892fce403b532c1a837f3de9c8e10d4f8358e89704d8cc3ae68aef

This reproduces an *untrusted-anchor* boundary violation; the previous
PATCH20 API explicitly required a genuinely verified Year5000 anchor.
Stage42 is closed as a research result, not as a claim of a production
defect under its documented trusted-anchor precondition. Stage43/PATCH21
introduces an optional independent canonical-anchor provider and
fail-closed verification at the API boundary. Stage43 Native acceptance
is pending; this document does not report its result.
