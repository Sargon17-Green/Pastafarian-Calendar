# Stage04 Rust direct-symbol source-only classifier — bounded hardening QA (2026-11-21)

Project: PC-BRANCH-RUST-AZERBAIJANI; authorized branch: `Rust+Azərbaycan-dili`.
Verified parent HEAD: `176f412de339abae807b304e4a8baead65e6c68f`; exact source blob before patch `393e38474d13046eea44981b32fa8d056bbef9d8`; exact tests blob `2537580557dbea9f037a10a812108fdfc9b50f67`.

## Reproducible static false positives (not historic runtime RED)
- A valid 33-hash Rust raw literal with a quotation mark and an entire fake `pub fn day(&BigInt)->BigInt` line inside string content: old source-only filter accepts; candidate masks all of it.
- A `#[cfg(any())]` immediately preceding a well-formed direct function signature: old source-only filter accepts despite the attribute disabling compilation; candidate rejects.
- A `cr#"... "#` C raw literal with a forged signature: old source filter accepts; candidate masks it.
- Nested `macro_rules!` declarations remain a negative static control. Ordinary top-level Rust `pub fn` remains a positive static control.

## Contract and scope
Input: source text plus the target symbol name. Output: `supported_signature(...)` boolean, a conservative *preliminary* source filter only.
- Mask Rust raw string contents through 255 hash markers, including byte/C raw variants; preserve newline offsets.
- Reject eligibility if the candidate is immediately attached to any outer attribute, or when an inner crate attribute precedes it: source-only inspection cannot prove conditional expansion.
- Preserve plain top-level direct declarations; do not treat re-exports, nested modules or literal contents as direct definitions.
- Accepting a source filter result cannot assert Rust Native, numeric day-tag semantics or observed historical RED. Only a pinned, compiled, invoked function with provenance can establish runtime callability.

## Verification limits and gates
The regression inputs were evaluated in an isolated local reconstruction of the existing parser and corrected parser before any repository mutation; these checks are Python static logic, **not compiled Rust**. Production implementation and existing `CallabilityTests` receive in-place fixes/negative controls without increasing their test-method count (19 existing tests). CI on the exact resulting commit, decoded checkout/job logs, and artifact verification must be evaluated separately after push. Historic production `src/lib.rs` remains unmodified. Stage04 stays OPEN/NOT_CLAIMED; CURRENT_STAGE=4 and LAST_COMPLETED_STAGE=3. No historical Rust numeric RED is asserted.

No merge/main, Stage05, publication or user-execution cleanup.
