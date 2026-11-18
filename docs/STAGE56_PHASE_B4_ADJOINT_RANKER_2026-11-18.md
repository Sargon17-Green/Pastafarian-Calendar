# Stage56 Phase B4 — exact lexicographic rank/unrank over the B3 shared adjoint

PROJECT_ID: PC-BRANCH-PHP-MALAY  
Branch: PHP+Bahasa-Melayu  
Parent: 2f294c03645c37857b87188cd0122eef82f4316e  
Status at authoring: implementation candidate; Native acceptance pending.

## Accepted predecessor: B3

Canonical push run #44375433187 completed successfully, **30/30 jobs**, on exact SHA `2f294c03645c37857b87188cd0122eef82f4316e`. Dedicated Native job #135053247694, `stage56-weaving-adjoint-b3-native`, completed/success with PHP 8.3.36, 64-bit; five PHP lints passed; B1 counters were vectors=120, prefixes=18302, words=3940, rejected=6; B3 counters were vectors=120, prefixes=18302, branches=18182, words=3940, invalid=8, huge=1; exit=0 and empty stderr. Artifact #14463250140 contains the exact PROJECT_ID and SHA, 11 files, zero-byte stderr, and passes ZIP CRC. ZIP SHA256 is `dc7c5b12259b45e532e673a8226ff46ba9557e782f7bb60fa6ac16bdfeb1ee73`.

## B4 objective and API

Add opt-in production class `MonthWeavingRanker56`, not wired into PATCH22/PATCH23. It exposes:

- `count(counts): BigInt`
- `rank(counts, word): BigInt`, one-based lexicographic rank
- `unrank(counts, rank): list<int>`, one-based inverse

At each prefix state, call B3 `candidateBlocks(remaining, opened)` **once**. Its ascending map partitions all valid suffixes into disjoint next-ID blocks. Ranking adds the exact sizes of legal blocks with ID smaller than the requested next ID, then consumes the requested ID. Unranking subtracts preceding blocks until the remaining rank lies in one block, then consumes that ID. Induction on the remaining word length proves the two operations are mutual inverses, provided the B3 block partition is exact; B3's independent DFS microgate checks every block in 18,302 prefixes and 18,182 sibling branches.

## Complexity and explicit limit

B3 computes a full sibling map in O(mL) exact arithmetic operations for a prefix with m active families and L remaining symbols. The B4 full-word rank or unrank therefore has O(mL²) arithmetic-operation upper bound over L successive prefixes, compared with B2's O(m²L²) upper bound from recomputing B1 suffix counts separately for each candidate. This is an asymptotic factor-m improvement, **not** a state-updatable adjoint and **not** evidence that the 512MiB/900s actual-year gate is met. Compression/decompression and BigInt digit growth must be measured on actual provider output.

## Independent verification contract

Use the separately written DFS enumerator in `tests/stage56_weaving_frontier.php`, not B1/B3 recurrence internals, as the ordering oracle. Exhaust all 120 vectors with 1..4 families and 1..3 copies each, all 3,940 complete words, all 3,940 rank results and inverse unrank results; assert 83,776 total word positions processed, 360 out-of-range rank rejections, five invalid-word rejections, and two genuine BigInt boundary roundtrips for eight families with six copies each. Keep the input vectors immutable. Native acceptance requires PHP 8.3/64-bit, six syntax lints, exact counters, <=512MiB, <=900s, exit=0, empty stderr, and PROJECT_ID/SHA-bound ZIP evidence.

## Provider and actual-year dependency — not satisfied

The current branch has no production `YearStructureProvider` class. `DateTuplePatch23` accepts `yearStructureProvider` as an injected callable; `YearStructureSlices56` explicitly says it does not build year records or a weaving; `DEVELOPMENT_STAGE.md` says `STAGE55_PRODUCTION_AUTONOMOUS_YEAR_STRUCTURE=NO`. The Stage56 production-year-structure contract also says the Year5000 anchor and adjacent-year callbacks remain caller-owned dependencies. Therefore no authorized, reproducible production vectors for years 4999, 5000 and 5001 are available in this branch. Test-oracle structures and synthetic vectors are not substitutes and will not be presented as actual-year profiles.

## NEXT

1. Verify the exact-SHA B4 Native job and artifact; repair only a log-proven defect.
2. Obtain or locate the authorized production year-structure provider/anchor and its reproducible inputs for years 4999, 5000 and 5001.
3. Run exact rank/unrank profiles under 512MiB/900s on those genuine vectors. If the B3-per-prefix O(mL²) path fails, derive and independently prove a state-updatable adjoint before any PATCH22/PATCH23 integration.

No main/merge, no production provider integration, and no Stage56 overall PASS.
