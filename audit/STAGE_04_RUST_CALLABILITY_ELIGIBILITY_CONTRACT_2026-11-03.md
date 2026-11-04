# Stage04 bounded CALLABILITY-ELIGIBILITY gate — 2026-11-03

PROJECT_ID: PC-BRANCH-RUST-AZERBAIJANI
Branch: Rust+Azərbaycan-dili
Historical pin: Stage3 closure 716e5a6f335b1a15464029b446edb468f3a8482c, src/lib.rs blob 8a813ba020c9101276007148c93cb00ae7836644
First Stage4 introduction: 2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f
Status: CURRENT_STAGE=4 / LAST_COMPLETED_STAGE=3 / Stage04 OPEN / BootstrapOnly

## Contract

Input: an exact pre-Stage4 Rust production source commit, path, blob, Stage3
closure, Stage4 introduction, actual checkout HEAD and a direct Rust symbol
path. First pass is the existing strict ancestry/blob/real-checkout provenance
gate; it is not replaced or weakened. The second gate conservatively accepts
a direct exported function with signature fn(&BigInt)->BigInt in the pinned
Rust source file. The path must map directly to the selected Rust module;
no test/support file, post-Stage4 implementation or foreign branch is eligible.

A compatible historical Rust symbol is *compiled and executed*, not just
searched by regex. A temporary read-only git archive of the exact historical
revision is built, and a test-only external harness binds the original function
to fn(&BigInt)->BigInt. Three input values F-1, F, F+1
(F=-15,055,671) are invoked and their actual results captured, without
comparing to an oracle at this stage. No production source is rewritten.
The archive is bounded to 8 MB; native execution to 300 seconds.
No witness is fabricated. An unsupported signature returns SOURCE_ONLY,
which makes no global absence claim. Infrastructure/build failures return
RUNTIME_UNVERIFIED, *not* SOURCE_ONLY and *not* a historical RED.

Output JSON includes source_pin_eligible, callable_numeric_function_verified,
callable_day_tag_route_verified, callability_status, observed_runtime_red=false
and stage04_closure=NOT_CLAIMED;
actual numeric outputs appear only when a historical function was executed.
Execution of a typed numeric symbol establishes *only* numeric-function
callability (`callable_numeric_function_verified=true`), never by itself
that the symbol implements production day-tag semantics. Accordingly,
`callable_day_tag_route_verified` remains false until an independent,
source-pinned semantic route proof is provided; the current CLI does not
make that proof. A synthetic +7 function must not be labeled a day-tag route.
Exit 0: source-only or executable eligibility decided. Exit 2: rejected pin.
Exit 3: runtime not verified. Only an independent normative comparison to
a genuinely executed old Rust production route can subsequently support a
historical RED; a synthetic example or foreign Python route never qualifies.

## Current repository result and controls

The pinned Stage3 lib.rs exports calendar_date_spaghetti but its source
returns Err(BootstrapOnly), and it is NOT a fn(&BigInt)->BigInt day-tag
callable. The current historical source check therefore expects
SOURCE_ONLY_NO_SUPPORTED_SIGNATURE, callable=false, RED=false,
closure=NOT_CLAIMED. This is not a universal absence theorem.

Nine isolated synthetic-history checks cover one **native Rust executed**
positive (outputs -15055665, -15055664, -15055663 from a synthetic +7
numeric probe; callable_numeric_function_verified=true but
callable_day_tag_route_verified=false, no RED claim), source-only negative, wrong/private signature,
module/path mismatch, symbol injection, wrong blob, post-Stage4 source,
stale checkout HEAD and typed test harness binding. These fixture tests
are deliberately independent of the Rust production implementation.

Local Python validation prior to repository commit was 7 passes and one
skipped cargo-dependent positive on an environment without cargo, using a
functionally equivalent prototype. The GitHub nine-test CI gate must pass
with **no skips**, and the actual Stage3 JSON verdict must match before
any Native acceptance is credited. Stage1–3 regression, existing Stage04
34 Native tests, 15 direct Python/Rust cases and Names Lock remain separate.
No Stage05, no main/merge, no Stage04 PASS is claimed by creating the gate.

NEXT after completed CI: review exact SHA and logs; if passed, retain Stage04
OPEN pending any genuine pinned pre-Stage4 callable Rust source and observed
numeric mismatch against independent normative oracle. Do not repeat
previously exhausted Rust history/source searches without new evidence.
