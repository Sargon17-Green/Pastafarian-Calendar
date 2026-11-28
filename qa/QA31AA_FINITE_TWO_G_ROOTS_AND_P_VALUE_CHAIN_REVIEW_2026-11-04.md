# QA31AA — finite signed-original operand root of j(185,8) (2026-11-04)

PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`
Working branch: `qa-befunge98-stage1-order-isolation-20261008`.
Verified pre-change HEAD: `94c75f181c9f48e638821d57ebbb161dea255daf`.
Previously pinned original source blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`. No production modification.

## Evidence and scope

Bounded to existing [QA31V signed original Native run 41689861481](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481) and the frozen [QA31Y archive](https://drive.google.com/file/d/1N3QeYs6FTJEafeHyeU0u5wiLdIRfv5CV/view?usp=drivesdk): 46,421,841 bytes, SHA256 `1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a`.

No new Native or CI was executed. QA31X's original SHA256 + ZIP CRC + signed trace gzip/CSV/receipt verifier loaded 8/8 original shard ZIPs, 29/29 signed original traces and 510,835 original STEPs. QA31Y's previously source-pinned opcode-site assertions checked 3,557 physical events (19 known sites); this session did **not** re-download/verify the complete source blob. This is a finite result only.

QA31Z's 384-step scan had resolved 103/364 local jump operands and conservatively left 261 `j(185,8)` operands `unknown`, because a pre-existing multiplier operand lay outside the forward scan rooted at the first targeted `g(151,8)`.

## New QA31AA analysis (768-STEP maximum)

Each of the **261** observed `j(185,8)` operands was traced using a physical forward stack-tag replay back to previously excluded, source-pinned **`g(57,8)`**, and independently using an unshared *backward required-index transfer* oracle. The two independent analyses agreed **261/261** on exact tick/coordinates and origin sites:

1. A physical `p(60,5)` wrote cell `(0,49)`.
2. 192 STEPs later, physical `g(57,8)` read the **same numeric value** at `(0,49)`; no intervening `s` instruction was observed.
3. 94 STEPs after `g(57,8)`, physical `g(151,8)` read another Funge-space value.
4. 27 STEPs after `g(151,8)`, the witnessed `j(185,8)` consumed operand `0` or `61`.

Thus each of the 261 finite physical operands has **two structurally observed g roots: (57,8) and (151,8)**. Neither path crossed an unsupported stack mutation in the bounded trace window, and every `p`/`g` value matched. The observed `g(57,8)` value histogram contains 16 different values (see executable summary for distribution). `g(57,8)` and `p(60,5)` were already among QA31Y's source-pinned opcodes.

**Important:** Numeric equality at a `p`/`g` boundary does not by itself establish causal input-byte ownership. The analysis does not prove the source bytes that fed `p`, that no unobserved interpreter effect changed Funge-space, general reachability, or global input-to-j causality. Structural tags deliberately persist through multiplication by zero and must not be misread as proof of numeric sensitivity. Every byte-owner field remains **`unknown`**.

Independent backward verifier: **261/261 original witness matches**, **19/19 hostile witness mutations rejected**; forward script **11/11 local synthetic guards passed**. Synthetic tests are **not** additional Native runs. Validated by frozen signed originals, not by self-reported witnesses alone.

## Reproduction

Python 3 standard library. Extract original QA31Y ZIP into a directory containing `QA31V_SHARD0.zip` through `QA31V_SHARD7.zip` and `QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv`, then place the QA31AA package's scripts in the same directory. Run:

```sh
python stage1_qa31aa_signed_operand_roots.py --zip-dir . --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --out QA31AA_REPRODUCED
python stage1_qa31aa_independent_reverse_oracle.py --zip-dir . --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --witnesses QA31AA_REPRODUCED/QA31AA_WITNESSES.json --out QA31AA_REPRODUCED/QA31AA_INDEPENDENT_SUMMARY.json
```

All same-branch source Python files and outputs are included in the independent QA31AA package; its self-contained logic references the frozen QA31Y original ZIP rather than duplicating source Native archives.

## Stage gate and NEXT

Stage1 remains **OPEN** (`FULL_FUNCTIONAL_QA_PASS=NO`, `GEOMETRIC_SPAGHETTI_QA_PASS=NO`). This is not global byte provenance, not 55-stage acceptance. No production/source edits, `main` change, merge, publication or Stage2.

**QA31AB:** finite source-pinned backward stack dependency from the physically observed `~(13,5)` stdin return to `p(60,5)` value in the same 261 signed traces, treating unsupported arities, alternate stack writers, or missing causality as `unknown`. Independent oracle + hostile controls; first quantify physical reachability/stack path before any new Native. Do **not** infer global input ownership from numeric equality or merely matching route output.
