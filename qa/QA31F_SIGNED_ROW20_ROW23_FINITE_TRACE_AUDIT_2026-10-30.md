# QA31F — Signed original row20/row23 two-gate witness audit (2026-10-30)

Project: PC-BRANCH-BEFUNGE98-KYRGYZ. Stage 1 only, QA branch `qa-befunge98-stage1-order-isolation-20261008`; verified parent HEAD `820e0fd579ff6b4f19d6160f9aabbe5aa580372f`. This is **new finite QA evidence**, not an interpreter reexecution, production modification, global source-reachability proof, or Stage 1 acceptance.

## Pinned original evidence and targeted work

- Original production source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`. Original static rows 20/23 were inspected by GitHub's blob API.
- Original signed QA20 workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761821210
- Four original ZIP SHA256s in shard order 0–3:
  - `0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076`
  - `0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea`
  - `d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c`
  - `d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07`
- Historical QA31A aggregate artifact 12634011438: ZIP `235be0d04cc2f6ab113b3a809c3a2ef93513c07cb2233b2b8b457722d409a4cd`; JSON `39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c`.
- All 48 QA20 signed STEP records were re-read (1,939,997 individual STEPs). Checked all ZIP hashes/CRC, original source identifiers, per-case compressed digests, sequence numbering and physical executed opcode/next-IP routes. QA31A summary states 136 historical original programs / 4,513,423 STEPs and 15 unvisited source targets; this run **did not** independently re-extract all 136 QA27 STEPs.
- Reproducible Python verifier (including 3 corrupted STEP rejection tests) stored as a permanent independent artifact: https://drive.google.com/file/d/1V4q2sGuhpqDA-T9W_YJnyqGxAgO-QhEH/view?usp=drivesdk
- Full method/report: https://drive.google.com/file/d/14IW1YnudrmsK_S2k7qMBQyylRwPxsdMM/view?usp=drivesdk

## New physical original-source observations

| Physical original control event (QA20) | Observed |
| --- | ---: |
| `j(89,20)` total visits | 165 |
| `j(89,20)` successor `(90,20)` → `x(150,20)` → `(10,5)` | 3 |
| `j(89,20)` successor `(151,20)` → `x(211,20)` → `(10,23)` | 162 |
| `g(57,23)` and `j(113,23)` following those 162 entries | 162 / 162 |
| `j(113,23)` successor `(114,23)` → `x(174,23)` → `(10,26)` | 162 |
| Original `x(235,23)` visits | **0** |
| Synthetic corrupted signed STEP routes rejected | 3 / 3 |

Within the original static row20/23 model, the 162 physically observed first-gate positive successors are consistent with `m=FungeSpace(3,49)=1`, and every subsequent second-gate zero successor with the predicate `q=FungeSpace(1,49) <= 3`. **No signed QA20 witness has the necessary simultaneous `m=1 AND q>3` needed to enter `x(235,23)`**. This is a finite original-IP observation, not a proof of global input impossibility.

The signed STEP format does **not** record direct `g` values, full stack state or storage-offset proofs. The observer checks the bounded executed opcode paths (no intervening `p`, `{`, `}`, or `u` on the relevant segments). Original-byte consistency over each visited segment is an extra check in the verifier when `--source src/interleaved_work_counts.b98` is supplied. Local run verified signed original archive evidence; complete source-byte pin was independently inspected using GitHub API, not locally supplied as an entire source file. No claims for other hypothetical original byte owners or input paths.

## Acceptance boundary and NEXT

Scoped original-signed-offline QA **passed locally**: 48/48 case archives, 1,939,997 STEP records, 165/162 gates and 3/3 hostile mutations checked. No **new GitHub Actions CI** or Native run has been claimed for this new report; previously completed CI 41108427185 verified only the earlier conditional source model on its exact preceding SHA.

**Stage 1 OPEN**; `FULL_FUNCTIONAL_QA_PASS`, `GEOMETRIC_SPAGHETTI_QA_PASS`, natural simultaneous gate witness and global source/stack/offset ownership are not established.

**NEXT:** Cross-index existing original signed `p`/live memory receipts for physical cell `(1,49)` before `g(57,23)`, and determine whether a natural input can make `q>3` while `m(3,49)=1` on the same original path. Only a source-backed candidate warrants a bounded Native experiment and independent auditor. Do not repeat the already verified 48-case trace scan or 20-case model without new evidence. No Stage 2, protected branch changes, PR merge, or publication.
