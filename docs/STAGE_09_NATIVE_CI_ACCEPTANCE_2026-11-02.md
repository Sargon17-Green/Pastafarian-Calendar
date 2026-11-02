# 第 9 階段 Native／CI 驗收紀錄（2026-11-02）

專案：`PC-BRANCH-PERL-GUOYU`；工作分支：`Perl+國語`。本紀錄只接受有界肉排區間分割生成切片，不代表完整曆法生成器驗收。

**驗收來源 SHA**：`f721156edd1b949980e00312b68f627a0cbe98de`。
契約：[`STAGE_09_CUTLET_PARTITION_GENERATION_CONTRACT_2026-11-01.md`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/f721156edd1b949980e00312b68f627a0cbe98de/docs/STAGE_09_CUTLET_PARTITION_GENERATION_CONTRACT_2026-11-01.md)。
CI：[`41354776711`](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41354776711)，`push`、attempt 1、`head_branch=Perl+國語`、`head_sha=f721156edd1b949980e00312b68f627a0cbe98de`、`completed/success`；最後更新 2026-11-01T22:07:16Z。驗收時已重新讀取分支 HEAD，與來源 SHA 相同。

## 同源必要工作：10／10 成功

使用 GitHub Actions jobs REST 分頁（每頁 100，合計 156 個 jobs）檢核，每個必要 job 均為 `completed/success`。另外 146 個非必要矩陣 job 為 `skipped`，不視為失敗，也不冒充已執行。

| 必要工作 | Job ID | 狀態 |
| --- | ---: | --- |
| `verify` | 124992406336 | success |
| `perl-stage01` | 124992406547 | success |
| `stage02-weaving-native` | 124992410444 | success |
| `stage03-weaving-native` | 124992410466 | success |
| `stage04-month-occurrence-native` | 124992410471 | success |
| `stage05-cutlet-occurrence-native` | 124992410578 | success |
| `stage06-year-occurrence-native` | 124992410484 | success |
| `stage07-five-field-native` | 124992410474 | success |
| `stage08-month-length-generation-native` | 124992410439 | success |
| `stage09-cutlet-partition-native` | 124992410457 | success |

前一次獨立查核已讀取 `verify` 與 Stage02..09 的九份完成日誌；本輪重新讀取先前未完成的 `perl-stage01` 日誌以及 Stage09 日誌，並直接查核本次 run 與全部必要 jobs 結果。`perl-stage01` 日誌包含 `All tests successful.`、`Files=105, Tests=147863`、`Result: PASS`；五組有界 smoke profile 均 PASS。此數據不可替代 Stage09 專門測試。

## Stage09 專門 Native 證據

[Artifact 13102717371](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41354776711/artifacts/13102717371)：`perl-stage09-cutlet-partition-native`。前一次已直接下載原始 ZIP（41,938 bytes），獨立重新計算 SHA256 並檢查 ZIP CRC 與七個成員；該結果本輪沿用，不宣稱重複下載。ZIP SHA256：
`2c9afb9a805c75cc40bbc9e115ea021bb79988c5f2ba16e207018f2b5e98f109`。
此摘要同時吻合 GitHub artifact metadata 與本輪重新讀取之 Stage09 upload job 日誌。

原七項證據：`source.txt`（來源 SHA 完整相符）、`perl-version.txt`（v5.40.5）、`syntax.stderr`（模組與測試 2/2 syntax OK）、`test.stdout`、`test.stderr`（空）、`test.exit`（0）、`result.txt`（`STAGE09_NATIVE_PASS=1`）。

Stage09 完整日誌確認 `1..15573`、`Files=1, Tests=15573`、`Result: PASS`，以及獨立測試標記：
- `STAGE09_INDEPENDENT_ENUMERATED=15048`；
- `STAGE09_INDEPENDENT_FAMILIES=170`；
- `STAGE09_LARGE_RANK_CASES=24`；
- `STAGE09_FULL_GENERATOR_NOT_VERIFIED`。

測試依契約以 Perl 5.40+、120 秒 timeout、384 MiB 虛擬位址空間上限執行；不能將虛擬記憶體限制誤寫成實際 peak RSS。upload cache 路徑與 Node.js deprecation 警告未改變測試成功與 test.stderr 空白的事實。

## 驗收決定與 NEXT

**STAGE 9 ACCEPTED**：只限 `Pastafari::Monster::CutletPartitionGeneration::cutlet_partition_family` 在契約界限 G=6..137、K=6..17、可選指定內部切點下的精確組合總數、字典序一基拆分、BigInt、非法輸入、輸入不變性，以及獨立 oracle 覆核。允許 `LAST_COMPLETED_STAGE` 由 8 更新為 9；隨附 commit 僅含本報告與 `DEVELOPMENT_STAGE.md`，不把報告 commit 當成新一輪 Native 測試。

**尚未驗收**：完整 `buildYearStructure`、年度聯合生成與全部五日期欄位、`calendarDate`、`year5000` 或整體 55 階段。

**NEXT**：以已接受的 Stage01..09 為依據，在本分支展開 Stage10 的規範來源探索，選定未覆蓋的最小獨立生成切片；先訂立可量測契約（輸入、輸出、精確排序、邊界、獨立 oracle、Native/CI gate），再實作與測試。不得複製另一語言分支的演算法或冒稱完整日期生成已驗收。

無 main、merge、發佈；原來源 SHA 的已通過 CI 不再重新派送。
