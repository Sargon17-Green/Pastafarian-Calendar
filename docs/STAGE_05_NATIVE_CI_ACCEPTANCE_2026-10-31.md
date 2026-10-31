# 第 5 階段 Native／CI 驗收紀錄（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；專屬分支：`Perl+國語`。
**本次驗收的原始碼 SHA**：`28882a8b1f037087068d34f66cf3796024b9631b`，不是本報告提交的後續文件 SHA。
契約：`docs/STAGE_05_CUTLET_OCCURRENCE_CONTRACT_2026-10-31.md`。
主流程：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196148045

## CI、原始碼及工作證據

分支 HEAD 與流程的 `head_sha` 均為 `28882a8b1f037087068d34f66cf3796024b9631b`（驗收前確認）。
流程 `41196148045` 的狀態為 `completed/success`，更新於 2026-10-31 11:55:59 UTC；
此流程為首次提交觸發的 push 流程，沒有重複執行先前通過的 SHA。
檢查共 152 個 job（API 分頁），以下六個本分支的必要工作均為 `completed/success`：

| 工作 | Job ID | 驗收證據 |
| --- | ---: | --- |
| `verify` | `124522597566` | Canonical Names Lock 成功 |
| `perl-stage01` | `124522597360` | `Files=101, Tests=109445`；`Result: PASS` |
| `stage02-weaving-native` | `124522600983` | `Tests=261`；`Result: PASS` |
| `stage03-weaving-native` | `124522601055` | `Tests=288`；`Result: PASS` |
| `stage04-month-occurrence-native` | `124522600893` | `Tests=385`；`Result: PASS` |
| `stage05-cutlet-occurrence-native` | `124522601014` | `Tests=18891`；`Result: PASS`；獨立逐日展開位置 `6285` |

未啟用的其他矩陣工作為 `skipped`，不屬於本階段必需工作。

## Stage5 原生工件：實際下載、解壓及校驗

工件：`perl-stage05-cutlet-occurrence-native`，ID `13041986194`：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196148045/artifacts/13041986194

已下載 ZIP 並檢查其中全部七個檔案；獨立計算 ZIP SHA-256 為
`8ebf5a8282bc98b3e95336ab503c90577f3fd1186b62f00b9ccbca3b957f93a8`，
等於 GitHub 工件 metadata 的 digest 及上傳日誌的 digest。

- `source.txt`：`28882a8b1f037087068d34f66cf3796024b9631b`。
- `perl-version.txt`：`v5.40.5`，符合 Perl >=5.40。
- `syntax.stderr`：恰有兩行，分別是模組 `CutletOccurrence.pm syntax OK` 與測試 `t/50_stage05_cutlet_occurrence.t syntax OK`。
- `test.exit`：`0`；`test.stderr`：0 bytes。
- `test.stdout`：`1..18891`、`All tests successful.`、`Files=1, Tests=18891`、`Result: PASS`，以及 `STAGE05_INDEPENDENT_DAY_POSITIONS=6285`。
- `result.txt`：`STAGE05_NATIVE_PASS=1`。

Native job 日誌證明執行 `timeout --signal=TERM --kill-after=5s 120s` 與
`ulimit -v 393216`（虛擬記憶體上限 384 MiB）；本次**未量測峰值 RSS**，
不得把虛擬記憶體限制解釋成 RSS 實測數字。

## Oracle 的獨立性、覆蓋率與限制

已直接檢查 `t/50_stage05_cutlet_occurrence.t` 與正式模組。
測試的期望結果透過把每一段長度**逐日展開**成位置、段序與日序產生，
而生產原語以累積段界定位。測試使用 frozen 名稱目錄映射及固定名稱錨點，
沒有用受測原語產生自己的期望結果，也沒有調用完整 `calendarDate`。
三組配置的 252、5778、255 個位置共 6285 個獨立位置，
各測試段索引、名稱與段內日序；另測試轉換邊界、BigInt、
輸入及輸出不可變性與非法輸入拒絕。
`18891` 是 TAP 斷言總數，不是 18891 個獨立日期。

**接受範圍**：僅為接收已給定段長及名稱索引時，
有界的肉排名稱／肉排內日數局部投影。
沒有證明這些輸入可由規範的 gate 演算法產生；
沒有完整五欄日期計算的通過證據，沒有全年或長期 soak，
也沒有宣稱 55 階段完成。

全部六個必要 CI 工作通過，工件與來源 SHA 相符，因此
**STAGE 5 ACCEPTED**。
`LAST_COMPLETED_STAGE` 可由 `4` 更新為 `5`，
`CURRENT_STAGE` 暫留 `5`，直到下一階段的獨立契約及實作開始。
本報告及狀態更新僅為文件變更，不代表新文件 SHA 的另一次 Native PASS。
不更動 main，不 merge，不對外發布。

下一步：只針對 `Perl+國語` 檢視規範的 `calendarDate` 五欄結構及
已有 Stage2–5 的局部語意，選擇 Stage6 尚未實作的、可測量語意；
提出獨立輸入／輸出、oracle、非法邊界、資源限額與驗收門檻。
