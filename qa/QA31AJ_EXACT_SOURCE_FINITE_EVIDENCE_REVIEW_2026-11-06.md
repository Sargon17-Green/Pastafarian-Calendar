# QA31AJ — accepted finite original-source q4 counter-cycle evidence (2026-11-06)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Exact source-audited code HEAD: 26b6e24686c25c60cd3578b3896d664a808af09f
Original production source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Production source unchanged. This document is QA-only.

## Completed exact-SHA evidence

- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42297366147
- Job: 128165983820, completed/success. Checkout, original source SHA pin,
  Python compilation, forward source interpreter, independent inverse,
  acceptance assertions and artifact upload all completed/success.
- CI stdout: QA31AJ_SOURCE_FINITE_PASS {'digits': 10, 'whitespace': 4, 'other': 242}
  8 forward controls; QA31AJ_INVERSE_PASS 256 bytes, 12 hostile rejected;
  QA31AJ_FINITE_ONLY_ACCEPTED.
- Original CI artifact:
  https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42297366147/artifacts/13542451997
- ZIP size 2205 bytes; SHA256
  38279f01f800d225e29ad55faade74fb4610a4657e16d8b638d98c02d8f2492f.
  Downloaded and independently checked ZIP CRC (4/4): forward.json,
  forward.log, inverse.json, inverse.log. Independently inspected both
  JSON files: 256/256, 16 source pins forward, nine reverse pins,
  8 controls, 12/12 inverse hostile mutants, new_native_runs=0,
  stage1_pass=false.
- Permanent reusable evidence mirror in ChatGPT Library:
  /Befunge_QA_Artifacts/QA31AJ_BEFUNGE98_KYRGYZ_FINITE_Q4_SOURCE_EVIDENCE_20261106.zip
  (same SHA256 as CI artifact).
- Full reproducible original-source Python scripts and workflow are committed
  under exact code SHA above. No heavy frozen Native corpus replay or new
  PyFunge execution was requested or performed by this QA.

## What is established and what is not

The *original source's canonical bounded row23→26* passage with q=3
sets q=4 at p(248,26) and m=0 at p(344,26), and returns to row5. The
next canonical original-code row5 / row8 / row11 / row17 / row20
transition was source-interpreted for every nonnegative byte 0..255:
10 digit bytes exit via row11 to row44; 4 whitespace bytes return via
row17/row20 to row5 with q4,m0 retained; 242 other byte values exit via
row17 to row44. None reaches row23 or row32 on this local transition.
Row35 with q3 independently writes q4 then proceeds to row38; it is
not evidence of a row32 re-entry.

This source-only local invariant does **not** rule out noncanonical IP
entry, alternate incoming stack state, self-modification, other q/m
writers, or reachable natural-input paths elsewhere. The original
200-case signed Native corpus had zero observed q>3 gates but also
did not establish global unreachability. There is no new natural-input
candidate and no authorized basis yet for a fresh Native probe.
Stage1 global/functional/geometric gates remain OPEN. No main/merge/Stage2.

## NEXT (QA31AK source-pinned predecessor/writer inventory)

Inspect original source coordinates and possible incoming vector edges
to rows 20/23/29/32, and potential noncanonical p writes to
q=(1,49) and m=(3,49) outside the canonical bounded source segments.
Require an independent opcode/address oracle and adversarial checks.
Treat source graph edges as conditional, not physical witnesses. Only
propose a new 25000-STEP/case Native probe after constructing and
independently checking a concrete natural-input candidate.
