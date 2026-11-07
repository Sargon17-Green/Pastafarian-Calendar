# QA31X — finite original-Native pairwise first divergence (2026-11-04)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`
Branch: `qa-befunge98-stage1-order-isolation-20261008`
Starting HEAD verified: `4a0c294a0976a8c8b088cacf1722a180282a994c`
Original production source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`
Original signed Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481

## Permanent reproducible artifact

[QA31X Python standard-library analyzer + original QA31W corpus + all pair witnesses, summary CSV, SHA256 manifest and reproducible log (Drive)](https://drive.google.com/file/d/1j0YOlNY56_9P0IwgaIZCMp3gW1CMZv-d/view?usp=drivesdk)

Complete ZIP SHA256: `bfc26846c1cdb538d450c14e093c427e64a955b4c2f9b0be920768ba39726ad7`. Source QA31W CSV pinned SHA256: `0c45aea30f021671084bb4ccaa67436a00edcf1aaa41a6b23e3afbfdf9b89800`.

Reproduce with Python 3 standard library (no Native rerun):

```sh
python stage1_qa31x_pairwise_first_divergence.py --zip-dir PATH_TO_8_ORIGINAL_QA31V_ZIPS --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --out OUT
```

Required exact `QA31V_SHARD0.zip`…`QA31V_SHARD7.zip` from the above original run; eight independent ZIP SHA256 are pinned in the program and in the manifest.

## Actually executed finite QA

- 8/8 original GitHub Actions artifact ZIP SHA256 and full ZIP CRC verified.
- 29/29 uniquely selected original compressed physical traces checked against signed SHA256 and full STEP tick/continuity/read-count constraints; total **510,835** physical STEP records decoded and used.
- **42** pair comparisons: all 28 pairs of 8 observed route-class representatives, all 7 consecutive 25-case shard boundaries, and 7 within-route negative-control comparisons (route R4 has only one sample).
- **12/12 synthetic analyzer self-tests** passed; these are not independent Native executions or hostile source-mutation tests.
- In 28 cross-route comparisons, 23 observed a same-tick, same-IP/delta/opcode transition difference; one cross-route pair R2/R3 retained identical physical IP/opcode path despite distinct read events. In the seven shard edges, six paths were identical; the sole changed signature had a same-instruction transition split. All seven within-route controls had identical physical control paths.
- No new Native, no source change, no main/merge, and no Stage1 PASS.

## Minimal physically witnessed boundary divergence

Original inputs `pair_34_00` (R1) vs `pair_34_09` (R7) have a first differing stdin `readline` payload at **STEP 292**, `ip=[13,5]`: suffix byte `00` vs `09`. A distinct stack state is observed at STEP 8758; the earliest measured control transition difference occurs at **STEP 9484**, both executing opcode `j` (decimal 106) at `ip=[335,17]` with direction `[1,0]`. The recorded next IP is `[336,17]` vs `[397,17]`; first different actual IP occurs at STEP 9485. These are *observations of two finite original traces*, not a proven source-level byte-ownership relation.

Six other shard edges had no physical control-flow divergence at equal tick, notwithstanding differing raw read events. Full event witnesses, alternative first stack/opcode differences, and every route-pair comparison reside in `QA31X_PAIRWISE_WITNESSES.json` in the ZIP. Distinct loop iteration counts may make same-tick comparisons lose instruction alignment; therefore `none observed` does not prove an absent branch.

## Acceptance boundary and NEXT

**QA31X finite offline analysis completed locally. Stage1 remains OPEN.** No global proof of input-byte ownership, all-source reachability, 15-cell frontier, full functional QA or geometric acceptance.

**NEXT QA31Y (engineering choice):** source-pinned, bounded upstream last-writer/read audit for the two concretely observed split instructions `j(185,8)` and `j(335,17)`. On the 29 existing SHA-pinned traces, enumerate the first splitting pre-stack operands and the most recent relevant physical `p/g/~` events, then cross-check signed source opcodes and independent byte provenance. Require explicit `unknown` when ownership cannot be established; retain frozen corpus, no Native rerun, and never promote a conditional correlation to a global reachability theorem.
