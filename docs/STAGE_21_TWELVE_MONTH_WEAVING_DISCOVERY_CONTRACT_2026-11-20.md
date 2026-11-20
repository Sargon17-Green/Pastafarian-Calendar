# Stage21 Twelve-Month / 48-Day Weaving DISCOVERY (2026-11-20)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Stage20 accepted source: 01f4d16e04f2225a7861076d747a669a0f00df77
Stage20 proof: docs/STAGE_20_NATIVE_CI_ACCEPTANCE_2026-11-20.md
LAST_COMPLETED_STAGE=20; Stage21 DISCOVERY ONLY. Production not extended; Native not accepted.

## Choice and bounded contract

Following the accepted 7/28, 8/32, 9/36, 10/40 and 11/44 month/day progression, select the next prospective WeavingPrimitive boundary of 12 months and 48 days. Preserve count_weavings/rank_weaving/unrank_weaving, Math::BigInt exactness, increasing first/last occurrences, one-based numeric lexicographic ordering, fresh returned ARRAYrefs and non-mutating inputs. Reject 13 months, 49 days, invalid rank/word and malformed inputs when implemented. The separate MonthOccurrence domain remains <=9 months and <=36 days. No five-field full-year generator claim.

## Independently implemented mathematical oracle (discovery result)

Path qa/perl-guoyu/stage21_independent_catalan12_oracle.pl
Git blob f75d17e4ee42c2a06e6ae094266459c679362d20
Independent Perl code enumerates valid open/close ordinal event sequences for 12 labels of multiplicity exactly two, converts ordinal events into byte labels 1..12, explicitly sorts numeric lexical order, checks every word's multiplicities and increasing first/last positions, then hashes original CSV numeric labels with LF.

Closed-form independent count Catalan(12)=binomial(24,12)/13=208012. Perl v5.40.1 source verified by Git blob, syntax OK and 208012/208012 valid ordered words; exact SHA256 0dbe36d23b6ffaa14822b1556d3eabc777d5961bdfd2fd79be39ee2daee76bbe. An independent scratch Python enumerator (NOT committed because source-policy foreign language guard) independently reproduced the count and hash. Local bounded Perl script: exit0; 2.33 seconds; peak RSS32256 KiB with <=120s and <=393216KiB virtual memory. No production code imported or tested: this is discovery evidence only.

## NEXT: measurable bounds, oracle and Native gates

1. Verify current Perl+國語 branch HEAD and exact accepted Stage20 WeavingPrimitive Git blob. Make a SCRATCH-ONLY bounds candidate from 11/44 to 12/48, without changing MonthOccurrence.
2. Run each profile in a separate Perl5.40+ process, timeout <=120s, ulimit -v 393216KiB, and record elapsed, peak RSS, exit and stderr: [1x12] expected count1; [2x12] count208012 with independent ordinal first/middle/last expected words; [3x12] count/roundtrip; [4x12] count-only and rank1 roundtrip as two independent budgeted processes; [37,1x11] and [48] at 48 days with expected count1.
3. Treat any failure to fit [4x12] as a RESOURCE FACT only, not a fabricated algorithm bug. If the candidate fails bounds, investigate optimization or another independently measurable bounded extension without committing unsafe production limits. Any expected-red requires a minimally reproduced actual defect.
4. If resource gates pass, implement the smallest production/domain-bound patch and update only newly legal legacy negative fixtures. Build a genuinely independent oracle test: all 208012 1-based ranks and inverse words must match the standalone oracle; partition into deterministic nonoverlapping shards (initially propose sixteen shards: twelve containing 13001 ranks and four containing 13000, subject to preflight <=120s / <=393216 KiB per shard). Add small exhaustive multiset cases, invalid profiles/ranks, boundary assertions and unchanged-input checks. Do not treat large count and roundtrip alone as independent evidence.
5. Add one dedicated Stage21 Native canonical job only after local production QA. Retain the existing 21 mandatory jobs; prospective acceptance requires 22/22 completed/success on same source SHA, every raw log, Stage01 full suite, independent Stage21 shards with syntax/TAP/exit/stderr/resource evidence, GitHub/upload/download SHA256 equality, seven-file artifact CRC/source and STAGE21_NATIVE_PASS=1.
6. No duplicated CI dispatch or pre-acceptance PASS, no main/merge/release. Queued or running CI is not a blocker. Do not advance LAST_COMPLETED_STAGE until those proofs exist.

Next discovery output: verified HEAD and blob IDs, bounded per-profile resource table, the independent oracle count/hash, a decision on feasible 12/48 scope grounded in measurements, and reproducer for any real failure (or explicitly NONE).
