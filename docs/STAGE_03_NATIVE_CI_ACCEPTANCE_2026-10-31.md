# 第 3 階段 Native／CI 驗收紀錄（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；工作分支：`Perl+國語`。
驗收對象**僅**為來源提交 `c01fccf4435c8f3e2a32ec36090a89a754ef116f`，不把本驗收文件提交本身視為重新測試過的程式版本。
原始契約：`docs/STAGE_03_WEAVING_BOUNDED_EXTENSION_CONTRACT_2026-10-31.md`。
流程：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41136371365

## 同來源 SHA 的完整作業結果

2026-10-30 22:22:20 UTC：run `41136371365` 已 `completed/success`，其 `head_sha` 為 `c01fccf4435c8f3e2a32ec36090a89a754ef116f`，`head_branch` 為 `Perl+國語`。四個必需工作皆 `completed/success`：

| 作業 | job ID | 觀察結果 |
|---|---:|---|
| `verify` | 124339722143 | Canonical names lock 檢驗成功 |
| `perl-stage01` | 124339721751 | `Files=99, Tests=90169`；`All tests successful`、`Result: PASS` |
| `stage02-weaving-native` | 124339730486 | `Files=1, Tests=261`；`Result: PASS` |
| `stage03-weaving-native` | 124339730555 | `Files=1, Tests=288`；`Result: PASS` |

其他不適用於此分支、條件未符合的矩陣工作標記 `skipped`；它們不是本階段的必需驗收工作。

## Stage3 執行及證據

GitHub Actions 使用 Perl 5.40.5。單獨的 Stage3 測試 `t/48_stage03_weaving_extended.t` 在 3 秒 wallclock 完成，288 條 TAP 斷言全部通過，`STAGE03_EXTENSION_NATIVE_PASS=1 INDEPENDENT_SMALL=1 CATALAN=1 LARGE_ROUNDTRIP=1`。

Stage3 作業設定 `timeout --signal=TERM --kill-after=5s 120s` 和 `ulimit -v 393216`，後者是 **384 MiB 虛擬記憶體上限**，不是 RSS 峰值量測。執行腳本記錄 `test.exit` 並要求退出碼 0、`test.stderr` 為空；工作成功，先前於追蹤器的實際 ZIP 檢查也記錄 `test.exit=0`、stderr 0 bytes。本輪從原始 job log 再核對了限制、TAP 和作業完成情況。

Artifact：`perl-stage03-weaving-native`，ID `13016577255`，包含 `source.txt`、`perl-version.txt`、`test.stdout`、`test.stderr`、`test.exit`、`result.txt`。Workflow upload log 顯示 ZIP SHA-256：
`aadb720c7984059b29b9a3178fc70ffb3173ccb9a8eabc93d8e4ad289292a033`；追蹤器記錄此前已獨立下載和核對該值，**本輪沒有再下載 ZIP 作第二次雜湊測量**。
網址：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41136371365/artifacts/13016577255

Stage2 回歸 artifact ID `13015743376`，upload ZIP SHA-256 `3bf60ff5677304ee5fbe1bede01af4a294892558d9bbfc73d6b8f08445c133d0`（來自上傳日誌；本輪未獨立重算）。

## Oracle 品質與限制

已直接讀取 `t/48_stage03_weaving_extended.t`：獨立 oracle 以多重集合的全部無重複排列作輸入，不利用生產 DP 的局部剪枝，在完整字串完成後才檢查每個月份索引的首次及末次出現順序，然後比較總數、每個有效字串的排名和反排名。測試集包括 `[2,2,2,2,2]`、`[2,2,2,1,1,1]`、`[3,2,2,1,1,1]`（窮舉部分合計長度最多 10）。六個長度為二的月份以 Catalan 數 `C6=132` 做獨立代數錨點及 132 個往返排名。24 天大案例只檢查首／中／末的雙向一致、輸入不可變與上下界，**沒有**宣稱大案例已獨立窮舉。

本驗收覆蓋 `1 <= 月數 <= 6`、總天數最多 24 的獨立交織原語；**不**證明日曆的五個日期分量、全年計算、47 個月份或無界 BigInt 工作量之正確性。Workflow 的普通 Node/action deprecation/cache 警告沒有導致測試 stderr 非空；不能與 Perl 的受檢 `test.stderr` 混為一談。

## 結論及後續

原始 SHA 上的契約 Native／CI 接受條件全部完成：**STAGE 3 ACCEPTED**。
`DEVELOPMENT_STAGE.md` 的 `LAST_COMPLETED_STAGE` 可由 2 改為 3，`CURRENT_STAGE` 留在 3。本文件和狀態欄位屬驗收紀錄提交，不重新主張對新提交執行 CI。**沒有**執行 main merge 或發布。

下一實質步驟：依本專案五分量權威契約，展開下一階段的需求發現與測試界定；先確定 Stage4 所需的精確輸入、輸出、來源獨立 oracle 和資源上限，才可按契約實作。此步驟不代表 Stage4 已開始或通過。
