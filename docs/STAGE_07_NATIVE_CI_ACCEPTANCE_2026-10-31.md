# 第 7 階段 Native／CI 驗收紀錄（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。
**已驗收的來源 SHA**：`4619e3a325d78551cef398b9db2981122e69d295`。
契約：[`docs/STAGE_07_MATERIALIZED_FIVE_FIELD_CONTRACT_2026-10-31.md`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/4619e3a325d78551cef398b9db2981122e69d295/docs/STAGE_07_MATERIALIZED_FIVE_FIELD_CONTRACT_2026-10-31.md)。
CI：[run 41239102183](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41239102183)，push、attempt 1、branch `Perl+國語`、head_sha 符合；`completed/success`，updated_at `2026-10-31T21:08:28Z`。
本次寫入文件後的新 HEAD 並**不是**另一個受驗收的原始碼 SHA，未重跑已通過的 CI。

## 八項必要驗收工作

兩頁 GitHub REST jobs 合計 154 件；以下八項均為 `completed/success` 且 head_sha 等於上述 SHA。
其他矩陣項目不構成此階段的必要工作。

| 工作名稱 | Job ID | 已閱讀的日誌證據 |
| --- | ---: | --- |
| `verify` | 124649040488 | 名稱鎖驗證成功 |
| `perl-stage01` | 124649040299 | `Files=103, Tests=125165`，`Result: PASS` |
| `stage02-weaving-native` | 124649044369 | `Tests=261`，`Result: PASS` |
| `stage03-weaving-native` | 124649044191 | `Tests=288`，`Result: PASS` |
| `stage04-month-occurrence-native` | 124649044287 | `Tests=385`，`Result: PASS` |
| `stage05-cutlet-occurrence-native` | 124649044278 | `Tests=18891`，`Result: PASS` |
| `stage06-year-occurrence-native` | 124649044297 | `Tests=7031`，`Result: PASS` |
| `stage07-five-field-native` | 124649044334 | `Tests=8689`，`Result: PASS`，`STAGE07_NATIVE_PASS=1` |

七個測試日誌與 verify 日誌已讀取；不以整個 workflow 成功取代細部確認。

## Stage 7 工件的獨立檢驗

[工件 13057244629](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41239102183/artifacts/13057244629)：
`perl-stage07-five-field-native`，ZIP 25,573 bytes。已實際下載及在獨立容器內開啟，ZIP CRC 檢驗成功。
本地重新計算 SHA-256：
`73b62e4760e452a826557eff596b5811b04ed2424b9df3b49e38848320e29ef4`。
與 GitHub Actions 上傳日誌列出的 SHA-256 完全相同。

解包恰好七個檔案：
- `source.txt`：`4619e3a325d78551cef398b9db2981122e69d295`。
- `perl-version.txt`：`v5.40.5`（符合最低 5.40）。
- `syntax.stderr`：恰兩行，模組及 `t/52_stage07_five_field_projection.t` 均 `syntax OK`。
- `test.exit`：`0`；`test.stderr`：空。
- `test.stdout`：`1..8689`、`All tests successful.`、`Files=1, Tests=8689`、`Result: PASS`、`STAGE07_INDEPENDENT_EXPANDED_POSITIONS=6993`、`STAGE07_INDEPENDENT_COMPARED_POSITIONS=1438`。
- `result.txt`：`STAGE07_NATIVE_PASS=1`。

工作日誌證明以 `ulimit -v 393216` 限制 384 MiB **虛擬位址空間**、以 `timeout --signal=TERM --kill-after=5s 120s` 限制 120 秒；測試實際報告 4 wallclock secs。沒有測量 peak RSS，不能聲稱 384 MiB 為已測量實際 RAM 用量。
警告 `Node.js 20 deprecated`、cache 不存在並未令本次必要工作失敗，與 Stage7 測試 stderr 為空不是同一回事。

## 接受範圍與後續

**STAGE 7 ACCEPTED**：在已外部具體化且合法的年度結構上，Perl 產生的五欄
`[yearNumber, cutletName, dayInCutlet, monthName, dayInMonth]`
通過契約的正反例及獨立日期擴展 Oracle。
此一結果 **不等於** 完整 `calendarDate`、`buildYearStructure`、`year5000`、`nextYear`、`previousYear`、`sauce`、全長織序排名／反排名或完整曆法生成器通過驗收。Stage4 的 24 日上限沒有擴展至完整年長。

因此 `LAST_COMPLETED_STAGE` 可由 6 改為 7；保留 `CURRENT_STAGE=7`，另立下階段的契約前不得聲稱 Stage8 已通過。
**NEXT**：Stage8 discovery：依本分支之 `calendarDate` 與 `buildYearStructure` 現有實際程式，選擇第一個有界、可獨立驗證的年度結構生成切片，界定輸入／輸出、獨立 oracle、錯誤案例、BigInt 邊界及 Native/CI 閘門。不得將 Stage7 的已提供結構假設偷換成完整生成證明。

沒有 main／merge／公開發布，沒有重跑已通過之同 SHA CI。
