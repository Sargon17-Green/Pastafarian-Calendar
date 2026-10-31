# 第 6 階段 Native／CI 驗收紀錄（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。
**原始碼驗收 SHA**：`acaa979e4647312314dca204cf97df2032814157`（此報告後續文件提交的 HEAD 並非另一次 Native PASS）。
契約：`docs/STAGE_06_YEAR_OCCURRENCE_CONTRACT_2026-10-31.md`。
主流程：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211547558

## 完成的 CI 閘門

在建立驗收文件之前，分支 HEAD、流程的 `head_sha` 均確認為 `acaa979e4647312314dca204cf97df2032814157`。
push run `41211547558` 於 2026-10-31 14:55:27 UTC 更新為 `completed/success`，不是由空的 combined commit status 推論。
已取得兩頁共 153 個 jobs 的結果；下列**七個**必要 job 均為 `completed/success`：

| 必要 job | Job ID | Native／核查結果 |
| --- | ---: | --- |
| `verify` | `124567432065` | Canonical Names Lock 成功 |
| `perl-stage01` | `124567431933` | `Files=102, Tests=116476`；`Result: PASS` |
| `stage02-weaving-native` | `124567435610` | `Tests=261`；`Result: PASS` |
| `stage03-weaving-native` | `124567435602` | `Tests=288`；`Result: PASS` |
| `stage04-month-occurrence-native` | `124567435842` | `Tests=385`；`Result: PASS` |
| `stage05-cutlet-occurrence-native` | `124567435677` | `Tests=18891`；`Result: PASS`；6285 獨立日期位置 |
| `stage06-year-occurrence-native` | `124567435642` | `Tests=7031`；`Result: PASS`；6993 獨立日期位置 |

其他分支的矩陣工作被略過（`skipped`），不屬於本階段必需的七項工作。
已檢視七個工作各自的原始日誌；並未在相同 SHA 上重啟已成功的作業。

## 第 6 階段工件的獨立驗證

GitHub Actions 工件：`perl-stage06-year-occurrence-native`，ID `13046059234`：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41211547558/artifacts/13046059234

工件 ZIP 已實際下載並解壓，對全部七個檔案進行內容檢視；獨立計算 ZIP SHA-256：
`7983a92d7d85615127bd2a4e73c57c7ae1c72d7131f8c0e317be61d292ef7c3c`，
與 GitHub metadata `digest` 相符。

- `source.txt`：恰為 `acaa979e4647312314dca204cf97df2032814157`。
- `perl-version.txt`：`v5.40.5`，符合 Perl 5.40 以上。
- `syntax.stderr`：恰兩行，`YearOccurrence.pm syntax OK` 與 `t/51_stage06_year_occurrence.t syntax OK`。
- `test.exit`：`0`；`test.stderr`：0 bytes。
- `test.stdout`：7031 個 `ok`、0 個 `not ok`、`1..7031`、`Files=1, Tests=7031`、`Result: PASS`、`STAGE06_INDEPENDENT_DAY_POSITIONS=6993`。
- `result.txt`：`STAGE06_NATIVE_PASS=1`。

已直接檢視生產模組 `lib/Pastafari/Monster/YearOccurrence.pm` 與
`t/51_stage06_year_occurrence.t`：生產端逐筆驗證再用 closeGateDay 二分搜尋；
測試端不調用生產搜尋作 Oracle，而是展開長度 252、963、5778 的全部日期位置。
另測共享邊界、101 個連續年份的上限、非法輸入及 Math::BigInt 不變性。
6993 是獨立日期位置數，不是 7031 個獨立日期。

原生 job 日誌有 `timeout --signal=TERM --kill-after=5s 120s` 與
`ulimit -v 393216`，故執行受到 120 秒及 384 MiB **虛擬記憶體**的限制。
未量測 RSS 峰值，不能將虛擬記憶體上限誤寫成實測 RSS。

## 接受邊界和後續

**STAGE 6 ACCEPTED**，僅限於已提供、驗證過且相鄰之年份區間的年份編號投影。
此模組不產生 gate，不調用完整的 `calendarDate`，不生成 year5000／nextYear／previousYear，
也不獨立證明完整五欄日期；原生輸出本身明載 `STAGE06_FULL_CANONICAL_FIVE_FIELDS_NOT_VERIFIED`。

依契約可將 `LAST_COMPLETED_STAGE=5` 更新為 `6`，保留 `CURRENT_STAGE=6`。
此文件提交不含生產碼或測試變更，**不得把先前 SHA 的 Native PASS 歸因於新的文件 HEAD**。
不修改 main，不 merge，不對外發布。

NEXT：在 Perl+國語 分支進行 Stage7 DISCOVERY：直接參照本分支的
`calendarDate`、`buildYearStructure`、Stage4–6 模組及現有獨立測試；
選擇最小且可驗證的五欄整合切片，先立出輸入／輸出、獨立 Oracle、
共享邊界與非法參數、資源界限及 Stage7 Native／CI 閘門。
在未有具體新來源 SHA 的證據之前不得宣稱 Stage7 PASS。
