# Stage17 原生 CI 驗收（2026-11-16）
專案：`PC-BRANCH-PERL-GUOYU`；分支：`Perl+國語`。

## 來源、工作及完整範圍
- **唯一驗收來源**：`457eb0a8c444c5d3416c79e03273d3144dcc3dec`；GitHub branch API 在提交本文件前確認分支 HEAD 等於該值，母提交 `c52e2996c58e0d9bdea90e8655518d57762b368c`。
- Canonical push run：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43939070420；run ID 43939070420，attempt 1，event push，head branch `Perl+國語`，head SHA 等於上述來源。2026-11-16T19:51:35Z 更新為 `completed/success`。
- GitHub jobs API `per_page=100`，page 1=100 jobs、page 2=64 jobs，共 **164 jobs；18/18 必需 completed/success；146 skipped；0 failed**。直接讀取全部 18 份原始 job logs，不只查 UI 狀態。
- 必需 job IDs：verify 133551391111；Stage01 133551391591；Stage02 133551405739；Stage03 133551405496；Stage04 133551405475；Stage05 133551405124；Stage06 133551405987；Stage07 133551405841；Stage08 133551405686；Stage09 133551405744；Stage10 133551405659；Stage11 133551405780；Stage12 133551406023；Stage13 133551405740；Stage14 133551405678；Stage15 133551405847；Stage16 133551405855；Stage17 133551405875。
- Stage01 完整 TAP：`Files=113, Tests=199251, Result: PASS`。已在同一 log 中看到 `t/47_stage02_weaving_primitive.t`、`t/48_stage03_weaving_extended.t`、`t/49_stage04_month_occurrence.t`、`t/61_stage16_weaving_seven_months.t`、`t/62_stage17_weaving_eight_months.t` 均為 ok。Stage02 專用 261 tests PASS；Stage04 專用 385 tests PASS。
- Stage17 原生 job：`Files=1, Tests=2972, Result: PASS`，wallclock 15s。完整上傳 stdout 中 2972 個順序 TAP `ok 1` 至 `ok 2972`、唯一 `1..2972`，無 `not ok`。
- 獨立 oracle 標記：`STAGE17_EXHAUSTIVE_PROFILES=4`、`STAGE17_EXHAUSTIVE_POSITIONS=5`、`STAGE17_CATALAN8_DYCK_WORDS=1430`、`STAGE17_CATALAN8_RANKS=1430`、`STAGE17_LARGE_32DAY_PROFILES=4`、`STAGE17_INVALID_PROFILES=14`、`STAGE17_INVALID_RANKS=11`、`STAGE17_INVALID_WORDS=8`。
- CI Perl `v5.40.5`；syntax 兩行：`WeavingPrimitive.pm syntax OK` 與 `t/62_stage17_weaving_eight_months.t syntax OK`；`test.stderr` 0 bytes，`test.exit` = 0。工作流程限制 `timeout 120s` 和 `ulimit -v 393216` KiB（虛擬位址空間上限，非 RSS）。

## 直接下載的七檔 ZIP：三方 SHA256 與 CRC
- 專用 artifact：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43939070420/artifacts/14263446619；ID `14263446619`；本地實際 ZIP 為 `10131` bytes。
- GitHub API digest = 原始 job log upload digest = 獨立下載後的 ZIP bytes SHA256：
  `bffdfcdf494e45020a8e0af4eb98a298cf83efd7f4e2203eb83ba6cd2e0beb1f`。
- ZIP CRC 全部正確（7/7）。成員恰為 `perl-version.txt`、`result.txt`、`source.txt`、`syntax.stderr`、`test.exit`、`test.stderr`、`test.stdout`；無缺漏／額外成員。
- `source.txt` 恰為 `457eb0a8c444c5d3416c79e03273d3144dcc3dec`；`perl-version.txt`=`v5.40.5`；`result.txt`=`STAGE17_NATIVE_PASS=1`。來源、測試、獨立 oracle、退出碼與上傳 ZIP 交叉一致。

## 驗收決議與限制
**Stage17 ACCEPTED；`LAST_COMPLETED_STAGE=17` 僅對已驗證來源 `457eb0a8c444c5d3416c79e03273d3144dcc3dec` 成立。** 後續驗收文檔／Stage18 探索文件的新 HEAD 不能冒充新 production native PASS。Stage18 尚未實作／驗收；252..5778 日全年生成器未驗證，亦無 main、merge、發佈。
