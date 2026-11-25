# QA31CT — Native semantic-domain gate for the active work_counts entry point

Date: 2026-11-25  
Project: PC-BRANCH-BEFUNGE98-KYRGYZ  
Scope: Stage 1 QA only. No production-source mutation, Stage 2, merge, protected-branch write, or main change.

## Pinned inputs

- Production entry point: src/work_counts.b98, Git blob 7418e1ec5fe88fe5c14b75710dea2d5607527f28, SHA-256 a59c1066843abfde9b059e9ec62b2c9daf0483f116095bbd78c19cf28ab59137.
- Independent five-field oracle: reference/work_counts.b98, Git blob f941efc793c9eee4accf5d03873f8ed029b16725.
- Independent save oracle: reference/save.b98, Git blob 7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44.
- Native interpreter: PyFunge 0.5-rc2, tarball SHA-256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac.

## Semantic contract

QA31CS establishes the lexical envelope: exactly four ASCII decimal tokens, separated by one or more ASCII space, tab, CR, or LF bytes; optional leading/trailing such whitespace; EOF is a valid terminator. This test uses canonical single-space/LF encodings so it isolates semantic validity from lexical behavior.

Let the four parsed fields be (signC, magnitudeC, signT, magnitudeT):

1. signC and signT must each be exactly 0 or 1.
2. A sign of 1 requires its corresponding magnitude to be strictly positive. Thus (1,0) is invalid negative zero; (0,0) is valid.
3. Magnitudes are arbitrary nonnegative integers. There is no 2^127−1 input ceiling. 2^127−1 is the output modulus, not a bound on the decimal input fields.
4. Every semantically invalid input must terminate normally and emit exactly seven -1 fields.
5. Every valid control must emit exactly seven fields and match the independent Native oracle: five fields from reference/work_counts.b98, plus one field from each of two separate reference/save.b98 invocations.

## Test matrix

Six malformed-by-semantics but lexically valid streams:

| Case | Input | Reason |
|---|---|---|
| signC-two | 2 1 0 1 | First sign outside {0,1} |
| signC-nine | 9 123 0 1 | First sign outside {0,1} |
| signT-two | 0 1 2 1 | Second sign outside {0,1} |
| signT-nine | 0 1 9 123 | Second sign outside {0,1} |
| negative-zero-C | 1 0 0 1 | Negative zero in first pair |
| negative-zero-T | 0 1 1 0 | Negative zero in second pair |

Eight valid controls include zero, both sign directions, the calendar boundary, 2^127−1, 2^127, and 2^128. The values above the modulus are deliberately positive controls: they test the unbounded nonnegative input domain rather than assuming a signed-128 input cap.

## Acceptance

- All three pinned Git blobs and SHA-256 values match.
- All six invalid semantic streams return exactly ["-1"] * 7.
- All eight valid streams return exactly seven fields and match the independent Native oracle.
- The Native job is completed/success on the exact pushed SHA; its log, JSON receipt, artifact digest, downloaded ZIP SHA-256, and ZIP CRC are independently checked.
- This is a focused semantic-domain gate, not full Stage 1 acceptance.

## Execution

Workflow: .github/workflows/befunge-qa31ct-work-counts-semantic-domain.yml.  
Runner: qa/qa31ct_work_counts_semantic_domain.py.
