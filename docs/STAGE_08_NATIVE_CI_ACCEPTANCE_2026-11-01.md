# 第 8 階段 Native／CI 驗收紀錄（2026-11-01）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。

**已驗收的來源 SHA**：`69a74d0fdfb52c3b3b2575cbb4288ac95b5a195e`。
契約：[`docs/STAGE_08_MONTH_LENGTH_GENERATION_CONTRACT_2026-11-01.md`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/69a74d0fdfb52c3b3b2575cbb4288ac95b5a195e/docs/STAGE_08_MONTH_LENGTH_GENERATION_CONTRACT_2026-11-01.md)。
CI：[run 41282895067](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41282895067)，push、attempt 1、branch `Perl+國語`、`head_sha=69a74d0fdfb52c3b3b2575cbb4288ac95b5a195e`，`completed/success`。
獨立確認本分支在驗收前 HEAD 正是來源 SHA。此文件的後續提交 **不是** 新一輪 Native 驗收，不重跑已通過的原來源 SHA。

## 同來源九項必要工作

GitHub REST 分頁 `per_page=100`：155 個 jobs（第 1 頁 100、第 2 頁 55），以下九項均為 `completed/success`。未指定的矩陣項目 `skipped` 不構成本階段必要工作。

| 工作 | Job ID | 結果與日誌 |
| --- | ---: | --- |
| `verify` | 124778256379 | success，canonical name lock |
| `perl-stage01` | 124778256496 | success，Files=104, Tests=132290，Result: PASS |
| `stage02-weaving-native` | 124778259493 | success，229 TAP，Result: PASS |
| `stage03-weaving-native` | 124778259356 | success，288 TAP，Result: PASS |
| `stage04-month-occurrence-native` | 124778259373 | success，Result: PASS |
| `stage05-cutlet-occurrence-native` | 124778259308 | success，18891 TAP，Result: PASS |
| `stage06-year-occurrence-native` | 124778259375 | success，7031 TAP，Result: PASS |
| `stage07-five-field-native` | 124778259425 | success，Result: PASS |
| `stage08-month-length-generation-native` | 124778259319 | success，7125 TAP，Result: PASS |

九份 logs 已直接讀取，不以 workflow 的整體 success 取代查證工作層級。Stage8 的工作日誌直接顯示 `timeout --signal=TERM --kill-after=5s 120s` 與 `ulimit -v 393216`（384 MiB 的 **虛擬位址空間** 上限，לא peak RSS 測量）。

## Stage8 工件真實檢驗

[Artifact 13073787264](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41282895067/artifacts/13073787264)：`perl-stage08-month-length-generation-native`，36,494 bytes。直接下載 ZIP，獨立重新計算 SHA-256，並以 ZipFile 檢驗 CRC（無錯誤）：
`64ee6e357d86c1a5f0d7e4da2417f98d697c84c15167f197a302ed12bb036031`。
此值與 Stage8 job upload 的 ZIP digest 完全相符。

恰七個 ZIP 成員：
- `source.txt`：`69a74d0fdfb52c3b3b2575cbb4288ac95b5a195e`；
- `perl-version.txt`：`v5.40.5`（符合 5.40+）；
- `syntax.stderr`：恰兩項 `syntax OK`，`MonthLengthGeneration.pm` 及 `t/53_stage08_month_length_generation.t`；
- `test.exit`：`0`；
- `test.stderr`：0 bytes；
- `test.stdout`：`1..7125`、`All tests successful.`、`Files=1, Tests=7125`、`Result: PASS`、`STAGE08_INDEPENDENT_ENUMERATED=7021`、`STAGE08_INDEPENDENT_BIGINT_CASES=15`、`STAGE08_FULL_GENERATOR_NOT_VERIFIED`；
- `result.txt`：`STAGE08_NATIVE_PASS=1`。

本 stage 工作耗時 14 wallclock secs，通過 120 秒上限；384 MiB 為配置限制而非可聲稱的測量記憶體實際使用量。警告 cache path / Node.js deprecated 為非阻塞性，亦不同於 空白的 `test.stderr`.

## 接受範圍與 NEXT

**STAGE 8 ACCEPTED**：`Pastafari::Monster::MonthLengthGeneration::month_length_family` 的有界合法月份長度組合生成、精確 BigInt 計數、字典序一基 unrank、獨立窮舉、容斥公式與邊界驗證已依原契約通過 Native／CI。只允許把 `LAST_COMPLETED_STAGE` 自 7 改為 8。

尚未驗收完整 `buildYearStructure`、cutlet 分割生成、months weaving、`calendarDate`、`year5000`、跨年運算、完整五欄輸出生成、或本曆法完整 55 階段。

**NEXT**：Stage9 discovery，聚焦 cutlet partition generation；先按現有同分支規範演算法界定一個有界、自主可驗證的實際生成切片（參數、分布、順序、BigInt、非法輸入、獨立 oracle、Native/CI 閘門），再進行實作；不得由 Stage8 的成功推論完整年份生成已驗收。

未進行 main／merge／公開發佈；未重跑已通過的原 SHA CI。
