# Stage56 B5 — provider path parity gate (QA-only)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Base branch: PHP+Bahasa-Melayu
Audited parent SHA: 307047d97f3c5adab07c9a88e3a003d58a757bec

## Reproduced defect

The B5 PHP input validator accepted the source claim `src/../Provider.php` even though the independent Git-byte-binding Python audit explicitly rejects dot-dot components. The old PHP condition checked only nonempty provider paths, forbidden `tests/fixtures/oracle` components and SHA syntax; it did not reject traversal, backslashes, empty path segments, paths outside `src`, or incorrect file extensions. This is a structural validation mismatch, not an observed real-year profile failure.

## Change and contract

The PHP `stage56B5SafeProviderPath` check now requires a relative POSIX path under literal `src/`, at least one additional component, a lowercase `.php` suffix, no NUL or backslash, no empty/dot/dot-dot component, and no case-insensitive `tests`, `fixtures`, or `oracle` component. All remaining production-source claims and year validators remain unchanged. The input JSON remains a claim and does not authenticate provenance.

The preflight suite retains its 16 original structural cases and adds 9 path rejections: traversal, dot, empty component, absolute, outside-source, backslash, wrong suffix, mixed-case fixtures, and NUL. Expected synthetic validator total: 25; native canonical workflow sentinel also updated to 25. The CLI negative suite remains 12. No new stage or production integration.

## Evidence and limits

- Local focused PHP 8.4.24 isolated path predicate probe: 10/10 PASS; old predicate reproduced accepting `src/../Provider.php`.
- After commit, inspect the automatic canonical push run at its new exact branch SHA, plus PHP 8.3/64-bit lint, 25 validator checks, 12 CLI checks, 22 Python source-binding checks, job log and SHA-bound artifact. Queued is not PASS and do not dispatch another run.
- Exact production provider and normative Year5000 anchor have not been authenticated. No 4999/5000/5001 profiles executed, no Stage56 full acceptance, no PATCH22/PATCH23 integration, no main merge or publication.
