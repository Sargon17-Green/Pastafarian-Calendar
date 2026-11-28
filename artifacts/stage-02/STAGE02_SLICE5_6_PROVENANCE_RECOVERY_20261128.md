# Stage02 historical Slice5/6 provenance recovery — 2026-11-28

PROJECT_ID: PC-BRANCH-SQL-TAMIL. Branch SQL+தமிழ். Parent d9520447425c03e4ef1d2478a3c333d77d2bd418 verified live. Supplements STAGE02_HISTORICAL_SOURCE_LOCK_RECONCILIATION_20261128.md. No new execution or production change.

## Original evidence

Targeted branch/path commit history of the two workflow files and sql/test/91_stage02_bowls_differential.sql, then repository Actions runs filtered by exact head_sha (not the PR-only wrapper), located three completed push runs. Job logs, exact checkout/version provenance, artifact metadata and actual downloaded ZIP bytes were inspected. All three ZIP SHA256 values match both upload log and metadata; all 12 entries passed CRC, original versions.txt gives PostgreSQL 17.11 and the respective exact SHA. Archives contain native.txt, differential.txt, isolation.txt, versions.txt, not packaged source bytes or internal source manifests.

| Slice | Tested source | Run / job / artifact | Native / isolation / differential | Original ZIP bytes / SHA256 |
|---|---|---|---|---|
| 5 initial | a5f0b24c91f23c3b586c97422d39c4e20a9ae9f0 | 41097516307 / 124206994125 / 12997675113 | 61/61, 4/4, ERROR (not accepted) | 1384 / 7f40373a0aa1cbaae54b4d97939aeb2f2fdf97609d72731674c7c93b6866eaef |
| 5 repaired | 669f8c0b6582fd201f0ce2a34dcb3a942258b8eb | 41098057490 / 124208857726 / 12995814704 | 61/61, 4/4, 762/762 | 1391 / 2a4988998dbd3e44d7480b319bfdc54e2105064961493cb82daefbc554c721c1 |
| 6 | 8b8a59cec8e316b859e30842ffbf1deecd793973 | 41108943424 / 124245945912 / 13001843490 | 93/93, 4/4, 432/432 | 1321 / adda50746e58fd963a70adb06b768e899e6180689dc1156d0ad9ae886dfaecfd |

Each successful archived verdict returned 1 from the count-and-bool_and gate, with COMMIT. Slice5 repaired 720 ranks + 12 signed/large wraps + 30 bowl fields; Slice6 3 day pairs x 4 drops x 6 indices x 6 bowls = 432. Initial failure at 91 line 50, reserved BOTH CTE, exit 3; repaired as pair_results in 669f8c0. No production mismatch inferred from syntax error. No replay justified for historical provenance. 1356 successful historical assertions including isolation; not new Native at HEAD.

## Source and harness reconciliation

Complete recursive tree responses at both successful commits and parent were non-truncated. Slice5: 8 numbered SQL files, only 06 differs; Slice6: 9 numbered SQL files, only 06 and 08 differ. Later files additions. Normative blob ce17bf6fd166451b6904411c5e29d1b26d92e278 identical. Combined with prior 22/24 map this locates 24/24 source trees; ancestry compare for these two and global acceptance remain distinct from tree/blob matching.

Both historical workflows and four actual test SQL files match parent blobs:
- bowls-native workflow c33ff297a845eed5b70dbd1e142a76537704702b; 90 native 9f777bfb8e651731b4089f93c91f228926ce8872; 91 differential 8ea79fdf55b289fdd8fcf01d14279ea6f82be51f.
- bowl-round-native workflow 783cb9a1dc297e46b80ca6aebe83781c045d6b27; 92 native 6ebc75ed2180a0d3ab90e38a79764fc22604022d; 93 differential 27cc068e6380f7ab2b600c634e4db2d3620e3ac7.

Read actual four harnesses and production 03,04,07, old and new 08. Slice5 calls bowl_order_from_number, bowl_order_from_drop, initial_bowls(work_counts), save_modulus and metadata checks. 07 blob 0ad25cc4054f46fba66c10dfeffcd81d49f32399 and 03 blob 72ae68d3ec009f65f081a099c8bf06e0dd3ed9d6 unchanged; 03 defines work_counts composite and day_count, foundation_day, save_value, save_modulus, regular_mod, floor_div. These paths do not call 06,08,16. Historical functional Slice5 evidence is source-equivalent for tested direct inputs; historical catalog/isolation remains historical, not a fresh full-schema catalog verdict.

Slice6 08 changed 68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6 -> f84f0ac6c2b570aa3ef61038247a44e602014534. Exact 04 blob caed82dc41d7a259953dc817d5e0722038821310 defines stone5 and immutable strict stone_state and stone_value. Old/new 08 ordering guards identical, all arithmetic and neighbor indices unchanged; substitution materializes stone_state once and maps stone kinds 1..5 to wheat/barley/salt/bitter/red exactly. Valid-index equivalence argument covers all valid p_i 1..46 under same input conditions; static, not fresh Native. The old native 8 invalid/null cases (0/47, fractional drop, short/null-member bowls, null bowl/drop/index) remain historically tested; no claim they ran again. 92 and 93 do not call 06, but 08 changed. Existing accepted stone-reuse run 45900542068 compares 3772+3496 drops and rounds at exact 3b8121ecd0eb8820d9af55c0d562150cdff003b6; complete numbered 28 production blobs plus oracle match parent, as do all 28 plus oracle at matrix 46340d661200fa2e6b8314e37f8c8ccc495b3886 and real-sauce c536ab40e01ec6d2ff8de1ee23b909b052064550. This confirms source continuity of those bounded accepted tests. Old fast-window 7e0212b0b2b91008dc99cfecb3d5db19984129c7 has 27 numbered files and differs in 06/08/16; existing recorded override-function equivalence is not full dependency closure.

## Residual
Map provenance gap resolved, not whole Stage02 acceptance. Continue changed-source harness/dependency ledger for 06/08/16 including invalid/boundary cases not proven equivalent, and global Stage02/legacy entrypoint contract. DEVELOPMENT_STAGE.md remains CURRENT_STAGE=1/LAST_COMPLETED_STAGE=1. Do not infer promotion or new stage. No new CI dispatch, production edit, main, merge, release or user execution. No new execution results; historical archive retrieval only.
