# Stage21 Post-Acceptance Bounded Static QA — Perl+國語 (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Reviewed branch HEAD / acceptance commit: 1d88c9d8a89d563c0f169ffc7fc648e8e9ce1259
Accepted production source: a06fb9ee6d78c47a7abb5bf10950f45d9bf518c0
Mode: **source-level static inspection and independent combinatorial range analysis only**. No new Perl/Native execution, CI dispatch, differential test, or stage acceptance is claimed.

## Exact inspected Git blobs
- `lib/Pastafari/Monster/WeavingPrimitive.pm`: `ca8180ded4d90c7f122279d16d697285a4e5d584`.
- `lib/Pastafari/Monster/MonthOccurrence.pm`: `72dfd4fc698d957a3dc0eab12eaf7f8e5a052cb5`.
- `t/68_stage21_weaving_twelve_months.t`: `245fa2ad898bba4a1925892b76c79d4e92a74e7a`.
- `t/69_stage21_mixed_profiles.t`: `4030ca3e0bf04da4eb9bdd9264ff147ef73e7a48`.
- `t/49_stage04_month_occurrence.t`: `78399f9b1c8bbd70368cca7526af21fcacc9cd1b`.

## Static QA findings

1. **Profile bounds and validation:** `_counts` requires a plain ARRAY ref, 1–12 months, ASCII positive decimal integers without leading zeroes, and an accumulated total of at most 48 days. Non-scalar month lengths, zero, negatives, decimals, and oversized values fail before solving. The public rank path rejects a non-ARRAY word and wrong total length; each label must be a valid 1-based numeric month index and a member of the current legal choices. `_rank_input` checks a 1-based positive decimal rank against the exact count.
2. **Independent numeric capacity proof:** `_solver` holds four unsigned little-endian 64-bit limbs, each normalized in base `10^12`, hence can represent nonnegative values below `10^48`. The count of legal order-constrained words cannot exceed all multiset words. For at most 12 positive classes and at most 48 symbols, the maximal multinomial bound is achieved by twelve classes of size four:
   `48!/(4!)^12 = 339917784579447928182134345929899510000000000` (45 decimal digits), strictly below `10^48`. This proves four limbs suffice for **all legal 12/48 input profiles**, not only the tested [4x12] case. Each normalized limb addition is below `2*10^12`, safely below 64-bit integer capacity. Separate integer-partition enumeration gives a maximum active mixed-radix product of `589824` (ten active lengths: two 4 and eight 5); therefore `code` and the radix index arithmetic stay below one million, with no floating-point precision dependency at this bound. These are mathematical/static bounds, **not** new runtime PASS claims.
3. **Lexical 1-based rank/unrank:** `_choices` yields numeric month indices in ascending order. `rank_weaving` starts at `Math::BigInt->bone` and adds exact counts of all preceding admissible choices; `unrank_weaving` selects the first choice whose suffix count covers the remaining 1-based rank, otherwise subtracts that count. `_next_state` consistently represents first/last occurrence order with closed/opened limits. The rank/unrank logic and the separately sorted independent byte-label oracle in t/68 are consistent on inspection.
4. **Input/output separation:** `_counts` creates fresh numeric `@lengths`; rank and unrank decrement only local `@remaining`; `_rank_input` creates a fresh `Math::BigInt`; unrank returns a fresh ARRAY ref; count returns a fresh `Math::BigInt` reconstructed from packed limbs. These paths do not write into the caller's profile, word, or rank. Accepted t/68 checks fresh output, source profile, and `Math::BigInt` rank; t/69 checks profile stability for large profiles.
5. **Independent MonthOccurrence domain:** `month_occurrence` refuses more than 9 months or more than 36 valid cumulative days *before* delegating to `unrank_weaving`; malformed lengths are delegated to the downstream validator. The 1-based date position is checked against the generated word length and converted via a fresh `Math::BigInt`; `dayInMonth` is likewise constructed afresh. Stage21's broader 12/48 primitive does **not** implicitly enlarge this projection API. t/49 independently enumerates small complete words and checks projections, invalid inputs and immutability.
6. **Non-blocking documentation drift:** The accepted production primitive still has a source comment calling it a “Stage21 candidate”; `MonthOccurrence.pm` has an older comment describing the Stage19 10/40 bound. Both are stale comments, not observed behavioral faults; this QA does not change production code or infer a failure from them.

## CI and acceptance evidence retained, not repeated
- Existing canonical run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44812489647 — metadata independently rechecked as completed/success on source a06fb9ee6d78c47a7abb5bf10950f45d9bf518c0.
- Stage21 artifact ID `14668587498` — provider digest independently rechecked: `sha256:9f1473a57a9be9a5da6ebf392b745c6b5fc57b3f449c2cedddea01f731a93c16`.
- Prior accepted evidence (22 mandatory job logs, 416904 Stage21 TAP, independent Catalan12 hashes, seven-file ZIP CRC/source/exit) remains recorded in `docs/STAGE_21_NATIVE_CI_ACCEPTANCE_2026-11-20.md`. This static QA did not redownload the ZIP or refetch all raw logs.

## Result and scope
**STATIC_QA_REVIEWED; NO PROVEN BEHAVIORAL BUG IN THE INSPECTED PATHS.** This is not an additional native PASS, CI PASS, differential PASS, or new stage acceptance. `LAST_COMPLETED_STAGE=21` remains unchanged. Full-year generator remains unverified. No Stage22, protected-branch/main modification, merge, release or publication is authorized by this report.

Next authorized work, if required: narrow Stage21 maintenance only (for example correcting stale source comments and reviewing targeted existing input guards) under a fresh branch-HEAD lease, recording any new CI as pending until completed. Opening Stage22 requires an explicit separate authorization.
