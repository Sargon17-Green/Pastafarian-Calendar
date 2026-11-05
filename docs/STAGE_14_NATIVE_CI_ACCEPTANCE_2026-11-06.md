# 第 14 階段 Native／CI 驗收紀錄（2026-11-06）

專案：`PC-BRANCH-PERL-GUOYU`；唯一分支：`Perl+國語`。Stage14 驗證凍結的正規名稱目錄與已驗收 Stage13 名稱選擇之整合；不驗證完整五欄日曆、sauce、askBowl 或年份生成。

## 同源 CI 與工作檢查

驗收的**原始 source SHA**：`79b159ab0a47ebfd2d95baf60bf5f41f2b60e17a`。在寫入驗收前，直接查詢分支 HEAD 並確認完全相等。
Canonical push run：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979442679
run_id=41979442679；attempt=1；event=push；status=completed；conclusion=success；head_branch=`Perl+國語`；head_sha=`79b159ab0a47ebfd2d95baf60bf5f41f2b60e17a`。已分頁查閱全部 161 jobs：**15/15 必需 jobs completed/success**，其餘 146 skipped，無必需 job 失敗；直接讀取所有 15 份 raw job logs。

必需 job IDs：verify 127085892337；perl-stage01 127085892637；Stage02 127085899569；Stage03 127085899491；Stage04 127085899543；Stage05 127085899516；Stage06 127085899614；Stage07 127085899976；Stage08 127085899766；Stage09 127085899972；Stage10 127085900105；Stage11 127085899948；Stage12 127085899735；Stage13 127085899999；Stage14 127085899663。

Stage01 原生完整測試：`Files=110, Tests=180906, Result: PASS`。Stage14：`Files=1, Tests=285, Result: PASS`。測試輸出包含 `STAGE14_FROZEN_CUTLET_NAMES=17`、`STAGE14_FROZEN_MONTH_NAMES=47`、`STAGE14_INDEPENDENT_BOUNDARIES=64`、`STAGE14_INVALID_CASES=17`、`STAGE14_FULL_GENERATOR_NOT_VERIFIED`。原始 job 顯示 Perl>=5.40 閘門、兩個 syntax OK、`timeout 120s` 與 `ulimit -v 393216` KiB。這是虛擬位址空間上限，**不是** RSS 的實測最大值。

## 直接下載並獨立核驗的 ZIP

Stage14 原始 artifact：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979442679/artifacts/13393014655
ID=13393014655；2,388 bytes；本地對實際下載位元組計算之 SHA256：
`17352b8ec4d264d3bb0eabb18bb8606461421ca35d85e8342a347084e90fe67c`
與 GitHub provider digest、Stage14 raw job upload log 相同。ZIP CRC 檢查無壞檔、**恰七件**：
1. `source.txt` = `79b159ab0a47ebfd2d95baf60bf5f41f2b60e17a`；
2. `perl-version.txt` = `v5.40.5`；
3. `syntax.stderr` = 模組與測試檔各一個 `syntax OK`（2/2）；
4. `test.stdout` = 285 TAP 通過、全部標記、`Result: PASS`；
5. `test.stderr` = 0 bytes；
6. `test.exit` = `0`；
7. `result.txt` = `STAGE14_NATIVE_PASS=1`。

## 結論與限制

**STAGE14 ACCEPTED；LAST_COMPLETED_STAGE 可設為 14。** Stage14 的正式目錄與獨立 BigInt 名稱選擇在該精確 source SHA 上通過 Native/CI 接受條件。不能將此結果延伸為完整五欄日曆產生器、sauce/askBowl 或 55 階段已完成。驗收文件本身及後續 Stage15 探索的 commit SHA 不另行繼承原始 SHA 的 Native PASS。無 main 變更、merge 或公開發佈。
