# Stage22 — 13-month / 52-day discovery contract (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU  
Authorized branch: Perl+國語  
Exact discovery parent: `60f2fc024a5177532ed987f9bf45b778854d9c63`.  
The user approved opening Stage22 and expanding scope in this conversation. LAST_COMPLETED_STAGE=21; Stage22 **NOT YET ACCEPTED**.

## API and invariants

Candidate `count_weavings(profile)`, `rank_weaving(profile,word)` and `unrank_weaving(profile,rank)` accept a positive integer array of 1..13 month lengths, total 1..52 days, with existing 1-based numeric lexical rank/unrank semantics. First appearances and last appearances of labels remain ascending; profile and Math::BigInt rank inputs must not be mutated and returned words must be fresh. Return exact Math::BigInt counts and ranks.

All invalid-profile and order cases must reject cleanly, including 14 months, 53 total days, zero/negative/noninteger elements, out-of-range ranks, invalid word length or repetition. Preserve the **separate** `MonthOccurrence` domain at 9 months/36 days. Do not change canonical-name catalog, chronology, date semantics, other languages, main or release scope.

## Independent discovery oracle — completed

For a profile with 13 labels occurring twice (26 days), enumerate balanced paths: each opening creates the next new label; each closing gives the next label in finishing order. Closing before opening produces numeric lexical order. Expected Catalan(13) = binomial(26,13)/14 = **742900**.

Committed independently-written Perl oracle: `qa/perl-guoyu/stage22_independent_catalan13_oracle.pl`, syntax OK, exit=0, stderr empty, 1.75 seconds, RSS 4224KiB, bounded to 120 seconds and 393216KiB VSZ. A separate local Python dynamic-programming ballot-unrank model independently generated all ranks with the same count and SHA-256. This Python cross-check is scratch-only, not foreign source in the Perl branch.

Canonical CSV numeric lexical rows with a trailing LF have SHA-256: `67edb036b070b196c6b889b161a27baef6b0ec7852717586550ef2f8b4d7173d`. Sentinels include rank 1, middle rank 371450 and last rank 742900. Both independent methods agree. **Discovery oracle pass is not Stage22 Native acceptance.**

## Numeric capacity proof — completed

For fixed positive lengths `l_i` totaling `n`, all unconstrained multiset permutations are `n!/product(l_i!)`. The first-appearance ordering partition has exactly `m!` equipotent label relabelings, so first-ordered sequences equal `n!/(product(l_i!)*m!)`, an upper bound on accepted weaving sequences. Balance lengths to maximize this quotient (factorial exchange argument), and use `n=52`; evaluate `m=1..13`. Global upper bound `14778213400262135041705388361938994140625` = **41 decimal digits**, below the existing four base-10^12 packed limbs' 48-digit capacity.

A separate product maximization over active labels with `sum(length)<=52` gives maximum radix product **1769472**, attained at `4,4,4,5,5,5,5,5,5,5,5`. There are at most `(13+1)(13+2)/2=105` interval buckets, yielding conservative exclusive memo index bound **185794560**, below `2^28`. These small bounded integers support exact index and quotient-floor arithmetic in the documented 64-bit Perl environment.

Committed Perl capacity preflight: `qa/perl-guoyu/stage22_capacity_preflight.pl`; syntax OK, exit=0, stderr empty, 0.03s/RSS10624KiB, timeout 120s, VSZ393216KiB. Machine record: `qa/perl-guoyu/stage22_discovery_preflight_2026-11-21.json`.

## NEXT — resource feasibility and production gates

1. Create an **uncommitted temporary copy** of the exact accepted Stage21 producer module, expanding domain guards only to 13 months/52 days. Check syntax using Perl 5.40.x. Under separate 120s / 393216KiB VSZ process limits, check 13x2 independent ordinal cases and heterogeneous small profiles, then 13x4 exact count and first/middle/last rank inverses. Record exit, stderr, elapsed, RSS, source hash and numerical outputs; distinguish correctness failure from timeout/OOM. No full-year claim.
2. If the 13x4 producer candidate is resource-safe, commit the minimal correct production change with Stage22 independent TAP tests and appropriate negative fixtures, retaining the 9/36 projection rule. If not safe, investigate a new resource-efficient algorithm **without** repeated unsupported reruns.
3. Add a dedicated Stage22 canonical Native job with an exact source lock and seven-file ZIP artifact (source, Perl version, syntax stderr, test stdout/stderr/exit, result). Require all mandatory jobs completed/success, inspect raw logs, independently hash/CRC/download artifacts and check Catalan13 oracle across deterministic shards.
4. Advance `LAST_COMPLETED_STAGE` to 22 only after full source-exact Native verification. Do not dispatch duplicate runs for already queued SHA. No merge/main/release.

**Status:** STAGE22_DISCOVERY_ORACLE_PASS and STATIC_CAPACITY_PASS only. Production Stage22, Native Stage22 and Stage22 stage acceptance remain **NOT ACCEPTED**. Full-year generator remains unverified.
