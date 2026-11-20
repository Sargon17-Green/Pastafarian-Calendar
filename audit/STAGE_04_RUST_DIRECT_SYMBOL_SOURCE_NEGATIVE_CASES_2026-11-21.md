# Rust Azerbaijani Stage04 — direct-symbol source qualification negative-case patch

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Parent branch HEAD: `f7414dd1c1753987b21af67693ba791a774d5212`
Branch: `Rust+Azərbaycan-dili`
Stage: CURRENT_STAGE=4; LAST_COMPLETED_STAGE=3; Stage04 remains OPEN / NOT_CLAIMED.

## Reproduced issue (static, pre-patch; not a historical Rust RED)
The previous `supported_signature` regex accepted `pub fn day(d: &BigInt) -> BigInt` when it occurred in a block comment, or inside `mod actual { ... }`. A synthetic `pub use actual::day;` at file scope means a crate may expose the symbol while the claimed file does not directly define it. Thus source signature presence and compiled symbol binding could refer to different definitions. Old regex: true in both bounded local counterexamples; candidate lexical/scope gate: false in both. **No Cargo or rustc was available locally; no Native result is asserted for this reproduction.**

## Contract and correction
- Input: pinned Rust source, requested direct function name and already checked source-path/symbol mapping.
- Output: source-only eligible only if a direct file-scope `pub fn name(d: &BigInt) -> BigInt { ... }` definition is visible after masking comments, ordinary/raw strings and char literals. It must have a body, not a semicolon.
- Negative or indeterminate cases (comment, raw string, nested module/impl, re-export-only, unterminated string/comment): false, then `SOURCE_ONLY_NO_SUPPORTED_SIGNATURE`, not a RED verdict.
- A positive lexical result **still requires** the existing separate Cargo build and native invocation to assert numeric callability. It cannot itself prove a day-tag route, semantic mismatch or Stage04 acceptance.
- This deliberately conservative source filter may reject legal Rust signatures with unsupported syntax. Such cases remain unverified, not historically absent.
- Three additional focused Python tests (16->19) exercise comment/literal forgery, re-export/nested scope, and valid direct top-level witness. Workflow expected count updated to 19. Pre-patch local static reproduction and candidate controls: 11/11 plus 2 old-vs-new counterexamples; not Native/CI.

## Pending exact-SHA validation
Run the existing branch-triggered Stage04 workflow and Names Lock on the resulting source/test SHA, check completed runs, jobs, checkout logs, 19/19 callability controls and the other original gates before claiming CI or Native PASS. Do not repeat accepted previous-SHA work manually. No changes to historical Rust production, main, Stage05, or acceptance policy.
