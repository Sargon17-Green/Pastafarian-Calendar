# Stage04 — canonical history-boundary pin hardening (2026-11-20)

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
BRANCH: Rust+Azərbaycan-dili
PARENT_HEAD: c989cae12b2aa483a44392f5742bff21276e2f6f
CURRENT_STAGE=4
LAST_COMPLETED_STAGE=3
STAGE04_CLOSURE=NOT_CLAIMED

## Reproduced validation flaw

The pre-patch `verify_pin` accepted caller-provided `stage3_closure` and `stage4_introduction` values after checking only their relative ancestry, the witness blob and current HEAD. A bounded local synthetic Git-history reproduction demonstrated that an actual post-Stage04 source with correct current HEAD and blob was rejected using the real synthetic boundaries, but accepted (`source_pin_eligible=true`) when later commits were passed as forged stage boundaries. The reproduced flaw affects source eligibility, **not** proof of an observed historical Rust numeric mismatch.

## Patch contract

The provenance gate now requires exact canonical boundaries:
- Stage03 closure `716e5a6f335b1a15464029b446edb468f3a8482c`
- Stage04 introduction `2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f`

The prior ancestry, blob, current checkout, Rust-path and native-callability checks remain intact. Existing synthetic-history test suites explicitly patch *only their test fixture* boundary constants; production CLI parameters cannot replace canonical identities. A new negative regression exercises post-Stage04 source + forged later stage checkpoints and requires rejection. The workflow's provenance unit-count gate is updated 13→14; the 16 callability controls remain unchanged. No production Rust source was modified.

Local bounded reproducer before patch (faithful transcription of source gate):
- Real synthetic boundaries: `REJECT`.
- Forged later synthetic boundaries: `source_pin_eligible=true` (undesired).

Local candidate check with immutable anchors:
- Real synthetic boundaries: `REJECT`.
- Forged later synthetic boundaries: `REJECT`.

These local checks are synthetic Python/Git gate reproductions, **not** the repository CI, not a Rust Native run, and not a historical numerical RED. Exact new-SHA test counts and status must be established separately from completed CI/log evidence. Do not attribute prior green runs to the patched SHA. Continue to require an independently verified pre-Stage04 production Rust day-tag callable and observed numeric RED before any Stage04 PASS or Stage05 progression.
