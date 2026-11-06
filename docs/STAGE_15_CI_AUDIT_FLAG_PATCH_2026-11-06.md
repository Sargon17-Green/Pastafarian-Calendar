# 第十五階段 CI 稽核狀態旗標修復（2026-11-06）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。本修復不更動 Stage15 生產模組、獨立 oracle、測試內容、工作流程或先前驗收紀錄。

## 已確認的同源失敗

Canonical push run：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173838731

原始 source SHA：`c6cf720e250d943cc74c75e61f87098161522cd4`；event=push；status=completed；conclusion=failure；attempt=1。分頁核對共 162 jobs：16 個必需 jobs 中，15 completed/success，只有 `perl-stage01`（job 127747623450）completed/failure；其餘 146 skipped。直接讀取該失敗 job 與 Stage15 job 127747629849 的原始日誌；未把其餘 14 份日誌視為已逐一審核。

`perl-stage01` 的完整測試摘要：`Files=111, Tests=195226, Result: FAIL`，唯一失敗測試檔為 `t/05_language_and_isolation_audit.t`，第 8 項 `沒有修改 Git 歷史`；此項依據 `^GIT_HISTORY_MUTATED=NO$` 驗證，但 Stage15 來源階段標記意外寫為 `GIT_HISTORY_MUTATED=YES`。這是已重現的階段狀態契約違反，不是 Stage15 計算 oracle 反例。

Stage15 專屬 Native job 127747629849 completed/success：Perl 5.40.5；syntax 2/2；`Files=1, Tests=14320, Result: PASS`；獨立展開日 6993、日比較 1585、串流邊界組態 24、非法案例 28；stderr 空、exit 0，明確保留完整生成器尚未驗證的限制。原始 ZIP 產物：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173838731/artifacts/13481634504 ，48,022 bytes，provider SHA256 與上傳日誌一致：`2c12b55b28d62fa057e038108a8b155fae3708b516932ad99c517eb21bad9461`。本次尚未獨立下載驗證 ZIP 位元組、CRC 及七件內容，故不能聲稱 Stage15 整體 Native 驗收完成。

## 最小修復與隔離測試

原始 Stage15 commit `c6cf720e250d943cc74c75e61f87098161522cd4` 之唯一父提交為 `787ebc7945da24d04a75c7fc39786e965f17bd70`；父提交的狀態標記為 `GIT_HISTORY_MUTATED=NO`。正常追加提交不是重寫既有 Git 歷史；未見需要把此旗標改為 YES 的事實。僅恢復 `DEVELOPMENT_STAGE.md` 一行為 `GIT_HISTORY_MUTATED=NO`，保留 `GITHUB_ACTIONS_PERFORMED=YES`、`LAST_COMPLETED_STAGE=14`、`CURRENT_STAGE=15` 和其餘內容。

在 Perl 5.40.1 的隔離合成 fixture 中，使用與精確來源相同的 `t/05_language_and_isolation_audit.t` 程式碼，逐案執行五種狀態：
- 舊 `GIT_HISTORY_MUTATED=YES`：第 8 項失敗，exit 1；
- 修正為 `NO` 且有既有 Stage14 CI 驗收 URL、產物 URL 及 source SHA 證據：8/8，exit 0；
- 刪除 CI 接受紀錄：預期失敗，exit 1；
- 非法歷史旗標 `BAD`：預期失敗，exit 1；
- 合法 `GITHUB_ACTIONS_PERFORMED=NO` 與 `GIT_HISTORY_MUTATED=NO`：8/8，exit 0。

五項預期均符合；這是合成 fixture 的有界稽核回歸測試，不是整個實際 checkout、Stage15 Native 或全套 CI 重新通過的證明。

## 後續接受條件

在修復後的新 branch source SHA 上，檢查 canonical push run 完成後的結論；逐一查閱全部 16 份必需 job 原始日誌，要求 16/16 completed/success；Stage01 全套 PASS，Stage15 14320 TAP 與獨立測試標記一致、syntax 2/2、stderr 0、exit 0、Perl 5.40+、120 秒及 384MiB 虛擬位址空間限制。下載新 SHA 的 Stage15 七件 ZIP，核驗 provider/upload/local SHA256、CRC、七件名稱及內容、source.txt 精確相等。滿足全部證據後才可記錄 Stage15 ACCEPTED、更新 `LAST_COMPLETED_STAGE=15`。原始失敗 source 的成功 Stage15 單一 job 不能取代新 source 的驗收。

不得聲稱完整五欄年度生成器、sauce 或 askBowl 已驗收；不得更改 main、merge 或公開發佈。
