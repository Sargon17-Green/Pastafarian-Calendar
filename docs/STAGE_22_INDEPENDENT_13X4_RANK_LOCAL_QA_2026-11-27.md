# Stage22 independent 13x4 ordinal — local differential QA
Date: 2026-11-27
PROJECT_ID: PC-BRANCH-PERL-GUOYU
Branch: Perl+國語
Tested HEAD: a83efd98b8c34cca8fa2d1d647e8b1f0a65e6e9d

## Contract and actual evidence
The prior independent count matched the historically accepted production count. This check instead selects a new interior 1-based ordinal 12345678901234567890123456789012, distinct from first/middle/last, profile thirteen fours. Obtain a fresh production unrank word and independently validate its exact numeric lexicographic ordinal; check multiplicity, first/last order, rank/profile immutability. No standalone count or previously accepted inverse case rerun. Both exact source Git blobs verified before execution: producer 4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6; independent oracle b6f6e055c41e31be369b11fbacc33f6d0279856e. Producer reconstructed from connector text and verified by Git hash; no direct network access in local container. Oracle from prior verified local file. Perl 5.40.1 Debian 13 x86_64. Four syntax checks passed. Each heavy process bounded by timeout 120s, kill-after 5s, virtual memory 393216 KiB.

- Production unrank exit 0, stderr empty, 37.85s, max RSS 123392 KiB.
- Word (52 labels): 1,2,3,4,2,2,5,1,6,5,7,1,6,5,8,8,9,10,4,9,10,3,1,11,7,12,2,13,3,6,12,8,3,10,9,4,4,13,5,7,6,12,7,8,9,13,10,11,11,11,12,13
- Word CSV SHA256 22f625841f0a6f0b0f25a72d0cd99e0403cc4c9a111008b310f2ee2fed074abc.
- Separate direct Perl verifier exit 0, stderr empty, exactly 4 occurrences of each label and strictly increasing first/last positions. Producer harness verifies input BigInt and profile unchanged.
- Independent bottom-up binary-limb lexical oracle exit 0, 29.91s, max RSS 162640 KiB, intentional statistics stderr: profile_months=13 days=52 capacity=3587219 nonzero_states=3587218 transitions=31089292.
- Oracle stdout exact total 21604722570792867375065793772732 and lexical_ordinal=12345678901234567890123456789012. Byte-for-byte comparator exit 0; final wrapper exit 0.
- Evidence ZIP 29 members, CRC verified, SHA256 f3c4cfe403d9c7b654df58085bf93cea104c0cd016c87bd7b1afff3f739a8de5, archived at /PC-BRANCH-PERL-GUOYU_Evidence/PC_BRANCH_PERL_GUOYU_STAGE22_13X4_INDEPENDENT_RANK_20261127.zip.

## Decision
PASS local source-exact differential ordinal check, one new interior rank only. No new CI/Ubuntu Native claim; no exhaustive 13x4 rank coverage claim or full-year verification. Historical Stage22 acceptance unchanged. No producer changes, Stage23, main, merge or release.
NEXT: review the remaining authorized Stage22 mixed-profile singleton separator and rank-input boundary coverage against existing fixtures; if a distinct gap exists, design a bounded local independent test without repeating accepted cases. No stage expansion.
