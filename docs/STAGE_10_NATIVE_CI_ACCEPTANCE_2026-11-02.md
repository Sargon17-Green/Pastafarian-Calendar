# 第 10 階段 Native／CI 驗收紀錄（2026-11-02）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。本文件僅驗收有界「不重複名稱索引序列」生成器，**並非完整五日期欄位或全曆法生成器驗收**。

## 來源與同源 CI

- **驗收來源 SHA**：`ceec4aeffc26c741a855c0111cf08348754682f3`；驗收前重新讀取分支 HEAD，與來源完全一致。
- 契約：[STAGE_10_DISTINCT_NAME_ASSIGNMENT_CONTRACT_2026-11-02.md](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/ceec4aeffc26c741a855c0111cf08348754682f3/docs/STAGE_10_DISTINCT_NAME_ASSIGNMENT_CONTRACT_2026-11-02.md)。
- 同源 canonical push run：[41503658663](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41503658663)；attempt=1、head_branch=`Perl+國語`、head_sha 完全相符、`completed/success`；更新於 2026-11-02T18:57:34Z。
- GitHub REST jobs 以每頁 100 筆分兩頁檢查：總計 157 項，**11/11 必要 jobs completed/success**；其餘 146 項矩陣 jobs skipped，沒有誤算為成功。

| 必要工作 | Job ID | 結果 |
| --- | ---: | --- |
| verify | 125477275928 | success |
| perl-stage01 | 125477275302 | success |
| stage02-weaving-native | 125477285116 | success |
| stage03-weaving-native | 125477285389 | success |
| stage04-month-occurrence-native | 125477285700 | success |
| stage05-cutlet-occurrence-native | 125477285338 | success |
| stage06-year-occurrence-native | 125477285474 | success |
| stage07-five-field-native | 125477285410 | success |
| stage08-month-length-generation-native | 125477285438 | success |
| stage09-cutlet-partition-native | 125477285431 | success |
| stage10-distinct-name-native | 125477285265 | success |

已直接讀取全部 11 個必要 job 日誌。主 `perl-stage01`：`Files=106, Tests=164119`、`Result: PASS`，五組 smoke profile PASS。Stage02..09 日誌分別有獨立測試通過證據；Stage10 並非僅依 job 狀態推論。

## Stage10 Native 原始 artifact 核驗

[Artifact 13170641173](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41503658663/artifacts/13170641173)，名稱 `perl-stage10-distinct-name-native`。直接下載 ZIP：**42,377 bytes**，獨立計算 SHA-256：
`bf3f7dbac8e187dedfee0820f1e9a81c40bee1d088b27bc079bd36e1bcb8cf08`。

此雜湊與 GitHub artifact metadata 及 Stage10 upload job 日誌完全相符。ZIP CRC 全部通過，恰有七個檔案：
- `source.txt` = `ceec4aeffc26c741a855c0111cf08348754682f3`；
- `perl-version.txt` = `v5.40.5`；
- `syntax.stderr`：模組和測試各 `syntax OK`（2/2）；
- `test.stdout`：`1..16256`、`Files=1, Tests=16256`、`Result: PASS`、`All tests successful.`；
- `test.stderr`：零位元組；
- `test.exit`：`0`；
- `result.txt`：`STAGE10_NATIVE_PASS=1`。

`test.stdout` 另有 `STAGE10_INDEPENDENT_ENUMERATED=16064`、`STAGE10_INDEPENDENT_FAMILIES=28`、`STAGE10_LARGE_RANK_CASES=20`，分別代表逐排名回溯比較、有限家族數、17/47 名稱目錄的獨立逆向排名檢核。Native log 顯示 `ulimit -v 393216` KiB 與 `timeout ... 120s`，Perl v5.40.5；4 秒的測試總牆鐘時間。不應將 VSZ 限制誤當成 peak RSS。

## 驗收結論及 NEXT

**STAGE 10 ACCEPTED**：只限 `Pastafari::Monster::DistinctNameAssignment::distinct_name_family`：`1<=k<=n<=47`，精確 falling factorial 計數、1-based lexicographic unrank、Math::BigInt、拒絕非法輸入、輸入不變性與避免輸出別名。已具備同源 11/11 job、Native 專門測試、獨立 oracle、原始 ZIP CRC/SHA256 及所有必要日誌證據。

准許以純文件 commit 把 `LAST_COMPLETED_STAGE` 從 9 改為 10；該 commit 不構成新 Native 測試。**尚未驗收**：全集成 `buildYearStructure`、完整五日期欄位、`calendarDate`、`year5000` 或 55 階段整體完成。

**NEXT**：在本 Perl 分支進行 Stage11 的規範來源與覆蓋缺口調查，選定最小尚未驗收之生成切片；先提交界限、獨立 oracle、排序與 Native/CI 門檻契約，才開始生產實作。不得採用其他分支的程式碼／fixtures，不得憑 Stage10 PASS 宣稱整體日曆正確。無 main、merge 或對外發布。
