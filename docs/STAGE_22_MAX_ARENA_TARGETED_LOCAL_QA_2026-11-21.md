# Stage22 maximum-arena targeted local QA — Perl+國語 (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU  
Authorized branch: Perl+國語  
Source-locked accepted producer commit: e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a  
Producer path: lib/Pastafari/Monster/WeavingPrimitive.pm  
Exact producer Git blob: 4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6  
Parent docs/QA HEAD before this targeted work: 310542213d18683c0f22283baab19b1654d039d7  
Independent reproducer: qa/perl-guoyu/stage22_max_arena_forward_oracle.cpp  
Reproducer exact Git blob: 993fd19509f970f4467eece681cc017e3d831959  
QA source commit: f81c62e39c5fbfb23c1b462fa1a8c578975c695f  
Scope: **maintenance of already-accepted Stage22**; no Stage23, no producer edit, no main/merge/release.

## Why this run was new

Post-acceptance exact static capacity analysis identified the largest legally permitted packed arena at 12 months and 52 days, profile:

    [3,4,4,5,5,5,5,5,5,4,4,3]

This has 4,021,367 potential memo states (129,186,415 raw packed-arena-plus-bitset bytes); accepted 13x4 has only 3,587,219 states. This witness had NOT been covered by the previous accepted Native job. All runs below used this **new** profile and source-locked Perl producer; no Catalan13 or accepted 13x4 rerun.

## Contract and evidence

Input: exact 12/52 profile above, ordinal 1, the ceiling midpoint 107296436795007023076004180014935, and last ordinal.  
Output: exact count, length-52 lexical words, inverse rank values.  
Oracle: independently written C++17 Boost fixed 256-bit integer *forward* transfer DP; an independent reverse suffix-count traversal validates numerical lexical ranks. The C++ source neither includes nor invokes the Perl producer. It was also checked against separate brute-force controls: [2,2]→2; [2,2,2]→5; [3,2,3]→19; [1,2,1]→1.  
Limits: 120 seconds, VSZ <=393216 KiB **per process**; record command exit, wall seconds, GNU time max RSS, stdout, stderr. Platform Linux x86-64; local Perl v5.40.1. Independent C++ compile: g++ -std=c++17 -O2 -Wall -Wextra -Werror.

**Exact full-count result, identical in Perl and independent C++:**

    214592873590014046152008360029870

| Check | Exit | Wall seconds | Peak RSS (KiB) | Evidence |
|---|---:|---:|---:|---|
| Perl count | 0 | 44.01 | 136960 | identical to independent forward-count oracle; stderr empty |
| C++ forward count | 0 | 0.83 | 215200 | 4,021,366 processed nonterminal states; 33,497,104 forward edges |
| Perl unrank first | 0 | 40.56 | 136960 | 52 labels; independently verified lexical rank=1 |
| Perl unrank midpoint | 0 | 41.78 | 136960 | independent lexical rank=107296436795007023076004180014935 |
| Perl unrank last | 0 | 42.27 | 136960 | independent lexical rank=214592873590014046152008360029870 |
| Perl rank first word | 0 | 0.16 | 136832 | returns 1 |
| Perl rank midpoint word | 0 | 39.87 | 136960 | returns midpoint |
| Perl rank last word | 0 | 40.86 | 136960 | returns exact full count |
| C++ lex first | 0 | 1.33 | 215288 | valid word, independent ordinal 1 |
| C++ lex midpoint | 0 | 1.62 | 215284 | valid word, independent ordinal midpoint |
| C++ lex last | 0 | 1.47 | 215288 | valid word, independent ordinal full count |

All **final** Perl processes returned exit 0 with empty stderr. All three C++ lexical checks returned exit 0; their stderr contained only the measured state/edge diagnostic. Both independent numeric and lexical oracles agree with Perl results. All final processes remained within both per-process resource limits.

QA harness correction: the first C++ lexical verification attempt retained both large forward and reverse arrays concurrently and hit std::bad_alloc within the 384MiB process cap. The independent oracle was corrected to release the forward array before allocating the reverse array; the final exact source (blob above) passed all three lexical checks. This was an oracle-harness allocation issue, **not** a demonstrated producer error.

Independent oracle local source SHA256: 7b3b6d37a714cc98169a89a002e49ff3e7f3daba2a1de17c02b874b019052ae7. Portable Linux reproduction bundle with raw stdout/stderr/time/exit evidence and exact accepted producer snapshot: Perl_Guoyu_Stage22_MaxArena_QA_20261121.zip, ZIP SHA256 e7bdd68f7352e76337b21e57835a59ec6e47326ac2621c36b1f8e2db313c857b. The bundle is retained as a conversation artifact, not a GitHub Actions artifact.

## Gate classification

- **Production code change:** none; Git blob remains exactly 4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6.
- **Local source-locked targeted QA:** PASS on the 12/52 maximum-arena witness (resource, count, 3 rank/unrank inverses, independent lexical/numeric checks).
- **New GitHub CI / Native:** NOT EXECUTED for this new witness; no new canonical acceptance claim.
- **Previously accepted Stage22 Native:** remains the *earlier* source e28e6186, canonical push run 44904659215, job 136847546239, artifact 14708038426, SHA256 ddef2e09f29b460ad4e5ddf8de4f9bd74b79e2befbd1a83f37dfa388c3de66d8. That prior run covered 13x4, not this new maximal-arena profile.
- **Overall stage:** Stage22 already accepted; full-year calendar **not verified**. No Stage23 authorization was inferred.

## Next independent authorized step

If platform-level confirmation of the newly covered 12/52 resource extreme is needed, create one isolated **source-locked Stage22-only** Native CI job for this exact witness with per-process time/VSZ/RSS logs and artifact, without dispatching the previously accepted Catalan13/13x4 suite. Review completed job+log+source SHA+artifact before granting the *new witness* a Native designation. Do not conflate this local QA with canonical CI.
