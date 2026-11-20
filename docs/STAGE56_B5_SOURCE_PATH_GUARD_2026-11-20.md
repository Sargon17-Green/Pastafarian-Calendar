# Stage56 B5 — source-directory bypass QA and patch (2026-11-20)

PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Base SHA: e211e27b09e7eab3dd476c55a9f126605e68f91c
Scope: source-binding audit only; no year-generator behavior change.

## Reproducible issue
At the base SHA, `safe_path()` rejected `tests` only as the *first* directory and checked `fixtures`/`oracle` case-sensitively. A source path such as `src/tests/YearStructureProvider.php` or `src/FiXtUrEs/YearStructureProvider.php` therefore passed the standalone path filter. A `canonical/TESTS/year5000_anchor.json` anchor path passed too. This was reproduced in an isolated execution of the exact prior path predicate. These are logical input-validation bypasses; there is **no evidence that such paths were used in production**. The wider audit still checks source claims, committed Git blobs, independent pins and active checkout bytes.

## Minimal patch and measurable QA contract
Reject any case-folded component matching `tests`, `fixtures`, or `oracle` in provider and anchor paths. Keep all existing path, Git-object, source-commit, working-tree-byte and out-of-band SHA checks unchanged.

Add three direct `safe_path` expected-rejection tests for the paths above. Existing synthetic positive and negative cases remain unchanged. Expected isolated audit self-test:
- POSIX: **22/22** (19 prior + 3 new)
- Windows: **20/20** (17 prior + 3 new; POSIX-only symlinks omitted)
- CI: Python compilation, zero exit and stderr, exact sentinel, and existing PHP8.3/64bit B5 gates (3 lints, 16 structural, 12 CLI negative). Verify only using a completed CI run on the new exact SHA.

## Strict limits
This patch **does not** establish an authentic production `YearStructureProvider`, canonical Year5000 anchor, SHA-pinned genuine-year 4999/5000/5001 exports, or actual-year performance. A path filter cannot prove canonical provenance. Do not claim Stage56 acceptance or merge to main. Next: inspect the automatic push CI evidence and independent authoritative source material before any 900s/512M actual-year profiles.
