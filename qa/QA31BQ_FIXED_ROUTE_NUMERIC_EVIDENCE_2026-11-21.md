# QA31BQ — fixed-original-route numeric executable-byte QA
PROJECT_ID: `PC-BRANCH-BEFUNGE98-KYRGYZ`
Authorized branch: `qa-befunge98-stage1-order-isolation-20261008`
Verified parent HEAD: `32babb5bef7e85eb9431ee6dda28004b0b9114e0`
Date: 2026-11-21. Classification: **LOCAL finite source-only QA accepted; Stage1 OPEN**. No new CI, Native, main, merge, or Stage2.

## Immutable inputs and persisted code
- Signed QA31AI original 200 Native archive SHA256 `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`.
- QA31BN SHA256 `6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79`.
- QA31BO SHA256 `b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de`.
- QA31BP SHA256 `d0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24`.
- Source Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Complete standalone reproducible package in user Library at `/Befunge_QA_Artifacts/QA31BQ_BEFUNGE98_KYRGYZ_FIXED_ROUTE_NUMERIC_20261121.zip`; ZIP SHA256 `23a587a58970031d56290399aed0db6f2df55a4107e322f6baa777fb054f1620`; 10 members, 9 SHA256 manifest entries, ZIP CRC PASS. The package contains both complete Python source files, RUN/REPRODUCE, case/prediction/hostile JSONL, machine summary and detailed Markdown report. The original 46MB signed corpus is referenced, not duplicated. Report is also saved separately at `/Befunge_QA_Artifacts/QA31BQ_FIXED_ROUTE_NUMERIC_EVIDENCE_2026-11-21.md`.

## Algorithms and finite checked result
All 8 original signed shards, 200/200 HALT receipt identities and 3,628,390 physical STEPs checked, and 135/135 selected original traces fully decompressed with contiguous STEPs and SHA checks. The two separate implementations are (1) concrete stack arithmetic along the signed frozen route and (2) affine coefficient-domain source-token interpreter with rejection of nonlinear or source-dependent x/address. Both derive `p(1500,1860).value = 56 * g(19,1696) + 62` and agree on all 945/945 mathematical predictions (7 hypothetical g values * 135 originals).

Per-case hypothetical values: g=-1 => 6, g=0 => 62 (`>`, original physical observation), g=1 => 118 (`v`), g=2 => 174, g=3 => 230, and g=±(2^127-1) => exact 128-bit-boundary-scale **formal mathematical** values. 135/945 are unchanged original-byte predictions and 810/945 conditionally different values. The two earlier signed x operands are constant in the original path. 24/24 genuine upstream no-op records preserved; 18/18 detached hostile signed STEP modifications rejected. Python compile PASS. Numeric overflow and out-of-ASCII opcode semantics are deliberately not claimed.

## Critical boundary
Those 810 changed-code results are **source-only conditional arithmetic**, NOT modified original Native execution. Altered source/g/address/writer/control transfer/opcode fetch or output remains UNKNOWN, as do global reachability, full functional and geometric Stage1 acceptance. In particular, the ASCII `v` prediction for g=1 would change control flow *if the cell were fetched* and is **not** evidence of an observed altered route. No new run, release, or Native acceptance.

**NEXT (QA-only, no new stage):** independent source-geometry check for the first post-fetch instruction at (1500,1860), comparing the conditional `>` and `v` branches while preserving the unknown actual altered-run reachability; require independent oracle, original code-cell ownership and >=12 hostile/no-op controls. No Native without a specific evidence-based need.