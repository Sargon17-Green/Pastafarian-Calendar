# 第 4 階段 Native／CI 驗收紀錄（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；分支：`Perl+國語`。
驗收**只針對原始程式提交** `bd0de67daeb8569a62006c7be11009979bc32752`，不是本驗收文件提交的新 SHA。
契約：`docs/STAGE_04_MONTH_OCCURRENCE_CONTRACT_2026-10-31.md`。
主流程：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41186935117

## 來源與工作確認

GitHub 分支的來源 HEAD 與主流程 head_sha 均為 `bd0de67daeb8569a62006c7be11009979bc32752`。
流程 `41186935117`：`completed/success`，2026-10-31 09:20:29 UTC 更新。
逐一檢查同一流程的必需工作，均為 `completed/success`：

| 工作 | job ID | 核驗結果 |
| --- | ---: | --- |
| `verify` | `124495653765` | Canonical Names Lock 成功 |
| `perl-stage01` | `124495653513` | `Files=100, Tests=90554`；`Result: PASS`；`t/05` 語言隔離及 `t/49` 均通過 |
| `stage02-weaving-native` | `124495657116` | `Tests=261`；`Result: PASS` |
| `stage03-weaving-native` | `124495657178` | `Tests=288`；`Result: PASS` |
| `stage04-month-occurrence-native` | `124495657141` | `Tests=385`；`Result: PASS` |

其他不適用於本分支的矩陣工作 `skipped`，並非本契約的必要工作。

## Stage4 獨立工件核驗

工件 `perl-stage04-month-occurrence-native`，ID `13037536925`：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41186935117/artifacts/13037536925

已實際下載 ZIP、開啟全部七個檔案並獨立重算 ZIP SHA-256：
`12b36d62278ec1d1a0ad2a7acf62a1ed210f5517ddac5c2cc37fb971af308c0d`。
此值等於 GitHub 工件 metadata 及上傳日誌的 digest。
`source.txt` 為 `bd0de67daeb8569a62006c7be11009979bc32752`；
`perl-version.txt` 為 `v5.40.5`；
`syntax.stderr` **恰好兩行**，分別確認生產模組及 `t/49` 測試檔 `syntax OK`；
`test.exit` 為 `0`；
`test.stderr` 為 **0 bytes**；
`test.stdout` 確認 `Files=1, Tests=385`、`All tests successful.` 及 `Result: PASS`。

原始 job log 證明執行 `timeout --signal=TERM --kill-after=5s 120s`
及 `ulimit -v 393216`，後者限制虛擬記憶體至 384 MiB；
未量測峰值 RSS，不能把 VSZ 限額當成 RSS 數值。
Stage4 測試單獨執行、無非零 `stderr`，並有 `STAGE04_MONTH_OCCURRENCE_NATIVE_PASS` 標記。
其他 jobs 分別另行上傳 Stage2 與 Stage3 工件，並於原始 log 顯示成功。

## Oracle、驗收範圍與限制

直接閱讀 `t/49_stage04_month_occurrence.t`：
小型案例 oracle 以固定基數完整枚舉字串，再於完整字串核對月份數、首次與末次出現順序；
前綴次數及月份索引不取自生產 DP 或 `unrank_weaving`。
同時覆蓋非法輸入、不可變性、獨立 BigInt 回傳及 24 日的有界端點。
數字 `385` 是整支 Stage4 TAP 測試斷言總數，不應表述為 385 個獨立完整字串。
24 日大案例僅檢查指定邊界，不是全年或完整五欄日期的獨立 oracle。

本次接受的是**有界月份索引與月內日數局部投影**，不是五欄全曆、
47 月全年、長期 soak 或無限 BigInt 規模的正確性證明。
`verify` 與所有必需回歸門檻成功，故 **STAGE 4 ACCEPTED**。
可將 `LAST_COMPLETED_STAGE` 由 `3` 更新為 `4`；
`CURRENT_STAGE` 暫留 `4`，等待 Stage5 的獨立需求發現與合約。
此文件和狀態變更本身不宣稱有新的原始程式 Native 測試；
沒有更動 main、merge 或對外發布。

下一步：直接核對本分支的 `t/lib/Pastafari/NormativeScroll.pm` 與五欄介面，
為 Stage5 挑選一個尚未實作、可量測的局部日期語義，
定義輸入／輸出、獨立 oracle、邊界與受控資源；確定契約後再實作。
