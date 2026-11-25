# SQL+தமிழ் Slice25 — direct coverage and original matrix gate audit

**PROJECT_ID:** `PC-BRANCH-SQL-TAMIL`  
**Audit date:** 2026-11-25  
**Branch:** `SQL+தமிழ்`  
**HEAD at audit:** `7572f4a665dfd608f7840a695465e1a4f8962b39`  
**Scope:** evidence audit only. No production SQL, no full-matrix replay, no main/merge/release.

## 1. Current exact-HEAD push results

Automatic push run [45657590624](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45657590624) completed/success on exact HEAD `7572f4a665dfd608f7840a695465e1a4f8962b39`, PostgreSQL 17.12:

| Case | Job | Artifact | Raw SHA-256 = upload log = GitHub metadata | CRC | Source locks | Typed oracle | PSQL_EXIT | Elapsed |
|---|---:|---:|---|---|---:|---:|---:|---:|
| `next_1_month_first` | 139358345990 | 15042419622 | `ddbc9acad6b82e027fe11d345006f943fb10f31ab0fe57583794f12cb72721b2` | 9/9 | 29/29 | 5/5 | 0 | 329.938 s |
| `next_1_month_second` | 139358346467 | 15043048509 | `af3fac5ea1e7535bc13f4cc7e903e0d9422834259706b9a49af062eafbe88696` | 9/9 | 29/29 | 5/5 | 0 | 487.290 s |

Actual typed tuples:
- first: `(5001, கொத்து, 2, எரிடு, 1)`
- second: `(5001, கொத்து, 38, எரிடு, 2)`

For both original ZIPs, the two internal manifest entries (`probe.sql`, `oracle.json`) were independently re-hashed and matched 2/2. Each ZIP contains 29 unique source-lock paths. The artifact `static.txt` says `NATIVE=NOT_YET_EXECUTED`; these are accepted direct archived-oracle checks, **not** a Native-stage PASS and **not** live normative differential.

Supporting exact-HEAD runs:
- Stage1 run 45657590095 / job 139358345249 completed/success, PG17.12: ordinary 52/52, saved-sum 7/7, heavy 3/3, production isolation 4/4. Original artifact 15042897603, 1,387 bytes; raw SHA-256 `6f7c7eaa36c3ba5f1e96e4936f352d13d6b3270f9ce0b51224f6d6600ac9bd8f` equals upload log and GitHub metadata; CRC 3/3.
- Canonical Names Lock run 45657590316 / job 139358347158 completed/success on the same exact HEAD; no artifact configured.

## 2. Direct archived-oracle coverage (separate from matrix gates)

Accepted direct cases now total **6/29**:
1. `prev_3_prev_middle`: run 45505543502, job 138839681587, SHA `51f279557cc25f97163bbd91f8c0a0f7bc485482`, artifact 14972669624, 5/5, 29/29 locks, PSQL_EXIT=0, 507.515 s; raw/upload/metadata SHA-256 `f8a95a4d5699f14d4babea70deb86c6a82821c12ad6cb5d78f816013955f833a`, CRC 8/8.
2. `anchor_cutlet_boundary_minus`, `anchor_cutlet_boundary`, `anchor_cutlet_boundary_plus`: run 45551461538, three completed/success jobs on SHA `8d9e07711d047b00ebc04ae8c0ef4ecd75ffcc7f`; each 29/29 locks, typed 5/5, PSQL_EXIT=0. Original artifacts 14993462927, 14993857190, 14994680554 have raw/upload/metadata SHA-256 equality and CRC 9/9 each.
3. `next_1_month_first`, `next_1_month_second`: run 45657590624 and artifacts above.

The locked fixture is blob `21f38cd280498070b08b6c3074780f1742c36957`: 29 distinct cases across eight year IDs. The **23 residual direct archived-oracle cases** are:
- `prev_3_prev_first`, `prev_3_prev_last`
- `prev_3_first`, `prev_3_middle`, `prev_3_last`
- `prev_2_first`, `prev_2_middle`, `prev_2_last`
- `anchor_first`, `anchor_middle`, `anchor_last`
- `next_1_first`, `next_1_middle`, `next_1_last`
- `next_2_first`, `next_2_middle`, `next_2_last`
- `next_3_first`, `next_3_middle`, `next_3_last`
- `next_3_next_first`, `next_3_next_middle`, `next_3_next_last`

The old matrix Native results overlap some residual cases but are recorded under the Native gate, not silently added to the separate direct-acceptance count. Five middle cases (`prev_3_middle`, `prev_2_middle`, `next_1_middle`, `next_2_middle`, `next_3_middle`) were absent from its 24-case Native matrix.

## 3. Original 56-job live matrix and gate audit

Original run [44896020377](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44896020377) tested exact SHA `62c07e286b537cd3969bc35399b1f160250dafb0`, branch `SQL+தமிழ்`, PostgreSQL 17.12. API returned all 56 completed jobs and 56 artifacts:
- Native: 24 jobs; 23 completed/success, one timeout (`prev_3_prev_middle`).
- Isolation: 8/8 completed/success.
- Live normative differential: 24 jobs; 22 completed/success, two timeouts (`prev_3_prev_last`, `next_3_next_middle`).
- The 22 successful differential cases cover all eight year IDs.

### Independently downloaded original archives

Downloaded and audited all 40 artifacts needed for the requested minimum gates: eight successful Native jobs (40 named Native field notices), all eight isolation jobs, and all 24 differential jobs. For all 40:
- original ZIP bytes SHA-256 = upload-log SHA-256 = GitHub artifact metadata digest (40/40);
- ZIP CRC/decompression passes (40/40);
- `versions.txt` identifies exact SHA `62c07e286b537cd3969bc35399b1f160250dafb0`, branch `SQL+தமிழ்`, PostgreSQL 17.12 (40/40);
- source manifest has 35 entries, including all 28 production SQL files (40/40); the 28 production hashes and other common source hashes are identical across all 40 archives;
- `completion.txt` exists for 38 successful jobs and is absent only for the two failed differential jobs.

Native log verification: eight selected successful jobs each emitted exactly five distinct `NOTICE: SLICE25_NATIVE_FIELD_PASS` records and one native green marker, proving the minimum 40 named Native assertions. Isolation: all eight logs emitted five Native field markers, one schema marker, one body marker, and one isolation green marker. Differential: all 22 successful logs emitted five Native plus five differential field markers and a differential green marker; the two timeout logs emitted zero field markers and no green marker.

| Mode | Case | Job | Artifact | Raw SHA-256 = upload = metadata | Result |
|---|---|---:|---:|---|---|
| Native | `anchor_first` | 136821728390 | 14704894752 | `479d5f43bde69042b014e4bf48a239fe83fe8cf3667f2cede1b3c66a52fcfe8c` | success |
| Native | `anchor_last` | 136821728230 | 14705965644 | `64c262b0c6c7e8b55e6f44333e71a2413ebac10232caef25263962055212d43b` | success |
| Native | `next_1_first` | 136821728401 | 14705821378 | `8547e5664879d45b9eff73fafecdefefb227632e778751151fe5040729f80ddd` | success |
| Native | `next_2_first` | 136821728418 | 14705112826 | `5f066ea6199ed2601815606f8588e93a2ae05ae756212ddda69c8386117f0fe2` | success |
| Native | `prev_3_prev_first` | 136821728419 | 14704093417 | `64f6a7a193f75423dfcf0cf4973263a68d2bec81a2d2bfcccc78378157ef3de3` | success |
| Native | `prev_3_prev_last` | 136821728422 | 14704033961 | `ce3b02886252429f8e6a77fcd88426b5a8cceda23309412690853ce981e80274` | success |
| Native | `prev_3_first` | 136821728427 | 14704746276 | `604e10b8c640ef71338f0a2646e84b88ff70985ed10ded842675420332429acf` | success |
| Native | `next_1_last` | 136821728429 | 14705064552 | `848f1e816951598b0835124f2f27a2c3d26c64da5102cf56f1d47d5b9ff99e5e` | success |
| Isolation | `prev_3_prev_first` | 136821730002 | 14706851245 | `3cb3acfc035705541a322ce082616829ad80d592b6d2cf02d5cf867a838d0592` | success |
| Isolation | `prev_3_first` | 136821730006 | 14706945605 | `08489ecff1bcb9d3c7886c401ffb5e4fc16e2d0ce87876fcb38f117c67f50071` | success |
| Isolation | `prev_2_first` | 136821730034 | 14706338933 | `bf57624d2979b8ff393f0ab3c5123f91daaa7eddac0809460b1944a80426e802` | success |
| Isolation | `anchor_first` | 136821730099 | 14706955480 | `a7b05d38ed10acd94527ea71677e4658df18ee8bc71efcdfd82ad2fab9933d75` | success |
| Isolation | `next_1_first` | 136821730112 | 14706478228 | `2a15d4e8143575b8849efd974262f1a9a9530d463837b73e70789ef2bfe72c5e` | success |
| Isolation | `next_2_first` | 136821730117 | 14706409627 | `ea63af51ecd0ccf48eabc4281646f713e5d84afdab2124fec023d7ac9bdea53b` | success |
| Isolation | `next_3_first` | 136821730137 | 14706299951 | `29daddb95500712785b49baec0e5ce4b3882a58874b13f60a34161eb1d07e7a1` | success |
| Isolation | `next_3_next_first` | 136821730196 | 14707440147 | `6c938b6baeb7e17a6988a5b9fdb496dc0db754d8108f15e839a38083023b2c59` | success |
| Differential | `prev_3_prev_first` | 136821730207 | 14707296518 | `ad4bdee4d616cced12841f525fed72d36aa41008885897379d452bd89fbc13c2` | success |
| Differential | `prev_3_prev_last` | 136821730236 | 14706902845 | `ade465a45fb1ae4fd6902ddb1d9d85a7cbd4217ddef0bb3d03c9674c660bdb43` | timeout |
| Differential | `prev_3_first` | 136821730815 | 14706839143 | `73b5b4984e196e85e7adc306134ecc7c88dc8e1c20f32033d343720db5f55698` | success |
| Differential | `prev_3_last` | 136821730843 | 14707850284 | `c03542d12cf6ea659cf2ec49b0ebf5a54ee459661991370c83189735d8dff045` | success |
| Differential | `prev_2_first` | 136821730968 | 14707850334 | `12d0b077f4d30873f67f26a2766f9dbab1d6c9b7816ca68983b7346dc73ad8f7` | success |
| Differential | `anchor_first` | 136821730978 | 14707497523 | `41252772b7a9ea85b8641f9c870aae540380666d8cf5831a0adb242de0cb3373` | success |
| Differential | `anchor_last` | 136821730983 | 14707905919 | `341d4acdd58d1bec0765ce986bf1221179cad91080bb6884cbb1bc393c308590` | success |
| Differential | `next_1_first` | 136821731029 | 14707686811 | `01c4a0de8ac3254616c28011175f9e0d09da8517e3e1b5aa1a42f8a44a2367a7` | success |
| Differential | `next_1_last` | 136821731038 | 14707234594 | `c57f75d76b55e6773c52e65e0093ec2f647a5c2c43464d48fc3a182f4ebb3d62` | success |
| Differential | `prev_2_last` | 136821731127 | 14706934759 | `8a52906400b9798b51840d53fc3ee94bc160b98dc0979ef644424c8ceb3a86c4` | success |
| Differential | `next_2_last` | 136821731129 | 14708027603 | `f5c8038a7857bd82f2ab6d0955f50ca7be085daf8ffbe111c00c57d2d80207a6` | success |
| Differential | `next_2_first` | 136821731179 | 14708180202 | `151dec9541ad8bd5bc5b706fcb5d6125a1ba5150bb2158badebc1f6442d0688d` | success |
| Differential | `next_3_first` | 136821731662 | 14707957914 | `f0bf9e1c479ddd90928993f3748907ec68d8d6d5c4fdaba03207e79decc6db0b` | success |
| Differential | `next_3_last` | 136821731726 | 14708355906 | `0fbb334405a7feec724fef825fbe19a489d4aac2bc9dde8644ae0af2c75eaff6` | success |
| Differential | `next_3_next_first` | 136821731790 | 14709120682 | `e12edc8157e34d552a19e225df3c817d5332fe00fe3776b221fb6ae76a1cc982` | success |
| Differential | `next_3_next_last` | 136821731833 | 14708531156 | `058e267d9086e270201c64c97605c2fc0b9b0141ef4f768b4a2efea3b2d4409c` | success |
| Differential | `anchor_cutlet_boundary_minus` | 136821731897 | 14707904803 | `2d0a21747ec8977f56ccaffda4ec25086466a4f4aeaa92da3e3000cc7ef472a0` | success |
| Differential | `anchor_cutlet_boundary` | 136821732004 | 14708641913 | `12a0da95e9c54c4f7f95069dfa9d6c7547d30867db1a73cd5d8a665b9c22b6b6` | success |
| Differential | `next_1_month_first` | 136821732094 | 14708547767 | `04f96c5069df1e6203f51c8cef46bdb53d0c7983b52589412d0abc23a52199ef` | success |
| Differential | `anchor_cutlet_boundary_plus` | 136821732123 | 14708627508 | `0ce4ca6373e1388153f2ce191c4f78600828b901f3e118460bf8af9191a1b33b` | success |
| Differential | `next_1_month_second` | 136821732128 | 14709115910 | `2f36052837cb09b33e3f2a3bf04a426a45390984778bc651e18ed1610452facb` | success |
| Differential | `prev_3_prev_middle` | 136821732214 | 14708369692 | `ba3f2033fd787d9031f2a97beba0497608624a7cbf065d04d7acbc3ba5c0707d` | success |
| Differential | `anchor_middle` | 136821732766 | 14708543520 | `91a0a0009c107694ba527cbf4fc73e9b56ed3feae28e07d321f6b1bcee69777b` | success |
| Differential | `next_3_next_middle` | 136821732884 | 14708869100 | `3b4cbc06ceb6ca64aec8cf3f9559826c6e5025b34be18bb991fc09f601af687a` | timeout |

### Three original timeout stacks

- Native `prev_3_prev_middle`, job 136821729378: 12-minute statement timeout in `month_weaving_ranked` → `choose_month_weaving` → `build_year_structure` → `calendar_date`.
- Differential `prev_3_prev_last`, job 136821730236: 12-minute timeout in `floor_div` → `save_value` → `stone_state` → `stone_value` → `bowl_round` → `sauce` → `gate_gap_signed` → `positive_gate_gap` → `gate_index_at_or_before` → `exact_gate_index` → `choose_cutlet_partition`.
- Differential `next_3_next_middle`, job 136821732884: 12-minute timeout in `bowl_factorial` → `bowl_order_from_number` → `post_stir_round` → `post_stir_chain` → `sauce` → `gate_gap_signed` → `positive_gate_gap` → `calendar_date`.

These are timeouts, not field mismatches. The run conclusion is failure; no full Slice25 acceptance.

### Non-additive prior pilots

- Runs 44890391746 and 44892630182 both tested differential `next_2_first`; this is the same case already in the 24-case matrix, not an additional unique case.
- Run 44905408848 differential `prev_3_prev_last` passed 5/5 archived goldens and 5/5 normative fields only with a QA-only `year5000_gate_window` DP override. That is not the unchanged production path and is not counted toward the 24 production differential cases.
- Run 44910633756 is a QA-only gate-guard candidate; its anchor case is Native, not differential, and its `prev_3_prev_middle` job timed out. It adds no live differential case.
- Run 45272513621 accepted a bounded structure probe but explicitly did not call direct `calendar_date`; it is not a direct or differential case.
- Run 45076535299 accepted a separate one-stone candidate (368 array comparisons, 12 invalid inputs, independent 230+32 vectors); it is not the Slice25 live normative calendar-date differential gate.

## 4. Gate decision

| Required gate | Audited result | Decision |
|---|---:|---|
| Named Native assertions >=40 | 40 directly verified from eight exact job logs; API matrix total 23/24 Native jobs success | Met |
| Production-only isolation >=8 | 8/8 with schema/body assertions | Met |
| Live normative differential >=24 | 22/24; two timeout cases | **Not met** |
| Eight distinct year IDs | 8/8 in the locked fixture and 22 successful differential cases | Met |
| Direct archived-oracle cases | 6/29 | 23 remain |

**Decision:** Slice25 remains **NOT ACCEPTED**. Archived-oracle direct results, QA-only candidates, bounded structure probes, and one-stone QA are not substitutes for the missing two live production differential cases.

## 5. NEXT

Do not replay the 56-job matrix or either timeout unchanged. First create a bounded, source-locked phase diagnosis for the two failed live differential inputs, preserving the unmodified production path:
1. `prev_3_prev_last`: isolate `exact_gate_index` / negative gate-gap / sauce / nested stone calls. The QA-only DP candidate pass is useful diagnostic evidence but cannot be credited as production.
2. `next_3_next_middle`: separately profile `bowl_factorial` / `post_stir_chain` / sauce on its own input.

Use one case per fresh PostgreSQL 17.12 job, the existing exact 29 source/fixture locks, explicit phase entry/exit markers, bounded statement and watchdog limits, all five typed fields, and original ZIP raw SHA/upload/metadata/CRC. Only after new evidence identifies the expensive path should a production-preserving optimization or explicit bypass be proposed and regression-tested. In parallel, continue the 23 residual direct archived-oracle cases in small one-case jobs; the next untested Native middle input to prioritize is `prev_3_middle`.

No production file changed during this audit. No merge, main, or release.
