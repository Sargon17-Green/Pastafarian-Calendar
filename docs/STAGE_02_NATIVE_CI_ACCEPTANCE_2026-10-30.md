# 第 2 階段：Perl 原生差分驗收與第 3 階段規格缺口（2026-10-30）

專案：`PC-BRANCH-PERL-GUOYU`；工作分支：`Perl+國語`。
本文件只記錄已完成的第二階段小型交織排名原語；不表示五個日期分量已實作，亦未合併 main。

## 已核實的來源與結果

- 驗收來源提交（非本報告提交）：[`6d8fa9eee93c777e689f01dd52ff222ca3a7c10c`](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/6d8fa9eee93c777e689f01dd52ff222ca3a7c10c)，分支 `Perl+國語`。
- GitHub Actions [run 41090811928](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41090811928)：`completed/success`，確認 `head_sha` 為上述提交；`verify`、`perl-stage01`、`stage02-weaving-native` 三個必需 job 均 `success`。
- [Stage2 Native job 124183902177](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41090811928/job/124183902177)：原生 Perl **5.40.5**；`t/47_stage02_weaving_primitive.t` 的 **261/261** 個斷言依序成功（`Files=1, Tests=261, Result: PASS`）。測試同時包含獨立窮舉及測試專用規範 oracle 差分，另有輸入及錯誤邊界檢查。
- 既有整體測試 `perl-stage01`：**98 個測試檔，89,881 項測試**，`Result: PASS`（job 124183892630）；`verify` job 124183893066 亦成功。這是同一個來源 SHA 上的驗證，不是沿用第一階段先前成功紀錄。
- [原始 Artifact 12994251695](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41090811928/artifacts/12994251695)：完整 ZIP 已下載及獨立查核，ZIP SHA-256 為 `66e8ad4295a2dc911121fcfcd84d5574807ce5a43fc872f9c1fa2d30713d0334`，與上傳 job 記錄一致。六個檔案包括 `source.txt`、`perl-version.txt`、`test.stdout`、`test.stderr`、`test.exit` 及 `result.txt`；其中來源 SHA 一致，退出碼 `0`，stderr **0 bytes**，TAP 編號 `1..261` 無缺漏，結尾 `STAGE02_PRIMITIVE_NATIVE_PASS=1 DIFFERENTIAL=1`。
- 執行上限由成功 job 的實際執行命令確立：`ulimit -v 393216`（**384 MiB 虛擬位址空間限制**，非實測 RSS），`timeout --signal=TERM --kill-after=5s 120s`。原生測試在低於 1 秒的 TAP wallclock 下成功，沒有觸發超限。Artifact 沒有記錄峰值 RSS，因此不得捏造其數值。

## 驗收結論及狀態

依據 [Stage2 合約](STAGE_02_WEAVING_PRIMITIVE_CONTRACT_2026-10-30.md) 的既定功能、差分及資源閘門：**第 2 階段驗收 PASS**。因此 `DEVELOPMENT_STAGE.md` 的 `LAST_COMPLETED_STAGE` 更新為 `2`。`CURRENT_STAGE=2` 暫留，直到第 3 階段有可執行且明確的技術契約才啟動，避免把未定義的工作誤當成正在實施的階段。

## 第 3 階段：尚待實質設計決策

現有 Stage2 合約只確立「先獨立交織／排名原語，再實作日期語意」的方向，**沒有**定義下一階段的具體輸入、輸出、哪一個日期分量、資源邊界或驗收矩陣。下列互不等價的可行路線需要決定，不能從 Stage2 的小型上限 `m<=4, sum(L)<=12` 唯一導出：

1. 第 3 階段先擴充交織原語的可處理規模，再接入日期語意；
2. 第 3 階段先選定五個日期分量之中一個精確子功能，建立最小語意生產 API 及獨立差分。

需先確定其中一路、具體輸入輸出、語意契約、是否維持原語現有上限、同 SHA CI/Native/差分及資源驗收規則。這是**實質規格缺口**而非「等待形式上的開階段授權」。在規格確立前，NEXT 為完成此技術決策；不建立假定的 Stage3 程式或 PASS，亦不合併 main。
